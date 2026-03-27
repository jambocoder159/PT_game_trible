/// 天賦樹靜態數據
/// 5 隻貓各有 3 分支 × 3~4 節點
import '../core/models/material.dart';
import '../core/models/talent_tree.dart';

class TalentTreeData {
  TalentTreeData._();

  // ─── 小麥 Wheat ───

  static const blazeTalents = <TalentNodeDefinition>[
    // 攻擊分支
    TalentNodeDefinition(
      id: 'blaze_atk_1', name: '揉麵強化', description: 'ATK +5%',
      branch: TalentBranch.attack, tier: 1,
      effectType: TalentEffectType.atkPercent, effectValue: 5,
      goldCost: 200, materialCost: {GameMaterial.commonShard: 3},
    ),
    TalentNodeDefinition(
      id: 'blaze_atk_2', name: '麵粉之力', description: 'ATK +8%',
      branch: TalentBranch.attack, tier: 2,
      effectType: TalentEffectType.atkPercent, effectValue: 8,
      goldCost: 500, materialCost: {GameMaterial.commonShard: 5, GameMaterial.advancedShard: 2},
      prerequisiteNodeId: 'blaze_atk_1',
    ),
    TalentNodeDefinition(
      id: 'blaze_atk_3', name: '烘焙精通', description: '技能傷害 +10%',
      branch: TalentBranch.attack, tier: 3,
      effectType: TalentEffectType.skillDamageUp, effectValue: 10,
      goldCost: 1000, materialCost: {GameMaterial.advancedShard: 3, GameMaterial.talentScroll: 1},
      prerequisiteNodeId: 'blaze_atk_2',
    ),
    TalentNodeDefinition(
      id: 'blaze_atk_4', name: '完美出爐', description: '暴擊傷害 +15%',
      branch: TalentBranch.attack, tier: 4,
      effectType: TalentEffectType.critDamage, effectValue: 15,
      goldCost: 2000, materialCost: {GameMaterial.advancedShard: 5, GameMaterial.talentScroll: 2, GameMaterial.rareShard: 1},
      prerequisiteNodeId: 'blaze_atk_3',
    ),
    // 防禦分支
    TalentNodeDefinition(
      id: 'blaze_def_1', name: '厚實麵皮', description: 'HP +5%',
      branch: TalentBranch.defense, tier: 1,
      effectType: TalentEffectType.hpPercent, effectValue: 5,
      goldCost: 200, materialCost: {GameMaterial.commonShard: 3},
    ),
    TalentNodeDefinition(
      id: 'blaze_def_2', name: '營養強化', description: 'HP +8%',
      branch: TalentBranch.defense, tier: 2,
      effectType: TalentEffectType.hpPercent, effectValue: 8,
      goldCost: 500, materialCost: {GameMaterial.commonShard: 5, GameMaterial.advancedShard: 2},
      prerequisiteNodeId: 'blaze_def_1',
    ),
    TalentNodeDefinition(
      id: 'blaze_def_3', name: '麵包護甲', description: '減傷 +5%',
      branch: TalentBranch.defense, tier: 3,
      effectType: TalentEffectType.dmgReduction, effectValue: 5,
      goldCost: 1000, materialCost: {GameMaterial.advancedShard: 3, GameMaterial.talentScroll: 1},
      prerequisiteNodeId: 'blaze_def_2',
    ),
    // 輔助分支
    TalentNodeDefinition(
      id: 'blaze_sup_1', name: '發酵導引', description: '能量獲取 +10%',
      branch: TalentBranch.support, tier: 1,
      effectType: TalentEffectType.energyGainUp, effectValue: 10,
      goldCost: 200, materialCost: {GameMaterial.commonShard: 3},
    ),
    TalentNodeDefinition(
      id: 'blaze_sup_2', name: '連續烘焙', description: '連擊傷害 +5%',
      branch: TalentBranch.support, tier: 2,
      effectType: TalentEffectType.comboBonus, effectValue: 5,
      goldCost: 500, materialCost: {GameMaterial.commonShard: 5, GameMaterial.advancedShard: 2},
      prerequisiteNodeId: 'blaze_sup_1',
    ),
    TalentNodeDefinition(
      id: 'blaze_sup_3', name: '麵包消除', description: '消除傷害 +8%',
      branch: TalentBranch.support, tier: 3,
      effectType: TalentEffectType.matchDamageUp, effectValue: 8,
      goldCost: 1000, materialCost: {GameMaterial.advancedShard: 3, GameMaterial.talentScroll: 1},
      prerequisiteNodeId: 'blaze_sup_2',
    ),
  ];

  // ─── 露露 Dew ───

  static const tideTalents = <TalentNodeDefinition>[
    // 攻擊分支
    TalentNodeDefinition(
      id: 'tide_atk_1', name: '果汁衝擊', description: 'ATK +5%',
      branch: TalentBranch.attack, tier: 1,
      effectType: TalentEffectType.atkPercent, effectValue: 5,
      goldCost: 200, materialCost: {GameMaterial.commonShard: 3},
    ),
    TalentNodeDefinition(
      id: 'tide_atk_2', name: '果汁之力', description: '消除傷害 +5%',
      branch: TalentBranch.attack, tier: 2,
      effectType: TalentEffectType.matchDamageUp, effectValue: 5,
      goldCost: 500, materialCost: {GameMaterial.commonShard: 5, GameMaterial.advancedShard: 2},
      prerequisiteNodeId: 'tide_atk_1',
    ),
    TalentNodeDefinition(
      id: 'tide_atk_3', name: '濃縮精華', description: '技能傷害 +8%',
      branch: TalentBranch.attack, tier: 3,
      effectType: TalentEffectType.skillDamageUp, effectValue: 8,
      goldCost: 1000, materialCost: {GameMaterial.advancedShard: 3, GameMaterial.talentScroll: 1},
      prerequisiteNodeId: 'tide_atk_2',
    ),
    // 防禦分支
    TalentNodeDefinition(
      id: 'tide_def_1', name: '果汁守護', description: 'HP +8%',
      branch: TalentBranch.defense, tier: 1,
      effectType: TalentEffectType.hpPercent, effectValue: 8,
      goldCost: 200, materialCost: {GameMaterial.commonShard: 3},
    ),
    TalentNodeDefinition(
      id: 'tide_def_2', name: '果皮護甲', description: 'DEF +5%',
      branch: TalentBranch.defense, tier: 2,
      effectType: TalentEffectType.defPercent, effectValue: 5,
      goldCost: 500, materialCost: {GameMaterial.commonShard: 5, GameMaterial.advancedShard: 2},
      prerequisiteNodeId: 'tide_def_1',
    ),
    TalentNodeDefinition(
      id: 'tide_def_3', name: '鮮果體魄', description: 'HP +10%',
      branch: TalentBranch.defense, tier: 3,
      effectType: TalentEffectType.hpPercent, effectValue: 10,
      goldCost: 1000, materialCost: {GameMaterial.advancedShard: 3, GameMaterial.talentScroll: 1},
      prerequisiteNodeId: 'tide_def_2',
    ),
    TalentNodeDefinition(
      id: 'tide_def_4', name: '果汁壁壘', description: '減傷 +8%',
      branch: TalentBranch.defense, tier: 4,
      effectType: TalentEffectType.dmgReduction, effectValue: 8,
      goldCost: 2000, materialCost: {GameMaterial.advancedShard: 5, GameMaterial.talentScroll: 2, GameMaterial.rareShard: 1},
      prerequisiteNodeId: 'tide_def_3',
    ),
    // 輔助分支
    TalentNodeDefinition(
      id: 'tide_sup_1', name: '調飲精通', description: '治療效果 +10%',
      branch: TalentBranch.support, tier: 1,
      effectType: TalentEffectType.healBoost, effectValue: 10,
      goldCost: 200, materialCost: {GameMaterial.commonShard: 3},
    ),
    TalentNodeDefinition(
      id: 'tide_sup_2', name: '能量果汁', description: '能量獲取 +15%',
      branch: TalentBranch.support, tier: 2,
      effectType: TalentEffectType.energyGainUp, effectValue: 15,
      goldCost: 500, materialCost: {GameMaterial.commonShard: 5, GameMaterial.advancedShard: 2},
      prerequisiteNodeId: 'tide_sup_1',
    ),
    TalentNodeDefinition(
      id: 'tide_sup_3', name: '活力泉源', description: '治療效果 +15%',
      branch: TalentBranch.support, tier: 3,
      effectType: TalentEffectType.healBoost, effectValue: 15,
      goldCost: 1000, materialCost: {GameMaterial.advancedShard: 3, GameMaterial.talentScroll: 1},
      prerequisiteNodeId: 'tide_sup_2',
    ),
  ];

  // ─── 抹抹 Matcha ───

  static const terraTalents = <TalentNodeDefinition>[
    // 攻擊分支
    TalentNodeDefinition(
      id: 'terra_atk_1', name: '抹茶拳擊', description: 'ATK +5%',
      branch: TalentBranch.attack, tier: 1,
      effectType: TalentEffectType.atkPercent, effectValue: 5,
      goldCost: 200, materialCost: {GameMaterial.commonShard: 3},
    ),
    TalentNodeDefinition(
      id: 'terra_atk_2', name: '抹茶衝擊', description: '消除傷害 +8%',
      branch: TalentBranch.attack, tier: 2,
      effectType: TalentEffectType.matchDamageUp, effectValue: 8,
      goldCost: 500, materialCost: {GameMaterial.commonShard: 5, GameMaterial.advancedShard: 2},
      prerequisiteNodeId: 'terra_atk_1',
    ),
    TalentNodeDefinition(
      id: 'terra_atk_3', name: '抹茶之力', description: 'ATK +10%',
      branch: TalentBranch.attack, tier: 3,
      effectType: TalentEffectType.atkPercent, effectValue: 10,
      goldCost: 1000, materialCost: {GameMaterial.advancedShard: 3, GameMaterial.talentScroll: 1},
      prerequisiteNodeId: 'terra_atk_2',
    ),
    // 防禦分支
    TalentNodeDefinition(
      id: 'terra_def_1', name: '濃厚防禦', description: 'DEF +8%',
      branch: TalentBranch.defense, tier: 1,
      effectType: TalentEffectType.defPercent, effectValue: 8,
      goldCost: 200, materialCost: {GameMaterial.commonShard: 3},
    ),
    TalentNodeDefinition(
      id: 'terra_def_2', name: '茶葉體魄', description: 'HP +10%',
      branch: TalentBranch.defense, tier: 2,
      effectType: TalentEffectType.hpPercent, effectValue: 10,
      goldCost: 500, materialCost: {GameMaterial.commonShard: 5, GameMaterial.advancedShard: 2},
      prerequisiteNodeId: 'terra_def_1',
    ),
    TalentNodeDefinition(
      id: 'terra_def_3', name: '抹茶護盾', description: '護盾效果 +15%',
      branch: TalentBranch.defense, tier: 3,
      effectType: TalentEffectType.shieldBoost, effectValue: 15,
      goldCost: 1000, materialCost: {GameMaterial.advancedShard: 3, GameMaterial.talentScroll: 1},
      prerequisiteNodeId: 'terra_def_2',
    ),
    TalentNodeDefinition(
      id: 'terra_def_4', name: '不動如茶', description: '減傷 +10%',
      branch: TalentBranch.defense, tier: 4,
      effectType: TalentEffectType.dmgReduction, effectValue: 10,
      goldCost: 2000, materialCost: {GameMaterial.advancedShard: 5, GameMaterial.talentScroll: 2, GameMaterial.rareShard: 1},
      prerequisiteNodeId: 'terra_def_3',
    ),
    // 輔助分支
    TalentNodeDefinition(
      id: 'terra_sup_1', name: '穩定茶香', description: '能量獲取 +10%',
      branch: TalentBranch.support, tier: 1,
      effectType: TalentEffectType.energyGainUp, effectValue: 10,
      goldCost: 200, materialCost: {GameMaterial.commonShard: 3},
    ),
    TalentNodeDefinition(
      id: 'terra_sup_2', name: '茶底穩固', description: 'HP +8%',
      branch: TalentBranch.support, tier: 2,
      effectType: TalentEffectType.hpPercent, effectValue: 8,
      goldCost: 500, materialCost: {GameMaterial.commonShard: 5, GameMaterial.advancedShard: 2},
      prerequisiteNodeId: 'terra_sup_1',
    ),
    TalentNodeDefinition(
      id: 'terra_sup_3', name: '茶道守護', description: 'DEF +5%',
      branch: TalentBranch.support, tier: 3,
      effectType: TalentEffectType.defPercent, effectValue: 5,
      goldCost: 1000, materialCost: {GameMaterial.advancedShard: 3, GameMaterial.talentScroll: 1},
      prerequisiteNodeId: 'terra_sup_2',
    ),
  ];

  // ─── 糖霜 Frosting ───

  static const flashTalents = <TalentNodeDefinition>[
    // 攻擊分支
    TalentNodeDefinition(
      id: 'flash_atk_1', name: '糖霜強化', description: 'ATK +8%',
      branch: TalentBranch.attack, tier: 1,
      effectType: TalentEffectType.atkPercent, effectValue: 8,
      goldCost: 200, materialCost: {GameMaterial.commonShard: 3},
    ),
    TalentNodeDefinition(
      id: 'flash_atk_2', name: '糖霜精通', description: '技能傷害 +10%',
      branch: TalentBranch.attack, tier: 2,
      effectType: TalentEffectType.skillDamageUp, effectValue: 10,
      goldCost: 500, materialCost: {GameMaterial.commonShard: 5, GameMaterial.advancedShard: 2},
      prerequisiteNodeId: 'flash_atk_1',
    ),
    TalentNodeDefinition(
      id: 'flash_atk_3', name: '糖霜閃耀', description: '暴擊率 +8%',
      branch: TalentBranch.attack, tier: 3,
      effectType: TalentEffectType.critChance, effectValue: 8,
      goldCost: 1000, materialCost: {GameMaterial.advancedShard: 3, GameMaterial.talentScroll: 1},
      prerequisiteNodeId: 'flash_atk_2',
    ),
    TalentNodeDefinition(
      id: 'flash_atk_4', name: '星星糖怒', description: '暴擊傷害 +20%',
      branch: TalentBranch.attack, tier: 4,
      effectType: TalentEffectType.critDamage, effectValue: 20,
      goldCost: 2000, materialCost: {GameMaterial.advancedShard: 5, GameMaterial.talentScroll: 2, GameMaterial.rareShard: 1},
      prerequisiteNodeId: 'flash_atk_3',
    ),
    // 防禦分支
    TalentNodeDefinition(
      id: 'flash_def_1', name: '糖粉護體', description: 'HP +5%',
      branch: TalentBranch.defense, tier: 1,
      effectType: TalentEffectType.hpPercent, effectValue: 5,
      goldCost: 200, materialCost: {GameMaterial.commonShard: 3},
    ),
    TalentNodeDefinition(
      id: 'flash_def_2', name: '糖衣護甲', description: 'DEF +5%',
      branch: TalentBranch.defense, tier: 2,
      effectType: TalentEffectType.defPercent, effectValue: 5,
      goldCost: 500, materialCost: {GameMaterial.commonShard: 5, GameMaterial.advancedShard: 2},
      prerequisiteNodeId: 'flash_def_1',
    ),
    TalentNodeDefinition(
      id: 'flash_def_3', name: '糖霜屏障', description: 'HP +8%',
      branch: TalentBranch.defense, tier: 3,
      effectType: TalentEffectType.hpPercent, effectValue: 8,
      goldCost: 1000, materialCost: {GameMaterial.advancedShard: 3, GameMaterial.talentScroll: 1},
      prerequisiteNodeId: 'flash_def_2',
    ),
    // 輔助分支
    TalentNodeDefinition(
      id: 'flash_sup_1', name: '裝飾感應', description: '連擊傷害 +10%',
      branch: TalentBranch.support, tier: 1,
      effectType: TalentEffectType.comboBonus, effectValue: 10,
      goldCost: 200, materialCost: {GameMaterial.commonShard: 3},
    ),
    TalentNodeDefinition(
      id: 'flash_sup_2', name: '糖霜積蓄', description: '能量獲取 +10%',
      branch: TalentBranch.support, tier: 2,
      effectType: TalentEffectType.energyGainUp, effectValue: 10,
      goldCost: 500, materialCost: {GameMaterial.commonShard: 5, GameMaterial.advancedShard: 2},
      prerequisiteNodeId: 'flash_sup_1',
    ),
    TalentNodeDefinition(
      id: 'flash_sup_3', name: '糖霜貫穿', description: '消除傷害 +10%',
      branch: TalentBranch.support, tier: 3,
      effectType: TalentEffectType.matchDamageUp, effectValue: 10,
      goldCost: 1000, materialCost: {GameMaterial.advancedShard: 3, GameMaterial.talentScroll: 1},
      prerequisiteNodeId: 'flash_sup_2',
    ),
  ];

  // ─── 可可 Cocoa ───

  static const shadowTalents = <TalentNodeDefinition>[
    // 攻擊分支
    TalentNodeDefinition(
      id: 'shadow_atk_1', name: '可可打擊', description: 'ATK +10%',
      branch: TalentBranch.attack, tier: 1,
      effectType: TalentEffectType.atkPercent, effectValue: 10,
      goldCost: 200, materialCost: {GameMaterial.commonShard: 3},
    ),
    TalentNodeDefinition(
      id: 'shadow_atk_2', name: '苦甜要害', description: '暴擊率 +10%',
      branch: TalentBranch.attack, tier: 2,
      effectType: TalentEffectType.critChance, effectValue: 10,
      goldCost: 500, materialCost: {GameMaterial.commonShard: 5, GameMaterial.advancedShard: 2},
      prerequisiteNodeId: 'shadow_atk_1',
    ),
    TalentNodeDefinition(
      id: 'shadow_atk_3', name: '深夜精通', description: '技能傷害 +15%',
      branch: TalentBranch.attack, tier: 3,
      effectType: TalentEffectType.skillDamageUp, effectValue: 15,
      goldCost: 1000, materialCost: {GameMaterial.advancedShard: 3, GameMaterial.talentScroll: 1},
      prerequisiteNodeId: 'shadow_atk_2',
    ),
    TalentNodeDefinition(
      id: 'shadow_atk_4', name: '極苦巧克力', description: '暴擊傷害 +25%',
      branch: TalentBranch.attack, tier: 4,
      effectType: TalentEffectType.critDamage, effectValue: 25,
      goldCost: 2000, materialCost: {GameMaterial.advancedShard: 5, GameMaterial.talentScroll: 2, GameMaterial.rareShard: 1},
      prerequisiteNodeId: 'shadow_atk_3',
    ),
    // 防禦分支
    TalentNodeDefinition(
      id: 'shadow_def_1', name: '可可閃避', description: 'HP +5%',
      branch: TalentBranch.defense, tier: 1,
      effectType: TalentEffectType.hpPercent, effectValue: 5,
      goldCost: 200, materialCost: {GameMaterial.commonShard: 3},
    ),
    TalentNodeDefinition(
      id: 'shadow_def_2', name: '深夜守護', description: 'DEF +5%',
      branch: TalentBranch.defense, tier: 2,
      effectType: TalentEffectType.defPercent, effectValue: 5,
      goldCost: 500, materialCost: {GameMaterial.commonShard: 5, GameMaterial.advancedShard: 2},
      prerequisiteNodeId: 'shadow_def_1',
    ),
    TalentNodeDefinition(
      id: 'shadow_def_3', name: '可可護體', description: '減傷 +5%',
      branch: TalentBranch.defense, tier: 3,
      effectType: TalentEffectType.dmgReduction, effectValue: 5,
      goldCost: 1000, materialCost: {GameMaterial.advancedShard: 3, GameMaterial.talentScroll: 1},
      prerequisiteNodeId: 'shadow_def_2',
    ),
    // 輔助分支
    TalentNodeDefinition(
      id: 'shadow_sup_1', name: '可可聚集', description: '能量獲取 +10%',
      branch: TalentBranch.support, tier: 1,
      effectType: TalentEffectType.energyGainUp, effectValue: 10,
      goldCost: 200, materialCost: {GameMaterial.commonShard: 3},
    ),
    TalentNodeDefinition(
      id: 'shadow_sup_2', name: '連續調製', description: '連擊傷害 +8%',
      branch: TalentBranch.support, tier: 2,
      effectType: TalentEffectType.comboBonus, effectValue: 8,
      goldCost: 500, materialCost: {GameMaterial.commonShard: 5, GameMaterial.advancedShard: 2},
      prerequisiteNodeId: 'shadow_sup_1',
    ),
    TalentNodeDefinition(
      id: 'shadow_sup_3', name: '可可消除', description: '消除傷害 +10%',
      branch: TalentBranch.support, tier: 3,
      effectType: TalentEffectType.matchDamageUp, effectValue: 10,
      goldCost: 1000, materialCost: {GameMaterial.advancedShard: 3, GameMaterial.talentScroll: 1},
      prerequisiteNodeId: 'shadow_sup_2',
    ),
  ];

  // ─── 窯窯 Kiln (destroyer, R) ───

  static const emberTalents = <TalentNodeDefinition>[
    // 攻擊分支
    TalentNodeDefinition(
      id: 'ember_atk_1', name: '窯火濺射', description: 'ATK +5%',
      branch: TalentBranch.attack, tier: 1,
      effectType: TalentEffectType.atkPercent, effectValue: 5,
      goldCost: 200, materialCost: {GameMaterial.commonShard: 3},
    ),
    TalentNodeDefinition(
      id: 'ember_atk_2', name: '窯烤擴散', description: '消除傷害 +8%',
      branch: TalentBranch.attack, tier: 2,
      effectType: TalentEffectType.matchDamageUp, effectValue: 8,
      goldCost: 500, materialCost: {GameMaterial.commonShard: 5, GameMaterial.advancedShard: 2},
      prerequisiteNodeId: 'ember_atk_1',
    ),
    TalentNodeDefinition(
      id: 'ember_atk_3', name: '窯烤殆盡', description: '技能傷害 +10%',
      branch: TalentBranch.attack, tier: 3,
      effectType: TalentEffectType.skillDamageUp, effectValue: 10,
      goldCost: 1000, materialCost: {GameMaterial.advancedShard: 3, GameMaterial.talentScroll: 1},
      prerequisiteNodeId: 'ember_atk_2',
    ),
    TalentNodeDefinition(
      id: 'ember_atk_4', name: '極致窯火', description: '暴擊傷害 +15%',
      branch: TalentBranch.attack, tier: 4,
      effectType: TalentEffectType.critDamage, effectValue: 15,
      goldCost: 2000, materialCost: {GameMaterial.advancedShard: 5, GameMaterial.talentScroll: 2, GameMaterial.rareShard: 1},
      prerequisiteNodeId: 'ember_atk_3',
    ),
    // 防禦分支
    TalentNodeDefinition(
      id: 'ember_def_1', name: '窯烤體魄', description: 'HP +5%',
      branch: TalentBranch.defense, tier: 1,
      effectType: TalentEffectType.hpPercent, effectValue: 5,
      goldCost: 200, materialCost: {GameMaterial.commonShard: 3},
    ),
    TalentNodeDefinition(
      id: 'ember_def_2', name: '窯壁屏障', description: 'DEF +5%',
      branch: TalentBranch.defense, tier: 2,
      effectType: TalentEffectType.defPercent, effectValue: 5,
      goldCost: 500, materialCost: {GameMaterial.commonShard: 5, GameMaterial.advancedShard: 2},
      prerequisiteNodeId: 'ember_def_1',
    ),
    TalentNodeDefinition(
      id: 'ember_def_3', name: '窯磚護甲', description: '減傷 +5%',
      branch: TalentBranch.defense, tier: 3,
      effectType: TalentEffectType.dmgReduction, effectValue: 5,
      goldCost: 1000, materialCost: {GameMaterial.advancedShard: 3, GameMaterial.talentScroll: 1},
      prerequisiteNodeId: 'ember_def_2',
    ),
    // 輔助分支
    TalentNodeDefinition(
      id: 'ember_sup_1', name: '窯火能量', description: '能量獲取 +10%',
      branch: TalentBranch.support, tier: 1,
      effectType: TalentEffectType.energyGainUp, effectValue: 10,
      goldCost: 200, materialCost: {GameMaterial.commonShard: 3},
    ),
    TalentNodeDefinition(
      id: 'ember_sup_2', name: '連鎖窯烤', description: '連擊傷害 +5%',
      branch: TalentBranch.support, tier: 2,
      effectType: TalentEffectType.comboBonus, effectValue: 5,
      goldCost: 500, materialCost: {GameMaterial.commonShard: 5, GameMaterial.advancedShard: 2},
      prerequisiteNodeId: 'ember_sup_1',
    ),
    TalentNodeDefinition(
      id: 'ember_sup_3', name: '窯烤消除', description: '消除傷害 +8%',
      branch: TalentBranch.support, tier: 3,
      effectType: TalentEffectType.matchDamageUp, effectValue: 8,
      goldCost: 1000, materialCost: {GameMaterial.advancedShard: 3, GameMaterial.talentScroll: 1},
      prerequisiteNodeId: 'ember_sup_2',
    ),
  ];

  // ─── 焦糖 Caramel (infiltrator, SR) ───

  static const infernoTalents = <TalentNodeDefinition>[
    // 攻擊分支
    TalentNodeDefinition(
      id: 'inferno_atk_1', name: '焦糖突襲', description: 'ATK +8%',
      branch: TalentBranch.attack, tier: 1,
      effectType: TalentEffectType.atkPercent, effectValue: 8,
      goldCost: 200, materialCost: {GameMaterial.commonShard: 3},
    ),
    TalentNodeDefinition(
      id: 'inferno_atk_2', name: '焦糖穿透', description: '暴擊率 +8%',
      branch: TalentBranch.attack, tier: 2,
      effectType: TalentEffectType.critChance, effectValue: 8,
      goldCost: 500, materialCost: {GameMaterial.commonShard: 5, GameMaterial.advancedShard: 2},
      prerequisiteNodeId: 'inferno_atk_1',
    ),
    TalentNodeDefinition(
      id: 'inferno_atk_3', name: '焦糖斬殺', description: '技能傷害 +12%',
      branch: TalentBranch.attack, tier: 3,
      effectType: TalentEffectType.skillDamageUp, effectValue: 12,
      goldCost: 1000, materialCost: {GameMaterial.advancedShard: 3, GameMaterial.talentScroll: 1},
      prerequisiteNodeId: 'inferno_atk_2',
    ),
    TalentNodeDefinition(
      id: 'inferno_atk_4', name: '極致焦糖', description: '暴擊傷害 +20%',
      branch: TalentBranch.attack, tier: 4,
      effectType: TalentEffectType.critDamage, effectValue: 20,
      goldCost: 2000, materialCost: {GameMaterial.advancedShard: 5, GameMaterial.talentScroll: 2, GameMaterial.rareShard: 1},
      prerequisiteNodeId: 'inferno_atk_3',
    ),
    // 防禦分支
    TalentNodeDefinition(
      id: 'inferno_def_1', name: '焦糖體魄', description: 'HP +5%',
      branch: TalentBranch.defense, tier: 1,
      effectType: TalentEffectType.hpPercent, effectValue: 5,
      goldCost: 200, materialCost: {GameMaterial.commonShard: 3},
    ),
    TalentNodeDefinition(
      id: 'inferno_def_2', name: '焦糖意志', description: 'DEF +5%',
      branch: TalentBranch.defense, tier: 2,
      effectType: TalentEffectType.defPercent, effectValue: 5,
      goldCost: 500, materialCost: {GameMaterial.commonShard: 5, GameMaterial.advancedShard: 2},
      prerequisiteNodeId: 'inferno_def_1',
    ),
    TalentNodeDefinition(
      id: 'inferno_def_3', name: '焦糖護體', description: '減傷 +5%',
      branch: TalentBranch.defense, tier: 3,
      effectType: TalentEffectType.dmgReduction, effectValue: 5,
      goldCost: 1000, materialCost: {GameMaterial.advancedShard: 3, GameMaterial.talentScroll: 1},
      prerequisiteNodeId: 'inferno_def_2',
    ),
    // 輔助分支
    TalentNodeDefinition(
      id: 'inferno_sup_1', name: '焦糖能量', description: '能量獲取 +10%',
      branch: TalentBranch.support, tier: 1,
      effectType: TalentEffectType.energyGainUp, effectValue: 10,
      goldCost: 200, materialCost: {GameMaterial.commonShard: 3},
    ),
    TalentNodeDefinition(
      id: 'inferno_sup_2', name: '焦糖消除', description: '消除傷害 +8%',
      branch: TalentBranch.support, tier: 2,
      effectType: TalentEffectType.matchDamageUp, effectValue: 8,
      goldCost: 500, materialCost: {GameMaterial.commonShard: 5, GameMaterial.advancedShard: 2},
      prerequisiteNodeId: 'inferno_sup_1',
    ),
    TalentNodeDefinition(
      id: 'inferno_sup_3', name: '焦糖連擊', description: '連擊傷害 +8%',
      branch: TalentBranch.support, tier: 3,
      effectType: TalentEffectType.comboBonus, effectValue: 8,
      goldCost: 1000, materialCost: {GameMaterial.advancedShard: 3, GameMaterial.talentScroll: 1},
      prerequisiteNodeId: 'inferno_sup_2',
    ),
  ];

  // ─── 薄荷 Mint (supporter, N) ───

  static const sproutTalents = <TalentNodeDefinition>[
    // 攻擊分支
    TalentNodeDefinition(
      id: 'sprout_atk_1', name: '薄荷抽打', description: 'ATK +5%',
      branch: TalentBranch.attack, tier: 1,
      effectType: TalentEffectType.atkPercent, effectValue: 5,
      goldCost: 200, materialCost: {GameMaterial.commonShard: 3},
    ),
    TalentNodeDefinition(
      id: 'sprout_atk_2', name: '薄荷纏繞', description: '消除傷害 +5%',
      branch: TalentBranch.attack, tier: 2,
      effectType: TalentEffectType.matchDamageUp, effectValue: 5,
      goldCost: 500, materialCost: {GameMaterial.commonShard: 5, GameMaterial.advancedShard: 2},
      prerequisiteNodeId: 'sprout_atk_1',
    ),
    TalentNodeDefinition(
      id: 'sprout_atk_3', name: '清涼之怒', description: '技能傷害 +8%',
      branch: TalentBranch.attack, tier: 3,
      effectType: TalentEffectType.skillDamageUp, effectValue: 8,
      goldCost: 1000, materialCost: {GameMaterial.advancedShard: 3, GameMaterial.talentScroll: 1},
      prerequisiteNodeId: 'sprout_atk_2',
    ),
    // 防禦分支
    TalentNodeDefinition(
      id: 'sprout_def_1', name: '薄荷護體', description: 'HP +8%',
      branch: TalentBranch.defense, tier: 1,
      effectType: TalentEffectType.hpPercent, effectValue: 8,
      goldCost: 200, materialCost: {GameMaterial.commonShard: 3},
    ),
    TalentNodeDefinition(
      id: 'sprout_def_2', name: '草本穩固', description: 'DEF +5%',
      branch: TalentBranch.defense, tier: 2,
      effectType: TalentEffectType.defPercent, effectValue: 5,
      goldCost: 500, materialCost: {GameMaterial.commonShard: 5, GameMaterial.advancedShard: 2},
      prerequisiteNodeId: 'sprout_def_1',
    ),
    TalentNodeDefinition(
      id: 'sprout_def_3', name: '薄荷之樹', description: 'HP +10%',
      branch: TalentBranch.defense, tier: 3,
      effectType: TalentEffectType.hpPercent, effectValue: 10,
      goldCost: 1000, materialCost: {GameMaterial.advancedShard: 3, GameMaterial.talentScroll: 1},
      prerequisiteNodeId: 'sprout_def_2',
    ),
    // 輔助分支
    TalentNodeDefinition(
      id: 'sprout_sup_1', name: '薄荷花粉', description: '治療效果 +10%',
      branch: TalentBranch.support, tier: 1,
      effectType: TalentEffectType.healBoost, effectValue: 10,
      goldCost: 200, materialCost: {GameMaterial.commonShard: 3},
    ),
    TalentNodeDefinition(
      id: 'sprout_sup_2', name: '清涼能量', description: '能量獲取 +15%',
      branch: TalentBranch.support, tier: 2,
      effectType: TalentEffectType.energyGainUp, effectValue: 15,
      goldCost: 500, materialCost: {GameMaterial.commonShard: 5, GameMaterial.advancedShard: 2},
      prerequisiteNodeId: 'sprout_sup_1',
    ),
    TalentNodeDefinition(
      id: 'sprout_sup_3', name: '香草恩賜', description: '治療效果 +15%',
      branch: TalentBranch.support, tier: 3,
      effectType: TalentEffectType.healBoost, effectValue: 15,
      goldCost: 1000, materialCost: {GameMaterial.advancedShard: 3, GameMaterial.talentScroll: 1},
      prerequisiteNodeId: 'sprout_sup_2',
    ),
  ];

  // ─── 肉桂 Cinnamon (striker, SR) ───

  static const gaiaTalents = <TalentNodeDefinition>[
    // 攻擊分支
    TalentNodeDefinition(
      id: 'gaia_atk_1', name: '肉桂衝擊', description: 'ATK +8%',
      branch: TalentBranch.attack, tier: 1,
      effectType: TalentEffectType.atkPercent, effectValue: 8,
      goldCost: 200, materialCost: {GameMaterial.commonShard: 3},
    ),
    TalentNodeDefinition(
      id: 'gaia_atk_2', name: '香料震裂', description: '技能傷害 +10%',
      branch: TalentBranch.attack, tier: 2,
      effectType: TalentEffectType.skillDamageUp, effectValue: 10,
      goldCost: 500, materialCost: {GameMaterial.commonShard: 5, GameMaterial.advancedShard: 2},
      prerequisiteNodeId: 'gaia_atk_1',
    ),
    TalentNodeDefinition(
      id: 'gaia_atk_3', name: '肉桂爆裂', description: '暴擊率 +8%',
      branch: TalentBranch.attack, tier: 3,
      effectType: TalentEffectType.critChance, effectValue: 8,
      goldCost: 1000, materialCost: {GameMaterial.advancedShard: 3, GameMaterial.talentScroll: 1},
      prerequisiteNodeId: 'gaia_atk_2',
    ),
    TalentNodeDefinition(
      id: 'gaia_atk_4', name: '極致肉桂', description: '暴擊傷害 +20%',
      branch: TalentBranch.attack, tier: 4,
      effectType: TalentEffectType.critDamage, effectValue: 20,
      goldCost: 2000, materialCost: {GameMaterial.advancedShard: 5, GameMaterial.talentScroll: 2, GameMaterial.rareShard: 1},
      prerequisiteNodeId: 'gaia_atk_3',
    ),
    // 防禦分支
    TalentNodeDefinition(
      id: 'gaia_def_1', name: '香料護衛', description: 'HP +5%',
      branch: TalentBranch.defense, tier: 1,
      effectType: TalentEffectType.hpPercent, effectValue: 5,
      goldCost: 200, materialCost: {GameMaterial.commonShard: 3},
    ),
    TalentNodeDefinition(
      id: 'gaia_def_2', name: '肉桂鎧甲', description: 'DEF +5%',
      branch: TalentBranch.defense, tier: 2,
      effectType: TalentEffectType.defPercent, effectValue: 5,
      goldCost: 500, materialCost: {GameMaterial.commonShard: 5, GameMaterial.advancedShard: 2},
      prerequisiteNodeId: 'gaia_def_1',
    ),
    TalentNodeDefinition(
      id: 'gaia_def_3', name: '香料之軀', description: '減傷 +5%',
      branch: TalentBranch.defense, tier: 3,
      effectType: TalentEffectType.dmgReduction, effectValue: 5,
      goldCost: 1000, materialCost: {GameMaterial.advancedShard: 3, GameMaterial.talentScroll: 1},
      prerequisiteNodeId: 'gaia_def_2',
    ),
    // 輔助分支
    TalentNodeDefinition(
      id: 'gaia_sup_1', name: '香料能量', description: '能量獲取 +10%',
      branch: TalentBranch.support, tier: 1,
      effectType: TalentEffectType.energyGainUp, effectValue: 10,
      goldCost: 200, materialCost: {GameMaterial.commonShard: 3},
    ),
    TalentNodeDefinition(
      id: 'gaia_sup_2', name: '肉桂連擊', description: '連擊傷害 +8%',
      branch: TalentBranch.support, tier: 2,
      effectType: TalentEffectType.comboBonus, effectValue: 8,
      goldCost: 500, materialCost: {GameMaterial.commonShard: 5, GameMaterial.advancedShard: 2},
      prerequisiteNodeId: 'gaia_sup_1',
    ),
    TalentNodeDefinition(
      id: 'gaia_sup_3', name: '肉桂消除', description: '消除傷害 +10%',
      branch: TalentBranch.support, tier: 3,
      effectType: TalentEffectType.matchDamageUp, effectValue: 10,
      goldCost: 1000, materialCost: {GameMaterial.advancedShard: 3, GameMaterial.talentScroll: 1},
      prerequisiteNodeId: 'gaia_sup_2',
    ),
  ];

  // ─── 奶昔 Shake (defender, R) ───

  static const frostTalents = <TalentNodeDefinition>[
    // 攻擊分支
    TalentNodeDefinition(
      id: 'frost_atk_1', name: '奶昔打擊', description: 'ATK +5%',
      branch: TalentBranch.attack, tier: 1,
      effectType: TalentEffectType.atkPercent, effectValue: 5,
      goldCost: 200, materialCost: {GameMaterial.commonShard: 3},
    ),
    TalentNodeDefinition(
      id: 'frost_atk_2', name: '冰涼侵蝕', description: '消除傷害 +5%',
      branch: TalentBranch.attack, tier: 2,
      effectType: TalentEffectType.matchDamageUp, effectValue: 5,
      goldCost: 500, materialCost: {GameMaterial.commonShard: 5, GameMaterial.advancedShard: 2},
      prerequisiteNodeId: 'frost_atk_1',
    ),
    TalentNodeDefinition(
      id: 'frost_atk_3', name: '冰沙衝擊', description: '技能傷害 +8%',
      branch: TalentBranch.attack, tier: 3,
      effectType: TalentEffectType.skillDamageUp, effectValue: 8,
      goldCost: 1000, materialCost: {GameMaterial.advancedShard: 3, GameMaterial.talentScroll: 1},
      prerequisiteNodeId: 'frost_atk_2',
    ),
    // 防禦分支
    TalentNodeDefinition(
      id: 'frost_def_1', name: '奶昔護甲', description: 'DEF +8%',
      branch: TalentBranch.defense, tier: 1,
      effectType: TalentEffectType.defPercent, effectValue: 8,
      goldCost: 200, materialCost: {GameMaterial.commonShard: 3},
    ),
    TalentNodeDefinition(
      id: 'frost_def_2', name: '奶昔體魄', description: 'HP +10%',
      branch: TalentBranch.defense, tier: 2,
      effectType: TalentEffectType.hpPercent, effectValue: 10,
      goldCost: 500, materialCost: {GameMaterial.commonShard: 5, GameMaterial.advancedShard: 2},
      prerequisiteNodeId: 'frost_def_1',
    ),
    TalentNodeDefinition(
      id: 'frost_def_3', name: '奶昔護盾', description: '護盾效果 +15%',
      branch: TalentBranch.defense, tier: 3,
      effectType: TalentEffectType.shieldBoost, effectValue: 15,
      goldCost: 1000, materialCost: {GameMaterial.advancedShard: 3, GameMaterial.talentScroll: 1},
      prerequisiteNodeId: 'frost_def_2',
    ),
    TalentNodeDefinition(
      id: 'frost_def_4', name: '冰淇淋壁壘', description: '減傷 +10%',
      branch: TalentBranch.defense, tier: 4,
      effectType: TalentEffectType.dmgReduction, effectValue: 10,
      goldCost: 2000, materialCost: {GameMaterial.advancedShard: 5, GameMaterial.talentScroll: 2, GameMaterial.rareShard: 1},
      prerequisiteNodeId: 'frost_def_3',
    ),
    // 輔助分支
    TalentNodeDefinition(
      id: 'frost_sup_1', name: '奶昔凝聚', description: '能量獲取 +10%',
      branch: TalentBranch.support, tier: 1,
      effectType: TalentEffectType.energyGainUp, effectValue: 10,
      goldCost: 200, materialCost: {GameMaterial.commonShard: 3},
    ),
    TalentNodeDefinition(
      id: 'frost_sup_2', name: '冰涼治癒', description: 'HP +8%',
      branch: TalentBranch.support, tier: 2,
      effectType: TalentEffectType.hpPercent, effectValue: 8,
      goldCost: 500, materialCost: {GameMaterial.commonShard: 5, GameMaterial.advancedShard: 2},
      prerequisiteNodeId: 'frost_sup_1',
    ),
    TalentNodeDefinition(
      id: 'frost_sup_3', name: '奶昔防禦', description: 'DEF +5%',
      branch: TalentBranch.support, tier: 3,
      effectType: TalentEffectType.defPercent, effectValue: 5,
      goldCost: 1000, materialCost: {GameMaterial.advancedShard: 3, GameMaterial.talentScroll: 1},
      prerequisiteNodeId: 'frost_sup_2',
    ),
  ];

  // ─── 蘇打 Soda (destroyer, SR) ───

  static const tsunamiTalents = <TalentNodeDefinition>[
    // 攻擊分支
    TalentNodeDefinition(
      id: 'tsunami_atk_1', name: '氣泡衝擊', description: 'ATK +8%',
      branch: TalentBranch.attack, tier: 1,
      effectType: TalentEffectType.atkPercent, effectValue: 8,
      goldCost: 200, materialCost: {GameMaterial.commonShard: 3},
    ),
    TalentNodeDefinition(
      id: 'tsunami_atk_2', name: '蘇打擴散', description: '消除傷害 +10%',
      branch: TalentBranch.attack, tier: 2,
      effectType: TalentEffectType.matchDamageUp, effectValue: 10,
      goldCost: 500, materialCost: {GameMaterial.commonShard: 5, GameMaterial.advancedShard: 2},
      prerequisiteNodeId: 'tsunami_atk_1',
    ),
    TalentNodeDefinition(
      id: 'tsunami_atk_3', name: '氣泡精通', description: '技能傷害 +12%',
      branch: TalentBranch.attack, tier: 3,
      effectType: TalentEffectType.skillDamageUp, effectValue: 12,
      goldCost: 1000, materialCost: {GameMaterial.advancedShard: 3, GameMaterial.talentScroll: 1},
      prerequisiteNodeId: 'tsunami_atk_2',
    ),
    TalentNodeDefinition(
      id: 'tsunami_atk_4', name: '極致蘇打', description: '暴擊傷害 +15%',
      branch: TalentBranch.attack, tier: 4,
      effectType: TalentEffectType.critDamage, effectValue: 15,
      goldCost: 2000, materialCost: {GameMaterial.advancedShard: 5, GameMaterial.talentScroll: 2, GameMaterial.rareShard: 1},
      prerequisiteNodeId: 'tsunami_atk_3',
    ),
    // 防禦分支
    TalentNodeDefinition(
      id: 'tsunami_def_1', name: '氣泡體魄', description: 'HP +5%',
      branch: TalentBranch.defense, tier: 1,
      effectType: TalentEffectType.hpPercent, effectValue: 5,
      goldCost: 200, materialCost: {GameMaterial.commonShard: 3},
    ),
    TalentNodeDefinition(
      id: 'tsunami_def_2', name: '蘇打護甲', description: 'DEF +5%',
      branch: TalentBranch.defense, tier: 2,
      effectType: TalentEffectType.defPercent, effectValue: 5,
      goldCost: 500, materialCost: {GameMaterial.commonShard: 5, GameMaterial.advancedShard: 2},
      prerequisiteNodeId: 'tsunami_def_1',
    ),
    TalentNodeDefinition(
      id: 'tsunami_def_3', name: '蘇打護體', description: '減傷 +5%',
      branch: TalentBranch.defense, tier: 3,
      effectType: TalentEffectType.dmgReduction, effectValue: 5,
      goldCost: 1000, materialCost: {GameMaterial.advancedShard: 3, GameMaterial.talentScroll: 1},
      prerequisiteNodeId: 'tsunami_def_2',
    ),
    // 輔助分支
    TalentNodeDefinition(
      id: 'tsunami_sup_1', name: '蘇打能量', description: '能量獲取 +10%',
      branch: TalentBranch.support, tier: 1,
      effectType: TalentEffectType.energyGainUp, effectValue: 10,
      goldCost: 200, materialCost: {GameMaterial.commonShard: 3},
    ),
    TalentNodeDefinition(
      id: 'tsunami_sup_2', name: '氣泡連擊', description: '連擊傷害 +8%',
      branch: TalentBranch.support, tier: 2,
      effectType: TalentEffectType.comboBonus, effectValue: 8,
      goldCost: 500, materialCost: {GameMaterial.commonShard: 5, GameMaterial.advancedShard: 2},
      prerequisiteNodeId: 'tsunami_sup_1',
    ),
    TalentNodeDefinition(
      id: 'tsunami_sup_3', name: '蘇打消除', description: '消除傷害 +8%',
      branch: TalentBranch.support, tier: 3,
      effectType: TalentEffectType.matchDamageUp, effectValue: 8,
      goldCost: 1000, materialCost: {GameMaterial.advancedShard: 3, GameMaterial.talentScroll: 1},
      prerequisiteNodeId: 'tsunami_sup_2',
    ),
  ];

  // ─── 棉花糖 Cotton (supporter, N) ───

  static const sparkTalents = <TalentNodeDefinition>[
    // 攻擊分支
    TalentNodeDefinition(
      id: 'spark_atk_1', name: '棉花糖釋放', description: 'ATK +5%',
      branch: TalentBranch.attack, tier: 1,
      effectType: TalentEffectType.atkPercent, effectValue: 5,
      goldCost: 200, materialCost: {GameMaterial.commonShard: 3},
    ),
    TalentNodeDefinition(
      id: 'spark_atk_2', name: '棉花糖打擊', description: '消除傷害 +5%',
      branch: TalentBranch.attack, tier: 2,
      effectType: TalentEffectType.matchDamageUp, effectValue: 5,
      goldCost: 500, materialCost: {GameMaterial.commonShard: 5, GameMaterial.advancedShard: 2},
      prerequisiteNodeId: 'spark_atk_1',
    ),
    TalentNodeDefinition(
      id: 'spark_atk_3', name: '棉花糖精通', description: '技能傷害 +8%',
      branch: TalentBranch.attack, tier: 3,
      effectType: TalentEffectType.skillDamageUp, effectValue: 8,
      goldCost: 1000, materialCost: {GameMaterial.advancedShard: 3, GameMaterial.talentScroll: 1},
      prerequisiteNodeId: 'spark_atk_2',
    ),
    // 防禦分支
    TalentNodeDefinition(
      id: 'spark_def_1', name: '棉花糖體質', description: 'HP +8%',
      branch: TalentBranch.defense, tier: 1,
      effectType: TalentEffectType.hpPercent, effectValue: 8,
      goldCost: 200, materialCost: {GameMaterial.commonShard: 3},
    ),
    TalentNodeDefinition(
      id: 'spark_def_2', name: '棉花糖護體', description: 'DEF +5%',
      branch: TalentBranch.defense, tier: 2,
      effectType: TalentEffectType.defPercent, effectValue: 5,
      goldCost: 500, materialCost: {GameMaterial.commonShard: 5, GameMaterial.advancedShard: 2},
      prerequisiteNodeId: 'spark_def_1',
    ),
    TalentNodeDefinition(
      id: 'spark_def_3', name: '甜蜜體魄', description: 'HP +10%',
      branch: TalentBranch.defense, tier: 3,
      effectType: TalentEffectType.hpPercent, effectValue: 10,
      goldCost: 1000, materialCost: {GameMaterial.advancedShard: 3, GameMaterial.talentScroll: 1},
      prerequisiteNodeId: 'spark_def_2',
    ),
    // 輔助分支
    TalentNodeDefinition(
      id: 'spark_sup_1', name: '甜蜜治癒', description: '治療效果 +10%',
      branch: TalentBranch.support, tier: 1,
      effectType: TalentEffectType.healBoost, effectValue: 10,
      goldCost: 200, materialCost: {GameMaterial.commonShard: 3},
    ),
    TalentNodeDefinition(
      id: 'spark_sup_2', name: '棉花糖充能', description: '能量獲取 +15%',
      branch: TalentBranch.support, tier: 2,
      effectType: TalentEffectType.energyGainUp, effectValue: 15,
      goldCost: 500, materialCost: {GameMaterial.commonShard: 5, GameMaterial.advancedShard: 2},
      prerequisiteNodeId: 'spark_sup_1',
    ),
    TalentNodeDefinition(
      id: 'spark_sup_3', name: '甜蜜恢復', description: '治療效果 +15%',
      branch: TalentBranch.support, tier: 3,
      effectType: TalentEffectType.healBoost, effectValue: 15,
      goldCost: 1000, materialCost: {GameMaterial.advancedShard: 3, GameMaterial.talentScroll: 1},
      prerequisiteNodeId: 'spark_sup_2',
    ),
  ];

  // ─── 可頌 Croissant (striker, SR) ───

  static const thunderTalents = <TalentNodeDefinition>[
    // 攻擊分支
    TalentNodeDefinition(
      id: 'thunder_atk_1', name: '可頌拳', description: 'ATK +8%',
      branch: TalentBranch.attack, tier: 1,
      effectType: TalentEffectType.atkPercent, effectValue: 8,
      goldCost: 200, materialCost: {GameMaterial.commonShard: 3},
    ),
    TalentNodeDefinition(
      id: 'thunder_atk_2', name: '酥皮精通', description: '技能傷害 +10%',
      branch: TalentBranch.attack, tier: 2,
      effectType: TalentEffectType.skillDamageUp, effectValue: 10,
      goldCost: 500, materialCost: {GameMaterial.commonShard: 5, GameMaterial.advancedShard: 2},
      prerequisiteNodeId: 'thunder_atk_1',
    ),
    TalentNodeDefinition(
      id: 'thunder_atk_3', name: '可頌暴擊', description: '暴擊率 +8%',
      branch: TalentBranch.attack, tier: 3,
      effectType: TalentEffectType.critChance, effectValue: 8,
      goldCost: 1000, materialCost: {GameMaterial.advancedShard: 3, GameMaterial.talentScroll: 1},
      prerequisiteNodeId: 'thunder_atk_2',
    ),
    TalentNodeDefinition(
      id: 'thunder_atk_4', name: '極致可頌', description: '暴擊傷害 +20%',
      branch: TalentBranch.attack, tier: 4,
      effectType: TalentEffectType.critDamage, effectValue: 20,
      goldCost: 2000, materialCost: {GameMaterial.advancedShard: 5, GameMaterial.talentScroll: 2, GameMaterial.rareShard: 1},
      prerequisiteNodeId: 'thunder_atk_3',
    ),
    // 防禦分支
    TalentNodeDefinition(
      id: 'thunder_def_1', name: '酥皮體質', description: 'HP +5%',
      branch: TalentBranch.defense, tier: 1,
      effectType: TalentEffectType.hpPercent, effectValue: 5,
      goldCost: 200, materialCost: {GameMaterial.commonShard: 3},
    ),
    TalentNodeDefinition(
      id: 'thunder_def_2', name: '可頌護甲', description: 'DEF +5%',
      branch: TalentBranch.defense, tier: 2,
      effectType: TalentEffectType.defPercent, effectValue: 5,
      goldCost: 500, materialCost: {GameMaterial.commonShard: 5, GameMaterial.advancedShard: 2},
      prerequisiteNodeId: 'thunder_def_1',
    ),
    TalentNodeDefinition(
      id: 'thunder_def_3', name: '酥皮抗性', description: '減傷 +5%',
      branch: TalentBranch.defense, tier: 3,
      effectType: TalentEffectType.dmgReduction, effectValue: 5,
      goldCost: 1000, materialCost: {GameMaterial.advancedShard: 3, GameMaterial.talentScroll: 1},
      prerequisiteNodeId: 'thunder_def_2',
    ),
    // 輔助分支
    TalentNodeDefinition(
      id: 'thunder_sup_1', name: '可頌能量', description: '能量獲取 +10%',
      branch: TalentBranch.support, tier: 1,
      effectType: TalentEffectType.energyGainUp, effectValue: 10,
      goldCost: 200, materialCost: {GameMaterial.commonShard: 3},
    ),
    TalentNodeDefinition(
      id: 'thunder_sup_2', name: '可頌連擊', description: '連擊傷害 +8%',
      branch: TalentBranch.support, tier: 2,
      effectType: TalentEffectType.comboBonus, effectValue: 8,
      goldCost: 500, materialCost: {GameMaterial.commonShard: 5, GameMaterial.advancedShard: 2},
      prerequisiteNodeId: 'thunder_sup_1',
    ),
    TalentNodeDefinition(
      id: 'thunder_sup_3', name: '可頌消除', description: '消除傷害 +10%',
      branch: TalentBranch.support, tier: 3,
      effectType: TalentEffectType.matchDamageUp, effectValue: 10,
      goldCost: 1000, materialCost: {GameMaterial.advancedShard: 3, GameMaterial.talentScroll: 1},
      prerequisiteNodeId: 'thunder_sup_2',
    ),
  ];

  // ─── 布丁 Pudding (defender, N) ───

  static const phantomTalents = <TalentNodeDefinition>[
    // 攻擊分支
    TalentNodeDefinition(
      id: 'phantom_atk_1', name: '布丁打擊', description: 'ATK +5%',
      branch: TalentBranch.attack, tier: 1,
      effectType: TalentEffectType.atkPercent, effectValue: 5,
      goldCost: 200, materialCost: {GameMaterial.commonShard: 3},
    ),
    TalentNodeDefinition(
      id: 'phantom_atk_2', name: '布丁侵蝕', description: '消除傷害 +5%',
      branch: TalentBranch.attack, tier: 2,
      effectType: TalentEffectType.matchDamageUp, effectValue: 5,
      goldCost: 500, materialCost: {GameMaterial.commonShard: 5, GameMaterial.advancedShard: 2},
      prerequisiteNodeId: 'phantom_atk_1',
    ),
    TalentNodeDefinition(
      id: 'phantom_atk_3', name: '布丁精通', description: '技能傷害 +8%',
      branch: TalentBranch.attack, tier: 3,
      effectType: TalentEffectType.skillDamageUp, effectValue: 8,
      goldCost: 1000, materialCost: {GameMaterial.advancedShard: 3, GameMaterial.talentScroll: 1},
      prerequisiteNodeId: 'phantom_atk_2',
    ),
    // 防禦分支
    TalentNodeDefinition(
      id: 'phantom_def_1', name: '布丁護甲', description: 'DEF +8%',
      branch: TalentBranch.defense, tier: 1,
      effectType: TalentEffectType.defPercent, effectValue: 8,
      goldCost: 200, materialCost: {GameMaterial.commonShard: 3},
    ),
    TalentNodeDefinition(
      id: 'phantom_def_2', name: '布丁體魄', description: 'HP +10%',
      branch: TalentBranch.defense, tier: 2,
      effectType: TalentEffectType.hpPercent, effectValue: 10,
      goldCost: 500, materialCost: {GameMaterial.commonShard: 5, GameMaterial.advancedShard: 2},
      prerequisiteNodeId: 'phantom_def_1',
    ),
    TalentNodeDefinition(
      id: 'phantom_def_3', name: '布丁護盾', description: '護盾效果 +15%',
      branch: TalentBranch.defense, tier: 3,
      effectType: TalentEffectType.shieldBoost, effectValue: 15,
      goldCost: 1000, materialCost: {GameMaterial.advancedShard: 3, GameMaterial.talentScroll: 1},
      prerequisiteNodeId: 'phantom_def_2',
    ),
    TalentNodeDefinition(
      id: 'phantom_def_4', name: '布丁壁壘', description: '減傷 +10%',
      branch: TalentBranch.defense, tier: 4,
      effectType: TalentEffectType.dmgReduction, effectValue: 10,
      goldCost: 2000, materialCost: {GameMaterial.advancedShard: 5, GameMaterial.talentScroll: 2, GameMaterial.rareShard: 1},
      prerequisiteNodeId: 'phantom_def_3',
    ),
    // 輔助分支
    TalentNodeDefinition(
      id: 'phantom_sup_1', name: '布丁能量', description: '能量獲取 +10%',
      branch: TalentBranch.support, tier: 1,
      effectType: TalentEffectType.energyGainUp, effectValue: 10,
      goldCost: 200, materialCost: {GameMaterial.commonShard: 3},
    ),
    TalentNodeDefinition(
      id: 'phantom_sup_2', name: '布丁回復', description: 'HP +8%',
      branch: TalentBranch.support, tier: 2,
      effectType: TalentEffectType.hpPercent, effectValue: 8,
      goldCost: 500, materialCost: {GameMaterial.commonShard: 5, GameMaterial.advancedShard: 2},
      prerequisiteNodeId: 'phantom_sup_1',
    ),
    TalentNodeDefinition(
      id: 'phantom_sup_3', name: '布丁守護', description: 'DEF +5%',
      branch: TalentBranch.support, tier: 3,
      effectType: TalentEffectType.defPercent, effectValue: 5,
      goldCost: 1000, materialCost: {GameMaterial.advancedShard: 3, GameMaterial.talentScroll: 1},
      prerequisiteNodeId: 'phantom_sup_2',
    ),
  ];

  // ─── 藍莓 Berry (destroyer, R) ───

  static const eclipseTalents = <TalentNodeDefinition>[
    // 攻擊分支
    TalentNodeDefinition(
      id: 'eclipse_atk_1', name: '莓果打擊', description: 'ATK +5%',
      branch: TalentBranch.attack, tier: 1,
      effectType: TalentEffectType.atkPercent, effectValue: 5,
      goldCost: 200, materialCost: {GameMaterial.commonShard: 3},
    ),
    TalentNodeDefinition(
      id: 'eclipse_atk_2', name: '莓果擴散', description: '消除傷害 +8%',
      branch: TalentBranch.attack, tier: 2,
      effectType: TalentEffectType.matchDamageUp, effectValue: 8,
      goldCost: 500, materialCost: {GameMaterial.commonShard: 5, GameMaterial.advancedShard: 2},
      prerequisiteNodeId: 'eclipse_atk_1',
    ),
    TalentNodeDefinition(
      id: 'eclipse_atk_3', name: '莓果精通', description: '技能傷害 +10%',
      branch: TalentBranch.attack, tier: 3,
      effectType: TalentEffectType.skillDamageUp, effectValue: 10,
      goldCost: 1000, materialCost: {GameMaterial.advancedShard: 3, GameMaterial.talentScroll: 1},
      prerequisiteNodeId: 'eclipse_atk_2',
    ),
    TalentNodeDefinition(
      id: 'eclipse_atk_4', name: '極致莓果', description: '暴擊傷害 +15%',
      branch: TalentBranch.attack, tier: 4,
      effectType: TalentEffectType.critDamage, effectValue: 15,
      goldCost: 2000, materialCost: {GameMaterial.advancedShard: 5, GameMaterial.talentScroll: 2, GameMaterial.rareShard: 1},
      prerequisiteNodeId: 'eclipse_atk_3',
    ),
    // 防禦分支
    TalentNodeDefinition(
      id: 'eclipse_def_1', name: '莓果體魄', description: 'HP +5%',
      branch: TalentBranch.defense, tier: 1,
      effectType: TalentEffectType.hpPercent, effectValue: 5,
      goldCost: 200, materialCost: {GameMaterial.commonShard: 3},
    ),
    TalentNodeDefinition(
      id: 'eclipse_def_2', name: '莓果護甲', description: 'DEF +5%',
      branch: TalentBranch.defense, tier: 2,
      effectType: TalentEffectType.defPercent, effectValue: 5,
      goldCost: 500, materialCost: {GameMaterial.commonShard: 5, GameMaterial.advancedShard: 2},
      prerequisiteNodeId: 'eclipse_def_1',
    ),
    TalentNodeDefinition(
      id: 'eclipse_def_3', name: '莓果護體', description: '減傷 +5%',
      branch: TalentBranch.defense, tier: 3,
      effectType: TalentEffectType.dmgReduction, effectValue: 5,
      goldCost: 1000, materialCost: {GameMaterial.advancedShard: 3, GameMaterial.talentScroll: 1},
      prerequisiteNodeId: 'eclipse_def_2',
    ),
    // 輔助分支
    TalentNodeDefinition(
      id: 'eclipse_sup_1', name: '莓果能量', description: '能量獲取 +10%',
      branch: TalentBranch.support, tier: 1,
      effectType: TalentEffectType.energyGainUp, effectValue: 10,
      goldCost: 200, materialCost: {GameMaterial.commonShard: 3},
    ),
    TalentNodeDefinition(
      id: 'eclipse_sup_2', name: '莓果連擊', description: '連擊傷害 +5%',
      branch: TalentBranch.support, tier: 2,
      effectType: TalentEffectType.comboBonus, effectValue: 5,
      goldCost: 500, materialCost: {GameMaterial.commonShard: 5, GameMaterial.advancedShard: 2},
      prerequisiteNodeId: 'eclipse_sup_1',
    ),
    TalentNodeDefinition(
      id: 'eclipse_sup_3', name: '莓果消除', description: '消除傷害 +8%',
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
