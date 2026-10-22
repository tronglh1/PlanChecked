// Gemini generateContent client (plain fetch). Same request shape and result as callClaude, so the
// escalation logic and validators stay provider-neutral. The tool's input_schema becomes the JSON
// response schema, which forces output that matches it.
import { GEMINI_URL_BASE } from './constants.ts';
import { ClaudeError, type ClaudeDeps, type ClaudeRequest } from './anthropic.ts';
import type { ClaudeResult } from './types.ts';

/** Gemini rejects "too complex" response schemas with a bare 400 INVALID_ARGUMENT; numeric bounds,
 * item counts and long enums are the usual causes. validate.ts re-checks every output, so the schema
 * sent to Gemini drops those keywords (and, on a second try, the enums too). */
const DROPPED_KEYWORDS = new Set(['minimum', 'maximum', 'exclusiveMinimum', 'exclusiveMaximum', 'minItems', 'maxItems',
  'minLength', 'maxLength', 'pattern', 'uniqueItems']);

export function geminiSchema(schema: unknown, opts: { keepEnums?: boolean } = {}): unknown {
  const keepEnums = opts.keepEnums ?? true;
  if (Array.isArray(schema)) return schema.map((x) => geminiSchema(x, opts));
  if (!schema || typeof schema !== 'object') return schema;
  const out: Record<string, unknown> = {};
  for (const [k, v] of Object.entries(schema as Record<string, unknown>)) {
    if (DROPPED_KEYWORDS.has(k) || (!keepEnums && k === 'enum')) continue;
    // "properties" maps names to schemas: keep every name, simplify each value.
    out[k] = k === 'properties' && v && typeof v === 'object'
      ? Object.fromEntries(Object.entries(v as Record<string, unknown>).map(([n, p]) => [n, geminiSchema(p, opts)]))
      : geminiSchema(v, opts);
  }
  return out;
}

/** Gemini 3.x thinks at "medium" by default; thinking tokens count toward maxOutputTokens and add
 * latency, which truncated plans and hit the timeout. Low thinking plus a larger budget avoids both. */
export function buildGeminiBody(req: ClaudeRequest, opts: { thinking?: boolean; keepEnums?: boolean } = {}) {
  const thinking = opts.thinking ?? true;
  return {
    systemInstruction: { parts: req.system.map((b) => ({ text: b.text })) },
    contents: [{
      role: 'user',
      parts: req.content.map((b) => b.type === 'text'
        ? { text: b.text }
        : { inlineData: { mimeType: b.source.media_type, data: b.source.data } }),
    }],
    generationConfig: {
      maxOutputTokens: Math.max(req.maxTokens * 3, 8192),
      ...(thinking ? { thinkingConfig: { thinkingLevel: 'low' } } : {}),
      responseMimeType: 'application/json',
      responseJsonSchema: geminiSchema(req.tool.input_schema, { keepEnums: opts.keepEnums }),
    },
  };
}

/** One generateContent call. Retries twice with backoff on 429 / 5xx ("model overloaded" is common),
 * once on network / timeout, and once with a plainer schema (no enums) on a 400. Returns the parsed JSON. */
export async function callGemini(req: ClaudeRequest, deps: ClaudeDeps): Promise<ClaudeResult> {
  const doFetch = deps.fetchImpl ?? fetch;
  const sleep = deps.sleep ?? ((ms: number) => new Promise<void>((r) => setTimeout(r, ms)));
  let lastErr: ClaudeError | null = null;
  let thinking = true;   // dropped once if a model rejects thinkingConfig
  let keepEnums = true;  // dropped once if the schema is rejected as invalid
  let busy = 0;          // 429 / 5xx retries so far
  for (let attempt = 0; attempt < 5; attempt++) {
    if (attempt > 0) await sleep(busy > 0 ? 1000 * busy : 700);
    const ctrl = new AbortController();
    const timer = setTimeout(() => ctrl.abort(), req.timeoutMs);
    try {
      const res = await doFetch(`${GEMINI_URL_BASE}/${req.model}:generateContent`, {
        method: 'POST',
        headers: { 'content-type': 'application/json', 'x-goog-api-key': deps.apiKey },
        body: JSON.stringify(buildGeminiBody(req, { thinking, keepEnums })),
        signal: ctrl.signal,
      });
      if (!res.ok) {
        const retryable = res.status === 429 || res.status >= 500;
        const text = await res.text().catch(() => '');
        lastErr = new ClaudeError(`gemini ${res.status}: ${text.slice(0, 300)}`, res.status, retryable);
        if (res.status === 400 && thinking && /thinking/i.test(text)) { thinking = false; continue; }
        if (res.status === 400 && keepEnums) { keepEnums = false; continue; }
        if (!retryable || ++busy > 2) throw lastErr;
        continue;
      }
      const data = await res.json();
      const parts: { text?: string; thought?: boolean }[] = data.candidates?.[0]?.content?.parts ?? [];
      const text = parts.filter((p) => !p.thought && typeof p.text === 'string').map((p) => p.text).join('');
      if (!text) throw new ClaudeError(`no text in response (${data.candidates?.[0]?.finishReason ?? data.promptFeedback?.blockReason ?? 'no candidate'})`, res.status, false);
      let input: unknown;
      try {
        input = JSON.parse(text);
      } catch (_) {
        throw new ClaudeError(`response is not valid JSON (${data.candidates?.[0]?.finishReason ?? '?'})`, res.status, false);
      }
      const u = data.usageMetadata ?? {};
      const cached = u.cachedContentTokenCount ?? 0;
      return {
        input,
        model: data.modelVersion ?? req.model,
        usage: {
          input_tokens: Math.max(0, (u.promptTokenCount ?? 0) - cached),
          output_tokens: (u.candidatesTokenCount ?? 0) + (u.thoughtsTokenCount ?? 0),
          cache_read_input_tokens: cached,
          cache_creation_input_tokens: 0,
        },
      };
    } catch (e) {
      if (e instanceof ClaudeError) { lastErr = e; if (!e.retryable || busy > 2) throw e; continue; }   // busy > 2: out of 429/5xx retries
      lastErr = new ClaudeError(e instanceof Error ? e.message : 'network error', null, true);   // abort / network
      if (attempt >= 1) break;
    } finally {
      clearTimeout(timer);
    }
  }
  throw lastErr ?? new ClaudeError('unknown error', null, false);
}
