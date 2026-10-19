import assert from 'node:assert/strict';
import { FcmClient, isUnregistered, parseServiceAccount, signJwt, type ServiceAccount } from './fcm.ts';

function toPem(der: ArrayBuffer): string {
  const b64 = btoa(String.fromCharCode(...new Uint8Array(der)));
  return `-----BEGIN PRIVATE KEY-----\n${b64.match(/.{1,64}/g)!.join('\n')}\n-----END PRIVATE KEY-----\n`;
}

async function makeAccount() {
  const kp = await crypto.subtle.generateKey(
    { name: 'RSASSA-PKCS1-v1_5', modulusLength: 2048, publicExponent: new Uint8Array([1, 0, 1]), hash: 'SHA-256' },
    true,
    ['sign', 'verify'],
  );
  const pem = toPem(await crypto.subtle.exportKey('pkcs8', kp.privateKey));
  const sa: ServiceAccount = {
    client_email: 'push@vuon-nha.iam.gserviceaccount.com',
    private_key: pem,
    project_id: 'vuon-nha',
    token_uri: 'https://oauth2.googleapis.com/token',
  };
  return { sa, publicKey: kp.publicKey };
}

const fromB64url = (s: string) => Uint8Array.from(atob(s.replace(/-/g, '+').replace(/_/g, '/')), (c) => c.charCodeAt(0));

Deno.test('parseServiceAccount validates the secret', () => {
  assert.throws(() => parseServiceAccount(undefined), /not set/);
  assert.throws(() => parseServiceAccount('nope'), /not valid JSON/);
  assert.throws(() => parseServiceAccount('{"client_email":"a"}'), /needs/);
  const sa = parseServiceAccount(JSON.stringify({ client_email: 'a@b', private_key: 'k', project_id: 'p' }));
  assert.equal(sa.token_uri, 'https://oauth2.googleapis.com/token');
});

Deno.test('signJwt makes a verifiable RS256 assertion with the messaging scope', async () => {
  const { sa, publicKey } = await makeAccount();
  const jwt = await signJwt(sa, 1_800_000_000);
  const [h, c, s] = jwt.split('.');
  assert.deepEqual(JSON.parse(new TextDecoder().decode(fromB64url(h))), { alg: 'RS256', typ: 'JWT' });
  const claims = JSON.parse(new TextDecoder().decode(fromB64url(c)));
  assert.equal(claims.iss, sa.client_email);
  assert.equal(claims.scope, 'https://www.googleapis.com/auth/firebase.messaging');
  assert.equal(claims.aud, sa.token_uri);
  assert.equal(claims.exp - claims.iat, 3600);
  const ok = await crypto.subtle.verify('RSASSA-PKCS1-v1_5', publicKey, fromB64url(s), new TextEncoder().encode(`${h}.${c}`));
  assert.equal(ok, true);
});

interface Call { url: string; init?: RequestInit }

function mockFetch(handler: (url: string, init: RequestInit | undefined, n: number) => Response) {
  const calls: Call[] = [];
  const f = (url: string, init?: RequestInit) => {
    calls.push({ url, init });
    return Promise.resolve(handler(url, init, calls.length));
  };
  return { f, calls };
}

const tokenResponse = (expiresIn = 3600, token = 'ya29.token') =>
  new Response(JSON.stringify({ access_token: token, expires_in: expiresIn }), { status: 200 });

Deno.test('access token is cached until one minute before expiry', async () => {
  const { sa } = await makeAccount();
  let now = 1_000_000;
  const { f, calls } = mockFetch(() => tokenResponse(3600));
  const c = new FcmClient(sa, f, () => now);
  assert.equal(await c.accessToken(), 'ya29.token');
  assert.equal(await c.accessToken(), 'ya29.token');
  assert.equal(calls.length, 1, 'second call served from cache');
  const body = new URLSearchParams(String(calls[0].init!.body));
  assert.equal(body.get('grant_type'), 'urn:ietf:params:oauth:grant-type:jwt-bearer');
  assert.ok(body.get('assertion')!.split('.').length === 3);
  now += 3600_000 - 30_000; // inside the 60 s refresh margin
  await c.accessToken();
  assert.equal(calls.length, 2, 'refreshed near expiry');
});

Deno.test('concurrent callers share one token request', async () => {
  const { sa } = await makeAccount();
  const { f, calls } = mockFetch(() => tokenResponse());
  const c = new FcmClient(sa, f);
  await Promise.all([c.accessToken(), c.accessToken(), c.accessToken()]);
  assert.equal(calls.length, 1);
});

Deno.test('send posts to the v1 endpoint with the bearer token', async () => {
  const { sa } = await makeAccount();
  const { f, calls } = mockFetch((url) => (url.includes('oauth2') ? tokenResponse() : new Response('{"name":"m"}', { status: 200 })));
  const c = new FcmClient(sa, f);
  const r = await c.send({ token: 'dev1', notification: { title: 'T', body: 'B' }, data: { route: '/household' } });
  assert.deepEqual(r, { status: 'ok' });
  const send = calls[1];
  assert.equal(send.url, 'https://fcm.googleapis.com/v1/projects/vuon-nha/messages:send');
  assert.equal((send.init!.headers as Record<string, string>).Authorization, 'Bearer ya29.token');
  assert.deepEqual(JSON.parse(String(send.init!.body)), {
    message: { token: 'dev1', notification: { title: 'T', body: 'B' }, data: { route: '/household' } },
  });
});

Deno.test('UNREGISTERED is reported; other errors are not', async () => {
  const unreg = JSON.stringify({ error: { code: 404, status: 'NOT_FOUND', details: [{ '@type': 'x', errorCode: 'UNREGISTERED' }] } });
  assert.equal(isUnregistered(404, unreg), true);
  assert.equal(isUnregistered(404, JSON.stringify({ error: { status: 'NOT_FOUND' } })), true);
  assert.equal(isUnregistered(400, JSON.stringify({ error: { status: 'INVALID_ARGUMENT' } })), false);
  assert.equal(isUnregistered(500, 'not json'), false);

  const { sa } = await makeAccount();
  const { f } = mockFetch((url) => (url.includes('oauth2') ? tokenResponse() : new Response(unreg, { status: 404 })));
  assert.deepEqual(await new FcmClient(sa, f).send({ token: 'x', notification: { title: 'a', body: 'b' } }), { status: 'unregistered' });
  const { f: f2 } = mockFetch((url) => (url.includes('oauth2') ? tokenResponse() : new Response('{"error":{"status":"INTERNAL"}}', { status: 500 })));
  const r = await new FcmClient(sa, f2).send({ token: 'x', notification: { title: 'a', body: 'b' } });
  assert.equal(r.status, 'error');
});

Deno.test('a 401 refreshes the access token once and retries', async () => {
  const { sa } = await makeAccount();
  let sends = 0;
  let tokens = 0;
  const { f } = mockFetch((url) => {
    if (url.includes('oauth2')) return tokenResponse(3600, `tok${++tokens}`);
    sends++;
    return sends === 1 ? new Response('{"error":{"status":"UNAUTHENTICATED"}}', { status: 401 }) : new Response('{}', { status: 200 });
  });
  const r = await new FcmClient(sa, f).send({ token: 'x', notification: { title: 'a', body: 'b' } });
  assert.deepEqual(r, { status: 'ok' });
  assert.equal(tokens, 2);
  assert.equal(sends, 2);
});
