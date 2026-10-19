// Server-side validation of model output (spec §5.3): only known codes, params in range, no doses.
// Invalid items are dropped (and listed in `dropped`); structurally unusable output fails the whole validation.
import {
  DOSE_RE, HEALTH_VALUES, HINT_CODES, HINT_FOR_REASON, MAX_DAYS, MAX_DELTA, MAX_ISSUES, MAX_STAGES, MAX_TASKS,
  RETAKE_REASONS, WINDOWS,
} from './constants.ts';
import type {
  CheckinIssue, CheckinOutput, DeltaOp, KnownCodes, NewPlantText, PlanOutput, PlanStage, PlanTask, TaskWindow,
  Validation,
} from './types.ts';

type Obj = Record<string, unknown>;
const isObj = (v: unknown): v is Obj => !!v && typeof v === 'object' && !Array.isArray(v);
const isInt = (v: unknown, min: number, max: number): v is number =>
  typeof v === 'number' && Number.isInteger(v) && v >= min && v <= max;
const isConf = (v: unknown): v is number => typeof v === 'number' && v >= 0 && v <= 1;
const isWindow = (v: unknown): v is TaskWindow => typeof v === 'string' && (WINDOWS as readonly string[]).includes(v);

export function containsDose(text: string): boolean {
  return DOSE_RE.test(text);
}

function safeText(v: unknown, max = 80): string | null {
  if (typeof v !== 'string') return null;
  const s = v.trim();
  if (!s || s.length > max || containsDose(s) || /[<>]/.test(s)) return null;
  return s;
}

export function confidenceBand(c: number, high = 0.75, medium = 0.5): 'high' | 'medium' | 'low' {
  return c >= high ? 'high' : c >= medium ? 'medium' : 'low';
}

// ---------------------------------------------------------------- plan
export function validatePlanOutput(raw: unknown, known: KnownCodes, opts: { plantKnown: boolean }): Validation<PlanOutput> {
  const errors: string[] = [];
  const dropped: string[] = [];
  if (!isObj(raw)) return { ok: false, errors: ['output is not an object'] };
  if (!isConf(raw.confidence)) errors.push('confidence missing or out of 0..1');

  // stages
  const stages: PlanStage[] = [];
  if (!Array.isArray(raw.stages) || raw.stages.length < 1 || raw.stages.length > MAX_STAGES) {
    errors.push('stages must be an array of 1..' + MAX_STAGES);
  } else {
    let prevTo = 0;
    const seen = new Set<string>();
    for (const s of raw.stages) {
      if (!isObj(s) || typeof s.code !== 'string' || !/^S\d{1,2}$/.test(s.code) || seen.has(s.code)) {
        errors.push('bad stage code'); continue;
      }
      if (!isInt(s.day_from, 1, MAX_DAYS) || !isInt(s.day_to, 1, MAX_DAYS) || s.day_to < s.day_from || s.day_from <= prevTo) {
        errors.push(`stage ${s.code}: bad day range`); continue;
      }
      let milestone: string | null = null;
      if (s.milestone != null && s.milestone !== '') {
        if (typeof s.milestone === 'string' && known.milestones.has(s.milestone)) milestone = s.milestone;
        else dropped.push(`stage ${s.code}: unknown milestone ${String(s.milestone)}`);
      }
      seen.add(s.code);
      prevTo = s.day_to;
      stages.push({
        code: s.code, day_from: s.day_from, day_to: s.day_to, milestone,
        ...(safeText(s.name_vi, 60) ? { name_vi: safeText(s.name_vi, 60)! } : {}),
        ...(safeText(s.name_en, 60) ? { name_en: safeText(s.name_en, 60)! } : {}),
      });
    }
  }
  if (errors.length) return { ok: false, errors };

  // tasks
  const stageByCode = new Map(stages.map((s) => [s.code, s]));
  const tasks: PlanTask[] = [];
  if (!Array.isArray(raw.tasks)) return { ok: false, errors: ['tasks must be an array'] };
  const seenTask = new Set<string>();
  for (const t of raw.tasks.slice(0, MAX_TASKS)) {
    if (!isObj(t) || typeof t.task !== 'string' || !known.tasks.has(t.task)) {
      dropped.push(`task: unknown code ${isObj(t) ? String(t.task) : '?'}`); continue;
    }
    const stage = typeof t.stage === 'string' ? stageByCode.get(t.stage) : undefined;
    if (!stage) { dropped.push(`task ${t.task}: unknown stage ${String(isObj(t) ? t.stage : '')}`); continue; }
    if (!isInt(t.every_d, 0, 60)) { dropped.push(`task ${t.task}: every_d out of range`); continue; }
    const key = `${stage.code}|${t.task}`;
    if (seenTask.has(key)) { dropped.push(`task ${t.task}: duplicate in ${stage.code}`); continue; }
    seenTask.add(key);
    const info = known.tasks.get(t.task)!;
    const len = stage.day_to - stage.day_from + 1;
    let offset = isInt(t.offset_d, 0, MAX_DAYS) ? t.offset_d : 0;
    if (offset > len - 1) { dropped.push(`task ${t.task}: offset clamped`); offset = len - 1; }
    let why: string | null = null;
    if (t.why != null && t.why !== '') {
      if (typeof t.why === 'string' && known.reasons.has(t.why)) why = t.why;
      else dropped.push(`task ${t.task}: unknown reason ${String(t.why)}`);
    }
    tasks.push({ task: t.task, stage: stage.code, every_d: t.every_d, window: isWindow(t.window) ? t.window : info.window, offset_d: offset, why });
  }
  if (raw.tasks.length > MAX_TASKS) dropped.push(`tasks truncated to ${MAX_TASKS}`);
  if (tasks.length < 3) return { ok: false, errors: ['fewer than 3 valid tasks'] };

  // new_text only for plants not in the DB
  let newText: NewPlantText | null = null;
  if (!opts.plantKnown && raw.new_text != null) {
    newText = validateNewText(raw.new_text, stages);
    if (!newText) dropped.push('new_text rejected');
  } else if (opts.plantKnown && raw.new_text != null) {
    dropped.push('new_text ignored for known plant');
  }

  return { ok: true, value: { confidence: raw.confidence as number, stages, tasks: ensureCheckins(tasks, stages), new_text: newText }, dropped };
}

function validateNewText(v: unknown, stages: PlanStage[]): NewPlantText | null {
  if (!isObj(v) || !isObj(v.plant)) return null;
  const p = v.plant;
  const name_vi = safeText(p.name_vi), name_en = safeText(p.name_en);
  if (!name_vi || !name_en) return null;
  if (p.group !== 'rau_qua' && p.group !== 'cay_canh') return null;
  const difficulty = ['easy', 'medium', 'hard'].includes(p.difficulty as string) ? (p.difficulty as 'easy' | 'medium' | 'hard') : 'medium';
  const days = isInt(p.days_to_harvest, 1, MAX_DAYS) ? p.days_to_harvest : stages[stages.length - 1].day_to;
  const outStages: NewPlantText['stages'] = [];
  if (Array.isArray(v.stages)) {
    for (const s of v.stages) {
      if (!isObj(s) || !stages.some((x) => x.code === s.code)) continue;
      const vi = safeText(s.name_vi, 60), en = safeText(s.name_en, 60);
      if (vi && en) outStages.push({ code: s.code as string, name_vi: vi, name_en: en });
    }
  }
  return {
    plant: { name_vi, name_en, scientific_name: safeText(p.scientific_name, 80), group: p.group, difficulty, days_to_harvest: days },
    stages: outStages,
  };
}

/** The plan must keep a check-in rhythm of 3-7 days (CHK-01): add T_CHECKIN to any stage that lacks one. */
export function ensureCheckins(tasks: PlanTask[], stages: PlanStage[]): PlanTask[] {
  const out = [...tasks];
  for (const s of stages) {
    if (out.some((t) => t.stage === s.code && t.task === 'T_CHECKIN')) continue;
    const len = s.day_to - s.day_from + 1;
    out.push({ task: 'T_CHECKIN', stage: s.code, every_d: len > 60 ? 7 : 5, window: 'all_day', offset_d: Math.min(2, len - 1), why: 'R_CHECKIN_CADENCE' });
  }
  return out;
}

// ---------------------------------------------------------------- check-in
export interface CheckinCtx {
  /** Stage codes of the project's approved plan (the delta may only reference these). */
  stageCodes: Set<string>;
  /** Local date YYYY-MM-DD of the user, used to bound `shift` targets. */
  today: string;
}

function validIsoDate(s: unknown): s is string {
  if (typeof s !== 'string' || !/^\d{4}-\d{2}-\d{2}$/.test(s)) return false;
  const d = new Date(s + 'T00:00:00Z');
  return !Number.isNaN(d.getTime()) && d.toISOString().slice(0, 10) === s;
}
const dayNumber = (iso: string) => Math.floor(new Date(iso + 'T00:00:00Z').getTime() / 86_400_000);

export function validateCheckinOutput(raw: unknown, known: KnownCodes, ctx: CheckinCtx): Validation<CheckinOutput> {
  const dropped: string[] = [];
  if (!isObj(raw)) return { ok: false, errors: ['output is not an object'] };

  if (raw.status === 'retake') {
    const reason = (RETAKE_REASONS as readonly string[]).includes(raw.reason as string) ? (raw.reason as typeof RETAKE_REASONS[number]) : null;
    if (!reason) return { ok: false, errors: ['retake: unknown reason'] };
    const hint = (HINT_CODES as readonly string[]).includes(raw.hint_code as string) ? (raw.hint_code as string) : HINT_FOR_REASON[reason];
    if (hint !== raw.hint_code) dropped.push('hint_code replaced');
    return { ok: true, value: { status: 'retake', reason, hint_code: hint }, dropped };
  }
  if (raw.status !== 'ok') return { ok: false, errors: ['status must be ok or retake'] };

  if (!isObj(raw.health) || !(HEALTH_VALUES as readonly string[]).includes(raw.health.value as string) || !isConf(raw.health.confidence)) {
    return { ok: false, errors: ['health missing or invalid'] };
  }
  const health = { value: raw.health.value as 'good' | 'fair' | 'poor', confidence: raw.health.confidence };

  let stage_est: { code: string; confidence: number } | null = null;
  if (isObj(raw.stage_est) && typeof raw.stage_est.code === 'string' && isConf(raw.stage_est.confidence)) {
    const base = /^(S\d{1,2})(_[a-z]+)?$/.exec(raw.stage_est.code);
    if (base && ctx.stageCodes.has(base[1])) stage_est = { code: raw.stage_est.code, confidence: raw.stage_est.confidence };
    else dropped.push(`stage_est: unknown ${raw.stage_est.code}`);
  }

  const issues: CheckinIssue[] = [];
  for (const i of Array.isArray(raw.issues) ? raw.issues.slice(0, MAX_ISSUES) : []) {
    if (!isObj(i) || typeof i.code !== 'string' || !known.problems.has(i.code)) { dropped.push(`issue: unknown ${isObj(i) ? String(i.code) : '?'}`); continue; }
    if (!isConf(i.confidence)) { dropped.push(`issue ${i.code}: bad confidence`); continue; }
    const actions: { task: string }[] = [];
    for (const a of Array.isArray(i.actions) ? i.actions.slice(0, 4) : []) {
      if (isObj(a) && typeof a.task === 'string' && known.tasks.has(a.task)) actions.push({ task: a.task });
      else dropped.push(`issue ${i.code}: unknown action`);
    }
    issues.push({ code: i.code, confidence: i.confidence, severity: (isInt(i.severity, 1, 3) ? i.severity : 1) as 1 | 2 | 3, actions });
  }

  let milestone_seen: { code: string; confidence: number } | null = null;
  if (isObj(raw.milestone_seen) && raw.milestone_seen.code != null) {
    const m = raw.milestone_seen;
    if (typeof m.code === 'string' && known.milestones.has(m.code) && isConf(m.confidence)) milestone_seen = { code: m.code, confidence: m.confidence };
    else dropped.push(`milestone_seen: unknown ${String(m.code)}`);
  }

  const delta: DeltaOp[] = [];
  const seen = new Set<string>();
  for (const d of Array.isArray(raw.delta) ? raw.delta : []) {
    if (delta.length >= MAX_DELTA) { dropped.push('delta truncated'); break; }
    if (!isObj(d) || typeof d.op !== 'string') { dropped.push('delta: malformed'); continue; }
    const why = typeof d.why === 'string' && known.reasons.has(d.why) ? d.why : null;
    if (d.why != null && d.why !== '' && !why) dropped.push(`delta ${d.op}: unknown reason`);
    const taskOk = typeof d.task === 'string' && known.tasks.has(d.task);
    let item: DeltaOp | null = null;
    if (d.op === 'add' && taskOk) {
      const stage = typeof d.stage === 'string' && ctx.stageCodes.has(d.stage) ? d.stage : null;
      if (d.stage != null && !stage) { dropped.push(`delta add ${d.task}: unknown stage`); }
      else item = { op: 'add', task: d.task as string, stage, every_d: isInt(d.every_d, 0, 60) ? d.every_d : null, window: isWindow(d.window) ? d.window : null, why };
    } else if (d.op === 'remove' && taskOk) {
      item = { op: 'remove', task: d.task as string, why };
    } else if (d.op === 'change_freq' && taskOk && isInt(d.every_d, 1, 60)) {
      item = { op: 'change_freq', task: d.task as string, every_d: d.every_d, why };
    } else if (d.op === 'shift' && typeof d.milestone === 'string' && known.milestones.has(d.milestone) && validIsoDate(d.to)) {
      const diff = dayNumber(d.to) - dayNumber(ctx.today);
      if (diff >= 0 && diff <= 180) item = { op: 'shift', milestone: d.milestone, to: d.to, why };
      else dropped.push('delta shift: date out of range');
    }
    if (!item) { dropped.push(`delta: invalid ${d.op}`); continue; }
    const key = `${item.op}|${'task' in item ? item.task : item.milestone}`;
    if (seen.has(key)) { dropped.push(`delta: duplicate ${key}`); continue; }
    seen.add(key);
    delta.push(item);
  }

  const reason_codes = (Array.isArray(raw.reason_codes) ? raw.reason_codes : []).filter((c): c is string => typeof c === 'string' && known.reasons.has(c)).slice(0, 5);

  return { ok: true, value: { status: 'ok', stage_est, health, issues, milestone_seen, delta, reason_codes }, dropped };
}

/** Lowest confidence the user will see: drives escalation and the "ask a local store" low band. */
export function minConfidence(o: CheckinOutput): number {
  if (o.status !== 'ok') return 1;
  return Math.min(o.health.confidence, ...o.issues.map((i) => i.confidence));
}
