/// 玩家資料 Provider
/// 管理玩家資料的載入、儲存、角色操作
import 'package:flutter/foundation.dart';
import '../../../config/cat_agent_data.dart';
import '../../../core/models/cat_agent.dart';
import '../../../core/models/player_data.dart';
import '../../../core/services/local_storage.dart';

class PlayerProvider extends ChangeNotifier {
  PlayerData _data = PlayerData.newPlayer();
  PlayerData get data => _data;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// 初始化：載入存檔
  Future<void> init() async {
    await LocalStorageService.instance.init();
    _data = LocalStorageService.instance.loadPlayerData();
    _isInitialized = true;
    notifyListeners();
  }

  /// 儲存資料
  Future<void> _save() async {
    await LocalStorageService.instance.savePlayerData(_data);
  }

  // ─── 角色操作 ───

  /// 取得角色定義 + 實例的完整資訊
  List<AgentInfo> get allAgentInfos {
    return CatAgentData.allAgents.map((def) {
      final instance = _data.agents[def.id];
      return AgentInfo(
        definition: def,
        instance: instance,
      );
    }).toList();
  }

  /// 取得已解鎖的角色
  List<AgentInfo> get unlockedAgents {
    return allAgentInfos.where((a) => a.isUnlocked).toList();
  }

  /// 取得當前隊伍的角色資訊
  List<AgentInfo> get teamAgents {
    return _data.team
        .map((id) {
          final def = CatAgentData.getById(id);
          if (def == null) return null;
          return AgentInfo(
            definition: def,
            instance: _data.agents[id],
          );
        })
        .whereType<AgentInfo>()
        .toList();
  }

  /// 解鎖角色
  Future<bool> unlockAgent(String agentId) async {
    final def = CatAgentData.getById(agentId);
    if (def == null) return false;

    // 檢查是否已解鎖
    if (_data.agents[agentId]?.isUnlocked == true) return false;

    // 檢查金幣
    if (_data.gold < def.unlockCondition.goldCost) return false;

    // 檢查鑽石
    if (_data.diamonds < def.unlockCondition.diamondCost) return false;

    // 檢查關卡進度
    if (def.unlockCondition.stageRequirement != null) {
      final progress = _data.stageProgress[def.unlockCondition.stageRequirement!];
      if (progress == null || !progress.cleared) return false;
      if (def.unlockCondition.requireAllStars == true && progress.stars < 3) {
        return false;
      }
    }

    // 扣除貨幣
    _data.gold -= def.unlockCondition.goldCost;
    _data.diamonds -= def.unlockCondition.diamondCost;

    // 解鎖角色
    _data.agents[agentId] = CatAgentInstance(
      definitionId: agentId,
      isUnlocked: true,
    );

    // 自動加入隊伍（如果隊伍未滿）
    if (_data.team.length < 3 && !_data.team.contains(agentId)) {
      _data.team.add(agentId);
    }

    await _save();
    notifyListeners();
    return true;
  }

  /// 升級角色
  Future<bool> levelUpAgent(String agentId, int expToAdd) async {
    final instance = _data.agents[agentId];
    if (instance == null || !instance.isUnlocked) return false;

    final def = CatAgentData.getById(agentId);
    if (def == null) return false;

    if (instance.level >= def.maxLevel) return false;

    instance.currentExp += expToAdd;

    // 檢查升級
    while (instance.level < def.maxLevel) {
      final required = def.expRequiredForLevel(instance.level + 1) -
          def.expRequiredForLevel(instance.level);
      if (instance.currentExp >= required) {
        instance.currentExp -= required;
        instance.level++;
      } else {
        break;
      }
    }

    await _save();
    notifyListeners();
    return true;
  }

  /// 設定隊伍
  Future<void> setTeam(List<String> agentIds) async {
    // 驗證：最多 3 個，且都已解鎖
    final validIds = agentIds.where((id) {
      return _data.agents[id]?.isUnlocked == true;
    }).take(3).toList();

    _data.team = validIds;
    await _save();
    notifyListeners();
  }

  /// 在隊伍中加入/移除角色
  Future<void> toggleTeamMember(String agentId) async {
    if (_data.team.contains(agentId)) {
      // 移除（但至少保留 1 個）
      if (_data.team.length > 1) {
        _data.team.remove(agentId);
      }
    } else if (_data.team.length < 3) {
      // 加入（最多 3 個）
      if (_data.agents[agentId]?.isUnlocked == true) {
        _data.team.add(agentId);
      }
    }
    await _save();
    notifyListeners();
  }

  // ─── 貨幣操作 ───

  Future<void> addGold(int amount) async {
    _data.gold += amount;
    await _save();
    notifyListeners();
  }

  Future<void> addDiamonds(int amount) async {
    _data.diamonds += amount;
    await _save();
    notifyListeners();
  }

  // ─── 體力操作 ───

  bool get hasEnoughStamina => _data.stamina > 0;

  Future<bool> consumeStamina(int amount) async {
    if (_data.consumeStamina(amount)) {
      await _save();
      notifyListeners();
      return true;
    }
    return false;
  }

  /// 刷新體力（計算離線恢復）
  void refreshStamina() {
    _data.recoverStamina();
    notifyListeners();
  }
}

/// 角色資訊（定義 + 實例的組合）
class AgentInfo {
  final CatAgentDefinition definition;
  final CatAgentInstance? instance;

  const AgentInfo({
    required this.definition,
    this.instance,
  });

  bool get isUnlocked => instance?.isUnlocked == true;
  int get level => instance?.level ?? 1;
  int get currentExp => instance?.currentExp ?? 0;

  int get atk => definition.atkAtLevel(level);
  int get def => definition.defAtLevel(level);
  int get hp => definition.hpAtLevel(level);
}
