// Gemini generateContent client (plain fetch). Same request shape and result as callClaude, so the
// escalation logic and validators stay provider-neutral. The tool's input_schema becomes the JSON
// response schema, which forces output that matches it.
import { GEMINI_URL_BASE } from './constants.ts';
import { ClaudeError, type ClaudeDeps, type ClaudeRequest } from './anthropic.ts';
import type { ClaudeResult } from './types.ts';

const DROP_KEYS = new Set(['pattern', 'maxLength', 'minLength']);
const isObj = (v: unknown): v is Record<string, unknown> => typeof v === 'object' && v !== null && !Array.isArray(v);

/**
 * Converts a tool input_schema to a conservative schema Gemini accepts: every enum has a type, nullable
 * values use anyOf with {type:'null'} (never null inside enum or a type array), and keywords Gemini
 * rejects (pattern, minLength, maxLength) are dropped. Pure; does not mutate its input.
 */
export function toGeminiSchema(schema: unknown): unknown {
  if (Array.isArray(schema)) return schema.map(toGeminiSchema);
  if (!isObj(schema)) return schema;
  const node: Record<string, unknown> = {};
  for (const [k, v] of Object.entries(schema)) if (!DROP_KEYS.has(k)) node[k] = v;

  // type: [X, 'null'] -> anyOf [{type: X, ...rest}, {type:'null'}]
  if (Array.isArray(node.type)) {
    const types = (node.type as unknown[]).filter((t) => t !== 'null');
    const nullable = types.length !== (node.type as unknown[]).length;
    const { type: _t, ...rest } = node;
    const variants = types.map((t) => toGeminiSchema({ ...rest, type: t }));
    if (nullable) variants.push({ type: 'null' });
    return variants.length === 1 ? variants[0] : { anyOf: variants };
  }

  // enum: needs a type; null is expressed through anyOf
  if (Array.isArray(node.enum)) {
    const all = node.enum as unknown[];
    const vals = all.filter((v) => v !== null);
    const hasNull = vals.length !== all.length;
    const inferred = vals.length > 0 && vals.every((v) => typeof v === 'number')
      ? (vals.every((v) => Number.isInteger(v)) ? 'integer' : 'number')
      : 'string';
    const inner: Record<string, unknown> = { ...node, type: node.type === 'null' || node.type === undefined ? inferred : node.type, enum: vals };
    return hasNull ? { anyOf: [inner, { type: 'null' }] } : inner;
  }

  if (isObj(node.properties)) {
    node.properties = Object.fromEntries(Object.entries(node.properties).map(([k, v]) => [k, toGeminiSchema(v)]));
  }
  if (node.items !== undefined) node.items = toGeminiSchema(node.items);
  if (Array.isArray(node.anyOf)) node.anyOf = node.anyOf.map(toGeminiSchema);
  return node;
}

export interface GeminiVariant { name: 'full' | 'no-thinking' | 'no-schema'; thinking: boolean; schema: boolean }
/** Request variants tried in order when Gemini answers 400 INVALID_ARGUMENT. */
export const GEMINI_VARIANTS: GeminiVariant[] = [
  { name: 'full', thinking: true, schema: true },
  { name: 'no-thinking', thinking: false, schema: true },
  { name: 'no-schema', thinking: false, schema: false },
];

/** Gemini 3.x thinks at "medium" by default; thinking tokens count toward maxOutputTokens and add
 * latency, which truncated plans and hit the timeout. Low thinking plus a larger budget avoids both.
 * Without `schema`, the JSON schema moves into the system instruction as plain text. */
export function buildGeminiBody(req: ClaudeRequest, opts: { thinking?: boolean; schema?: boolean } = {}) {
  const thinking = opts.thinking ?? true;
  const schema = opts.schema ?? true;
  const system = req.system.map((b) => ({ text: b.text }));
  if (!schema) {
    system.push({ text: `Reply with one JSON object matching this JSON schema: ${JSON.stringify(req.tool.input_schema)}` });
  }
  return {
    systemInstruction: { parts: system },
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
      ...(schema ? { responseJsonSchema: toGeminiSchema(req.tool.input_schema) } : {}),
    },
  };
}

const OVERLOAD_BACKOFF_MS = [800, 2000];

/**
 * One generateContent call. 400 walks the GEMINI_VARIANTS ladder; 503/429 retry with backoff (then a
 * retryable "gemini overloaded:" error); other 5xx / network / timeout retry once. Returns the parsed JSON.
 */
export async function callGemini(req: ClaudeRequest, deps: ClaudeDeps): Promise<ClaudeResult> {
  const doFetch = deps.fetchImpl ?? fetch;
  const sleep = deps.sleep ?? ((ms: number) => new Promise<void>((r) => setTimeout(r, ms)));
  let lastErr: ClaudeError | null = null;
  let vi = 0;
  let overloads = 0;
  let others = 0;
  for (;;) {
    const variant = GEMINI_VARIANTS[vi];
    const ctrl = new AbortController();
    const timer = setTimeout(() => ctrl.abort(), req.timeoutMs);
    try {
      const res = await doFetch(`${GEMINI_URL_BASE}/${req.model}:generateContent`, {
        method: 'POST',
        headers: { 'content-type': 'application/json', 'x-goog-api-key': deps.apiKey },
        body: JSON.stringify(buildGeminiBody(req, variant)),
        signal: ctrl.signal,
      });
      if (!res.ok) {
        const text = await res.text().catch(() => '');
        if (res.status === 400 && vi < GEMINI_VARIANTS.length - 1) { vi++; continue; }
        if (res.status === 400) {
          const tried = GEMINI_VARIANTS.map((v) => v.name).join(' > ');
          throw new ClaudeError(`gemini 400 (failed variant: ${variant.name}; tried ${tried}): ${text.slice(0, 300)}`, 400, false);
        }
        if (res.status === 503 || res.status === 429) {
          if (overloads < OVERLOAD_BACKOFF_MS.length) { await sleep(OVERLOAD_BACKOFF_MS[overloads++]); continue; }
          throw new ClaudeError(`gemini overloaded: ${res.status}: ${text.slice(0, 300)}`, res.status, true);
        }
        const retryable = res.status >= 500;
        lastErr = new ClaudeError(`gemini ${res.status}: ${text.slice(0, 300)}`, res.status, retryable);
        if (!retryable || others >= 1) throw lastErr;
        others++;
        await sleep(700);
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
      if (e instanceof ClaudeError) throw e;
      lastErr = new ClaudeError(e instanceof Error ? e.message : 'network error', null, true);   // abort / network
      if (others >= 1) throw lastErr;
      others++;
      await sleep(700);
    } finally {
      clearTimeout(timer);
    }
  }
}
