import assert from 'node:assert/strict';
import { AiFailure, buildBody, callClaude, estimateCost, generateWithEscalation, type ClaudeRequest } from './anthropic.ts';
import { MODEL_DEFAULT, MODEL_STRONG } from './constants.ts';
import { goodPlan, known } from './test_helpers.ts';
import { checkinTool, planSystem, planTool } from './prompts.ts';
import { validatePlanOutput } from './validate.ts';
import type { PlanOutput } from './types.ts';

const req = (model = MODEL_DEFAULT): ClaudeRequest => ({
  model, system: planSystem(known), tool: planTool(known), maxTokens: 1000, timeoutMs: 500,
  content: [{ type: 'text', text: 'hi' }],
});
const okResponse = (input: unknown, model = MODEL_DEFAULT) =>
  new Response(JSON.stringify({ model, content: [{ type: 'tool_use', name: 'submit_plan', input }], usage: { input_tokens: 100, output_tokens: 50, cache_read_input_tokens: 400 } }), { status: 200 });
const noSleep = () => Promise.resolve();

Deno.test('request: forced tool, cached system, correct endpoint headers', async () => {
  const body = buildBody(req());
  assert.deepEqual(body.tool_choice, { type: 'tool', name: 'submit_plan' });
  assert.equal(body.system[0].cache_control?.type, 'ephemeral');
  assert.equal(body.model, 'claude-haiku-5-5');

  let seen: { url: string; headers: Record<string, string> } | null = null;
  const fetchImpl = ((url: string, init: RequestInit) => {
    seen = { url, headers: init.headers as Record<string, string> };
    return Promise.resolve(okResponse(goodPlan()));
  }) as unknown as typeof fetch;
  const r = await callClaude(req(), { apiKey: 'sk-test', fetchImpl, sleep: noSleep });
  assert.equal(seen!.url, 'https://api.anthropic.com/v1/messages');
  assert.equal(seen!.headers['x-api-key'], 'sk-test');
  assert.equal(seen!.headers['anthropic-version'], '2023-06-01');
  assert.equal(r.usage.cache_read_input_tokens, 400);
  assert.equal((r.input as { confidence: number }).confidence, 0.86);
});

Deno.test('callClaude retries once on 429/5xx, not on 400', async () => {
  let calls = 0;
  const flaky = (() => { calls++; return Promise.resolve(calls === 1 ? new Response('busy', { status: 529 }) : okResponse(goodPlan())); }) as unknown as typeof fetch;
  await callClaude(req(), { apiKey: 'k', fetchImpl: flaky, sleep: noSleep });
  assert.equal(calls, 2);

  calls = 0;
  const bad = (() => { calls++; return Promise.resolve(new Response('nope', { status: 400 })); }) as unknown as typeof fetch;
  await assert.rejects(callClaude(req(), { apiKey: 'k', fetchImpl: bad, sleep: noSleep }), /anthropic 400/);
  assert.equal(calls, 1);

  calls = 0;
  const down = (() => { calls++; return Promise.reject(new Error('socket hang up')); }) as unknown as typeof fetch;
  await assert.rejects(callClaude(req(), { apiKey: 'k', fetchImpl: down, sleep: noSleep }), /socket hang up/);
  assert.equal(calls, 2);

  const noTool = (() => Promise.resolve(new Response(JSON.stringify({ content: [{ type: 'text', text: 'sorry' }] }), { status: 200 }))) as unknown as typeof fetch;
  await assert.rejects(callClaude(req(), { apiKey: 'k', fetchImpl: noTool, sleep: noSleep }), /no tool_use/);
});

function escalationArgs(responses: unknown[], opts: { startStrong?: boolean } = {}) {
  const models: string[] = [];
  const queue = [...responses];
  return {
    models,
    args: {
      startStrong: opts.startStrong ?? false,
      threshold: 0.6,
      confidenceOf: (v: PlanOutput) => v.confidence,
      validate: (i: unknown) => validatePlanOutput(i, known, { plantKnown: true }),
      call: (model: string) => {
        models.push(model);
        const next = queue.shift();
        if (next instanceof Error) return Promise.reject(next);
        return callClaude(req(model), { apiKey: 'k', sleep: noSleep, fetchImpl: (() => Promise.resolve(okResponse(next, model))) as unknown as typeof fetch });
      },
    },
  };
}

Deno.test('escalation: confident Haiku answer stays on Haiku', async () => {
  const { args, models } = escalationArgs([goodPlan()]);
  const r = await generateWithEscalation(args);
  assert.deepEqual(models, [MODEL_DEFAULT]);
  assert.equal(r.escalated, false);
  assert.equal(r.usage.input_tokens, 100);
});

Deno.test('escalation: low confidence escalates to Sonnet and keeps the better answer', async () => {
  const low = { ...goodPlan(), confidence: 0.4 };
  const better = { ...goodPlan(), confidence: 0.8 };
  const { args, models } = escalationArgs([low, better]);
  const r = await generateWithEscalation(args);
  assert.deepEqual(models, [MODEL_DEFAULT, MODEL_STRONG]);
  assert.equal(r.model, MODEL_STRONG);
  assert.equal(r.value.confidence, 0.8);
  assert.equal(r.usage.input_tokens, 200, 'usage of both calls is summed');
});

Deno.test('escalation: invalid Haiku output retries on Sonnet; unknown plant starts on Sonnet', async () => {
  const { args, models } = escalationArgs([{ garbage: true }, goodPlan()]);
  const r = await generateWithEscalation(args);
  assert.deepEqual(models, [MODEL_DEFAULT, MODEL_STRONG]);
  assert.equal(r.escalated, true);

  const s = escalationArgs([goodPlan()], { startStrong: true });
  await generateWithEscalation(s.args);
  assert.deepEqual(s.models, [MODEL_STRONG]);
});

Deno.test('escalation: when both models fail the caller gets AiFailure (=> seed fallback)', async () => {
  const bad = escalationArgs([{ garbage: true }, { garbage: true }]);
  await assert.rejects(generateWithEscalation(bad.args), (e: unknown) => e instanceof AiFailure && e.reason === 'invalid_output');
  const down = escalationArgs([new Error('x'), new Error('y')]);
  await assert.rejects(generateWithEscalation(down.args), (e: unknown) => e instanceof AiFailure && e.reason === 'ai_error');
});

Deno.test('cost estimate and tool schemas only allow known codes', () => {
  const c = estimateCost(MODEL_DEFAULT, { input_tokens: 1000, output_tokens: 1000, cache_read_input_tokens: 10000, cache_creation_input_tokens: 0 });
  assert.equal(c, 0.007);
  const tool = planTool(known).input_schema as { properties: { tasks: { items: { properties: { task: { enum: string[] } } } } } };
  assert.deepEqual(tool.properties.tasks.items.properties.task.enum.sort(), [...known.tasks.keys()].sort());
  const ck = checkinTool(known).input_schema as { properties: { issues: { items: { properties: { code: { enum: string[] } } } } } };
  assert.deepEqual(ck.properties.issues.items.properties.code.enum.sort(), [...known.problems].sort());
  assert.match(planSystem(known)[0].text, /Never state a dose/);
});
