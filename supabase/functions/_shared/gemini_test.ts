import assert from 'node:assert/strict';
import { resolveAi } from './ai.ts';
import { generateWithEscalation, type ClaudeRequest } from './anthropic.ts';
import { GEMINI_MODEL_DEFAULT, GEMINI_MODEL_FALLBACK, GEMINI_MODEL_STRONG, MODEL_DEFAULT } from './constants.ts';
import { buildGeminiBody, callGemini, toGeminiSchema } from './gemini.ts';
import { goodPlan, known } from './test_helpers.ts';
import { checkinTool, planSystem, planTool } from './prompts.ts';
import { validatePlanOutput } from './validate.ts';
import type { PlanOutput } from './types.ts';

const req = (model = GEMINI_MODEL_DEFAULT): ClaudeRequest => ({
  model, system: planSystem(known), tool: planTool(known), maxTokens: 1000, timeoutMs: 500,
  content: [
    { type: 'text', text: 'hi', cache_control: { type: 'ephemeral' } },
    { type: 'image', source: { type: 'base64', media_type: 'image/jpeg', data: 'AAAA' } },
  ],
});
const okResponse = (input: unknown) =>
  new Response(JSON.stringify({
    modelVersion: GEMINI_MODEL_DEFAULT,
    candidates: [{ content: { parts: [{ text: 'thinking', thought: true }, { text: JSON.stringify(input) }] }, finishReason: 'STOP' }],
    usageMetadata: { promptTokenCount: 500, cachedContentTokenCount: 400, candidatesTokenCount: 50, thoughtsTokenCount: 10 },
  }), { status: 200 });
const noSleep = () => Promise.resolve();

Deno.test('gemini body: system instruction, inline image, JSON schema from the tool', () => {
  const body = buildGeminiBody(req());
  assert.equal(body.systemInstruction.parts.length, planSystem(known).length);
  assert.deepEqual(body.contents[0].parts[0], { text: 'hi' });
  assert.deepEqual(body.contents[0].parts[1], { inlineData: { mimeType: 'image/jpeg', data: 'AAAA' } });
  assert.equal(body.generationConfig.responseMimeType, 'application/json');
  assert.deepEqual(body.generationConfig.responseJsonSchema, toGeminiSchema(planTool(known).input_schema));
});

Deno.test('gemini call: endpoint, key header, parsed JSON, usage mapping', async () => {
  let seen: { url: string; headers: Record<string, string> } | null = null;
  const fetchImpl = ((url: string, init: RequestInit) => {
    seen = { url, headers: init.headers as Record<string, string> };
    return Promise.resolve(okResponse(goodPlan()));
  }) as unknown as typeof fetch;
  const r = await callGemini(req(), { apiKey: 'g-test', fetchImpl, sleep: noSleep });
  assert.equal(seen!.url, `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL_DEFAULT}:generateContent`);
  assert.equal(seen!.headers['x-goog-api-key'], 'g-test');
  assert.deepEqual(r.input, goodPlan());
  assert.deepEqual(r.usage, { input_tokens: 100, output_tokens: 60, cache_read_input_tokens: 400, cache_creation_input_tokens: 0 });
});

Deno.test('gemini call: retries once on 503, fails fast on 400 and on non-JSON text', async () => {
  let n = 0;
  const flaky = (() => Promise.resolve(++n === 1 ? new Response('busy', { status: 503 }) : okResponse(goodPlan()))) as unknown as typeof fetch;
  await callGemini(req(), { apiKey: 'k', fetchImpl: flaky, sleep: noSleep });
  assert.equal(n, 2);

  n = 0;
  const bad = (() => { n++; return Promise.resolve(new Response('bad', { status: 400 })); }) as unknown as typeof fetch;
  await assert.rejects(callGemini(req(), { apiKey: 'k', fetchImpl: bad, sleep: noSleep }), /gemini 400 \(failed variant: no-schema/);
  assert.equal(n, 3);

  n = 0;
  const forbidden = (() => { n++; return Promise.resolve(new Response('no', { status: 403 })); }) as unknown as typeof fetch;
  await assert.rejects(callGemini(req(), { apiKey: 'k', fetchImpl: forbidden, sleep: noSleep }), /gemini 403/);
  assert.equal(n, 1);

  const prose = (() => Promise.resolve(new Response(JSON.stringify({ candidates: [{ content: { parts: [{ text: 'not json' }] } }] }), { status: 200 }))) as unknown as typeof fetch;
  await assert.rejects(callGemini(req(), { apiKey: 'k', fetchImpl: prose, sleep: noSleep }), /not valid JSON/);
});

Deno.test('provider: gemini when only GEMINI_API_KEY is set, overrides and missing key', () => {
  const env = (vars: Record<string, string>) => (k: string) => vars[k];
  const g = resolveAi(env({ GEMINI_API_KEY: 'g' }));
  assert.equal(g.provider, 'gemini');
  assert.deepEqual(g.models, { default: GEMINI_MODEL_DEFAULT, strong: GEMINI_MODEL_STRONG });

  const a = resolveAi(env({ ANTHROPIC_API_KEY: 'a', GEMINI_API_KEY: 'g' }));
  assert.equal(a.provider, 'anthropic');
  assert.equal(a.models.default, MODEL_DEFAULT);

  const forced = resolveAi(env({ AI_PROVIDER: 'Gemini', ANTHROPIC_API_KEY: 'a', GEMINI_API_KEY: 'g', AI_MODEL_STRONG: 'gemini-x' }));
  assert.equal(forced.provider, 'gemini');
  assert.equal(forced.models.strong, 'gemini-x');

  assert.throws(() => resolveAi(env({ AI_PROVIDER: 'gemini' })), /missing GEMINI_API_KEY/);
  assert.throws(() => resolveAi(env({})), /missing ANTHROPIC_API_KEY/);
});

Deno.test('escalation runs on gemini models end to end', async () => {
  const calls: string[] = [];
  const fetchImpl = ((url: string) => { calls.push(url); return Promise.resolve(okResponse(goodPlan())); }) as unknown as typeof fetch;
  const ai = resolveAi((k) => ({ GEMINI_API_KEY: 'g' } as Record<string, string>)[k], fetchImpl);
  const r = await generateWithEscalation<PlanOutput>({
    startStrong: false, threshold: 0.6, models: ai.models,
    confidenceOf: (v) => v.confidence,
    validate: (input) => validatePlanOutput(input, known, { plantKnown: true }),
    call: (model) => ai.call({ ...req(model) }),
  });
  assert.equal(r.model, GEMINI_MODEL_DEFAULT);
  assert.equal(calls.length, 1);
});

const walk = (v: unknown, f: (o: Record<string, unknown>) => void) => {
  if (Array.isArray(v)) v.forEach((x) => walk(x, f));
  else if (v && typeof v === 'object') { f(v as Record<string, unknown>); Object.values(v).forEach((x) => walk(x, f)); }
};

Deno.test('toGeminiSchema: enum with null becomes typed enum + nullable anyOf', () => {
  assert.deepEqual(toGeminiSchema({ enum: ['a', 'b', null], description: 'd' }),
    { anyOf: [{ type: 'string', enum: ['a', 'b'], description: 'd' }, { type: 'null' }] });
});

Deno.test('toGeminiSchema: enum-only gets a type (string / integer / number)', () => {
  assert.deepEqual(toGeminiSchema({ enum: ['x'] }), { type: 'string', enum: ['x'] });
  assert.deepEqual(toGeminiSchema({ enum: [1, 2] }), { type: 'integer', enum: [1, 2] });
  assert.deepEqual(toGeminiSchema({ enum: [0.5, 1] }), { type: 'number', enum: [0.5, 1] });
});

Deno.test('toGeminiSchema: type array with null becomes anyOf; pattern/length dropped, others kept', () => {
  assert.deepEqual(
    toGeminiSchema({ type: ['string', 'null'], pattern: '^a', maxLength: 5, minLength: 1, description: 'd' }),
    { anyOf: [{ type: 'string', description: 'd' }, { type: 'null' }] });
  assert.deepEqual(toGeminiSchema({ type: 'integer', minimum: 1, maximum: 9 }), { type: 'integer', minimum: 1, maximum: 9 });
});

Deno.test('toGeminiSchema: recurses into properties, items, anyOf; a property named pattern survives; input not mutated', () => {
  const input = {
    type: 'object', required: ['pattern'],
    properties: {
      pattern: { type: 'string', maxLength: 3 },
      list: { type: 'array', minItems: 1, maxItems: 2, items: { enum: ['a', null] } },
      alt: { anyOf: [{ type: 'string', pattern: 'x' }, { type: 'null' }] },
      nest: { type: 'object', properties: { z: { type: ['number', 'null'] } } },
    },
  };
  const copy = JSON.parse(JSON.stringify(input));
  const out = toGeminiSchema(input) as any;
  assert.deepEqual(input, copy);
  assert.deepEqual(out.required, ['pattern']);
  assert.deepEqual(out.properties.pattern, { type: 'string' });
  assert.deepEqual(out.properties.list.items, { anyOf: [{ type: 'string', enum: ['a'] }, { type: 'null' }] });
  assert.equal(out.properties.list.minItems, 1);
  assert.deepEqual(out.properties.alt, { anyOf: [{ type: 'string' }, { type: 'null' }] });
  assert.deepEqual(out.properties.nest.properties.z, { anyOf: [{ type: 'number' }, { type: 'null' }] });
});

Deno.test('toGeminiSchema: real tools convert cleanly (no null in enum, typed enums, no dropped keywords)', () => {
  for (const tool of [planTool(known), checkinTool(known)]) {
    walk(toGeminiSchema(tool.input_schema), (o) => {
      if (Array.isArray(o.enum)) { assert.ok(!o.enum.includes(null)); assert.equal(typeof o.type, 'string'); }
      assert.ok(!Array.isArray(o.type));
      for (const k of ['pattern', 'maxLength', 'minLength']) assert.ok(!(k in o) || typeof o[k] === 'object');
    });
  }
});

const seq = (...rs: (() => Response)[]) => {
  const bodies: any[] = [];
  let i = 0;
  const fetchImpl = ((_u: string, init: RequestInit) => { bodies.push(JSON.parse(init.body as string)); return Promise.resolve(rs[Math.min(i++, rs.length - 1)]()); }) as unknown as typeof fetch;
  return { fetchImpl, bodies };
};
const r400 = () => new Response('{"error":{"status":"INVALID_ARGUMENT"}}', { status: 400 });
const r503 = () => new Response('{"error":{"status":"UNAVAILABLE"}}', { status: 503 });

Deno.test('gemini 400 ladder: without thinking, then without schema, then success', async () => {
  const { fetchImpl, bodies } = seq(r400, r400, () => okResponse(goodPlan()));
  const r = await callGemini(req(), { apiKey: 'k', fetchImpl, sleep: noSleep });
  assert.deepEqual(r.input, goodPlan());
  assert.equal(bodies.length, 3);
  assert.ok(bodies[0].generationConfig.thinkingConfig && bodies[0].generationConfig.responseJsonSchema);
  assert.ok(!bodies[1].generationConfig.thinkingConfig && bodies[1].generationConfig.responseJsonSchema);
  const g = bodies[2].generationConfig;
  assert.ok(!g.thinkingConfig && !g.responseJsonSchema);
  assert.equal(g.responseMimeType, 'application/json');
  const parts = bodies[2].systemInstruction.parts;
  assert.match(parts[parts.length - 1].text, /^Reply with one JSON object matching this JSON schema: \{/);
  assert.ok(parts[parts.length - 1].text.includes(JSON.stringify(planTool(known).input_schema)));
});

Deno.test('gemini 503: backs off 800ms then 2000ms and succeeds', async () => {
  const slept: number[] = [];
  const { fetchImpl, bodies } = seq(r503, r503, () => okResponse(goodPlan()));
  await callGemini(req(), { apiKey: 'k', fetchImpl, sleep: (ms) => { slept.push(ms); return Promise.resolve(); } });
  assert.deepEqual(slept, [800, 2000]);
  assert.equal(bodies.length, 3);
});

Deno.test('gemini 503 exhausted: retryable "gemini overloaded:" error', async () => {
  const { fetchImpl, bodies } = seq(r503);
  await assert.rejects(callGemini(req(), { apiKey: 'k', fetchImpl, sleep: noSleep }),
    (e: any) => e.retryable === true && /^gemini overloaded:/.test(e.message));
  assert.equal(bodies.length, 3);
});

Deno.test('ai.ts: overloaded model falls back to GEMINI_MODEL_FALLBACK (or AI_MODEL_FALLBACK) once', async () => {
  const urls: string[] = [];
  const fetchImpl = ((url: string) => { urls.push(url); return Promise.resolve(url.includes(GEMINI_MODEL_DEFAULT) ? r503() : okResponse(goodPlan())); }) as unknown as typeof fetch;
  const ai = resolveAi((k) => ({ GEMINI_API_KEY: 'g' } as Record<string, string>)[k], fetchImpl, noSleep);
  const r = await ai.call(req(GEMINI_MODEL_DEFAULT));
  assert.deepEqual(r.input, goodPlan());
  assert.equal(urls.length, 4);
  assert.ok(urls[3].includes(`/${GEMINI_MODEL_FALLBACK}:`));

  urls.length = 0;
  const ai2 = resolveAi((k) => ({ GEMINI_API_KEY: 'g', AI_MODEL_FALLBACK: 'gemini-custom' } as Record<string, string>)[k], fetchImpl, noSleep);
  await ai2.call(req(GEMINI_MODEL_DEFAULT));
  assert.ok(urls[3].includes('/gemini-custom:'));

  // fallback equal to requested model: no extra attempt
  urls.length = 0;
  const alwaysDown = (() => { urls.push('x'); return Promise.resolve(r503()); }) as unknown as typeof fetch;
  const ai3 = resolveAi((k) => ({ GEMINI_API_KEY: 'g', AI_MODEL_FALLBACK: GEMINI_MODEL_DEFAULT } as Record<string, string>)[k], alwaysDown, noSleep);
  await assert.rejects(ai3.call(req(GEMINI_MODEL_DEFAULT)), /gemini overloaded/);
  assert.equal(urls.length, 3);

  // non-retryable errors do not fall back
  urls.length = 0;
  const forbidden = (() => { urls.push('x'); return Promise.resolve(new Response('no', { status: 403 })); }) as unknown as typeof fetch;
  const ai4 = resolveAi((k) => ({ GEMINI_API_KEY: 'g' } as Record<string, string>)[k], forbidden, noSleep);
  await assert.rejects(ai4.call(req(GEMINI_MODEL_DEFAULT)), /gemini 403/);
  assert.equal(urls.length, 1);
});

Deno.test('escalation failure message carries both models errors, shortened', async () => {
  const long = 'x'.repeat(400);
  await assert.rejects(
    generateWithEscalation<PlanOutput>({
      startStrong: false, threshold: 0.6, models: { default: 'm1', strong: 'm2' },
      confidenceOf: (v) => v.confidence,
      validate: (input) => validatePlanOutput(input, known, { plantKnown: true }),
      call: (model) => Promise.reject(new Error(model === 'm1' ? `gemini 503: ${long}` : 'gemini 400: invalid')),
    }),
    (e: any) => e.reason === 'ai_error' && e.message.startsWith('default: gemini 503: ') && e.message.includes(' | strong: gemini 400: invalid') && e.message.length < 300);
});
