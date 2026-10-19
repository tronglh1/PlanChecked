// Anthropic Messages API client (plain fetch), forced tool output, retry, Haiku -> Sonnet escalation.
import { ANTHROPIC_URL, ANTHROPIC_VERSION, DEFAULT_PRICES, MODEL_DEFAULT, MODEL_STRONG } from './constants.ts';
import type { ClaudeResult, Usage, Validation } from './types.ts';

export interface ToolDef {
  name: string;
  description: string;
  input_schema: Record<string, unknown>;
}

export interface SystemBlock {
  type: 'text';
  text: string;
  cache_control?: { type: 'ephemeral' };
}

export type ContentBlock =
  | { type: 'text'; text: string; cache_control?: { type: 'ephemeral' } }
  | { type: 'image'; source: { type: 'base64'; media_type: 'image/jpeg' | 'image/png' | 'image/webp'; data: string } };

export interface ClaudeRequest {
  model: string;
  system: SystemBlock[];
  /** Single user turn; order = plant card -> project card -> images (prompt-cache friendly). */
  content: ContentBlock[];
  tool: ToolDef;
  maxTokens: number;
  timeoutMs: number;
}

export interface ClaudeDeps {
  apiKey: string;
  fetchImpl?: typeof fetch;
  sleep?: (ms: number) => Promise<void>;
}

export class ClaudeError extends Error {
  constructor(message: string, public status: number | null, public retryable: boolean) {
    super(message);
  }
}

export class AiFailure extends Error {
  constructor(public reason: 'ai_error' | 'invalid_output', message: string, public usage: Usage, public model: string | null) {
    super(message);
  }
}

export const emptyUsage = (): Usage => ({ input_tokens: 0, output_tokens: 0, cache_read_input_tokens: 0, cache_creation_input_tokens: 0 });
export function addUsage(a: Usage, b: Usage): Usage {
  return {
    input_tokens: a.input_tokens + b.input_tokens,
    output_tokens: a.output_tokens + b.output_tokens,
    cache_read_input_tokens: a.cache_read_input_tokens + b.cache_read_input_tokens,
    cache_creation_input_tokens: a.cache_creation_input_tokens + b.cache_creation_input_tokens,
  };
}

export function buildBody(req: ClaudeRequest) {
  return {
    model: req.model,
    max_tokens: req.maxTokens,
    system: req.system,
    messages: [{ role: 'user', content: req.content }],
    tools: [req.tool],
    tool_choice: { type: 'tool', name: req.tool.name },   // forces JSON that matches the tool schema
  };
}

/** One Messages API call with one retry on 429 / 5xx / network / timeout. Returns the tool_use input. */
export async function callClaude(req: ClaudeRequest, deps: ClaudeDeps): Promise<ClaudeResult> {
  const doFetch = deps.fetchImpl ?? fetch;
  const sleep = deps.sleep ?? ((ms: number) => new Promise<void>((r) => setTimeout(r, ms)));
  let lastErr: ClaudeError | null = null;
  for (let attempt = 0; attempt < 2; attempt++) {
    if (attempt > 0) await sleep(700);
    const ctrl = new AbortController();
    const timer = setTimeout(() => ctrl.abort(), req.timeoutMs);
    try {
      const res = await doFetch(ANTHROPIC_URL, {
        method: 'POST',
        headers: { 'content-type': 'application/json', 'x-api-key': deps.apiKey, 'anthropic-version': ANTHROPIC_VERSION },
        body: JSON.stringify(buildBody(req)),
        signal: ctrl.signal,
      });
      if (!res.ok) {
        const retryable = res.status === 429 || res.status >= 500;
        lastErr = new ClaudeError(`anthropic ${res.status}`, res.status, retryable);
        await res.text().catch(() => '');
        if (!retryable) throw lastErr;
        continue;
      }
      const data = await res.json();
      const block = (data.content ?? []).find((b: { type: string }) => b.type === 'tool_use');
      if (!block) throw new ClaudeError('no tool_use block in response', res.status, false);
      const u = data.usage ?? {};
      return {
        input: block.input,
        model: data.model ?? req.model,
        usage: {
          input_tokens: u.input_tokens ?? 0,
          output_tokens: u.output_tokens ?? 0,
          cache_read_input_tokens: u.cache_read_input_tokens ?? 0,
          cache_creation_input_tokens: u.cache_creation_input_tokens ?? 0,
        },
      };
    } catch (e) {
      if (e instanceof ClaudeError) { lastErr = e; if (!e.retryable) throw e; continue; }
      lastErr = new ClaudeError(e instanceof Error ? e.message : 'network error', null, true);   // abort / network
    } finally {
      clearTimeout(timer);
    }
  }
  throw lastErr ?? new ClaudeError('unknown error', null, false);
}

export interface EscalationArgs<T> {
  /** Calls the model; the caller builds the request. */
  call: (model: string) => Promise<ClaudeResult>;
  validate: (input: unknown) => Validation<T>;
  confidenceOf: (v: T) => number;
  /** Start straight on the strong model (unknown plant). */
  startStrong: boolean;
  threshold: number;
  models?: { default: string; strong: string };
}

export interface EscalationResult<T> {
  value: T;
  dropped: string[];
  model: string;
  usage: Usage;
  escalated: boolean;
}

/**
 * Haiku first; escalate to Sonnet once when the output is invalid or confidence is below the threshold.
 * Throws AiFailure when no valid output could be produced.
 */
export async function generateWithEscalation<T>(a: EscalationArgs<T>): Promise<EscalationResult<T>> {
  const models = a.models ?? { default: MODEL_DEFAULT, strong: MODEL_STRONG };
  let usage = emptyUsage();
  let lastModel: string | null = null;
  const tryModel = async (model: string): Promise<{ value: T; dropped: string[] } | { error: string; transport: boolean }> => {
    try {
      const r = await a.call(model);
      lastModel = r.model;
      usage = addUsage(usage, r.usage);
      const v = a.validate(r.input);
      return v.ok ? { value: v.value, dropped: v.dropped } : { error: v.errors.join('; '), transport: false };
    } catch (e) {
      return { error: e instanceof Error ? e.message : String(e), transport: true };
    }
  };

  const first = a.startStrong ? models.strong : models.default;
  const r1 = await tryModel(first);
  if ('value' in r1) {
    if (first === models.strong || a.confidenceOf(r1.value) >= a.threshold) {
      return { ...r1, model: first, usage, escalated: first === models.strong };
    }
    const r2 = await tryModel(models.strong);
    if ('value' in r2 && a.confidenceOf(r2.value) >= a.confidenceOf(r1.value)) return { ...r2, model: models.strong, usage, escalated: true };
    return { ...r1, model: first, usage, escalated: true };
  }
  if (first === models.default) {
    const r2 = await tryModel(models.strong);
    if ('value' in r2) return { ...r2, model: models.strong, usage, escalated: true };
    throw new AiFailure(r2.transport && r1.transport ? 'ai_error' : 'invalid_output', r2.error, usage, lastModel);
  }
  throw new AiFailure(r1.transport ? 'ai_error' : 'invalid_output', r1.error, usage, lastModel);
}

/** Estimated cost in USD for a usage record (prices: env MODEL_PRICES_JSON or DEFAULT_PRICES). */
export function estimateCost(model: string, u: Usage, prices: Record<string, { in: number; out: number; cache_read: number }> = DEFAULT_PRICES): number {
  const p = prices[model] ?? prices[MODEL_STRONG];
  const fresh = u.input_tokens + u.cache_creation_input_tokens;
  return Math.round(((fresh * p.in + u.output_tokens * p.out + u.cache_read_input_tokens * p.cache_read) / 1_000_000) * 100_000) / 100_000;
}
