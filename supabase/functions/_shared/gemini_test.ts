import assert from 'node:assert/strict';
import { resolveAi } from './ai.ts';
import { generateWithEscalation, type ClaudeRequest } from './anthropic.ts';
import { GEMINI_MODEL_DEFAULT, GEMINI_MODEL_STRONG, MODEL_DEFAULT } from './constants.ts';
import { buildGeminiBody, callGemini } from './gemini.ts';
import { goodPlan, known } from './test_helpers.ts';
import { planSystem, planTool } from './prompts.ts';
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
  assert.deepEqual(body.generationConfig.responseJsonSchema, planTool(known).input_schema);
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
  await assert.rejects(callGemini(req(), { apiKey: 'k', fetchImpl: bad, sleep: noSleep }), /gemini 400/);
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
