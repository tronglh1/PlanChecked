// System prompts + tool (JSON schema) definitions. Enums come from the DB code lists, so the model can only
// pick known codes; validate.ts re-checks everything anyway.
import { HINT_CODES, MAX_DELTA, RETAKE_REASONS, WINDOWS } from './constants.ts';
import type { ToolDef, SystemBlock } from './anthropic.ts';
import type { KnownCodes } from './types.ts';

const SAFETY = `Safety rules (mandatory):
- Never state a dose, amount, concentration or product quantity for fertilizer, pesticide or any chemical. If a product is relevant, only say to follow the product label.
- Prefer organic and gentle actions first (rinse, hand-pick, prune, adjust watering, light, drainage).
- Output only codes and numbers from the provided lists. Do not write free text sentences.
- If unsure, lower the confidence value instead of guessing. Never invent a plant, problem or task code.
- Toxicity warnings are handled by the app, not by you.`;

function codeLists(known: KnownCodes): string {
  const tasks = [...known.tasks.entries()].map(([c, v]) => `${c}(${v.window}${v.intervalDays ? `,every ${v.intervalDays}d` : ''})`).join(' ');
  return `Task codes: ${tasks}\nProblem codes: ${[...known.problems].join(' ')}\nReason codes: ${[...known.reasons].join(' ')}\nMilestone codes: ${[...known.milestones].join(' ')}`;
}

export function planSystem(known: KnownCodes): SystemBlock[] {
  return [{
    type: 'text',
    cache_control: { type: 'ephemeral' },
    text: `You plan home plant care for Vietnamese growers (pots on balconies, indoors, yards, rooftops). You return a care plan as stages and recurring tasks by calling the tool submit_plan.

Plan rules:
- Stages are S1..Sn, contiguous day ranges starting at day 1, covering the plant life from the given start stage to harvest (edible) or about 180 days (ornamental).
- Each stage has a milestone code when a visible milestone ends it, otherwise null.
- Tasks: task code, stage, every_d (0 = once, 1 = daily, n = every n days), window (morning|afternoon|all_day), offset_d (days after stage start for the first run), why (reason code or null).
- Adapt watering frequency to the season, light level (sun_level 1 = very little sun .. 4 = full sun), pot, and whether watering is manual or automatic. Hot or high-sun settings need more frequent watering; rainy season less.
- Always include a T_CHECKIN task in every stage, every 3 to 7 days.
- Keep the plan realistic for the user's experience and time budget; beginners get fewer tasks.
- Use the same plan skeleton as the plant card when it lists stages; otherwise propose stages yourself.
- If the plant is not known (plant_card.known = false) fill new_text with plant facts (names, group, difficulty, days_to_harvest) and stage names in Vietnamese and English. If known, new_text must be null.
${SAFETY}

${codeLists(known)}`,
  }];
}

export function checkinSystem(known: KnownCodes): SystemBlock[] {
  return [{
    type: 'text',
    cache_control: { type: 'ephemeral' },
    text: `You assess plant health from photos for a home-grower app and suggest small changes to the care plan by calling the tool submit_checkin.

Rules:
- Always fill every field of the tool call; never omit one. Use null or an empty array when a field does not apply.
- If the photo is too blurry, too dark, too far away or does not show a plant, return status "retake" with a reason (${RETAKE_REASONS.join('|')}) and a hint_code (${HINT_CODES.join('|')}). Still fill health with your best guess and use null for stage_est and milestone_seen and empty arrays for issues, delta and reason_codes.
- Otherwise status "ok" with reason and hint_code both null: estimate stage (S-code from the project plan, optional suffix like _late), health (good|fair|poor) with confidence 0..1, up to ${4} issues using problem codes with confidence, severity 1..3 and suggested safe action task codes, an optional milestone_seen (only when clearly visible), and a delta.
- delta is at most ${MAX_DELTA} operations: add (task, stage), remove (task), change_freq (task, every_d), shift (milestone, to = ISO date). Only propose a change when the photo or the project card supports it. Prefer fewer, safer changes. No change is a valid answer.
- Use the project card history (adherence, skipped tasks, active issues, previous check-ins) to avoid repeating advice that was already applied.
- Tags given by the user (LEAF_YELLOW, WILT, PESTS, SPOTS) are hints, not facts: confirm from the image.
${SAFETY}

${codeLists(known)}`,
  }];
}

const conf = { type: 'number', minimum: 0, maximum: 1 };

export function planTool(known: KnownCodes): ToolDef {
  return {
    name: 'submit_plan',
    description: 'Submit the care plan as stages and tasks using only the allowed codes.',
    input_schema: {
      type: 'object',
      required: ['confidence', 'stages', 'tasks', 'new_text'],
      properties: {
        confidence: conf,
        stages: {
          type: 'array', minItems: 1, maxItems: 10,
          items: {
            type: 'object', required: ['code', 'day_from', 'day_to', 'milestone'],
            properties: {
              code: { type: 'string', pattern: '^S[0-9]{1,2}$' },
              day_from: { type: 'integer', minimum: 1 }, day_to: { type: 'integer', minimum: 1 },
              milestone: { enum: [...known.milestones, null] },
            },
          },
        },
        tasks: {
          type: 'array', maxItems: 80,
          items: {
            type: 'object', required: ['task', 'stage', 'every_d', 'window'],
            properties: {
              task: { enum: [...known.tasks.keys()] },
              stage: { type: 'string', pattern: '^S[0-9]{1,2}$' },
              every_d: { type: 'integer', minimum: 0, maximum: 60 },
              window: { enum: [...WINDOWS] },
              offset_d: { type: 'integer', minimum: 0 },
              why: { enum: [...known.reasons, null] },
            },
          },
        },
        new_text: {
          anyOf: [{ type: 'null' }, {
            type: 'object', required: ['plant', 'stages'],
            properties: {
              plant: {
                type: 'object', required: ['name_vi', 'name_en', 'group', 'difficulty', 'days_to_harvest'],
                properties: {
                  name_vi: { type: 'string', maxLength: 80 }, name_en: { type: 'string', maxLength: 80 },
                  scientific_name: { type: ['string', 'null'], maxLength: 80 },
                  group: { enum: ['rau_qua', 'cay_canh'] }, difficulty: { enum: ['easy', 'medium', 'hard'] },
                  days_to_harvest: { type: 'integer', minimum: 1 },
                },
              },
              stages: {
                type: 'array',
                items: { type: 'object', required: ['code', 'name_vi', 'name_en'], properties: {
                  code: { type: 'string' }, name_vi: { type: 'string', maxLength: 60 }, name_en: { type: 'string', maxLength: 60 } } },
              },
            },
          }],
        },
      },
    },
  };
}

export function checkinTool(known: KnownCodes): ToolDef {
  const taskEnum = { enum: [...known.tasks.keys()] };
  return {
    name: 'submit_checkin',
    description: 'Submit the photo assessment and plan delta, or ask for a retake.',
    input_schema: {
      type: 'object',
      required: ['status', 'reason', 'hint_code', 'stage_est', 'health', 'issues', 'milestone_seen', 'delta', 'reason_codes'],
      properties: {
        status: { enum: ['ok', 'retake'] },
        reason: { enum: [...RETAKE_REASONS, null] },
        hint_code: { enum: [...HINT_CODES, null] },
        stage_est: { anyOf: [{ type: 'null' }, { type: 'object', required: ['code', 'confidence'], properties: { code: { type: 'string' }, confidence: conf } }] },
        health: { type: 'object', required: ['value', 'confidence'], properties: { value: { enum: ['good', 'fair', 'poor'] }, confidence: conf } },
        issues: {
          type: 'array', maxItems: 4,
          items: { type: 'object', required: ['code', 'confidence', 'severity'], properties: {
            code: { enum: [...known.problems] }, confidence: conf, severity: { type: 'integer', minimum: 1, maximum: 3 },
            actions: { type: 'array', maxItems: 4, items: { type: 'object', required: ['task'], properties: { task: taskEnum } } } } },
        },
        milestone_seen: { anyOf: [{ type: 'null' }, { type: 'object', required: ['code', 'confidence'], properties: { code: { enum: [...known.milestones] }, confidence: conf } }] },
        delta: {
          type: 'array', maxItems: MAX_DELTA,
          items: { type: 'object', required: ['op'], properties: {
            op: { enum: ['add', 'remove', 'change_freq', 'shift'] },
            task: taskEnum, stage: { type: 'string' }, every_d: { type: 'integer', minimum: 0, maximum: 60 },
            window: { enum: [...WINDOWS] }, milestone: { enum: [...known.milestones] },
            to: { type: 'string', description: 'ISO date YYYY-MM-DD' }, why: { enum: [...known.reasons, null] } } },
        },
        reason_codes: { type: 'array', maxItems: 5, items: { enum: [...known.reasons] } },
      },
    },
  };
}
