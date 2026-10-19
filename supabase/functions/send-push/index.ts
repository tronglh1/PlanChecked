// POST /functions/v1/send-push   (called by the database, not by the app)
// Body: Database-Webhook shaped event, see supabase/migrations/20261019000600_qa2_fixes.sql (push_dispatch).
// Auth: header `x-webhook-secret` must equal the PUSH_WEBHOOK_SECRET secret (deployed with --no-verify-jwt).
// Sends FCM HTTP v1 pushes for: task assignee change, user_badges insert, household_activity insert.
import { adminClient } from '../_shared/auth.ts';
import { FcmClient, parseServiceAccount } from '../_shared/fcm.ts';
import { errorResponse, HttpError, json, preflight } from '../_shared/http.ts';
import { handleEvent, type WebhookEvent } from '../_shared/push.ts';
import { supabasePushStore } from '../_shared/push_store.ts';

// Kept at module scope so the OAuth access token is cached across invocations of a warm instance.
let fcm: FcmClient | null = null;

function secretsEqual(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  let d = 0;
  for (let i = 0; i < a.length; i++) d |= a.charCodeAt(i) ^ b.charCodeAt(i);
  return d === 0;
}

Deno.serve(async (req) => {
  const pre = preflight(req);
  if (pre) return pre;
  try {
    if (req.method !== 'POST') throw new HttpError(405, 'method_not_allowed');
    const expected = Deno.env.get('PUSH_WEBHOOK_SECRET');
    if (!expected) throw new HttpError(500, 'server_misconfigured', 'missing env PUSH_WEBHOOK_SECRET');
    if (!secretsEqual(req.headers.get('x-webhook-secret') ?? '', expected)) throw new HttpError(401, 'unauthorized');

    let ev: WebhookEvent;
    try {
      ev = await req.json();
    } catch (_) {
      throw new HttpError(400, 'invalid_json');
    }
    try {
      fcm ??= new FcmClient(parseServiceAccount(Deno.env.get('FCM_SERVICE_ACCOUNT')));
    } catch (e) {
      throw new HttpError(500, 'server_misconfigured', (e as Error).message);
    }
    const summary = await handleEvent(ev, supabasePushStore(adminClient()), fcm);
    return json(summary ?? { ignored: true });
  } catch (e) {
    return errorResponse(e);
  }
});
