/// 素材類型
/// 用於天賦樹、技能強化、被動技能的升級消耗
enum MaterialType {
  commonShard,   // 普通碎片
  advancedShard, // 進階碎片
  rareShard,     // 稀有碎片
  talentScroll,  // 天賦卷軸
  skillCore,     // 技能核心
  passiveGem;    // 被動寶石

  String get label {
    switch (this) {
      case MaterialType.commonShard:
        return '普通碎片';
      case MaterialType.advancedShard:
        return '進階碎片';
      case MaterialType.rareShard:
        return '稀有碎片';
      case MaterialType.talentScroll:
        return '天賦卷軸';
      case MaterialType.skillCore:
        return '技能核心';
      case MaterialType.passiveGem:
        return '被動寶石';
    }
  }

  String get emoji {
    switch (this) {
      case MaterialType.commonShard:
        return '🔹';
      case MaterialType.advancedShard:
        return '🔷';
      case MaterialType.rareShard:
        return '💎';
      case MaterialType.talentScroll:
        return '📜';
      case MaterialType.skillCore:
        return '⚙️';
      case MaterialType.passiveGem:
        return '💠';
    }
  }
}
