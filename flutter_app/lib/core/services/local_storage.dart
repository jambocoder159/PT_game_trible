/// 本地存檔服務
/// MVP 版本：使用 SharedPreferences 儲存玩家資料
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/player_data.dart';

class LocalStorageService {
  static const _playerDataKey = 'player_data';
  static LocalStorageService? _instance;

  SharedPreferences? _prefs;

  LocalStorageService._();

  static LocalStorageService get instance {
    _instance ??= LocalStorageService._();
    return _instance!;
  }

  /// 初始化（必須在使用前呼叫）
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// 儲存玩家資料
  Future<void> savePlayerData(PlayerData data) async {
    final json = jsonEncode(data.toJson());
    await _prefs?.setString(_playerDataKey, json);
  }

  /// 載入玩家資料
  PlayerData loadPlayerData() {
    final jsonStr = _prefs?.getString(_playerDataKey);
    if (jsonStr == null) {
      return PlayerData.newPlayer();
    }
    try {
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      final data = PlayerData.fromJson(json);
      // 計算離線期間的體力恢復
      data.recoverStamina();
      // 檢查每日任務是否需要重置
      if (data.dailyQuests.needsReset) {
        data.dailyQuests.reset();
      }
      return data;
    } catch (_) {
      return PlayerData.newPlayer();
    }
  }

  /// 清除所有存檔（用於重置）
  Future<void> clearAll() async {
    await _prefs?.remove(_playerDataKey);
  }
}
