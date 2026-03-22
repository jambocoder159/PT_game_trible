/// 天賦樹模型
/// 每隻貓有 3 條分支（攻擊/防禦/輔助），每條分支 3~4 個節點
import 'material.dart';

/// 天賦分支
enum TalentBranch {
  attack,  // 攻擊
  defense, // 防禦
  support; // 輔助

  String get label {
    switch (this) {
      case TalentBranch.attack:
        return '攻擊';
      case TalentBranch.defense:
        return '防禦';
      case TalentBranch.support:
        return '輔助';
    }
  }

  String get emoji {
    switch (this) {
      case TalentBranch.attack:
        return '⚔️';
      case TalentBranch.defense:
        return '🛡️';
      case TalentBranch.support:
        return '💫';
    }
  }
}

/// 天賦效果類型
enum TalentEffectType {
  atkPercent,     // +X% ATK
  defPercent,     // +X% DEF
  hpPercent,      // +X% HP
  skillDamageUp,  // +X% 技能傷害
  energyGainUp,   // +X% 能量獲取
  shieldBoost,    // +X% 護盾效果
  healBoost,      // +X% 治療效果
  comboBonus,     // +X% 連擊傷害
  critChance,     // +X% 暴擊率
  critDamage,     // +X% 暴擊傷害
  dmgReduction,   // -X% 受到傷害
  matchDamageUp;  // +X% 消除傷害

  String get label {
    switch (this) {
      case TalentEffectType.atkPercent:
        return 'ATK';
      case TalentEffectType.defPercent:
        return 'DEF';
      case TalentEffectType.hpPercent:
        return 'HP';
      case TalentEffectType.skillDamageUp:
        return '技能傷害';
      case TalentEffectType.energyGainUp:
        return '能量獲取';
      case TalentEffectType.shieldBoost:
        return '護盾效果';
      case TalentEffectType.healBoost:
        return '治療效果';
      case TalentEffectType.comboBonus:
        return '連擊傷害';
      case TalentEffectType.critChance:
        return '暴擊率';
      case TalentEffectType.critDamage:
        return '暴擊傷害';
      case TalentEffectType.dmgReduction:
        return '減傷';
      case TalentEffectType.matchDamageUp:
        return '消除傷害';
    }
  }
}

/// 天賦節點定義（靜態數據）
class TalentNodeDefinition {
  final String id;
  final String name;
  final String description;
  final TalentBranch branch;
  final int tier; // 1-4
  final TalentEffectType effectType;
  final double effectValue; // 百分比值，例如 5 代表 5%
  final int goldCost;
  final Map<GameMaterial, int> materialCost;
  final String? prerequisiteNodeId;

  const TalentNodeDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.branch,
    required this.tier,
    required this.effectType,
    required this.effectValue,
    required this.goldCost,
    required this.materialCost,
    this.prerequisiteNodeId,
  });
}
