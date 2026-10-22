import assert from 'node:assert/strict';
import {
  adherence14d, buildPlanContext, buildPlantCard, buildProjectCard, buildUserCard, daysBetween, localDate, seasonFor,
  shouldSkipRecent, skippedSummary, slugify, stageForDay, templateKey,
} from './context.ts';
import { isValidShotPath, looksLikeJpeg, parseShots, toBase64 } from './image.ts';
import { inviteLink } from './invite.ts';

Deno.test('template key matches the spec example format', () => {
  assert.equal(templateKey({ plantId: 'basil', zone: 'VN_S', season: 'rainy', startStage: 'seedling', space: 'balcony', sunLevel: 3 }),
    'basil|VN_S|rainy|seedling|balcony|sun3');
});

Deno.test('season and local date', () => {
  assert.equal(seasonFor('VN_S', '2026-10-13'), 'rainy');
  assert.equal(seasonFor('VN_S', '2026-12-01'), 'dry');
  assert.equal(seasonFor('VN_N', '2026-07-01'), 'hot');
  assert.equal(seasonFor('VN_C', '2026-01-01'), 'cool');
  // 2026-10-18 18:00 UTC is already 19 Oct in Ho Chi Minh (UTC+7)
  assert.equal(localDate('Asia/Ho_Chi_Minh', new Date('2026-10-18T18:00:00Z')), '2026-10-19');
  assert.equal(localDate('nonsense/zone', new Date('2026-10-18T18:00:00Z')), '2026-10-19');
  assert.equal(daysBetween('2026-10-13', '2026-10-19'), 6);
});

Deno.test('slugify strips Vietnamese diacritics', () => {
  assert.equal(slugify('Rau Đắng Lá Lớn'), 'rau_dang_la_lon');
  assert.equal(slugify('!!!'), 'plant');
});

Deno.test('plant / user / plan context are compact and typed', () => {
  const plant = buildPlantCard({ id: 'tomato_cherry', group: 'rau_qua', name_vi: 'Cà chua bi', name_en: 'Cherry tomato', days_to_harvest: 85, toxic_child: false, toxic_pet: true },
    'x', 'rau_qua', [{ code: 'S1', day_min: 1, day_max: 7, milestone_code: 'SPROUT' }], ['P_APHID', 'P_A', 'P_B', 'P_C', 'P_D', 'P_E', 'P_F']);
  assert.equal(plant.known, true);
  assert.equal(plant.problems_top.length, 6);
  assert.deepEqual(plant.stages[0], { code: 'S1', from: 1, to: 7, ms: 'SPROUT' });
  const unknown = buildPlantCard(null, 'Rau đắng', 'rau_qua', [], []);
  assert.equal(unknown.known, false);
  assert.equal(unknown.name, 'Rau đắng');
  const user = buildUserCard({ experience: 'pro', lang: 'en' });
  assert.deepEqual(user, { experience: 'pro', time_budget: '10-30p', prefer_organic: true, lang: 'en' });
  assert.equal(buildUserCard({ experience: 'wizard' }).experience, 'new');
  const ctx = buildPlanContext({ startDate: '2026-10-13', startStage: 'seedling', zone: 'VN_S', season: 'rainy', space: 'balcony', sunLevel: 3, pot: 'plastic_20l', watering: 'manual', hasChildren: false, hasPets: true, lessons: ['a', 'b', 'c', 'd'] }, plant, user);
  assert.equal(ctx.lessons.length, 3);
  assert.equal(ctx.household.has_pets, true);
  assert.equal(ctx.context.sun_level, 3);
});

Deno.test('adherence over 14 days ignores today\'s pending tasks', () => {
  const occ = [
    { due_date: '2026-10-19', state: 'pending' },
    { due_date: '2026-10-18', state: 'done' },
    { due_date: '2026-10-17', state: 'done' },
    { due_date: '2026-10-16', state: 'skipped' },
    { due_date: '2026-10-15', state: 'pending' },
    { due_date: '2026-09-01', state: 'skipped' },
  ];
  assert.equal(adherence14d(occ, '2026-10-19'), 0.5);
  assert.equal(adherence14d([], '2026-10-19'), null);
});

Deno.test('skipped summary groups repeats', () => {
  assert.deepEqual(skippedSummary(['T_FERT_ORGANIC', 'T_WATER', 'T_FERT_ORGANIC']), ['T_FERT_ORGANIC x2', 'T_WATER']);
});

Deno.test('stage for day', () => {
  const st = [{ code: 'S1', day_from: 1, day_to: 7 }, { code: 'S2', day_from: 8, day_to: 30 }];
  assert.equal(stageForDay(st, 3), 'S1');
  assert.equal(stageForDay(st, 8), 'S2');
  assert.equal(stageForDay(st, 99), 'S2');
  assert.equal(stageForDay([], 5), 'S1');
});

Deno.test('project card keeps last 3 check-ins and summarizes the rest', () => {
  const ck = (d: number, health: string, issues: string[] = []) => ({ created_day: d, status: 'analyzed', ai_result: { health: { value: health }, issues: issues.map((c) => ({ code: c, severity: 2 })) } });
  const card = buildProjectCard({
    plantId: 'tomato_cherry', day: 38, stage: 'S3', zone: 'VN_S', season: 'rainy', space: 'balcony', sun: 3, pot: 'plastic_20l', water: 'manual',
    occurrences: [{ due_date: '2026-10-18', state: 'done' }], today: '2026-10-19', skipCodes: ['T_FERT_ORGANIC', 'T_FERT_ORGANIC'],
    checkins: [ck(36, 'fair', ['P_APHID']), ck(30, 'good'), ck(23, 'good'), ck(15, 'fair', ['P_APHID']), ck(8, 'good', ['P_APHID', 'P_ROOT_ROT'])],
    changes: [{ change_kind: 'add', payload: { task: 'T_EGGSHELL_ADD' } }, { change_kind: 'shift', payload: { milestone: 'FLOWER' } }],
  });
  assert.deepEqual(card.checkins.map((c) => c.d), [23, 30, 36], 'oldest first, only three');
  assert.deepEqual(card.active_issues, [{ code: 'P_APHID', sev: 2 }]);
  assert.deepEqual(card.skipped, ['T_FERT_ORGANIC x2']);
  assert.deepEqual(card.applied_changes, ['T_EGGSHELL_ADD:add', 'FLOWER:shift']);
  assert.match(card.history_summary!, /^2 earlier check-ins; issues: P_APHIDx2, P_ROOT_ROTx1$/);
  assert.ok(JSON.stringify(card).length < 1600, 'stays compact (~300-500 tokens)');
});

Deno.test('24h skip rule', () => {
  const now = new Date('2026-10-19T10:00:00Z');
  assert.equal(shouldSkipRecent('2026-10-19T02:00:00Z', ['WILT'], ['WILT'], now), true);
  assert.equal(shouldSkipRecent('2026-10-19T02:00:00Z', ['WILT'], [], now), true);
  assert.equal(shouldSkipRecent('2026-10-19T02:00:00Z', ['WILT'], ['PESTS'], now), false, 'new tag => analyze');
  assert.equal(shouldSkipRecent('2026-10-17T02:00:00Z', [], [], now), false, 'older than 24h');
  assert.equal(shouldSkipRecent(null, [], [], now), false);
});

Deno.test('shot paths must belong to the project and an allowed folder', () => {
  const u = '11111111-1111-4111-8111-111111111111', p = '22222222-2222-4222-8222-222222222222', f = '33333333-3333-4333-8333-333333333333';
  assert.equal(isValidShotPath(`${u}/${p}/${f}.jpg`, p, [u]), true);
  assert.equal(isValidShotPath(`${u}/${p}/${f}.png`, p, [u]), false);
  assert.equal(isValidShotPath(`${f}/${p}/${f}.jpg`, p, [u]), false, 'foreign folder');
  assert.equal(isValidShotPath(`${u}/${f}/${f}.jpg`, p, [u]), false, 'other project');
  assert.equal(isValidShotPath(`../${p}/${f}.jpg`, p, [u]), false);
  const shots = parseShots([{ shot: 'whole_plant', path: `${u}/${p}/${f}.jpg` }, { shot: 'selfie', path: `${u}/${p}/${f}.jpg` }, { shot: 'close_leaf', path: 'x' }], p, [u]);
  assert.equal(shots.length, 1);
});

Deno.test('image helpers and invite link', () => {
  assert.equal(looksLikeJpeg(new Uint8Array([0xff, 0xd8, 0xff, 0xe0])), true);
  assert.equal(looksLikeJpeg(new Uint8Array([0x89, 0x50, 0x4e, 0x47])), false);
  assert.equal(toBase64(new Uint8Array([104, 105])), 'aGk=');
  assert.equal(inviteLink('https://vuonnha.app/i/', 'VUON-1234'), 'https://vuonnha.app/i/VUON-1234');
});
