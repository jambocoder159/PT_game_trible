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
import 'game_provider.dart' show EliminatedBlockInfo;

/// 戰鬥事件（給 UI 播放動畫用）
class BattleEvent {
  final BattleEventType type;
  final String message;
  final int value; // 傷害值或回復值
  final BlockColor? color; // 對應的方塊顏色
  final int? attackerIndex; // 攻擊者在 team/enemies 中的 index
  final int? targetIndex; // 目標在 enemies/team 中的 index
  final bool isPlayerAttack; // true=我方攻擊, false=敵方攻擊
  final String? emoji; // 攻擊者 emoji（衝撞動畫用）

  // ── 傷害分解 ──
  final int preComboDamage;   // combo 前累積傷害
  final int combo;
  final double comboMult;
  final double attributeMult;

  // ── 消除方塊位置（boardAttack 用）──
  final List<EliminatedBlockInfo> eliminatedBlocks;

  const BattleEvent({
    required this.type,
    required this.message,
    this.value = 0,
    this.color,
    this.attackerIndex,
    this.targetIndex,
    this.isPlayerAttack = false,
    this.emoji,
    this.preComboDamage = 0,
    this.combo = 0,
    this.comboMult = 1.0,
    this.attributeMult = 1.0,
    this.eliminatedBlocks = const [],
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
  autoAttack, // 角色自動攻擊（回合結束打出）
  boardAttack, // 棋盤傷害（粒子飛向敵人）
  damageAccum, // 角色累積傷害（頭像跳數字）
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
  // 攻擊動畫事件佇列（供左側面板衝撞動畫使用）
  final List<BattleEvent> _attackAnimEvents = [];

  /// 消費一般事件（技能、回復、勝敗等，供 _SkillEffectBar 使用）
  List<BattleEvent> consumeEvents() {
    final events = List<BattleEvent>.from(_events);
    _events.clear();
    return events;
  }

  /// 消費攻擊動畫事件（autoAttack/enemyAttack，供衝撞動畫使用）
  List<BattleEvent> consumeAttackEvents() {
    final events = List<BattleEvent>.from(_attackAnimEvents);
    _attackAnimEvents.clear();
    return events;
  }

  /// UI 命中時呼叫：扣血 + 檢查擊殺/勝利
  bool applyHitDamage(int damage) {
    if (_battleState == null) return false;

    final killed = BattleEngine.applyHitDamage(_battleState!, damage);

    if (killed) {
      _events.add(const BattleEvent(
        type: BattleEventType.enemyKilled,
        message: '敵人被擊敗！',
      ));
      if (_battleState!.allEnemiesDead) {
        _events.add(const BattleEvent(
          type: BattleEventType.victory,
          message: '任務完成！',
        ));
      }
    }

    notifyListeners();
    return killed;
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
      final hpMult = 1.0 + (stage.chapter - 1) * 0.25;
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

    // 初始化敵人技能狀態（屬性壓制光環等）
    _battleState!.initEnemySkills();

    notifyListeners();
  }

  /// 處理三消結果 — 由 GameProvider 呼叫
  /// 每次連鎖消除 = 1 tick，消方塊驅動時間軸
  void onMatchesProcessed(
    Map<BlockColor, int> matchedBlocks,
    int combo, {
    List<EliminatedBlockInfo> eliminatedBlocks = const [],
  }) {
    if (_battleState == null || _battleState!.isBattleOver) return;

    final result = BattleEngine.processTick(
      _battleState!,
      matchedBlocks,
      combo,
    );

    // 發送棋盤傷害事件（粒子從消除位置飛向敵人）
    if (result.boardDamage > 0) {
      final boardEvent = BattleEvent(
        type: BattleEventType.boardAttack,
        message: '-${result.boardDamage}',
        value: result.boardDamage,
        targetIndex: _battleState!.currentEnemyIndex,
        eliminatedBlocks: eliminatedBlocks,
      );
      _events.add(boardEvent);
      _attackAnimEvents.add(boardEvent);
    }

    // 發送角色累積傷害事件（頭像跳數字）
    for (final accum in result.accumEvents) {
      final attackerIdx = _battleState!.team.indexWhere(
          (a) => a.definition.id == accum.agentId);
      _events.add(BattleEvent(
        type: BattleEventType.damageAccum,
        message: '+${accum.damage}',
        value: accum.damage,
        attackerIndex: attackerIdx,
        isPlayerAttack: true,
      ));
      _attackAnimEvents.add(BattleEvent(
        type: BattleEventType.damageAccum,
        message: '+${accum.damage}',
        value: accum.damage,
        attackerIndex: attackerIdx,
        isPlayerAttack: true,
      ));
    }

    notifyListeners();
  }

  /// 處理回合結束（每次玩家操作後都會呼叫）
  /// 1. 統一打出累積的角色傷害（含 combo）
  /// 2. 敵人推進 countdown 並攻擊
  void onTurnEnd({bool hadMatches = true}) {
    if (_battleState == null || _battleState!.isBattleOver) return;

    // ── 打出累積傷害 ──
    final finalResult = BattleEngine.finalizeAttacks(_battleState!);
    for (final attack in finalResult.attacks) {
      final attackerIdx = _battleState!.team.indexWhere(
          (a) => a.definition.id == attack.attackerId);
      final targetIdx = _battleState!.currentEnemyIndex;
      final emoji = attackerIdx >= 0
          ? _battleState!.team[attackerIdx].definition.attribute.emoji
          : '⚔';
      final event = BattleEvent(
        type: BattleEventType.autoAttack,
        message: '-${attack.damage}',
        value: attack.damage,
        attackerIndex: attackerIdx,
        targetIndex: targetIdx,
        isPlayerAttack: true,
        emoji: emoji,
        preComboDamage: attack.preComboDamage,
        combo: attack.combo,
        comboMult: attack.comboMult,
        attributeMult: attack.attributeMult,
      );
      _events.add(event);
      _attackAnimEvents.add(event);
    }

    // 傷害延遲到 UI 命中時才扣，這裡不檢查 killed/victory
    // UI 會在 _onRushHit 中呼叫 applyHitDamage，再檢查勝敗

    _battleState!.turnCount++;

    // ── 敵方攻擊階段（整輪結束後統一處理） ──
    final enemyAttacks = BattleEngine.processEnemyPhase(_battleState!);
    for (final attack in enemyAttacks) {
      final attackerIdx = _battleState!.enemies.indexWhere(
          (e) => e.definition.id == attack.attackerId);
      final emoji = attackerIdx >= 0
          ? _battleState!.enemies[attackerIdx].definition.emoji
          : '👊';
      final event = BattleEvent(
        type: BattleEventType.enemyAttack,
        message: '-${attack.damage}',
        value: attack.damage,
        attackerIndex: attackerIdx,
        isPlayerAttack: false,
        emoji: emoji,
      );
      _events.add(event);
      _attackAnimEvents.add(event);
    }

    if (_battleState!.isTeamDead) {
      _events.add(const BattleEvent(
        type: BattleEventType.defeat,
        message: '任務失敗...',
      ));
    }

    // 處理持續效果（DoT、HoT、被動）
    BattleEngine.processTurnStart(_battleState!);

    notifyListeners();
  }

  /// 施放技能
  ///
  /// [useAttackOnly] 只使用攻擊/治療/護盾效果，不觸發方塊效果
  /// [useBoardOnly] 只使用方塊效果，不觸發攻擊效果
  void activateSkill(int agentIndex, {
    bool useAttackOnly = false,
    bool useBoardOnly = false,
  }) {
    if (_battleState == null || _battleState!.isBattleOver) return;
    if (agentIndex >= _battleState!.team.length) return;

    final agent = _battleState!.team[agentIndex];
    if (!agent.isSkillReady) return;

    final result = BattleEngine.activateSkill(_battleState!, agent);

    if (!useBoardOnly) {
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
    } else {
      // 僅方塊效果模式：加入提示事件
      _events.add(BattleEvent(
        type: BattleEventType.skillActivated,
        message: '${agent.definition.name} 發動方塊效果！',
        value: 0,
      ));
    }

    if (_battleState!.allEnemiesDead) {
      _events.add(const BattleEvent(
        type: BattleEventType.victory,
        message: '任務完成！',
      ));
    }

    // 記錄施放技能的角色 ID，供動畫使用
    _lastSkillAgentId = agent.definition.id;
    _lastSkillAgentName = agent.definition.name;
    _lastSkillName = agent.definition.skill.name;

    notifyListeners();

    // 執行放置效果（操作棋盤）
    if (!useAttackOnly && result.boardEffect != null && result.agentColor != null) {
      onBoardEffectRequested?.call(result.boardEffect!, result.agentColor!);
    }
  }

  /// 最近施放技能的角色資訊（供動畫使用）
  String? _lastSkillAgentId;
  String? _lastSkillAgentName;
  String? _lastSkillName;

  String? get lastSkillAgentId => _lastSkillAgentId;
  String? get lastSkillAgentName => _lastSkillAgentName;
  String? get lastSkillName => _lastSkillName;

  /// 消費（清除）技能動畫資訊
  void consumeSkillAnim() {
    _lastSkillAgentId = null;
    _lastSkillAgentName = null;
    _lastSkillName = null;
  }

  /// 結束戰鬥
  void endBattle() {
    _battleState = null;
    _currentStage = null;
    _events.clear();
    _attackAnimEvents.clear();
    notifyListeners();
  }
}
