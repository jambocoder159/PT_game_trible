import 'dart:math';
import 'package:flutter/foundation.dart';
import '../../../core/models/block.dart';
import '../../../core/models/cat_data.dart';
import '../../../core/models/material.dart';
import '../../../core/models/player_data.dart';
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
  (List<CatReward>, int)? collectAllRewards(String catId, int playerLevel, {PlayerData? playerData}) {
    final cat = _cats[catId];
    if (cat == null || !cat.isFull(playerLevel)) return null;

    final chestCount = cat.chestCount(playerLevel);
    if (chestCount <= 0) return null;

    // 為每個寶箱生成獎勵
    final rewards = <CatReward>[];
    for (int i = 0; i < chestCount; i++) {
      rewards.add(_generateReward(playerLevel, playerData: playerData));
    }

    // 扣除已開的寶箱對應的飼料，保留剩餘
    cat.currentFood -= chestCount * cat.maxFood(playerLevel);
    if (cat.currentFood < 0) cat.currentFood = 0;

    notifyListeners();
    _save();

    return (rewards, chestCount);
  }

  /// 根據玩家等級產生獎勵（同時產出素材到 PlayerData）
  CatReward _generateReward(int playerLevel, {PlayerData? playerData}) {
    // 基礎金幣獎勵
    int goldAmount = 10 + playerLevel * 5;
    int rarity = 1;

    if (playerLevel >= 10) {
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

    // 產出實際素材到 PlayerData
    if (playerData != null) {
      switch (rarity) {
        case 1:
          _addMaterial(playerData, GameMaterial.commonShard, 2 + _random.nextInt(2));
          if (_random.nextDouble() < 0.15) {
            _addMaterial(playerData, GameMaterial.talentScroll, 1);
          }
          break;
        case 2:
          _addMaterial(playerData, GameMaterial.advancedShard, 1 + _random.nextInt(2));
          if (_random.nextDouble() < 0.2) {
            _addMaterial(playerData, GameMaterial.skillCore, 1);
          }
          break;
        case 3:
          _addMaterial(playerData, GameMaterial.rareShard, 1);
          _addMaterial(playerData, GameMaterial.passiveGem, 1);
          if (_random.nextDouble() < 0.3) {
            _addMaterial(playerData, GameMaterial.skillCore, 1);
          }
          break;
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

  void _addMaterial(PlayerData data, GameMaterial type, int amount) {
    final key = type.name;
    data.materials[key] = (data.materials[key] ?? 0) + amount;
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
