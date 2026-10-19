// FCM HTTP v1 client for Edge Functions: service-account OAuth2 (RS256 JWT signed with WebCrypto, no libraries),
// access-token cache, and message sending with UNREGISTERED detection. `fetch` and the clock are injectable for tests.

export interface ServiceAccount {
  client_email: string;
  private_key: string;
  project_id: string;
  token_uri: string;
}

const SCOPE = 'https://www.googleapis.com/auth/firebase.messaging';
const DEFAULT_TOKEN_URI = 'https://oauth2.googleapis.com/token';

export function parseServiceAccount(raw: string | undefined | null): ServiceAccount {
  if (!raw) throw new Error('FCM_SERVICE_ACCOUNT is not set');
  let j: Record<string, unknown>;
  try {
    j = JSON.parse(raw);
  } catch (_) {
    throw new Error('FCM_SERVICE_ACCOUNT is not valid JSON');
  }
  const { client_email, private_key, project_id } = j as Record<string, string>;
  if (!client_email || !private_key || !project_id) {
    throw new Error('FCM_SERVICE_ACCOUNT needs client_email, private_key and project_id');
  }
  return {
    client_email,
    private_key,
    project_id,
    token_uri: typeof j.token_uri === 'string' ? j.token_uri : DEFAULT_TOKEN_URI,
  };
}

const enc = new TextEncoder();

function b64url(data: Uint8Array | string): string {
  const bytes = typeof data === 'string' ? enc.encode(data) : data;
  let s = '';
  for (const b of bytes) s += String.fromCharCode(b);
  return btoa(s).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
}

async function importPrivateKey(pem: string): Promise<CryptoKey> {
  const body = pem.replace(/-----(BEGIN|END) PRIVATE KEY-----/g, '').replace(/\\n/g, '').replace(/\s+/g, '');
  const der = Uint8Array.from(atob(body), (c) => c.charCodeAt(0));
  return await crypto.subtle.importKey('pkcs8', der, { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' }, false, ['sign']);
}

/** RS256 JWT assertion for the OAuth2 jwt-bearer grant. */
export async function signJwt(sa: ServiceAccount, nowSec: number): Promise<string> {
  const header = b64url(JSON.stringify({ alg: 'RS256', typ: 'JWT' }));
  const claims = b64url(JSON.stringify({
    iss: sa.client_email,
    scope: SCOPE,
    aud: sa.token_uri,
    iat: nowSec,
    exp: nowSec + 3600,
  }));
  const input = `${header}.${claims}`;
  const key = await importPrivateKey(sa.private_key);
  const sig = new Uint8Array(await crypto.subtle.sign('RSASSA-PKCS1-v1_5', key, enc.encode(input)));
  return `${input}.${b64url(sig)}`;
}

export interface FcmMessage {
  token: string;
  notification: { title: string; body: string };
  data?: Record<string, string>;
}

export type SendResult =
  | { status: 'ok' }
  | { status: 'unregistered' }
  | { status: 'error'; httpStatus: number; detail: string };

export type FetchLike = (input: string, init?: RequestInit) => Promise<Response>;

export class FcmClient {
  #cache: { token: string; expiresAt: number } | null = null;
  #inflight: Promise<string> | null = null;

  constructor(
    private sa: ServiceAccount,
    private fetchImpl: FetchLike = (i, init) => fetch(i, init),
    private now: () => number = () => Date.now(),
  ) {}

  /** Cached OAuth2 access token (refreshed one minute before it expires; concurrent callers share one request). */
  async accessToken(): Promise<string> {
    const c = this.#cache;
    if (c && c.expiresAt - 60_000 > this.now()) return c.token;
    this.#inflight ??= this.#refresh().finally(() => (this.#inflight = null));
    return await this.#inflight;
  }

  async #refresh(): Promise<string> {
    const assertion = await signJwt(this.sa, Math.floor(this.now() / 1000));
    const res = await this.fetchImpl(this.sa.token_uri, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: new URLSearchParams({
        grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
        assertion,
      }).toString(),
    });
    const j = await res.json().catch(() => ({}));
    if (!res.ok || typeof j.access_token !== 'string') {
      throw new Error(`fcm_oauth_failed_${res.status}`);
    }
    const ttl = typeof j.expires_in === 'number' ? j.expires_in : 3600;
    this.#cache = { token: j.access_token, expiresAt: this.now() + ttl * 1000 };
    return j.access_token;
  }

  invalidate(): void {
    this.#cache = null;
  }

  async send(message: FcmMessage): Promise<SendResult> {
    for (let attempt = 0; attempt < 2; attempt++) {
      const token = await this.accessToken();
      const res = await this.fetchImpl(`https://fcm.googleapis.com/v1/projects/${this.sa.project_id}/messages:send`, {
        method: 'POST',
        headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
        body: JSON.stringify({ message }),
      });
      if (res.ok) {
        await res.body?.cancel();
        return { status: 'ok' };
      }
      const text = await res.text();
      if (res.status === 401 && attempt === 0) {
        this.invalidate(); // expired / revoked access token: fetch a new one once
        continue;
      }
      return isUnregistered(res.status, text) ? { status: 'unregistered' } : { status: 'error', httpStatus: res.status, detail: text.slice(0, 300) };
    }
    return { status: 'error', httpStatus: 401, detail: 'unauthorized' };
  }
}

/** FCM v1 reports a dead token as 404 with details[].errorCode = UNREGISTERED. */
export function isUnregistered(httpStatus: number, body: string): boolean {
  try {
    const e = JSON.parse(body)?.error;
    const codes = (e?.details ?? []).map((d: { errorCode?: string }) => d.errorCode);
    if (codes.includes('UNREGISTERED')) return true;
    return httpStatus === 404 && e?.status === 'NOT_FOUND';
  } catch (_) {
    return false;
  }
}
