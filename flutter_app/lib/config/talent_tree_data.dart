/// 天賦樹靜態數據
/// 5 隻貓各有 3 分支 × 3~4 節點
import '../core/models/material.dart';
import '../core/models/talent_tree.dart';

class TalentTreeData {
  TalentTreeData._();

  // ─── 阿焰 Blaze ───

  static const blazeTalents = <TalentNodeDefinition>[
    // 攻擊分支
    TalentNodeDefinition(
      id: 'blaze_atk_1', name: '爪擊強化', description: 'ATK +5%',
      branch: TalentBranch.attack, tier: 1,
      effectType: TalentEffectType.atkPercent, effectValue: 5,
      goldCost: 200, materialCost: {GameMaterial.commonShard: 3},
    ),
    TalentNodeDefinition(
      id: 'blaze_atk_2', name: '烈焰之力', description: 'ATK +8%',
      branch: TalentBranch.attack, tier: 2,
      effectType: TalentEffectType.atkPercent, effectValue: 8,
      goldCost: 500, materialCost: {GameMaterial.commonShard: 5, GameMaterial.advancedShard: 2},
      prerequisiteNodeId: 'blaze_atk_1',
    ),
    TalentNodeDefinition(
      id: 'blaze_atk_3', name: '技能精通', description: '技能傷害 +10%',
      branch: TalentBranch.attack, tier: 3,
      effectType: TalentEffectType.skillDamageUp, effectValue: 10,
      goldCost: 1000, materialCost: {GameMaterial.advancedShard: 3, GameMaterial.talentScroll: 1},
      prerequisiteNodeId: 'blaze_atk_2',
    ),
    TalentNodeDefinition(
      id: 'blaze_atk_4', name: '致命一擊', description: '暴擊傷害 +15%',
      branch: TalentBranch.attack, tier: 4,
      effectType: TalentEffectType.critDamage, effectValue: 15,
      goldCost: 2000, materialCost: {GameMaterial.advancedShard: 5, GameMaterial.talentScroll: 2, GameMaterial.rareShard: 1},
      prerequisiteNodeId: 'blaze_atk_3',
    ),
    // 防禦分支
    TalentNodeDefinition(
      id: 'blaze_def_1', name: '堅韌體魄', description: 'HP +5%',
      branch: TalentBranch.defense, tier: 1,
      effectType: TalentEffectType.hpPercent, effectValue: 5,
      goldCost: 200, materialCost: {GameMaterial.commonShard: 3},
    ),
    TalentNodeDefinition(
      id: 'blaze_def_2', name: '生命強化', description: 'HP +8%',
      branch: TalentBranch.defense, tier: 2,
      effectType: TalentEffectType.hpPercent, effectValue: 8,
      goldCost: 500, materialCost: {GameMaterial.commonShard: 5, GameMaterial.advancedShard: 2},
      prerequisiteNodeId: 'blaze_def_1',
    ),
    TalentNodeDefinition(
      id: 'blaze_def_3', name: '火焰護甲', description: '減傷 +5%',
      branch: TalentBranch.defense, tier: 3,
      effectType: TalentEffectType.dmgReduction, effectValue: 5,
      goldCost: 1000, materialCost: {GameMaterial.advancedShard: 3, GameMaterial.talentScroll: 1},
      prerequisiteNodeId: 'blaze_def_2',
    ),
    // 輔助分支
    TalentNodeDefinition(
      id: 'blaze_sup_1', name: '能量導引', description: '能量獲取 +10%',
      branch: TalentBranch.support, tier: 1,
      effectType: TalentEffectType.energyGainUp, effectValue: 10,
      goldCost: 200, materialCost: {GameMaterial.commonShard: 3},
    ),
    TalentNodeDefinition(
      id: 'blaze_sup_2', name: '連擊本能', description: '連擊傷害 +5%',
      branch: TalentBranch.support, tier: 2,
      effectType: TalentEffectType.comboBonus, effectValue: 5,
      goldCost: 500, materialCost: {GameMaterial.commonShard: 5, GameMaterial.advancedShard: 2},
      prerequisiteNodeId: 'blaze_sup_1',
    ),
    TalentNodeDefinition(
      id: 'blaze_sup_3', name: '消除強化', description: '消除傷害 +8%',
      branch: TalentBranch.support, tier: 3,
      effectType: TalentEffectType.matchDamageUp, effectValue: 8,
      goldCost: 1000, materialCost: {GameMaterial.advancedShard: 3, GameMaterial.talentScroll: 1},
      prerequisiteNodeId: 'blaze_sup_2',
    ),
  ];

  // ─── 小波 Tide ───

  static const tideTalents = <TalentNodeDefinition>[
    // 攻擊分支
    TalentNodeDefinition(
      id: 'tide_atk_1', name: '水流衝擊', description: 'ATK +5%',
      branch: TalentBranch.attack, tier: 1,
      effectType: TalentEffectType.atkPercent, effectValue: 5,
      goldCost: 200, materialCost: {GameMaterial.commonShard: 3},
    ),
    TalentNodeDefinition(
      id: 'tide_atk_2', name: '潮汐之力', description: '消除傷害 +5%',
      branch: TalentBranch.attack, tier: 2,
      effectType: TalentEffectType.matchDamageUp, effectValue: 5,
      goldCost: 500, materialCost: {GameMaterial.commonShard: 5, GameMaterial.advancedShard: 2},
      prerequisiteNodeId: 'tide_atk_1',
    ),
    TalentNodeDefinition(
      id: 'tide_atk_3', name: '水壓集中', description: '技能傷害 +8%',
      branch: TalentBranch.attack, tier: 3,
      effectType: TalentEffectType.skillDamageUp, effectValue: 8,
      goldCost: 1000, materialCost: {GameMaterial.advancedShard: 3, GameMaterial.talentScroll: 1},
      prerequisiteNodeId: 'tide_atk_2',
    ),
    // 防禦分支
    TalentNodeDefinition(
      id: 'tide_def_1', name: '水之守護', description: 'HP +8%',
      branch: TalentBranch.defense, tier: 1,
      effectType: TalentEffectType.hpPercent, effectValue: 8,
      goldCost: 200, materialCost: {GameMaterial.commonShard: 3},
    ),
    TalentNodeDefinition(
      id: 'tide_def_2', name: '波浪護甲', description: 'DEF +5%',
      branch: TalentBranch.defense, tier: 2,
      effectType: TalentEffectType.defPercent, effectValue: 5,
      goldCost: 500, materialCost: {GameMaterial.commonShard: 5, GameMaterial.advancedShard: 2},
      prerequisiteNodeId: 'tide_def_1',
    ),
    TalentNodeDefinition(
      id: 'tide_def_3', name: '深海體魄', description: 'HP +10%',
      branch: TalentBranch.defense, tier: 3,
      effectType: TalentEffectType.hpPercent, effectValue: 10,
      goldCost: 1000, materialCost: {GameMaterial.advancedShard: 3, GameMaterial.talentScroll: 1},
      prerequisiteNodeId: 'tide_def_2',
    ),
    TalentNodeDefinition(
      id: 'tide_def_4', name: '海洋壁壘', description: '減傷 +8%',
      branch: TalentBranch.defense, tier: 4,
      effectType: TalentEffectType.dmgReduction, effectValue: 8,
      goldCost: 2000, materialCost: {GameMaterial.advancedShard: 5, GameMaterial.talentScroll: 2, GameMaterial.rareShard: 1},
      prerequisiteNodeId: 'tide_def_3',
    ),
    // 輔助分支
    TalentNodeDefinition(
      id: 'tide_sup_1', name: '治療精通', description: '治療效果 +10%',
      branch: TalentBranch.support, tier: 1,
      effectType: TalentEffectType.healBoost, effectValue: 10,
      goldCost: 200, materialCost: {GameMaterial.commonShard: 3},
    ),
    TalentNodeDefinition(
      id: 'tide_sup_2', name: '能量潮汐', description: '能量獲取 +15%',
      branch: TalentBranch.support, tier: 2,
      effectType: TalentEffectType.energyGainUp, effectValue: 15,
      goldCost: 500, materialCost: {GameMaterial.commonShard: 5, GameMaterial.advancedShard: 2},
      prerequisiteNodeId: 'tide_sup_1',
    ),
    TalentNodeDefinition(
      id: 'tide_sup_3', name: '生命泉源', description: '治療效果 +15%',
      branch: TalentBranch.support, tier: 3,
      effectType: TalentEffectType.healBoost, effectValue: 15,
      goldCost: 1000, materialCost: {GameMaterial.advancedShard: 3, GameMaterial.talentScroll: 1},
      prerequisiteNodeId: 'tide_sup_2',
    ),
  ];

  // ─── 大地 Terra ───

  static const terraTalents = <TalentNodeDefinition>[
    // 攻擊分支
    TalentNodeDefinition(
      id: 'terra_atk_1', name: '岩石拳擊', description: 'ATK +5%',
      branch: TalentBranch.attack, tier: 1,
      effectType: TalentEffectType.atkPercent, effectValue: 5,
      goldCost: 200, materialCost: {GameMaterial.commonShard: 3},
    ),
    TalentNodeDefinition(
      id: 'terra_atk_2', name: '地裂衝擊', description: '消除傷害 +8%',
      branch: TalentBranch.attack, tier: 2,
      effectType: TalentEffectType.matchDamageUp, effectValue: 8,
      goldCost: 500, materialCost: {GameMaterial.commonShard: 5, GameMaterial.advancedShard: 2},
      prerequisiteNodeId: 'terra_atk_1',
    ),
    TalentNodeDefinition(
      id: 'terra_atk_3', name: '大地之力', description: 'ATK +10%',
      branch: TalentBranch.attack, tier: 3,
      effectType: TalentEffectType.atkPercent, effectValue: 10,
      goldCost: 1000, materialCost: {GameMaterial.advancedShard: 3, GameMaterial.talentScroll: 1},
      prerequisiteNodeId: 'terra_atk_2',
    ),
    // 防禦分支
    TalentNodeDefinition(
      id: 'terra_def_1', name: '鋼鐵防禦', description: 'DEF +8%',
      branch: TalentBranch.defense, tier: 1,
      effectType: TalentEffectType.defPercent, effectValue: 8,
      goldCost: 200, materialCost: {GameMaterial.commonShard: 3},
    ),
    TalentNodeDefinition(
      id: 'terra_def_2', name: '厚重體魄', description: 'HP +10%',
      branch: TalentBranch.defense, tier: 2,
      effectType: TalentEffectType.hpPercent, effectValue: 10,
      goldCost: 500, materialCost: {GameMaterial.commonShard: 5, GameMaterial.advancedShard: 2},
      prerequisiteNodeId: 'terra_def_1',
    ),
    TalentNodeDefinition(
      id: 'terra_def_3', name: '護盾強化', description: '護盾效果 +15%',
      branch: TalentBranch.defense, tier: 3,
      effectType: TalentEffectType.shieldBoost, effectValue: 15,
      goldCost: 1000, materialCost: {GameMaterial.advancedShard: 3, GameMaterial.talentScroll: 1},
      prerequisiteNodeId: 'terra_def_2',
    ),
    TalentNodeDefinition(
      id: 'terra_def_4', name: '不動如山', description: '減傷 +10%',
      branch: TalentBranch.defense, tier: 4,
      effectType: TalentEffectType.dmgReduction, effectValue: 10,
      goldCost: 2000, materialCost: {GameMaterial.advancedShard: 5, GameMaterial.talentScroll: 2, GameMaterial.rareShard: 1},
      prerequisiteNodeId: 'terra_def_3',
    ),
    // 輔助分支
    TalentNodeDefinition(
      id: 'terra_sup_1', name: '穩定能量', description: '能量獲取 +10%',
      branch: TalentBranch.support, tier: 1,
      effectType: TalentEffectType.energyGainUp, effectValue: 10,
      goldCost: 200, materialCost: {GameMaterial.commonShard: 3},
    ),
    TalentNodeDefinition(
      id: 'terra_sup_2', name: '根基穩固', description: 'HP +8%',
      branch: TalentBranch.support, tier: 2,
      effectType: TalentEffectType.hpPercent, effectValue: 8,
      goldCost: 500, materialCost: {GameMaterial.commonShard: 5, GameMaterial.advancedShard: 2},
      prerequisiteNodeId: 'terra_sup_1',
    ),
    TalentNodeDefinition(
      id: 'terra_sup_3', name: '堅守陣地', description: 'DEF +5%',
      branch: TalentBranch.support, tier: 3,
      effectType: TalentEffectType.defPercent, effectValue: 5,
      goldCost: 1000, materialCost: {GameMaterial.advancedShard: 3, GameMaterial.talentScroll: 1},
      prerequisiteNodeId: 'terra_sup_2',
    ),
  ];

  // ─── 閃光 Flash ───

  static const flashTalents = <TalentNodeDefinition>[
    // 攻擊分支
    TalentNodeDefinition(
      id: 'flash_atk_1', name: '電擊強化', description: 'ATK +8%',
      branch: TalentBranch.attack, tier: 1,
      effectType: TalentEffectType.atkPercent, effectValue: 8,
      goldCost: 200, materialCost: {GameMaterial.commonShard: 3},
    ),
    TalentNodeDefinition(
      id: 'flash_atk_2', name: '雷霆精通', description: '技能傷害 +10%',
      branch: TalentBranch.attack, tier: 2,
      effectType: TalentEffectType.skillDamageUp, effectValue: 10,
      goldCost: 500, materialCost: {GameMaterial.commonShard: 5, GameMaterial.advancedShard: 2},
      prerequisiteNodeId: 'flash_atk_1',
    ),
    TalentNodeDefinition(
      id: 'flash_atk_3', name: '電光石火', description: '暴擊率 +8%',
      branch: TalentBranch.attack, tier: 3,
      effectType: TalentEffectType.critChance, effectValue: 8,
      goldCost: 1000, materialCost: {GameMaterial.advancedShard: 3, GameMaterial.talentScroll: 1},
      prerequisiteNodeId: 'flash_atk_2',
    ),
    TalentNodeDefinition(
      id: 'flash_atk_4', name: '雷神之怒', description: '暴擊傷害 +20%',
      branch: TalentBranch.attack, tier: 4,
      effectType: TalentEffectType.critDamage, effectValue: 20,
      goldCost: 2000, materialCost: {GameMaterial.advancedShard: 5, GameMaterial.talentScroll: 2, GameMaterial.rareShard: 1},
      prerequisiteNodeId: 'flash_atk_3',
    ),
    // 防禦分支
    TalentNodeDefinition(
      id: 'flash_def_1', name: '靜電場護體', description: 'HP +5%',
      branch: TalentBranch.defense, tier: 1,
      effectType: TalentEffectType.hpPercent, effectValue: 5,
      goldCost: 200, materialCost: {GameMaterial.commonShard: 3},
    ),
    TalentNodeDefinition(
      id: 'flash_def_2', name: '電磁護甲', description: 'DEF +5%',
      branch: TalentBranch.defense, tier: 2,
      effectType: TalentEffectType.defPercent, effectValue: 5,
      goldCost: 500, materialCost: {GameMaterial.commonShard: 5, GameMaterial.advancedShard: 2},
      prerequisiteNodeId: 'flash_def_1',
    ),
    TalentNodeDefinition(
      id: 'flash_def_3', name: '電流屏障', description: 'HP +8%',
      branch: TalentBranch.defense, tier: 3,
      effectType: TalentEffectType.hpPercent, effectValue: 8,
      goldCost: 1000, materialCost: {GameMaterial.advancedShard: 3, GameMaterial.talentScroll: 1},
      prerequisiteNodeId: 'flash_def_2',
    ),
    // 輔助分支
    TalentNodeDefinition(
      id: 'flash_sup_1', name: '連擊感應', description: '連擊傷害 +10%',
      branch: TalentBranch.support, tier: 1,
      effectType: TalentEffectType.comboBonus, effectValue: 10,
      goldCost: 200, materialCost: {GameMaterial.commonShard: 3},
    ),
    TalentNodeDefinition(
      id: 'flash_sup_2', name: '電能積蓄', description: '能量獲取 +10%',
      branch: TalentBranch.support, tier: 2,
      effectType: TalentEffectType.energyGainUp, effectValue: 10,
      goldCost: 500, materialCost: {GameMaterial.commonShard: 5, GameMaterial.advancedShard: 2},
      prerequisiteNodeId: 'flash_sup_1',
    ),
    TalentNodeDefinition(
      id: 'flash_sup_3', name: '電流貫穿', description: '消除傷害 +10%',
      branch: TalentBranch.support, tier: 3,
      effectType: TalentEffectType.matchDamageUp, effectValue: 10,
      goldCost: 1000, materialCost: {GameMaterial.advancedShard: 3, GameMaterial.talentScroll: 1},
      prerequisiteNodeId: 'flash_sup_2',
    ),
  ];

  // ─── 影子 Shadow ───

  static const shadowTalents = <TalentNodeDefinition>[
    // 攻擊分支
    TalentNodeDefinition(
      id: 'shadow_atk_1', name: '暗影刺擊', description: 'ATK +10%',
      branch: TalentBranch.attack, tier: 1,
      effectType: TalentEffectType.atkPercent, effectValue: 10,
      goldCost: 200, materialCost: {GameMaterial.commonShard: 3},
    ),
    TalentNodeDefinition(
      id: 'shadow_atk_2', name: '致命要害', description: '暴擊率 +10%',
      branch: TalentBranch.attack, tier: 2,
      effectType: TalentEffectType.critChance, effectValue: 10,
      goldCost: 500, materialCost: {GameMaterial.commonShard: 5, GameMaterial.advancedShard: 2},
      prerequisiteNodeId: 'shadow_atk_1',
    ),
    TalentNodeDefinition(
      id: 'shadow_atk_3', name: '暗殺精通', description: '技能傷害 +15%',
      branch: TalentBranch.attack, tier: 3,
      effectType: TalentEffectType.skillDamageUp, effectValue: 15,
      goldCost: 1000, materialCost: {GameMaterial.advancedShard: 3, GameMaterial.talentScroll: 1},
      prerequisiteNodeId: 'shadow_atk_2',
    ),
    TalentNodeDefinition(
      id: 'shadow_atk_4', name: '死神之刃', description: '暴擊傷害 +25%',
      branch: TalentBranch.attack, tier: 4,
      effectType: TalentEffectType.critDamage, effectValue: 25,
      goldCost: 2000, materialCost: {GameMaterial.advancedShard: 5, GameMaterial.talentScroll: 2, GameMaterial.rareShard: 1},
      prerequisiteNodeId: 'shadow_atk_3',
    ),
    // 防禦分支
    TalentNodeDefinition(
      id: 'shadow_def_1', name: '暗影閃避', description: 'HP +5%',
      branch: TalentBranch.defense, tier: 1,
      effectType: TalentEffectType.hpPercent, effectValue: 5,
      goldCost: 200, materialCost: {GameMaterial.commonShard: 3},
    ),
    TalentNodeDefinition(
      id: 'shadow_def_2', name: '夜行者', description: 'DEF +5%',
      branch: TalentBranch.defense, tier: 2,
      effectType: TalentEffectType.defPercent, effectValue: 5,
      goldCost: 500, materialCost: {GameMaterial.commonShard: 5, GameMaterial.advancedShard: 2},
      prerequisiteNodeId: 'shadow_def_1',
    ),
    TalentNodeDefinition(
      id: 'shadow_def_3', name: '暗影護體', description: '減傷 +5%',
      branch: TalentBranch.defense, tier: 3,
      effectType: TalentEffectType.dmgReduction, effectValue: 5,
      goldCost: 1000, materialCost: {GameMaterial.advancedShard: 3, GameMaterial.talentScroll: 1},
      prerequisiteNodeId: 'shadow_def_2',
    ),
    // 輔助分支
    TalentNodeDefinition(
      id: 'shadow_sup_1', name: '暗能聚集', description: '能量獲取 +10%',
      branch: TalentBranch.support, tier: 1,
      effectType: TalentEffectType.energyGainUp, effectValue: 10,
      goldCost: 200, materialCost: {GameMaterial.commonShard: 3},
    ),
    TalentNodeDefinition(
      id: 'shadow_sup_2', name: '連擊暗殺', description: '連擊傷害 +8%',
      branch: TalentBranch.support, tier: 2,
      effectType: TalentEffectType.comboBonus, effectValue: 8,
      goldCost: 500, materialCost: {GameMaterial.commonShard: 5, GameMaterial.advancedShard: 2},
      prerequisiteNodeId: 'shadow_sup_1',
    ),
    TalentNodeDefinition(
      id: 'shadow_sup_3', name: '暗影消除', description: '消除傷害 +10%',
      branch: TalentBranch.support, tier: 3,
      effectType: TalentEffectType.matchDamageUp, effectValue: 10,
      goldCost: 1000, materialCost: {GameMaterial.advancedShard: 3, GameMaterial.talentScroll: 1},
      prerequisiteNodeId: 'shadow_sup_2',
    ),
  ];

  // ─── 燼火 Ember (destroyer, R) ───

  static const emberTalents = <TalentNodeDefinition>[
    // 攻擊分支
    TalentNodeDefinition(
      id: 'ember_atk_1', name: '火花濺射', description: 'ATK +5%',
      branch: TalentBranch.attack, tier: 1,
      effectType: TalentEffectType.atkPercent, effectValue: 5,
      goldCost: 200, materialCost: {GameMaterial.commonShard: 3},
    ),
    TalentNodeDefinition(
      id: 'ember_atk_2', name: '烈焰擴散', description: '消除傷害 +8%',
      branch: TalentBranch.attack, tier: 2,
      effectType: TalentEffectType.matchDamageUp, effectValue: 8,
      goldCost: 500, materialCost: {GameMaterial.commonShard: 5, GameMaterial.advancedShard: 2},
      prerequisiteNodeId: 'ember_atk_1',
    ),
    TalentNodeDefinition(
      id: 'ember_atk_3', name: '焚燒殆盡', description: '技能傷害 +10%',
      branch: TalentBranch.attack, tier: 3,
      effectType: TalentEffectType.skillDamageUp, effectValue: 10,
      goldCost: 1000, materialCost: {GameMaterial.advancedShard: 3, GameMaterial.talentScroll: 1},
      prerequisiteNodeId: 'ember_atk_2',
    ),
    TalentNodeDefinition(
      id: 'ember_atk_4', name: '毀滅之焰', description: '暴擊傷害 +15%',
      branch: TalentBranch.attack, tier: 4,
      effectType: TalentEffectType.critDamage, effectValue: 15,
      goldCost: 2000, materialCost: {GameMaterial.advancedShard: 5, GameMaterial.talentScroll: 2, GameMaterial.rareShard: 1},
      prerequisiteNodeId: 'ember_atk_3',
    ),
    // 防禦分支
    TalentNodeDefinition(
      id: 'ember_def_1', name: '灼熱體魄', description: 'HP +5%',
      branch: TalentBranch.defense, tier: 1,
      effectType: TalentEffectType.hpPercent, effectValue: 5,
      goldCost: 200, materialCost: {GameMaterial.commonShard: 3},
    ),
    TalentNodeDefinition(
      id: 'ember_def_2', name: '火焰屏障', description: 'DEF +5%',
      branch: TalentBranch.defense, tier: 2,
      effectType: TalentEffectType.defPercent, effectValue: 5,
      goldCost: 500, materialCost: {GameMaterial.commonShard: 5, GameMaterial.advancedShard: 2},
      prerequisiteNodeId: 'ember_def_1',
    ),
    TalentNodeDefinition(
      id: 'ember_def_3', name: '餘燼護甲', description: '減傷 +5%',
      branch: TalentBranch.defense, tier: 3,
      effectType: TalentEffectType.dmgReduction, effectValue: 5,
      goldCost: 1000, materialCost: {GameMaterial.advancedShard: 3, GameMaterial.talentScroll: 1},
      prerequisiteNodeId: 'ember_def_2',
    ),
    // 輔助分支
    TalentNodeDefinition(
      id: 'ember_sup_1', name: '火焰能量', description: '能量獲取 +10%',
      branch: TalentBranch.support, tier: 1,
      effectType: TalentEffectType.energyGainUp, effectValue: 10,
      goldCost: 200, materialCost: {GameMaterial.commonShard: 3},
    ),
    TalentNodeDefinition(
      id: 'ember_sup_2', name: '連鎖燃燒', description: '連擊傷害 +5%',
      branch: TalentBranch.support, tier: 2,
      effectType: TalentEffectType.comboBonus, effectValue: 5,
      goldCost: 500, materialCost: {GameMaterial.commonShard: 5, GameMaterial.advancedShard: 2},
      prerequisiteNodeId: 'ember_sup_1',
    ),
    TalentNodeDefinition(
      id: 'ember_sup_3', name: '火海消除', description: '消除傷害 +8%',
      branch: TalentBranch.support, tier: 3,
      effectType: TalentEffectType.matchDamageUp, effectValue: 8,
      goldCost: 1000, materialCost: {GameMaterial.advancedShard: 3, GameMaterial.talentScroll: 1},
      prerequisiteNodeId: 'ember_sup_2',
    ),
  ];

  // ─── 煉獄 Inferno (infiltrator, SR) ───

  static const infernoTalents = <TalentNodeDefinition>[
    // 攻擊分支
    TalentNodeDefinition(
      id: 'inferno_atk_1', name: '灼燒突襲', description: 'ATK +8%',
      branch: TalentBranch.attack, tier: 1,
      effectType: TalentEffectType.atkPercent, effectValue: 8,
      goldCost: 200, materialCost: {GameMaterial.commonShard: 3},
    ),
    TalentNodeDefinition(
      id: 'inferno_atk_2', name: '烈焰穿透', description: '暴擊率 +8%',
      branch: TalentBranch.attack, tier: 2,
      effectType: TalentEffectType.critChance, effectValue: 8,
      goldCost: 500, materialCost: {GameMaterial.commonShard: 5, GameMaterial.advancedShard: 2},
      prerequisiteNodeId: 'inferno_atk_1',
    ),
    TalentNodeDefinition(
      id: 'inferno_atk_3', name: '煉獄斬殺', description: '技能傷害 +12%',
      branch: TalentBranch.attack, tier: 3,
      effectType: TalentEffectType.skillDamageUp, effectValue: 12,
      goldCost: 1000, materialCost: {GameMaterial.advancedShard: 3, GameMaterial.talentScroll: 1},
      prerequisiteNodeId: 'inferno_atk_2',
    ),
    TalentNodeDefinition(
      id: 'inferno_atk_4', name: '業火終焉', description: '暴擊傷害 +20%',
      branch: TalentBranch.attack, tier: 4,
      effectType: TalentEffectType.critDamage, effectValue: 20,
      goldCost: 2000, materialCost: {GameMaterial.advancedShard: 5, GameMaterial.talentScroll: 2, GameMaterial.rareShard: 1},
      prerequisiteNodeId: 'inferno_atk_3',
    ),
    // 防禦分支
    TalentNodeDefinition(
      id: 'inferno_def_1', name: '烈焰殘軀', description: 'HP +5%',
      branch: TalentBranch.defense, tier: 1,
      effectType: TalentEffectType.hpPercent, effectValue: 5,
      goldCost: 200, materialCost: {GameMaterial.commonShard: 3},
    ),
    TalentNodeDefinition(
      id: 'inferno_def_2', name: '灼熱意志', description: 'DEF +5%',
      branch: TalentBranch.defense, tier: 2,
      effectType: TalentEffectType.defPercent, effectValue: 5,
      goldCost: 500, materialCost: {GameMaterial.commonShard: 5, GameMaterial.advancedShard: 2},
      prerequisiteNodeId: 'inferno_def_1',
    ),
    TalentNodeDefinition(
      id: 'inferno_def_3', name: '火牢護體', description: '減傷 +5%',
      branch: TalentBranch.defense, tier: 3,
      effectType: TalentEffectType.dmgReduction, effectValue: 5,
      goldCost: 1000, materialCost: {GameMaterial.advancedShard: 3, GameMaterial.talentScroll: 1},
      prerequisiteNodeId: 'inferno_def_2',
    ),
    // 輔助分支
    TalentNodeDefinition(
      id: 'inferno_sup_1', name: '暗火能量', description: '能量獲取 +10%',
      branch: TalentBranch.support, tier: 1,
      effectType: TalentEffectType.energyGainUp, effectValue: 10,
      goldCost: 200, materialCost: {GameMaterial.commonShard: 3},
    ),
    TalentNodeDefinition(
      id: 'inferno_sup_2', name: '潛行灼燒', description: '消除傷害 +8%',
      branch: TalentBranch.support, tier: 2,
      effectType: TalentEffectType.matchDamageUp, effectValue: 8,
      goldCost: 500, materialCost: {GameMaterial.commonShard: 5, GameMaterial.advancedShard: 2},
      prerequisiteNodeId: 'inferno_sup_1',
    ),
    TalentNodeDefinition(
      id: 'inferno_sup_3', name: '焚世連擊', description: '連擊傷害 +8%',
      branch: TalentBranch.support, tier: 3,
      effectType: TalentEffectType.comboBonus, effectValue: 8,
      goldCost: 1000, materialCost: {GameMaterial.advancedShard: 3, GameMaterial.talentScroll: 1},
      prerequisiteNodeId: 'inferno_sup_2',
    ),
  ];

  // ─── 萌芽 Sprout (supporter, N) ───

  static const sproutTalents = <TalentNodeDefinition>[
    // 攻擊分支
    TalentNodeDefinition(
      id: 'sprout_atk_1', name: '藤蔓抽打', description: 'ATK +5%',
      branch: TalentBranch.attack, tier: 1,
      effectType: TalentEffectType.atkPercent, effectValue: 5,
      goldCost: 200, materialCost: {GameMaterial.commonShard: 3},
    ),
    TalentNodeDefinition(
      id: 'sprout_atk_2', name: '荊棘纏繞', description: '消除傷害 +5%',
      branch: TalentBranch.attack, tier: 2,
      effectType: TalentEffectType.matchDamageUp, effectValue: 5,
      goldCost: 500, materialCost: {GameMaterial.commonShard: 5, GameMaterial.advancedShard: 2},
      prerequisiteNodeId: 'sprout_atk_1',
    ),
    TalentNodeDefinition(
      id: 'sprout_atk_3', name: '自然之怒', description: '技能傷害 +8%',
      branch: TalentBranch.attack, tier: 3,
      effectType: TalentEffectType.skillDamageUp, effectValue: 8,
      goldCost: 1000, materialCost: {GameMaterial.advancedShard: 3, GameMaterial.talentScroll: 1},
      prerequisiteNodeId: 'sprout_atk_2',
    ),
    // 防禦分支
    TalentNodeDefinition(
      id: 'sprout_def_1', name: '樹皮護體', description: 'HP +8%',
      branch: TalentBranch.defense, tier: 1,
      effectType: TalentEffectType.hpPercent, effectValue: 8,
      goldCost: 200, materialCost: {GameMaterial.commonShard: 3},
    ),
    TalentNodeDefinition(
      id: 'sprout_def_2', name: '根系穩固', description: 'DEF +5%',
      branch: TalentBranch.defense, tier: 2,
      effectType: TalentEffectType.defPercent, effectValue: 5,
      goldCost: 500, materialCost: {GameMaterial.commonShard: 5, GameMaterial.advancedShard: 2},
      prerequisiteNodeId: 'sprout_def_1',
    ),
    TalentNodeDefinition(
      id: 'sprout_def_3', name: '生命之樹', description: 'HP +10%',
      branch: TalentBranch.defense, tier: 3,
      effectType: TalentEffectType.hpPercent, effectValue: 10,
      goldCost: 1000, materialCost: {GameMaterial.advancedShard: 3, GameMaterial.talentScroll: 1},
      prerequisiteNodeId: 'sprout_def_2',
    ),
    // 輔助分支
    TalentNodeDefinition(
      id: 'sprout_sup_1', name: '治癒花粉', description: '治療效果 +10%',
      branch: TalentBranch.support, tier: 1,
      effectType: TalentEffectType.healBoost, effectValue: 10,
      goldCost: 200, materialCost: {GameMaterial.commonShard: 3},
    ),
    TalentNodeDefinition(
      id: 'sprout_sup_2', name: '光合能量', description: '能量獲取 +15%',
      branch: TalentBranch.support, tier: 2,
      effectType: TalentEffectType.energyGainUp, effectValue: 15,
      goldCost: 500, materialCost: {GameMaterial.commonShard: 5, GameMaterial.advancedShard: 2},
      prerequisiteNodeId: 'sprout_sup_1',
    ),
    TalentNodeDefinition(
      id: 'sprout_sup_3', name: '森林恩賜', description: '治療效果 +15%',
      branch: TalentBranch.support, tier: 3,
      effectType: TalentEffectType.healBoost, effectValue: 15,
      goldCost: 1000, materialCost: {GameMaterial.advancedShard: 3, GameMaterial.talentScroll: 1},
      prerequisiteNodeId: 'sprout_sup_2',
    ),
  ];

  // ─── 大地母神 Gaia (striker, SR) ───

  static const gaiaTalents = <TalentNodeDefinition>[
    // 攻擊分支
    TalentNodeDefinition(
      id: 'gaia_atk_1', name: '巨石衝擊', description: 'ATK +8%',
      branch: TalentBranch.attack, tier: 1,
      effectType: TalentEffectType.atkPercent, effectValue: 8,
      goldCost: 200, materialCost: {GameMaterial.commonShard: 3},
    ),
    TalentNodeDefinition(
      id: 'gaia_atk_2', name: '地殼震裂', description: '技能傷害 +10%',
      branch: TalentBranch.attack, tier: 2,
      effectType: TalentEffectType.skillDamageUp, effectValue: 10,
      goldCost: 500, materialCost: {GameMaterial.commonShard: 5, GameMaterial.advancedShard: 2},
      prerequisiteNodeId: 'gaia_atk_1',
    ),
    TalentNodeDefinition(
      id: 'gaia_atk_3', name: '山崩地裂', description: '暴擊率 +8%',
      branch: TalentBranch.attack, tier: 3,
      effectType: TalentEffectType.critChance, effectValue: 8,
      goldCost: 1000, materialCost: {GameMaterial.advancedShard: 3, GameMaterial.talentScroll: 1},
      prerequisiteNodeId: 'gaia_atk_2',
    ),
    TalentNodeDefinition(
      id: 'gaia_atk_4', name: '天崩地裂', description: '暴擊傷害 +20%',
      branch: TalentBranch.attack, tier: 4,
      effectType: TalentEffectType.critDamage, effectValue: 20,
      goldCost: 2000, materialCost: {GameMaterial.advancedShard: 5, GameMaterial.talentScroll: 2, GameMaterial.rareShard: 1},
      prerequisiteNodeId: 'gaia_atk_3',
    ),
    // 防禦分支
    TalentNodeDefinition(
      id: 'gaia_def_1', name: '大地護衛', description: 'HP +5%',
      branch: TalentBranch.defense, tier: 1,
      effectType: TalentEffectType.hpPercent, effectValue: 5,
      goldCost: 200, materialCost: {GameMaterial.commonShard: 3},
    ),
    TalentNodeDefinition(
      id: 'gaia_def_2', name: '岩石鎧甲', description: 'DEF +5%',
      branch: TalentBranch.defense, tier: 2,
      effectType: TalentEffectType.defPercent, effectValue: 5,
      goldCost: 500, materialCost: {GameMaterial.commonShard: 5, GameMaterial.advancedShard: 2},
      prerequisiteNodeId: 'gaia_def_1',
    ),
    TalentNodeDefinition(
      id: 'gaia_def_3', name: '磐石之軀', description: '減傷 +5%',
      branch: TalentBranch.defense, tier: 3,
      effectType: TalentEffectType.dmgReduction, effectValue: 5,
      goldCost: 1000, materialCost: {GameMaterial.advancedShard: 3, GameMaterial.talentScroll: 1},
      prerequisiteNodeId: 'gaia_def_2',
    ),
    // 輔助分支
    TalentNodeDefinition(
      id: 'gaia_sup_1', name: '地脈能量', description: '能量獲取 +10%',
      branch: TalentBranch.support, tier: 1,
      effectType: TalentEffectType.energyGainUp, effectValue: 10,
      goldCost: 200, materialCost: {GameMaterial.commonShard: 3},
    ),
    TalentNodeDefinition(
      id: 'gaia_sup_2', name: '大地連擊', description: '連擊傷害 +8%',
      branch: TalentBranch.support, tier: 2,
      effectType: TalentEffectType.comboBonus, effectValue: 8,
      goldCost: 500, materialCost: {GameMaterial.commonShard: 5, GameMaterial.advancedShard: 2},
      prerequisiteNodeId: 'gaia_sup_1',
    ),
    TalentNodeDefinition(
      id: 'gaia_sup_3', name: '地震消除', description: '消除傷害 +10%',
      branch: TalentBranch.support, tier: 3,
      effectType: TalentEffectType.matchDamageUp, effectValue: 10,
      goldCost: 1000, materialCost: {GameMaterial.advancedShard: 3, GameMaterial.talentScroll: 1},
      prerequisiteNodeId: 'gaia_sup_2',
    ),
  ];

  // ─── 冰霜 Frost (defender, R) ───

  static const frostTalents = <TalentNodeDefinition>[
    // 攻擊分支
    TalentNodeDefinition(
      id: 'frost_atk_1', name: '冰錐打擊', description: 'ATK +5%',
      branch: TalentBranch.attack, tier: 1,
      effectType: TalentEffectType.atkPercent, effectValue: 5,
      goldCost: 200, materialCost: {GameMaterial.commonShard: 3},
    ),
    TalentNodeDefinition(
      id: 'frost_atk_2', name: '寒氣侵蝕', description: '消除傷害 +5%',
      branch: TalentBranch.attack, tier: 2,
      effectType: TalentEffectType.matchDamageUp, effectValue: 5,
      goldCost: 500, materialCost: {GameMaterial.commonShard: 5, GameMaterial.advancedShard: 2},
      prerequisiteNodeId: 'frost_atk_1',
    ),
    TalentNodeDefinition(
      id: 'frost_atk_3', name: '冰封衝擊', description: '技能傷害 +8%',
      branch: TalentBranch.attack, tier: 3,
      effectType: TalentEffectType.skillDamageUp, effectValue: 8,
      goldCost: 1000, materialCost: {GameMaterial.advancedShard: 3, GameMaterial.talentScroll: 1},
      prerequisiteNodeId: 'frost_atk_2',
    ),
    // 防禦分支
    TalentNodeDefinition(
      id: 'frost_def_1', name: '冰晶護甲', description: 'DEF +8%',
      branch: TalentBranch.defense, tier: 1,
      effectType: TalentEffectType.defPercent, effectValue: 8,
      goldCost: 200, materialCost: {GameMaterial.commonShard: 3},
    ),
    TalentNodeDefinition(
      id: 'frost_def_2', name: '寒冰體魄', description: 'HP +10%',
      branch: TalentBranch.defense, tier: 2,
      effectType: TalentEffectType.hpPercent, effectValue: 10,
      goldCost: 500, materialCost: {GameMaterial.commonShard: 5, GameMaterial.advancedShard: 2},
      prerequisiteNodeId: 'frost_def_1',
    ),
    TalentNodeDefinition(
      id: 'frost_def_3', name: '冰盾強化', description: '護盾效果 +15%',
      branch: TalentBranch.defense, tier: 3,
      effectType: TalentEffectType.shieldBoost, effectValue: 15,
      goldCost: 1000, materialCost: {GameMaterial.advancedShard: 3, GameMaterial.talentScroll: 1},
      prerequisiteNodeId: 'frost_def_2',
    ),
    TalentNodeDefinition(
      id: 'frost_def_4', name: '永凍壁壘', description: '減傷 +10%',
      branch: TalentBranch.defense, tier: 4,
      effectType: TalentEffectType.dmgReduction, effectValue: 10,
      goldCost: 2000, materialCost: {GameMaterial.advancedShard: 5, GameMaterial.talentScroll: 2, GameMaterial.rareShard: 1},
      prerequisiteNodeId: 'frost_def_3',
    ),
    // 輔助分支
    TalentNodeDefinition(
      id: 'frost_sup_1', name: '寒氣凝聚', description: '能量獲取 +10%',
      branch: TalentBranch.support, tier: 1,
      effectType: TalentEffectType.energyGainUp, effectValue: 10,
      goldCost: 200, materialCost: {GameMaterial.commonShard: 3},
    ),
    TalentNodeDefinition(
      id: 'frost_sup_2', name: '冰霜治癒', description: 'HP +8%',
      branch: TalentBranch.support, tier: 2,
      effectType: TalentEffectType.hpPercent, effectValue: 8,
      goldCost: 500, materialCost: {GameMaterial.commonShard: 5, GameMaterial.advancedShard: 2},
      prerequisiteNodeId: 'frost_sup_1',
    ),
    TalentNodeDefinition(
      id: 'frost_sup_3', name: '冰牆防禦', description: 'DEF +5%',
      branch: TalentBranch.support, tier: 3,
      effectType: TalentEffectType.defPercent, effectValue: 5,
      goldCost: 1000, materialCost: {GameMaterial.advancedShard: 3, GameMaterial.talentScroll: 1},
      prerequisiteNodeId: 'frost_sup_2',
    ),
  ];

  // ─── 海嘯 Tsunami (destroyer, SR) ───

  static const tsunamiTalents = <TalentNodeDefinition>[
    // 攻擊分支
    TalentNodeDefinition(
      id: 'tsunami_atk_1', name: '巨浪衝擊', description: 'ATK +8%',
      branch: TalentBranch.attack, tier: 1,
      effectType: TalentEffectType.atkPercent, effectValue: 8,
      goldCost: 200, materialCost: {GameMaterial.commonShard: 3},
    ),
    TalentNodeDefinition(
      id: 'tsunami_atk_2', name: '洪流擴散', description: '消除傷害 +10%',
      branch: TalentBranch.attack, tier: 2,
      effectType: TalentEffectType.matchDamageUp, effectValue: 10,
      goldCost: 500, materialCost: {GameMaterial.commonShard: 5, GameMaterial.advancedShard: 2},
      prerequisiteNodeId: 'tsunami_atk_1',
    ),
    TalentNodeDefinition(
      id: 'tsunami_atk_3', name: '怒濤精通', description: '技能傷害 +12%',
      branch: TalentBranch.attack, tier: 3,
      effectType: TalentEffectType.skillDamageUp, effectValue: 12,
      goldCost: 1000, materialCost: {GameMaterial.advancedShard: 3, GameMaterial.talentScroll: 1},
      prerequisiteNodeId: 'tsunami_atk_2',
    ),
    TalentNodeDefinition(
      id: 'tsunami_atk_4', name: '滅世洪水', description: '暴擊傷害 +15%',
      branch: TalentBranch.attack, tier: 4,
      effectType: TalentEffectType.critDamage, effectValue: 15,
      goldCost: 2000, materialCost: {GameMaterial.advancedShard: 5, GameMaterial.talentScroll: 2, GameMaterial.rareShard: 1},
      prerequisiteNodeId: 'tsunami_atk_3',
    ),
    // 防禦分支
    TalentNodeDefinition(
      id: 'tsunami_def_1', name: '水壓體魄', description: 'HP +5%',
      branch: TalentBranch.defense, tier: 1,
      effectType: TalentEffectType.hpPercent, effectValue: 5,
      goldCost: 200, materialCost: {GameMaterial.commonShard: 3},
    ),
    TalentNodeDefinition(
      id: 'tsunami_def_2', name: '深海護甲', description: 'DEF +5%',
      branch: TalentBranch.defense, tier: 2,
      effectType: TalentEffectType.defPercent, effectValue: 5,
      goldCost: 500, materialCost: {GameMaterial.commonShard: 5, GameMaterial.advancedShard: 2},
      prerequisiteNodeId: 'tsunami_def_1',
    ),
    TalentNodeDefinition(
      id: 'tsunami_def_3', name: '潮汐護體', description: '減傷 +5%',
      branch: TalentBranch.defense, tier: 3,
      effectType: TalentEffectType.dmgReduction, effectValue: 5,
      goldCost: 1000, materialCost: {GameMaterial.advancedShard: 3, GameMaterial.talentScroll: 1},
      prerequisiteNodeId: 'tsunami_def_2',
    ),
    // 輔助分支
    TalentNodeDefinition(
      id: 'tsunami_sup_1', name: '潮汐能量', description: '能量獲取 +10%',
      branch: TalentBranch.support, tier: 1,
      effectType: TalentEffectType.energyGainUp, effectValue: 10,
      goldCost: 200, materialCost: {GameMaterial.commonShard: 3},
    ),
    TalentNodeDefinition(
      id: 'tsunami_sup_2', name: '浪潮連擊', description: '連擊傷害 +8%',
      branch: TalentBranch.support, tier: 2,
      effectType: TalentEffectType.comboBonus, effectValue: 8,
      goldCost: 500, materialCost: {GameMaterial.commonShard: 5, GameMaterial.advancedShard: 2},
      prerequisiteNodeId: 'tsunami_sup_1',
    ),
    TalentNodeDefinition(
      id: 'tsunami_sup_3', name: '洪流消除', description: '消除傷害 +8%',
      branch: TalentBranch.support, tier: 3,
      effectType: TalentEffectType.matchDamageUp, effectValue: 8,
      goldCost: 1000, materialCost: {GameMaterial.advancedShard: 3, GameMaterial.talentScroll: 1},
      prerequisiteNodeId: 'tsunami_sup_2',
    ),
  ];

  // ─── 電火花 Spark (supporter, N) ───

  static const sparkTalents = <TalentNodeDefinition>[
    // 攻擊分支
    TalentNodeDefinition(
      id: 'spark_atk_1', name: '靜電釋放', description: 'ATK +5%',
      branch: TalentBranch.attack, tier: 1,
      effectType: TalentEffectType.atkPercent, effectValue: 5,
      goldCost: 200, materialCost: {GameMaterial.commonShard: 3},
    ),
    TalentNodeDefinition(
      id: 'spark_atk_2', name: '電弧打擊', description: '消除傷害 +5%',
      branch: TalentBranch.attack, tier: 2,
      effectType: TalentEffectType.matchDamageUp, effectValue: 5,
      goldCost: 500, materialCost: {GameMaterial.commonShard: 5, GameMaterial.advancedShard: 2},
      prerequisiteNodeId: 'spark_atk_1',
    ),
    TalentNodeDefinition(
      id: 'spark_atk_3', name: '電擊精通', description: '技能傷害 +8%',
      branch: TalentBranch.attack, tier: 3,
      effectType: TalentEffectType.skillDamageUp, effectValue: 8,
      goldCost: 1000, materialCost: {GameMaterial.advancedShard: 3, GameMaterial.talentScroll: 1},
      prerequisiteNodeId: 'spark_atk_2',
    ),
    // 防禦分支
    TalentNodeDefinition(
      id: 'spark_def_1', name: '電磁體質', description: 'HP +8%',
      branch: TalentBranch.defense, tier: 1,
      effectType: TalentEffectType.hpPercent, effectValue: 8,
      goldCost: 200, materialCost: {GameMaterial.commonShard: 3},
    ),
    TalentNodeDefinition(
      id: 'spark_def_2', name: '電場護體', description: 'DEF +5%',
      branch: TalentBranch.defense, tier: 2,
      effectType: TalentEffectType.defPercent, effectValue: 5,
      goldCost: 500, materialCost: {GameMaterial.commonShard: 5, GameMaterial.advancedShard: 2},
      prerequisiteNodeId: 'spark_def_1',
    ),
    TalentNodeDefinition(
      id: 'spark_def_3', name: '充電體魄', description: 'HP +10%',
      branch: TalentBranch.defense, tier: 3,
      effectType: TalentEffectType.hpPercent, effectValue: 10,
      goldCost: 1000, materialCost: {GameMaterial.advancedShard: 3, GameMaterial.talentScroll: 1},
      prerequisiteNodeId: 'spark_def_2',
    ),
    // 輔助分支
    TalentNodeDefinition(
      id: 'spark_sup_1', name: '電能治癒', description: '治療效果 +10%',
      branch: TalentBranch.support, tier: 1,
      effectType: TalentEffectType.healBoost, effectValue: 10,
      goldCost: 200, materialCost: {GameMaterial.commonShard: 3},
    ),
    TalentNodeDefinition(
      id: 'spark_sup_2', name: '電流充能', description: '能量獲取 +15%',
      branch: TalentBranch.support, tier: 2,
      effectType: TalentEffectType.energyGainUp, effectValue: 15,
      goldCost: 500, materialCost: {GameMaterial.commonShard: 5, GameMaterial.advancedShard: 2},
      prerequisiteNodeId: 'spark_sup_1',
    ),
    TalentNodeDefinition(
      id: 'spark_sup_3', name: '電療恢復', description: '治療效果 +15%',
      branch: TalentBranch.support, tier: 3,
      effectType: TalentEffectType.healBoost, effectValue: 15,
      goldCost: 1000, materialCost: {GameMaterial.advancedShard: 3, GameMaterial.talentScroll: 1},
      prerequisiteNodeId: 'spark_sup_2',
    ),
  ];

  // ─── 雷霆 Thunder (striker, SR) ───

  static const thunderTalents = <TalentNodeDefinition>[
    // 攻擊分支
    TalentNodeDefinition(
      id: 'thunder_atk_1', name: '雷擊拳', description: 'ATK +8%',
      branch: TalentBranch.attack, tier: 1,
      effectType: TalentEffectType.atkPercent, effectValue: 8,
      goldCost: 200, materialCost: {GameMaterial.commonShard: 3},
    ),
    TalentNodeDefinition(
      id: 'thunder_atk_2', name: '閃電精通', description: '技能傷害 +10%',
      branch: TalentBranch.attack, tier: 2,
      effectType: TalentEffectType.skillDamageUp, effectValue: 10,
      goldCost: 500, materialCost: {GameMaterial.commonShard: 5, GameMaterial.advancedShard: 2},
      prerequisiteNodeId: 'thunder_atk_1',
    ),
    TalentNodeDefinition(
      id: 'thunder_atk_3', name: '雷電暴擊', description: '暴擊率 +8%',
      branch: TalentBranch.attack, tier: 3,
      effectType: TalentEffectType.critChance, effectValue: 8,
      goldCost: 1000, materialCost: {GameMaterial.advancedShard: 3, GameMaterial.talentScroll: 1},
      prerequisiteNodeId: 'thunder_atk_2',
    ),
    TalentNodeDefinition(
      id: 'thunder_atk_4', name: '天雷轟頂', description: '暴擊傷害 +20%',
      branch: TalentBranch.attack, tier: 4,
      effectType: TalentEffectType.critDamage, effectValue: 20,
      goldCost: 2000, materialCost: {GameMaterial.advancedShard: 5, GameMaterial.talentScroll: 2, GameMaterial.rareShard: 1},
      prerequisiteNodeId: 'thunder_atk_3',
    ),
    // 防禦分支
    TalentNodeDefinition(
      id: 'thunder_def_1', name: '雷電體質', description: 'HP +5%',
      branch: TalentBranch.defense, tier: 1,
      effectType: TalentEffectType.hpPercent, effectValue: 5,
      goldCost: 200, materialCost: {GameMaterial.commonShard: 3},
    ),
    TalentNodeDefinition(
      id: 'thunder_def_2', name: '雷場護甲', description: 'DEF +5%',
      branch: TalentBranch.defense, tier: 2,
      effectType: TalentEffectType.defPercent, effectValue: 5,
      goldCost: 500, materialCost: {GameMaterial.commonShard: 5, GameMaterial.advancedShard: 2},
      prerequisiteNodeId: 'thunder_def_1',
    ),
    TalentNodeDefinition(
      id: 'thunder_def_3', name: '電流抗性', description: '減傷 +5%',
      branch: TalentBranch.defense, tier: 3,
      effectType: TalentEffectType.dmgReduction, effectValue: 5,
      goldCost: 1000, materialCost: {GameMaterial.advancedShard: 3, GameMaterial.talentScroll: 1},
      prerequisiteNodeId: 'thunder_def_2',
    ),
    // 輔助分支
    TalentNodeDefinition(
      id: 'thunder_sup_1', name: '電能脈衝', description: '能量獲取 +10%',
      branch: TalentBranch.support, tier: 1,
      effectType: TalentEffectType.energyGainUp, effectValue: 10,
      goldCost: 200, materialCost: {GameMaterial.commonShard: 3},
    ),
    TalentNodeDefinition(
      id: 'thunder_sup_2', name: '雷電連擊', description: '連擊傷害 +8%',
      branch: TalentBranch.support, tier: 2,
      effectType: TalentEffectType.comboBonus, effectValue: 8,
      goldCost: 500, materialCost: {GameMaterial.commonShard: 5, GameMaterial.advancedShard: 2},
      prerequisiteNodeId: 'thunder_sup_1',
    ),
    TalentNodeDefinition(
      id: 'thunder_sup_3', name: '閃電消除', description: '消除傷害 +10%',
      branch: TalentBranch.support, tier: 3,
      effectType: TalentEffectType.matchDamageUp, effectValue: 10,
      goldCost: 1000, materialCost: {GameMaterial.advancedShard: 3, GameMaterial.talentScroll: 1},
      prerequisiteNodeId: 'thunder_sup_2',
    ),
  ];

  // ─── 幻影 Phantom (defender, N) ───

  static const phantomTalents = <TalentNodeDefinition>[
    // 攻擊分支
    TalentNodeDefinition(
      id: 'phantom_atk_1', name: '幽影爪擊', description: 'ATK +5%',
      branch: TalentBranch.attack, tier: 1,
      effectType: TalentEffectType.atkPercent, effectValue: 5,
      goldCost: 200, materialCost: {GameMaterial.commonShard: 3},
    ),
    TalentNodeDefinition(
      id: 'phantom_atk_2', name: '暗影侵蝕', description: '消除傷害 +5%',
      branch: TalentBranch.attack, tier: 2,
      effectType: TalentEffectType.matchDamageUp, effectValue: 5,
      goldCost: 500, materialCost: {GameMaterial.commonShard: 5, GameMaterial.advancedShard: 2},
      prerequisiteNodeId: 'phantom_atk_1',
    ),
    TalentNodeDefinition(
      id: 'phantom_atk_3', name: '虛無打擊', description: '技能傷害 +8%',
      branch: TalentBranch.attack, tier: 3,
      effectType: TalentEffectType.skillDamageUp, effectValue: 8,
      goldCost: 1000, materialCost: {GameMaterial.advancedShard: 3, GameMaterial.talentScroll: 1},
      prerequisiteNodeId: 'phantom_atk_2',
    ),
    // 防禦分支
    TalentNodeDefinition(
      id: 'phantom_def_1', name: '幽魂護甲', description: 'DEF +8%',
      branch: TalentBranch.defense, tier: 1,
      effectType: TalentEffectType.defPercent, effectValue: 8,
      goldCost: 200, materialCost: {GameMaterial.commonShard: 3},
    ),
    TalentNodeDefinition(
      id: 'phantom_def_2', name: '暗影體魄', description: 'HP +10%',
      branch: TalentBranch.defense, tier: 2,
      effectType: TalentEffectType.hpPercent, effectValue: 10,
      goldCost: 500, materialCost: {GameMaterial.commonShard: 5, GameMaterial.advancedShard: 2},
      prerequisiteNodeId: 'phantom_def_1',
    ),
    TalentNodeDefinition(
      id: 'phantom_def_3', name: '幻影護盾', description: '護盾效果 +15%',
      branch: TalentBranch.defense, tier: 3,
      effectType: TalentEffectType.shieldBoost, effectValue: 15,
      goldCost: 1000, materialCost: {GameMaterial.advancedShard: 3, GameMaterial.talentScroll: 1},
      prerequisiteNodeId: 'phantom_def_2',
    ),
    TalentNodeDefinition(
      id: 'phantom_def_4', name: '虛無壁壘', description: '減傷 +10%',
      branch: TalentBranch.defense, tier: 4,
      effectType: TalentEffectType.dmgReduction, effectValue: 10,
      goldCost: 2000, materialCost: {GameMaterial.advancedShard: 5, GameMaterial.talentScroll: 2, GameMaterial.rareShard: 1},
      prerequisiteNodeId: 'phantom_def_3',
    ),
    // 輔助分支
    TalentNodeDefinition(
      id: 'phantom_sup_1', name: '暗影能量', description: '能量獲取 +10%',
      branch: TalentBranch.support, tier: 1,
      effectType: TalentEffectType.energyGainUp, effectValue: 10,
      goldCost: 200, materialCost: {GameMaterial.commonShard: 3},
    ),
    TalentNodeDefinition(
      id: 'phantom_sup_2', name: '幽魂回復', description: 'HP +8%',
      branch: TalentBranch.support, tier: 2,
      effectType: TalentEffectType.hpPercent, effectValue: 8,
      goldCost: 500, materialCost: {GameMaterial.commonShard: 5, GameMaterial.advancedShard: 2},
      prerequisiteNodeId: 'phantom_sup_1',
    ),
    TalentNodeDefinition(
      id: 'phantom_sup_3', name: '暗影守護', description: 'DEF +5%',
      branch: TalentBranch.support, tier: 3,
      effectType: TalentEffectType.defPercent, effectValue: 5,
      goldCost: 1000, materialCost: {GameMaterial.advancedShard: 3, GameMaterial.talentScroll: 1},
      prerequisiteNodeId: 'phantom_sup_2',
    ),
  ];

  // ─── 蝕日 Eclipse (destroyer, R) ───

  static const eclipseTalents = <TalentNodeDefinition>[
    // 攻擊分支
    TalentNodeDefinition(
      id: 'eclipse_atk_1', name: '暗蝕打擊', description: 'ATK +5%',
      branch: TalentBranch.attack, tier: 1,
      effectType: TalentEffectType.atkPercent, effectValue: 5,
      goldCost: 200, materialCost: {GameMaterial.commonShard: 3},
    ),
    TalentNodeDefinition(
      id: 'eclipse_atk_2', name: '蝕光擴散', description: '消除傷害 +8%',
      branch: TalentBranch.attack, tier: 2,
      effectType: TalentEffectType.matchDamageUp, effectValue: 8,
      goldCost: 500, materialCost: {GameMaterial.commonShard: 5, GameMaterial.advancedShard: 2},
      prerequisiteNodeId: 'eclipse_atk_1',
    ),
    TalentNodeDefinition(
      id: 'eclipse_atk_3', name: '蝕日精通', description: '技能傷害 +10%',
      branch: TalentBranch.attack, tier: 3,
      effectType: TalentEffectType.skillDamageUp, effectValue: 10,
      goldCost: 1000, materialCost: {GameMaterial.advancedShard: 3, GameMaterial.talentScroll: 1},
      prerequisiteNodeId: 'eclipse_atk_2',
    ),
    TalentNodeDefinition(
      id: 'eclipse_atk_4', name: '永夜吞噬', description: '暴擊傷害 +15%',
      branch: TalentBranch.attack, tier: 4,
      effectType: TalentEffectType.critDamage, effectValue: 15,
      goldCost: 2000, materialCost: {GameMaterial.advancedShard: 5, GameMaterial.talentScroll: 2, GameMaterial.rareShard: 1},
      prerequisiteNodeId: 'eclipse_atk_3',
    ),
    // 防禦分支
    TalentNodeDefinition(
      id: 'eclipse_def_1', name: '黑暗體魄', description: 'HP +5%',
      branch: TalentBranch.defense, tier: 1,
      effectType: TalentEffectType.hpPercent, effectValue: 5,
      goldCost: 200, materialCost: {GameMaterial.commonShard: 3},
    ),
    TalentNodeDefinition(
      id: 'eclipse_def_2', name: '蝕影護甲', description: 'DEF +5%',
      branch: TalentBranch.defense, tier: 2,
      effectType: TalentEffectType.defPercent, effectValue: 5,
      goldCost: 500, materialCost: {GameMaterial.commonShard: 5, GameMaterial.advancedShard: 2},
      prerequisiteNodeId: 'eclipse_def_1',
    ),
    TalentNodeDefinition(
      id: 'eclipse_def_3', name: '暗蝕護體', description: '減傷 +5%',
      branch: TalentBranch.defense, tier: 3,
      effectType: TalentEffectType.dmgReduction, effectValue: 5,
      goldCost: 1000, materialCost: {GameMaterial.advancedShard: 3, GameMaterial.talentScroll: 1},
      prerequisiteNodeId: 'eclipse_def_2',
    ),
    // 輔助分支
    TalentNodeDefinition(
      id: 'eclipse_sup_1', name: '蝕光能量', description: '能量獲取 +10%',
      branch: TalentBranch.support, tier: 1,
      effectType: TalentEffectType.energyGainUp, effectValue: 10,
      goldCost: 200, materialCost: {GameMaterial.commonShard: 3},
    ),
    TalentNodeDefinition(
      id: 'eclipse_sup_2', name: '暗蝕連擊', description: '連擊傷害 +5%',
      branch: TalentBranch.support, tier: 2,
      effectType: TalentEffectType.comboBonus, effectValue: 5,
      goldCost: 500, materialCost: {GameMaterial.commonShard: 5, GameMaterial.advancedShard: 2},
      prerequisiteNodeId: 'eclipse_sup_1',
    ),
    TalentNodeDefinition(
      id: 'eclipse_sup_3', name: '蝕日消除', description: '消除傷害 +8%',
      branch: TalentBranch.support, tier: 3,
      effectType: TalentEffectType.matchDamageUp, effectValue: 8,
      goldCost: 1000, materialCost: {GameMaterial.advancedShard: 3, GameMaterial.talentScroll: 1},
      prerequisiteNodeId: 'eclipse_sup_2',
    ),
  ];

  // ─── 查詢方法 ───

  static const Map<String, List<TalentNodeDefinition>> _agentTalents = {
    'blaze': blazeTalents,
    'tide': tideTalents,
    'terra': terraTalents,
    'flash': flashTalents,
    'shadow': shadowTalents,
    'ember': emberTalents,
    'inferno': infernoTalents,
    'sprout': sproutTalents,
    'gaia': gaiaTalents,
    'frost': frostTalents,
    'tsunami': tsunamiTalents,
    'spark': sparkTalents,
    'thunder': thunderTalents,
    'phantom': phantomTalents,
    'eclipse': eclipseTalents,
  };

  static List<TalentNodeDefinition> getTalentsForAgent(String agentId) {
    return _agentTalents[agentId] ?? [];
  }

  static TalentNodeDefinition? getNodeById(String nodeId) {
    for (final talents in _agentTalents.values) {
      for (final node in talents) {
        if (node.id == nodeId) return node;
      }
    }
    return null;
  }

  static List<TalentNodeDefinition> getNodesForBranch(
    String agentId,
    TalentBranch branch,
  ) {
    return getTalentsForAgent(agentId)
        .where((n) => n.branch == branch)
        .toList()
      ..sort((a, b) => a.tier.compareTo(b.tier));
  }
}
