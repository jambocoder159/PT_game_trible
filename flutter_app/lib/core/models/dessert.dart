/// 甜點解鎖方式
enum DessertUnlockType {
  defaultUnlocked, // 預設解鎖
  stageClear,      // 通關解鎖
  purchase,        // 食譜購買
}

/// 甜點解鎖條件
class DessertUnlockCondition {
  final DessertUnlockType type;
  final String? stageId;       // stageClear 時需要的關卡 ID
  final int purchaseCost;      // purchase 時的費用

  const DessertUnlockCondition.defaultUnlocked()
      : type = DessertUnlockType.defaultUnlocked,
        stageId = null,
        purchaseCost = 0;

  const DessertUnlockCondition.stageClear(this.stageId)
      : type = DessertUnlockType.stageClear,
        purchaseCost = 0;

  const DessertUnlockCondition.purchase(this.purchaseCost)
      : type = DessertUnlockType.purchase,
        stageId = null;

  factory DessertUnlockCondition.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String? ?? 'default';
    switch (typeStr) {
      case 'stageClear':
        return DessertUnlockCondition.stageClear(json['stageId'] as String?);
      case 'purchase':
        return DessertUnlockCondition.purchase((json['goldCost'] as num?)?.toInt() ?? 0);
      default:
        return const DessertUnlockCondition.defaultUnlocked();
    }
  }
}

/// 甜點食譜定義
class DessertRecipe {
  final String id;
  final String name;
  final String emoji;
  final int tier; // 1~4
  final Map<String, int> ingredients; // ingredientId → 數量
  final int sellPrice;
  final DessertUnlockCondition unlock;

  const DessertRecipe({
    required this.id,
    required this.name,
    required this.emoji,
    required this.tier,
    required this.ingredients,
    required this.sellPrice,
    required this.unlock,
  });

  factory DessertRecipe.fromJson(Map<String, dynamic> json) {
    final rawIngredients = json['ingredients'] as Map<String, dynamic>? ?? {};
    final ingredients = rawIngredients.map((k, v) => MapEntry(k, (v as num).toInt()));
    return DessertRecipe(
      id: json['id'] as String,
      name: json['name'] as String,
      emoji: json['emoji'] as String,
      tier: (json['tier'] as num).toInt(),
      ingredients: ingredients,
      sellPrice: (json['sellPrice'] as num).toInt(),
      unlock: DessertUnlockCondition.fromJson(json['unlock'] as Map<String, dynamic>? ?? {}),
    );
  }
}
