// Data access helpers shared by ai-plan and ai-checkin (service-role client, called after authorisation).
import type { SupabaseClient } from '@supabase/supabase-js';
import { BAND_HIGH, BAND_MEDIUM, DEFAULT_PRICES, ESCALATE_BELOW } from './constants.ts';
import { HttpError } from './http.ts';
import type { KnownCodes, TaskWindow } from './types.ts';

export async function loadKnownCodes(admin: SupabaseClient): Promise<KnownCodes> {
  const [t, p, r, m] = await Promise.all([
    admin.from('task_codes').select('code, default_window, default_interval_days'),
    admin.from('problem_codes').select('code'),
    admin.from('reason_codes').select('code'),
    admin.from('milestone_codes').select('code'),
  ]);
  for (const x of [t, p, r, m]) if (x.error) throw new HttpError(500, 'db_error', x.error.message);
  return {
    tasks: new Map((t.data ?? []).map((x) => [x.code as string, { window: x.default_window as TaskWindow, intervalDays: x.default_interval_days as number | null }])),
    problems: new Set((p.data ?? []).map((x) => x.code as string)),
    reasons: new Set((r.data ?? []).map((x) => x.code as string)),
    milestones: new Set((m.data ?? []).map((x) => x.code as string)),
  };
}

export interface Thresholds { escalateBelow: number; high: number; medium: number }

export async function loadThresholds(admin: SupabaseClient): Promise<Thresholds> {
  const { data } = await admin.from('app_config').select('key, value').in('key', ['ai_escalate_below', 'band_high', 'band_medium']);
  const get = (k: string, d: number) => {
    const v = Number(data?.find((x) => x.key === k)?.value);
    return Number.isFinite(v) ? v : d;
  };
  return { escalateBelow: get('ai_escalate_below', ESCALATE_BELOW), high: get('band_high', BAND_HIGH), medium: get('band_medium', BAND_MEDIUM) };
}

export function loadPrices(): typeof DEFAULT_PRICES {
  try {
    const raw = Deno.env.get('MODEL_PRICES_JSON');
    return raw ? { ...DEFAULT_PRICES, ...JSON.parse(raw) } : DEFAULT_PRICES;
  } catch (_) {
    return DEFAULT_PRICES;
  }
}

export function requireApiKey(): string {
  const k = Deno.env.get('ANTHROPIC_API_KEY');
  if (!k) throw new HttpError(500, 'server_misconfigured', 'missing ANTHROPIC_API_KEY');
  return k;
}

/** Postgres error code for quota is P0429 (consume_ai_quota). */
export function isQuotaError(e: { message?: string; code?: string } | null): boolean {
  return !!e && (e.code === 'P0429' || /ai_quota_exceeded/.test(e.message ?? ''));
}
