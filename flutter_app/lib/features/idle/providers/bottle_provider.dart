import 'dart:math';
import 'package:flutter/foundation.dart';
import '../../../config/ingredient_data.dart';
import '../../../core/models/block.dart';
import '../../../core/models/bottle_data.dart';
import '../../../core/models/ingredient.dart';
import '../../../core/models/player_data.dart';
import '../../../core/services/local_storage.dart';

/// 轉換結果
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

/// 魔法瓶管理 Provider — 能量累積、食材轉換、瓶子升級
class BottleProvider extends ChangeNotifier {
  final Map<BlockColor, BottleStatus> _bottles = {};
  bool _isInitialized = false;
  final _random = Random();

  /// 爆擊基礎機率
  static const double baseCritChance = 0.15;

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

  /// 取得某瓶在當前等級下可產出的食材
  List<IngredientDefinition> getAvailableIngredients(BlockColor color) {
    final bottle = _bottles[color];
    if (bottle == null) return [];
    return IngredientDefinitions.getAvailable(color, bottle.level);
  }

  /// 轉換能量為食材
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

    // 扣除能量
    bottle.consumeEnergy(ingredient.energyCost);

    // 加入食材到玩家庫存
    playerData.ingredients[ingredientId] =
        (playerData.ingredients[ingredientId] ?? 0) + 1;

    // 爆擊判定
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

  /// 爆擊額外產出：同瓶更高稀有度食材，或同品 +1
  IngredientDefinition? _getCritBonus(
    BlockColor color,
    IngredientDefinition current,
    int bottleLevel,
  ) {
    final allInBottle = IngredientDefinitions.getByBottleColor(color);
    // 找比目前更高稀有度且已解鎖的食材
    final higherTier = allInBottle
        .where((i) =>
            i.tier.index > current.tier.index &&
            i.bottleLevelRequired <= bottleLevel)
        .toList();
    if (higherTier.isNotEmpty) {
      return higherTier[_random.nextInt(higherTier.length)];
    }
    // 已是最高稀有度：額外 +1 同品
    return current;
  }

  /// 升級瓶子
  /// 回傳是否成功
  bool upgradeBottle(
    BlockColor color,
    PlayerData playerData,
  ) {
    final bottle = _bottles[color];
    if (bottle == null) return false;
    if (bottle.level >= BottleDefinitions.maxLevel) return false;

    final targetLevel = bottle.level + 1;
    final levelData = BottleDefinitions.getLevelData(targetLevel);

    // 檢查關卡門檻
    if (levelData.stageGateId != null) {
      final progress = playerData.stageProgress[levelData.stageGateId!];
      if (progress == null || !progress.cleared) return false;
    }

    // 檢查金幣
    if (playerData.gold < levelData.upgradeCostGold) return false;

    // 檢查材料
    final materials = BottleDefinitions.getUpgradeMaterials(targetLevel, color);
    for (final entry in materials.entries) {
      if ((playerData.materials[entry.key] ?? 0) < entry.value) return false;
    }

    // 扣除金幣和材料
    playerData.gold -= levelData.upgradeCostGold;
    for (final entry in materials.entries) {
      playerData.materials[entry.key] =
          (playerData.materials[entry.key] ?? 0) - entry.value;
    }

    // 升級
    bottle.level = targetLevel;

    notifyListeners();
    _save();
    return true;
  }

  /// 檢查瓶子是否可升級
  bool canUpgrade(BlockColor color, PlayerData playerData) {
    final bottle = _bottles[color];
    if (bottle == null || bottle.level >= BottleDefinitions.maxLevel) return false;

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
