/// 被動技能模型
/// 每隻貓有 4 個被動，解鎖後最多同時裝備 2 個
import 'material.dart';

/// 被動效果類型
enum PassiveEffectType {
  energyBonus,       // 消除特定顏色方塊時額外能量
  lowHpBoost,        // 低血量時提升攻擊
  firstStrikeBonus,  // 首次攻擊加成
  comboSkillBonus,   // 連擊後技能傷害加成
  counterAttack,     // 反擊
  matchChainBonus,   // 長連鎖加成
  turnStartHeal,     // 每回合治療
  onKillEffect,      // 擊殺效果
  shieldOnSkill,     // 放技能時獲得護盾
  healOnMatch,       // 消除方塊時治療
  energyOnDamaged,   // 受傷時獲得能量
  executeThresholdUp,// 斬殺門檻提升
  dmgReduction,      // 減傷
  critChance,        // 暴擊率
  lowEnemyHpBonus;   // 攻擊低血敵人加成

  String get label {
    switch (this) {
      case PassiveEffectType.energyBonus:
        return '能量加成';
      case PassiveEffectType.lowHpBoost:
        return '低血量強化';
      case PassiveEffectType.firstStrikeBonus:
        return '先手加成';
      case PassiveEffectType.comboSkillBonus:
        return '連擊技能強化';
      case PassiveEffectType.counterAttack:
        return '反擊';
      case PassiveEffectType.matchChainBonus:
        return '連鎖加成';
      case PassiveEffectType.turnStartHeal:
        return '回合治療';
      case PassiveEffectType.onKillEffect:
        return '擊殺效果';
      case PassiveEffectType.shieldOnSkill:
        return '技能護盾';
      case PassiveEffectType.healOnMatch:
        return '消除治療';
      case PassiveEffectType.energyOnDamaged:
        return '受傷能量';
      case PassiveEffectType.executeThresholdUp:
        return '斬殺強化';
      case PassiveEffectType.dmgReduction:
        return '減傷';
      case PassiveEffectType.critChance:
        return '暴擊';
      case PassiveEffectType.lowEnemyHpBonus:
        return '追擊';
    }
  }
}

/// 被動技能定義
class PassiveSkillDefinition {
  final String id;
  final String agentId;
  final String name;
  final String description;
  final PassiveEffectType effectType;
  final double effectValue;
  final int goldCost;
  final Map<MaterialType, int> materialCost;
  final int unlockAtAgentLevel;

  const PassiveSkillDefinition({
    required this.id,
    required this.agentId,
    required this.name,
    required this.description,
    required this.effectType,
    required this.effectValue,
    required this.goldCost,
    required this.materialCost,
    required this.unlockAtAgentLevel,
  });
}
