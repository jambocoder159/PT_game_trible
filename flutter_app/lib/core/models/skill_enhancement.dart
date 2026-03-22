/// 技能強化模型
/// 每隻貓的主動技能可升 1→5 階
import 'material.dart';

/// 技能強化附加機制
enum SkillTierMechanic {
  dot,                // 持續傷害
  aoeSplash,          // 濺射
  energyRefund,       // 能量退還
  durationExtend,     // 持續時間延長
  executeThresholdUp, // 斬殺門檻提升
  defBreak,           // 破防
  delayAdded,         // 延遲
  reflect;            // 反射傷害

  String get label {
    switch (this) {
      case SkillTierMechanic.dot:
        return '持續傷害';
      case SkillTierMechanic.aoeSplash:
        return '濺射';
      case SkillTierMechanic.energyRefund:
        return '能量退還';
      case SkillTierMechanic.durationExtend:
        return '持續延長';
      case SkillTierMechanic.executeThresholdUp:
        return '斬殺門檻提升';
      case SkillTierMechanic.defBreak:
        return '破防';
      case SkillTierMechanic.delayAdded:
        return '延遲';
      case SkillTierMechanic.reflect:
        return '反射';
    }
  }
}

/// 技能階級定義
class SkillTierDefinition {
  final int tier;                       // 1-5
  final String name;
  final String description;
  final double multiplierBonus;         // 累加到基礎倍率
  final SkillTierMechanic? newMechanic;
  final double mechanicValue;           // 機制參數值
  final int goldCost;
  final Map<MaterialType, int> materialCost;

  const SkillTierDefinition({
    required this.tier,
    required this.name,
    required this.description,
    required this.multiplierBonus,
    this.newMechanic,
    this.mechanicValue = 0,
    required this.goldCost,
    required this.materialCost,
  });
}
