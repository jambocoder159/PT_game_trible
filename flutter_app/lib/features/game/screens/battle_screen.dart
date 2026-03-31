/// 戰鬥畫面（手機版優化）
/// 闖關模式：左側角色面板 + 右側棋盤，木質風格 UI
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../config/boss_dialogue_data.dart';
import '../../../config/cat_agent_data.dart';
import '../../../config/game_modes.dart';
import '../../../config/image_assets.dart';
import '../../../config/stage_data.dart';
import '../../../config/theme.dart';
import '../../../core/models/battle_state.dart';
import '../../../core/models/enemy.dart';
import '../../../core/models/game_state.dart';
import '../../../core/models/material.dart';
import '../../../core/services/local_storage.dart';
import '../../agents/providers/player_provider.dart';
import '../providers/battle_provider.dart';
import '../providers/game_provider.dart';
import '../widgets/combo_counter.dart';
import '../widgets/damage_counter.dart';
import '../widgets/game_board.dart';
import '../../agents/widgets/agent_unlock_animation.dart';
import '../widgets/cat_placeholder.dart';
import '../widgets/pause_menu.dart';

// ─── 點心屋風格配色（陽光鄉村木質） ───
const _woodLight = Color(0xFFFFE4B5);   // 蜂蜜金
const _woodMid = Color(0xFFDEB887);     // 小麥色
const _woodDark = Color(0xFFC49A6C);    // 暖木色
const _woodBorder = Color(0xFFA0764E);  // 深木邊框
const _panelBg = Color(0xFFFFE4B5);     // 蜂蜜金 (= AppTheme.bgSecondary)
const _gamePanelBg = Color(0xFFFFFFFF); // 純白 (= AppTheme.bgCard)

/// 戰鬥畫面
class BattleScreen extends StatefulWidget {
  final StageDefinition stage;
  /// 戰鬥結束回調（教學模式使用），若為 null 則用 Navigator.pop
  final VoidCallback? onBattleEnd;

  const BattleScreen({super.key, required this.stage, this.onBattleEnd});

  @override
  State<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends State<BattleScreen> {
  bool _resultSaved = false;
  BattleRewardResult? _reward;
  bool _boardOnLeft = false; // 預設棋盤在右側（截圖佈局）
  bool _victoryAnimPlaying = false; // 勝利爆炸演出中
  bool _showResult = false; // 顯示結算畫面
  final ValueNotifier<bool> _attackAnimPlaying = ValueNotifier(false);

  // Boss 對話演出
  bool _showBossIntro = false;

  // 技能橫幅動畫
  bool _showSkillBanner = false;
  String? _skillBannerAgentId;
  String? _skillBannerAgentName;
  String? _skillBannerSkillName;
  Color? _skillBannerColor;

  // 首戰引導
  int _battleGuideStep = -1; // -1=不顯示, 0=第一步, 1=第二步
  bool _isFirstBattle = false;

  @override
  void initState() {
    super.initState();
    _loadBoardPosition();
    // Boss 關（X-10）顯示對話演出
    if (widget.stage.stageNumber == 10 &&
        bossDialogues.containsKey(widget.stage.chapter)) {
      _showBossIntro = true;
    }
    // 首戰引導：1-1 且從未通過任何關卡
    final progress = context.read<PlayerProvider>().data.stageProgress;
    if (widget.stage.id == '1-1' && !progress.values.any((p) => p.cleared)) {
      _isFirstBattle = true;
      _battleGuideStep = 0;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initBattle();
    });
  }

  void _loadBoardPosition() {
    final saved = LocalStorageService.instance.getJson('battle_board_left');
    if (saved is bool) _boardOnLeft = saved;
  }

  void _toggleBoardPosition() {
    setState(() => _boardOnLeft = !_boardOnLeft);
    LocalStorageService.instance.setJson('battle_board_left', _boardOnLeft);
  }

  void _initBattle() {
    final gameProvider = context.read<GameProvider>();
    final battleProvider = context.read<BattleProvider>();
    final playerProvider = context.read<PlayerProvider>();

    battleProvider.startBattle(
      stage: widget.stage,
      teamAgentIds: playerProvider.data.team,
      playerData: playerProvider.data,
    );

    final battleMode = GameModeConfig(
      id: 'battle_${widget.stage.id}',
      title: widget.stage.name,
      description: '任務 ${widget.stage.id}',
      numCols: 3,
      actionPointsStart: widget.stage.moveLimit,
      enableHorizontalMatches: true,
      scoring: GameModes.triple.scoring,
    );

    gameProvider.onMatchTurnComplete = (result) {
      battleProvider.onMatchesProcessed(
        result.matchedBlockCounts,
        result.combo,
      );
      if (result.totalBlocksEliminated > 0) {
        context.read<PlayerProvider>().addBlocksEliminated(
          result.totalBlocksEliminated,
        );
      }
    };
    gameProvider.onTurnEnd = ({bool hadMatches = true}) {
      battleProvider.onTurnEnd(hadMatches: hadMatches);
    };
    battleProvider.onBoardEffectRequested = (effect, agentColor) {
      return gameProvider.applyBoardEffect(effect, agentColor);
    };

    gameProvider.startGame(battleMode);
  }

  Future<void> _saveResult(bool isVictory, int score) async {
    if (_resultSaved) return;
    _resultSaved = true;

    final playerProvider = context.read<PlayerProvider>();
    final battleProvider = context.read<BattleProvider>();
    final bs = battleProvider.battleState;
    final hpPercent = bs != null && bs.teamMaxHp > 0
        ? bs.teamCurrentHp / bs.teamMaxHp
        : 0.0;

    final reward = await playerProvider.completeBattle(
      stageId: widget.stage.id,
      isVictory: isVictory,
      score: score,
      hpPercent: hpPercent,
      goldReward: widget.stage.reward.gold,
      expReward: widget.stage.reward.exp,
      unlockAgentId: widget.stage.reward.unlockAgentId,
    );

    if (mounted) {
      setState(() {
        _reward = BattleRewardResult(
          gold: reward.gold,
          exp: reward.exp,
          stars: reward.stars,
          isFirstClear: reward.isFirstClear,
          agentUnlocked: reward.agentUnlocked,
          unlockedAgentId: reward.unlockedAgentId,
          materialDrops: reward.materialDrops,
        );
      });
    }
  }

  void _startEndAnimation(bool isVictory) {
    if (_victoryAnimPlaying || _showResult) return;
    setState(() {
      _victoryAnimPlaying = true;
    });
  }

  void _retryBattle(BuildContext context) {
    final playerProvider = context.read<PlayerProvider>();

    // 檢查體力
    if (playerProvider.data.stamina < widget.stage.staminaCost) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('體力不足！需要 ${widget.stage.staminaCost} 體力'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 消耗體力
    playerProvider.consumeStamina(widget.stage.staminaCost);

    // 重置狀態並重新開始
    setState(() {
      _resultSaved = false;
      _reward = null;
      _victoryAnimPlaying = false;
      _showResult = false;
    });

    final battleProvider = context.read<BattleProvider>();
    battleProvider.endBattle();
    _initBattle();
  }

  VoidCallback? _getNextStageCallback(
      BuildContext context, BattleProvider battle) {
    // 找到當前關卡在同章節的下一關
    final currentStage = widget.stage;
    final chapterStages = StageData.getChapterStages(currentStage.chapter);
    final currentIndex =
        chapterStages.indexWhere((s) => s.id == currentStage.id);

    StageDefinition? nextStage;
    if (currentIndex >= 0 && currentIndex < chapterStages.length - 1) {
      nextStage = chapterStages[currentIndex + 1];
    } else {
      // 本章最後一關 → 找下一章的第一關
      final nextChapter = currentStage.chapter + 1;
      final nextChapterStages = StageData.getChapterStages(nextChapter);
      if (nextChapterStages.isNotEmpty) {
        nextStage = nextChapterStages.first;
      }
    }

    if (nextStage == null) return null;

    final playerProvider = context.read<PlayerProvider>();
    final ns = nextStage;

    return () {
      // 檢查體力
      if (playerProvider.data.stamina < ns.staminaCost) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('體力不足！下一關需要 ${ns.staminaCost} 體力'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // 消耗體力並切換到下一關
      playerProvider.consumeStamina(ns.staminaCost);
      battle.endBattle();
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => BattleScreen(stage: ns),
          transitionDuration: const Duration(milliseconds: 500),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    };
  }

  void _confirmExitBattle(BuildContext context, BattleProvider battle) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgSecondary,
        title: const Text('確認放棄'),
        content: const Text('放棄任務後已消耗的體力不會返還，確定要離開嗎？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('繼續戰鬥'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              battle.endBattle();
              Navigator.of(context).pop();
            },
            child: Text(
              '確定離開',
              style: TextStyle(color: AppTheme.accentSecondary),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    final gameProvider = context.read<GameProvider>();
    final battleProvider = context.read<BattleProvider>();
    gameProvider.onMatchTurnComplete = null;
    gameProvider.onTurnEnd = null;
    battleProvider.onBoardEffectRequested = null;
    _attackAnimPlaying.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bgPath = ImageAssets.battleBackground(widget.stage.chapter);

    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      body: SafeArea(
        child: Stack(
          children: [
            // 章節背景圖
            if (bgPath != null)
              Positioned.fill(
                child: Opacity(
                  opacity: 0.5,
                  child: Image.asset(
                    bgPath,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),
            Consumer<BattleProvider>(
          builder: (context, battle, _) {
            final battleState = battle.battleState;

            // 偵測技能施放 → 觸發橫幅動畫
            if (battle.lastSkillAgentId != null && !_showSkillBanner) {
              final agentDef = battleState?.team
                  .where((a) => a.definition.id == battle.lastSkillAgentId)
                  .firstOrNull
                  ?.definition;
              final agentColor = agentDef?.attribute.blockColor.color;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && battle.lastSkillAgentId != null) {
                  setState(() {
                    _showSkillBanner = true;
                    _skillBannerAgentId = battle.lastSkillAgentId;
                    _skillBannerAgentName = battle.lastSkillAgentName;
                    _skillBannerSkillName = battle.lastSkillName;
                    _skillBannerColor = agentColor ?? Colors.amber;
                  });
                  battle.consumeSkillAnim();
                }
              });
            }

            return Stack(
              children: [
                Column(
                  children: [
                    // ── 頂部木質風格標題欄 ──
                    _WoodTopBar(
                      stage: widget.stage,
                      onBack: () => _confirmExitBattle(context, battle),
                      onToggle: _toggleBoardPosition,
                      onPause: () => context.read<GameProvider>().pauseGame(),
                    ),

                    // ── 主體分屏區域 ──
                    Expanded(
                      child: Row(
                        children: _boardOnLeft
                            ? [
                                // 棋盤在左（獨立 Consumer 隔離重繪）
                                Expanded(
                                  flex: 6,
                                  child: RepaintBoundary(
                                    child: Consumer<GameProvider>(
                                      builder: (_, game, __) => _GamePanel(
                                        battleState: battleState,
                                        gameState: game.state,
                                      ),
                                    ),
                                  ),
                                ),
                                // 角色在右
                                if (battleState != null)
                                  Expanded(
                                    flex: 4,
                                    child: RepaintBoundary(
                                      child: _CatAgentPanel(
                                        battleState: battleState,
                                        battleProvider: battle,
                                        attackAnimPlaying: _attackAnimPlaying,
                                      ),
                                    ),
                                  ),
                              ]
                            : [
                                // 角色在左
                                if (battleState != null)
                                  Expanded(
                                    flex: 4,
                                    child: RepaintBoundary(
                                      child: _CatAgentPanel(
                                        battleState: battleState,
                                        battleProvider: battle,
                                        attackAnimPlaying: _attackAnimPlaying,
                                      ),
                                    ),
                                  ),
                                // 棋盤在右
                                Expanded(
                                  flex: 6,
                                  child: RepaintBoundary(
                                    child: Consumer<GameProvider>(
                                      builder: (_, game, __) => _GamePanel(
                                        battleState: battleState,
                                        gameState: game.state,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                      ),
                    ),

                    // ── 底部控制列 ──
                    Consumer<GameProvider>(
                      builder: (_, game, __) => _WoodBottomBar(
                        gameState: game.state,
                        battleProvider: battle,
                      ),
                    ),
                  ],
                ),

                // 暫停選單覆蓋層
                Consumer<GameProvider>(
                  builder: (_, game, __) {
                    if (game.state?.status != GameStatus.paused) {
                      return const SizedBox.shrink();
                    }
                    return PauseMenu(
                      onResume: () => game.resumeGame(),
                      onExitToMenu: () {
                        battle.endBattle();
                        Navigator.of(context).pop();
                      },
                    );
                  },
                ),

                // 戰鬥結束 — 等攻擊動畫播完，再播爆炸演出＋結算
                ValueListenableBuilder<bool>(
                  valueListenable: _attackAnimPlaying,
                  builder: (_, animPlaying, __) => Consumer<GameProvider>(
                    builder: (_, game, __) {
                      final gameState = game.state;
                      if ((battle.isBattleOver || (gameState?.status == GameStatus.gameOver && !battle.isBattleOver)) &&
                          !_victoryAnimPlaying && !_showResult &&
                          !animPlaying) {
                        final isVictory = battle.isBattleOver && battle.isVictory;
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _saveResult(isVictory, gameState?.score ?? 0);
                          _startEndAnimation(isVictory);
                        });
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),

                // 技能施放橫幅動畫（寶可夢藍寶石版飛天風格）
                if (_showSkillBanner)
                  _SkillBannerAnimation(
                    agentId: _skillBannerAgentId!,
                    agentName: _skillBannerAgentName ?? '',
                    skillName: _skillBannerSkillName ?? '',
                    color: _skillBannerColor ?? Colors.amber,
                    onComplete: () {
                      if (mounted) {
                        setState(() => _showSkillBanner = false);
                      }
                    },
                  ),

                // Boss 對話演出
                if (_showBossIntro)
                  _BossIntroOverlay(
                    chapter: widget.stage.chapter,
                    onComplete: () {
                      if (mounted) {
                        setState(() => _showBossIntro = false);
                      }
                    },
                  ),

                // 首戰引導 Overlay
                if (_battleGuideStep >= 0)
                  _FirstBattleGuide(
                    step: _battleGuideStep,
                    onNext: () {
                      if (_battleGuideStep >= 1) {
                        setState(() => _battleGuideStep = -1);
                      } else {
                        setState(() => _battleGuideStep++);
                      }
                    },
                  ),

                // 爆炸演出層
                if (_victoryAnimPlaying)
                  _BattleEndExplosion(
                    isVictory: battle.isVictory,
                    onComplete: () {
                      if (mounted) {
                        setState(() {
                          _victoryAnimPlaying = false;
                          _showResult = true;
                        });
                      }
                    },
                  ),

                // 結算畫面
                if (_showResult)
                  _BattleEndOverlay(
                    isVictory: battle.isBattleOver ? battle.isVictory : false,
                    stage: widget.stage,
                    score: context.read<GameProvider>().state?.score ?? 0,
                    reward: _reward,
                    onExit: () {
                      setState(() => _showResult = false);
                      battle.endBattle();
                      if (widget.onBattleEnd != null) {
                        widget.onBattleEnd!();
                      } else {
                        Navigator.of(context).pop();
                      }
                    },
                    onRetry: () => _retryBattle(context),
                    onNextStage: (battle.isBattleOver && battle.isVictory)
                        ? _getNextStageCallback(context, battle)
                        : null,
                  ),
              ],
            );
          },
        ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════
// 木質風格頂部欄
// ═══════════════════════════════════════════

class _WoodTopBar extends StatelessWidget {
  final StageDefinition stage;
  final VoidCallback onBack;
  final VoidCallback onToggle;
  final VoidCallback onPause;

  const _WoodTopBar({
    required this.stage,
    required this.onBack,
    required this.onToggle,
    required this.onPause,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_woodLight, _woodMid, _woodDark],
        ),
        border: Border(
          bottom: BorderSide(color: _woodBorder, width: 3),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          // 返回按鈕
          _WoodButton(
            onTap: onBack,
            child: const Icon(Icons.arrow_back_ios_new, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 8),
          // STAGE 名稱
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'STAGE ${stage.id}',
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  stage.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFFFF3CD),
                    shadows: [Shadow(color: Colors.black38, blurRadius: 2)],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          // 切換按鈕
          _WoodButton(
            onTap: onToggle,
            child: const Icon(Icons.swap_horiz, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 4),
          // 設定/暫停按鈕
          _WoodButton(
            onTap: onPause,
            child: const Icon(Icons.settings, size: 16, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

/// 木質風格小按鈕
class _WoodButton extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;

  const _WoodButton({required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: _woodDark.withAlpha(80),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _woodBorder.withAlpha(120), width: 1.5),
        ),
        child: Center(child: child),
      ),
    );
  }
}

// ═══════════════════════════════════════════
// 左側面板：敵人卡牌（上）+ 我方角色（下）+ 攻擊動畫 overlay
// ═══════════════════════════════════════════

/// 衝撞動畫資料
class _RushAnimData {
  final Offset from;
  final Offset to;
  final String emoji;
  final Color color;
  final int damage;
  final bool isPlayerAttack;
  final int? targetIndex; // 目標卡牌 index（用於閃爍）
  final UniqueKey key = UniqueKey();

  // Balatro 傷害分解
  final int baseDamage;
  final double attributeMult;
  final int matchCount;
  final int combo;
  final double comboMult;

  // 卡牌攻擊動畫用
  final String? attackerAgentId;
  final String? attackerName;

  _RushAnimData({
    required this.from,
    required this.to,
    required this.emoji,
    required this.color,
    required this.damage,
    required this.isPlayerAttack,
    this.targetIndex,
    this.baseDamage = 0,
    this.attributeMult = 1.0,
    this.matchCount = 0,
    this.combo = 0,
    this.comboMult = 1.0,
    this.attackerAgentId,
    this.attackerName,
  });

  /// 是否需要 Balatro 風格傷害演出
  bool get needsCounterBuildup =>
      combo > 1 || attributeMult > 1.0 || matchCount > 2;
}

/// 飄浮傷害數字資料
class _DamagePopupData {
  final Offset position;
  final int damage;
  final Color color;
  final bool useCounter; // 是否使用 Balatro 風格計數器
  final UniqueKey key = UniqueKey();

  // Balatro 傷害分解
  final int baseDamage;
  final double attributeMult;
  final int matchCount;
  final int combo;
  final double comboMult;

  _DamagePopupData({
    required this.position,
    required this.damage,
    required this.color,
    this.useCounter = false,
    this.baseDamage = 0,
    this.attributeMult = 1.0,
    this.matchCount = 0,
    this.combo = 0,
    this.comboMult = 1.0,
  });
}

class _CatAgentPanel extends StatefulWidget {
  final BattleState battleState;
  final BattleProvider battleProvider;
  final ValueNotifier<bool> attackAnimPlaying;

  const _CatAgentPanel({
    required this.battleState,
    required this.battleProvider,
    required this.attackAnimPlaying,
  });

  @override
  State<_CatAgentPanel> createState() => _CatAgentPanelState();
}

class _CatAgentPanelState extends State<_CatAgentPanel>
    with TickerProviderStateMixin {
  // GlobalKeys for card position tracking
  final List<GlobalKey> _enemyKeys = [];
  final List<GlobalKey> _playerKeys = [];
  final GlobalKey _panelKey = GlobalKey();
  final GlobalKey _playerSectionKey = GlobalKey();

  // Active animations
  final List<_RushAnimData> _activeRushAnims = [];
  final List<_DamagePopupData> _activeDamagePopups = [];

  // 序列化攻擊佇列
  final List<_RushAnimData> _pendingAttacks = [];
  bool _isPlayingSequence = false;

  // 階段標示
  String? _phaseBanner; // "進攻!" / "敵方回合"
  bool _phaseBannerIsEnemy = false; // 標示類型（用於動畫方向）

  // 預感暗幕（敵方回合前的戲劇停頓）
  double _anticipationAlpha = 0.0;

  // Enemy card hit flash states
  final Map<int, bool> _enemyHitStates = {};
  bool _playerSectionHit = false;

  @override
  void didUpdateWidget(covariant _CatAgentPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 確保 keys 數量匹配
    _syncKeys();
    // 消費戰鬥事件，觸發動畫
    _processEvents();
  }

  void _syncKeys() {
    while (_enemyKeys.length < widget.battleState.enemies.length) {
      _enemyKeys.add(GlobalKey());
    }
    while (_playerKeys.length < widget.battleState.team.length) {
      _playerKeys.add(GlobalKey());
    }
  }

  Offset? _getCardCenter(GlobalKey key) {
    final renderBox = key.currentContext?.findRenderObject() as RenderBox?;
    final panelBox = _panelKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || panelBox == null) return null;
    final cardCenter = renderBox.localToGlobal(
      Offset(renderBox.size.width / 2, renderBox.size.height / 2),
    );
    return panelBox.globalToLocal(cardCenter);
  }

  Offset? _getPlayerSectionCenter() {
    final renderBox = _playerSectionKey.currentContext?.findRenderObject() as RenderBox?;
    final panelBox = _panelKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || panelBox == null) return null;
    final center = renderBox.localToGlobal(
      Offset(renderBox.size.width / 2, renderBox.size.height / 2),
    );
    return panelBox.globalToLocal(center);
  }

  void _processEvents() {
    final events = widget.battleProvider.consumeAttackEvents();
    if (events.isEmpty) return;

    // 一次性批量快取所有卡片位置，避免動畫中重複 RenderBox 查詢
    final cachedPlayerPos = <int, Offset>{};
    final cachedEnemyPos = <int, Offset>{};
    for (int i = 0; i < _playerKeys.length; i++) {
      final pos = _getCardCenter(_playerKeys[i]);
      if (pos != null) cachedPlayerPos[i] = pos;
    }
    for (int i = 0; i < _enemyKeys.length; i++) {
      final pos = _getCardCenter(_enemyKeys[i]);
      if (pos != null) cachedEnemyPos[i] = pos;
    }
    final playerSectionCenter = _getPlayerSectionCenter();

    // 收集所有攻擊到 pending 佇列
    for (final event in events) {
      if (event.type == BattleEventType.autoAttack &&
          event.attackerIndex != null &&
          event.targetIndex != null) {
        final fromIdx = event.attackerIndex! < _playerKeys.length
            ? event.attackerIndex!
            : _playerKeys.length - 1;
        final toIdx = event.targetIndex! < _enemyKeys.length
            ? event.targetIndex!
            : _enemyKeys.length - 1;
        final from = cachedPlayerPos[fromIdx];
        final to = cachedEnemyPos[toIdx];
        if (from != null && to != null) {
          // 取得攻擊者資訊
          final attacker = fromIdx < widget.battleState.team.length
              ? widget.battleState.team[fromIdx]
              : null;
          _pendingAttacks.add(_RushAnimData(
            from: from,
            to: to,
            emoji: event.emoji ?? '⚔',
            color: attacker?.definition.attribute.blockColor.color ?? Colors.cyan,
            damage: event.value,
            isPlayerAttack: true,
            targetIndex: event.targetIndex,
            baseDamage: event.baseDamage,
            attributeMult: event.attributeMult,
            matchCount: event.matchCount,
            combo: event.combo,
            comboMult: event.comboMult,
            attackerAgentId: attacker?.definition.id,
            attackerName: attacker?.definition.name,
          ));
        }
      } else if (event.type == BattleEventType.enemyAttack &&
          event.attackerIndex != null) {
        final fromIdx = event.attackerIndex! < _enemyKeys.length
            ? event.attackerIndex!
            : _enemyKeys.length - 1;
        final from = cachedEnemyPos[fromIdx];
        if (from != null && playerSectionCenter != null) {
          final enemyAttacker = fromIdx < widget.battleState.enemies.length
              ? widget.battleState.enemies[fromIdx]
              : null;
          _pendingAttacks.add(_RushAnimData(
            from: from,
            to: playerSectionCenter,
            emoji: event.emoji ?? '👊',
            color: enemyAttacker?.definition.attribute.blockColor.color ?? Colors.red,
            damage: event.value,
            isPlayerAttack: false,
            attackerAgentId: enemyAttacker?.definition.id,
            attackerName: enemyAttacker?.definition.name,
          ));
        }
      }
    }

    // 如果有新事件且未在播放中，啟動序列播放
    if (_pendingAttacks.isNotEmpty && !_isPlayingSequence) {
      _playAttackSequence();
    }
  }

  /// 序列化播放攻擊動畫（Balatro 風格節奏）
  /// 我方快攻交錯、敵方慢重、攻守轉場戲劇停頓
  Future<void> _playAttackSequence() async {
    if (_isPlayingSequence) return;
    _isPlayingSequence = true;
    widget.attackAnimPlaying.value = true;

    while (_pendingAttacks.isNotEmpty) {
      if (!mounted) break;

      final attack = _pendingAttacks.removeAt(0);
      final isEnemy = !attack.isPlayerAttack;

      // ── 攻守轉場：預感停頓 + 暗幕 ──
      if (isEnemy && _phaseBanner != '敵方回合') {
        // 從我方→敵方：400ms 戲劇停頓 + 畫面微暗
        if (_phaseBanner == '進攻!') {
          setState(() => _phaseBanner = null);
          await Future.delayed(const Duration(milliseconds: 150));
          if (!mounted) break;
        }
        // 預感暗幕漸入
        setState(() => _anticipationAlpha = 60.0);
        await Future.delayed(const Duration(milliseconds: 250));
        if (!mounted) break;
        setState(() {
          _phaseBanner = '敵方回合';
          _phaseBannerIsEnemy = true;
        });
        await Future.delayed(const Duration(milliseconds: 400));
        if (!mounted) break;
      }
      if (!isEnemy && _phaseBanner != '進攻!') {
        setState(() {
          _anticipationAlpha = 0.0;
          _phaseBanner = '進攻!';
          _phaseBannerIsEnemy = false;
        });
        await Future.delayed(const Duration(milliseconds: 250));
        if (!mounted) break;
      }

      // ── 播放攻擊動畫 ──
      setState(() {
        _activeRushAnims.add(attack);
      });

      // 動態間隔：我方快攻交錯 150ms / 敵方慢重 500ms
      final delay = isEnemy ? 500 : 150;
      await Future.delayed(Duration(milliseconds: delay));
      if (!mounted) break;
    }

    // 全部播完，清除階段標示和暗幕
    if (mounted) {
      await Future.delayed(const Duration(milliseconds: 150));
      if (mounted) {
        setState(() {
          _phaseBanner = null;
          _anticipationAlpha = 0.0;
          _isPlayingSequence = false;
        });
        if (_activeRushAnims.isEmpty) {
          widget.attackAnimPlaying.value = false;
        }
      }
    }
  }

  void _onRushHit(_RushAnimData data) {
    HapticFeedback.mediumImpact();
    setState(() {
      final useCounter = data.isPlayerAttack && data.needsCounterBuildup;
      _activeDamagePopups.add(_DamagePopupData(
        position: data.to + const Offset(-20, -28),
        damage: data.damage,
        color: data.isPlayerAttack ? Colors.white : Colors.red,
        useCounter: useCounter,
        baseDamage: data.baseDamage,
        attributeMult: data.attributeMult,
        matchCount: data.matchCount,
        combo: data.combo,
        comboMult: data.comboMult,
      ));
      if (data.isPlayerAttack && data.targetIndex != null) {
        _enemyHitStates[data.targetIndex!] = true;
      } else if (!data.isPlayerAttack) {
        _playerSectionHit = true;
      }
    });
    // 單一延遲清除 hit 閃爍狀態
    Future.delayed(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      setState(() {
        if (data.isPlayerAttack && data.targetIndex != null) {
          _enemyHitStates[data.targetIndex!] = false;
        } else if (!data.isPlayerAttack) {
          _playerSectionHit = false;
        }
      });
    });
  }

  void _removeRush(_RushAnimData data) {
    if (mounted) {
      setState(() => _activeRushAnims.remove(data));
      if (_activeRushAnims.isEmpty && !_isPlayingSequence) {
        widget.attackAnimPlaying.value = false;
      }
    }
  }

  void _removePopup(_DamagePopupData data) {
    if (mounted) setState(() => _activeDamagePopups.remove(data));
  }

  @override
  Widget build(BuildContext context) {
    _syncKeys();

    return Stack(
      key: _panelKey,
      children: [
        // 原有佈局
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xCCE8D5B7),  // Warm Wheat
                Color(0xBBF5E6D3),  // Almond
                Color(0xAAE8D5B7),  // Warm Wheat
                Color(0x99D7C4A8),  // Muted wheat
              ],
              stops: [0.0, 0.3, 0.75, 1.0],
            ),
          ),
          child: Column(
            children: [
              // ── 上半：敵人卡牌 ──
              Expanded(
                flex: 5,
                child: _EnemyCardsSection(
                  battleState: widget.battleState,
                  cardKeys: _enemyKeys,
                  hitStates: _enemyHitStates,
                ),
              ),
              // 分隔線
              Container(
                height: 2,
                color: AppTheme.accentSecondary.withAlpha(60),
                margin: const EdgeInsets.symmetric(horizontal: 6),
              ),
              // ── 下半：我方角色 ──
              Expanded(
                flex: 5,
                child: _ShakeWrapper(
                  key: _playerSectionKey,
                  isShaking: _playerSectionHit,
                  intensity: ShakeIntensity.heavy,
                  child: _PlayerCardsSection(
                    battleState: widget.battleState,
                    battleProvider: widget.battleProvider,
                    cardKeys: _playerKeys,
                  ),
                ),
              ),
            ],
          ),
        ),
        // 預感暗幕層（敵方回合前的戲劇停頓）
        if (_anticipationAlpha > 0)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                color: Colors.black.withAlpha(_anticipationAlpha.round()),
              ),
            ),
          ),
        // Combo 計數器（右上角）
        if (widget.battleState.lastCombo > 0)
          Positioned(
            top: 8,
            right: 8,
            child: ComboCounter(combo: widget.battleState.lastCombo),
          ),
        // 階段標示層（動畫化）
        if (_phaseBanner != null)
          _PhaseBannerWidget(
            key: ValueKey('phase_$_phaseBanner'),
            text: _phaseBanner!,
            isEnemy: _phaseBannerIsEnemy,
          ),
        // 衝撞動畫層
        ..._activeRushAnims.map((rush) => _RushAttackWidget(
          key: rush.key,
          data: rush,
          onHit: () => _onRushHit(rush),
          onComplete: () => _removeRush(rush),
        )),
        // 飄浮傷害數字層
        ..._activeDamagePopups.map((popup) => popup.useCounter
            ? DamageCounterWidget(
                key: popup.key,
                position: popup.position,
                finalDamage: popup.damage,
                baseDamage: popup.baseDamage,
                attributeMult: popup.attributeMult,
                matchCount: popup.matchCount,
                combo: popup.combo,
                comboMult: popup.comboMult,
                color: popup.color,
                onComplete: () => _removePopup(popup),
              )
            : _DamagePopup(
                key: popup.key,
                position: popup.position,
                damage: popup.damage,
                color: popup.color,
                onComplete: () => _removePopup(popup),
              ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════
// 震動強度等級（Balatro 風格分級打擊感）
// ═══════════════════════════════════════════

enum ShakeIntensity {
  light,   // 消方塊等輕微反饋
  medium,  // 普攻命中
  heavy,   // 敵方攻擊、大傷害
  massive, // 技能施放、Boss 擊殺
}

// ═══════════════════════════════════════════
// 動畫化階段標示（進攻→左滑入 / 敵方→上方落下）
// ═══════════════════════════════════════════

class _PhaseBannerWidget extends StatefulWidget {
  final String text;
  final bool isEnemy;

  const _PhaseBannerWidget({
    super.key,
    required this.text,
    required this.isEnemy,
  });

  @override
  State<_PhaseBannerWidget> createState() => _PhaseBannerWidgetState();
}

class _PhaseBannerWidgetState extends State<_PhaseBannerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnim;
  late Animation<double> _opacityAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    // 敵方稍長（更有威脅感）
    final durationMs = widget.isEnemy ? 650 : 550;
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: durationMs),
    );

    if (widget.isEnemy) {
      // 「敵方回合」：從上方落下 + bounceOut
      _slideAnim = Tween<double>(begin: -1.5, end: 0.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.0, 0.45, curve: Curves.bounceOut),
        ),
      );
    } else {
      // 「進攻!」：從左側滑入 + easeOutBack 過衝
      _slideAnim = Tween<double>(begin: -2.0, end: 0.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.0, 0.40, curve: Curves.easeOutBack),
        ),
      );
    }

    // 彈入縮放
    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.8, end: 1.1), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.1, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.6), weight: 25),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    // 淡入→持續→淡出
    _opacityAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(_controller);

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isEnemy ? Colors.red : Colors.cyan;

    return Positioned.fill(
      child: Center(
        child: IgnorePointer(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (_, child) {
              final slideVal = _slideAnim.value;
              // 敵方：Y 軸偏移 / 我方：X 軸偏移
              final offset = widget.isEnemy
                  ? Offset(0, slideVal * 40)
                  : Offset(slideVal * 60, 0);

              return Transform.translate(
                offset: offset,
                child: Transform.scale(
                  scale: _scaleAnim.value.clamp(0.0, 2.0),
                  child: Opacity(
                    opacity: _opacityAnim.value.clamp(0.0, 1.0),
                    child: child,
                  ),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: color.withAlpha(200),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.white.withAlpha(100),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withAlpha(120),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Text(
                widget.text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                  shadows: [
                    Shadow(color: Colors.black54, blurRadius: 4),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════
// 增強型 2D 晃動包裝器 + 縮放脈衝
// ═══════════════════════════════════════════

class _ShakeWrapper extends StatefulWidget {
  final bool isShaking;
  final ShakeIntensity intensity;
  final Widget child;

  const _ShakeWrapper({
    super.key,
    required this.isShaking,
    this.intensity = ShakeIntensity.medium,
    required this.child,
  });

  @override
  State<_ShakeWrapper> createState() => _ShakeWrapperState();
}

class _ShakeWrapperState extends State<_ShakeWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  ShakeIntensity _activeIntensity = ShakeIntensity.medium;

  // 各等級參數
  static const _params = {
    ShakeIntensity.light:   (amplitude: 3.0,  durationMs: 200, zoom: 1.0),
    ShakeIntensity.medium:  (amplitude: 6.0,  durationMs: 300, zoom: 1.0),
    ShakeIntensity.heavy:   (amplitude: 10.0, durationMs: 400, zoom: 1.02),
    ShakeIntensity.massive: (amplitude: 14.0, durationMs: 500, zoom: 1.03),
  };

  @override
  void initState() {
    super.initState();
    _activeIntensity = widget.intensity;
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: _params[_activeIntensity]!.durationMs),
    );
  }

  @override
  void didUpdateWidget(covariant _ShakeWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isShaking && !oldWidget.isShaking) {
      _activeIntensity = widget.intensity;
      _controller.duration = Duration(
        milliseconds: _params[_activeIntensity]!.durationMs,
      );
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, child) {
        final p = _params[_activeIntensity]!;
        final t = _controller.value;
        final decay = 1.0 - t;

        // 2D 震動：X 和 Y 使用不同頻率避免圓周感
        final offsetX = sin(t * pi * 5) * p.amplitude * decay;
        final offsetY = sin(t * pi * 7) * p.amplitude * 0.6 * decay;

        // heavy/massive 加入 zoom pulse
        final zoom = p.zoom > 1.0
            ? 1.0 + (p.zoom - 1.0) * sin(t * pi) // 脈衝：0→peak→0
            : 1.0;

        Widget result = Transform.translate(
          offset: Offset(offsetX, offsetY),
          child: child,
        );

        if (zoom > 1.0) {
          result = Transform.scale(scale: zoom, child: result);
        }

        return result;
      },
      child: widget.child,
    );
  }
}

// ═══════════════════════════════════════════
// 角色衝撞動畫
// ═══════════════════════════════════════════

/// 爐石風格卡牌攻擊動畫
/// 四階段：浮起 → 衝刺 → 撞擊（畫面震動）→ 返回
class _RushAttackWidget extends StatefulWidget {
  final _RushAnimData data;
  final VoidCallback onHit;
  final VoidCallback onComplete;

  const _RushAttackWidget({
    super.key,
    required this.data,
    required this.onHit,
    required this.onComplete,
  });

  @override
  State<_RushAttackWidget> createState() => _RushAttackWidgetState();
}

class _RushAttackWidgetState extends State<_RushAttackWidget>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _impactController;
  late Animation<double> _positionAnim;
  late Animation<double> _scaleAnim;
  late Animation<double> _elevationAnim;
  late Animation<double> _squashXAnim;
  late Animation<double> _squashYAnim;
  bool _hitFired = false;

  late List<double> _burstLineOffsets;

  static const _cardSize = 60.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _impactController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    final rng = Random();
    _burstLineOffsets = List.generate(10, (_) => 0.6 + rng.nextDouble() * 0.4);

    // 位置動畫：浮起(不動) → 衝刺到目標 → 停頓 → 返回
    _positionAnim = TweenSequence<double>([
      // 浮起階段 (0-15%): 原地不動
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 0.0),
        weight: 15,
      ),
      // 衝刺階段 (15-40%): 衝向目標
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 25,
      ),
      // 撞擊停頓 (40-55%): 停在目標
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.0),
        weight: 15,
      ),
      // 返回 (55-100%): 回到原位
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 45,
      ),
    ]).animate(_controller);

    // 整體縮放（浮起放大 → 撞擊回復）
    _scaleAnim = TweenSequence<double>([
      // 浮起放大
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.15)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 15,
      ),
      // 衝刺中保持放大
      TweenSequenceItem(
        tween: Tween(begin: 1.15, end: 1.15),
        weight: 25,
      ),
      // 撞擊階段
      TweenSequenceItem(
        tween: Tween(begin: 1.15, end: 1.0),
        weight: 15,
      ),
      // 返回
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.0),
        weight: 45,
      ),
    ]).animate(_controller);

    // 浮起時的陰影/高度感
    _elevationAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 12.0), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 12.0, end: 12.0), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 12.0, end: 0.0), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.0), weight: 45),
    ]).animate(_controller);

    // 撞擊 squash 效果
    _squashXAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 37),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.25), weight: 8),
      TweenSequenceItem(tween: Tween(begin: 1.25, end: 1.0), weight: 10),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 45),
    ]).animate(_controller);

    _squashYAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 37),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.75), weight: 8),
      TweenSequenceItem(tween: Tween(begin: 0.75, end: 1.0), weight: 10),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 45),
    ]).animate(_controller);

    _controller.addListener(_checkHit);
    _controller.forward().then((_) => widget.onComplete());
  }

  void _checkHit() {
    if (!_hitFired && _controller.value >= 0.40) {
      _hitFired = true;
      widget.onHit();
      _impactController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_checkHit);
    _controller.dispose();
    _impactController.dispose();
    super.dispose();
  }

  Widget _buildCardGhost() {
    final data = widget.data;
    final agentId = data.attackerAgentId;
    final isPlayer = data.isPlayerAttack;

    // 構建攻擊幽靈卡
    Widget imageWidget;
    if (isPlayer && agentId != null) {
      final path = ImageAssets.avatarImage(agentId);
      if (path != null) {
        imageWidget = Image.asset(
          path,
          width: 36,
          height: 36,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Text(
            data.emoji,
            style: const TextStyle(fontSize: 24),
          ),
        );
      } else {
        imageWidget = Text(data.emoji, style: const TextStyle(fontSize: 24));
      }
    } else if (!isPlayer && agentId != null) {
      imageWidget = GameImage(
        assetPath: ImageAssets.enemyImage(agentId),
        fallbackEmoji: data.emoji,
        width: 36,
        height: 36,
      );
    } else {
      imageWidget = Text(data.emoji, style: const TextStyle(fontSize: 24));
    }

    return Container(
      width: _cardSize,
      height: _cardSize,
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: data.color, width: 2),
        boxShadow: [
          BoxShadow(
            color: data.color.withAlpha(100),
            blurRadius: _elevationAnim.value,
            spreadRadius: _elevationAnim.value / 4,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Center(child: imageWidget),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_controller, _impactController]),
      builder: (_, __) {
        final t = _positionAnim.value;
        final pos = Offset.lerp(widget.data.from, widget.data.to, t)!;
        final scale = _scaleAnim.value;

        // 浮起時微微上移
        final liftOffset = _controller.value < 0.15
            ? -4.0 * (_controller.value / 0.15)
            : _controller.value < 0.40
                ? -4.0
                : 0.0;

        return Stack(
          children: [
            // 卡牌幽靈
            Positioned(
              left: pos.dx - _cardSize / 2,
              top: pos.dy - _cardSize / 2 + liftOffset,
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..scale(
                    scale * _squashXAnim.value,
                    scale * _squashYAnim.value,
                  ),
                child: _buildCardGhost(),
              ),
            ),
            // 撞擊爆發特效
            if (_impactController.value > 0 && _impactController.value < 1.0)
              Positioned(
                left: widget.data.to.dx - 28,
                top: widget.data.to.dy - 28,
                width: 56,
                height: 56,
                child: CustomPaint(
                  painter: _ImpactBurstPainter(
                    progress: Curves.easeOutCubic.transform(
                      _impactController.value,
                    ),
                    color: widget.data.color,
                    lineOffsets: _burstLineOffsets,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

// ═══════════════════════════════════════════
// 自繪撞擊��發特效（漫畫速度線 + 放射環 + 中心閃光）
// ═══════════════════════════════════════════

class _ImpactBurstPainter extends CustomPainter {
  final double progress;
  final Color color;
  final List<double> lineOffsets;

  _ImpactBurstPainter({
    required this.progress,
    required this.color,
    required this.lineOffsets,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final center = Offset(cx, cy);
    final maxRadius = size.width / 2;
    final alpha = ((1.0 - progress) * 255).round().clamp(0, 255);
    if (alpha <= 0) return;

    // 1) 中心閃光填充
    final flashRadius = maxRadius * 0.5 * progress;
    final flashAlpha = ((1.0 - progress) * 200).round().clamp(0, 255);
    final flashPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withAlpha(flashAlpha),
          color.withAlpha((flashAlpha * 0.5).round()),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: flashRadius));
    canvas.drawCircle(center, flashRadius, flashPaint);

    // 2) 放射線條（漫畫速度線風格）
    final linePaint = Paint()
      ..color = Colors.white.withAlpha(alpha)
      ..strokeWidth = (2.0 * (1.0 - progress * 0.5)).clamp(0.5, 2.0)
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < lineOffsets.length; i++) {
      final angle = (i / lineOffsets.length) * 2 * pi;
      final lenFactor = lineOffsets[i];
      final innerR = maxRadius * 0.2 * progress;
      final outerR = maxRadius * progress * lenFactor;
      final cosA = cos(angle);
      final sinA = sin(angle);
      canvas.drawLine(
        Offset(cx + cosA * innerR, cy + sinA * innerR),
        Offset(cx + cosA * outerR, cy + sinA * outerR),
        linePaint,
      );
    }

    // 3) 外圈擴散環
    final ringRadius = maxRadius * 0.7 * progress;
    final ringAlpha = ((1.0 - progress) * 180).round().clamp(0, 255);
    final ringPaint = Paint()
      ..color = color.withAlpha(ringAlpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = (2.5 * (1.0 - progress * 0.6)).clamp(0.5, 2.5);
    canvas.drawCircle(center, ringRadius, ringPaint);
  }

  @override
  bool shouldRepaint(_ImpactBurstPainter old) => old.progress != progress;
}

// ═══════════════════════════════════════════
// 飄浮傷害數字
// ═══════════════════════════════════════════

class _DamagePopup extends StatefulWidget {
  final Offset position;
  final int damage;
  final Color color;
  final VoidCallback onComplete;

  const _DamagePopup({
    super.key,
    required this.position,
    required this.damage,
    required this.color,
    required this.onComplete,
  });

  @override
  State<_DamagePopup> createState() => _DamagePopupState();
}

class _DamagePopupState extends State<_DamagePopup>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnim;
  late Animation<double> _scaleAnim;
  late Animation<double> _opacityAnim;
  late Animation<double> _shakeAnim;

  // 依傷害量決定的視覺參數
  late double _fontSize;
  late double _glowRadius;
  late double _peakScale;
  late bool _hasShake;

  @override
  void initState() {
    super.initState();
    final d = widget.damage;

    // 傷害量分級視覺
    if (d >= 100) {
      _fontSize = 38;
      _glowRadius = 20;
      _peakScale = 2.0;
      _hasShake = true;
    } else if (d >= 50) {
      _fontSize = 32;
      _glowRadius = 16;
      _peakScale = 1.8;
      _hasShake = true;
    } else if (d >= 20) {
      _fontSize = 26;
      _glowRadius = 12;
      _peakScale = 1.6;
      _hasShake = false;
    } else {
      _fontSize = 22;
      _glowRadius = 8;
      _peakScale = 1.4;
      _hasShake = false;
    }

    final duration = _hasShake ? 900 : 700;
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: duration),
    );

    _slideAnim = Tween<Offset>(
      begin: Offset.zero,
      end: Offset(0, _hasShake ? -2.5 : -2.0),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: _peakScale), weight: 15),
      TweenSequenceItem(tween: Tween(begin: _peakScale, end: 1.0), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 70),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _opacityAnim = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.65, 1.0, curve: Curves.easeIn),
      ),
    );

    // 大傷害震動
    _shakeAnim = _hasShake
        ? Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(
              parent: _controller,
              curve: const Interval(0.0, 0.35, curve: Curves.linear),
            ),
          )
        : const AlwaysStoppedAnimation(0.0);

    _controller.forward().then((_) => widget.onComplete());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.position.dx,
      top: widget.position.dy,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, child) {
          final shakeOffset = _hasShake
              ? sin(_shakeAnim.value * pi * 6) * 3.0 * (1.0 - _shakeAnim.value)
              : 0.0;
          return SlideTransition(
            position: _slideAnim,
            child: Transform.translate(
              offset: Offset(shakeOffset, 0),
              child: ScaleTransition(
                scale: _scaleAnim,
                child: FadeTransition(
                  opacity: _opacityAnim,
                  child: child,
                ),
              ),
            ),
          );
        },
        child: Text(
          '-${widget.damage}',
          style: TextStyle(
            fontSize: _fontSize,
            fontWeight: FontWeight.w900,
            color: widget.color,
            shadows: [
              Shadow(
                color: widget.color.withAlpha(200),
                blurRadius: _glowRadius,
              ),
              const Shadow(
                color: Colors.black,
                blurRadius: 6,
                offset: Offset(1, 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 敵人卡牌區域
class _EnemyCardsSection extends StatelessWidget {
  final BattleState battleState;
  final List<GlobalKey> cardKeys;
  final Map<int, bool> hitStates;

  const _EnemyCardsSection({
    required this.battleState,
    required this.cardKeys,
    required this.hitStates,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      children: battleState.enemies.asMap().entries.map((entry) {
        final enemy = entry.value;
        final isCurrent = entry.key == battleState.currentEnemyIndex;
        final isHit = hitStates[entry.key] ?? false;
        return _EnemyCard(
          key: entry.key < cardKeys.length ? cardKeys[entry.key] : null,
          enemy: enemy,
          isCurrent: isCurrent,
          isHit: isHit,
          battleState: battleState,
        );
      }).toList(),
    );
  }
}

/// 單一敵人卡牌（橫式遊戲王風格 + 命中閃爍 + 狀態效果 + 攻擊意圖）
class _EnemyCard extends StatelessWidget {
  final EnemyInstance enemy;
  final bool isCurrent;
  final bool isHit;
  final BattleState battleState;

  const _EnemyCard({
    super.key,
    required this.enemy,
    required this.isCurrent,
    required this.battleState,
    this.isHit = false,
  });

  @override
  Widget build(BuildContext context) {
    if (enemy.isDead) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Opacity(
          opacity: 0.3,
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.bgCard,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                GameImage(
                  assetPath: ImageAssets.enemyImage(enemy.definition.id),
                  fallbackEmoji: enemy.definition.emoji,
                  width: 24, height: 24,
                ),
                const SizedBox(width: 6),
                Text(
                  '${enemy.definition.name} ✕',
                  style: TextStyle(
                    color: AppTheme.textSecondary.withAlpha(100),
                    fontSize: 10,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final color = enemy.definition.attribute.blockColor.color;
    final countdownPercent = enemy.definition.attackInterval > 0
        ? enemy.attackCountdown / enemy.definition.attackInterval
        : 0.0;

    // 外框顏色 — 遊戲王風格雙邊框
    final outerBorderColor = isCurrent
        ? Colors.red.withAlpha(200)
        : color.withAlpha(100);
    final innerBorderColor = isCurrent
        ? Colors.red.withAlpha(100)
        : color.withAlpha(50);

    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
        height: 80,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: isHit
              ? Colors.white.withAlpha(120)
              : AppTheme.bgCard,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: outerBorderColor, width: 2),
          boxShadow: [
            if (isCurrent)
              BoxShadow(color: color.withAlpha(60), blurRadius: 10, spreadRadius: 1),
            if (isHit)
              BoxShadow(color: Colors.white.withAlpha(80), blurRadius: 12),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: innerBorderColor, width: 1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              // ─── 左側：大圖區域（遊戲王風格）───
              SizedBox(
                width: 72,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // 背景漸層
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            color.withAlpha(40),
                            color.withAlpha(15),
                          ],
                        ),
                        border: Border(
                          right: BorderSide(color: color.withAlpha(80), width: 1.5),
                        ),
                      ),
                    ),
                    // 角色大圖
                    Padding(
                      padding: const EdgeInsets.all(4),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: GameImage(
                          assetPath: ImageAssets.enemyImage(enemy.definition.id),
                          fallbackEmoji: enemy.definition.emoji,
                          width: 64,
                          height: 72,
                        ),
                      ),
                    ),
                    // 倒數弧形指示器
                    Positioned(
                      top: 2,
                      right: 4,
                      child: _MiniCountdownArc(
                        progress: countdownPercent,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
              // ─── 右側：名稱 + HP 條 + ATK + 狀態 ───
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 名稱列
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              enemy.definition.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(color: Colors.black87, blurRadius: 3)
                                ],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          _AttackIntent(
                            countdown: enemy.attackCountdown,
                            atk: enemy.atk,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // HP 條
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: enemy.hpPercent,
                          minHeight: 8,
                          backgroundColor: AppTheme.bgCard,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            enemy.hpPercent > 0.5
                                ? Colors.green
                                : enemy.hpPercent > 0.25
                                    ? Colors.orange
                                    : Colors.red,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      // 數值列
                      Row(
                        children: [
                          Text(
                            '${enemy.currentHp}/${enemy.maxHp}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'ATK ${enemy.atk}',
                            style: TextStyle(
                              color: Colors.red.shade200,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (isCurrent) ...[
                            if (battleState.defDebuffTurns > 0)
                              _StatusIcon(
                                icon: Icons.shield_outlined,
                                color: Colors.orange,
                                label: '${battleState.defDebuffTurns}',
                                tooltip: '破防',
                              ),
                            if (battleState.activeDots.isNotEmpty)
                              _StatusIcon(
                                icon: Icons.local_fire_department,
                                color: Colors.deepOrange,
                                label:
                                    '${battleState.activeDots.first.turnsRemaining}',
                                tooltip: 'DoT',
                              ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 迷你倒數弧形指示器（敵人卡片右上角）
class _MiniCountdownArc extends StatelessWidget {
  final double progress;
  final Color color;

  const _MiniCountdownArc({required this.progress, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 18,
      height: 18,
      child: CustomPaint(
        painter: _MiniArcPainter(progress: progress, color: color),
      ),
    );
  }
}

class _MiniArcPainter extends CustomPainter {
  final double progress;
  final Color color;

  _MiniArcPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 1;

    // 背景圓
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.black54
        ..style = PaintingStyle.fill,
    );

    // 倒數弧
    if (progress > 0) {
      final arcPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2,
        2 * pi * progress,
        false,
        arcPaint,
      );
    }

    // 中心數字區域不畫 — 讓它保持乾淨
  }

  @override
  bool shouldRepaint(_MiniArcPainter old) =>
      old.progress != progress || old.color != color;
}

/// 我方角色卡牌區域
class _PlayerCardsSection extends StatelessWidget {
  final BattleState battleState;
  final BattleProvider battleProvider;
  final List<GlobalKey> cardKeys;

  const _PlayerCardsSection({
    required this.battleState,
    required this.battleProvider,
    required this.cardKeys,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      children: [
        // 團隊狀態列（HP + buff 圖示）
        _TeamStatusBar(battleState: battleState),
        const SizedBox(height: 2),
        // 角色卡牌
        ...battleState.team.asMap().entries.map((entry) {
        final index = entry.key;
        final agent = entry.value;
        return _CatAgentCard(
          key: index < cardKeys.length ? cardKeys[index] : null,
          agent: agent,
          onTap: () {
            if (agent.isSkillReady) {
              _showSkillConfirm(context, agent, index);
            }
          },
        );
      }),
      ],
    );
  }

  void _showSkillConfirm(BuildContext context, BattleAgent agent, int index) {
    final color = agent.definition.attribute.blockColor.color;
    final effect = agent.definition.skill.boardEffect;

    HapticFeedback.lightImpact();

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: color.withAlpha(120), width: 1.5),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 角色圖片
              CatStatusRing(
                ringColor: color,
                isReady: true,
                size: 56,
                child: _buildAgentAvatar(agent.definition.id, color, 50),
              ),
              const SizedBox(height: 10),
              Text(
                '${agent.definition.name} — ${agent.definition.skill.name}',
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              // 技能描述
              if (effect != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: color.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '🎯 ${effect.description}',
                    style: TextStyle(color: color, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 16),
              // 雙選擇：進攻 or 換方塊
              if (effect != null)
                Column(
                  children: [
                    // 進攻模式
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          HapticFeedback.mediumImpact();
                          battleProvider.activateSkill(index,
                              useAttackOnly: true);
                        },
                        icon: const Text('⚔️', style: TextStyle(fontSize: 16)),
                        label: const Text('進攻'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade700,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // 方塊效果模式
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          HapticFeedback.mediumImpact();
                          battleProvider.activateSkill(index,
                              useBoardOnly: true);
                        },
                        icon: const Text('🧩', style: TextStyle(fontSize: 16)),
                        label: Text(effect.description,
                            style: const TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: color,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // 取消
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.textSecondary,
                          side: BorderSide(color: Colors.white.withAlpha(30)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('取消'),
                      ),
                    ),
                  ],
                )
              else
                // 沒有方塊效果的技能 → 直接施放
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.textSecondary,
                          side: BorderSide(color: Colors.white.withAlpha(30)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('取消'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          HapticFeedback.mediumImpact();
                          battleProvider.activateSkill(index);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: color,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('施放！'),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 單一我方角色卡片（橫式遊戲王風格 + 能量條）
class _CatAgentCard extends StatelessWidget {
  final BattleAgent agent;
  final VoidCallback onTap;

  const _CatAgentCard({super.key, required this.agent, required this.onTap});

  void _showAgentInfo(BuildContext context) {
    final def = agent.definition;
    final color = def.attribute.blockColor.color;

    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: color.withAlpha(120), width: 1.5),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withAlpha(60),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: color.withAlpha(120)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: _buildAgentAvatar(def.id, color, 36),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${def.name} Lv.${agent.level}',
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${def.breed} · ${def.role.label}',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _InfoStat('ATK', '${agent.atk}', Colors.orange),
                  _InfoStat('DEF', '${agent.def}', Colors.blue),
                  _InfoStat('HP', '${agent.hp}', Colors.green),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🎯 ${def.skill.name}',
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      def.skill.description,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '能量消耗: ${def.skill.energyCost}',
                      style: TextStyle(
                        color: Colors.amber.shade300,
                        fontSize: 11,
                      ),
                    ),
                    if (def.skill.boardEffect != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '🧩 ${def.skill.boardEffect!.description}',
                          style: TextStyle(
                            color: Colors.cyan.shade300,
                            fontSize: 11,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '💡 被動：${def.passiveDescription}',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('關閉'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = agent.definition.attribute.blockColor.color;
    final isReady = agent.isSkillReady;

    // 外框顏色 — 遊戲王風格雙邊框
    final outerBorderColor = isReady
        ? Colors.amber.withAlpha(200)
        : color.withAlpha(100);
    final innerBorderColor = isReady
        ? Colors.amber.withAlpha(100)
        : color.withAlpha(50);

    return GestureDetector(
      onTap: isReady ? onTap : null,
      onLongPress: () => _showAgentInfo(context),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: Container(
          height: 80,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: outerBorderColor, width: 2),
            color: AppTheme.bgCard,
            boxShadow: [
              if (isReady)
                BoxShadow(
                  color: Colors.amber.withAlpha(60),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
            ],
          ),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: innerBorderColor, width: 1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                // ─── 左側：角色大圖（遊戲王風格）───
                SizedBox(
                  width: 72,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // 背景漸層
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              color.withAlpha(40),
                              color.withAlpha(15),
                            ],
                          ),
                          border: Border(
                            right: BorderSide(color: color.withAlpha(80), width: 1.5),
                          ),
                        ),
                      ),
                      // 角色大圖
                      Padding(
                        padding: const EdgeInsets.all(4),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: _buildAgentAvatar(
                            agent.definition.id, color, 64,
                          ),
                        ),
                      ),
                      // 技能就緒閃光
                      if (isReady)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.amber.withAlpha(80),
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // ─── 右側：名稱 + ATK/DEF + 能量條 ───
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 名稱 + Lv
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                agent.definition.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  shadows: [
                                    Shadow(color: Colors.black87, blurRadius: 3)
                                  ],
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: color.withAlpha(40),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(
                                'Lv.${agent.level}',
                                style: TextStyle(
                                  color: color,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        // ATK + DEF
                        Row(
                          children: [
                            Text(
                              'ATK ${agent.atk}',
                              style: TextStyle(
                                color: Colors.orange.shade200,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'DEF ${agent.def}',
                              style: TextStyle(
                                color: Colors.blue.shade200,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        // 能量條
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: agent.energyPercent,
                            minHeight: 7,
                            backgroundColor: AppTheme.bgCard,
                            valueColor: AlwaysStoppedAnimation(
                              isReady ? Colors.amber : color.withAlpha(150),
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        if (isReady)
                          const Text(
                            '▶ 點擊施放技能',
                            style: TextStyle(
                              color: Colors.amber,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        else
                          Text(
                            '能量 ${agent.currentEnergy}/${agent.maxEnergy}',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 9,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 角色圖片 Widget（帶 fallback）
Widget _buildAgentAvatar(String agentId, Color color, double size) {
  final path = ImageAssets.avatarImage(agentId);
  if (path == null) return CatPlaceholder(color: color, size: size);
  return Image.asset(
    path,
    width: size,
    height: size,
    fit: BoxFit.cover,
    errorBuilder: (_, __, ___) => CatPlaceholder(color: color, size: size),
  );
}

class _InfoStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _InfoStat(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════
// 右側遊戲面板（棋盤 + 敵人資訊）
// ═══════════════════════════════════════════

class _GamePanel extends StatelessWidget {
  final BattleState? battleState;
  final GameState? gameState;

  const _GamePanel({required this.battleState, required this.gameState});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _gamePanelBg.withAlpha(200),
        border: const Border(
          left: BorderSide(color: _woodDark, width: 3),
        ),
      ),
      child: Column(
        children: [
          // Combo 顯示
          if (gameState != null && gameState!.combo > 0)
            _ComboBar(combo: gameState!.combo),

          // 棋盤
          const Expanded(
            child: Padding(
              padding: EdgeInsets.all(4),
              child: Center(child: GameBoard()),
            ),
          ),

          // 技能效果提示
          if (battleState != null)
            Consumer<BattleProvider>(
              builder: (context, battle, _) {
                return _SkillEffectBar(battleProvider: battle);
              },
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════
// 木質風格底部欄
// ═══════════════════════════════════════════

class _WoodBottomBar extends StatelessWidget {
  final GameState? gameState;
  final BattleProvider battleProvider;

  const _WoodBottomBar({
    required this.gameState,
    required this.battleProvider,
  });

  @override
  Widget build(BuildContext context) {
    final ap = gameState?.actionPoints ?? 0;
    final isLow = ap <= 3;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_woodDark, _woodMid, _woodLight],
        ),
        border: Border(
          top: BorderSide(color: _woodBorder, width: 3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.directions_walk,
            size: 16,
            color: isLow ? Colors.red : Colors.white70,
          ),
          const SizedBox(width: 4),
          Text(
            '剩餘 $ap 步',
            style: TextStyle(
              color: isLow ? Colors.red : const Color(0xFFFBBF24),
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════
// Combo 顯示
// ═══════════════════════════════════════════

class _ComboBar extends StatelessWidget {
  final int combo;

  const _ComboBar({required this.combo});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 3),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.withAlpha(200), AppTheme.blockGold.withAlpha(200)],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_fire_department, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            '${combo}x Combo!',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════
// 技能效果提示條
// ═══════════════════════════════════════════

class _SkillEffectBar extends StatelessWidget {
  final BattleProvider battleProvider;

  const _SkillEffectBar({required this.battleProvider});

  @override
  Widget build(BuildContext context) {
    final events = battleProvider.consumeEvents();
    if (events.isEmpty) return const SizedBox.shrink();

    final event = events.last;
    final (icon, color) = _eventStyle(event.type);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      margin: const EdgeInsets.only(bottom: 2),
      color: color.withAlpha(40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              event.message,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  (IconData, Color) _eventStyle(BattleEventType type) {
    switch (type) {
      case BattleEventType.damage:
        return (Icons.flash_on, Colors.orange);
      case BattleEventType.autoAttack:
        return (Icons.gps_fixed, Colors.cyan);
      case BattleEventType.enemyAttack:
        return (Icons.warning, Colors.red);
      case BattleEventType.skillActivated:
        return (Icons.auto_awesome, Colors.amber);
      case BattleEventType.enemyKilled:
        return (Icons.check_circle, Colors.green);
      case BattleEventType.heal:
        return (Icons.favorite, Colors.green);
      case BattleEventType.shield:
        return (Icons.shield, Colors.blue);
      case BattleEventType.victory:
        return (Icons.emoji_events, Colors.amber);
      case BattleEventType.defeat:
        return (Icons.close, Colors.red);
    }
  }
}

// ═══════════════════════════════════════════
// 戰鬥結束覆蓋層
// ═══════════════════════════════════════════

class BattleRewardResult {
  final int gold;
  final int exp;
  final int stars;
  final bool isFirstClear;
  final bool agentUnlocked;
  final String? unlockedAgentId;
  final Map<GameMaterial, int> materialDrops;

  const BattleRewardResult({
    this.gold = 0,
    this.exp = 0,
    this.stars = 0,
    this.isFirstClear = false,
    this.agentUnlocked = false,
    this.unlockedAgentId,
    this.materialDrops = const {},
  });
}

class _BattleEndOverlay extends StatelessWidget {
  final bool isVictory;
  final StageDefinition stage;
  final int score;
  final BattleRewardResult? reward;
  final VoidCallback onExit;
  final VoidCallback onRetry;
  final VoidCallback? onNextStage;

  const _BattleEndOverlay({
    required this.isVictory,
    required this.stage,
    required this.score,
    this.reward,
    required this.onExit,
    required this.onRetry,
    this.onNextStage,
  });

  int get _stars => reward?.stars ?? (isVictory ? 1 : 0);

  @override
  Widget build(BuildContext context) {
    final borderColor =
        isVictory ? Colors.amber.withAlpha(150) : Colors.red.withAlpha(150);
    final titleColor = isVictory ? Colors.amber : Colors.red;

    return Container(
      color: AppTheme.bgSecondary,
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          constraints: const BoxConstraints(maxWidth: 360),
          decoration: BoxDecoration(
            color: AppTheme.bgSecondary,
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            border: Border.all(color: borderColor, width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── 標題區 ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isVictory
                        ? [Colors.amber.withAlpha(30), Colors.amber.withAlpha(10)]
                        : [Colors.red.withAlpha(30), Colors.red.withAlpha(10)],
                  ),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(AppTheme.radiusLarge),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      isVictory ? '任務完成！' : '任務失敗',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: titleColor,
                      ),
                    ),
                    if (isVictory) ...[
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(3, (i) {
                          final filled = i < _stars;
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: Icon(
                              filled ? Icons.star_rounded : Icons.star_outline_rounded,
                              color: filled ? Colors.amber : Colors.grey.shade600,
                              size: 40,
                            ),
                          );
                        }),
                      ),
                    ],
                  ],
                ),
              ),

              // ── 獎勵區 ──
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isVictory && reward != null) ...[
                      // 金幣 + 經驗
                      Row(
                        children: [
                          Expanded(
                            child: _RewardCard(
                              emoji: '🪙',
                              label: '金幣',
                              value: '+${reward!.gold}',
                              color: const Color(0xFFD4A017),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _RewardCard(
                              emoji: '✨',
                              label: '經驗值',
                              value: '+${reward!.exp}',
                              color: const Color(0xFF7EC8E3),
                            ),
                          ),
                        ],
                      ),

                      // 重複通關提示
                      if (!reward!.isFirstClear)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            '(重複通關 — 半額獎勵)',
                            style: TextStyle(
                              color: AppTheme.textSecondary.withAlpha(180),
                              fontSize: 11,
                            ),
                          ),
                        ),

                      // 素材掉落
                      if (reward!.materialDrops.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '素材掉落',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: reward!.materialDrops.entries.map((e) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: AppTheme.bgCard,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: AppTheme.accentSecondary.withAlpha(60)),
                              ),
                              child: Text(
                                '${e.key.emoji} x${e.value}',
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 13,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],

                      // 新夥伴解鎖
                      if (reward!.agentUnlocked &&
                          reward!.unlockedAgentId != null) ...[
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () {
                            final def = CatAgentData.getById(reward!.unlockedAgentId!);
                            if (def != null) {
                              final overlay = Overlay.of(context);
                              late OverlayEntry entry;
                              entry = OverlayEntry(
                                builder: (_) => AgentUnlockAnimation(
                                  definition: def,
                                  onComplete: () {
                                    entry.remove();
                                  },
                                ),
                              );
                              overlay.insert(entry);
                            }
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.amber.withAlpha(30),
                                  Colors.orange.withAlpha(20),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: Colors.amber.withAlpha(100)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('🎉', style: TextStyle(fontSize: 20)),
                                const SizedBox(width: 8),
                                Text(
                                  '新夥伴加入！點擊查看',
                                  style: TextStyle(
                                    color: Colors.amber,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],

                    // 失敗時的鼓勵語
                    if (!isVictory) ...[
                      const SizedBox(height: 8),
                      Text(
                        '調整隊伍再挑戰一次吧！',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // ── 按鈕區 ──
                    // 勝利且有下一關 → 三個按鈕（返回地圖 / 再戰 / 下一關）
                    if (isVictory && onNextStage != null) ...[
                      // 下一關（主按鈕）
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: onNextStage,
                          icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                          label: const Text('繼續下一關'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accentSecondary,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: onExit,
                              icon: const Icon(Icons.map_outlined, size: 16),
                              label: const Text('返回地圖',
                                  style: TextStyle(fontSize: 13)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.textPrimary,
                                side: BorderSide(
                                    color: Colors.white.withAlpha(60)),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: onRetry,
                              icon: const Icon(Icons.refresh, size: 16),
                              label: const Text('再戰一次',
                                  style: TextStyle(fontSize: 13)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.textPrimary,
                                side: BorderSide(
                                    color: Colors.white.withAlpha(60)),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      // 無下一關或失敗 → 兩個按鈕
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: onExit,
                              icon: const Icon(Icons.map_outlined, size: 18),
                              label: const Text('返回地圖'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.textPrimary,
                                side: BorderSide(
                                    color: Colors.white.withAlpha(60)),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: onRetry,
                              icon: const Icon(Icons.refresh, size: 18),
                              label: Text(isVictory ? '再戰一次' : '重新挑戰'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isVictory
                                    ? AppTheme.accentPrimary
                                    : AppTheme.accentSecondary,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 獎勵資訊行
class _RewardSection extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _RewardSection({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.textSecondary),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 14,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

/// 獎勵卡片（金幣/經驗）
class _RewardCard extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;
  final Color color;

  const _RewardCard({
    required this.emoji,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════
// 狀態效果圖示（敵人 debuff / 我方 buff）
// ═══════════════════════════════════════════

/// 小型狀態效果圖示（用於卡片上）
class _StatusIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String tooltip;

  const _StatusIcon({
    required this.icon,
    required this.color,
    required this.label,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 3),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
        decoration: BoxDecoration(
          color: color.withAlpha(40),
          borderRadius: BorderRadius.circular(3),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 8, color: color),
            Text(
              label,
              style: TextStyle(color: color, fontSize: 7, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

/// 敵人攻擊意圖預告
class _AttackIntent extends StatelessWidget {
  final int countdown;
  final int atk;

  const _AttackIntent({required this.countdown, required this.atk});

  @override
  Widget build(BuildContext context) {
    // countdown == 1 → 下一 tick 就會攻擊（危險）
    // countdown == 2 → 即將攻擊（警告）
    final isDanger = countdown <= 1;
    final isWarning = countdown == 2;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
      decoration: BoxDecoration(
        color: isDanger
            ? Colors.red.withAlpha(60)
            : isWarning
                ? Colors.orange.withAlpha(30)
                : Colors.transparent,
        borderRadius: BorderRadius.circular(3),
        border: isDanger
            ? Border.all(color: Colors.red.withAlpha(120), width: 0.5)
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isDanger) ...[
            // 危險：顯示攻擊預告傷害
            const Icon(Icons.warning_amber_rounded, size: 8, color: Colors.red),
            const SizedBox(width: 1),
            Text(
              '$atk',
              style: const TextStyle(
                color: Colors.red,
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
            ),
          ] else ...[
            Icon(
              Icons.bolt,
              size: 8,
              color: isWarning ? Colors.orange : Colors.white54,
            ),
            Text(
              '$countdown',
              style: TextStyle(
                color: isWarning ? Colors.orange : Colors.white54,
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 團隊狀態列：HP 條 + buff 圖示
class _TeamStatusBar extends StatelessWidget {
  final BattleState battleState;

  const _TeamStatusBar({required this.battleState});

  @override
  Widget build(BuildContext context) {
    final hpPercent = battleState.teamMaxHp > 0
        ? battleState.teamCurrentHp / battleState.teamMaxHp
        : 0.0;

    final hasShield = battleState.shieldTurnsLeft > 0;
    final hasHot = battleState.hotTurnsLeft > 0;
    final hasReflect = battleState.reflectTurnsLeft > 0;
    final hasAnyBuff = hasShield || hasHot || hasReflect;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HP 條
          Row(
            children: [
              const Icon(Icons.favorite, size: 9, color: Colors.red),
              const SizedBox(width: 3),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: hpPercent,
                    minHeight: 5,
                    backgroundColor: AppTheme.bgCard,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      hpPercent > 0.5
                          ? Colors.green
                          : hpPercent > 0.25
                              ? Colors.orange
                              : Colors.red,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 3),
              Text(
                '${battleState.teamCurrentHp}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          // Buff 圖示列
          if (hasAnyBuff) ...[
            const SizedBox(height: 2),
            Row(
              children: [
                if (hasShield)
                  _BuffChip(
                    icon: Icons.shield,
                    label: '護盾 ${battleState.shieldTurnsLeft}',
                    color: Colors.blue,
                  ),
                if (hasHot)
                  _BuffChip(
                    icon: Icons.healing,
                    label: '回復 ${battleState.hotTurnsLeft}',
                    color: Colors.green,
                  ),
                if (hasReflect)
                  _BuffChip(
                    icon: Icons.replay,
                    label: '反射 ${battleState.reflectTurnsLeft}',
                    color: Colors.purple,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Buff 標籤
class _BuffChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _BuffChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
        decoration: BoxDecoration(
          color: color.withAlpha(40),
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: color.withAlpha(80), width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 8, color: color),
            const SizedBox(width: 2),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 7,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════
// 技能施放橫幅動畫（寶可夢藍寶石版飛天風格）
// 黑色電影式橫條 + 角色立繪從左滑入 + 技能名稱 + 閃光
// ═══════════════════════════════════════════

class _SkillBannerAnimation extends StatefulWidget {
  final String agentId;
  final String agentName;
  final String skillName;
  final Color color;
  final VoidCallback onComplete;

  const _SkillBannerAnimation({
    required this.agentId,
    required this.agentName,
    required this.skillName,
    required this.color,
    required this.onComplete,
  });

  @override
  State<_SkillBannerAnimation> createState() => _SkillBannerAnimationState();
}

class _SkillBannerAnimationState extends State<_SkillBannerAnimation>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  // 各階段動畫
  late Animation<double> _bannerOpenAnim;   // 黑條展開
  late Animation<double> _charSlideAnim;    // 角色滑入
  late Animation<double> _textFadeAnim;     // 文字淡入
  late Animation<double> _flashAnim;        // 閃光
  late Animation<double> _bannerCloseAnim;  // 黑條收合
  late Animation<double> _zoomAnim;         // 整體縮放（電影感）
  late Animation<double> _freezeFlashAnim;  // 開場凍結閃光

  @override
  void initState() {
    super.initState();
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1350), // 加長 150ms 給凍結幀
    );

    // Timeline（含凍結幀偏移）:
    // 0%-4%:    凍結幀白閃（新增）
    // 4%-17%:   黑條從中間展開
    // 12%-48%:  角色從左側滑入到中央
    // 27%-53%:  技能名稱淡入
    // 50%-63%:  閃光效果
    // 72%-100%: 黑條收合，整體消失

    // 凍結幀白閃
    _freezeFlashAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.5), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 0.5, end: 0.0), weight: 60),
    ]).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.06, curve: Curves.easeOut),
    ));

    _bannerOpenAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.04, 0.17, curve: Curves.easeOut),
      ),
    );

    _charSlideAnim = Tween<double>(begin: -1.5, end: 0.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.12, 0.48, curve: Curves.easeOutCubic),
      ),
    );

    _textFadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.27, 0.53, curve: Curves.easeIn),
      ),
    );

    _flashAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.8), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 0.8, end: 0.0), weight: 60),
    ]).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.50, 0.63, curve: Curves.easeOut),
      ),
    );

    _bannerCloseAnim = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.72, 1.0, curve: Curves.easeInCubic),
      ),
    );

    // 整體縮放：微縮出→回彈（電影感 zoom）
    _zoomAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.97), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 0.97, end: 0.97), weight: 55),
      TweenSequenceItem(tween: Tween(begin: 0.97, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(
      parent: _mainController,
      curve: Curves.easeInOut,
    ));

    HapticFeedback.heavyImpact();
    _mainController.forward().then((_) => widget.onComplete());
  }

  @override
  void dispose() {
    _mainController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final bannerHeight = screenSize.height * 0.28;
    final charImagePath = ImageAssets.characterImage(widget.agentId);

    return AnimatedBuilder(
      animation: _mainController,
      builder: (context, _) {
        // 整體可見度（開合階段）
        final bannerScale = _mainController.value < 0.72
            ? _bannerOpenAnim.value
            : _bannerCloseAnim.value;

        if (bannerScale <= 0.01 && _freezeFlashAnim.value <= 0.01) {
          return const SizedBox.shrink();
        }

        return Transform.scale(
          scale: _zoomAnim.value,
          child: Stack(
            children: [
              // 凍結幀白閃（技能施放瞬間的衝擊感）
              if (_freezeFlashAnim.value > 0.01)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      color: Colors.white.withAlpha(
                        (_freezeFlashAnim.value * 255).round().clamp(0, 255),
                      ),
                    ),
                  ),
                ),
              // 半透明背景遮罩
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    color: Colors.black.withAlpha((bannerScale * 120).round()),
                  ),
              ),
            ),

            // 中央橫幅區域
            Center(
              child: ClipRect(
                child: Align(
                  alignment: Alignment.center,
                  heightFactor: bannerScale.clamp(0.0, 1.0),
                  child: Container(
                    width: screenSize.width,
                    height: bannerHeight,
                    decoration: BoxDecoration(
                      // 斜切黑條（類似寶可夢風格）
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withAlpha(0),
                          Colors.black.withAlpha(220),
                          Colors.black.withAlpha(240),
                          Colors.black.withAlpha(220),
                          Colors.black.withAlpha(0),
                        ],
                        stops: const [0.0, 0.15, 0.5, 0.85, 1.0],
                      ),
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // 上下彩色線條
                        Positioned(
                          top: bannerHeight * 0.12,
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 2,
                            color: widget.color.withAlpha(180),
                          ),
                        ),
                        Positioned(
                          bottom: bannerHeight * 0.12,
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 2,
                            color: widget.color.withAlpha(180),
                          ),
                        ),

                        // 角色立繪（從左滑入）
                        Positioned(
                          left: screenSize.width * 0.05 +
                              (_charSlideAnim.value * screenSize.width * 0.3),
                          top: -bannerHeight * 0.15,
                          child: Opacity(
                            opacity: (_charSlideAnim.value + 1.5).clamp(0.0, 1.0),
                            child: SizedBox(
                              height: bannerHeight * 1.3,
                              width: bannerHeight * 1.0,
                              child: charImagePath != null
                                  ? Image.asset(
                                      charImagePath,
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, __, ___) =>
                                          CatPlaceholder(
                                        color: widget.color,
                                        size: bannerHeight * 0.8,
                                      ),
                                    )
                                  : CatPlaceholder(
                                      color: widget.color,
                                      size: bannerHeight * 0.8,
                                    ),
                            ),
                          ),
                        ),

                        // 技能名稱（右側）
                        Positioned(
                          right: screenSize.width * 0.08,
                          top: 0,
                          bottom: 0,
                          child: Opacity(
                            opacity: _textFadeAnim.value,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                // 角色名
                                Text(
                                  widget.agentName,
                                  style: TextStyle(
                                    color: widget.color,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 2,
                                    shadows: [
                                      Shadow(
                                        color: widget.color.withAlpha(120),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                // 技能名
                                Text(
                                  widget.skillName,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 3,
                                    shadows: [
                                      Shadow(
                                        color: widget.color.withAlpha(200),
                                        blurRadius: 12,
                                      ),
                                      const Shadow(
                                        color: Colors.black,
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // 閃光效果
                        if (_flashAnim.value > 0.01)
                          Positioned.fill(
                            child: IgnorePointer(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: RadialGradient(
                                    center: const Alignment(-0.2, 0.0),
                                    radius: 1.5,
                                    colors: [
                                      widget.color
                                          .withAlpha((_flashAnim.value * 200).round()),
                                      Colors.white
                                          .withAlpha((_flashAnim.value * 100).round()),
                                      Colors.transparent,
                                    ],
                                    stops: const [0.0, 0.3, 1.0],
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            ],
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════
// 戰鬥結束爆炸演出
// ═══════════════════════════════════════════

class _BattleEndExplosion extends StatefulWidget {
  final bool isVictory;
  final VoidCallback onComplete;

  const _BattleEndExplosion({
    required this.isVictory,
    required this.onComplete,
  });

  @override
  State<_BattleEndExplosion> createState() => _BattleEndExplosionState();
}

class _BattleEndExplosionState extends State<_BattleEndExplosion>
    with TickerProviderStateMixin {
  late AnimationController _flashController;
  late AnimationController _expandController;
  late AnimationController _textController;

  late Animation<double> _flashOpacity;
  late Animation<double> _expandScale;
  late Animation<double> _expandOpacity;
  late Animation<double> _textScale;
  late Animation<double> _textOpacity;

  @override
  void initState() {
    super.initState();

    // 階段 1：白色閃光（0~600ms）
    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _flashOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.9), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.9, end: 0.0), weight: 70),
    ]).animate(CurvedAnimation(
      parent: _flashController,
      curve: Curves.easeOut,
    ));

    // 階段 2：擴散光環（200ms~1400ms）
    _expandController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _expandScale = Tween<double>(begin: 0.0, end: 3.0).animate(
      CurvedAnimation(parent: _expandController, curve: Curves.easeOutCubic),
    );
    _expandOpacity = Tween<double>(begin: 0.8, end: 0.0).animate(
      CurvedAnimation(parent: _expandController, curve: Curves.easeIn),
    );

    // 階段 3：文字彈入（500ms~1500ms）
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _textScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.4), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.4, end: 0.9), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.05), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 1.05, end: 1.0), weight: 35),
    ]).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeOut,
    ));
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
      ),
    );

    _startSequence();
  }

  Future<void> _startSequence() async {
    // 階段 1：閃光
    HapticFeedback.heavyImpact();
    _flashController.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;

    // 階段 2：擴散光環
    _expandController.forward();
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    // 階段 3：文字彈入
    HapticFeedback.mediumImpact();
    _textController.forward();
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;

    widget.onComplete();
  }

  @override
  void dispose() {
    _flashController.dispose();
    _expandController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isVictory ? Colors.amber : Colors.red;
    final text = widget.isVictory ? '勝利！' : '失敗...';

    return Stack(
      children: [
        // 半透明黑底（漸入）
        AnimatedBuilder(
          animation: _flashController,
          builder: (_, __) {
            return Container(
              color: Colors.black.withAlpha(
                (_flashController.value * 120).round().clamp(0, 120),
              ),
            );
          },
        ),

        // 白色閃光
        AnimatedBuilder(
          animation: _flashOpacity,
          builder: (_, __) {
            return Container(
              color: Colors.white.withAlpha(
                (_flashOpacity.value * 255).round().clamp(0, 255),
              ),
            );
          },
        ),

        // 擴散光環
        Center(
          child: AnimatedBuilder(
            animation: _expandController,
            builder: (_, __) {
              return Opacity(
                opacity: _expandOpacity.value.clamp(0.0, 1.0),
                child: Transform.scale(
                  scale: _expandScale.value,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: color, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: color.withAlpha(100),
                          blurRadius: 40,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // 放射線條
        Center(
          child: AnimatedBuilder(
            animation: _expandController,
            builder: (_, __) {
              return Opacity(
                opacity: _expandOpacity.value.clamp(0.0, 1.0),
                child: CustomPaint(
                  size: const Size(300, 300),
                  painter: _RadialBurstPainter(
                    progress: _expandScale.value / 3.0,
                    color: color,
                  ),
                ),
              );
            },
          ),
        ),

        // 文字
        Center(
          child: AnimatedBuilder(
            animation: _textController,
            builder: (_, __) {
              return Opacity(
                opacity: _textOpacity.value.clamp(0.0, 1.0),
                child: Transform.scale(
                  scale: _textScale.value,
                  child: Text(
                    text,
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      color: color,
                      letterSpacing: 6,
                      shadows: [
                        Shadow(
                          color: color.withAlpha(180),
                          blurRadius: 24,
                        ),
                        const Shadow(
                          color: Colors.black,
                          blurRadius: 8,
                          offset: Offset(2, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// 放射爆發線條
class _RadialBurstPainter extends CustomPainter {
  final double progress;
  final Color color;

  _RadialBurstPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxLen = size.width / 2;
    const numRays = 12;

    final paint = Paint()
      ..color = color.withAlpha((180 * (1.0 - progress)).round().clamp(0, 255))
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < numRays; i++) {
      final angle = (i / numRays) * pi * 2;
      final innerR = maxLen * progress * 0.3;
      final outerR = maxLen * progress;
      final start = Offset(
        center.dx + cos(angle) * innerR,
        center.dy + sin(angle) * innerR,
      );
      final end = Offset(
        center.dx + cos(angle) * outerR,
        center.dy + sin(angle) * outerR,
      );
      canvas.drawLine(start, end, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RadialBurstPainter old) =>
      old.progress != progress;
}

// ═══════════════════════════════════════════
// Boss 對話演出
// ═══════════════════════════════════════════

class _BossIntroOverlay extends StatefulWidget {
  final int chapter;
  final VoidCallback onComplete;

  const _BossIntroOverlay({
    required this.chapter,
    required this.onComplete,
  });

  @override
  State<_BossIntroOverlay> createState() => _BossIntroOverlayState();
}

class _BossIntroOverlayState extends State<_BossIntroOverlay>
    with TickerProviderStateMixin {
  late AnimationController _entranceController;
  late Animation<double> _bgFade;
  late Animation<Offset> _bossSlide;
  late Animation<double> _bossFade;

  int _currentLine = 0;
  String _displayedText = '';
  bool _isTyping = false;

  BossDialogue? get _dialogue => bossDialogues[widget.chapter];

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _bgFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );

    _bossSlide = Tween<Offset>(
      begin: const Offset(-1.0, 0.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.2, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    _bossFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.2, 0.6, curve: Curves.easeIn),
      ),
    );

    HapticFeedback.heavyImpact();
    _entranceController.forward().then((_) {
      _typeCurrentLine();
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  void _typeCurrentLine() {
    final lines = _dialogue?.introLines ?? [];
    if (_currentLine >= lines.length) return;

    _isTyping = true;
    _displayedText = '';
    final fullText = lines[_currentLine];
    int charIndex = 0;

    Future.doWhile(() async {
      if (!mounted || charIndex >= fullText.length) {
        if (mounted) setState(() => _isTyping = false);
        return false;
      }
      await Future.delayed(const Duration(milliseconds: 40));
      if (!mounted) return false;
      charIndex++;
      setState(() {
        _displayedText = fullText.substring(0, charIndex);
      });
      return charIndex < fullText.length;
    });
  }

  void _onTap() {
    final lines = _dialogue?.introLines ?? [];

    if (_isTyping) {
      // 跳過打字效果，直接顯示完整文字
      setState(() {
        _displayedText = lines[_currentLine];
        _isTyping = false;
      });
      return;
    }

    // 下一句
    if (_currentLine < lines.length - 1) {
      setState(() => _currentLine++);
      _typeCurrentLine();
    } else {
      // 對話結束
      widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dialogue = _dialogue;
    if (dialogue == null) {
      widget.onComplete();
      return const SizedBox.shrink();
    }

    final screenSize = MediaQuery.of(context).size;
    final bossImagePath = ImageAssets.bossImage(widget.chapter);
    final lines = dialogue.introLines;
    final isLastLine = _currentLine >= lines.length - 1 && !_isTyping;

    return AnimatedBuilder(
      animation: _entranceController,
      builder: (context, _) {
        return GestureDetector(
          onTap: _onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            color: Colors.black.withAlpha((_bgFade.value * 200).round()),
            child: Stack(
              children: [
                // Boss 立繪（左側大圖）
                Positioned(
                  left: 0,
                  bottom: screenSize.height * 0.15,
                  child: SlideTransition(
                    position: _bossSlide,
                    child: FadeTransition(
                      opacity: _bossFade,
                      child: SizedBox(
                        height: screenSize.height * 0.55,
                        child: Image.asset(
                          bossImagePath,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => SizedBox(
                            width: 200,
                            child: Center(
                              child: Text(
                                dialogue.bossName,
                                style: const TextStyle(
                                  fontSize: 48,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // 對話框（底部）
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: FadeTransition(
                    opacity: _bossFade,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withAlpha(0),
                            Colors.black.withAlpha(220),
                            Colors.black.withAlpha(240),
                          ],
                          stops: const [0.0, 0.25, 1.0],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Boss 名稱
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.withAlpha(150),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              dialogue.bossName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // 對話文字
                          SizedBox(
                            height: 50,
                            child: Text(
                              _displayedText,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                height: 1.5,
                                shadows: [
                                  Shadow(
                                    color: Colors.black,
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // 提示文字
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              isLastLine ? '▶ 點擊開戰！' : '▶ 點擊繼續',
                              style: TextStyle(
                                color: isLastLine
                                    ? Colors.amber
                                    : Colors.white.withAlpha(180),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════
// 首戰引導 Overlay（1-1 首次進入時顯示）
// ═══════════════════════════════════════════

class _FirstBattleGuide extends StatelessWidget {
  final int step;
  final VoidCallback onNext;

  const _FirstBattleGuide({
    required this.step,
    required this.onNext,
  });

  static const _steps = [
    (
      title: '⚔️ 消除方塊攻擊搗蛋鬼！',
      description: '消除棋盤上的方塊就能對搗蛋鬼造成傷害。\n'
          '消除越多、連鎖越長，傷害越高！\n\n'
          '注意左上方搗蛋鬼的血量條！',
      buttonText: '了解！',
    ),
    (
      title: '🐱 夥伴技能',
      description: '消除方塊時，左側夥伴的技能條會充能。\n'
          '充滿後會自動施放技能 — 造成大量傷害！\n\n'
          '準備好了嗎？開始戰鬥吧！',
      buttonText: '開始戰鬥！',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final s = _steps[step.clamp(0, _steps.length - 1)];

    return Stack(
      children: [
        // 半透明遮罩
        Positioned.fill(
          child: GestureDetector(
            onTap: () {},
            child: Container(color: Colors.black.withAlpha(140)),
          ),
        ),

        // 對話框
        Positioned(
          left: 20,
          right: 20,
          bottom: MediaQuery.of(context).padding.bottom + 24,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _panelBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _woodBorder, width: 2),
              boxShadow: [
                BoxShadow(
                  color: _woodDark.withAlpha(60),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.title,
                  style: const TextStyle(
                    color: Color(0xFF5D4037),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  s.description,
                  style: TextStyle(
                    color: const Color(0xFF5D4037).withAlpha(200),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _woodDark,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      s.buttonText,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // 步驟指示器
        Positioned(
          left: 0,
          right: 0,
          bottom: MediaQuery.of(context).padding.bottom + 8,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_steps.length, (i) {
              final active = i == step;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: active ? 20 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: active ? _woodDark : _woodMid.withAlpha(120),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}
