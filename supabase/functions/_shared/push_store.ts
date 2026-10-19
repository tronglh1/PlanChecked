// PushStore backed by the service-role Supabase client (used by send-push only, after the webhook secret is checked).
import type { SupabaseClient } from '@supabase/supabase-js';
import type { Lang, PrefRow, PushKind, PushStore, Recipient } from './push.ts';

const lang = (v: unknown): Lang => (v === 'en' ? 'en' : 'vi');

export function supabasePushStore(db: SupabaseClient): PushStore {
  return {
    async users(ids) {
      if (!ids.length) return [];
      const { data, error } = await db.from('users').select('id, lang, timezone, quiet_start, quiet_end').in('id', ids).is('deleted_at', null);
      if (error) throw new Error(`users: ${error.message}`);
      return (data ?? []).map((u): Recipient => ({
        id: u.id as string,
        lang: lang(u.lang),
        timezone: (u.timezone as string) || 'Asia/Ho_Chi_Minh',
        quiet_start: (u.quiet_start as string | null) ?? null,
        quiet_end: (u.quiet_end as string | null) ?? null,
      }));
    },
    async prefs(ids, type: PushKind) {
      const out = new Map<string, PrefRow>();
      if (!ids.length) return out;
      const { data, error } = await db.from('notification_prefs').select('user_id, enabled, quiet_start, quiet_end').eq('type', type).in('user_id', ids);
      if (error) throw new Error(`prefs: ${error.message}`);
      for (const r of data ?? []) {
        out.set(r.user_id as string, { enabled: r.enabled !== false, quiet_start: (r.quiet_start as string | null) ?? null, quiet_end: (r.quiet_end as string | null) ?? null });
      }
      return out;
    },
    async tokens(ids) {
      if (!ids.length) return [];
      const { data, error } = await db.from('push_tokens').select('user_id, token').in('user_id', ids);
      if (error) throw new Error(`tokens: ${error.message}`);
      return (data ?? []) as { user_id: string; token: string }[];
    },
    async deleteToken(token) {
      const { error } = await db.from('push_tokens').delete().eq('token', token);
      if (error) console.error('push_tokens delete failed', error.message);
    },
    async householdMembers(householdId) {
      const { data, error } = await db.from('household_members').select('user_id').eq('household_id', householdId);
      if (error) throw new Error(`members: ${error.message}`);
      return (data ?? []).map((r) => r.user_id as string);
    },
    async displayName(userId) {
      const { data } = await db.from('users').select('display_name').eq('id', userId).maybeSingle();
      return (data?.display_name as string | undefined) || null;
    },
    async projectName(projectId) {
      const { data } = await db.from('projects').select('name').eq('id', projectId).maybeSingle();
      return (data?.name as string | undefined) || null;
    },
    async label(kind, code, l) {
      if (kind === 'badge') {
        const { data } = await db.from('badges_catalog').select('name_vi, name_en').eq('code', code).maybeSingle();
        return ((l === 'en' ? data?.name_en : data?.name_vi) as string | undefined) || null;
      }
      const { data } = await db.from('text_templates').select('body').eq('kind', kind).eq('code', code).eq('lang', l).eq('field', 'name').maybeSingle();
      return (data?.body as string | undefined) || null;
    },
    async taskInfo(taskId) {
      const { data } = await db.from('tasks').select('task_code, project_id').eq('id', taskId).maybeSingle();
      return data ? { task_code: data.task_code as string, project_id: data.project_id as string } : null;
    },
  };
}
