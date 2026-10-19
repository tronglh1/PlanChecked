// Seed source: 30 plants popular with Vietnamese home growers (+2 hidden generic fallbacks).
// Each plant gets stages and a default task template built only from task/reason/milestone codes.
// This default plan is both the "template" seed and the fallback plan when the AI fails or the quota is reached.
// Facts here are authored, not expert-reviewed => data_status 'ai_unverified'.

// ---------------------------------------------------------------- archetypes
// stage: [code, name_vi, name_en, endFraction, milestone, phase]
const clampOffset = (off, len) => Math.max(0, Math.min(off, len - 1));

const archetypes = {
  leafy: {
    stages: [
      ['S1', 'Gieo hạt & nảy mầm', 'Sowing & germination', 0.15, 'SPROUT', 'seed'],
      ['S2', 'Cây con', 'Seedling', 0.4, 'TRUE_LEAVES', 'seedling'],
      ['S3', 'Phát triển lá', 'Leaf growth', 0.75, null, 'mature'],
      ['S4', 'Thu hoạch', 'Harvest', 1.0, 'HARVEST', 'mature'],
    ],
    tasks: (o, len) => [
      ['S1', 'T_SOW', 'morning', 0, 0, 'R_ROUTINE'],
      ['S1', 'T_WATER', 'morning', 1, 0, 'R_ESTABLISH_ROOTS'],
      ['S1', 'T_CHECKIN', 'all_day', 5, 3, 'R_CHECKIN_CADENCE'],
      ...(o.thin === false ? [] : [['S2', 'T_THIN', 'morning', 0, clampOffset(2, len.S2), 'R_STAGE_GROWTH']]),
      ['S2', 'T_WATER', 'morning', o.water ?? 1, 0, 'R_STAGE_GROWTH'],
      ['S2', 'T_PEST_CHECK', 'afternoon', 4, 1, 'R_PREVENT_PEST'],
      ['S2', 'T_CHECKIN', 'all_day', 5, 2, 'R_CHECKIN_CADENCE'],
      ['S3', 'T_WATER', 'morning', o.water ?? 1, 0, 'R_STAGE_GROWTH'],
      ['S3', 'T_FERT_ORGANIC', 'morning', o.fert ?? 12, 3, 'R_STAGE_GROWTH'],
      ['S3', 'T_PEST_CHECK', 'afternoon', 4, 1, 'R_PREVENT_PEST'],
      ...(o.pickPests ? [['S3', 'T_PICK_PESTS', 'morning', 3, 2, 'R_PREVENT_PEST']] : []),
      ['S3', 'T_CHECKIN', 'all_day', 5, 2, 'R_CHECKIN_CADENCE'],
      ['S4', 'T_HARVEST', 'morning', o.harvest ?? 3, 0, 'R_HARVEST_READY'],
      ['S4', 'T_WATER', 'morning', o.water ?? 1, 0, 'R_ROUTINE'],
      ['S4', 'T_CHECKIN', 'all_day', 7, 2, 'R_CHECKIN_CADENCE'],
    ],
  },
  herb: {
    stages: [
      ['S1', 'Gieo hạt / giâm cành', 'Sowing / cuttings', 0.12, 'SPROUT', 'seed'],
      ['S2', 'Cây con', 'Seedling', 0.35, 'TRUE_LEAVES', 'seedling'],
      ['S3', 'Phát triển', 'Growth', 0.6, null, 'mature'],
      ['S4', 'Thu hoạch liên tục', 'Ongoing harvest', 1.0, 'HARVEST', 'mature'],
    ],
    tasks: (o, len) => [
      [o.cutting ? 'S1' : 'S1', o.cutting ? 'T_CUT_PROPAGATE' : 'T_SOW', 'morning', 0, 0, 'R_ROUTINE'],
      ['S1', 'T_WATER', 'morning', 1, 0, 'R_ESTABLISH_ROOTS'],
      ['S1', 'T_CHECKIN', 'all_day', 5, 3, 'R_CHECKIN_CADENCE'],
      ...(o.thin ? [['S2', 'T_THIN', 'morning', 0, clampOffset(2, len.S2), 'R_STAGE_GROWTH']] : []),
      ['S2', 'T_WATER', 'morning', o.water ?? 2, 0, 'R_STAGE_GROWTH'],
      ['S2', 'T_PEST_CHECK', 'afternoon', 5, 1, 'R_PREVENT_PEST'],
      ['S2', 'T_CHECKIN', 'all_day', 5, 2, 'R_CHECKIN_CADENCE'],
      ['S3', 'T_WATER', 'morning', o.water ?? 2, 0, 'R_STAGE_GROWTH'],
      ...(o.pinch === false ? [] : [['S3', 'T_PINCH', 'morning', 10, 2, 'R_STAGE_GROWTH']]),
      ['S3', 'T_FERT_ORGANIC', 'morning', 14, 3, 'R_STAGE_GROWTH'],
      ['S3', 'T_PEST_CHECK', 'afternoon', 4, 1, 'R_PREVENT_PEST'],
      ['S3', 'T_CHECKIN', 'all_day', 5, 2, 'R_CHECKIN_CADENCE'],
      ['S4', 'T_HARVEST', 'morning', o.harvest ?? 4, 0, 'R_HARVEST_READY'],
      ...(o.deadhead ? [['S4', 'T_DEADHEAD', 'morning', 7, 2, 'R_ROUTINE']] : []),
      ['S4', 'T_WATER', 'morning', o.water ?? 2, 0, 'R_ROUTINE'],
      ['S4', 'T_PEST_CHECK', 'afternoon', 5, 1, 'R_PREVENT_PEST'],
      ['S4', 'T_CHECKIN', 'all_day', 7, 2, 'R_CHECKIN_CADENCE'],
    ],
  },
  fruiting: {
    stages: [
      ['S1', 'Gieo hạt & nảy mầm', 'Sowing & germination', 0.08, 'SPROUT', 'seed'],
      ['S2', 'Cây con', 'Seedling', 0.22, 'TRUE_LEAVES', 'seedling'],
      ['S3', 'Sinh trưởng thân lá', 'Vegetative growth', 0.45, 'HEIGHT_40', 'mature'],
      ['S4', 'Ra hoa', 'Flowering', 0.6, 'FLOWER', 'mature'],
      ['S5', 'Đậu quả', 'Fruit set', 0.75, 'FRUIT_SET', 'mature'],
      ['S6', 'Thu hoạch', 'Harvest', 1.0, 'HARVEST', 'mature'],
    ],
    tasks: (o, len) => [
      ['S1', 'T_SOW', 'morning', 0, 0, 'R_ROUTINE'],
      ['S1', 'T_WATER', 'morning', 1, 0, 'R_ESTABLISH_ROOTS'],
      ['S1', 'T_CHECKIN', 'all_day', 5, 3, 'R_CHECKIN_CADENCE'],
      ['S2', 'T_WATER', 'morning', 1, 0, 'R_STAGE_GROWTH'],
      ['S2', 'T_PEST_CHECK', 'afternoon', 4, 1, 'R_PREVENT_PEST'],
      ['S2', 'T_TRANSPLANT', 'afternoon', 0, clampOffset(len.S2 - 2, len.S2), 'R_STAGE_GROWTH'],
      ['S2', 'T_CHECKIN', 'all_day', 5, 2, 'R_CHECKIN_CADENCE'],
      o.vine ? ['S3', 'T_TRELLIS', 'morning', 7, 0, 'R_STAGE_GROWTH'] : ['S3', 'T_STAKE', 'morning', 0, 0, 'R_STAGE_GROWTH'],
      ['S3', 'T_WATER', 'morning', o.water ?? 2, 0, 'R_STAGE_GROWTH'],
      ['S3', 'T_FERT_ORGANIC', 'morning', 14, 3, 'R_STAGE_GROWTH'],
      ['S3', 'T_MULCH', 'morning', 0, clampOffset(2, len.S3), 'R_ROUTINE'],
      ...(o.prune ? [['S3', 'T_PRUNE', 'morning', 10, 4, 'R_STAGE_GROWTH']] : []),
      ['S3', 'T_PEST_CHECK', 'afternoon', 4, 1, 'R_PREVENT_PEST'],
      ['S3', 'T_CHECKIN', 'all_day', 5, 2, 'R_CHECKIN_CADENCE'],
      ['S4', 'T_WATER', 'morning', o.water ?? 2, 0, 'R_FLOWERING'],
      ['S4', 'T_FERT_ORGANIC', 'morning', 14, 1, 'R_FLOWERING'],
      ...(o.pollinate ? [['S4', 'T_HAND_POLLINATE', 'morning', 2, 0, 'R_FLOWERING']] : []),
      ...(o.vine ? [['S4', 'T_TRELLIS', 'morning', 7, 0, 'R_STAGE_GROWTH']] : []),
      ['S4', 'T_PEST_CHECK', 'afternoon', 4, 1, 'R_PREVENT_PEST'],
      ['S4', 'T_CHECKIN', 'all_day', 5, 2, 'R_CHECKIN_CADENCE'],
      ['S5', 'T_WATER', 'morning', o.water ?? 2, 0, 'R_FRUITING'],
      ['S5', 'T_FERT_ORGANIC', 'morning', 14, 1, 'R_FRUITING'],
      ['S5', 'T_PEST_CHECK', 'afternoon', 4, 1, 'R_PREVENT_PEST'],
      ['S5', 'T_CHECKIN', 'all_day', 5, 2, 'R_CHECKIN_CADENCE'],
      ['S6', 'T_HARVEST', 'morning', o.harvest ?? 3, 0, 'R_HARVEST_READY'],
      ['S6', 'T_WATER', 'morning', o.water ?? 2, 0, 'R_FRUITING'],
      ['S6', 'T_CHECKIN', 'all_day', 7, 2, 'R_CHECKIN_CADENCE'],
    ],
  },
  perennial: {
    stages: [
      ['S1', 'Trồng & bén rễ', 'Planting & rooting', 0.1, 'NEW_GROWTH', 'seed'],
      ['S2', 'Phát triển', 'Growth', 0.4, null, 'seedling'],
      ['S3', 'Ra hoa', 'Flowering', 0.6, 'FLOWER', 'mature'],
      ['S4', 'Đậu quả', 'Fruit set', 0.8, 'FRUIT_SET', 'mature'],
      ['S5', 'Thu hoạch', 'Harvest', 1.0, 'HARVEST', 'mature'],
    ],
    tasks: (o, len) => [
      ['S1', 'T_TRANSPLANT', 'afternoon', 0, 0, 'R_ESTABLISH_ROOTS'],
      ['S1', 'T_WATER', 'morning', 2, 0, 'R_ESTABLISH_ROOTS'],
      ['S1', 'T_MOVE_SHADE', 'afternoon', 0, 1, 'R_ESTABLISH_ROOTS'],
      ['S1', 'T_CHECKIN', 'all_day', 5, 3, 'R_CHECKIN_CADENCE'],
      ['S2', 'T_WATER', 'morning', o.water ?? 2, 0, 'R_STAGE_GROWTH'],
      ['S2', 'T_FERT_ORGANIC', 'morning', 21, 3, 'R_STAGE_GROWTH'],
      ...(o.runner ? [['S2', 'T_REMOVE_RUNNER', 'morning', 14, 5, 'R_STAGE_GROWTH']] : [['S2', 'T_PRUNE', 'morning', 30, 10, 'R_STAGE_GROWTH']]),
      ...(o.repot ? [['S2', 'T_REPOT', 'morning', 0, clampOffset(len.S2 - 3, len.S2), 'R_SMALL_POT']] : []),
      ['S2', 'T_PEST_CHECK', 'afternoon', 5, 1, 'R_PREVENT_PEST'],
      ['S2', 'T_CHECKIN', 'all_day', 5, 2, 'R_CHECKIN_CADENCE'],
      ['S3', 'T_WATER', 'morning', o.water ?? 2, 0, 'R_FLOWERING'],
      ['S3', 'T_FERT_ORGANIC', 'morning', 14, 1, 'R_FLOWERING'],
      ...(o.pollinate ? [['S3', 'T_HAND_POLLINATE', 'morning', 2, 0, 'R_FLOWERING']] : []),
      ['S3', 'T_PEST_CHECK', 'afternoon', 5, 1, 'R_PREVENT_PEST'],
      ['S3', 'T_CHECKIN', 'all_day', 5, 2, 'R_CHECKIN_CADENCE'],
      ['S4', 'T_WATER', 'morning', o.water ?? 2, 0, 'R_FRUITING'],
      ['S4', 'T_FERT_ORGANIC', 'morning', 14, 1, 'R_FRUITING'],
      ...(o.runner ? [['S4', 'T_MULCH', 'morning', 0, 0, 'R_FRUITING']] : []),
      ['S4', 'T_PEST_CHECK', 'afternoon', 5, 1, 'R_PREVENT_PEST'],
      ['S4', 'T_CHECKIN', 'all_day', 5, 2, 'R_CHECKIN_CADENCE'],
      ['S5', 'T_HARVEST', 'morning', o.harvest ?? 3, 0, 'R_HARVEST_READY'],
      ['S5', 'T_WATER', 'morning', o.water ?? 2, 0, 'R_FRUITING'],
      ...(o.runner ? [] : [['S5', 'T_PRUNE', 'morning', 0, clampOffset(len.S5 - 5, len.S5), 'R_ROUTINE']]),
      ['S5', 'T_CHECKIN', 'all_day', 7, 2, 'R_CHECKIN_CADENCE'],
    ],
  },
  succulent: {
    stages: [
      ['S1', 'Trồng & làm quen', 'Planting & settling in', 0.12, 'NEW_GROWTH', 'seed'],
      ['S2', 'Phát triển', 'Growth', 0.55, null, 'seedling'],
      ['S3', 'Duy trì', 'Maintenance', 1.0, null, 'mature'],
    ],
    tasks: (o, len) => [
      ['S1', 'T_SOW', 'morning', 0, 0, 'R_ESTABLISH_ROOTS'],
      ['S1', 'T_WATER', 'morning', 4, 3, 'R_ESTABLISH_ROOTS'],
      ['S1', 'T_MOVE_SHADE', 'afternoon', 0, 1, 'R_ESTABLISH_ROOTS'],
      ['S1', 'T_CHECKIN', 'all_day', 7, 4, 'R_CHECKIN_CADENCE'],
      ['S2', 'T_WATER', 'morning', o.water, 0, 'R_STAGE_GROWTH'],
      ['S2', 'T_ROTATE_POT', 'morning', 14, 2, 'R_HIGH_LIGHT'],
      ['S2', 'T_REMOVE_DEAD_LEAF', 'morning', 14, 3, 'R_ROUTINE'],
      ['S2', 'T_PEST_CHECK', 'afternoon', 10, 2, 'R_PREVENT_PEST'],
      ['S2', 'T_FERT_ORGANIC', 'morning', 45, 10, 'R_STAGE_GROWTH'],
      ['S2', 'T_PROTECT_RAIN', 'morning', 0, 0, 'R_RAINY_SEASON'],
      ['S2', 'T_CHECKIN', 'all_day', 7, 3, 'R_CHECKIN_CADENCE'],
      ['S3', 'T_WATER', 'morning', o.water, 0, 'R_ROUTINE'],
      ['S3', 'T_ROTATE_POT', 'morning', 14, 2, 'R_HIGH_LIGHT'],
      ['S3', 'T_CHECK_DRAINAGE', 'morning', 30, 5, 'R_WET_SOIL'],
      ['S3', 'T_REMOVE_DEAD_LEAF', 'morning', 14, 3, 'R_ROUTINE'],
      ['S3', 'T_PEST_CHECK', 'afternoon', 10, 2, 'R_PREVENT_PEST'],
      ['S3', 'T_REPOT', 'morning', 0, clampOffset(Math.floor(len.S3 / 2), len.S3), 'R_SMALL_POT'],
      ...(o.harvest ? [['S3', 'T_HARVEST', 'morning', 30, 10, 'R_HARVEST_READY']] : []),
      ['S3', 'T_CHECKIN', 'all_day', 10, 4, 'R_CHECKIN_CADENCE'],
    ],
  },
  foliage: {
    stages: [
      ['S1', 'Nhân giống / làm quen', 'Propagation / settling in', 0.08, 'NEW_GROWTH', 'seed'],
      ['S2', 'Phát triển', 'Growth', 0.5, 'NEW_GROWTH', 'seedling'],
      ['S3', 'Chăm duy trì', 'Maintenance', 1.0, null, 'mature'],
    ],
    tasks: (o, len) => [
      [o.cutting ? 'S1' : 'S1', o.cutting ? 'T_CUT_PROPAGATE' : 'T_SOW', 'morning', 0, 0, 'R_ESTABLISH_ROOTS'],
      ['S1', 'T_WATER', 'morning', 3, 2, 'R_ESTABLISH_ROOTS'],
      ['S1', 'T_CHECKIN', 'all_day', 7, 4, 'R_CHECKIN_CADENCE'],
      ['S2', 'T_WATER', 'morning', o.water, 0, 'R_STAGE_GROWTH'],
      ...(o.mist ? [['S2', 'T_MIST', 'morning', 3, 1, 'R_INDOOR_AIR']] : []),
      ...(o.stake ? [['S2', 'T_STAKE', 'morning', 0, clampOffset(10, len.S2), 'R_STAGE_GROWTH']] : []),
      ['S2', 'T_FERT_ORGANIC', 'morning', 30, 7, 'R_STAGE_GROWTH'],
      ['S2', 'T_WIPE_LEAVES', 'morning', 14, 5, 'R_ROUTINE'],
      ['S2', 'T_PEST_CHECK', 'afternoon', 7, 2, 'R_PREVENT_PEST'],
      ['S2', 'T_CHECKIN', 'all_day', 7, 3, 'R_CHECKIN_CADENCE'],
      ['S3', 'T_WATER', 'morning', o.water, 0, 'R_ROUTINE'],
      ...(o.mist ? [['S3', 'T_MIST', 'morning', 3, 1, 'R_INDOOR_AIR']] : []),
      ['S3', 'T_WIPE_LEAVES', 'morning', 14, 5, 'R_ROUTINE'],
      ['S3', 'T_ROTATE_POT', 'morning', 14, 3, 'R_LOW_LIGHT'],
      ['S3', 'T_REMOVE_DEAD_LEAF', 'morning', 14, 4, 'R_ROUTINE'],
      ['S3', 'T_PRUNE', 'morning', 30, 10, 'R_ROUTINE'],
      ['S3', 'T_FERT_ORGANIC', 'morning', 30, 7, 'R_STAGE_GROWTH'],
      ['S3', 'T_PEST_CHECK', 'afternoon', 7, 2, 'R_PREVENT_PEST'],
      ['S3', 'T_REPOT', 'morning', 0, clampOffset(len.S3 - 10, len.S3), 'R_SMALL_POT'],
      ['S3', 'T_CHECKIN', 'all_day', 10, 4, 'R_CHECKIN_CADENCE'],
    ],
  },
  flowering: {
    stages: [
      ['S1', 'Trồng & bén rễ', 'Planting & rooting', 0.1, 'NEW_GROWTH', 'seed'],
      ['S2', 'Phát triển cành lá', 'Foliage growth', 0.4, null, 'seedling'],
      ['S3', 'Ra nụ', 'Budding', 0.6, null, 'mature'],
      ['S4', 'Ra hoa', 'Flowering', 0.85, 'FLOWER', 'mature'],
      ['S5', 'Tỉa sau hoa & phục hồi', 'Post-bloom pruning & recovery', 1.0, null, 'mature'],
    ],
    tasks: (o, len) => [
      ['S1', 'T_TRANSPLANT', 'afternoon', 0, 0, 'R_ESTABLISH_ROOTS'],
      ['S1', 'T_WATER', 'morning', 2, 0, 'R_ESTABLISH_ROOTS'],
      ['S1', 'T_MOVE_SHADE', 'afternoon', 0, 1, 'R_ESTABLISH_ROOTS'],
      ['S1', 'T_CHECKIN', 'all_day', 5, 3, 'R_CHECKIN_CADENCE'],
      ['S2', 'T_WATER', 'morning', o.water, 0, 'R_STAGE_GROWTH'],
      ['S2', 'T_FERT_ORGANIC', 'morning', 14, 3, 'R_STAGE_GROWTH'],
      ...(o.pinch ? [['S2', 'T_PINCH', 'morning', 14, 5, 'R_STAGE_GROWTH']] : [['S2', 'T_PRUNE', 'morning', 21, 7, 'R_STAGE_GROWTH']]),
      ['S2', 'T_PEST_CHECK', 'afternoon', 4, 1, 'R_PREVENT_PEST'],
      ['S2', 'T_CHECKIN', 'all_day', 5, 2, 'R_CHECKIN_CADENCE'],
      ['S3', 'T_WATER', 'morning', o.waterBud ?? o.water, 0, 'R_FLOWERING'],
      ['S3', 'T_FERT_ORGANIC', 'morning', 14, 1, 'R_FLOWERING'],
      ['S3', 'T_MOVE_LIGHT', 'morning', 0, 0, 'R_LOW_LIGHT'],
      ['S3', 'T_PEST_CHECK', 'afternoon', 4, 1, 'R_PREVENT_PEST'],
      ['S3', 'T_CHECKIN', 'all_day', 5, 2, 'R_CHECKIN_CADENCE'],
      ['S4', 'T_WATER', 'morning', o.water, 0, 'R_FLOWERING'],
      ['S4', 'T_DEADHEAD', 'morning', 5, 2, 'R_FLOWERING'],
      ['S4', 'T_FERT_ORGANIC', 'morning', 14, 1, 'R_FLOWERING'],
      ['S4', 'T_PEST_CHECK', 'afternoon', 4, 1, 'R_PREVENT_PEST'],
      ['S4', 'T_CHECKIN', 'all_day', 5, 2, 'R_CHECKIN_CADENCE'],
      ['S5', 'T_PRUNE', 'morning', 0, 0, 'R_ROUTINE'],
      ['S5', 'T_WATER', 'morning', o.water, 1, 'R_ROUTINE'],
      ['S5', 'T_COMPOST_TOPDRESS', 'morning', 0, clampOffset(3, len.S5), 'R_STAGE_GROWTH'],
      ['S5', 'T_CHECKIN', 'all_day', 10, 3, 'R_CHECKIN_CADENCE'],
    ],
  },
};

const defaultProblems = {
  leafy: ['P_CATERPILLAR', 'P_APHID', 'P_YELLOW_LEAF_HUNGRY', 'P_WILT_UNDERWATER', 'P_SNAIL_SLUG'],
  herb: ['P_YELLOW_LEAF_OVERWATER', 'P_APHID', 'P_WILT_UNDERWATER', 'P_LEAF_SPOT', 'P_WHITEFLY'],
  fruiting: ['P_APHID', 'P_BLOSSOM_DROP', 'P_YELLOW_LEAF_HUNGRY', 'P_POWDERY_MILDEW', 'P_SPIDER_MITE', 'P_WHITEFLY'],
  perennial: ['P_APHID', 'P_SCALE', 'P_YELLOW_LEAF_HUNGRY', 'P_ROOT_ROT', 'P_LEAF_SPOT'],
  succulent: ['P_ROOT_ROT', 'P_MEALYBUG', 'P_YELLOW_LEAF_OVERWATER', 'P_LOW_LIGHT_LEGGY', 'P_SUNBURN'],
  foliage: ['P_YELLOW_LEAF_OVERWATER', 'P_SPIDER_MITE', 'P_MEALYBUG', 'P_TIP_BURN', 'P_ROOT_ROT'],
  flowering: ['P_APHID', 'P_POWDERY_MILDEW', 'P_NO_FLOWER', 'P_SPIDER_MITE', 'P_LEAF_SPOT'],
};

// ---------------------------------------------------------------- plants
// toxic flags follow commonly published pet/child toxicity lists; shown as warnings, to be verified by an expert.
const P = (id, group, vi, en, sci, aliases, difficulty, days, tc, tp, arch, opts = {}, extraProblems = []) =>
  ({ id, group, vi, en, sci, aliases, difficulty, days, tc, tp, arch, opts, extraProblems });

export const plants = [
  // vegetables, herbs, fruit (rau_qua)
  P('kangkong', 'rau_qua', 'Rau muống', 'Water spinach (kangkong)', 'Ipomoea aquatica', 'rau muong kangkong ong choy', 'easy', 30, false, false, 'leafy', { water: 1, thin: true, harvest: 5, fert: 10 }),
  P('choy_sum', 'rau_qua', 'Cải ngọt', 'Choy sum (sweet mustard greens)', 'Brassica rapa var. parachinensis', 'cai ngot cai xanh mustard greens', 'easy', 35, false, false, 'leafy', { water: 1, harvest: 4, fert: 10, pickPests: true }),
  P('lettuce', 'rau_qua', 'Xà lách', 'Lettuce', 'Lactuca sativa', 'xa lach rau diep lettuce', 'easy', 45, false, false, 'leafy', { water: 1, harvest: 3, fert: 12 }),
  P('coriander', 'rau_qua', 'Rau mùi (ngò rí)', 'Coriander (cilantro)', 'Coriandrum sativum', 'rau mui ngo ri ngo cilantro', 'medium', 45, false, false, 'leafy', { water: 2, harvest: 5, fert: 14, thin: true }),
  P('scallion', 'rau_qua', 'Hành lá', 'Scallion (green onion)', 'Allium fistulosum', 'hanh la hanh hoa green onion spring onion', 'easy', 40, false, true, 'leafy', { water: 2, thin: false, harvest: 7, fert: 14 }),
  P('basil', 'rau_qua', 'Húng quế', 'Basil', 'Ocimum basilicum', 'hung que que basil', 'easy', 60, false, false, 'herb', { water: 2, pinch: true, deadhead: true, harvest: 4 }),
  P('perilla', 'rau_qua', 'Tía tô', 'Perilla (shiso)', 'Perilla frutescens', 'tia to perilla shiso', 'easy', 60, false, false, 'herb', { water: 2, pinch: true, deadhead: true, harvest: 4 }),
  P('mint', 'rau_qua', 'Bạc hà', 'Mint', 'Mentha spp.', 'bac ha rau hung cay mint', 'easy', 60, false, true, 'herb', { water: 2, pinch: true, cutting: true, harvest: 4 }),
  P('lemongrass', 'rau_qua', 'Sả', 'Lemongrass', 'Cymbopogon citratus', 'sa cay sa lemongrass', 'easy', 120, false, true, 'herb', { water: 3, pinch: false, cutting: true, harvest: 10 }),
  P('chili', 'rau_qua', 'Ớt', 'Chili pepper', 'Capsicum annuum', 'ot ot hiem chili pepper', 'medium', 110, false, false, 'fruiting', { water: 2, harvest: 4 }, ['P_BLOSSOM_DROP']),
  P('tomato_cherry', 'rau_qua', 'Cà chua bi', 'Cherry tomato', 'Solanum lycopersicum var. cerasiforme', 'ca chua bi ca chua cherry tomato', 'medium', 85, false, true, 'fruiting', { water: 2, prune: true, harvest: 3 }, ['P_BLOSSOM_END_ROT', 'P_CALCIUM_LOW']),
  P('cucumber', 'rau_qua', 'Dưa leo', 'Cucumber', 'Cucumis sativus', 'dua leo dua chuot cucumber', 'medium', 55, false, false, 'fruiting', { water: 1, vine: true, pollinate: true, harvest: 2 }, ['P_POWDERY_MILDEW']),
  P('luffa', 'rau_qua', 'Mướp', 'Luffa (sponge gourd)', 'Luffa aegyptiaca', 'muop muop huong luffa loofah sponge gourd', 'medium', 75, false, false, 'fruiting', { water: 1, vine: true, pollinate: true, harvest: 3 }),
  P('okra', 'rau_qua', 'Đậu bắp', 'Okra', 'Abelmoschus esculentus', 'dau bap okra lady finger', 'medium', 60, false, false, 'fruiting', { water: 2, harvest: 2 }),
  P('bitter_melon', 'rau_qua', 'Khổ qua (mướp đắng)', 'Bitter melon', 'Momordica charantia', 'kho qua muop dang bitter melon bitter gourd', 'medium', 75, false, false, 'fruiting', { water: 1, vine: true, pollinate: true, harvest: 3 }),
  P('lemon', 'rau_qua', 'Chanh', 'Lemon / lime', 'Citrus × limon', 'chanh chanh ta chanh khong hat lemon lime', 'hard', 540, false, true, 'perennial', { water: 2, repot: true, harvest: 5 }, ['P_SCALE', 'P_ROOT_ROT']),
  P('strawberry', 'rau_qua', 'Dâu tây', 'Strawberry', 'Fragaria × ananassa', 'dau tay strawberry', 'hard', 100, false, false, 'perennial', { water: 1, runner: true, pollinate: true, harvest: 2 }, ['P_POWDERY_MILDEW', 'P_SNAIL_SLUG']),
  // ornamental (cay_canh)
  P('aloe_vera', 'cay_canh', 'Lô hội (nha đam)', 'Aloe vera', 'Aloe vera', 'lo hoi nha dam aloe vera', 'easy', 365, false, true, 'succulent', { water: 10, harvest: true }),
  P('echeveria', 'cay_canh', 'Sen đá', 'Echeveria (succulent rosette)', 'Echeveria spp.', 'sen da sen da succulent echeveria', 'medium', 365, false, false, 'succulent', { water: 7 }),
  P('cactus', 'cay_canh', 'Xương rồng', 'Cactus', 'Cactaceae', 'xuong rong cactus', 'easy', 365, false, false, 'succulent', { water: 14 }),
  P('pothos', 'cay_canh', 'Trầu bà', 'Pothos (devil\'s ivy)', 'Epipremnum aureum', 'trau ba trau ba leo pothos devils ivy', 'easy', 180, true, true, 'foliage', { water: 4, cutting: true }),
  P('snake_plant', 'cay_canh', 'Lưỡi hổ', 'Snake plant', 'Dracaena trifasciata', 'luoi ho luoi cop snake plant sansevieria', 'easy', 180, false, true, 'foliage', { water: 10, cutting: true }),
  P('zz_plant', 'cay_canh', 'Kim tiền', 'ZZ plant', 'Zamioculcas zamiifolia', 'kim tien zz plant zamioculcas', 'easy', 180, true, true, 'foliage', { water: 10, cutting: true }),
  P('peace_lily', 'cay_canh', 'Lan ý', 'Peace lily', 'Spathiphyllum wallisii', 'lan y buom trang peace lily spathiphyllum', 'medium', 180, true, true, 'foliage', { water: 4, mist: true }),
  P('monstera', 'cay_canh', 'Monstera (trầu bà lá xẻ)', 'Monstera (Swiss cheese plant)', 'Monstera deliciosa', 'monstera trau ba la xe trau ba nam my swiss cheese', 'easy', 240, true, true, 'foliage', { water: 6, stake: true, cutting: true }),
  P('parlor_palm', 'cay_canh', 'Cau tiểu trâm', 'Parlor palm', 'Chamaedorea elegans', 'cau tieu tram cau canh parlor palm', 'medium', 240, false, false, 'foliage', { water: 4, mist: true }),
  P('aglaonema', 'cay_canh', 'Vạn niên thanh', 'Chinese evergreen', 'Aglaonema spp.', 'van nien thanh aglaonema chinese evergreen', 'easy', 180, true, true, 'foliage', { water: 5 }),
  P('rose', 'cay_canh', 'Hoa hồng', 'Rose', 'Rosa spp.', 'hoa hong hong rose', 'hard', 240, false, false, 'flowering', { water: 2 }, ['P_BLOSSOM_DROP']),
  P('bougainvillea', 'cay_canh', 'Hoa giấy', 'Bougainvillea', 'Bougainvillea spp.', 'hoa giay bougainvillea', 'medium', 240, false, false, 'flowering', { water: 3, waterBud: 4 }),
  P('chrysanthemum', 'cay_canh', 'Hoa cúc', 'Chrysanthemum', 'Chrysanthemum × morifolium', 'hoa cuc cuc chrysanthemum mum', 'medium', 150, false, true, 'flowering', { water: 2, pinch: true }),
  // hidden generic plans used when a plant is not in the database or the AI fails for it
  P('generic_edible', 'rau_qua', 'Cây ăn lá/quả (chung)', 'Generic edible plant', null, 'generic', 'medium', 60, false, false, 'leafy', { water: 2, harvest: 4 }),
  P('generic_ornamental', 'cay_canh', 'Cây cảnh (chung)', 'Generic ornamental plant', null, 'generic', 'medium', 180, false, false, 'foliage', { water: 5 }),
];

// ---------------------------------------------------------------- expansion
export function expandPlant(pl) {
  const a = archetypes[pl.arch];
  const days = pl.days;
  const stages = [];
  let prev = 0;
  a.stages.forEach(([code, vi, en, frac, milestone, phase], i) => {
    const max = Math.max(prev + 1, Math.round(frac * days));
    stages.push({ code, order: i + 1, vi, en, min: prev + 1, max: i === a.stages.length - 1 ? Math.max(max, days) : max, milestone, phase });
    prev = stages[stages.length - 1].max;
  });
  const len = Object.fromEntries(stages.map((s) => [s.code, s.max - s.min + 1]));
  const tasks = a.tasks(pl.opts, len).map(([stage, task, window, every, offset, reason]) => ({
    stage, task, window, every, offset: Math.min(offset, len[stage] - 1), reason,
  }));
  // one row per (plant, stage, task) - keep the first definition
  const seen = new Set();
  const uniq = tasks.filter((t) => (seen.has(`${t.stage}|${t.task}`) ? false : seen.add(`${t.stage}|${t.task}`)));
  const problems = [...new Set([...pl.extraProblems, ...defaultProblems[pl.arch]])].slice(0, 6);
  return { stages, tasks: uniq, problems };
}
