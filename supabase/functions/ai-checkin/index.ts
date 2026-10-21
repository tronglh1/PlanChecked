// POST /functions/v1/ai-checkin   { checkin_id }
// The app uploads ~768px JPEGs to the private `checkins` bucket and inserts a `checkins` row (status pending,
// shots = [{shot, path}], tags, note), then calls this function. One call returns diagnosis + plan delta, or a retake request.
import type { SupabaseClient } from '@supabase/supabase-js';
import { authenticate } from '../_shared/auth.ts';
import { AiFailure, estimateCost, generateWithEscalation, type ContentBlock } from '../_shared/anthropic.ts';
import { CHECKIN_TIMEOUT_MS, MAX_IMAGE_BYTES, MILESTONE_MIN_CONFIDENCE } from '../_shared/constants.ts';
import {
  buildPlantCard, buildProjectCard, buildUserCard, daysBetween, localDate, seasonFor, shouldSkipRecent, stageForDay,
  type ChangeRow, type CheckinRow, type OccurrenceRow,
} from '../_shared/context.ts';
import { isQuotaError, loadKnownCodes, loadPrices, loadThresholds } from '../_shared/db.ts';
import { requireAi } from '../_shared/ai.ts';
import { errorResponse, HttpError, isUuid, json, preflight, readJson } from '../_shared/http.ts';
import { looksLikeJpeg, parseShots, toBase64 } from '../_shared/image.ts';
import { checkinSystem, checkinTool } from '../_shared/prompts.ts';
import type { CheckinOutput } from '../_shared/types.ts';
import { confidenceBand, minConfidence, validateCheckinOutput } from '../_shared/validate.ts';

Deno.serve(async (req) => {
  const pre = preflight(req);
  if (pre) return pre;
  try {
    const r = await handle(req);
    return json(r.body, r.status ?? 200);
  } catch (e) {
    return errorResponse(e);
  }
});

async function handle(req: Request): Promise<{ body: Record<string, unknown>; status?: number }> {
  const ctx = await authenticate(req);
  const body = await readJson(req);
  if (!isUuid(body.checkin_id)) throw new HttpError(400, 'invalid_checkin_id');
  const { admin } = ctx;

  // Read as the user: RLS guarantees they can see the project. Only the author may analyze their own check-in.
  const { data: checkin } = await ctx.user.from('checkins').select('*').eq('id', body.checkin_id).maybeSingle();
  if (!checkin) throw new HttpError(404, 'checkin_not_found');
  if (checkin.user_id !== ctx.userId) throw new HttpError(403, 'not_checkin_author');
  if (checkin.status !== 'pending') return { body: { status: 'already_processed', checkin_status: checkin.status, checkin_id: checkin.id, result: checkin.ai_result } };

  const { data: project } = await admin.from('projects').select('*').eq('id', checkin.project_id).single();
  if (!project) throw new HttpError(404, 'project_not_found');
  const tags: string[] = checkin.tags ?? [];

  // ---- skip rule: analyzed < 24h ago and no new tag => no AI call, no quota, no XP
  const { data: last } = await admin.from('checkins').select('id, created_at, tags').eq('project_id', project.id).in('status', ['analyzed', 'approved'])
    .neq('id', checkin.id).order('created_at', { ascending: false }).limit(1).maybeSingle();
  if (last && shouldSkipRecent(last.created_at, last.tags ?? [], tags)) {
    await admin.from('checkins').update({ status: 'rejected', counts_toward_quota: false, ai_result: { skipped: 'recent_analysis', previous_checkin_id: last.id } }).eq('id', checkin.id);
    return { body: { status: 'skipped_recent', previous_checkin_id: last.id, checkin_id: checkin.id } };
  }

  // ---- shots: must be this project's, in a folder the caller may use, and actually present
  const folders = [ctx.userId, ...(project.household_id ? [project.household_id as string] : [])];
  const shots = parseShots(checkin.shots, project.id, folders);
  if (!shots.length) throw new HttpError(400, 'no_valid_shots');

  // ---- quota (retakes and AI failures are refunded below)
  const { error: quotaErr } = await ctx.user.rpc('consume_ai_quota', { p_kind: 'checkin' });
  if (quotaErr) {
    if (isQuotaError(quotaErr)) {
      const { data: quota } = await ctx.user.rpc('get_ai_quota');
      throw new HttpError(429, 'ai_quota_exceeded', 'Daily check-in limit reached', { quota });
    }
    throw new HttpError(500, 'quota_error', quotaErr.message);
  }
  const refund = () => admin.rpc('ai_quota_refund', { p_user: ctx.userId, p_kind: 'checkin' });

  try {
    const imageBlocks = await loadImages(admin, shots);
    const thresholds = await loadThresholds(admin);
    const known = await loadKnownCodes(admin);

    // ---- cards
    const { data: profile } = await admin.from('users').select('*').eq('id', project.owner_id).single();
    const { data: ownProfile } = await admin.from('users').select('timezone').eq('id', ctx.userId).single();
    const today = localDate(ownProfile?.timezone ?? profile?.timezone);
    const day = Math.max(1, daysBetween(project.start_date, today) + 1);
    const { data: plan } = await admin.from('plans').select('id').eq('project_id', project.id).eq('status', 'approved').maybeSingle();
    const { data: stageRows } = plan ? await admin.from('stages').select('code, day_from, day_to').eq('plan_id', plan.id).order('idx') : { data: [] };
    const stages = stageRows ?? [];
    const stageCodes = new Set(stages.map((s) => s.code as string));

    const since = new Date(Date.now() - 14 * 86_400_000).toISOString().slice(0, 10);
    const [{ data: occ }, { data: skips }, { data: cks }, { data: chg }] = await Promise.all([
      admin.from('task_occurrences').select('due_date, state').eq('project_id', project.id).gte('due_date', since),
      admin.from('task_logs').select('tasks(task_code)').eq('project_id', project.id).eq('action', 'skip').gte('acted_at', since),
      admin.from('checkins').select('id, created_at, ai_result, tags').eq('project_id', project.id).in('status', ['analyzed', 'approved']).neq('id', checkin.id)
        .order('created_at', { ascending: false }).limit(12),
      admin.from('checkin_changes').select('change_kind, payload, checkins!inner(project_id)').eq('accepted', true).eq('checkins.project_id', project.id)
        .order('created_at', { ascending: false }).limit(5),
    ]);
    const startDate: string = project.start_date;
    const checkinRows: CheckinRow[] = (cks ?? []).map((c) => ({
      created_day: Math.max(1, daysBetween(startDate, localDate(ownProfile?.timezone, new Date(c.created_at))) + 1),
      status: 'analyzed', ai_result: c.ai_result,
    }));
    const card = buildProjectCard({
      plantId: project.plant_id ?? project.plant_name_custom ?? 'unknown', day, stage: stageForDay(stages, day),
      zone: profile?.zone_code ?? 'VN_S', season: seasonFor(profile?.zone_code ?? 'VN_S', today), space: project.space, sun: project.sun_level,
      pot: project.pot_type, water: project.watering, occurrences: (occ ?? []) as OccurrenceRow[], today,
      skipCodes: (skips ?? []).map((s: { tasks: { task_code: string } | { task_code: string }[] | null }) => (Array.isArray(s.tasks) ? s.tasks[0]?.task_code : s.tasks?.task_code) ?? '').filter(Boolean),
      checkins: checkinRows, changes: (chg ?? []) as unknown as ChangeRow[],
    });
    const { data: plantRow } = project.plant_id ? await admin.from('plants').select('*').eq('id', project.plant_id).maybeSingle() : { data: null };
    const plantKnown = !!plantRow;
    const userCard = buildUserCard(profile);
    const plantCard = buildPlantCard(plantRow, project.plant_name_custom ?? project.name, plantRow?.group ?? 'rau_qua', [], []);

    // previous thumbnail only while an issue is tracked
    const content: ContentBlock[] = [
      { type: 'text', text: `plant: ${plantCard.name} (${plantCard.group}); user: ${JSON.stringify(userCard)}`, cache_control: { type: 'ephemeral' } },
      { type: 'text', text: JSON.stringify({
        project_card: card, tags, note: (checkin.note ?? '').slice(0, 200),
        images: shots.map((s) => ({ shot: s.shot, px: 768, jpeg_q: 75 })),
        today, plan_stage_codes: [...stageCodes],
      }) },
    ];
    for (let i = 0; i < imageBlocks.length; i++) {
      content.push({ type: 'text', text: `image ${i + 1}: ${shots[i].shot}` }, imageBlocks[i]);
    }
    if (card.active_issues.length && cks?.[0]) {
      const prev = parseShots(((await admin.from('checkins').select('shots').eq('id', cks[0].id).single()).data ?? {}).shots, project.id, folders, 1)[0];
      if (prev) {
        const [b] = await loadImages(admin, [prev]).catch(() => []);
        if (b) content.push({ type: 'text', text: `previous photo (tracking ${card.active_issues[0].code})` }, b);
      }
    }

    const ai = requireAi();
    const system = checkinSystem(known);
    const tool = checkinTool(known);
    let result;
    try {
      result = await generateWithEscalation<CheckinOutput>({
        startStrong: !plantKnown,
        models: ai.models,
        threshold: thresholds.escalateBelow,
        confidenceOf: minConfidence,
        validate: (input) => validateCheckinOutput(input, known, { stageCodes, today }),
        call: (model) => ai.call({ model, system, tool, content, maxTokens: 1800, timeoutMs: CHECKIN_TIMEOUT_MS }),
      });
    } catch (e) {
      if (e instanceof AiFailure) {
        await recordUsage(admin, ctx.userId, e.model ?? ai.models.default, e.usage);
        await refund();
        // Keep the provider's reply so a failed check-in can be diagnosed from the table.
        await admin.from('checkins').update({ ai_result: { error: e.reason, detail: e.message.slice(0, 300) } }).eq('id', checkin.id);
        // Spec §7 #38: no delta is applied, the plan stays as it is.
        return { status: 502, body: { status: 'error', code: 'AI_UNAVAILABLE', reason: e.reason, detail: e.message.slice(0, 200), checkin_id: checkin.id } };
      }
      throw e;
    }
    await recordUsage(admin, ctx.userId, result.model, result.usage);
    const out = result.value;

    // ---- retake: not counted toward the quota, no XP
    if (out.status === 'retake') {
      await refund();
      await admin.from('checkins').update({ status: 'retake', counts_toward_quota: false, ai_result: out, model: result.model }).eq('id', checkin.id);
      return { body: { ...out, checkin_id: checkin.id, model: result.model } };
    }

    // ---- ok: persist result (status analyzed triggers +30 XP server-side)
    const low = minConfidence(out);
    const band = confidenceBand(low, thresholds.high, thresholds.medium);
    await admin.from('checkins').update({ status: 'analyzed', ai_result: out, model: result.model }).eq('id', checkin.id);

    let changes: { id: string; change_kind: string; payload: unknown }[] = [];
    if (out.delta.length) {
      const { data } = await admin.from('checkin_changes').insert(out.delta.map((d) => ({
        checkin_id: checkin.id, change_kind: d.op, payload: d, accepted: false,
      }))).select('id, change_kind, payload');
      changes = data ?? [];
    }

    let milestone: { code: string; confidence: number; new: boolean } | null = null;
    if (out.milestone_seen && out.milestone_seen.confidence >= MILESTONE_MIN_CONFIDENCE) {
      const { data: ins, error } = await admin.from('milestones_reached').insert({
        project_id: project.id, milestone_code: out.milestone_seen.code, confirmed_by: 'ai', checkin_id: checkin.id, reached_on: today,
      }).select('id').maybeSingle();
      milestone = { ...out.milestone_seen, new: !!ins && !error };   // unique(project, milestone): repeat sightings are not new
    }

    const { data: after } = await admin.from('users').select('xp_total, level').eq('id', ctx.userId).single();
    return {
      body: {
        ...out, checkin_id: checkin.id, model: result.model, escalated: result.escalated,
        confidence_band: band, low_confidence: band === 'low',     // low => app suggests a local agricultural store (CHK-08)
        changes, milestone, xp: after,
      },
    };
  } catch (e) {
    await refund();   // any unexpected failure after the quota was taken gives it back
    throw e;
  }
}

async function loadImages(admin: SupabaseClient, shots: { shot: string; path: string }[]): Promise<ContentBlock[]> {
  const out: ContentBlock[] = [];
  for (const s of shots) {
    const { data, error } = await admin.storage.from('checkins').download(s.path);
    if (error || !data) throw new HttpError(400, 'image_not_found', s.path);
    const bytes = new Uint8Array(await data.arrayBuffer());
    if (bytes.length > MAX_IMAGE_BYTES) throw new HttpError(400, 'image_too_large', 'upload a ~768px JPEG');
    if (!looksLikeJpeg(bytes)) throw new HttpError(400, 'image_not_jpeg');
    out.push({ type: 'image', source: { type: 'base64', media_type: 'image/jpeg', data: toBase64(bytes) } });
  }
  return out;
}

async function recordUsage(admin: SupabaseClient, userId: string, model: string, u: { input_tokens: number; output_tokens: number; cache_read_input_tokens: number; cache_creation_input_tokens: number }) {
  await admin.rpc('ai_usage_record', {
    p_user: userId, p_kind: 'checkin', p_model: model, p_in: u.input_tokens + u.cache_creation_input_tokens, p_out: u.output_tokens,
    p_cache: u.cache_read_input_tokens, p_cost: estimateCost(model, u, loadPrices()),
  });
}
