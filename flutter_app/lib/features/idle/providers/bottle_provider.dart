import 'dart:math';
import 'package:flutter/foundation.dart';
import '../../../config/bottle_dessert_map.dart';
import '../../../config/ingredient_data.dart';
import '../../../core/models/block.dart';
import '../../../core/models/bottle_data.dart';
import '../../../core/models/dessert.dart';
import '../../../core/models/ingredient.dart';
import '../../../core/models/player_data.dart';
import '../../../core/services/local_storage.dart';

/// 收成結果
class HarvestResult {
  final Map<String, int> dessertsProduced; // dessertId → count
  final int totalGold;
  final int critBonusGold;

  const HarvestResult({
    required this.dessertsProduced,
    required this.totalGold,
    required this.critBonusGold,
  });

  bool get isEmpty => totalGold == 0;
}

/// 魔法瓶管理 Provider — 能量累積、收成、瓶子升級
class BottleProvider extends ChangeNotifier {
  final Map<BlockColor, BottleStatus> _bottles = {};
  bool _isInitialized = false;
  final _random = Random();

  /// 爆擊基礎機率（+50% 金幣）
  static const double baseCritChance = 0.15;

  /// 自動收成開關
  bool _autoHarvestEnabled = false;
  bool get autoHarvestEnabled => _autoHarvestEnabled;

  void setAutoHarvest(bool enabled) {
    _autoHarvestEnabled = enabled;
    notifyListeners();
    _saveAutoHarvest();
  }

  Future<void> _saveAutoHarvest() async {
    await LocalStorageService.instance
        .setJson('auto_harvest', _autoHarvestEnabled);
  }

  Map<BlockColor, BottleStatus> get bottles => _bottles;
  bool get isInitialized => _isInitialized;

  /// 初始化 — 從 localStorage 載入或建立預設瓶子
  Future<void> init() async {
    final storage = LocalStorageService.instance;
    final json = storage.getJson('bottle_states');

    if (json != null && json is Map<String, dynamic>) {
      for (final entry in json.entries) {
        final status = BottleStatus.fromJson(
          entry.value as Map<String, dynamic>,
        );
        _bottles[status.color] = status;
      }
    }

    // 確保 5 個瓶子都存在
    for (final color in BlockColor.values) {
      _bottles.putIfAbsent(color, () => BottleStatus(color: color));
    }

    // 載入自動收成設定
    final autoHarvest = LocalStorageService.instance.getJson('auto_harvest');
    if (autoHarvest is bool) _autoHarvestEnabled = autoHarvest;

    _isInitialized = true;
    notifyListeners();
  }

  /// 取得指定顏色的瓶子
  BottleStatus getBottle(BlockColor color) =>
      _bottles[color] ?? BottleStatus(color: color);

  /// 增加能量到對應顏色的瓶子
  void addEnergy(BlockColor color, int amount) {
    final bottle = _bottles[color];
    if (bottle == null) return;
    bottle.addEnergy(amount);
    notifyListeners();
    _save();
  }

  /// 批量增加能量（消除結算時用）
  void addEnergyBatch(Map<BlockColor, int> energyByColor) {
    for (final entry in energyByColor.entries) {
      final bottle = _bottles[entry.key];
      if (bottle == null) continue;
      bottle.addEnergy(entry.value);
    }
    notifyListeners();
    _save();
  }

  /// 指定瓶子是否有足夠能量開始製作甜點。
  bool canProduce(BlockColor color, String dessertId) {
    final bottle = _bottles[color];
    if (bottle == null) return false;

    final recipe = DessertDefinitions.getById(dessertId);
    if (recipe == null) return false;
    if (recipe.sourceColor != null && recipe.sourceColor != color) return false;

    final energyCost = recipe.directEnergyCost ??
        BottleDessertMap.getBestForLevel(color, bottle.level)?.energyCost;
    if (energyCost == null || energyCost <= 0) return false;

    final available = BottleDessertMap.getAvailable(color, bottle.level)
        .any((tier) => tier.dessertId == dessertId);
    if (!available) return false;

    return bottle.currentEnergy >= energyCost;
  }

  /// 開始製作時扣除瓶子能量。
  bool consumeEnergy(BlockColor color, int amount) {
    final bottle = _bottles[color];
    if (bottle == null || amount <= 0) return false;
    final didConsume = bottle.consumeEnergy(amount);
    if (didConsume) {
      notifyListeners();
      _save();
    }
    return didConsume;
  }

  // ═══════════════════════════════════════════
  // 收成系統（新）
  // ═══════════════════════════════════════════

  /// 一鍵收成：所有瓶子的能量 → 甜點 → 直接賣出拿金幣
  HarvestResult harvest(PlayerData playerData) {
    final dessertsProduced = <String, int>{};
    int totalGold = 0;
    int critBonusGold = 0;

    for (final color in BlockColor.values) {
      final bottle = _bottles[color];
      if (bottle == null || bottle.currentEnergy <= 0) continue;

      // 取得當前生產的甜點
      final dessertId = bottle.currentDessertId ??
          BottleDessertMap.getBestForLevel(color, bottle.level)?.dessertId;
      if (dessertId == null) continue;

      final recipe = DessertDefinitions.getById(dessertId);
      if (recipe == null) continue;

      final energyCost = recipe.directEnergyCost ??
          BottleDessertMap.getBestForLevel(color, bottle.level)?.energyCost ??
          30;

      // 計算產出數量
      final count = bottle.currentEnergy ~/ energyCost;
      if (count <= 0) continue;

      // 扣除能量
      bottle.consumeEnergy(count * energyCost);

      // 計算金幣
      int gold = count * recipe.sellPrice;

      // 爆擊判定（每瓶獨立判定）
      if (_random.nextDouble() < baseCritChance) {
        final bonus = (gold * 0.5).round();
        critBonusGold += bonus;
        gold += bonus;
      }

      dessertsProduced[dessertId] = (dessertsProduced[dessertId] ?? 0) + count;
      totalGold += gold;
    }

    if (totalGold > 0) {
      playerData.gold += totalGold;
      notifyListeners();
      _save();
    }

    return HarvestResult(
      dessertsProduced: dessertsProduced,
      totalGold: totalGold,
      critBonusGold: critBonusGold,
    );
  }

  /// 滿瓶數量
  int getFullBottleCount() {
    return _bottles.values.where((b) => b.isFull).length;
  }

  /// 有能量可收成的瓶子數量（能量 >= 該瓶最低 energyCost）
  int getHarvestableCount() {
    int count = 0;
    for (final bottle in _bottles.values) {
      if (bottle.currentEnergy <= 0) continue;
      final dessertId = bottle.currentDessertId ??
          BottleDessertMap.getBestForLevel(bottle.color, bottle.level)
              ?.dessertId;
      if (dessertId == null) continue;
      final recipe = DessertDefinitions.getById(dessertId);
      final energyCost = recipe?.directEnergyCost ??
          BottleDessertMap.getBestForLevel(bottle.color, bottle.level)
              ?.energyCost ??
          30;
      if (bottle.currentEnergy >= energyCost) count++;
    }
    return count;
  }

  /// 最接近滿的瓶子的填充進度 (0.0~1.0)
  double getNearestProgress() {
    double best = 0.0;
    for (final bottle in _bottles.values) {
      if (bottle.fillProgress > best) best = bottle.fillProgress;
    }
    return best;
  }

  /// 預估收成金幣
  int estimateHarvestGold() {
    int total = 0;
    for (final bottle in _bottles.values) {
      if (bottle.currentEnergy <= 0) continue;
      final dessertId = bottle.currentDessertId ??
          BottleDessertMap.getBestForLevel(bottle.color, bottle.level)
              ?.dessertId;
      if (dessertId == null) continue;
      final recipe = DessertDefinitions.getById(dessertId);
      if (recipe == null) continue;
      final energyCost = recipe.directEnergyCost ??
          BottleDessertMap.getBestForLevel(bottle.color, bottle.level)
              ?.energyCost ??
          30;
      final count = bottle.currentEnergy ~/ energyCost;
      total += count * recipe.sellPrice;
    }
    return total;
  }

  /// 設定某瓶當前生產的甜點
  void setCurrentDessert(BlockColor color, String? dessertId) {
    final bottle = _bottles[color];
    if (bottle == null) return;
    bottle.currentDessertId = dessertId;
    notifyListeners();
    _save();
  }

  /// 取得某瓶當前生產的甜點
  DessertRecipe? getCurrentDessert(BlockColor color) {
    final bottle = _bottles[color];
    if (bottle == null) return null;

    if (bottle.currentDessertId != null) {
      final recipe = DessertDefinitions.getById(bottle.currentDessertId!);
      if (recipe != null) return recipe;
    }
    // 回退：取該瓶等級的最佳甜點
    final tier = BottleDessertMap.getBestForLevel(color, bottle.level);
    if (tier == null) return null;
    return DessertDefinitions.getById(tier.dessertId);
  }

  // ═══════════════════════════════════════════
  // 舊系統相容（deprecated）
  // ═══════════════════════════════════════════

  /// @deprecated 使用 harvest() 代替
  List<IngredientDefinition> getAvailableIngredients(BlockColor color) {
    final bottle = _bottles[color];
    if (bottle == null) return [];
    return IngredientDefinitions.getAvailable(color, bottle.level);
  }

  /// @deprecated 使用 harvest() 代替
  ConvertResult? convertIngredient(
    BlockColor bottleColor,
    String ingredientId,
    PlayerData playerData,
  ) {
    final bottle = _bottles[bottleColor];
    if (bottle == null) return null;

    final ingredient = IngredientDefinitions.getById(ingredientId);
    if (ingredient == null) return null;
    if (ingredient.bottleColor != bottleColor) return null;
    if (ingredient.bottleLevelRequired > bottle.level) return null;
    if (bottle.currentEnergy < ingredient.energyCost) return null;

    bottle.consumeEnergy(ingredient.energyCost);
    playerData.ingredients[ingredientId] =
        (playerData.ingredients[ingredientId] ?? 0) + 1;

    final isCritical = _random.nextDouble() < baseCritChance;
    IngredientDefinition? bonusIngredient;
    if (isCritical) {
      bonusIngredient = _getCritBonus(bottleColor, ingredient, bottle.level);
      if (bonusIngredient != null) {
        playerData.ingredients[bonusIngredient.id] =
            (playerData.ingredients[bonusIngredient.id] ?? 0) + 1;
      }
    }

    notifyListeners();
    _save();

    return ConvertResult(
      ingredient: ingredient,
      isCritical: isCritical,
      bonusIngredient: bonusIngredient,
    );
  }

  IngredientDefinition? _getCritBonus(
    BlockColor color,
    IngredientDefinition current,
    int bottleLevel,
  ) {
    final allInBottle = IngredientDefinitions.getByBottleColor(color);
    final higherTier = allInBottle
        .where((i) =>
            i.tier.index > current.tier.index &&
            i.bottleLevelRequired <= bottleLevel)
        .toList();
    if (higherTier.isNotEmpty) {
      return higherTier[_random.nextInt(higherTier.length)];
    }
    return current;
  }

  /// @deprecated 使用 setCurrentDessert() 代替
  void setDefaultIngredient(BlockColor color, String? ingredientId) {
    final bottle = _bottles[color];
    if (bottle == null) return;
    // 映射到新系統：忽略，不再設定食材
    notifyListeners();
    _save();
  }

  /// @deprecated 使用 getCurrentDessert() 代替
  IngredientDefinition? getDefaultIngredient(BlockColor color) {
    final bottle = _bottles[color];
    if (bottle == null) return null;
    if (bottle.currentDessertId != null) {
      // 新系統：不再回傳食材
    }
    final available = getAvailableIngredients(color);
    if (available.isEmpty) return null;
    available.sort((a, b) => a.energyCost.compareTo(b.energyCost));
    return available.first;
  }

  /// @deprecated 使用 harvest() 代替
  Map<String, int> convertAllDefault(PlayerData playerData) {
    // 委派給 harvest 然後返回相容格式
    final result = harvest(playerData);
    final compat = <String, int>{};
    for (final entry in result.dessertsProduced.entries) {
      final recipe = DessertDefinitions.getById(entry.key);
      if (recipe != null) {
        compat[recipe.name] = entry.value;
      }
    }
    return compat;
  }

  // ═══════════════════════════════════════════
  // 瓶子升級（不變）
  // ═══════════════════════════════════════════

  bool upgradeBottle(BlockColor color, PlayerData playerData) {
    final bottle = _bottles[color];
    if (bottle == null) return false;
    if (bottle.level >= BottleDefinitions.maxLevel) return false;

    final targetLevel = bottle.level + 1;
    final levelData = BottleDefinitions.getLevelData(targetLevel);

    if (levelData.stageGateId != null) {
      final progress = playerData.stageProgress[levelData.stageGateId!];
      if (progress == null || !progress.cleared) return false;
    }

    if (playerData.gold < levelData.upgradeCostGold) return false;

    final materials = BottleDefinitions.getUpgradeMaterials(targetLevel, color);
    for (final entry in materials.entries) {
      if ((playerData.materials[entry.key] ?? 0) < entry.value) return false;
    }

    playerData.gold -= levelData.upgradeCostGold;
    for (final entry in materials.entries) {
      playerData.materials[entry.key] =
          (playerData.materials[entry.key] ?? 0) - entry.value;
    }

    bottle.level = targetLevel;
    notifyListeners();
    _save();
    return true;
  }

  bool canUpgrade(BlockColor color, PlayerData playerData) {
    final bottle = _bottles[color];
    if (bottle == null || bottle.level >= BottleDefinitions.maxLevel) {
      return false;
    }

    final targetLevel = bottle.level + 1;
    final levelData = BottleDefinitions.getLevelData(targetLevel);

    if (levelData.stageGateId != null) {
      final progress = playerData.stageProgress[levelData.stageGateId!];
      if (progress == null || !progress.cleared) return false;
    }
    if (playerData.gold < levelData.upgradeCostGold) return false;

    final materials = BottleDefinitions.getUpgradeMaterials(targetLevel, color);
    for (final entry in materials.entries) {
      if ((playerData.materials[entry.key] ?? 0) < entry.value) return false;
    }
    return true;
  }

  Future<void> _save() async {
    final storage = LocalStorageService.instance;
    final json = <String, dynamic>{};
    for (final entry in _bottles.entries) {
      json[entry.key.name] = entry.value.toJson();
    }
    await storage.setJson('bottle_states', json);
  }
}

/// @deprecated 舊版轉換結果
class ConvertResult {
  final IngredientDefinition ingredient;
  final bool isCritical;
  final IngredientDefinition? bonusIngredient;

  const ConvertResult({
    required this.ingredient,
    required this.isCritical,
    this.bonusIngredient,
  });
}
