/// 被動技能靜態數據
/// 15 隻貓各有 4 個被動技能
import '../core/models/material.dart';
import '../core/models/passive_skill.dart';

class PassiveSkillData {
  PassiveSkillData._();

  // ─── 小麥 Wheat ───

  static const blazePassives = <PassiveSkillDefinition>[
    PassiveSkillDefinition(
      id: 'blaze_p1', agentId: 'blaze',
      name: '麵粉之心', description: '消除☀️方塊時，能量獲取 +20%',
      effectType: PassiveEffectType.energyBonus, effectValue: 0.2,
      goldCost: 300, materialCost: {GameMaterial.commonShard: 3, GameMaterial.passiveGem: 1},
      unlockAtAgentLevel: 5,
    ),
    PassiveSkillDefinition(
      id: 'blaze_p2', agentId: 'blaze',
      name: '連續揉麵', description: '達成 3+ 連擊後，下次技能傷害 +25%',
      effectType: PassiveEffectType.comboSkillBonus, effectValue: 0.25,
      goldCost: 600, materialCost: {GameMaterial.advancedShard: 2, GameMaterial.passiveGem: 1},
      unlockAtAgentLevel: 10,
    ),
    PassiveSkillDefinition(
      id: 'blaze_p3', agentId: 'blaze',
      name: '烘焙直覺', description: '所有攻擊暴擊率 +15%',
      effectType: PassiveEffectType.critChance, effectValue: 0.15,
      goldCost: 1000, materialCost: {GameMaterial.advancedShard: 3, GameMaterial.passiveGem: 2},
      unlockAtAgentLevel: 15,
    ),
    PassiveSkillDefinition(
      id: 'blaze_p4', agentId: 'blaze',
      name: '窯火重燃', description: '隊伍 HP 低於 25% 時，ATK +30%',
      effectType: PassiveEffectType.lowHpBoost, effectValue: 0.3,
      goldCost: 1500, materialCost: {GameMaterial.rareShard: 2, GameMaterial.passiveGem: 3},
      unlockAtAgentLevel: 20,
    ),
  ];

  // ─── 露露 Dew ───

  static const tidePassives = <PassiveSkillDefinition>[
    PassiveSkillDefinition(
      id: 'tide_p1', agentId: 'tide',
      name: '果汁節奏', description: '每回合開始時，回復隊伍 3% HP',
      effectType: PassiveEffectType.turnStartHeal, effectValue: 0.03,
      goldCost: 300, materialCost: {GameMaterial.commonShard: 3, GameMaterial.passiveGem: 1},
      unlockAtAgentLevel: 5,
    ),
    PassiveSkillDefinition(
      id: 'tide_p2', agentId: 'tide',
      name: '果汁守護', description: '使用技能後，獲得 15% 護盾 1 回合',
      effectType: PassiveEffectType.shieldOnSkill, effectValue: 0.15,
      goldCost: 600, materialCost: {GameMaterial.advancedShard: 2, GameMaterial.passiveGem: 1},
      unlockAtAgentLevel: 10,
    ),
    PassiveSkillDefinition(
      id: 'tide_p3', agentId: 'tide',
      name: '急救果汁', description: 'HP 低於 40% 時，自動回復 8% HP（每場限 1 次）',
      effectType: PassiveEffectType.lowHpBoost, effectValue: 0.08,
      goldCost: 1000, materialCost: {GameMaterial.advancedShard: 3, GameMaterial.passiveGem: 2},
      unlockAtAgentLevel: 15,
    ),
    PassiveSkillDefinition(
      id: 'tide_p4', agentId: 'tide',
      name: '活力泉源', description: '消除💧方塊時，回復隊伍 2% HP',
      effectType: PassiveEffectType.healOnMatch, effectValue: 0.02,
      goldCost: 1500, materialCost: {GameMaterial.rareShard: 2, GameMaterial.passiveGem: 3},
      unlockAtAgentLevel: 20,
    ),
  ];

  // ─── 抹抹 Matcha ───

  static const terraPassives = <PassiveSkillDefinition>[
    PassiveSkillDefinition(
      id: 'terra_p1', agentId: 'terra',
      name: '抹茶意志', description: '受到的傷害減少 8%',
      effectType: PassiveEffectType.dmgReduction, effectValue: 0.08,
      goldCost: 400, materialCost: {GameMaterial.commonShard: 4, GameMaterial.passiveGem: 1},
      unlockAtAgentLevel: 5,
    ),
    PassiveSkillDefinition(
      id: 'terra_p2', agentId: 'terra',
      name: '抹茶反擊', description: '受擊時 20% 機率反擊，造成 50% ATK 傷害',
      effectType: PassiveEffectType.counterAttack, effectValue: 0.2,
      goldCost: 800, materialCost: {GameMaterial.advancedShard: 2, GameMaterial.passiveGem: 1},
      unlockAtAgentLevel: 12,
    ),
    PassiveSkillDefinition(
      id: 'terra_p3', agentId: 'terra',
      name: '抹茶守護', description: '護盾效果 +20%',
      effectType: PassiveEffectType.shieldOnSkill, effectValue: 0.2,
      goldCost: 1200, materialCost: {GameMaterial.advancedShard: 3, GameMaterial.passiveGem: 2},
      unlockAtAgentLevel: 18,
    ),
    PassiveSkillDefinition(
      id: 'terra_p4', agentId: 'terra',
      name: '抹茶之力', description: '隊伍受傷時，獲得 1 點能量',
      effectType: PassiveEffectType.energyOnDamaged, effectValue: 1,
      goldCost: 2000, materialCost: {GameMaterial.rareShard: 2, GameMaterial.passiveGem: 3},
      unlockAtAgentLevel: 25,
    ),
  ];

  // ─── 糖霜 Frosting ───

  static const flashPassives = <PassiveSkillDefinition>[
    PassiveSkillDefinition(
      id: 'flash_p1', agentId: 'flash',
      name: '糖粉場', description: '達成 5+ 連擊時，技能傷害 +15%',
      effectType: PassiveEffectType.comboSkillBonus, effectValue: 0.15,
      goldCost: 400, materialCost: {GameMaterial.commonShard: 4, GameMaterial.passiveGem: 1},
      unlockAtAgentLevel: 5,
    ),
    PassiveSkillDefinition(
      id: 'flash_p2', agentId: 'flash',
      name: '連鎖糖霜', description: '單次消除 5+ 方塊時，該次傷害 +30%',
      effectType: PassiveEffectType.matchChainBonus, effectValue: 0.3,
      goldCost: 800, materialCost: {GameMaterial.advancedShard: 2, GameMaterial.passiveGem: 1},
      unlockAtAgentLevel: 12,
    ),
    PassiveSkillDefinition(
      id: 'flash_p3', agentId: 'flash',
      name: '糖霜過量', description: '擊殺敵人時獲得 2 點能量',
      effectType: PassiveEffectType.onKillEffect, effectValue: 2,
      goldCost: 1200, materialCost: {GameMaterial.advancedShard: 3, GameMaterial.passiveGem: 2},
      unlockAtAgentLevel: 18,
    ),
    PassiveSkillDefinition(
      id: 'flash_p4', agentId: 'flash',
      name: '星星糖怒', description: '場上有 2+ 敵人時，ATK +20%',
      effectType: PassiveEffectType.lowHpBoost, effectValue: 0.2,
      goldCost: 2000, materialCost: {GameMaterial.rareShard: 2, GameMaterial.passiveGem: 3},
      unlockAtAgentLevel: 25,
    ),
  ];

  // ─── 可可 Cocoa ───

  static const shadowPassives = <PassiveSkillDefinition>[
    PassiveSkillDefinition(
      id: 'shadow_p1', agentId: 'shadow',
      name: '深夜潛行', description: '戰鬥中首次攻擊傷害 ×1.5',
      effectType: PassiveEffectType.firstStrikeBonus, effectValue: 1.5,
      goldCost: 400, materialCost: {GameMaterial.commonShard: 4, GameMaterial.passiveGem: 1},
      unlockAtAgentLevel: 5,
    ),
    PassiveSkillDefinition(
      id: 'shadow_p2', agentId: 'shadow',
      name: '苦甜弱點', description: '斬殺門檻提升 +10%（30% → 40%）',
      effectType: PassiveEffectType.executeThresholdUp, effectValue: 0.1,
      goldCost: 800, materialCost: {GameMaterial.advancedShard: 2, GameMaterial.passiveGem: 1},
      unlockAtAgentLevel: 12,
    ),
    PassiveSkillDefinition(
      id: 'shadow_p3', agentId: 'shadow',
      name: '可可回饋', description: '擊殺敵人時，退還 30% 能量',
      effectType: PassiveEffectType.onKillEffect, effectValue: 0.3,
      goldCost: 1200, materialCost: {GameMaterial.advancedShard: 3, GameMaterial.passiveGem: 2},
      unlockAtAgentLevel: 18,
    ),
    PassiveSkillDefinition(
      id: 'shadow_p4', agentId: 'shadow',
      name: '深夜可可', description: '攻擊 HP 低於 50% 的敵人時，傷害 +20%',
      effectType: PassiveEffectType.lowEnemyHpBonus, effectValue: 0.2,
      goldCost: 2000, materialCost: {GameMaterial.rareShard: 2, GameMaterial.passiveGem: 3},
      unlockAtAgentLevel: 25,
    ),
  ];

  // ─── 窯窯 Kiln (☀️ destroyer, R) ───

  static const emberPassives = <PassiveSkillDefinition>[
    PassiveSkillDefinition(
      id: 'ember_p1', agentId: 'ember',
      name: '窯烤連鎖', description: '單次消除 5+ 方塊時，該次傷害 +20%',
      effectType: PassiveEffectType.matchChainBonus, effectValue: 0.2,
      goldCost: 300, materialCost: {GameMaterial.commonShard: 3, GameMaterial.passiveGem: 1},
      unlockAtAgentLevel: 5,
    ),
    PassiveSkillDefinition(
      id: 'ember_p2', agentId: 'ember',
      name: '烤盡殘敵', description: '擊殺敵人時獲得 2 點能量',
      effectType: PassiveEffectType.onKillEffect, effectValue: 2,
      goldCost: 600, materialCost: {GameMaterial.advancedShard: 2, GameMaterial.passiveGem: 1},
      unlockAtAgentLevel: 10,
    ),
    PassiveSkillDefinition(
      id: 'ember_p3', agentId: 'ember',
      name: '窯火連擊', description: '達成 3+ 連擊後，下次技能傷害 +20%',
      effectType: PassiveEffectType.comboSkillBonus, effectValue: 0.2,
      goldCost: 1000, materialCost: {GameMaterial.advancedShard: 3, GameMaterial.passiveGem: 2},
      unlockAtAgentLevel: 15,
    ),
    PassiveSkillDefinition(
      id: 'ember_p4', agentId: 'ember',
      name: '焦香審判', description: '攻擊 HP 低於 50% 的敵人時，傷害 +25%',
      effectType: PassiveEffectType.lowEnemyHpBonus, effectValue: 0.25,
      goldCost: 1500, materialCost: {GameMaterial.rareShard: 2, GameMaterial.passiveGem: 3},
      unlockAtAgentLevel: 20,
    ),
  ];

  // ─── 焦糖 Caramel (☀️ infiltrator, SR) ───

  static const infernoPassives = <PassiveSkillDefinition>[
    PassiveSkillDefinition(
      id: 'inferno_p1', agentId: 'inferno',
      name: '搶先外送', description: '戰鬥中首次攻擊傷害 ×1.4',
      effectType: PassiveEffectType.firstStrikeBonus, effectValue: 1.4,
      goldCost: 400, materialCost: {GameMaterial.commonShard: 4, GameMaterial.passiveGem: 1},
      unlockAtAgentLevel: 5,
    ),
    PassiveSkillDefinition(
      id: 'inferno_p2', agentId: 'inferno',
      name: '焦糖弱點', description: '斬殺門檻提升 +8%',
      effectType: PassiveEffectType.executeThresholdUp, effectValue: 0.08,
      goldCost: 800, materialCost: {GameMaterial.advancedShard: 2, GameMaterial.passiveGem: 1},
      unlockAtAgentLevel: 12,
    ),
    PassiveSkillDefinition(
      id: 'inferno_p3', agentId: 'inferno',
      name: '焦糖收割', description: '擊殺敵人時，退還 25% 能量',
      effectType: PassiveEffectType.onKillEffect, effectValue: 0.25,
      goldCost: 1200, materialCost: {GameMaterial.advancedShard: 3, GameMaterial.passiveGem: 2},
      unlockAtAgentLevel: 18,
    ),
    PassiveSkillDefinition(
      id: 'inferno_p4', agentId: 'inferno',
      name: '焦糖暴擊', description: '所有攻擊暴擊率 +18%',
      effectType: PassiveEffectType.critChance, effectValue: 0.18,
      goldCost: 2000, materialCost: {GameMaterial.rareShard: 2, GameMaterial.passiveGem: 3},
      unlockAtAgentLevel: 25,
    ),
  ];

  // ─── 薄荷 Mint (🍃 supporter, N) ───

  static const sproutPassives = <PassiveSkillDefinition>[
    PassiveSkillDefinition(
      id: 'sprout_p1', agentId: 'sprout',
      name: '薄荷祝福', description: '每回合開始時，回復隊伍 2% HP',
      effectType: PassiveEffectType.turnStartHeal, effectValue: 0.02,
      goldCost: 300, materialCost: {GameMaterial.commonShard: 3, GameMaterial.passiveGem: 1},
      unlockAtAgentLevel: 5,
    ),
    PassiveSkillDefinition(
      id: 'sprout_p2', agentId: 'sprout',
      name: '清新治療', description: '消除🍃方塊時，回復隊伍 2% HP',
      effectType: PassiveEffectType.healOnMatch, effectValue: 0.02,
      goldCost: 600, materialCost: {GameMaterial.advancedShard: 2, GameMaterial.passiveGem: 1},
      unlockAtAgentLevel: 10,
    ),
    PassiveSkillDefinition(
      id: 'sprout_p3', agentId: 'sprout',
      name: '薄荷護罩', description: '使用技能後，獲得 12% 護盾 1 回合',
      effectType: PassiveEffectType.shieldOnSkill, effectValue: 0.12,
      goldCost: 1000, materialCost: {GameMaterial.advancedShard: 3, GameMaterial.passiveGem: 2},
      unlockAtAgentLevel: 15,
    ),
    PassiveSkillDefinition(
      id: 'sprout_p4', agentId: 'sprout',
      name: '香草共鳴', description: '消除方塊時，能量獲取 +15%',
      effectType: PassiveEffectType.energyBonus, effectValue: 0.15,
      goldCost: 1500, materialCost: {GameMaterial.rareShard: 2, GameMaterial.passiveGem: 3},
      unlockAtAgentLevel: 20,
    ),
  ];

  // ─── 肉桂 Cinnamon (🍃 striker, SR) ───

  static const gaiaPassives = <PassiveSkillDefinition>[
    PassiveSkillDefinition(
      id: 'gaia_p1', agentId: 'gaia',
      name: '肉桂暴擊', description: '所有攻擊暴擊率 +12%',
      effectType: PassiveEffectType.critChance, effectValue: 0.12,
      goldCost: 400, materialCost: {GameMaterial.commonShard: 4, GameMaterial.passiveGem: 1},
      unlockAtAgentLevel: 5,
    ),
    PassiveSkillDefinition(
      id: 'gaia_p2', agentId: 'gaia',
      name: '香料之力', description: '隊伍 HP 低於 30% 時，ATK +25%',
      effectType: PassiveEffectType.lowHpBoost, effectValue: 0.25,
      goldCost: 800, materialCost: {GameMaterial.advancedShard: 2, GameMaterial.passiveGem: 1},
      unlockAtAgentLevel: 12,
    ),
    PassiveSkillDefinition(
      id: 'gaia_p3', agentId: 'gaia',
      name: '先手一擊', description: '戰鬥中首次攻擊傷害 ×1.3',
      effectType: PassiveEffectType.firstStrikeBonus, effectValue: 1.3,
      goldCost: 1200, materialCost: {GameMaterial.advancedShard: 3, GameMaterial.passiveGem: 2},
      unlockAtAgentLevel: 18,
    ),
    PassiveSkillDefinition(
      id: 'gaia_p4', agentId: 'gaia',
      name: '肉桂連擊', description: '達成 3+ 連擊後，下次技能傷害 +30%',
      effectType: PassiveEffectType.comboSkillBonus, effectValue: 0.3,
      goldCost: 2000, materialCost: {GameMaterial.rareShard: 2, GameMaterial.passiveGem: 3},
      unlockAtAgentLevel: 25,
    ),
  ];

  // ─── 奶昔 Shake (💧 defender, R) ───

  static const frostPassives = <PassiveSkillDefinition>[
    PassiveSkillDefinition(
      id: 'frost_p1', agentId: 'frost',
      name: '奶昔護體', description: '受到的傷害減少 6%',
      effectType: PassiveEffectType.dmgReduction, effectValue: 0.06,
      goldCost: 300, materialCost: {GameMaterial.commonShard: 3, GameMaterial.passiveGem: 1},
      unlockAtAgentLevel: 5,
    ),
    PassiveSkillDefinition(
      id: 'frost_p2', agentId: 'frost',
      name: '奶昔反擊', description: '受擊時 15% 機率反擊，造成 50% ATK 傷害',
      effectType: PassiveEffectType.counterAttack, effectValue: 0.15,
      goldCost: 600, materialCost: {GameMaterial.advancedShard: 2, GameMaterial.passiveGem: 1},
      unlockAtAgentLevel: 10,
    ),
    PassiveSkillDefinition(
      id: 'frost_p3', agentId: 'frost',
      name: '冰淇淋護盾', description: '使用技能後，獲得 15% 護盾 1 回合',
      effectType: PassiveEffectType.shieldOnSkill, effectValue: 0.15,
      goldCost: 1000, materialCost: {GameMaterial.advancedShard: 3, GameMaterial.passiveGem: 2},
      unlockAtAgentLevel: 15,
    ),
    PassiveSkillDefinition(
      id: 'frost_p4', agentId: 'frost',
      name: '奶昔吸能', description: '隊伍受傷時，獲得 1 點能量',
      effectType: PassiveEffectType.energyOnDamaged, effectValue: 1,
      goldCost: 1500, materialCost: {GameMaterial.rareShard: 2, GameMaterial.passiveGem: 3},
      unlockAtAgentLevel: 20,
    ),
  ];

  // ─── 蘇打 Soda (💧 destroyer, SR) ───

  static const tsunamiPassives = <PassiveSkillDefinition>[
    PassiveSkillDefinition(
      id: 'tsunami_p1', agentId: 'tsunami',
      name: '氣泡連鎖', description: '單次消除 5+ 方塊時，該次傷害 +25%',
      effectType: PassiveEffectType.matchChainBonus, effectValue: 0.25,
      goldCost: 400, materialCost: {GameMaterial.commonShard: 4, GameMaterial.passiveGem: 1},
      unlockAtAgentLevel: 5,
    ),
    PassiveSkillDefinition(
      id: 'tsunami_p2', agentId: 'tsunami',
      name: '蘇打滅敵', description: '擊殺敵人時獲得 3 點能量',
      effectType: PassiveEffectType.onKillEffect, effectValue: 3,
      goldCost: 800, materialCost: {GameMaterial.advancedShard: 2, GameMaterial.passiveGem: 1},
      unlockAtAgentLevel: 12,
    ),
    PassiveSkillDefinition(
      id: 'tsunami_p3', agentId: 'tsunami',
      name: '氣泡連擊', description: '達成 3+ 連擊後，下次技能傷害 +25%',
      effectType: PassiveEffectType.comboSkillBonus, effectValue: 0.25,
      goldCost: 1200, materialCost: {GameMaterial.advancedShard: 3, GameMaterial.passiveGem: 2},
      unlockAtAgentLevel: 18,
    ),
    PassiveSkillDefinition(
      id: 'tsunami_p4', agentId: 'tsunami',
      name: '蘇打之災', description: '攻擊 HP 低於 50% 的敵人時，傷害 +30%',
      effectType: PassiveEffectType.lowEnemyHpBonus, effectValue: 0.3,
      goldCost: 2000, materialCost: {GameMaterial.rareShard: 2, GameMaterial.passiveGem: 3},
      unlockAtAgentLevel: 25,
    ),
  ];

  // ─── 棉花糖 Cotton (⭐ supporter, N) ───

  static const sparkPassives = <PassiveSkillDefinition>[
    PassiveSkillDefinition(
      id: 'spark_p1', agentId: 'spark',
      name: '棉花糖治療', description: '每回合開始時，回復隊伍 2% HP',
      effectType: PassiveEffectType.turnStartHeal, effectValue: 0.02,
      goldCost: 300, materialCost: {GameMaterial.commonShard: 3, GameMaterial.passiveGem: 1},
      unlockAtAgentLevel: 5,
    ),
    PassiveSkillDefinition(
      id: 'spark_p2', agentId: 'spark',
      name: '棉花糖回復', description: '消除⭐方塊時，回復隊伍 2% HP',
      effectType: PassiveEffectType.healOnMatch, effectValue: 0.02,
      goldCost: 600, materialCost: {GameMaterial.advancedShard: 2, GameMaterial.passiveGem: 1},
      unlockAtAgentLevel: 10,
    ),
    PassiveSkillDefinition(
      id: 'spark_p3', agentId: 'spark',
      name: '棉花糖護盾', description: '使用技能後，獲得 12% 護盾 1 回合',
      effectType: PassiveEffectType.shieldOnSkill, effectValue: 0.12,
      goldCost: 1000, materialCost: {GameMaterial.advancedShard: 3, GameMaterial.passiveGem: 2},
      unlockAtAgentLevel: 15,
    ),
    PassiveSkillDefinition(
      id: 'spark_p4', agentId: 'spark',
      name: '甜蜜共鳴', description: '消除方塊時，能量獲取 +15%',
      effectType: PassiveEffectType.energyBonus, effectValue: 0.15,
      goldCost: 1500, materialCost: {GameMaterial.rareShard: 2, GameMaterial.passiveGem: 3},
      unlockAtAgentLevel: 20,
    ),
  ];

  // ─── 可頌 Croissant (⭐ striker, SR) ───

  static const thunderPassives = <PassiveSkillDefinition>[
    PassiveSkillDefinition(
      id: 'thunder_p1', agentId: 'thunder',
      name: '可頌暴擊', description: '所有攻擊暴擊率 +12%',
      effectType: PassiveEffectType.critChance, effectValue: 0.12,
      goldCost: 400, materialCost: {GameMaterial.commonShard: 4, GameMaterial.passiveGem: 1},
      unlockAtAgentLevel: 5,
    ),
    PassiveSkillDefinition(
      id: 'thunder_p2', agentId: 'thunder',
      name: '酥皮之怒', description: '隊伍 HP 低於 30% 時，ATK +25%',
      effectType: PassiveEffectType.lowHpBoost, effectValue: 0.25,
      goldCost: 800, materialCost: {GameMaterial.advancedShard: 2, GameMaterial.passiveGem: 1},
      unlockAtAgentLevel: 12,
    ),
    PassiveSkillDefinition(
      id: 'thunder_p3', agentId: 'thunder',
      name: '可頌先手', description: '戰鬥中首次攻擊傷害 ×1.3',
      effectType: PassiveEffectType.firstStrikeBonus, effectValue: 1.3,
      goldCost: 1200, materialCost: {GameMaterial.advancedShard: 3, GameMaterial.passiveGem: 2},
      unlockAtAgentLevel: 18,
    ),
    PassiveSkillDefinition(
      id: 'thunder_p4', agentId: 'thunder',
      name: '可頌齊發', description: '達成 3+ 連擊後，下次技能傷害 +30%',
      effectType: PassiveEffectType.comboSkillBonus, effectValue: 0.3,
      goldCost: 2000, materialCost: {GameMaterial.rareShard: 2, GameMaterial.passiveGem: 3},
      unlockAtAgentLevel: 25,
    ),
  ];

  // ─── 布丁 Pudding (🌙 defender, N) ───

  static const phantomPassives = <PassiveSkillDefinition>[
    PassiveSkillDefinition(
      id: 'phantom_p1', agentId: 'phantom',
      name: '布丁護甲', description: '受到的傷害減少 5%',
      effectType: PassiveEffectType.dmgReduction, effectValue: 0.05,
      goldCost: 300, materialCost: {GameMaterial.commonShard: 3, GameMaterial.passiveGem: 1},
      unlockAtAgentLevel: 5,
    ),
    PassiveSkillDefinition(
      id: 'phantom_p2', agentId: 'phantom',
      name: '布丁反擊', description: '受擊時 15% 機率反擊，造成 50% ATK 傷害',
      effectType: PassiveEffectType.counterAttack, effectValue: 0.15,
      goldCost: 600, materialCost: {GameMaterial.advancedShard: 2, GameMaterial.passiveGem: 1},
      unlockAtAgentLevel: 10,
    ),
    PassiveSkillDefinition(
      id: 'phantom_p3', agentId: 'phantom',
      name: '布丁護盾', description: '使用技能後，獲得 12% 護盾 1 回合',
      effectType: PassiveEffectType.shieldOnSkill, effectValue: 0.12,
      goldCost: 1000, materialCost: {GameMaterial.advancedShard: 3, GameMaterial.passiveGem: 2},
      unlockAtAgentLevel: 15,
    ),
    PassiveSkillDefinition(
      id: 'phantom_p4', agentId: 'phantom',
      name: '布丁吸能', description: '隊伍受傷時，獲得 1 點能量',
      effectType: PassiveEffectType.energyOnDamaged, effectValue: 1,
      goldCost: 1500, materialCost: {GameMaterial.rareShard: 2, GameMaterial.passiveGem: 3},
      unlockAtAgentLevel: 20,
    ),
  ];

  // ─── 藍莓 Berry (🌙 destroyer, R) ───

  static const eclipsePassives = <PassiveSkillDefinition>[
    PassiveSkillDefinition(
      id: 'eclipse_p1', agentId: 'eclipse',
      name: '莓果連鎖', description: '單次消除 5+ 方塊時，該次傷害 +20%',
      effectType: PassiveEffectType.matchChainBonus, effectValue: 0.2,
      goldCost: 300, materialCost: {GameMaterial.commonShard: 3, GameMaterial.passiveGem: 1},
      unlockAtAgentLevel: 5,
    ),
    PassiveSkillDefinition(
      id: 'eclipse_p2', agentId: 'eclipse',
      name: '莓果收割', description: '擊殺敵人時獲得 2 點能量',
      effectType: PassiveEffectType.onKillEffect, effectValue: 2,
      goldCost: 600, materialCost: {GameMaterial.advancedShard: 2, GameMaterial.passiveGem: 1},
      unlockAtAgentLevel: 10,
    ),
    PassiveSkillDefinition(
      id: 'eclipse_p3', agentId: 'eclipse',
      name: '莓果連擊', description: '達成 3+ 連擊後，下次技能傷害 +20%',
      effectType: PassiveEffectType.comboSkillBonus, effectValue: 0.2,
      goldCost: 1000, materialCost: {GameMaterial.advancedShard: 3, GameMaterial.passiveGem: 2},
      unlockAtAgentLevel: 15,
    ),
    PassiveSkillDefinition(
      id: 'eclipse_p4', agentId: 'eclipse',
      name: '莓果終結', description: '攻擊 HP 低於 50% 的敵人時，傷害 +25%',
      effectType: PassiveEffectType.lowEnemyHpBonus, effectValue: 0.25,
      goldCost: 1500, materialCost: {GameMaterial.rareShard: 2, GameMaterial.passiveGem: 3},
      unlockAtAgentLevel: 20,
    ),
  ];

  // ─── 查詢方法 ───

  static const Map<String, List<PassiveSkillDefinition>> _agentPassives = {
    'blaze': blazePassives,
    'tide': tidePassives,
    'terra': terraPassives,
    'flash': flashPassives,
    'shadow': shadowPassives,
    'ember': emberPassives,
    'inferno': infernoPassives,
    'sprout': sproutPassives,
    'gaia': gaiaPassives,
    'frost': frostPassives,
    'tsunami': tsunamiPassives,
    'spark': sparkPassives,
    'thunder': thunderPassives,
    'phantom': phantomPassives,
    'eclipse': eclipsePassives,
  };

  static List<PassiveSkillDefinition> getPassivesForAgent(String agentId) {
    return _agentPassives[agentId] ?? [];
  }

  static PassiveSkillDefinition? getPassiveById(String passiveId) {
    for (final passives in _agentPassives.values) {
      for (final p in passives) {
        if (p.id == passiveId) return p;
      }
    }
    return null;
  }
}
