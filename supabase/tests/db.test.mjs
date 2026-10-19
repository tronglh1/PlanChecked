// Runs every migration + seed in PGlite and asserts schema, seed integrity, RLS, XP rules, quota, invites.
//   cd supabase/tests && npm i && npm test            (or PGLITE_ENTRY=/path/to/pglite/dist/index.js node --test db.test.mjs)
import test from 'node:test';
import assert from 'node:assert/strict';
import { bootDb, asUser, createUser, U } from './lib.mjs';

const db = await bootDb();
const q = async (sql, params) => (await db.query(sql, params)).rows;
const as = async (uid, sql, params) => (await asUser(db, uid, sql, params)).rows;
const rejects = (p, re) => assert.rejects(p, re);

await createUser(db, U.alice, 'alice@example.com', { full_name: 'Alice' });
await createUser(db, U.bob, 'bob@example.com');
await createUser(db, U.carol, 'carol@example.com');

let projectA;   // alice's tomato project, shared later
let planId;
const today = async (uid) => (await q('select public.user_local_date($1)::text as d', [uid]))[0].d;

test('profile row is auto-created on auth.users insert', async () => {
  const r = await q('select display_name, lang, level, xp_total from public.users where id = $1', [U.alice]);
  assert.equal(r[0].display_name, 'Alice');
  assert.equal(r[0].lang, 'vi');
  assert.equal(r[0].level, 1);
  const b = await q('select display_name from public.users where id = $1', [U.bob]);
  assert.equal(b[0].display_name, 'bob');
});

test('seed: 30 visible plants with stages, default tasks, problems', async () => {
  assert.equal((await q('select count(*)::int c from public.plants where not hidden'))[0].c, 30);
  assert.equal((await q('select count(*)::int c from public.plants where not hidden and "group"=\'rau_qua\''))[0].c, 17);
  const bad = await q(`select p.id from public.plants p
    where (select count(*) from public.plant_stages s where s.plant_id = p.id) < 3
       or (select count(*) from public.plant_default_tasks t where t.plant_id = p.id) < 8
       or (select count(*) from public.plant_problems pp where pp.plant_id = p.id) < 3`);
  assert.deepEqual(bad, []);
  // stage day ranges are contiguous and start at 1
  const gaps = await q(`select plant_id from (
      select plant_id, day_min, lag(day_max) over (partition by plant_id order by "order") as prev_max from public.plant_stages) x
    where (prev_max is null and day_min <> 1) or (prev_max is not null and day_min <> prev_max + 1)`);
  assert.deepEqual(gaps, []);
  // default tasks stay inside their stage
  const off = await q(`select t.plant_id, t.task_code from public.plant_default_tasks t join public.plant_stages s
      on s.plant_id = t.plant_id and s.code = t.stage_code where t.offset_d > s.day_max - s.day_min`);
  assert.deepEqual(off, []);
});

test('seed: every code has VN + EN texts (name, steps, why) and no dose-like text', async () => {
  const need = async (table, kind, fields) => {
    const rows = await q(`select code from public.${table}`);
    for (const { code } of rows) for (const lang of ['vi', 'en']) for (const field of fields) {
      const r = await q('select 1 from public.text_templates where kind=$1 and code=$2 and lang=$3 and field=$4', [kind, code, lang, field]);
      assert.equal(r.length, 1, `missing ${kind}/${code}/${lang}/${field}`);
    }
  };
  await need('task_codes', 'task', ['name', 'steps', 'why']);
  await need('problem_codes', 'problem', ['name', 'steps', 'why']);
  await need('reason_codes', 'reason', ['name', 'why']);
  await need('milestone_codes', 'milestone', ['name']);
  for (const tag of ['LEAF_YELLOW', 'WILT', 'PESTS', 'SPOTS']) {
    assert.equal((await q("select 1 from public.text_templates where kind='tag' and code=$1 and field='name'", [tag])).length, 2);
  }
  const dose = await q(`select kind, code, lang, field from public.text_templates
    where body ~* '[0-9]\\s*(ml|mg|g|kg|l|%|ppm|gram|tsp|tbsp)([^a-zà-ỹ]|$)'`);
  assert.deepEqual(dose, []);
  // every task_code referenced by plant templates / problem actions exists
  const orphan = await q(`select distinct a from public.problem_codes, unnest(safe_actions) a where a not in (select code from public.task_codes)`);
  assert.deepEqual(orphan, []);
});

test('vn_normalize / search_plants are diacritic-free', async () => {
  assert.equal((await q("select public.vn_search_key('Húng Quế Đà Lạt') k"))[0].k, 'hung que da lat');
  const a = await as(U.alice, "select id from public.search_plants('hung que')");
  assert.equal(a[0].id, 'basil');
  const b = await as(U.alice, "select id from public.search_plants('Cà chua')");
  assert.ok(b.some((r) => r.id === 'tomato_cherry'));
  const c = await as(U.alice, "select id from public.search_plants('', 'cay_canh', 50)");
  assert.equal(c.length, 13);
});

test('content tables are readable by authenticated users but not writable', async () => {
  assert.equal((await as(U.bob, 'select count(*)::int c from public.plants'))[0].c, 32);
  assert.ok((await as(U.bob, 'select count(*)::int c from public.text_templates'))[0].c > 400);
  await rejects(as(U.bob, "update public.plants set name_vi='x'"), /permission denied/);
  await rejects(as(U.bob, "insert into public.text_templates(kind,code,lang,field,body) values ('task','X','vi','name','y')"), /permission denied/);
});

test('fallback_plan builds a plan from codes and honours start_stage', async () => {
  const full = (await q("select public.fallback_plan('tomato_cherry','seed') p"))[0].p;
  assert.equal(full.stages.length, 6);
  assert.equal(full.stages[0].day_from, 1);
  const seedling = (await q("select public.fallback_plan('tomato_cherry','seedling') p"))[0].p;
  assert.equal(seedling.stages.length, 5);
  assert.equal(seedling.stages[0].day_from, 1);
  assert.ok(seedling.tasks.every((t) => t.task.startsWith('T_')));
});

test('RLS: user A cannot see user B project; B cannot write A rows', async () => {
  const d = await today(U.alice);
  const r = await as(U.alice, `insert into public.projects(owner_id, plant_id, name, start_date, start_stage)
      values ($1,'tomato_cherry','Cà chua ban công',$2,'seed') returning id`, [U.alice, d]);
  projectA = r[0].id;
  const plan = (await q("select public.fallback_plan('tomato_cherry','seed') p"))[0].p;
  planId = (await q("select public.create_draft_plan($1,'fallback',0.5,'k','m',$2::jsonb,$3::jsonb) id",
    [projectA, JSON.stringify(plan.stages), JSON.stringify(plan.tasks)]))[0].id;
  assert.equal((await as(U.alice, 'select count(*)::int c from public.projects'))[0].c, 1);
  assert.equal((await as(U.bob, 'select count(*)::int c from public.projects'))[0].c, 0);
  assert.equal((await as(U.bob, 'select count(*)::int c from public.plans'))[0].c, 0);
  assert.equal((await as(U.bob, 'select count(*)::int c from public.tasks'))[0].c, 0);
  assert.equal((await as(U.bob, 'select count(*)::int c from public.users'))[0].c, 1);   // only self
  assert.equal((await as(U.bob, 'update public.projects set name=\'hacked\' returning id')).length, 0);
  await rejects(as(U.bob, 'insert into public.projects(owner_id, plant_id, name) values ($1,\'basil\',\'x\')', [U.alice]), /row-level security/);
});

test('plan approval materializes occurrences visible to the owner only', async () => {
  const n = (await as(U.alice, 'select public.approve_plan($1) n', [planId]))[0].n;
  assert.ok(n > 0);
  const occ = await as(U.alice, 'select count(*)::int c from public.task_occurrences');
  assert.ok(occ[0].c > 0);
  assert.equal((await as(U.bob, 'select count(*)::int c from public.task_occurrences'))[0].c, 0);
  await rejects(as(U.bob, 'select public.approve_plan($1)', [planId]), /not_allowed/);
});

let inviteCode;
test('household: create, invite by code, accept; member sees shared project', async () => {
  const h = (await as(U.alice, "select * from public.create_household('Nhà mình')"))[0];
  await rejects(as(U.alice, "select * from public.create_household('Again')"), /already_in_household/);
  await rejects(as(U.bob, "select * from public.create_invite('code')"), /not_household_owner/);
  const inv = (await as(U.alice, "select * from public.create_invite('code', null, 'member')"))[0];
  assert.match(inv.code, /^VUON-\d{4}$/);
  inviteCode = inv.code;
  // project becomes shared (owner role may share)
  await as(U.alice, 'update public.projects set household_id = $1 where id = $2', [h.id, projectA]);
  assert.equal((await as(U.bob, 'select count(*)::int c from public.projects'))[0].c, 0, 'not visible before joining');

  assert.deepEqual((await as(U.bob, "select public.accept_invite('VUON-0000') r"))[0].r.error, 'invite_invalid');
  const ok = (await as(U.bob, 'select public.accept_invite($1) r', [inviteCode.toLowerCase()]))[0].r;
  assert.equal(ok.ok, true);
  assert.equal((await as(U.carol, 'select public.accept_invite($1) r', [inviteCode]))[0].r.error, 'invite_invalid', 'single use');
  assert.equal((await as(U.bob, 'select public.accept_invite($1) r', [inviteCode]))[0].r.error, 'already_in_household');

  assert.equal((await as(U.bob, 'select count(*)::int c from public.projects'))[0].c, 1);
  assert.ok((await as(U.bob, 'select count(*)::int c from public.tasks'))[0].c > 0);
  assert.equal((await as(U.carol, 'select count(*)::int c from public.projects'))[0].c, 0, 'outsider still blind');
  assert.equal((await as(U.bob, 'select count(*)::int c from public.household_members'))[0].c, 2);
  assert.equal((await as(U.carol, 'select count(*)::int c from public.household_members'))[0].c, 0);
  const prof = await as(U.bob, 'select id from public.member_profiles order by id');
  assert.equal(prof.length, 2);
});

test('Member can Done tasks but cannot edit tasks, assign, share or invite', async () => {
  await rejects(as(U.bob, "update public.tasks set assignee_id = $1", [U.bob]).then((r) => { if (!r.length) throw new Error('no rows'); }), /no rows/);
  await rejects(as(U.bob, "insert into public.tasks(project_id, task_code) values ($1,'T_WATER')", [projectA]), /row-level security/);
  await rejects(as(U.bob, "select * from public.create_invite('code')"), /not_household_owner/);
  await rejects(as(U.bob, "delete from public.projects where id=$1 returning id", [projectA]).then((r) => { if (!r.length) throw new Error('no rows'); }), /no rows/);
  const d = await today(U.bob);
  const t = (await as(U.bob, `select t.id from public.tasks t where t.task_code='T_WATER' limit 1`))[0].id;
  const log = await as(U.bob, "insert into public.task_logs(task_id, occurrence_date, user_id, action) values ($1,$2,$3,'done') returning id", [t, d, U.bob]);
  assert.equal(log.length, 1);
  assert.equal((await as(U.alice, 'select count(*)::int c from public.household_activity'))[0].c >= 1, true);
  // Owner assigns
  const r = await as(U.alice, "update public.tasks set assignee_id=$1 where id=$2 returning id", [U.bob, t]);
  assert.equal(r.length, 1);
});

test('XP: +10 on-time, once per occurrence, clients cannot edit xp_total', async () => {
  const d = await today(U.alice);
  const t = (await as(U.alice, `select id from public.tasks where project_id=$1 and task_code='T_SOW' limit 1`, [projectA]))[0].id;
  const before = (await q('select xp_total from public.users where id=$1', [U.alice]))[0].xp_total;
  await as(U.alice, "insert into public.task_logs(task_id, occurrence_date, action) values ($1,$2,'done')", [t, d]);
  assert.equal((await q('select xp_total from public.users where id=$1', [U.alice]))[0].xp_total, before + 10);
  await rejects(as(U.alice, "insert into public.task_logs(task_id, occurrence_date, action) values ($1,$2,'done')", [t, d]), /duplicate key/);
  assert.equal((await q('select xp_total from public.users where id=$1', [U.alice]))[0].xp_total, before + 10);
  await as(U.alice, 'update public.users set xp_total = 99999, level = 6 where id = $1', [U.alice]);
  assert.equal((await q('select xp_total from public.users where id=$1', [U.alice]))[0].xp_total, before + 10);
  // future occurrence is rejected
  await rejects(as(U.alice, "insert into public.task_logs(task_id, occurrence_date, action) values ($1, ($2::date + 3), 'done')", [t, d]), /future_occurrence/);
  // forged client timestamp in the future is clamped to now
  const w = (await as(U.alice, `select id from public.tasks where project_id=$1 and task_code='T_WATER' limit 1`, [projectA]))[0].id;
  const l = await as(U.alice, "insert into public.task_logs(task_id, occurrence_date, action, acted_at) values ($1,$2,'done', now() + interval '2 days') returning (acted_at <= now()) ok", [w, d]);
  assert.equal(l[0].ok, true);
  assert.ok((await q("select count(*)::int c from public.user_badges where user_id=$1 and badge_code='FIRST_TASK'", [U.alice]))[0].c === 1);
});

test('XP: ordinary XP is capped at 150 per day', async () => {
  const d = await today(U.carol);
  const p = (await as(U.carol, "insert into public.projects(owner_id, plant_id, name, start_date) values ($1,'basil','Basil',$2) returning id", [U.carol, d]))[0].id;
  const ids = [];
  for (let i = 0; i < 20; i++) {
    ids.push((await as(U.carol, "insert into public.tasks(project_id, task_code, frequency) values ($1,'T_WATER','daily') returning id", [p]))[0].id);
  }
  for (const id of ids) await as(U.carol, "insert into public.task_logs(task_id, occurrence_date, action) values ($1,$2,'done')", [id, d]);
  assert.equal((await q('select xp_total from public.users where id=$1', [U.carol]))[0].xp_total, 150);
  assert.equal((await q("select coalesce(sum(amount),0)::int s from public.xp_events where user_id=$1", [U.carol]))[0].s, 150);
});

test('XP: check-in +30 only after server analysis; retake none; milestone needs a photo-confirmed check-in', async () => {
  const xp = async () => (await q('select xp_total from public.users where id=$1', [U.bob]))[0].xp_total;
  // bob (member) checks in on alice's shared project; he tries to forge status
  const c = (await as(U.bob, "insert into public.checkins(project_id, user_id, status, shots, tags) values ($1,$2,'analyzed','[]','{LEAF_YELLOW}') returning id, status", [projectA, U.bob]))[0];
  assert.equal(c.status, 'pending', 'client cannot pre-set status');
  const base = await xp();
  await rejects(as(U.bob, "update public.checkins set status='analyzed' where id=$1", [c.id]), /permission denied/);
  await q("update public.checkins set status='retake', counts_toward_quota=false where id=$1", [c.id]);
  assert.equal(await xp(), base);
  const c2 = (await as(U.bob, "insert into public.checkins(project_id, shots) values ($1,'[]') returning id", [projectA]))[0].id;
  await q("update public.checkins set status='analyzed', model='claude-haiku-5-5' where id=$1", [c2]);   // service role path
  assert.equal(await xp(), base + 30);
  // second check-in same project same day: no more XP
  const c3 = (await as(U.bob, "insert into public.checkins(project_id, shots) values ($1,'[]') returning id", [projectA]))[0].id;
  await q("update public.checkins set status='analyzed' where id=$1", [c3]);
  assert.equal(await xp(), base + 30);

  // manual milestone claim never gives XP
  await as(U.alice, "insert into public.milestones_reached(project_id, milestone_code, confirmed_by) values ($1,'SPROUT','user')", [projectA]);
  assert.equal(await xp(), base + 30);
  await rejects(as(U.alice, "insert into public.milestones_reached(project_id, milestone_code, confirmed_by, checkin_id) values ($1,'FLOWER','user',$2)", [projectA, c2]), /row-level security/);
  // server confirms a milestone with the analyzed check-in: +100 to the photographer
  await q("insert into public.milestones_reached(project_id, milestone_code, confirmed_by, checkin_id) values ($1,'TRUE_LEAVES','ai',$2)", [projectA, c2]);
  assert.equal(await xp(), base + 130);
  // clients cannot write xp_events
  await rejects(as(U.bob, "insert into public.xp_events(user_id, source, ref_id, amount, day) values ($1,'checkin',gen_random_uuid(),500,current_date)", [U.bob]), /permission denied/);
});

test('apply_checkin_changes applies only accepted items', async () => {
  const c = (await as(U.alice, "insert into public.checkins(project_id, shots) values ($1,'[]') returning id", [projectA]))[0].id;
  await q("update public.checkins set status='analyzed' where id=$1", [c]);
  const stage = (await q("select s.code from public.stages s where s.plan_id=$1 and s.idx=3", [planId]))[0].code;
  const ch1 = (await q("insert into public.checkin_changes(checkin_id, change_kind, payload) values ($1,'add',$2) returning id",
    [c, JSON.stringify({ op: 'add', task: 'T_EGGSHELL_ADD', stage })]))[0].id;
  const ch2 = (await q("insert into public.checkin_changes(checkin_id, change_kind, payload) values ($1,'change_freq',$2) returning id",
    [c, JSON.stringify({ op: 'change_freq', task: 'T_WATER', every_d: 1 })]))[0].id;
  const n = (await as(U.alice, 'select public.apply_checkin_changes($1, $2::uuid[]) n', [c, [ch1]]))[0].n;
  assert.equal(n, 1);
  assert.equal((await q("select count(*)::int c from public.tasks where project_id=$1 and task_code='T_EGGSHELL_ADD'", [projectA]))[0].c, 1);
  assert.equal((await q('select accepted from public.checkin_changes where id=$1', [ch2]))[0].accepted, false);
  assert.equal((await q('select status from public.checkins where id=$1', [c]))[0].status, 'approved');
});

test('consume_ai_quota enforces the daily cap and counts per user', async () => {
  for (let i = 1; i <= 5; i++) {
    const r = (await as(U.bob, "select public.consume_ai_quota('plan') r"))[0].r;
    assert.equal(r.used, i);
  }
  await rejects(as(U.bob, "select public.consume_ai_quota('plan')"), /ai_quota_exceeded/);
  assert.equal((await as(U.alice, "select public.consume_ai_quota('plan') r"))[0].r.used, 1);
  await q("select public.ai_quota_refund($1,'plan')", [U.bob]);
  assert.equal((await as(U.bob, "select public.consume_ai_quota('plan') r"))[0].r.used, 5);
  await rejects(as(U.bob, "select public.ai_quota_refund($1,'plan')", [U.bob]), /permission denied/);
  await rejects(as(U.bob, "update public.ai_usage set count = 0"), /permission denied/);
  assert.equal((await as(U.bob, 'select public.get_ai_quota() r'))[0].r.plan.cap, 5);
});

test('storage: checkin photos readable by project members only', async () => {
  const path = `${U.alice}/${projectA}/11111111-1111-4111-8111-111111111111.jpg`;
  await asUser(db, U.alice, "insert into storage.objects(bucket_id, name, owner_id) values ('checkins',$1,$2)", [path, U.alice]);
  assert.equal((await as(U.alice, "select count(*)::int c from storage.objects where bucket_id='checkins'"))[0].c, 1);
  assert.equal((await as(U.bob, "select count(*)::int c from storage.objects where bucket_id='checkins'"))[0].c, 1, 'household member');
  assert.equal((await as(U.carol, "select count(*)::int c from storage.objects where bucket_id='checkins'"))[0].c, 0);
  await rejects(as(U.carol, "insert into storage.objects(bucket_id, name, owner_id) values ('checkins',$1,$2)", [`${U.carol}/${projectA}/22222222-2222-4222-8222-222222222222.jpg`, U.carol]), /row-level security/);
  await rejects(as(U.alice, "insert into storage.objects(bucket_id, name, owner_id) values ('checkins',$1,$2)", [`${U.alice}/${projectA}/x.png`, U.alice]), /row-level security/);
  assert.equal((await q("select public from storage.buckets where id='checkins'"))[0].public, false);
});

test('streak, leave_household transfers ownership, delete_my_account removes data', async () => {
  assert.ok((await as(U.alice, 'select public.my_streak() s'))[0].s >= 1);
  await as(U.alice, 'select public.delete_my_account()');
  assert.equal((await q('select count(*)::int c from public.users where id=$1', [U.alice]))[0].c, 0);
  assert.equal((await q('select count(*)::int c from auth.users where id=$1', [U.alice]))[0].c, 0);
  assert.equal((await q('select count(*)::int c from public.projects where owner_id=$1', [U.alice]))[0].c, 0);
  const m = await q('select role from public.household_members where user_id=$1', [U.bob]);
  assert.equal(m[0].role, 'owner', 'ownership passed to the remaining member');
  assert.equal((await as(U.bob, 'select count(*)::int c from public.projects'))[0].c, 0);
});
