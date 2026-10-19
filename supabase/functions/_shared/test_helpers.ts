// Test fixtures shared by the unit tests.
import type { KnownCodes } from './types.ts';

export const known: KnownCodes = {
  tasks: new Map([
    ['T_WATER', { window: 'morning', intervalDays: 2 }],
    ['T_FERT_ORGANIC', { window: 'morning', intervalDays: 14 }],
    ['T_PRUNE', { window: 'morning', intervalDays: 14 }],
    ['T_EGGSHELL_ADD', { window: 'morning', intervalDays: null }],
    ['T_SOW', { window: 'morning', intervalDays: null }],
    ['T_CHECKIN', { window: 'all_day', intervalDays: 5 }],
    ['T_PEST_CHECK', { window: 'afternoon', intervalDays: 4 }],
  ]),
  problems: new Set(['P_CALCIUM_LOW', 'P_APHID', 'P_YELLOW_LEAF_OVERWATER']),
  reasons: new Set(['R_HOT_SEASON', 'R_HEAT_33C', 'R_CHECKIN_CADENCE']),
  milestones: new Set(['SPROUT', 'HEIGHT_40', 'FLOWER']),
};

export const goodPlan = () => ({
  confidence: 0.86,
  stages: [
    { code: 'S1', day_from: 1, day_to: 7, milestone: 'SPROUT' },
    { code: 'S2', day_from: 8, day_to: 40, milestone: null },
  ],
  tasks: [
    { task: 'T_SOW', stage: 'S1', every_d: 0, window: 'morning', offset_d: 0, why: null },
    { task: 'T_WATER', stage: 'S1', every_d: 1, window: 'morning', why: 'R_HOT_SEASON' },
    { task: 'T_WATER', stage: 'S2', every_d: 2, window: 'morning', offset_d: 0, why: 'R_HOT_SEASON' },
    { task: 'T_FERT_ORGANIC', stage: 'S2', every_d: 14, window: 'morning', offset_d: 3, why: null },
  ],
  new_text: null,
});

export const checkinCtx = { stageCodes: new Set(['S1', 'S2', 'S3']), today: '2026-10-19' };

export const goodCheckin = () => ({
  status: 'ok',
  stage_est: { code: 'S3_late', confidence: 0.82 },
  health: { value: 'good', confidence: 0.8 },
  issues: [{ code: 'P_CALCIUM_LOW', confidence: 0.58, severity: 1, actions: [{ task: 'T_EGGSHELL_ADD' }] }],
  milestone_seen: { code: 'HEIGHT_40', confidence: 0.9 },
  delta: [
    { op: 'add', task: 'T_EGGSHELL_ADD', stage: 'S3' },
    { op: 'change_freq', task: 'T_WATER', every_d: 1, why: 'R_HEAT_33C' },
    { op: 'shift', milestone: 'FLOWER', to: '2026-10-25' },
  ],
  reason_codes: ['R_HOT_SEASON'],
});
