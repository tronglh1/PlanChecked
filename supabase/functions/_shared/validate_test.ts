import assert from 'node:assert/strict';
import { checkinCtx, goodCheckin, goodPlan, known } from './test_helpers.ts';
import { confidenceBand, containsDose, ensureCheckins, minConfidence, validateCheckinOutput, validatePlanOutput } from './validate.ts';
import type { CheckinOutput } from './types.ts';
import { checkinTool } from './prompts.ts';

Deno.test('plan: valid output passes, check-in task is injected, offsets/windows defaulted', () => {
  const r = validatePlanOutput(goodPlan(), known, { plantKnown: true });
  assert.ok(r.ok);
  if (!r.ok) return;
  assert.equal(r.value.stages.length, 2);
  assert.equal(r.value.tasks.filter((t) => t.task === 'T_CHECKIN').length, 2, 'one T_CHECKIN per stage');
  assert.equal(r.value.tasks.find((t) => t.task === 'T_WATER' && t.stage === 'S1')!.offset_d, 0);
});

Deno.test('plan: unknown codes and out-of-range params are dropped, not trusted', () => {
  const p = goodPlan();
  p.tasks.push({ task: 'T_MAKE_UP', stage: 'S1', every_d: 1, window: 'morning', offset_d: 0, why: null });
  p.tasks.push({ task: 'T_PRUNE', stage: 'S9', every_d: 7, window: 'morning', offset_d: 0, why: null });
  p.tasks.push({ task: 'T_PRUNE', stage: 'S2', every_d: 99, window: 'morning', offset_d: 0, why: null });
  p.tasks.push({ task: 'T_PRUNE', stage: 'S2', every_d: 7, window: 'night' as never, offset_d: 500, why: 'R_MADE_UP' });
  const r = validatePlanOutput(p, known, { plantKnown: true });
  assert.ok(r.ok);
  if (!r.ok) return;
  const prune = r.value.tasks.filter((t) => t.task === 'T_PRUNE');
  assert.equal(prune.length, 1);
  assert.equal(prune[0].window, 'morning', 'invalid window falls back to the code default');
  assert.equal(prune[0].offset_d, 32, 'offset clamped inside the stage');
  assert.equal(prune[0].why, null);
  assert.ok(r.dropped.some((d) => d.includes('T_MAKE_UP')));
  assert.ok(r.dropped.some((d) => d.includes('S9')));
  assert.ok(r.dropped.some((d) => d.includes('every_d')));
});

Deno.test('plan: structurally bad output is rejected', () => {
  assert.equal(validatePlanOutput(null, known, { plantKnown: true }).ok, false);
  const p = goodPlan();
  (p as { confidence: number }).confidence = 1.4;
  assert.equal(validatePlanOutput(p, known, { plantKnown: true }).ok, false);
  const overlap = goodPlan();
  overlap.stages[1].day_from = 5;
  assert.equal(validatePlanOutput(overlap, known, { plantKnown: true }).ok, false);
  const few = goodPlan();
  few.tasks = few.tasks.slice(0, 2);
  assert.equal(validatePlanOutput(few, known, { plantKnown: true }).ok, false);
});

Deno.test('plan: unknown milestone on a stage is nulled; new_text only for unknown plants and without doses', () => {
  const p = goodPlan();
  p.stages[0].milestone = 'ASCENSION';
  const r = validatePlanOutput(p, known, { plantKnown: true });
  assert.ok(r.ok && r.value.stages[0].milestone === null);

  const nt = {
    plant: { name_vi: 'Cây lạ', name_en: 'Odd plant', group: 'rau_qua', difficulty: 'easy', days_to_harvest: 50, scientific_name: null },
    stages: [{ code: 'S1', name_vi: 'Gieo', name_en: 'Sow' }, { code: 'S9', name_vi: 'x', name_en: 'y' }],
  };
  const withText = { ...goodPlan(), new_text: nt };
  const unknown = validatePlanOutput(withText, known, { plantKnown: false });
  assert.ok(unknown.ok && unknown.value.new_text?.stages.length === 1, 'stage not in the plan is discarded');
  const ignored = validatePlanOutput(withText, known, { plantKnown: true });
  assert.ok(ignored.ok && ignored.value.new_text === null);
  const dosed = validatePlanOutput({ ...goodPlan(), new_text: { ...nt, plant: { ...nt.plant, name_en: 'Plant 5ml fert' } } }, known, { plantKnown: false });
  assert.ok(dosed.ok && dosed.value.new_text === null, 'dose-like text is rejected');
});

Deno.test('dose detection', () => {
  assert.equal(containsDose('mix 5 ml per litre'), true);
  assert.equal(containsDose('2% solution'), true);
  assert.equal(containsDose('10 g'), true);
  assert.equal(containsDose('Pha 3 muỗng'), true);
  assert.equal(containsDose('cao 40 cm, tưới 2 lần'), false);
  assert.equal(containsDose('Húng quế'), false);
});

Deno.test('ensureCheckins adds weekly check-in to long stages', () => {
  const out = ensureCheckins([], [{ code: 'S1', day_from: 1, day_to: 100, milestone: null }]);
  assert.equal(out[0].every_d, 7);
});

Deno.test('checkin: spec example validates; unknown stage_est/op/codes are filtered', () => {
  const r = validateCheckinOutput(goodCheckin(), known, checkinCtx);
  assert.ok(r.ok);
  if (!r.ok || r.value.status !== 'ok') return;
  assert.equal(r.value.delta.length, 3);
  assert.equal(r.value.issues[0].code, 'P_CALCIUM_LOW');
  assert.equal(r.value.stage_est?.code, 'S3_late');

  const bad = goodCheckin() as Record<string, unknown>;
  bad.stage_est = { code: 'S9_late', confidence: 0.5 };
  bad.issues = [{ code: 'P_ALIEN', confidence: 0.9, severity: 2, actions: [] }, { code: 'P_APHID', confidence: 0.7, severity: 7, actions: [{ task: 'T_NUKE' }, { task: 'T_PRUNE' }] }];
  bad.delta = [
    { op: 'add', task: 'T_NUKE', stage: 'S1' },
    { op: 'add', task: 'T_PRUNE', stage: 'S9' },
    { op: 'explode', task: 'T_PRUNE' },
    { op: 'change_freq', task: 'T_WATER', every_d: 0 },
    { op: 'shift', milestone: 'FLOWER', to: '2025-01-01' },
    { op: 'shift', milestone: 'FLOWER', to: '2026-13-40' },
    { op: 'shift', milestone: 'FLOWER', to: '2027-12-01' },
    { op: 'remove', task: 'T_PRUNE' },
    { op: 'remove', task: 'T_PRUNE' },
  ];
  bad.milestone_seen = { code: 'MOON', confidence: 0.9 };
  const r2 = validateCheckinOutput(bad, known, checkinCtx);
  assert.ok(r2.ok);
  if (!r2.ok || r2.value.status !== 'ok') return;
  assert.equal(r2.value.stage_est, null);
  assert.deepEqual(r2.value.issues.map((i) => i.code), ['P_APHID']);
  assert.equal(r2.value.issues[0].severity, 1, 'bad severity defaults to 1');
  assert.deepEqual(r2.value.issues[0].actions, [{ task: 'T_PRUNE' }]);
  assert.deepEqual(r2.value.delta.map((d) => d.op), ['remove'], 'only the one valid, de-duplicated op survives');
  assert.equal(r2.value.milestone_seen, null);
});

Deno.test('checkin: retake response is normalised, ok without health is rejected', () => {
  const r = validateCheckinOutput({ status: 'retake', reason: 'BLUR', hint_code: 'H_WHATEVER' }, known, checkinCtx);
  assert.ok(r.ok && r.value.status === 'retake' && r.value.hint_code === 'H_RETAKE_BLUR');
  assert.equal(validateCheckinOutput({ status: 'retake', reason: 'SAD' }, known, checkinCtx).ok, false);
  assert.equal(validateCheckinOutput({ status: 'ok', issues: [] }, known, checkinCtx).ok, false);
  assert.equal(validateCheckinOutput({ status: 'maybe' }, known, checkinCtx).ok, false);
});

Deno.test('checkin: delta capped, min confidence and bands', () => {
  const many = goodCheckin() as Record<string, unknown>;
  many.delta = Array.from({ length: 10 }, (_, i) => ({ op: 'shift', milestone: 'FLOWER', to: `2026-11-${String(i + 1).padStart(2, '0')}` }));
  const r = validateCheckinOutput(many, known, checkinCtx);
  assert.ok(r.ok && r.value.status === 'ok' && r.value.delta.length === 1, 'duplicates collapse');
  const ok = validateCheckinOutput(goodCheckin(), known, checkinCtx);
  assert.ok(ok.ok);
  if (ok.ok) assert.equal(minConfidence(ok.value as CheckinOutput), 0.58);
  assert.equal(confidenceBand(0.86), 'high');
  assert.equal(confidenceBand(0.58), 'medium');
  assert.equal(confidenceBand(0.3), 'low');
});

Deno.test('checkinTool schema: every top-level property is required (Gemini omits optional ones)', () => {
  const schema = checkinTool(known).input_schema as { required: string[]; properties: Record<string, unknown> };
  for (const k of Object.keys(schema.properties)) assert.ok(schema.required.includes(k), `${k} must be required`);
  assert.equal(schema.required.length, Object.keys(schema.properties).length);
});

Deno.test('checkin: retake output carrying health and nulls/empty arrays is accepted', () => {
  const r = validateCheckinOutput({
    status: 'retake', reason: 'BLUR', hint_code: 'H_RETAKE_BLUR',
    stage_est: null, health: { value: 'fair', confidence: 0.3 }, issues: [], milestone_seen: null, delta: [], reason_codes: [],
  }, known, checkinCtx);
  assert.ok(r.ok);
  if (r.ok) assert.equal(r.value.status, 'retake');
});

Deno.test('checkin: ok output with reason/hint_code/stage_est null and empty arrays is accepted', () => {
  const r = validateCheckinOutput({
    status: 'ok', reason: null, hint_code: null, stage_est: null, health: { value: 'good', confidence: 0.8 },
    issues: [], milestone_seen: null, delta: [], reason_codes: [],
  }, known, checkinCtx);
  assert.ok(r.ok);
  if (r.ok && r.value.status === 'ok') {
    assert.equal(r.value.stage_est, null);
    assert.equal(r.value.issues.length, 0);
  }
});
