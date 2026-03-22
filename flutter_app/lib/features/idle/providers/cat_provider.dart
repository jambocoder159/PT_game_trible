import 'dart:math';
import 'package:flutter/foundation.dart';
import '../../../core/models/block.dart';
import '../../../core/models/cat_data.dart';
import '../../../core/services/local_storage.dart';

/// 貓咪管理 Provider — 飼料累積、餵食、收穫
class CatProvider extends ChangeNotifier {
  final Map<String, CatStatus> _cats = {};
  bool _isInitialized = false;
  final _random = Random();

  Map<String, CatStatus> get cats => _cats;
  bool get isInitialized => _isInitialized;

  /// 初始化 — 從 localStorage 載入或建立預設貓咪
  Future<void> init() async {
    final storage = LocalStorageService.instance;
    final json = storage.getJson('cat_states');

    if (json != null && json is Map<String, dynamic>) {
      for (final entry in json.entries) {
        _cats[entry.key] = CatStatus.fromJson(
          entry.value as Map<String, dynamic>,
        );
      }
    }

    // 確保 5 隻貓都存在
    for (final def in CatDefinitions.all) {
      _cats.putIfAbsent(def.id, () => CatStatus(definitionId: def.id));
    }

    _isInitialized = true;
    notifyListeners();
  }

  /// 取得對應顏色的貓咪
  CatStatus? getCatByColor(BlockColor color) {
    final def = CatDefinitions.getByColor(color);
    if (def == null) return null;
    return _cats[def.id];
  }

  /// 餵食對應顏色的貓咪（不設上限，允許累積多個寶箱）
  void feedCat(BlockColor color, int amount, int playerLevel) {
    final cat = getCatByColor(color);
    if (cat == null) return;

    cat.currentFood += amount;
    cat.totalFed += amount;

    notifyListeners();
    _save();
  }

  /// 批量餵食（消除結算時用）
  void feedMultiple(Map<BlockColor, int> foodMap, int playerLevel) {
    for (final entry in foodMap.entries) {
      final cat = getCatByColor(entry.key);
      if (cat == null) continue;

      cat.currentFood += entry.value;
      cat.totalFed += entry.value;
    }

    notifyListeners();
    _save();
  }

  /// 收穫所有累積的寶箱（批量開啟）
  /// 回傳 (獎勵列表, 寶箱數量)
  (List<CatReward>, int)? collectAllRewards(String catId, int playerLevel) {
    final cat = _cats[catId];
    if (cat == null || !cat.isFull(playerLevel)) return null;

    final chestCount = cat.chestCount(playerLevel);
    if (chestCount <= 0) return null;

    // 為每個寶箱生成獎勵
    final rewards = <CatReward>[];
    for (int i = 0; i < chestCount; i++) {
      rewards.add(_generateReward(playerLevel));
    }

    // 扣除已開的寶箱對應的飼料，保留剩餘
    cat.currentFood -= chestCount * cat.maxFood(playerLevel);
    if (cat.currentFood < 0) cat.currentFood = 0;

    notifyListeners();
    _save();

    return (rewards, chestCount);
  }

  /// 根據玩家等級產生獎勵
  CatReward _generateReward(int playerLevel) {
    // 基礎金幣獎勵
    int goldAmount = 10 + playerLevel * 5;
    int rarity = 1;

    if (playerLevel >= 10) {
      // 高等級有機率獲得更好獎勵
      final roll = _random.nextDouble();
      if (roll < 0.15) {
        rarity = 3;
        goldAmount = 50 + playerLevel * 10;
      } else if (roll < 0.45) {
        rarity = 2;
        goldAmount = 25 + playerLevel * 7;
      }
    } else if (playerLevel >= 5) {
      final roll = _random.nextDouble();
      if (roll < 0.2) {
        rarity = 2;
        goldAmount = 20 + playerLevel * 5;
      }
    }

    final names = {
      1: '普通素材',
      2: '進階素材',
      3: '稀有素材',
    };

    return CatReward(
      name: names[rarity] ?? '普通素材',
      quantity: goldAmount,
      rarity: rarity,
    );
  }

  Future<void> _save() async {
    final storage = LocalStorageService.instance;
    final json = <String, dynamic>{};
    for (final entry in _cats.entries) {
      json[entry.key] = entry.value.toJson();
    }
    await storage.setJson('cat_states', json);
  }
}
