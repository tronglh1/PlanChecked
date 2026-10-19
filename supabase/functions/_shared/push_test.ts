import assert from 'node:assert/strict';
import type { SendResult } from './fcm.ts';
import {
  handleEvent, inQuietHours, type Lang, type PrefRow, type PushKind, type PushStore, type Recipient, type Sender,
} from './push.ts';

const A = 'aaaaaaaa-0000-4000-8000-000000000001'; // actor
const B = 'bbbbbbbb-0000-4000-8000-000000000002';
const C = 'cccccccc-0000-4000-8000-000000000003';
const H = 'dddddddd-0000-4000-8000-0000000000aa';

interface World {
  users: Record<string, Partial<Recipient>>;
  prefs: Record<string, Partial<Record<PushKind, PrefRow>>>;
  tokens: { user_id: string; token: string }[];
  members: string[];
}

function makeStore(w: Partial<World> = {}) {
  const world: World = {
    users: { [A]: {}, [B]: {}, [C]: { lang: 'en' } },
    prefs: {},
    tokens: [{ user_id: B, token: 'tokB1' }, { user_id: B, token: 'tokB2' }, { user_id: C, token: 'tokC' }],
    members: [A, B, C],
    ...w,
  };
  const deleted: string[] = [];
  const store: PushStore = {
    users: (ids) =>
      Promise.resolve(ids.filter((i) => world.users[i]).map((id): Recipient => ({
        id, lang: 'vi', timezone: 'Asia/Ho_Chi_Minh', quiet_start: null, quiet_end: null, ...world.users[id],
      }))),
    prefs: (ids, type) => {
      const m = new Map<string, PrefRow>();
      for (const i of ids) if (world.prefs[i]?.[type]) m.set(i, world.prefs[i][type]!);
      return Promise.resolve(m);
    },
    tokens: (ids) => Promise.resolve(world.tokens.filter((t) => ids.includes(t.user_id) && !deleted.includes(t.token))),
    deleteToken: (t) => {
      deleted.push(t);
      return Promise.resolve();
    },
    householdMembers: () => Promise.resolve(world.members),
    displayName: (id) => Promise.resolve(id === A ? 'Lan' : null),
    projectName: () => Promise.resolve('Cà chua ban công'),
    label: (kind, code, lang: Lang) =>
      Promise.resolve(kind === 'task' ? (lang === 'vi' ? 'Tưới gốc' : 'Water the base') : kind === 'badge' ? (lang === 'vi' ? 'Hạt giống đầu tiên' : 'First seed') : null),
    taskInfo: () => Promise.resolve({ task_code: 'T_WATER', project_id: 'p1' }),
  };
  return { store, deleted };
}

function makeSender(result: (token: string) => SendResult = () => ({ status: 'ok' })) {
  const sent: { token: string; title: string; body: string; data?: Record<string, string> }[] = [];
  const sender: Sender = {
    send: (m) => {
      sent.push({ token: m.token, title: m.notification.title, body: m.notification.body, data: m.data });
      return Promise.resolve(result(m.token));
    },
  };
  return { sender, sent };
}

const noon = new Date('2026-10-19T05:00:00Z'); // 12:00 in Ho Chi Minh
const night = new Date('2026-10-19T16:30:00Z'); // 23:30 in Ho Chi Minh

const assignEv = (to = B, from: string | null = null) => ({
  type: 'UPDATE', table: 'tasks', actor_id: A,
  record: { id: 't1', task_code: 'T_WATER', project_id: 'p1', assignee_id: to },
  old_record: { id: 't1', assignee_id: from },
});

Deno.test('assignment: push to the new assignee in their language, every token', async () => {
  const { store } = makeStore();
  const { sender, sent } = makeSender();
  const s = await handleEvent(assignEv(), store, sender, noon);
  assert.equal(s?.kind, 'assignment');
  assert.equal(s?.sent, 2);
  assert.deepEqual(sent.map((x) => x.token), ['tokB1', 'tokB2']);
  assert.equal(sent[0].title, 'Việc mới cho bạn');
  assert.equal(sent[0].body, 'Lan giao bạn: Tưới gốc (Cà chua ban công)');
  assert.deepEqual(sent[0].data, { type: 'assignment', route: '/task/t1' });

  const en = makeSender();
  await handleEvent(assignEv(C), store, en.sender, noon);
  assert.equal(en.sent[0].title, 'New task for you');
  assert.equal(en.sent[0].body, 'Lan assigned you: Water the base (Cà chua ban công)');
});

Deno.test('assignment: unchanged, cleared or self-assigned tasks send nothing', async () => {
  const { store } = makeStore();
  const { sender, sent } = makeSender();
  assert.equal(await handleEvent(assignEv(B, B), store, sender, noon), null, 'same assignee');
  assert.equal(await handleEvent({ ...assignEv(), record: { id: 't1', assignee_id: null } }, store, sender, noon), null);
  assert.equal(await handleEvent(assignEv(A), store, sender, noon), null, 'actor assigned themselves');
  assert.equal(await handleEvent({ table: 'something_else', record: { id: 1 } }, store, sender, noon), null);
  assert.equal(sent.length, 0);
});

Deno.test('achievement: badge name, route to the achievements tab', async () => {
  const { store } = makeStore();
  const { sender, sent } = makeSender();
  const s = await handleEvent({ type: 'INSERT', table: 'user_badges', record: { user_id: B, badge_code: 'FIRST_SEED' } }, store, sender, noon);
  assert.equal(s?.sent, 2);
  assert.equal(sent[0].title, 'Huy hiệu mới');
  assert.equal(sent[0].body, 'Bạn vừa nhận huy hiệu "Hạt giống đầu tiên"');
  assert.equal(sent[0].data?.route, '/achievements');
});

Deno.test('household activity: everyone except the actor', async () => {
  const { store } = makeStore();
  const { sender, sent } = makeSender();
  const s = await handleEvent({
    type: 'INSERT', table: 'household_activity', actor_id: A,
    record: { id: 'x', household_id: H, actor_id: A, kind: 'task_done', project_id: 'p1', payload: { task_code: 'T_WATER' } },
  }, store, sender, noon);
  assert.equal(s?.recipients, 2);
  assert.deepEqual([...new Set(sent.map((x) => x.token))].sort(), ['tokB1', 'tokB2', 'tokC']);
  assert.equal(sent.find((x) => x.token === 'tokB1')!.body, 'Lan đã hoàn thành Tưới gốc');
  assert.equal(sent.find((x) => x.token === 'tokC')!.body, 'Lan completed Water the base');
  assert.ok(!sent.some((x) => x.token === 'tokA'));
});

Deno.test('prefs: a disabled type is skipped for that user only', async () => {
  const { store } = makeStore({ prefs: { [B]: { household_activity: { enabled: false, quiet_start: null, quiet_end: null } } } });
  const { sender, sent } = makeSender();
  const s = await handleEvent({
    table: 'household_activity', actor_id: A,
    record: { household_id: H, actor_id: A, kind: 'checkin', project_id: 'p1', payload: {} },
  }, store, sender, noon);
  assert.equal(s?.skipped.disabled, 1);
  assert.deepEqual(sent.map((x) => x.token), ['tokC']);
  // another type stays on for the same user
  const s2 = await handleEvent({ table: 'user_badges', record: { user_id: B, badge_code: 'X' } }, store, sender, noon);
  assert.equal(s2?.sent, 2);
});

Deno.test('quiet hours: wrap-around window, per-type override, user timezone', async () => {
  assert.equal(inQuietHours('22:00:00', '06:30:00', 'Asia/Ho_Chi_Minh', night), true);
  assert.equal(inQuietHours('22:00', '06:30', 'Asia/Ho_Chi_Minh', noon), false);
  assert.equal(inQuietHours('13:00', '14:00', 'Asia/Ho_Chi_Minh', noon), false);
  assert.equal(inQuietHours('11:00', '13:00', 'Asia/Ho_Chi_Minh', noon), true);
  assert.equal(inQuietHours('22:00', '22:00', 'Asia/Ho_Chi_Minh', night), false, 'empty window');
  assert.equal(inQuietHours(null, '06:00', 'Asia/Ho_Chi_Minh', night), false);
  // same instant, other timezone: 16:30Z is 09:30 in Los Angeles (UTC-7)
  assert.equal(inQuietHours('22:00', '06:30', 'America/Los_Angeles', night), false);

  const { store } = makeStore({ users: { [B]: { quiet_start: '22:00:00', quiet_end: '06:30:00' }, [C]: { lang: 'en' } } });
  const { sender, sent } = makeSender();
  const s = await handleEvent({ table: 'user_badges', record: { user_id: B, badge_code: 'X' } }, store, sender, night);
  assert.equal(s?.skipped.quiet, 1);
  assert.equal(sent.length, 0);

  // a per-type override beats the profile window
  const o = makeStore({
    users: { [B]: { quiet_start: '22:00:00', quiet_end: '06:30:00' } },
    prefs: { [B]: { achievement: { enabled: true, quiet_start: '01:00:00', quiet_end: '02:00:00' } } },
  });
  const s2 = await handleEvent({ table: 'user_badges', record: { user_id: B, badge_code: 'X' } }, o.store, sender, night);
  assert.equal(s2?.sent, 2);
});

Deno.test('tokens FCM reports UNREGISTERED are deleted; other failures are kept', async () => {
  const { store, deleted } = makeStore();
  const { sender } = makeSender((t) => (t === 'tokB1' ? { status: 'unregistered' } : t === 'tokB2' ? { status: 'error', httpStatus: 500, detail: 'x' } : { status: 'ok' }));
  const s = await handleEvent({ table: 'user_badges', record: { user_id: B, badge_code: 'X' } }, store, sender, noon);
  assert.deepEqual(deleted, ['tokB1']);
  assert.equal(s?.removed_tokens, 1);
  assert.equal(s?.errors, 1);
  assert.equal(s?.sent, 0);
});

Deno.test('a sender that throws is counted as an error, not a crash; users without tokens are skipped', async () => {
  const { store } = makeStore({ tokens: [{ user_id: B, token: 'tokB1' }] });
  const sender: Sender = { send: () => Promise.reject(new Error('network')) };
  const s = await handleEvent({ table: 'user_badges', record: { user_id: B, badge_code: 'X' } }, store, sender, noon);
  assert.equal(s?.errors, 1);
  const none = await handleEvent({ table: 'user_badges', record: { user_id: C, badge_code: 'X' } }, makeStore({ tokens: [] }).store, sender, noon);
  assert.equal(none?.skipped.no_token, 1);
});
