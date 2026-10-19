// Tunable constants. Values that product may change at runtime live in the DB table app_config instead.

export const MODEL_DEFAULT = 'claude-haiku-5-5';
export const MODEL_STRONG = 'claude-sonnet-5-5';

export const ANTHROPIC_URL = 'https://api.anthropic.com/v1/messages';
export const ANTHROPIC_VERSION = '2023-06-01';

/** Escalate Haiku -> Sonnet below this confidence (app_config.ai_escalate_below overrides). */
export const ESCALATE_BELOW = 0.6;
export const BAND_HIGH = 0.75;
export const BAND_MEDIUM = 0.5;
/** A milestone is only recorded (and XP awarded) when the model is at least this sure. */
export const MILESTONE_MIN_CONFIDENCE = 0.75;

export const PLAN_TIMEOUT_MS = 18_000;
export const CHECKIN_TIMEOUT_MS = 14_000;

export const MAX_STAGES = 10;
export const MAX_TASKS = 80;
export const MAX_DAYS = 730;
export const MAX_DELTA = 6;
export const MAX_ISSUES = 4;
export const MAX_IMAGES = 3;
export const MAX_IMAGE_BYTES = 1_500_000;

export const RETAKE_REASONS = ['BLUR', 'DARK', 'TOO_FAR', 'NOT_PLANT'] as const;
export const HINT_CODES = ['H_RETAKE_LIGHT', 'H_RETAKE_BLUR', 'H_RETAKE_FRAMING', 'H_RETAKE_NOT_PLANT'] as const;
export const HINT_FOR_REASON: Record<string, string> = {
  BLUR: 'H_RETAKE_BLUR',
  DARK: 'H_RETAKE_LIGHT',
  TOO_FAR: 'H_RETAKE_FRAMING',
  NOT_PLANT: 'H_RETAKE_NOT_PLANT',
};

export const WINDOWS = ['morning', 'afternoon', 'all_day'] as const;
export const HEALTH_VALUES = ['good', 'fair', 'poor'] as const;

/** USD per million tokens. Placeholders: override with env MODEL_PRICES_JSON = {"model":{"in":x,"out":y,"cache_read":z}}. */
export const DEFAULT_PRICES: Record<string, { in: number; out: number; cache_read: number }> = {
  [MODEL_DEFAULT]: { in: 1, out: 5, cache_read: 0.1 },
  [MODEL_STRONG]: { in: 3, out: 15, cache_read: 0.3 },
};

/** Anything that looks like a dose, amount or concentration is rejected from AI-written text (spec §5.3). */
export const DOSE_RE = /\d\s*(ml|mg|g|kg|l|lít|%|ppm|muỗng|thìa|tsp|tbsp|gram)(?![a-zà-ỹ])/i;
