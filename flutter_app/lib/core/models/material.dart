/// 素材類型
/// 用於天賦樹、技能強化、被動技能、進化的升級消耗
///
/// 分類：
/// - 碎片系列：commonShard / advancedShard / rareShard（通用養成）
/// - 功能素材：talentScroll / skillCore / passiveGem（系統專用）
/// - 屬性精華：essenceA~E（對應五屬性，進化 & 天賦用）
/// - 通用道具：expPotion / sweepTicket / crystalDust（便利 & 兌換）
enum GameMaterial {
  // ── 碎片系列 ──
  commonShard,   // 普通碎片
  advancedShard, // 進階碎片
  rareShard,     // 稀有碎片

  // ── 功能素材 ──
  talentScroll,  // 天賦卷軸
  skillCore,     // 技能核心
  passiveGem,    // 被動寶石

  // ── 屬性精華（五色） ──
  essenceA,      // 🔴 火焰精華
  essenceB,      // 🟢 大地精華
  essenceC,      // 🔵 水晶精華
  essenceD,      // 🟡 雷光精華
  essenceE,      // 🟣 暗影精華

  // ── 通用道具 ──
  expPotion,     // 經驗藥水（直接加角色 EXP）
  sweepTicket,   // 掃蕩券（自動通關已三星關卡）
  crystalDust;   // 水晶粉塵（萬能兌換貨幣）

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
      case GameMaterial.essenceA:
        return '火焰精華';
      case GameMaterial.essenceB:
        return '大地精華';
      case GameMaterial.essenceC:
        return '水晶精華';
      case GameMaterial.essenceD:
        return '雷光精華';
      case GameMaterial.essenceE:
        return '暗影精華';
      case GameMaterial.expPotion:
        return '經驗藥水';
      case GameMaterial.sweepTicket:
        return '掃蕩券';
      case GameMaterial.crystalDust:
        return '水晶粉塵';
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
      case GameMaterial.essenceA:
        return '🔥';
      case GameMaterial.essenceB:
        return '🌿';
      case GameMaterial.essenceC:
        return '💧';
      case GameMaterial.essenceD:
        return '⚡';
      case GameMaterial.essenceE:
        return '🌑';
      case GameMaterial.expPotion:
        return '🧪';
      case GameMaterial.sweepTicket:
        return '🎟️';
      case GameMaterial.crystalDust:
        return '✨';
    }
  }

  /// 素材分類
  MaterialCategory get category {
    switch (this) {
      case GameMaterial.commonShard:
      case GameMaterial.advancedShard:
      case GameMaterial.rareShard:
        return MaterialCategory.shard;
      case GameMaterial.talentScroll:
      case GameMaterial.skillCore:
      case GameMaterial.passiveGem:
        return MaterialCategory.functional;
      case GameMaterial.essenceA:
      case GameMaterial.essenceB:
      case GameMaterial.essenceC:
      case GameMaterial.essenceD:
      case GameMaterial.essenceE:
        return MaterialCategory.essence;
      case GameMaterial.expPotion:
      case GameMaterial.sweepTicket:
      case GameMaterial.crystalDust:
        return MaterialCategory.universal;
    }
  }

  /// 稀有度（1=普通, 2=進階, 3=稀有）
  int get rarity {
    switch (this) {
      case GameMaterial.commonShard:
      case GameMaterial.essenceA:
      case GameMaterial.essenceB:
      case GameMaterial.essenceC:
      case GameMaterial.essenceD:
      case GameMaterial.essenceE:
      case GameMaterial.crystalDust:
        return 1;
      case GameMaterial.advancedShard:
      case GameMaterial.talentScroll:
      case GameMaterial.expPotion:
      case GameMaterial.sweepTicket:
        return 2;
      case GameMaterial.rareShard:
      case GameMaterial.skillCore:
      case GameMaterial.passiveGem:
        return 3;
    }
  }

  /// 素材說明
  String get description {
    switch (this) {
      case GameMaterial.commonShard:
        return '基礎養成素材，各系統通用';
      case GameMaterial.advancedShard:
        return '中階養成素材，技能強化和天賦常用';
      case GameMaterial.rareShard:
        return '珍貴素材，高階進化與強化必備';
      case GameMaterial.talentScroll:
        return '解鎖天賦節點的專用素材';
      case GameMaterial.skillCore:
        return '強化技能階級的核心零件';
      case GameMaterial.passiveGem:
        return '解鎖被動技能的寶石';
      case GameMaterial.essenceA:
        return '火系角色進化專用精華';
      case GameMaterial.essenceB:
        return '大地系角色進化專用精華';
      case GameMaterial.essenceC:
        return '水系角色進化專用精華';
      case GameMaterial.essenceD:
        return '雷系角色進化專用精華';
      case GameMaterial.essenceE:
        return '暗系角色進化專用精華';
      case GameMaterial.expPotion:
        return '使用後直接為角色增加經驗值';
      case GameMaterial.sweepTicket:
        return '自動通關已三星的關卡，獲得獎勵';
      case GameMaterial.crystalDust:
        return '萬能兌換貨幣，可轉換為其他素材';
    }
  }
}

/// 素材分類
enum MaterialCategory {
  shard,      // 碎片
  functional, // 功能素材
  essence,    // 屬性精華
  universal;  // 通用道具

  String get label {
    switch (this) {
      case MaterialCategory.shard:
        return '碎片';
      case MaterialCategory.functional:
        return '功能素材';
      case MaterialCategory.essence:
        return '屬性精華';
      case MaterialCategory.universal:
        return '通用道具';
    }
  }

  String get emoji {
    switch (this) {
      case MaterialCategory.shard:
        return '💠';
      case MaterialCategory.functional:
        return '🔧';
      case MaterialCategory.essence:
        return '🌀';
      case MaterialCategory.universal:
        return '📦';
    }
  }
}
