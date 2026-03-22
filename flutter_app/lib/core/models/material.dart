/// 素材類型
/// 用於天賦樹、技能強化、被動技能的升級消耗
enum GameMaterial {
  commonShard,   // 普通碎片
  advancedShard, // 進階碎片
  rareShard,     // 稀有碎片
  talentScroll,  // 天賦卷軸
  skillCore,     // 技能核心
  passiveGem;    // 被動寶石

  String get label {
    switch (this) {
      case GameMaterial.commonShard:
        return '普通碎片';
      case GameMaterial.advancedShard:
        return '進階碎片';
      case GameMaterial.rareShard:
        return '稀有碎片';
      case GameMaterial.talentScroll:
        return '天賦卷軸';
      case GameMaterial.skillCore:
        return '技能核心';
      case GameMaterial.passiveGem:
        return '被動寶石';
    }
  }

  String get emoji {
    switch (this) {
      case GameMaterial.commonShard:
        return '🔹';
      case GameMaterial.advancedShard:
        return '🔷';
      case GameMaterial.rareShard:
        return '💎';
      case GameMaterial.talentScroll:
        return '📜';
      case GameMaterial.skillCore:
        return '⚙️';
      case GameMaterial.passiveGem:
        return '💠';
    }
  }
}
