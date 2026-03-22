import 'block.dart';

/// 貓咪定義（5 隻，各對應一個方塊顏色）
class CatDefinition {
  final String id;
  final String name;
  final String emoji;
  final BlockColor color;
  final int baseMaxFood; // 基礎飽食度上限

  const CatDefinition({
    required this.id,
    required this.name,
    required this.emoji,
    required this.color,
    this.baseMaxFood = 50,
  });
}

/// 所有貓咪定義
class CatDefinitions {
  CatDefinitions._();

  static const blazeCat = CatDefinition(
    id: 'blaze_cat',
    name: '火焰貓',
    emoji: '🔥',
    color: BlockColor.coral,
    baseMaxFood: 50,
  );

  static const tideCat = CatDefinition(
    id: 'tide_cat',
    name: '海潮貓',
    emoji: '🌊',
    color: BlockColor.teal,
    baseMaxFood: 50,
  );

  static const forestCat = CatDefinition(
    id: 'forest_cat',
    name: '森林貓',
    emoji: '🌿',
    color: BlockColor.mint,
    baseMaxFood: 50,
  );

  static const flashCat = CatDefinition(
    id: 'flash_cat',
    name: '閃電貓',
    emoji: '⚡',
    color: BlockColor.gold,
    baseMaxFood: 50,
  );

  static const shadowCat = CatDefinition(
    id: 'shadow_cat',
    name: '暗影貓',
    emoji: '🌙',
    color: BlockColor.rose,
    baseMaxFood: 50,
  );

  static const List<CatDefinition> all = [
    blazeCat,
    tideCat,
    forestCat,
    flashCat,
    shadowCat,
  ];

  static CatDefinition? getById(String id) {
    for (final cat in all) {
      if (cat.id == id) return cat;
    }
    return null;
  }

  static CatDefinition? getByColor(BlockColor color) {
    for (final cat in all) {
      if (cat.color == color) return cat;
    }
    return null;
  }
}

/// 貓咪實例狀態（可序列化）
class CatStatus {
  final String definitionId;
  int currentFood;
  int totalFed; // 累計餵食量（用於計算等級）

  CatStatus({
    required this.definitionId,
    this.currentFood = 0,
    this.totalFed = 0,
  });

  CatDefinition? get definition => CatDefinitions.getById(definitionId);

  /// 根據玩家等級計算飽食度上限
  int maxFood(int playerLevel) {
    final base = definition?.baseMaxFood ?? 50;
    return (base * (1 + playerLevel * 0.15)).round();
  }

  /// 是否至少有一個寶箱可開
  bool isFull(int playerLevel) => currentFood >= maxFood(playerLevel);

  /// 累積的寶箱數量
  int chestCount(int playerLevel) {
    final max = maxFood(playerLevel);
    if (max <= 0) return 0;
    return currentFood ~/ max;
  }

  /// 當前進度條 (0.0 ~ 1.0)，只顯示「下一個寶箱」的進度
  double progress(int playerLevel) {
    final max = maxFood(playerLevel);
    if (max <= 0) return 0;
    return ((currentFood % max) / max).clamp(0.0, 1.0);
  }

  /// 整體飽食度佔比（用於判斷是否溢出）
  double overallProgress(int playerLevel) {
    final max = maxFood(playerLevel);
    if (max <= 0) return 0;
    return (currentFood / max).clamp(0.0, 999.0);
  }

  factory CatStatus.fromJson(Map<String, dynamic> json) {
    return CatStatus(
      definitionId: json['definitionId'] as String? ?? '',
      currentFood: json['currentFood'] as int? ?? 0,
      totalFed: json['totalFed'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'definitionId': definitionId,
      'currentFood': currentFood,
      'totalFed': totalFed,
    };
  }
}

/// 貓咪產出的獎勵
class CatReward {
  final String name;
  final int quantity;
  final int rarity; // 1=普通, 2=進階, 3=稀有

  const CatReward({
    required this.name,
    required this.quantity,
    this.rarity = 1,
  });
}
