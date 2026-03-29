import 'package:flutter/foundation.dart';
import '../../../config/ingredient_data.dart';
import '../../../core/models/dessert.dart';
import '../../../core/models/player_data.dart';

/// 甜點製作 Provider — 製作、販賣食材/甜點
class CraftingProvider extends ChangeNotifier {
  /// 檢查食譜是否已解鎖
  bool isRecipeUnlocked(String recipeId, PlayerData playerData) {
    final recipe = DessertDefinitions.getById(recipeId);
    if (recipe == null) return false;

    switch (recipe.unlock.type) {
      case DessertUnlockType.defaultUnlocked:
        return true;
      case DessertUnlockType.stageClear:
        final stageId = recipe.unlock.stageId;
        if (stageId == null) return false;
        final progress = playerData.stageProgress[stageId];
        return progress != null && progress.cleared;
      case DessertUnlockType.purchase:
        return playerData.unlockedRecipes.contains(recipeId);
    }
  }

  /// 購買食譜
  bool buyRecipe(String recipeId, PlayerData playerData) {
    final recipe = DessertDefinitions.getById(recipeId);
    if (recipe == null) return false;
    if (recipe.unlock.type != DessertUnlockType.purchase) return false;
    if (playerData.unlockedRecipes.contains(recipeId)) return false;
    if (playerData.gold < recipe.unlock.purchaseCost) return false;

    playerData.gold -= recipe.unlock.purchaseCost;
    playerData.unlockedRecipes.add(recipeId);
    notifyListeners();
    return true;
  }

  /// 檢查是否有足夠食材製作
  bool canCraft(String recipeId, PlayerData playerData) {
    final recipe = DessertDefinitions.getById(recipeId);
    if (recipe == null) return false;
    if (!isRecipeUnlocked(recipeId, playerData)) return false;

    for (final entry in recipe.ingredients.entries) {
      if ((playerData.ingredients[entry.key] ?? 0) < entry.value) return false;
    }
    return true;
  }

  /// 製作甜點
  bool craftDessert(String recipeId, PlayerData playerData) {
    if (!canCraft(recipeId, playerData)) return false;

    final recipe = DessertDefinitions.getById(recipeId)!;

    // 扣除食材
    for (final entry in recipe.ingredients.entries) {
      playerData.ingredients[entry.key] =
          (playerData.ingredients[entry.key] ?? 0) - entry.value;
    }

    // 加入甜點
    playerData.desserts[recipeId] =
        (playerData.desserts[recipeId] ?? 0) + 1;

    notifyListeners();
    return true;
  }

  /// 販賣食材
  int sellIngredient(String ingredientId, int count, PlayerData playerData) {
    final ingredient = IngredientDefinitions.getById(ingredientId);
    if (ingredient == null) return 0;

    final owned = playerData.ingredients[ingredientId] ?? 0;
    final actualCount = count.clamp(0, owned);
    if (actualCount <= 0) return 0;

    playerData.ingredients[ingredientId] = owned - actualCount;
    final income = ingredient.sellPrice * actualCount;
    playerData.gold += income;

    notifyListeners();
    return income;
  }

  /// 販賣甜點
  int sellDessert(String dessertId, int count, PlayerData playerData) {
    final recipe = DessertDefinitions.getById(dessertId);
    if (recipe == null) return 0;

    final owned = playerData.desserts[dessertId] ?? 0;
    final actualCount = count.clamp(0, owned);
    if (actualCount <= 0) return 0;

    playerData.desserts[dessertId] = owned - actualCount;
    final income = recipe.sellPrice * actualCount;
    playerData.gold += income;

    notifyListeners();
    return income;
  }

  /// 取得所有可見的食譜（包含鎖定的，按 tier 排序）
  List<DessertRecipe> getAllRecipes() {
    return DessertDefinitions.all;
  }
}
