import 'package:flutter/foundation.dart';
import '../../../core/services/local_storage.dart';
import '../../agents/providers/player_provider.dart';
import '../config/tutorial_config.dart';
import '../models/tutorial_state.dart';

/// 教學系統中央狀態管理
class TutorialProvider extends ChangeNotifier {
  static const _storageKey = 'tutorial_state';

  TutorialState _state = TutorialState.initial();
  bool _isInitialized = false;

  TutorialState get state => _state;
  bool get isInitialized => _isInitialized;
  TutorialPhase get currentPhase => _state.currentPhase;
  int get currentStep => _state.currentStep;
  int get currentSubStep => _state.currentSubStep;
  bool get isCompleted => _state.currentPhase == TutorialPhase.completed;

  /// 初始化，從本地存檔載入
  Future<void> init() async {
    final json = LocalStorageService.instance.getJson(_storageKey);
    if (json != null && json is Map<String, dynamic>) {
      _state = TutorialState.fromJson(json);
    } else {
      _state = TutorialState.initial();
    }
    _isInitialized = true;
    notifyListeners();
  }

  /// 儲存至本地
  Future<void> _save() async {
    await LocalStorageService.instance.setJson(_storageKey, _state.toJson());
  }

  /// 推進至下一步驟
  Future<void> advanceStep() async {
    _state.currentSubStep = 0;
    _state.currentStep++;
    await _save();
    notifyListeners();
  }

  /// 推進子步驟
  Future<void> advanceSubStep() async {
    _state.currentSubStep++;
    await _save();
    notifyListeners();
  }

  /// 設定步驟（直接跳到指定步驟）
  Future<void> setStep(int step, {int subStep = 0}) async {
    _state.currentStep = step;
    _state.currentSubStep = subStep;
    await _save();
    notifyListeners();
  }

  /// 推進至下一階段
  Future<void> advancePhase() async {
    final nextIdx = _state.currentPhase.index + 1;
    if (nextIdx < TutorialPhase.values.length) {
      _state.currentPhase = TutorialPhase.values[nextIdx];
      _state.currentStep = 0;
      _state.currentSubStep = 0;
      await _save();
      notifyListeners();
    }
  }

  /// 跳過當前階段（僅限可跳過的 Phase 0 和 Phase 2）
  Future<void> skipPhase() async {
    if (_state.currentPhase == TutorialPhase.phase0 ||
        _state.currentPhase == TutorialPhase.phase2) {
      await advancePhase();
    }
  }

  /// 更新小任務進度（Phase 1 Step 1.7）
  Future<void> incrementPastriesSold() async {
    _state.pastriesSold++;
    await _save();
    notifyListeners();
  }

  /// 更新戰鬥階段（Phase 3）
  Future<void> advanceBattleStage() async {
    _state.currentBattleStage++;
    await _save();
    notifyListeners();
  }

  /// 標記露露已被救出
  Future<void> markLuluRescued() async {
    _state.luluRescued = true;
    await _save();
    notifyListeners();
  }

  /// Phase 4 完成旗標
  Future<void> markTeamSetupDone() async {
    _state.teamSetupDone = true;
    await _save();
    notifyListeners();
  }

  Future<void> markUpgradeDone() async {
    _state.upgradeDone = true;
    await _save();
    notifyListeners();
  }

  Future<void> markAutoEliminateDone() async {
    _state.autoEliminateDone = true;
    await _save();
    notifyListeners();
  }

  Future<void> markDailyQuestDone() async {
    _state.dailyQuestDone = true;
    await _save();
    notifyListeners();
  }

  Future<void> markStaminaDone() async {
    _state.staminaDone = true;
    await _save();
    notifyListeners();
  }

  /// 完成教學（正常流程走完 & 跳過共用）
  /// 標記關卡 1-1 通過 + 發放獎勵
  Future<void> completeTutorial(
    PlayerProvider player, {
    List<String>? stagesToClear,
    String? agentToUnlock,
    bool skipAgentUnlock = false,
  }) async {
    _state.currentPhase = TutorialPhase.completed;
    await _save();

    await player.completeTutorial(
      bonusGold: TutorialConfig.rewardGold,
      bonusDiamonds: TutorialConfig.rewardDiamonds,
      stagesToClear: stagesToClear ?? ['1-1'],
      agentToUnlock: skipAgentUnlock ? null : (agentToUnlock ?? TutorialConfig.luluAgentId),
    );

    notifyListeners();
  }

  /// 跳過整個教學（向下相容別名）
  Future<void> skipEntireTutorial(PlayerProvider player) async {
    await completeTutorial(player);
  }

  /// 重設教學（GM 用）
  Future<void> resetTutorial() async {
    _state = TutorialState.initial();
    await _save();
    notifyListeners();
  }

  /// 清除本地存檔
  static Future<void> clearStorage() async {
    await LocalStorageService.instance
        .setJson(_storageKey, null);
  }
}
