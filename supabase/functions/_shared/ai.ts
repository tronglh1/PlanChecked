// Picks the AI provider from Supabase secrets. Gemini when AI_PROVIDER=gemini, or when only
// GEMINI_API_KEY is set; otherwise Anthropic. AI_MODEL_DEFAULT / AI_MODEL_STRONG override the models.
import { callClaude, type ClaudeRequest } from './anthropic.ts';
import { GEMINI_MODEL_DEFAULT, GEMINI_MODEL_STRONG, MODEL_DEFAULT, MODEL_STRONG } from './constants.ts';
import { callGemini } from './gemini.ts';
import { HttpError } from './http.ts';
import type { ClaudeResult } from './types.ts';

export type AiProvider = 'anthropic' | 'gemini';

export interface AiClient {
  provider: AiProvider;
  models: { default: string; strong: string };
  call: (req: ClaudeRequest) => Promise<ClaudeResult>;
}

export function resolveAi(env: (k: string) => string | undefined, fetchImpl?: typeof fetch): AiClient {
  const explicit = env('AI_PROVIDER')?.trim().toLowerCase();
  const provider: AiProvider = explicit === 'gemini' || explicit === 'anthropic'
    ? explicit
    : env('GEMINI_API_KEY') && !env('ANTHROPIC_API_KEY') ? 'gemini' : 'anthropic';
  const keyName = provider === 'gemini' ? 'GEMINI_API_KEY' : 'ANTHROPIC_API_KEY';
  const apiKey = env(keyName);
  if (!apiKey) throw new HttpError(500, 'server_misconfigured', `missing ${keyName}`);
  const defaults = provider === 'gemini'
    ? { default: GEMINI_MODEL_DEFAULT, strong: GEMINI_MODEL_STRONG }
    : { default: MODEL_DEFAULT, strong: MODEL_STRONG };
  const models = { default: env('AI_MODEL_DEFAULT') || defaults.default, strong: env('AI_MODEL_STRONG') || defaults.strong };
  const call = provider === 'gemini' ? callGemini : callClaude;
  return { provider, models, call: (req) => call(req, { apiKey, fetchImpl }) };
}

export const requireAi = (): AiClient => resolveAi((k) => Deno.env.get(k));
