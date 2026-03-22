/// 被動技能靜態數據
/// 5 隻貓各有 4 個被動技能
import '../core/models/material.dart';
import '../core/models/passive_skill.dart';

class PassiveSkillData {
  PassiveSkillData._();

  // ─── 阿焰 Blaze ───

  static const blazePassives = <PassiveSkillDefinition>[
    PassiveSkillDefinition(
      id: 'blaze_p1', agentId: 'blaze',
      name: '烈焰之心', description: '消除紅色方塊時，能量獲取 +20%',
      effectType: PassiveEffectType.energyBonus, effectValue: 0.2,
      goldCost: 300, materialCost: {GameMaterial.commonShard: 3, GameMaterial.passiveGem: 1},
      unlockAtAgentLevel: 5,
    ),
    PassiveSkillDefinition(
      id: 'blaze_p2', agentId: 'blaze',
      name: '連擊狂熱', description: '達成 3+ 連擊後，下次技能傷害 +25%',
      effectType: PassiveEffectType.comboSkillBonus, effectValue: 0.25,
      goldCost: 600, materialCost: {GameMaterial.advancedShard: 2, GameMaterial.passiveGem: 1},
      unlockAtAgentLevel: 10,
    ),
    PassiveSkillDefinition(
      id: 'blaze_p3', agentId: 'blaze',
      name: '致命本能', description: '所有攻擊暴擊率 +15%',
      effectType: PassiveEffectType.critChance, effectValue: 0.15,
      goldCost: 1000, materialCost: {GameMaterial.advancedShard: 3, GameMaterial.passiveGem: 2},
      unlockAtAgentLevel: 15,
    ),
    PassiveSkillDefinition(
      id: 'blaze_p4', agentId: 'blaze',
      name: '浴火重生', description: '隊伍 HP 低於 25% 時，ATK +30%',
      effectType: PassiveEffectType.lowHpBoost, effectValue: 0.3,
      goldCost: 1500, materialCost: {GameMaterial.rareShard: 2, GameMaterial.passiveGem: 3},
      unlockAtAgentLevel: 20,
    ),
  ];

  // ─── 小波 Tide ───

  static const tidePassives = <PassiveSkillDefinition>[
    PassiveSkillDefinition(
      id: 'tide_p1', agentId: 'tide',
      name: '潮汐節奏', description: '每回合開始時，回復隊伍 3% HP',
      effectType: PassiveEffectType.turnStartHeal, effectValue: 0.03,
      goldCost: 300, materialCost: {GameMaterial.commonShard: 3, GameMaterial.passiveGem: 1},
      unlockAtAgentLevel: 5,
    ),
    PassiveSkillDefinition(
      id: 'tide_p2', agentId: 'tide',
      name: '水之守護', description: '使用技能後，獲得 15% 護盾 1 回合',
      effectType: PassiveEffectType.shieldOnSkill, effectValue: 0.15,
      goldCost: 600, materialCost: {GameMaterial.advancedShard: 2, GameMaterial.passiveGem: 1},
      unlockAtAgentLevel: 10,
    ),
    PassiveSkillDefinition(
      id: 'tide_p3', agentId: 'tide',
      name: '急救本能', description: 'HP 低於 40% 時，自動回復 8% HP（每場限 1 次）',
      effectType: PassiveEffectType.lowHpBoost, effectValue: 0.08,
      goldCost: 1000, materialCost: {GameMaterial.advancedShard: 3, GameMaterial.passiveGem: 2},
      unlockAtAgentLevel: 15,
    ),
    PassiveSkillDefinition(
      id: 'tide_p4', agentId: 'tide',
      name: '生命潮湧', description: '消除藍色方塊時，回復隊伍 2% HP',
      effectType: PassiveEffectType.healOnMatch, effectValue: 0.02,
      goldCost: 1500, materialCost: {GameMaterial.rareShard: 2, GameMaterial.passiveGem: 3},
      unlockAtAgentLevel: 20,
    ),
  ];

  // ─── 大地 Terra ───

  static const terraPassives = <PassiveSkillDefinition>[
    PassiveSkillDefinition(
      id: 'terra_p1', agentId: 'terra',
      name: '鋼鐵意志', description: '受到的傷害減少 8%',
      effectType: PassiveEffectType.dmgReduction, effectValue: 0.08,
      goldCost: 400, materialCost: {GameMaterial.commonShard: 4, GameMaterial.passiveGem: 1},
      unlockAtAgentLevel: 5,
    ),
    PassiveSkillDefinition(
      id: 'terra_p2', agentId: 'terra',
      name: '反擊護甲', description: '受擊時 20% 機率反擊，造成 50% ATK 傷害',
      effectType: PassiveEffectType.counterAttack, effectValue: 0.2,
      goldCost: 800, materialCost: {GameMaterial.advancedShard: 2, GameMaterial.passiveGem: 1},
      unlockAtAgentLevel: 12,
    ),
    PassiveSkillDefinition(
      id: 'terra_p3', agentId: 'terra',
      name: '守護之牆', description: '護盾效果 +20%',
      effectType: PassiveEffectType.shieldOnSkill, effectValue: 0.2,
      goldCost: 1200, materialCost: {GameMaterial.advancedShard: 3, GameMaterial.passiveGem: 2},
      unlockAtAgentLevel: 18,
    ),
    PassiveSkillDefinition(
      id: 'terra_p4', agentId: 'terra',
      name: '大地之力', description: '隊伍受傷時，獲得 1 點能量',
      effectType: PassiveEffectType.energyOnDamaged, effectValue: 1,
      goldCost: 2000, materialCost: {GameMaterial.rareShard: 2, GameMaterial.passiveGem: 3},
      unlockAtAgentLevel: 25,
    ),
  ];

  // ─── 閃光 Flash ───

  static const flashPassives = <PassiveSkillDefinition>[
    PassiveSkillDefinition(
      id: 'flash_p1', agentId: 'flash',
      name: '靜電場', description: '達成 5+ 連擊時，技能傷害 +15%',
      effectType: PassiveEffectType.comboSkillBonus, effectValue: 0.15,
      goldCost: 400, materialCost: {GameMaterial.commonShard: 4, GameMaterial.passiveGem: 1},
      unlockAtAgentLevel: 5,
    ),
    PassiveSkillDefinition(
      id: 'flash_p2', agentId: 'flash',
      name: '連鎖閃電', description: '單次消除 5+ 方塊時，該次傷害 +30%',
      effectType: PassiveEffectType.matchChainBonus, effectValue: 0.3,
      goldCost: 800, materialCost: {GameMaterial.advancedShard: 2, GameMaterial.passiveGem: 1},
      unlockAtAgentLevel: 12,
    ),
    PassiveSkillDefinition(
      id: 'flash_p3', agentId: 'flash',
      name: '電能過載', description: '擊殺敵人時獲得 2 點能量',
      effectType: PassiveEffectType.onKillEffect, effectValue: 2,
      goldCost: 1200, materialCost: {GameMaterial.advancedShard: 3, GameMaterial.passiveGem: 2},
      unlockAtAgentLevel: 18,
    ),
    PassiveSkillDefinition(
      id: 'flash_p4', agentId: 'flash',
      name: '雷霆之怒', description: '場上有 2+ 敵人時，ATK +20%',
      effectType: PassiveEffectType.lowHpBoost, effectValue: 0.2,
      goldCost: 2000, materialCost: {GameMaterial.rareShard: 2, GameMaterial.passiveGem: 3},
      unlockAtAgentLevel: 25,
    ),
  ];

  // ─── 影子 Shadow ───

  static const shadowPassives = <PassiveSkillDefinition>[
    PassiveSkillDefinition(
      id: 'shadow_p1', agentId: 'shadow',
      name: '暗影潛行', description: '戰鬥中首次攻擊傷害 ×1.5',
      effectType: PassiveEffectType.firstStrikeBonus, effectValue: 1.5,
      goldCost: 400, materialCost: {GameMaterial.commonShard: 4, GameMaterial.passiveGem: 1},
      unlockAtAgentLevel: 5,
    ),
    PassiveSkillDefinition(
      id: 'shadow_p2', agentId: 'shadow',
      name: '致命弱點', description: '斬殺門檻提升 +10%（30% → 40%）',
      effectType: PassiveEffectType.executeThresholdUp, effectValue: 0.1,
      goldCost: 800, materialCost: {GameMaterial.advancedShard: 2, GameMaterial.passiveGem: 1},
      unlockAtAgentLevel: 12,
    ),
    PassiveSkillDefinition(
      id: 'shadow_p3', agentId: 'shadow',
      name: '暗殺回饋', description: '擊殺敵人時，退還 30% 能量',
      effectType: PassiveEffectType.onKillEffect, effectValue: 0.3,
      goldCost: 1200, materialCost: {GameMaterial.advancedShard: 3, GameMaterial.passiveGem: 2},
      unlockAtAgentLevel: 18,
    ),
    PassiveSkillDefinition(
      id: 'shadow_p4', agentId: 'shadow',
      name: '死神之影', description: '攻擊 HP 低於 50% 的敵人時，傷害 +20%',
      effectType: PassiveEffectType.lowEnemyHpBonus, effectValue: 0.2,
      goldCost: 2000, materialCost: {GameMaterial.rareShard: 2, GameMaterial.passiveGem: 3},
      unlockAtAgentLevel: 25,
    ),
  ];

  // ─── 查詢方法 ───

  static const Map<String, List<PassiveSkillDefinition>> _agentPassives = {
    'blaze': blazePassives,
    'tide': tidePassives,
    'terra': terraPassives,
    'flash': flashPassives,
    'shadow': shadowPassives,
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
