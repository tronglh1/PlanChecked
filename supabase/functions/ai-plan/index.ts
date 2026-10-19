// POST /functions/v1/ai-plan   { project_id, regenerate?: boolean, plant_group?: 'rau_qua'|'cay_canh' }
// Creates a DRAFT plan for a project: template hit (no AI) -> else AI (Haiku, escalate to Sonnet) -> else seed fallback.
// The app then shows the plan for approval (approve_plan RPC). Returns codes + params only.
import type { SupabaseClient } from '@supabase/supabase-js';
import { authenticate } from '../_shared/auth.ts';
import { AiFailure, estimateCost, generateWithEscalation } from '../_shared/anthropic.ts';
import { PLAN_TIMEOUT_MS } from '../_shared/constants.ts';
import {
  buildPlanContext, buildPlantCard, buildUserCard, localDate, seasonFor, slugify, templateKey,
} from '../_shared/context.ts';
import { isQuotaError, loadKnownCodes, loadPrices, loadThresholds } from '../_shared/db.ts';
import { requireAi } from '../_shared/ai.ts';
import { errorResponse, HttpError, isUuid, json, preflight, readJson } from '../_shared/http.ts';
import { planSystem, planTool } from '../_shared/prompts.ts';
import type { PlanOutput, PlanStage, PlanTask } from '../_shared/types.ts';
import { validatePlanOutput } from '../_shared/validate.ts';

Deno.serve(async (req) => {
  const pre = preflight(req);
  if (pre) return pre;
  try {
    return json(await handle(req));
  } catch (e) {
    return errorResponse(e);
  }
});

type FallbackReason = 'quota_exceeded' | 'ai_error' | 'invalid_output' | null;
interface PlanBody { stages: PlanStage[]; tasks: PlanTask[] }

async function handle(req: Request) {
  const ctx = await authenticate(req);
  const body = await readJson(req);
  if (!isUuid(body.project_id)) throw new HttpError(400, 'invalid_project_id');
  const regenerate = body.regenerate === true;
  const groupHint = body.plant_group === 'cay_canh' ? 'cay_canh' : 'rau_qua';
  const { admin } = ctx;

  // Project is read as the user, so RLS decides visibility; only the project owner may generate its plan.
  const { data: project } = await ctx.user.from('projects').select('*').eq('id', body.project_id).maybeSingle();
  if (!project) throw new HttpError(404, 'project_not_found');
  if (project.owner_id !== ctx.userId) throw new HttpError(403, 'not_project_owner');

  if (!regenerate) {
    const { data: existing } = await admin.from('plans').select('id, source, confidence, model').eq('project_id', project.id).eq('status', 'draft').maybeSingle();
    if (existing) {
      const { stages, tasks } = await loadPlanBody(admin, existing.id);
      return { plan_id: existing.id, source: existing.source, confidence: existing.confidence, template_key: project.template_key, model: existing.model, from_cache: true, fallback_reason: null, new_plant: false, stages, tasks };
    }
  }

  const { data: profile } = await admin.from('users').select('*').eq('id', ctx.userId).single();
  const known = await loadKnownCodes(admin);
  const thresholds = await loadThresholds(admin);

  // ---- plant data
  let plant = null as Awaited<ReturnType<typeof loadPlant>>;
  if (project.plant_id) plant = await loadPlant(admin, project.plant_id);
  const plantName: string = plant?.row.name_en ?? project.plant_name_custom ?? project.name;
  const plantId: string = plant?.row.id ?? `custom_${slugify(plantName)}`;
  const plantKnown = !!plant;
  const group = plant?.row.group ?? groupHint;

  // ---- context
  const zone: string = profile?.zone_code ?? 'VN_S';
  const today = localDate(profile?.timezone);
  const season = seasonFor(zone, today);
  const key = templateKey({ plantId, zone, season, startStage: project.start_stage, space: project.space, sunLevel: project.sun_level });

  // ---- 1. template hit: no AI, no quota
  const { data: tpl } = await admin.from('plan_templates').select('template_key, body, confidence, hit_count').eq('template_key', key).eq('status', 'active').maybeSingle();
  if (tpl) {
    const bodyJson = tpl.body as PlanBody;
    const planId = await createDraft(admin, project.id, 'template', tpl.confidence, key, null, bodyJson);
    await admin.from('plan_templates').update({ hit_count: (tpl.hit_count ?? 0) + 1 }).eq('template_key', key);
    return respond(planId, 'template', tpl.confidence, key, null, bodyJson, true, null, false);
  }

  const fallback = async (reason: FallbackReason) => {
    const { data: fb } = await admin.rpc('fallback_plan', {
      p_plant: plantKnown ? plantId : group === 'cay_canh' ? 'generic_ornamental' : 'generic_edible',
      p_start: project.start_stage,
    });
    const fbBody = (fb ?? (await admin.rpc('fallback_plan', { p_plant: group === 'cay_canh' ? 'generic_ornamental' : 'generic_edible', p_start: 'seed' })).data) as PlanBody | null;
    if (!fbBody) throw new HttpError(500, 'no_fallback_plan');
    const planId = await createDraft(admin, project.id, 'fallback', null, key, null, fbBody);
    return respond(planId, 'fallback', null, key, null, fbBody, false, reason, false);
  };

  // ---- 2. AI, guarded by the daily quota
  const { error: quotaErr } = await ctx.user.rpc('consume_ai_quota', { p_kind: 'plan' });
  if (quotaErr) {
    if (isQuotaError(quotaErr)) return await fallback('quota_exceeded');
    throw new HttpError(500, 'quota_error', quotaErr.message);
  }

  const plantCard = buildPlantCard(plant?.row ?? null, plantName, group, plant?.stages ?? [], plant?.problems ?? []);
  const userCard = buildUserCard(profile);
  const { data: lessonRows } = await admin.from('project_lessons').select('text').eq('user_id', ctx.userId)
    .eq('plant_id', plantId).order('created_at', { ascending: false }).limit(3);
  const context = buildPlanContext({
    startDate: project.start_date, startStage: project.start_stage, zone, season, space: project.space, sunLevel: project.sun_level,
    pot: project.pot_type, watering: project.watering, hasChildren: !!profile?.has_children, hasPets: !!profile?.has_pets,
    lessons: (lessonRows ?? []).map((l) => l.text as string),
  }, plantCard, userCard);

  const ai = requireAi();
  const system = planSystem(known);
  const tool = planTool(known);
  let result;
  try {
    result = await generateWithEscalation<PlanOutput>({
      startStrong: !plantKnown,
      models: ai.models,
      threshold: thresholds.escalateBelow,
      confidenceOf: (v) => v.confidence,
      validate: (input) => validatePlanOutput(input, known, { plantKnown }),
      call: (model) => ai.call({
        model, system, tool, maxTokens: 3500, timeoutMs: PLAN_TIMEOUT_MS,
        content: [
          { type: 'text', text: `plant_card: ${JSON.stringify(plantCard)}`, cache_control: { type: 'ephemeral' } },
          { type: 'text', text: JSON.stringify(context) },
        ],
      }),
    });
  } catch (e) {
    if (e instanceof AiFailure) {
      await recordUsage(admin, ctx.userId, e.model ?? ai.models.default, e.usage);
      await admin.rpc('ai_quota_refund', { p_user: ctx.userId, p_kind: 'plan' });
      console.error('ai-plan failed', e.reason, e.message);
      return await fallback(e.reason);
    }
    throw e;
  }
  await recordUsage(admin, ctx.userId, result.model, result.usage);
  if (result.dropped.length) console.warn('ai-plan dropped', result.dropped);

  // ---- 3. persist: unknown plant row, template for later users, draft plan
  const out = result.value;
  let finalPlantId = plant?.row.id ?? null;
  let newPlant = false;
  if (!plantKnown && out.new_text) {
    finalPlantId = await createUnverifiedPlant(admin, plantId, out, project.id, thresholds.escalateBelow);
    newPlant = true;
  }
  const names = new Map((plant?.allStages ?? []).map((s) => [s.code, s]));
  const planBody: PlanBody = {
    stages: out.stages.map((s) => ({
      ...s,
      name_vi: s.name_vi ?? names.get(s.code)?.name_vi ?? out.new_text?.stages.find((x) => x.code === s.code)?.name_vi ?? s.code,
      name_en: s.name_en ?? names.get(s.code)?.name_en ?? out.new_text?.stages.find((x) => x.code === s.code)?.name_en ?? s.code,
    })),
    tasks: out.tasks,
  };
  if (out.confidence >= thresholds.medium) {
    await admin.from('plan_templates').upsert({
      template_key: key, plant_id: finalPlantId, zone, season, start_stage: project.start_stage, space: project.space,
      sun_level: project.sun_level, created_by: 'ai', confidence: out.confidence, body: planBody,
    }, { onConflict: 'template_key', ignoreDuplicates: true });
  }
  const planId = await createDraft(admin, project.id, 'ai', out.confidence, key, result.model, planBody);
  return respond(planId, 'ai', out.confidence, key, result.model, planBody, false, null, newPlant);
}

// ---------------------------------------------------------------- helpers
async function loadPlant(admin: SupabaseClient, id: string) {
  const { data: row } = await admin.from('plants').select('*').eq('id', id).maybeSingle();
  if (!row) return null;
  const [{ data: st }, { data: pp }] = await Promise.all([
    admin.from('plant_stages').select('code, name_vi, name_en, day_min, day_max, milestone_code').eq('plant_id', id).order('order'),
    admin.from('plant_problems').select('problem_code').eq('plant_id', id).order('rank'),
  ]);
  return {
    row,
    stages: (st ?? []).map((s) => ({ code: s.code, day_min: s.day_min, day_max: s.day_max, milestone_code: s.milestone_code })),
    allStages: (st ?? []) as { code: string; name_vi: string; name_en: string }[],
    problems: (pp ?? []).map((p) => p.problem_code as string),
  };
}

async function createDraft(admin: SupabaseClient, projectId: string, source: string, confidence: number | null, key: string, model: string | null, body: PlanBody): Promise<string> {
  const { data, error } = await admin.rpc('create_draft_plan', {
    p_project: projectId, p_source: source, p_confidence: confidence, p_template_key: key, p_model: model,
    p_stages: body.stages, p_tasks: body.tasks,
  });
  if (error) throw new HttpError(500, 'plan_persist_failed', error.message);
  return data as string;
}

async function createUnverifiedPlant(admin: SupabaseClient, id: string, out: PlanOutput, projectId: string, _t: number): Promise<string> {
  const t = out.new_text!;
  await admin.from('plants').upsert({
    id, group: t.plant.group, name_vi: t.plant.name_vi, name_en: t.plant.name_en, scientific_name: t.plant.scientific_name,
    search_key: await searchKey(admin, `${t.plant.name_vi} ${t.plant.name_en}`), difficulty: t.plant.difficulty,
    days_to_harvest: t.plant.days_to_harvest, data_status: 'ai_unverified', sources: ['ai:new_plant'],
  }, { onConflict: 'id', ignoreDuplicates: true });
  const rows = out.stages.map((s, i) => {
    const n = t.stages.find((x) => x.code === s.code);
    return { plant_id: id, code: s.code, order: i + 1, name_vi: n?.name_vi ?? s.code, name_en: n?.name_en ?? s.code, day_min: s.day_from, day_max: s.day_to, milestone_code: s.milestone, phase: i === 0 ? 'seed' : 'mature' };
  });
  await admin.from('plant_stages').upsert(rows, { onConflict: 'plant_id,code', ignoreDuplicates: true });
  await admin.from('projects').update({ plant_id: id }).eq('id', projectId);
  return id;
}

async function searchKey(admin: SupabaseClient, text: string): Promise<string> {
  const { data } = await admin.rpc('vn_search_key', { p_text: text });
  return (data as string) ?? text.toLowerCase();
}

async function recordUsage(admin: SupabaseClient, userId: string, model: string, u: { input_tokens: number; output_tokens: number; cache_read_input_tokens: number; cache_creation_input_tokens: number }) {
  await admin.rpc('ai_usage_record', {
    p_user: userId, p_kind: 'plan', p_model: model, p_in: u.input_tokens + u.cache_creation_input_tokens, p_out: u.output_tokens,
    p_cache: u.cache_read_input_tokens, p_cost: estimateCost(model, u, loadPrices()),
  });
}

async function loadPlanBody(admin: SupabaseClient, planId: string): Promise<PlanBody> {
  const { data: st } = await admin.from('stages').select('id, code, name, name_en, day_from, day_to, milestone_code').eq('plan_id', planId).order('idx');
  const { data: tk } = await admin.from('tasks').select('stage_id, task_code, frequency, interval_days, window, day_offset, reason_code')
    .in('stage_id', (st ?? []).map((s) => s.id));
  const codeById = new Map((st ?? []).map((s) => [s.id as string, s.code as string]));
  return {
    stages: (st ?? []).map((s) => ({ code: s.code, day_from: s.day_from, day_to: s.day_to, milestone: s.milestone_code, name_vi: s.name, name_en: s.name_en ?? undefined })),
    tasks: (tk ?? []).map((t) => ({
      task: t.task_code, stage: codeById.get(t.stage_id) ?? '', window: t.window,
      every_d: t.frequency === 'once' ? 0 : t.frequency === 'daily' ? 1 : (t.interval_days ?? 1), offset_d: t.day_offset, why: t.reason_code,
    })),
  };
}

function respond(planId: string, source: string, confidence: number | null, key: string, model: string | null, body: PlanBody, fromCache: boolean, reason: FallbackReason, newPlant: boolean) {
  return { plan_id: planId, source, confidence, template_key: key, model, from_cache: fromCache, fallback_reason: reason, new_plant: newPlant, stages: body.stages, tasks: body.tasks };
}
