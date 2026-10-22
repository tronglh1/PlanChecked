// POST /functions/v1/invite   { channel: 'link'|'code'|'email'|'phone', target?: string, role?: 'member'|'owner' }
// Creates an invite for the caller's household (Owner only, enforced by the create_invite RPC) and, for the email
// channel, sends the link when an email provider is configured (RESEND_API_KEY + INVITE_FROM_EMAIL).
// Otherwise the code and link are returned so the app can share them (share sheet / copy).
import { authenticate } from '../_shared/auth.ts';
import { errorResponse, HttpError, json, preflight, readJson } from '../_shared/http.ts';
import { inviteLink } from '../_shared/invite.ts';

Deno.serve(async (req) => {
  const pre = preflight(req);
  if (pre) return pre;
  try {
    return json(await handle(req));
  } catch (e) {
    return errorResponse(e);
  }
});

const CHANNELS = ['link', 'code', 'email', 'phone'];
const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const esc = (s: string) => s.replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]!));

async function handle(req: Request) {
  const ctx = await authenticate(req);
  const body = await readJson(req);
  const channel = typeof body.channel === 'string' && CHANNELS.includes(body.channel) ? body.channel : 'code';
  const role = body.role === 'owner' ? 'owner' : 'member';
  const target = typeof body.target === 'string' ? body.target.trim().slice(0, 200) : null;
  if (channel === 'email' && (!target || !EMAIL_RE.test(target))) throw new HttpError(400, 'invalid_email');

  const { data, error } = await ctx.user.rpc('create_invite', { p_channel: channel, p_target: target, p_role: role });
  if (error) {
    if (/not_household_owner/.test(error.message)) throw new HttpError(403, 'not_household_owner');
    if (/too_many_invites/.test(error.message)) throw new HttpError(429, 'too_many_invites');
    throw new HttpError(500, 'invite_failed', error.message);
  }
  const invite = data as { id: string; code: string; expires_at: string; role: string; channel: string; household_id: string };
  const link = inviteLink(Deno.env.get('INVITE_LINK_BASE') ?? 'https://vuonnha.app/i', invite.code);

  const result: Record<string, unknown> = {
    invite: { id: invite.id, code: invite.code, expires_at: invite.expires_at, role: invite.role, channel: invite.channel },
    link,
    email_sent: false,
  };

  if (channel === 'email') {
    const key = Deno.env.get('RESEND_API_KEY');
    const from = Deno.env.get('INVITE_FROM_EMAIL');
    if (!key || !from) {
      result.email_error = 'email_not_configured';
    } else {
      const [{ data: me }, { data: h }] = await Promise.all([
        ctx.admin.from('users').select('display_name').eq('id', ctx.userId).single(),
        ctx.admin.from('households').select('name').eq('id', invite.household_id).single(),
      ]);
      const who = esc(me?.display_name || 'Một người bạn');
      const house = esc(h?.name || 'Nhà mình');
      try {
        const res = await fetch('https://api.resend.com/emails', {
          method: 'POST',
          headers: { Authorization: `Bearer ${key}`, 'content-type': 'application/json' },
          body: JSON.stringify({
            from, to: [target], subject: `${me?.display_name || 'Bạn bè'} mời bạn vào "${h?.name || 'Nhà mình'}" trên Vườn Nhà`,
            html: `<p>${who} mời bạn cùng chăm cây trong gia đình <b>${house}</b> trên Vườn Nhà.</p>
<p>Mở liên kết: <a href="${esc(link)}">${esc(link)}</a></p><p>Hoặc nhập mã: <b>${esc(invite.code)}</b> (hết hạn sau 7 ngày).</p>`,
          }),
        });
        result.email_sent = res.ok;
        if (!res.ok) result.email_error = `provider_${res.status}`;
      } catch (_) {
        result.email_error = 'provider_unreachable';
      }
    }
  } else if (channel === 'phone') {
    result.sms_error = 'sms_not_supported';   // share the code/link through the OS share sheet instead
  }
  return result;
}
