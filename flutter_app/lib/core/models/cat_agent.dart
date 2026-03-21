/// 貓咪特工角色模型
///
/// 屬性系統：5 屬性（剪刀石頭布式相剋）
/// - 三角相剋：A(🔴) → 剋 B(🟢) → 剋 C(🔵) → 剋 A
/// - 互相剋制：D(🟡) ⟷ E(🟣)
/// - 剋制倍率：被剋 1.5x，剋制 0.75x
import 'block.dart';

/// 角色屬性（對應 5 種方塊顏色）
enum AgentAttribute {
  /// 🔴 屬性A — 對應 BlockColor.coral
  attributeA,

  /// 🟢 屬性B — 對應 BlockColor.mint
  attributeB,

  /// 🔵 屬性C — 對應 BlockColor.teal
  attributeC,

  /// 🟡 屬性D — 對應 BlockColor.gold
  attributeD,

  /// 🟣 屬性E — 對應 BlockColor.rose
  attributeE;

  /// 對應的方塊顏色
  BlockColor get blockColor {
    switch (this) {
      case AgentAttribute.attributeA:
        return BlockColor.coral;
      case AgentAttribute.attributeB:
        return BlockColor.mint;
      case AgentAttribute.attributeC:
        return BlockColor.teal;
      case AgentAttribute.attributeD:
        return BlockColor.gold;
      case AgentAttribute.attributeE:
        return BlockColor.rose;
    }
  }

  /// 計算對目標屬性的傷害倍率
  double damageMultiplierAgainst(AgentAttribute target) {
    // 三角相剋：A → B → C → A
    if (this == AgentAttribute.attributeA &&
        target == AgentAttribute.attributeB) {
      return 1.5;
    }
    if (this == AgentAttribute.attributeB &&
        target == AgentAttribute.attributeC) {
      return 1.5;
    }
    if (this == AgentAttribute.attributeC &&
        target == AgentAttribute.attributeA) {
      return 1.5;
    }

    // 三角被剋
    if (this == AgentAttribute.attributeB &&
        target == AgentAttribute.attributeA) {
      return 0.75;
    }
    if (this == AgentAttribute.attributeC &&
        target == AgentAttribute.attributeB) {
      return 0.75;
    }
    if (this == AgentAttribute.attributeA &&
        target == AgentAttribute.attributeC) {
      return 0.75;
    }

    // 互相剋制：D ⟷ E
    if (this == AgentAttribute.attributeD &&
        target == AgentAttribute.attributeE) {
      return 1.5;
    }
    if (this == AgentAttribute.attributeE &&
        target == AgentAttribute.attributeD) {
      return 1.5;
    }

    return 1.0;
  }

  String get label {
    switch (this) {
      case AgentAttribute.attributeA:
        return '屬性A';
      case AgentAttribute.attributeB:
        return '屬性B';
      case AgentAttribute.attributeC:
        return '屬性C';
      case AgentAttribute.attributeD:
        return '屬性D';
      case AgentAttribute.attributeE:
        return '屬性E';
    }
  }

  String get emoji {
    switch (this) {
      case AgentAttribute.attributeA:
        return '🔴';
      case AgentAttribute.attributeB:
        return '🟢';
      case AgentAttribute.attributeC:
        return '🔵';
      case AgentAttribute.attributeD:
        return '🟡';
      case AgentAttribute.attributeE:
        return '🟣';
    }
  }
}

/// 角色職業
enum AgentRole {
  striker, // 突擊手
  defender, // 防衛者
  supporter, // 支援者
  destroyer, // 破壞者
  infiltrator; // 潛行者

  String get label {
    switch (this) {
      case AgentRole.striker:
        return '突擊手';
      case AgentRole.defender:
        return '防衛者';
      case AgentRole.supporter:
        return '支援者';
      case AgentRole.destroyer:
        return '破壞者';
      case AgentRole.infiltrator:
        return '潛行者';
    }
  }
}

/// 角色稀有度
enum AgentRarity {
  n(1, 'N'),
  r(2, 'R'),
  sr(3, 'SR'),
  ssr(4, 'SSR');

  final int tier;
  final String display;

  const AgentRarity(this.tier, this.display);
}

/// 技能效果類型
enum SkillEffectType {
  damage, // 傷害
  heal, // 回復
  shield, // 減傷
  aoe, // 全體傷害
  execute, // 斬殺（低血加傷）
  delay, // 延遲敵人攻擊
}

/// 技能定義
class AgentSkill {
  final String name;
  final String description;
  final int energyCost; // 需要累積多少能量
  final SkillEffectType effectType;
  final double baseMultiplier; // 基礎倍率（隨等級成長）
  final double levelScaling; // 每級增加的倍率

  const AgentSkill({
    required this.name,
    required this.description,
    required this.energyCost,
    required this.effectType,
    required this.baseMultiplier,
    this.levelScaling = 0.05,
  });

  /// 計算特定等級的倍率
  double multiplierAtLevel(int level) {
    return baseMultiplier + (level - 1) * levelScaling;
  }
}

/// 解鎖條件
class UnlockCondition {
  final String? stageRequirement; // 需通關的關卡 ID（例如 "1-3"）
  final bool? requireAllStars; // 是否需要全三星
  final int goldCost; // 金幣花費
  final int diamondCost; // 鑽石花費

  const UnlockCondition({
    this.stageRequirement,
    this.requireAllStars,
    this.goldCost = 0,
    this.diamondCost = 0,
  });

  /// 初始角色，無需解鎖
  static const free = UnlockCondition();

  bool get isFree =>
      stageRequirement == null && goldCost == 0 && diamondCost == 0;
}

/// 角色定義（靜態數據，不可變）
class CatAgentDefinition {
  final String id;
  final String name;
  final String codename;
  final String breed;
  final AgentAttribute attribute;
  final AgentRole role;
  final AgentRarity rarity;
  final AgentSkill skill;
  final String passiveDescription;
  final UnlockCondition unlockCondition;

  // 基礎屬性（等級 1）
  final int baseAtk;
  final int baseDef;
  final int baseHp;

  // 每級成長
  final double atkGrowth;
  final double defGrowth;
  final double hpGrowth;

  const CatAgentDefinition({
    required this.id,
    required this.name,
    required this.codename,
    required this.breed,
    required this.attribute,
    required this.role,
    required this.rarity,
    required this.skill,
    required this.passiveDescription,
    required this.unlockCondition,
    required this.baseAtk,
    required this.baseDef,
    required this.baseHp,
    this.atkGrowth = 3.0,
    this.defGrowth = 2.0,
    this.hpGrowth = 10.0,
  });

  /// 計算特定等級的 ATK
  int atkAtLevel(int level) => baseAtk + ((level - 1) * atkGrowth).round();

  /// 計算特定等級的 DEF
  int defAtLevel(int level) => baseDef + ((level - 1) * defGrowth).round();

  /// 計算特定等級的 HP
  int hpAtLevel(int level) => baseHp + ((level - 1) * hpGrowth).round();

  /// 等級上限
  int get maxLevel {
    switch (rarity) {
      case AgentRarity.n:
        return 30;
      case AgentRarity.r:
        return 40;
      case AgentRarity.sr:
        return 50;
      case AgentRarity.ssr:
        return 50;
    }
  }

  /// 升到指定等級所需的累計 EXP
  int expRequiredForLevel(int level) {
    if (level <= 1) return 0;
    // 簡單公式：每級所需 EXP 遞增
    int total = 0;
    for (int l = 2; l <= level; l++) {
      total += (10 + (l - 1) * 5) * rarity.tier;
    }
    return total;
  }
}

/// 玩家擁有的角色實例（可變狀態）
class CatAgentInstance {
  final String definitionId;
  int level;
  int currentExp;
  bool isUnlocked;

  CatAgentInstance({
    required this.definitionId,
    this.level = 1,
    this.currentExp = 0,
    this.isUnlocked = false,
  });

  /// 從 JSON 建立
  factory CatAgentInstance.fromJson(Map<String, dynamic> json) {
    return CatAgentInstance(
      definitionId: json['definitionId'] as String,
      level: json['level'] as int? ?? 1,
      currentExp: json['currentExp'] as int? ?? 0,
      isUnlocked: json['isUnlocked'] as bool? ?? false,
    );
  }

  /// 轉為 JSON
  Map<String, dynamic> toJson() {
    return {
      'definitionId': definitionId,
      'level': level,
      'currentExp': currentExp,
      'isUnlocked': isUnlocked,
    };
  }
}
