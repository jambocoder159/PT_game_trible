/// 數值配置載入器
/// 從 JSON 資源檔載入遊戲數值，失敗時使用預設值
import 'dart:convert';
import 'package:flutter/services.dart';
import 'balance_config.dart';
import 'battle_params.dart';
import 'evolution_data.dart';
import 'game_modes.dart';
import 'ingredient_data.dart';
import '../core/models/bottle_data.dart';

class BalanceLoader {
  BalanceLoader._();

  /// 從 assets 載入所有數值配置
  static Future<void> loadFromAssets() async {
    await Future.wait([
      _loadJson('battle_params.json', (json) {
        BalanceConfig.instance.battleParams = BattleParams.fromJson(json);
      }),
      _loadJson('evolution.json', (json) {
        EvolutionData.loadFromJson(json);
      }),
      _loadJson('ingredients.json', (json) {
        IngredientDefinitions.loadFromJson(json);
      }),
      _loadJson('desserts.json', (json) {
        DessertDefinitions.loadFromJson(json);
      }),
      _loadJson('bottles.json', (json) {
        BottleDefinitions.loadFromJson(json);
      }),
      _loadJson('game_modes.json', (json) {
        GameModes.loadFromJson(json);
      }),
      // player_config.json 和 chest_drops.json 由各自的 provider 在需要時讀取
      // 或在未來整合時加入
    ]);
  }

  /// 通用 JSON 載入：失敗時 gracefully fallback 到預設值
  static Future<void> _loadJson(
    String fileName,
    void Function(Map<String, dynamic>) onLoad,
  ) async {
    try {
      final jsonStr = await rootBundle.loadString('assets/balance/$fileName');
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      onLoad(json);
    } catch (e) {
      assert(() {
        // ignore: avoid_print
        print('[BalanceLoader] 載入 $fileName 失敗，使用預設值: $e');
        return true;
      }());
    }
  }
}
