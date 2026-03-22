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
      goldCost: 200, materialCost: {MaterialType.commonShard: 3},
    ),
    TalentNodeDefinition(
      id: 'blaze_atk_2', name: '烈焰之力', description: 'ATK +8%',
      branch: TalentBranch.attack, tier: 2,
      effectType: TalentEffectType.atkPercent, effectValue: 8,
      goldCost: 500, materialCost: {MaterialType.commonShard: 5, MaterialType.advancedShard: 2},
      prerequisiteNodeId: 'blaze_atk_1',
    ),
    TalentNodeDefinition(
      id: 'blaze_atk_3', name: '技能精通', description: '技能傷害 +10%',
      branch: TalentBranch.attack, tier: 3,
      effectType: TalentEffectType.skillDamageUp, effectValue: 10,
      goldCost: 1000, materialCost: {MaterialType.advancedShard: 3, MaterialType.talentScroll: 1},
      prerequisiteNodeId: 'blaze_atk_2',
    ),
    TalentNodeDefinition(
      id: 'blaze_atk_4', name: '致命一擊', description: '暴擊傷害 +15%',
      branch: TalentBranch.attack, tier: 4,
      effectType: TalentEffectType.critDamage, effectValue: 15,
      goldCost: 2000, materialCost: {MaterialType.advancedShard: 5, MaterialType.talentScroll: 2, MaterialType.rareShard: 1},
      prerequisiteNodeId: 'blaze_atk_3',
    ),
    // 防禦分支
    TalentNodeDefinition(
      id: 'blaze_def_1', name: '堅韌體魄', description: 'HP +5%',
      branch: TalentBranch.defense, tier: 1,
      effectType: TalentEffectType.hpPercent, effectValue: 5,
      goldCost: 200, materialCost: {MaterialType.commonShard: 3},
    ),
    TalentNodeDefinition(
      id: 'blaze_def_2', name: '生命強化', description: 'HP +8%',
      branch: TalentBranch.defense, tier: 2,
      effectType: TalentEffectType.hpPercent, effectValue: 8,
      goldCost: 500, materialCost: {MaterialType.commonShard: 5, MaterialType.advancedShard: 2},
      prerequisiteNodeId: 'blaze_def_1',
    ),
    TalentNodeDefinition(
      id: 'blaze_def_3', name: '火焰護甲', description: '減傷 +5%',
      branch: TalentBranch.defense, tier: 3,
      effectType: TalentEffectType.dmgReduction, effectValue: 5,
      goldCost: 1000, materialCost: {MaterialType.advancedShard: 3, MaterialType.talentScroll: 1},
      prerequisiteNodeId: 'blaze_def_2',
    ),
    // 輔助分支
    TalentNodeDefinition(
      id: 'blaze_sup_1', name: '能量導引', description: '能量獲取 +10%',
      branch: TalentBranch.support, tier: 1,
      effectType: TalentEffectType.energyGainUp, effectValue: 10,
      goldCost: 200, materialCost: {MaterialType.commonShard: 3},
    ),
    TalentNodeDefinition(
      id: 'blaze_sup_2', name: '連擊本能', description: '連擊傷害 +5%',
      branch: TalentBranch.support, tier: 2,
      effectType: TalentEffectType.comboBonus, effectValue: 5,
      goldCost: 500, materialCost: {MaterialType.commonShard: 5, MaterialType.advancedShard: 2},
      prerequisiteNodeId: 'blaze_sup_1',
    ),
    TalentNodeDefinition(
      id: 'blaze_sup_3', name: '消除強化', description: '消除傷害 +8%',
      branch: TalentBranch.support, tier: 3,
      effectType: TalentEffectType.matchDamageUp, effectValue: 8,
      goldCost: 1000, materialCost: {MaterialType.advancedShard: 3, MaterialType.talentScroll: 1},
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
      goldCost: 200, materialCost: {MaterialType.commonShard: 3},
    ),
    TalentNodeDefinition(
      id: 'tide_atk_2', name: '潮汐之力', description: '消除傷害 +5%',
      branch: TalentBranch.attack, tier: 2,
      effectType: TalentEffectType.matchDamageUp, effectValue: 5,
      goldCost: 500, materialCost: {MaterialType.commonShard: 5, MaterialType.advancedShard: 2},
      prerequisiteNodeId: 'tide_atk_1',
    ),
    TalentNodeDefinition(
      id: 'tide_atk_3', name: '水壓集中', description: '技能傷害 +8%',
      branch: TalentBranch.attack, tier: 3,
      effectType: TalentEffectType.skillDamageUp, effectValue: 8,
      goldCost: 1000, materialCost: {MaterialType.advancedShard: 3, MaterialType.talentScroll: 1},
      prerequisiteNodeId: 'tide_atk_2',
    ),
    // 防禦分支
    TalentNodeDefinition(
      id: 'tide_def_1', name: '水之守護', description: 'HP +8%',
      branch: TalentBranch.defense, tier: 1,
      effectType: TalentEffectType.hpPercent, effectValue: 8,
      goldCost: 200, materialCost: {MaterialType.commonShard: 3},
    ),
    TalentNodeDefinition(
      id: 'tide_def_2', name: '波浪護甲', description: 'DEF +5%',
      branch: TalentBranch.defense, tier: 2,
      effectType: TalentEffectType.defPercent, effectValue: 5,
      goldCost: 500, materialCost: {MaterialType.commonShard: 5, MaterialType.advancedShard: 2},
      prerequisiteNodeId: 'tide_def_1',
    ),
    TalentNodeDefinition(
      id: 'tide_def_3', name: '深海體魄', description: 'HP +10%',
      branch: TalentBranch.defense, tier: 3,
      effectType: TalentEffectType.hpPercent, effectValue: 10,
      goldCost: 1000, materialCost: {MaterialType.advancedShard: 3, MaterialType.talentScroll: 1},
      prerequisiteNodeId: 'tide_def_2',
    ),
    TalentNodeDefinition(
      id: 'tide_def_4', name: '海洋壁壘', description: '減傷 +8%',
      branch: TalentBranch.defense, tier: 4,
      effectType: TalentEffectType.dmgReduction, effectValue: 8,
      goldCost: 2000, materialCost: {MaterialType.advancedShard: 5, MaterialType.talentScroll: 2, MaterialType.rareShard: 1},
      prerequisiteNodeId: 'tide_def_3',
    ),
    // 輔助分支
    TalentNodeDefinition(
      id: 'tide_sup_1', name: '治療精通', description: '治療效果 +10%',
      branch: TalentBranch.support, tier: 1,
      effectType: TalentEffectType.healBoost, effectValue: 10,
      goldCost: 200, materialCost: {MaterialType.commonShard: 3},
    ),
    TalentNodeDefinition(
      id: 'tide_sup_2', name: '能量潮汐', description: '能量獲取 +15%',
      branch: TalentBranch.support, tier: 2,
      effectType: TalentEffectType.energyGainUp, effectValue: 15,
      goldCost: 500, materialCost: {MaterialType.commonShard: 5, MaterialType.advancedShard: 2},
      prerequisiteNodeId: 'tide_sup_1',
    ),
    TalentNodeDefinition(
      id: 'tide_sup_3', name: '生命泉源', description: '治療效果 +15%',
      branch: TalentBranch.support, tier: 3,
      effectType: TalentEffectType.healBoost, effectValue: 15,
      goldCost: 1000, materialCost: {MaterialType.advancedShard: 3, MaterialType.talentScroll: 1},
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
      goldCost: 200, materialCost: {MaterialType.commonShard: 3},
    ),
    TalentNodeDefinition(
      id: 'terra_atk_2', name: '地裂衝擊', description: '消除傷害 +8%',
      branch: TalentBranch.attack, tier: 2,
      effectType: TalentEffectType.matchDamageUp, effectValue: 8,
      goldCost: 500, materialCost: {MaterialType.commonShard: 5, MaterialType.advancedShard: 2},
      prerequisiteNodeId: 'terra_atk_1',
    ),
    TalentNodeDefinition(
      id: 'terra_atk_3', name: '大地之力', description: 'ATK +10%',
      branch: TalentBranch.attack, tier: 3,
      effectType: TalentEffectType.atkPercent, effectValue: 10,
      goldCost: 1000, materialCost: {MaterialType.advancedShard: 3, MaterialType.talentScroll: 1},
      prerequisiteNodeId: 'terra_atk_2',
    ),
    // 防禦分支
    TalentNodeDefinition(
      id: 'terra_def_1', name: '鋼鐵防禦', description: 'DEF +8%',
      branch: TalentBranch.defense, tier: 1,
      effectType: TalentEffectType.defPercent, effectValue: 8,
      goldCost: 200, materialCost: {MaterialType.commonShard: 3},
    ),
    TalentNodeDefinition(
      id: 'terra_def_2', name: '厚重體魄', description: 'HP +10%',
      branch: TalentBranch.defense, tier: 2,
      effectType: TalentEffectType.hpPercent, effectValue: 10,
      goldCost: 500, materialCost: {MaterialType.commonShard: 5, MaterialType.advancedShard: 2},
      prerequisiteNodeId: 'terra_def_1',
    ),
    TalentNodeDefinition(
      id: 'terra_def_3', name: '護盾強化', description: '護盾效果 +15%',
      branch: TalentBranch.defense, tier: 3,
      effectType: TalentEffectType.shieldBoost, effectValue: 15,
      goldCost: 1000, materialCost: {MaterialType.advancedShard: 3, MaterialType.talentScroll: 1},
      prerequisiteNodeId: 'terra_def_2',
    ),
    TalentNodeDefinition(
      id: 'terra_def_4', name: '不動如山', description: '減傷 +10%',
      branch: TalentBranch.defense, tier: 4,
      effectType: TalentEffectType.dmgReduction, effectValue: 10,
      goldCost: 2000, materialCost: {MaterialType.advancedShard: 5, MaterialType.talentScroll: 2, MaterialType.rareShard: 1},
      prerequisiteNodeId: 'terra_def_3',
    ),
    // 輔助分支
    TalentNodeDefinition(
      id: 'terra_sup_1', name: '穩定能量', description: '能量獲取 +10%',
      branch: TalentBranch.support, tier: 1,
      effectType: TalentEffectType.energyGainUp, effectValue: 10,
      goldCost: 200, materialCost: {MaterialType.commonShard: 3},
    ),
    TalentNodeDefinition(
      id: 'terra_sup_2', name: '根基穩固', description: 'HP +8%',
      branch: TalentBranch.support, tier: 2,
      effectType: TalentEffectType.hpPercent, effectValue: 8,
      goldCost: 500, materialCost: {MaterialType.commonShard: 5, MaterialType.advancedShard: 2},
      prerequisiteNodeId: 'terra_sup_1',
    ),
    TalentNodeDefinition(
      id: 'terra_sup_3', name: '堅守陣地', description: 'DEF +5%',
      branch: TalentBranch.support, tier: 3,
      effectType: TalentEffectType.defPercent, effectValue: 5,
      goldCost: 1000, materialCost: {MaterialType.advancedShard: 3, MaterialType.talentScroll: 1},
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
      goldCost: 200, materialCost: {MaterialType.commonShard: 3},
    ),
    TalentNodeDefinition(
      id: 'flash_atk_2', name: '雷霆精通', description: '技能傷害 +10%',
      branch: TalentBranch.attack, tier: 2,
      effectType: TalentEffectType.skillDamageUp, effectValue: 10,
      goldCost: 500, materialCost: {MaterialType.commonShard: 5, MaterialType.advancedShard: 2},
      prerequisiteNodeId: 'flash_atk_1',
    ),
    TalentNodeDefinition(
      id: 'flash_atk_3', name: '電光石火', description: '暴擊率 +8%',
      branch: TalentBranch.attack, tier: 3,
      effectType: TalentEffectType.critChance, effectValue: 8,
      goldCost: 1000, materialCost: {MaterialType.advancedShard: 3, MaterialType.talentScroll: 1},
      prerequisiteNodeId: 'flash_atk_2',
    ),
    TalentNodeDefinition(
      id: 'flash_atk_4', name: '雷神之怒', description: '暴擊傷害 +20%',
      branch: TalentBranch.attack, tier: 4,
      effectType: TalentEffectType.critDamage, effectValue: 20,
      goldCost: 2000, materialCost: {MaterialType.advancedShard: 5, MaterialType.talentScroll: 2, MaterialType.rareShard: 1},
      prerequisiteNodeId: 'flash_atk_3',
    ),
    // 防禦分支
    TalentNodeDefinition(
      id: 'flash_def_1', name: '靜電場護體', description: 'HP +5%',
      branch: TalentBranch.defense, tier: 1,
      effectType: TalentEffectType.hpPercent, effectValue: 5,
      goldCost: 200, materialCost: {MaterialType.commonShard: 3},
    ),
    TalentNodeDefinition(
      id: 'flash_def_2', name: '電磁護甲', description: 'DEF +5%',
      branch: TalentBranch.defense, tier: 2,
      effectType: TalentEffectType.defPercent, effectValue: 5,
      goldCost: 500, materialCost: {MaterialType.commonShard: 5, MaterialType.advancedShard: 2},
      prerequisiteNodeId: 'flash_def_1',
    ),
    TalentNodeDefinition(
      id: 'flash_def_3', name: '電流屏障', description: 'HP +8%',
      branch: TalentBranch.defense, tier: 3,
      effectType: TalentEffectType.hpPercent, effectValue: 8,
      goldCost: 1000, materialCost: {MaterialType.advancedShard: 3, MaterialType.talentScroll: 1},
      prerequisiteNodeId: 'flash_def_2',
    ),
    // 輔助分支
    TalentNodeDefinition(
      id: 'flash_sup_1', name: '連擊感應', description: '連擊傷害 +10%',
      branch: TalentBranch.support, tier: 1,
      effectType: TalentEffectType.comboBonus, effectValue: 10,
      goldCost: 200, materialCost: {MaterialType.commonShard: 3},
    ),
    TalentNodeDefinition(
      id: 'flash_sup_2', name: '電能積蓄', description: '能量獲取 +10%',
      branch: TalentBranch.support, tier: 2,
      effectType: TalentEffectType.energyGainUp, effectValue: 10,
      goldCost: 500, materialCost: {MaterialType.commonShard: 5, MaterialType.advancedShard: 2},
      prerequisiteNodeId: 'flash_sup_1',
    ),
    TalentNodeDefinition(
      id: 'flash_sup_3', name: '電流貫穿', description: '消除傷害 +10%',
      branch: TalentBranch.support, tier: 3,
      effectType: TalentEffectType.matchDamageUp, effectValue: 10,
      goldCost: 1000, materialCost: {MaterialType.advancedShard: 3, MaterialType.talentScroll: 1},
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
      goldCost: 200, materialCost: {MaterialType.commonShard: 3},
    ),
    TalentNodeDefinition(
      id: 'shadow_atk_2', name: '致命要害', description: '暴擊率 +10%',
      branch: TalentBranch.attack, tier: 2,
      effectType: TalentEffectType.critChance, effectValue: 10,
      goldCost: 500, materialCost: {MaterialType.commonShard: 5, MaterialType.advancedShard: 2},
      prerequisiteNodeId: 'shadow_atk_1',
    ),
    TalentNodeDefinition(
      id: 'shadow_atk_3', name: '暗殺精通', description: '技能傷害 +15%',
      branch: TalentBranch.attack, tier: 3,
      effectType: TalentEffectType.skillDamageUp, effectValue: 15,
      goldCost: 1000, materialCost: {MaterialType.advancedShard: 3, MaterialType.talentScroll: 1},
      prerequisiteNodeId: 'shadow_atk_2',
    ),
    TalentNodeDefinition(
      id: 'shadow_atk_4', name: '死神之刃', description: '暴擊傷害 +25%',
      branch: TalentBranch.attack, tier: 4,
      effectType: TalentEffectType.critDamage, effectValue: 25,
      goldCost: 2000, materialCost: {MaterialType.advancedShard: 5, MaterialType.talentScroll: 2, MaterialType.rareShard: 1},
      prerequisiteNodeId: 'shadow_atk_3',
    ),
    // 防禦分支
    TalentNodeDefinition(
      id: 'shadow_def_1', name: '暗影閃避', description: 'HP +5%',
      branch: TalentBranch.defense, tier: 1,
      effectType: TalentEffectType.hpPercent, effectValue: 5,
      goldCost: 200, materialCost: {MaterialType.commonShard: 3},
    ),
    TalentNodeDefinition(
      id: 'shadow_def_2', name: '夜行者', description: 'DEF +5%',
      branch: TalentBranch.defense, tier: 2,
      effectType: TalentEffectType.defPercent, effectValue: 5,
      goldCost: 500, materialCost: {MaterialType.commonShard: 5, MaterialType.advancedShard: 2},
      prerequisiteNodeId: 'shadow_def_1',
    ),
    TalentNodeDefinition(
      id: 'shadow_def_3', name: '暗影護體', description: '減傷 +5%',
      branch: TalentBranch.defense, tier: 3,
      effectType: TalentEffectType.dmgReduction, effectValue: 5,
      goldCost: 1000, materialCost: {MaterialType.advancedShard: 3, MaterialType.talentScroll: 1},
      prerequisiteNodeId: 'shadow_def_2',
    ),
    // 輔助分支
    TalentNodeDefinition(
      id: 'shadow_sup_1', name: '暗能聚集', description: '能量獲取 +10%',
      branch: TalentBranch.support, tier: 1,
      effectType: TalentEffectType.energyGainUp, effectValue: 10,
      goldCost: 200, materialCost: {MaterialType.commonShard: 3},
    ),
    TalentNodeDefinition(
      id: 'shadow_sup_2', name: '連擊暗殺', description: '連擊傷害 +8%',
      branch: TalentBranch.support, tier: 2,
      effectType: TalentEffectType.comboBonus, effectValue: 8,
      goldCost: 500, materialCost: {MaterialType.commonShard: 5, MaterialType.advancedShard: 2},
      prerequisiteNodeId: 'shadow_sup_1',
    ),
    TalentNodeDefinition(
      id: 'shadow_sup_3', name: '暗影消除', description: '消除傷害 +10%',
      branch: TalentBranch.support, tier: 3,
      effectType: TalentEffectType.matchDamageUp, effectValue: 10,
      goldCost: 1000, materialCost: {MaterialType.advancedShard: 3, MaterialType.talentScroll: 1},
      prerequisiteNodeId: 'shadow_sup_2',
    ),
  ];

  // ─── 查詢方法 ───

  static const Map<String, List<TalentNodeDefinition>> _agentTalents = {
    'blaze': blazeTalents,
    'tide': tideTalents,
    'terra': terraTalents,
    'flash': flashTalents,
    'shadow': shadowTalents,
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
