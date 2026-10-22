// send-push logic: turns a database change into FCM messages. Pure of I/O except through the injected
// `PushStore` (database) and `Sender` (FCM), so it is unit-tested with in-memory fakes and a mocked fetch.
import type { SendResult } from './fcm.ts';

export type PushKind = 'assignment' | 'achievement' | 'household_activity';
export type Lang = 'vi' | 'en';

/** Database-webhook shaped event (see push_dispatch in migration 0600). */
export interface WebhookEvent {
  type?: string;
  table?: string;
  record?: Record<string, unknown> | null;
  old_record?: Record<string, unknown> | null;
  actor_id?: string | null;
}

export interface Recipient {
  id: string;
  lang: Lang;
  timezone: string;
  quiet_start: string | null;
  quiet_end: string | null;
}

export interface PrefRow {
  enabled: boolean;
  quiet_start: string | null;
  quiet_end: string | null;
}

export interface PushStore {
  users(ids: string[]): Promise<Recipient[]>;
  /** notification_prefs rows of [type] by user id (a missing row means "enabled, no override"). */
  prefs(ids: string[], type: PushKind): Promise<Map<string, PrefRow>>;
  tokens(ids: string[]): Promise<{ user_id: string; token: string }[]>;
  deleteToken(token: string): Promise<void>;
  householdMembers(householdId: string): Promise<string[]>;
  displayName(userId: string): Promise<string | null>;
  projectName(projectId: string): Promise<string | null>;
  /** task, milestone, ... name from text_templates, or the badge name for kind "badge"; null when unknown. */
  label(kind: 'task' | 'milestone' | 'badge', code: string, lang: Lang): Promise<string | null>;
  taskInfo(taskId: string): Promise<{ task_code: string; project_id: string } | null>;
}

export interface Sender {
  send(m: { token: string; notification: { title: string; body: string }; data?: Record<string, string> }): Promise<SendResult>;
}

export interface PushSummary {
  kind: PushKind | null;
  recipients: number;
  sent: number;
  skipped: { disabled: number; quiet: number; no_token: number };
  removed_tokens: number;
  errors: number;
}

const emptySummary = (kind: PushKind | null): PushSummary => ({
  kind,
  recipients: 0,
  sent: 0,
  skipped: { disabled: 0, quiet: 0, no_token: 0 },
  removed_tokens: 0,
  errors: 0,
});

// ---------------------------------------------------------------- quiet hours

function minutes(t: string | null | undefined): number | null {
  const m = /^(\d{1,2}):(\d{2})/.exec(t ?? '');
  if (!m) return null;
  const v = Number(m[1]) * 60 + Number(m[2]);
  return v >= 0 && v < 1440 ? v : null;
}

export function localMinutes(timezone: string, now: Date): number {
  let parts: Intl.DateTimeFormatPart[];
  try {
    parts = new Intl.DateTimeFormat('en-GB', { timeZone: timezone, hour: '2-digit', minute: '2-digit', hourCycle: 'h23' }).formatToParts(now);
  } catch (_) {
    parts = new Intl.DateTimeFormat('en-GB', { timeZone: 'Asia/Ho_Chi_Minh', hour: '2-digit', minute: '2-digit', hourCycle: 'h23' }).formatToParts(now);
  }
  const h = Number(parts.find((p) => p.type === 'hour')?.value ?? 0);
  const m = Number(parts.find((p) => p.type === 'minute')?.value ?? 0);
  return h * 60 + m;
}

/** True when [now] (in [timezone]) falls in [start, end); windows may wrap midnight (22:00-06:30). */
export function inQuietHours(start: string | null, end: string | null, timezone: string, now: Date): boolean {
  const s = minutes(start);
  const e = minutes(end);
  if (s === null || e === null || s === e) return false;
  const cur = localMinutes(timezone, now);
  return s < e ? cur >= s && cur < e : cur >= s || cur < e;
}

// ---------------------------------------------------------------- texts

interface Texts {
  title: string;
  body: string;
  route: string;
}

const T = {
  vi: {
    assignTitle: 'Việc mới cho bạn',
    assign: (who: string | null, task: string, project: string | null) =>
      `${who ?? 'Người nhà'} giao bạn: ${task}${project ? ` (${project})` : ''}`,
    badgeTitle: 'Huy hiệu mới',
    badge: (name: string) => `Bạn vừa nhận huy hiệu "${name}"`,
    activityTitle: 'Vườn nhà',
    someone: 'Người nhà',
    done: (who: string, task: string | null) => `${who} đã hoàn thành ${task ?? 'một việc'}`,
    checkin: (who: string, project: string | null) => `${who} vừa chụp check-in${project ? ` cho ${project}` : ''}`,
    milestone: (who: string, name: string | null, project: string | null) =>
      `${who} đạt mốc ${name ?? 'mới'}${project ? ` ở ${project}` : ''}`,
    joined: (who: string) => `${who} đã tham gia gia đình`,
    left: (who: string) => `${who} đã rời gia đình`,
    shared: (who: string, project: string | null) => `${who} chia sẻ ${project ?? 'một cây'} với gia đình`,
    other: (who: string) => `${who} có hoạt động mới`,
  },
  en: {
    assignTitle: 'New task for you',
    assign: (who: string | null, task: string, project: string | null) =>
      `${who ?? 'A family member'} assigned you: ${task}${project ? ` (${project})` : ''}`,
    badgeTitle: 'New badge',
    badge: (name: string) => `You earned the "${name}" badge`,
    activityTitle: 'Vườn Nhà',
    someone: 'A family member',
    done: (who: string, task: string | null) => `${who} completed ${task ?? 'a task'}`,
    checkin: (who: string, project: string | null) => `${who} posted a check-in${project ? ` for ${project}` : ''}`,
    milestone: (who: string, name: string | null, project: string | null) =>
      `${who} reached ${name ?? 'a new milestone'}${project ? ` on ${project}` : ''}`,
    joined: (who: string) => `${who} joined the household`,
    left: (who: string) => `${who} left the household`,
    shared: (who: string, project: string | null) => `${who} shared ${project ?? 'a plant'} with the household`,
    other: (who: string) => `${who} has new activity`,
  },
} as const;

export function assignmentText(lang: Lang, who: string | null, task: string, project: string | null, taskId: string): Texts {
  return { title: T[lang].assignTitle, body: T[lang].assign(who, task, project), route: `/task/${taskId}` };
}

export function badgeText(lang: Lang, name: string): Texts {
  return { title: T[lang].badgeTitle, body: T[lang].badge(name), route: '/achievements' };
}

export function activityText(
  lang: Lang,
  kind: string,
  who: string | null,
  ctx: { task: string | null; project: string | null; milestone: string | null },
): Texts {
  const t = T[lang];
  const w = who ?? t.someone;
  const body = kind === 'task_done'
    ? t.done(w, ctx.task)
    : kind === 'checkin'
    ? t.checkin(w, ctx.project)
    : kind === 'milestone'
    ? t.milestone(w, ctx.milestone, ctx.project)
    : kind === 'member_joined'
    ? t.joined(w)
    : kind === 'member_left'
    ? t.left(w)
    : kind === 'project_shared'
    ? t.shared(w, ctx.project)
    : t.other(w);
  return { title: t.activityTitle, body, route: '/household' };
}

// ---------------------------------------------------------------- event handling

const str = (v: unknown): string | null => (typeof v === 'string' && v ? v : null);

/**
 * Handles one event. Returns null for events that never produce a push (so callers can answer 200 and move on).
 * Delivery rules, per recipient: notification_prefs.enabled for the type (default on), quiet hours (the per-type
 * override in notification_prefs, else users.quiet_start/quiet_end, evaluated in the user's timezone; pushes inside
 * the window are dropped, not queued), then every push_tokens row; tokens FCM reports UNREGISTERED are deleted.
 */
export async function handleEvent(ev: WebhookEvent, store: PushStore, sender: Sender, now: Date = new Date()): Promise<PushSummary | null> {
  const rec = ev.record ?? null;
  if (!rec) return null;
  const actor = str(ev.actor_id) ?? str(rec.actor_id);

  let kind: PushKind;
  let recipients: string[];
  switch (ev.table) {
    case 'tasks': {
      const to = str(rec.assignee_id);
      const before = str(ev.old_record?.assignee_id);
      if (!to || to === before || to === actor) return null;
      kind = 'assignment';
      recipients = [to];
      break;
    }
    case 'user_badges': {
      const to = str(rec.user_id);
      if (!to || !str(rec.badge_code)) return null;
      kind = 'achievement';
      recipients = [to];
      break;
    }
    case 'household_activity': {
      const hid = str(rec.household_id);
      if (!hid) return null;
      kind = 'household_activity';
      recipients = (await store.householdMembers(hid)).filter((u) => u !== actor);
      break;
    }
    default:
      return null;
  }

  const summary = emptySummary(kind);
  recipients = [...new Set(recipients)];
  if (!recipients.length) return summary;
  summary.recipients = recipients.length;

  const [users, prefs] = await Promise.all([store.users(recipients), store.prefs(recipients, kind)]);
  const eligible: Recipient[] = [];
  for (const u of users) {
    const p = prefs.get(u.id);
    if (p && !p.enabled) {
      summary.skipped.disabled++;
      continue;
    }
    const qs = p?.quiet_start && p?.quiet_end ? p.quiet_start : u.quiet_start;
    const qe = p?.quiet_start && p?.quiet_end ? p.quiet_end : u.quiet_end;
    if (inQuietHours(qs, qe, u.timezone, now)) {
      summary.skipped.quiet++;
      continue;
    }
    eligible.push(u);
  }
  if (!eligible.length) return summary;

  const tokens = await store.tokens(eligible.map((u) => u.id));
  const byUser = new Map<string, string[]>();
  for (const t of tokens) byUser.set(t.user_id, [...(byUser.get(t.user_id) ?? []), t.token]);

  const whoName = actor ? await store.displayName(actor) : null;
  const textCache = new Map<Lang, Texts>();
  const textsFor = async (lang: Lang): Promise<Texts | null> => {
    const hit = textCache.get(lang);
    if (hit) return hit;
    let t: Texts;
    if (kind === 'assignment') {
      const taskId = str(rec.id);
      const info = taskId ? await store.taskInfo(taskId) : null;
      const code = info?.task_code ?? str(rec.task_code);
      if (!taskId || !code) return null;
      const project = info?.project_id ?? str(rec.project_id);
      t = assignmentText(lang, whoName, (await store.label('task', code, lang)) ?? code, project ? await store.projectName(project) : null, taskId);
    } else if (kind === 'achievement') {
      const code = str(rec.badge_code)!;
      t = badgeText(lang, (await store.label('badge', code, lang)) ?? code);
    } else {
      const payload = (rec.payload ?? {}) as Record<string, unknown>;
      const taskCode = str(payload.task_code);
      const msCode = str(payload.milestone_code);
      const project = str(rec.project_id);
      t = activityText(lang, str(rec.kind) ?? '', whoName, {
        task: taskCode ? await store.label('task', taskCode, lang) : null,
        milestone: msCode ? await store.label('milestone', msCode, lang) : null,
        project: project ? await store.projectName(project) : str(payload.name),
      });
    }
    textCache.set(lang, t);
    return t;
  };

  for (const u of eligible) {
    const toks = byUser.get(u.id) ?? [];
    if (!toks.length) {
      summary.skipped.no_token++;
      continue;
    }
    const text = await textsFor(u.lang);
    if (!text) continue;
    for (const token of toks) {
      let r: SendResult;
      try {
        r = await sender.send({
          token,
          notification: { title: text.title, body: text.body },
          data: { type: kind, route: text.route },
        });
      } catch (_) {
        r = { status: 'error', httpStatus: 0, detail: 'exception' };
      }
      if (r.status === 'ok') summary.sent++;
      else if (r.status === 'unregistered') {
        await store.deleteToken(token);
        summary.removed_tokens++;
      } else summary.errors++;
    }
  }
  return summary;
}
