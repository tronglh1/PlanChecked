// Gemini generateContent client (plain fetch). Same request shape and result as callClaude, so the
// escalation logic and validators stay provider-neutral. The tool's input_schema becomes the JSON
// response schema, which forces output that matches it.
import { GEMINI_URL_BASE } from './constants.ts';
import { ClaudeError, type ClaudeDeps, type ClaudeRequest } from './anthropic.ts';
import type { ClaudeResult } from './types.ts';

/** Gemini 3.x thinks at "medium" by default; thinking tokens count toward maxOutputTokens and add
 * latency, which truncated plans and hit the timeout. Low thinking plus a larger budget avoids both. */
export function buildGeminiBody(req: ClaudeRequest, opts: { thinking?: boolean } = {}) {
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
      responseJsonSchema: req.tool.input_schema,
    },
  };
}

/** One generateContent call with one retry on 429 / 5xx / network / timeout. Returns the parsed JSON. */
export async function callGemini(req: ClaudeRequest, deps: ClaudeDeps): Promise<ClaudeResult> {
  const doFetch = deps.fetchImpl ?? fetch;
  const sleep = deps.sleep ?? ((ms: number) => new Promise<void>((r) => setTimeout(r, ms)));
  let lastErr: ClaudeError | null = null;
  let thinking = true;   // dropped once if a model rejects thinkingConfig
  for (let attempt = 0; attempt < 3; attempt++) {
    if (attempt > 0) await sleep(700);
    const ctrl = new AbortController();
    const timer = setTimeout(() => ctrl.abort(), req.timeoutMs);
    try {
      const res = await doFetch(`${GEMINI_URL_BASE}/${req.model}:generateContent`, {
        method: 'POST',
        headers: { 'content-type': 'application/json', 'x-goog-api-key': deps.apiKey },
        body: JSON.stringify(buildGeminiBody(req, { thinking })),
        signal: ctrl.signal,
      });
      if (!res.ok) {
        const retryable = res.status === 429 || res.status >= 500;
        const text = await res.text().catch(() => '');
        lastErr = new ClaudeError(`gemini ${res.status}: ${text.slice(0, 300)}`, res.status, retryable);
        if (res.status === 400 && thinking && /thinking/i.test(text)) { thinking = false; continue; }
        if (!retryable || attempt >= 1) throw lastErr;
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
      if (e instanceof ClaudeError) { lastErr = e; if (!e.retryable) throw e; continue; }
      lastErr = new ClaudeError(e instanceof Error ? e.message : 'network error', null, true);   // abort / network
      if (attempt >= 1) break;
    } finally {
      clearTimeout(timer);
    }
  }
  throw lastErr ?? new ClaudeError('unknown error', null, false);
}
