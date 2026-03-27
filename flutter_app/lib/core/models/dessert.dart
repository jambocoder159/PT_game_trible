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
}
