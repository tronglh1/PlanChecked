// Pure builders for the compact context sent to the model (spec §5): plant card, project card, user card,
// plus template-key and season helpers. No I/O here, so everything is unit-testable.
import type { PlantCard, ProjectCard, UserCard } from './types.ts';

export type Zone = 'VN_N' | 'VN_C' | 'VN_S';

/** YYYY-MM-DD of an instant in an IANA timezone (falls back to Ho Chi Minh). */
export function localDate(tz: string | null | undefined, at: Date = new Date()): string {
  try {
    return new Intl.DateTimeFormat('en-CA', { timeZone: tz || 'Asia/Ho_Chi_Minh', year: 'numeric', month: '2-digit', day: '2-digit' }).format(at);
  } catch (_) {
    return new Intl.DateTimeFormat('en-CA', { timeZone: 'Asia/Ho_Chi_Minh', year: 'numeric', month: '2-digit', day: '2-digit' }).format(at);
  }
}

export function daysBetween(fromIso: string, toIso: string): number {
  return Math.round((Date.parse(toIso + 'T00:00:00Z') - Date.parse(fromIso + 'T00:00:00Z')) / 86_400_000);
}

/** South: rainy May-Oct / dry Nov-Apr. North and Centre: hot May-Oct / cool Nov-Apr. */
export function seasonFor(zone: string, isoDate: string): string {
  const month = Number(isoDate.slice(5, 7));
  const warm = month >= 5 && month <= 10;
  if (zone === 'VN_S') return warm ? 'rainy' : 'dry';
  return warm ? 'hot' : 'cool';
}

/** Spec §4.2 example: `basil|VN_S|rainy|seedling|balcony|sun3`. Built by the server, never trusted from the model. */
export function templateKey(p: { plantId: string; zone: string; season: string; startStage: string; space: string; sunLevel: number }): string {
  return [p.plantId, p.zone, p.season, p.startStage, p.space, `sun${p.sunLevel}`].join('|');
}

export function slugify(name: string): string {
  return name.normalize('NFD').replace(/[̀-ͯ]/g, '').replace(/đ/gi, 'd').toLowerCase()
    .replace(/[^a-z0-9]+/g, '_').replace(/^_+|_+$/g, '').slice(0, 40) || 'plant';
}

// ---------------------------------------------------------------- cards
export interface PlantRow {
  id: string; group: 'rau_qua' | 'cay_canh'; name_vi: string; name_en: string; days_to_harvest: number | null;
  toxic_child: boolean; toxic_pet: boolean; data_status?: string;
}
export interface StageRow { code: string; day_min: number; day_max: number; milestone_code: string | null }

export function buildPlantCard(plant: PlantRow | null, fallbackName: string, group: 'rau_qua' | 'cay_canh', stages: StageRow[], problems: string[]): PlantCard {
  return {
    id: plant?.id ?? null,
    name: plant ? plant.name_en : fallbackName,
    group: plant?.group ?? group,
    known: !!plant,
    days_to_harvest: plant?.days_to_harvest ?? null,
    stages: stages.map((s) => ({ code: s.code, from: s.day_min, to: s.day_max, ms: s.milestone_code })),
    problems_top: problems.slice(0, 6),
    toxic_child: plant?.toxic_child ?? false,
    toxic_pet: plant?.toxic_pet ?? false,
  };
}

export function buildUserCard(u: { experience?: string; time_budget?: string; prefer_organic?: boolean; lang?: string } | null): UserCard {
  return {
    experience: (['new', 'mid', 'pro'].includes(u?.experience ?? '') ? u!.experience : 'new') as UserCard['experience'],
    time_budget: u?.time_budget ?? '10-30p',
    prefer_organic: u?.prefer_organic ?? true,
    lang: u?.lang === 'en' ? 'en' : 'vi',
  };
}

export interface PlanContextInput {
  startDate: string; startStage: string; zone: string; season: string; space: string; sunLevel: number;
  pot: string | null; watering: string; hasChildren: boolean; hasPets: boolean; lessons: string[];
}

/** The `ai-plan` user message (spec §5.1 input), without plant card which is cached separately. */
export function buildPlanContext(i: PlanContextInput, plant: PlantCard, user: UserCard) {
  return {
    plant_id: plant.id ?? plant.name,
    start_date: i.startDate,
    start_stage: i.startStage,
    context: { zone: i.zone, season: i.season, space: i.space, sun_level: i.sunLevel, pot: i.pot, watering: i.watering },
    user: { experience: user.experience, time_budget: user.time_budget, prefer_organic: user.prefer_organic },
    household: { has_children: i.hasChildren, has_pets: i.hasPets },
    lessons: i.lessons.slice(0, 3).map((l) => l.slice(0, 160)),
  };
}

// ---------------------------------------------------------------- project card (check-in)
export interface OccurrenceRow { due_date: string; state: string }
export interface CheckinRow { created_day: number; status: string; ai_result: { health?: { value?: string }; issues?: { code: string; severity?: number }[] } | null }
export interface ChangeRow { change_kind: string; payload: { task?: string; milestone?: string } }

/** Share of due occurrences in the last 14 days that were done (null when nothing was due). */
export function adherence14d(occ: OccurrenceRow[], today: string): number | null {
  const due = occ.filter((o) => { const d = daysBetween(o.due_date, today); return d >= 0 && d < 14 && !(d === 0 && o.state === 'pending'); });
  if (!due.length) return null;
  return Math.round((due.filter((o) => o.state === 'done').length / due.length) * 100) / 100;
}

export function skippedSummary(skips: string[], minCount = 2): string[] {
  const c = new Map<string, number>();
  for (const s of skips) c.set(s, (c.get(s) ?? 0) + 1);
  return [...c.entries()].filter(([, n]) => n >= 1).sort((a, b) => b[1] - a[1]).slice(0, 4)
    .map(([code, n]) => (n >= minCount ? `${code} x${n}` : code));
}

export function stageForDay(stages: { code: string; day_from: number; day_to: number }[], day: number): string {
  if (!stages.length) return 'S1';
  const hit = stages.find((s) => day >= s.day_from && day <= s.day_to);
  if (hit) return hit.code;
  return day < stages[0].day_from ? stages[0].code : stages[stages.length - 1].code;
}

export interface ProjectCardInput {
  plantId: string; day: number; stage: string; zone: string; season: string; space: string; sun: number;
  pot: string | null; water: string; occurrences: OccurrenceRow[]; today: string; skipCodes: string[];
  /** Newest first, only analyzed/approved ones. */
  checkins: CheckinRow[]; changes: ChangeRow[];
}

/** Project card, ~300-500 tokens: last 3 check-ins in full, older ones folded into history_summary (spec §5.2). */
export function buildProjectCard(i: ProjectCardInput): ProjectCard {
  const recent = i.checkins.slice(0, 3);
  const older = i.checkins.slice(3);
  const card: ProjectCard = {
    plant: i.plantId, stage: i.stage, day: i.day, zone: i.zone, season: i.season, space: i.space, sun: i.sun,
    pot: i.pot, water: i.water,
    adherence_14d: adherence14d(i.occurrences, i.today),
    skipped: skippedSummary(i.skipCodes),
    checkins: recent.map((c) => ({ d: c.created_day, health: c.ai_result?.health?.value ?? 'unknown' })).reverse(),
    active_issues: (recent[0]?.ai_result?.issues ?? []).slice(0, 3).map((x) => ({ code: x.code, sev: x.severity ?? 1 })),
    applied_changes: i.changes.slice(0, 5).map((c) => `${c.payload.task ?? c.payload.milestone ?? '?'}:${c.change_kind}`),
  };
  if (older.length) {
    const issueCounts = new Map<string, number>();
    for (const c of older) for (const x of c.ai_result?.issues ?? []) issueCounts.set(x.code, (issueCounts.get(x.code) ?? 0) + 1);
    const top = [...issueCounts.entries()].sort((a, b) => b[1] - a[1]).slice(0, 3).map(([k, n]) => `${k}x${n}`);
    card.history_summary = `${older.length} earlier check-ins` + (top.length ? `; issues: ${top.join(', ')}` : '; no issues');
  }
  return card;
}

/** Spec §5.2: skip the AI call if the project was analyzed < 24 h ago and the user adds no new tag. */
export function shouldSkipRecent(lastAnalyzedAt: string | null, lastTags: string[], newTags: string[], now: Date = new Date()): boolean {
  if (!lastAnalyzedAt) return false;
  const ageMs = now.getTime() - Date.parse(lastAnalyzedAt);
  if (!(ageMs >= 0 && ageMs < 24 * 3600 * 1000)) return false;
  return newTags.every((t) => lastTags.includes(t));
}
