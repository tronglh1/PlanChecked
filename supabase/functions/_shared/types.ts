// Shared types for the Vườn Nhà Edge Functions (pure, no runtime imports).

export type TaskWindow = 'morning' | 'afternoon' | 'all_day';
export type Band = 'high' | 'medium' | 'low';

/** Code lists loaded from the DB (task_codes, problem_codes, reason_codes, milestone_codes). */
export interface KnownCodes {
  tasks: Map<string, { window: TaskWindow; intervalDays: number | null }>;
  problems: Set<string>;
  reasons: Set<string>;
  milestones: Set<string>;
}

export interface PlanStage {
  code: string;
  day_from: number;
  day_to: number;
  milestone: string | null;
  name_vi?: string;
  name_en?: string;
}

export interface PlanTask {
  task: string;
  stage: string;
  every_d: number; // 0 = once, 1 = daily, n = every n days
  window: TaskWindow;
  offset_d: number;
  why: string | null;
}

export interface NewPlantText {
  plant: {
    name_vi: string;
    name_en: string;
    scientific_name: string | null;
    group: 'rau_qua' | 'cay_canh';
    difficulty: 'easy' | 'medium' | 'hard';
    days_to_harvest: number;
  };
  stages: { code: string; name_vi: string; name_en: string }[];
}

export interface PlanOutput {
  confidence: number;
  stages: PlanStage[];
  tasks: PlanTask[];
  new_text: NewPlantText | null;
}

export interface ValidationOk<T> {
  ok: true;
  value: T;
  /** Items the validator removed or clamped (unknown codes, out-of-range params). */
  dropped: string[];
}
export interface ValidationFail {
  ok: false;
  errors: string[];
}
export type Validation<T> = ValidationOk<T> | ValidationFail;

export type DeltaOp =
  | { op: 'add'; task: string; stage: string | null; every_d: number | null; window: TaskWindow | null; why: string | null }
  | { op: 'remove'; task: string; why: string | null }
  | { op: 'change_freq'; task: string; every_d: number; why: string | null }
  | { op: 'shift'; milestone: string; to: string; why: string | null };

export interface CheckinIssue {
  code: string;
  confidence: number;
  severity: 1 | 2 | 3;
  actions: { task: string }[];
}

export type CheckinOutput =
  | { status: 'retake'; reason: RetakeReason; hint_code: string }
  | {
      status: 'ok';
      stage_est: { code: string; confidence: number } | null;
      health: { value: 'good' | 'fair' | 'poor'; confidence: number };
      issues: CheckinIssue[];
      milestone_seen: { code: string; confidence: number } | null;
      delta: DeltaOp[];
      reason_codes: string[];
    };

export type RetakeReason = 'BLUR' | 'DARK' | 'TOO_FAR' | 'NOT_PLANT';

export interface Usage {
  input_tokens: number;
  output_tokens: number;
  cache_read_input_tokens: number;
  cache_creation_input_tokens: number;
}

export interface ClaudeResult {
  input: unknown;
  usage: Usage;
  model: string;
}

/** Compact context cards (spec §5). */
export interface PlantCard {
  id: string | null;
  name: string;
  group: 'rau_qua' | 'cay_canh';
  known: boolean;
  days_to_harvest: number | null;
  stages: { code: string; from: number; to: number; ms: string | null }[];
  problems_top: string[];
  toxic_child: boolean;
  toxic_pet: boolean;
}

export interface UserCard {
  experience: 'new' | 'mid' | 'pro';
  time_budget: string;
  prefer_organic: boolean;
  lang: 'vi' | 'en';
}

export interface ProjectCard {
  plant: string;
  stage: string;
  day: number;
  zone: string;
  season: string;
  space: string;
  sun: number;
  pot: string | null;
  water: string;
  adherence_14d: number | null;
  skipped: string[];
  checkins: { d: number; health: string }[];
  history_summary?: string;
  active_issues: { code: string; sev: number }[];
  applied_changes: string[];
}
