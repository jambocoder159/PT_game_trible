/// 戰鬥 Provider
/// 管理闖關模式的戰鬥狀態，與 GameProvider 協同工作
/// GameProvider 負責三消核心，BattleProvider 負責戰鬥層
import 'package:flutter/foundation.dart';
import '../../../config/cat_agent_data.dart';
import '../../../config/evolution_data.dart';
import '../../../config/passive_skill_data.dart';
import '../../../config/stage_data.dart';
import '../../../config/talent_tree_data.dart';
import '../../../core/engine/battle_engine.dart';
import '../../../core/models/battle_state.dart';
import '../../../core/models/block.dart';
import '../../../core/models/cat_agent.dart';
import '../../../core/models/enemy.dart';
import '../../../core/models/player_data.dart';

/// 戰鬥事件（給 UI 播放動畫用）
class BattleEvent {
  final BattleEventType type;
  final String message;
  final int value; // 傷害值或回復值
  final BlockColor? color; // 對應的方塊顏色

  const BattleEvent({
    required this.type,
    required this.message,
    this.value = 0,
    this.color,
  });
}

enum BattleEventType {
  damage, // 對敵人造成傷害
  enemyAttack, // 敵人攻擊
  skillActivated, // 技能施放
  enemyKilled, // 敵人被擊敗
  heal, // 回復
  shield, // 護盾
  victory, // 勝利
  defeat, // 失敗
}

/// 放置效果回呼（由 GameProvider 執行棋盤操作）
typedef OnBoardEffectRequested = Future<void> Function(SkillBoardEffect effect, BlockColor agentColor);

class BattleProvider extends ChangeNotifier {
  BattleState? _battleState;
  BattleState? get battleState => _battleState;

  /// 放置效果回呼（戰鬥畫面設定）
  OnBoardEffectRequested? onBoardEffectRequested;

  StageDefinition? _currentStage;
  StageDefinition? get currentStage => _currentStage;

  bool get isInBattle => _battleState != null && !_battleState!.isBattleOver;
  bool get isBattleOver => _battleState?.isBattleOver == true;
  bool get isVictory => _battleState?.isVictory == true;

  // 事件佇列
  final List<BattleEvent> _events = [];
  List<BattleEvent> consumeEvents() {
    final events = List<BattleEvent>.from(_events);
    _events.clear();
    return events;
  }

  /// 開始戰鬥
  void startBattle({
    required StageDefinition stage,
    required List<String> teamAgentIds,
    required PlayerData playerData,
  }) {
    _currentStage = stage;

    // 建立隊伍
    final team = <BattleAgent>[];
    for (final id in teamAgentIds) {
      final def = CatAgentData.getById(id);
      final instance = playerData.agents[id];
      if (def != null && instance != null && instance.isUnlocked) {
        // 載入天賦數據
        final talents = instance.unlockedTalentIds
            .map((tid) => TalentTreeData.getNodeById(tid))
            .nonNulls
            .toList();
        // 載入被動數據
        final passives = instance.equippedPassiveIds
            .map((pid) => PassiveSkillData.getPassiveById(pid))
            .nonNulls
            .toList();

        // 計算進化倍率
        double evoAtk = 1.0, evoDef = 1.0, evoHp = 1.0;
        if (instance.evolutionStage > 0) {
          final evo = EvolutionData.getEvolution(
            def.rarity.name, instance.evolutionStage);
          if (evo != null) {
            evoAtk = evo.atkMultiplier;
            evoDef = evo.defMultiplier;
            evoHp = evo.hpMultiplier;
          }
        }

        team.add(BattleAgent(
          definition: def,
          level: instance.level,
          skillTier: instance.skillTier,
          evolutionStage: instance.evolutionStage,
          evoAtkMult: evoAtk,
          evoDefMult: evoDef,
          evoHpMult: evoHp,
          unlockedTalents: talents,
          equippedPassives: passives,
        ));
      }
    }

    // 如果隊伍為空，至少放一個預設角色
    if (team.isEmpty) {
      team.add(BattleAgent(
        definition: CatAgentData.blazeAgent,
        level: 1,
      ));
    }

    // 建立敵人實例
    final enemies = stage.enemies.map((def) {
      // 根據章節調整難度
      final hpMult = 1.0 + (stage.chapter - 1) * 0.15;
      final atkMult = 1.0 + (stage.chapter - 1) * 0.1;
      return EnemyInstance.fromDefinition(def,
          hpMultiplier: hpMult, atkMultiplier: atkMult);
    }).toList();

    // 計算隊伍總 HP
    final totalHp = team.fold<int>(0, (sum, a) => sum + a.hp);

    _battleState = BattleState(
      team: team,
      enemies: enemies,
      teamMaxHp: totalHp,
      teamCurrentHp: totalHp,
    );

    notifyListeners();
  }

  /// 處理三消結果 — 由 GameProvider 呼叫
  /// matchedBlocks: 此次消除的方塊顏色 → 數量
  void onMatchesProcessed(Map<BlockColor, int> matchedBlocks, int combo) {
    if (_battleState == null || _battleState!.isBattleOver) return;

    final result = BattleEngine.processMatches(
      _battleState!,
      matchedBlocks,
      combo,
    );

    // 發送傷害事件
    for (final entry in result.damageByColor.entries) {
      _events.add(BattleEvent(
        type: BattleEventType.damage,
        message: '-${entry.value}',
        value: entry.value,
        color: entry.key,
      ));
    }

    if (result.enemyKilled) {
      _events.add(BattleEvent(
        type: BattleEventType.enemyKilled,
        message: '敵人被擊敗！',
      ));
    }

    if (_battleState!.allEnemiesDead) {
      _events.add(const BattleEvent(
        type: BattleEventType.victory,
        message: '任務完成！',
      ));
    }

    notifyListeners();
  }

  /// 處理回合結束（玩家操作後）— 回合開始效果 + 敵人回擊
  void onTurnEnd() {
    if (_battleState == null || _battleState!.isBattleOver) return;

    _battleState!.turnCount++;

    // 處理回合開始效果（DoT、HoT、被動）
    BattleEngine.processTurnStart(_battleState!);

    final result = BattleEngine.processEnemyTurn(_battleState!);

    if (result.enemyAttacked) {
      _events.add(BattleEvent(
        type: BattleEventType.enemyAttack,
        message: '-${result.enemyDamage}',
        value: result.enemyDamage,
      ));

      if (_battleState!.isTeamDead) {
        _events.add(const BattleEvent(
          type: BattleEventType.defeat,
          message: '任務失敗...',
        ));
      }
    }

    notifyListeners();
  }

  /// 施放技能
  void activateSkill(int agentIndex) {
    if (_battleState == null || _battleState!.isBattleOver) return;
    if (agentIndex >= _battleState!.team.length) return;

    final agent = _battleState!.team[agentIndex];
    if (!agent.isSkillReady) return;

    final result = BattleEngine.activateSkill(_battleState!, agent);

    // 根據技能類型選擇事件類型
    BattleEventType eventType;
    if (result.hpHealed > 0 && result.damageDealt == 0) {
      eventType = BattleEventType.heal;
    } else if (result.shieldTurns > 0 && result.damageDealt == 0) {
      eventType = BattleEventType.shield;
    } else {
      eventType = BattleEventType.skillActivated;
    }

    _events.add(BattleEvent(
      type: eventType,
      message: result.description,
      value: result.damageDealt + result.hpHealed,
    ));

    if (_battleState!.allEnemiesDead) {
      _events.add(const BattleEvent(
        type: BattleEventType.victory,
        message: '任務完成！',
      ));
    }

    notifyListeners();

    // 執行放置效果（操作棋盤）
    if (result.boardEffect != null && result.agentColor != null) {
      onBoardEffectRequested?.call(result.boardEffect!, result.agentColor!);
    }
  }

  /// 結束戰鬥
  void endBattle() {
    _battleState = null;
    _currentStage = null;
    _events.clear();
    notifyListeners();
  }
}
