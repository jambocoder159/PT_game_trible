/// 戰鬥畫面（手機版優化）
/// 闖關模式：左側角色面板 + 右側棋盤，木質風格 UI
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../config/game_modes.dart';
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
import '../widgets/game_board.dart';
import '../widgets/cat_placeholder.dart';
import '../widgets/pause_menu.dart';

// ─── 木質風格配色 ───
const _woodLight = Color(0xFFC4A24E);
const _woodMid = Color(0xFFA0852B);
const _woodDark = Color(0xFF8B6914);
const _woodBorder = Color(0xFF6B4F0E);
const _panelBg = Color(0xFF4A5568);
const _gamePanelBg = Color(0xFF5BA8A0);

/// 戰鬥畫面
class BattleScreen extends StatefulWidget {
  final StageDefinition stage;

  const BattleScreen({super.key, required this.stage});

  @override
  State<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends State<BattleScreen> {
  bool _resultSaved = false;
  BattleRewardResult? _reward;
  bool _boardOnLeft = false; // 預設棋盤在右側（截圖佈局）

  @override
  void initState() {
    super.initState();
    _loadBoardPosition();
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
    gameProvider.onTurnEnd = () {
      battleProvider.onTurnEnd();
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
    final reward = await playerProvider.completeBattle(
      stageId: widget.stage.id,
      isVictory: isVictory,
      score: score,
      twoStarScore: widget.stage.twoStarScore,
      threeStarScore: widget.stage.threeStarScore,
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
    });

    final battleProvider = context.read<BattleProvider>();
    battleProvider.endBattle();
    _initBattle();
  }

  @override
  void dispose() {
    final gameProvider = context.read<GameProvider>();
    final battleProvider = context.read<BattleProvider>();
    gameProvider.onMatchTurnComplete = null;
    gameProvider.onTurnEnd = null;
    battleProvider.onBoardEffectRequested = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2D3748),
      body: SafeArea(
        child: Consumer2<GameProvider, BattleProvider>(
          builder: (context, game, battle, _) {
            final gameState = game.state;
            final battleState = battle.battleState;

            return Stack(
              children: [
                Column(
                  children: [
                    // ── 頂部木質風格標題欄 ──
                    _WoodTopBar(
                      stage: widget.stage,
                      gameState: gameState,
                      onBack: () {
                        battle.endBattle();
                        Navigator.of(context).pop();
                      },
                      onToggle: _toggleBoardPosition,
                      onPause: () => game.pauseGame(),
                    ),

                    // ── 主體分屏區域 ──
                    Expanded(
                      child: Row(
                        children: _boardOnLeft
                            ? [
                                // 棋盤在左
                                Expanded(
                                  flex: 6,
                                  child: _GamePanel(
                                    battleState: battleState,
                                    gameState: gameState,
                                  ),
                                ),
                                // 角色在右
                                if (battleState != null)
                                  Expanded(
                                    flex: 4,
                                    child: _CatAgentPanel(
                                      battleState: battleState,
                                      battleProvider: battle,
                                    ),
                                  ),
                              ]
                            : [
                                // 角色在左（截圖預設佈局）
                                if (battleState != null)
                                  Expanded(
                                    flex: 4,
                                    child: _CatAgentPanel(
                                      battleState: battleState,
                                      battleProvider: battle,
                                    ),
                                  ),
                                // 棋盤在右
                                Expanded(
                                  flex: 6,
                                  child: _GamePanel(
                                    battleState: battleState,
                                    gameState: gameState,
                                  ),
                                ),
                              ],
                      ),
                    ),

                    // ── 底部控制列 ──
                    _WoodBottomBar(
                      gameState: gameState,
                      battleProvider: battle,
                    ),
                  ],
                ),

                // 暫停選單覆蓋層
                if (gameState?.status == GameStatus.paused)
                  PauseMenu(
                    onResume: () => game.resumeGame(),
                    onExitToMenu: () {
                      battle.endBattle();
                      Navigator.of(context).pop();
                    },
                  ),

                // 戰鬥結束
                if (battle.isBattleOver) ...[
                  Builder(builder: (_) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _saveResult(battle.isVictory, gameState?.score ?? 0);
                    });
                    return const SizedBox.shrink();
                  }),
                  _BattleEndOverlay(
                    isVictory: battle.isVictory,
                    stage: widget.stage,
                    score: gameState?.score ?? 0,
                    reward: _reward,
                    onExit: () {
                      battle.endBattle();
                      Navigator.of(context).pop();
                    },
                    onRetry: () => _retryBattle(context),
                  ),
                ],

                if (gameState?.status == GameStatus.gameOver &&
                    !battle.isBattleOver) ...[
                  Builder(builder: (_) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _saveResult(false, gameState?.score ?? 0);
                    });
                    return const SizedBox.shrink();
                  }),
                  _BattleEndOverlay(
                    isVictory: false,
                    stage: widget.stage,
                    score: gameState?.score ?? 0,
                    reward: _reward,
                    onExit: () {
                      battle.endBattle();
                      Navigator.of(context).pop();
                    },
                    onRetry: () => _retryBattle(context),
                  ),
                ],
              ],
            );
          },
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
  final GameState? gameState;
  final VoidCallback onBack;
  final VoidCallback onToggle;
  final VoidCallback onPause;

  const _WoodTopBar({
    required this.stage,
    required this.gameState,
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
          // SCORE
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'SCORE',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  '${gameState?.score ?? 0}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    shadows: [Shadow(color: Colors.black38, blurRadius: 2)],
                  ),
                ),
              ],
            ),
          ),
          // STAGE
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'STAGE',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                stage.id,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFFFF3CD),
                  shadows: [Shadow(color: Colors.black38, blurRadius: 2)],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
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
          color: Colors.black26,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white30, width: 1.5),
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

  _RushAnimData({
    required this.from,
    required this.to,
    required this.emoji,
    required this.color,
    required this.damage,
    required this.isPlayerAttack,
    this.targetIndex,
  });
}

/// 飄浮傷害數字資料
class _DamagePopupData {
  final Offset position;
  final int damage;
  final Color color;
  final UniqueKey key = UniqueKey();

  _DamagePopupData({
    required this.position,
    required this.damage,
    required this.color,
  });
}

class _CatAgentPanel extends StatefulWidget {
  final BattleState battleState;
  final BattleProvider battleProvider;

  const _CatAgentPanel({
    required this.battleState,
    required this.battleProvider,
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
    for (final event in events) {
      if (event.type == BattleEventType.autoAttack &&
          event.attackerIndex != null &&
          event.targetIndex != null) {
        // 我方攻擊 → 從角色卡牌衝向敵人卡牌
        final from = _getCardCenter(
            event.attackerIndex! < _playerKeys.length
                ? _playerKeys[event.attackerIndex!]
                : _playerKeys.last);
        final to = _getCardCenter(
            event.targetIndex! < _enemyKeys.length
                ? _enemyKeys[event.targetIndex!]
                : _enemyKeys.last);
        if (from != null && to != null) {
          _activeRushAnims.add(_RushAnimData(
            from: from,
            to: to,
            emoji: event.emoji ?? '⚔',
            color: Colors.cyan,
            damage: event.value,
            isPlayerAttack: true,
            targetIndex: event.targetIndex,
          ));
        }
      } else if (event.type == BattleEventType.enemyAttack &&
          event.attackerIndex != null) {
        // 敵人攻擊 → 從敵人卡牌衝向我方區域
        final from = _getCardCenter(
            event.attackerIndex! < _enemyKeys.length
                ? _enemyKeys[event.attackerIndex!]
                : _enemyKeys.last);
        final to = _getPlayerSectionCenter();
        if (from != null && to != null) {
          _activeRushAnims.add(_RushAnimData(
            from: from,
            to: to,
            emoji: event.emoji ?? '👊',
            color: Colors.red,
            damage: event.value,
            isPlayerAttack: false,
          ));
        }
      }
    }
  }

  void _onRushHit(_RushAnimData data) {
    setState(() {
      // 在目標位置加傷害數字
      _activeDamagePopups.add(_DamagePopupData(
        position: data.to + const Offset(-12, -20),
        damage: data.damage,
        color: data.isPlayerAttack ? Colors.white : Colors.red,
      ));
      // 觸發目標閃爍
      if (data.isPlayerAttack && data.targetIndex != null) {
        _enemyHitStates[data.targetIndex!] = true;
        Future.delayed(const Duration(milliseconds: 150), () {
          if (mounted) setState(() => _enemyHitStates[data.targetIndex!] = false);
        });
      } else if (!data.isPlayerAttack) {
        _playerSectionHit = true;
        Future.delayed(const Duration(milliseconds: 150), () {
          if (mounted) setState(() => _playerSectionHit = false);
        });
      }
    });
  }

  void _removeRush(_RushAnimData data) {
    if (mounted) setState(() => _activeRushAnims.remove(data));
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
                Color(0xFF7BA0C4),
                Color(0xFFA8C4D9),
                Color(0xFFD4C5A9),
                Color(0xFF9E9E9E),
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
                color: Colors.white24,
                margin: const EdgeInsets.symmetric(horizontal: 6),
              ),
              // ── 下半：我方角色 ──
              Expanded(
                flex: 5,
                child: _ShakeWrapper(
                  key: _playerSectionKey,
                  isShaking: _playerSectionHit,
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
        // 衝撞動畫層
        ..._activeRushAnims.map((rush) => _RushAttackWidget(
          key: rush.key,
          data: rush,
          onHit: () => _onRushHit(rush),
          onComplete: () => _removeRush(rush),
        )),
        // 飄浮傷害數字層
        ..._activeDamagePopups.map((popup) => _DamagePopup(
          key: popup.key,
          position: popup.position,
          damage: popup.damage,
          color: popup.color,
          onComplete: () => _removePopup(popup),
        )),
      ],
    );
  }
}

// ═══════════════════════════════════════════
// 晃動包裝器（敵人攻擊時我方區域晃動）
// ═══════════════════════════════════════════

class _ShakeWrapper extends StatefulWidget {
  final bool isShaking;
  final Widget child;

  const _ShakeWrapper({
    super.key,
    required this.isShaking,
    required this.child,
  });

  @override
  State<_ShakeWrapper> createState() => _ShakeWrapperState();
}

class _ShakeWrapperState extends State<_ShakeWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
  }

  @override
  void didUpdateWidget(covariant _ShakeWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isShaking && !oldWidget.isShaking) {
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
        final offset = sin(_controller.value * pi * 4) * 4.0 *
            (1.0 - _controller.value);
        return Transform.translate(
          offset: Offset(offset, 0),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

// ═══════════════════════════════════════════
// 角色衝撞動畫
// ═══════════════════════════════════════════

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
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _positionAnim;
  late Animation<double> _scaleXAnim;
  late Animation<double> _scaleYAnim;
  bool _hitFired = false;
  bool _showImpact = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    // 位置：0→1→0（衝出→撞擊→彈回）
    _positionAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.0), // 停頓
        weight: 10,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
    ]).animate(_controller);

    // scaleX：撞擊時壓扁
    _scaleXAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 45),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 10),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 10),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 35),
    ]).animate(_controller);

    // scaleY：撞擊時壓扁
    _scaleYAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 45),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.7), weight: 10),
      TweenSequenceItem(tween: Tween(begin: 0.7, end: 1.0), weight: 10),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 35),
    ]).animate(_controller);

    _controller.addListener(_checkHit);
    _controller.forward().then((_) => widget.onComplete());
  }

  void _checkHit() {
    // 在 50% 時觸發撞擊（到達目標）
    if (!_hitFired && _controller.value >= 0.50) {
      _hitFired = true;
      widget.onHit();
      setState(() => _showImpact = true);
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted) setState(() => _showImpact = false);
      });
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_checkHit);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        final t = _positionAnim.value;
        final pos = Offset.lerp(widget.data.from, widget.data.to, t)!;

        return Stack(
          children: [
            // 衝撞 emoji
            Positioned(
              left: pos.dx - 14,
              top: pos.dy - 14,
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..scale(_scaleXAnim.value, _scaleYAnim.value),
                child: Text(
                  widget.data.emoji,
                  style: TextStyle(
                    fontSize: 24,
                    shadows: [
                      Shadow(
                        color: widget.data.color.withAlpha(180),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // 撞擊特效
            if (_showImpact)
              Positioned(
                left: widget.data.to.dx - 14,
                top: widget.data.to.dy - 14,
                child: const Text(
                  '💥',
                  style: TextStyle(fontSize: 24),
                ),
              ),
          ],
        );
      },
    );
  }
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

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _slideAnim = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -1.5),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.4), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.4, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _opacityAnim = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 1.0, curve: Curves.easeIn),
      ),
    );

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
          return SlideTransition(
            position: _slideAnim,
            child: ScaleTransition(
              scale: _scaleAnim,
              child: FadeTransition(
                opacity: _opacityAnim,
                child: child,
              ),
            ),
          );
        },
        child: Text(
          '-${widget.damage}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: widget.color,
            shadows: [
              Shadow(
                color: widget.color.withAlpha(150),
                blurRadius: 8,
              ),
              const Shadow(
                color: Colors.black,
                blurRadius: 4,
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
        );
      }).toList(),
    );
  }
}

/// 單一敵人卡牌（含命中閃爍效果）
class _EnemyCard extends StatelessWidget {
  final EnemyInstance enemy;
  final bool isCurrent;
  final bool isHit;

  const _EnemyCard({
    super.key,
    required this.enemy,
    required this.isCurrent,
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
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Text(enemy.definition.emoji, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 4),
                Text(
                  '${enemy.definition.name} ✕',
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 9,
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isHit
                  ? Colors.white.withAlpha(120)
                  : isCurrent
                      ? Colors.black38
                      : Colors.black12,
              borderRadius: BorderRadius.circular(6),
              border: isCurrent
                  ? Border.all(color: Colors.red.withAlpha(150), width: 1.5)
                  : null,
            ),
            child: Row(
              children: [
                // Speed 環圈 + Emoji
                CatStatusRing(
                  ringColor: color,
                  progress: countdownPercent,
                  size: 36,
                  child: Container(
                    color: color.withAlpha(30),
                    child: Center(
                      child: Text(enemy.definition.emoji, style: const TextStyle(fontSize: 16)),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                // 名稱 + HP + ATK
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        enemy.definition.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          shadows: [Shadow(color: Colors.black54, blurRadius: 2)],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 1),
                      // HP 條
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: enemy.hpPercent,
                          minHeight: 4,
                          backgroundColor: Colors.black26,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            enemy.hpPercent > 0.5
                                ? Colors.green
                                : enemy.hpPercent > 0.25
                                    ? Colors.orange
                                    : Colors.red,
                          ),
                        ),
                      ),
                      const SizedBox(height: 1),
                      Row(
                        children: [
                          Text(
                            'ATK ${enemy.atk}',
                            style: TextStyle(
                              color: Colors.red.shade200,
                              fontSize: 7,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.bolt,
                            size: 8,
                            color: enemy.attackCountdown <= 1
                                ? Colors.red
                                : Colors.white54,
                          ),
                          Text(
                            '${enemy.attackCountdown}',
                            style: TextStyle(
                              color: enemy.attackCountdown <= 1
                                  ? Colors.red
                                  : Colors.white54,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
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
      children: battleState.team.asMap().entries.map((entry) {
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
      }).toList(),
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
              CatStatusRing(
                ringColor: color,
                isReady: true,
                size: 56,
                child: CatPlaceholder(color: color, size: 50),
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

/// 單一我方角色卡片（含 Speed 環圈 + 能量條）
class _CatAgentCard extends StatelessWidget {
  final BattleAgent agent;
  final VoidCallback onTap;

  const _CatAgentCard({super.key, required this.agent, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = agent.definition.attribute.blockColor.color;
    final isReady = agent.isSkillReady;
    final ringColor = isReady ? Colors.amber : color;

    return GestureDetector(
      onTap: isReady ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isReady ? Colors.black38 : Colors.black12,
            borderRadius: BorderRadius.circular(6),
            border: isReady
                ? Border.all(color: Colors.amber.withAlpha(150), width: 1.5)
                : null,
          ),
          child: Row(
            children: [
              // Speed 環圈 + 貓咪
              CatStatusRing(
                ringColor: ringColor,
                isReady: isReady,
                progress: agent.attackCountdownPercent,
                size: 40,
                child: CatPlaceholder(color: color, size: 34),
              ),
              const SizedBox(width: 4),
              // 資訊
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 名稱 + ATK
                    Row(
                      children: [
                        Text(
                          agent.definition.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            shadows: [Shadow(color: Colors.black54, blurRadius: 2)],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Spacer(),
                        Text(
                          '⚔${agent.atk}',
                          style: TextStyle(
                            color: Colors.orange.shade200,
                            fontSize: 7,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    // 能量條
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: agent.energyPercent,
                        minHeight: 4,
                        backgroundColor: Colors.black26,
                        valueColor: AlwaysStoppedAnimation(
                          isReady ? Colors.amber : color.withAlpha(150),
                        ),
                      ),
                    ),
                    const SizedBox(height: 1),
                    // 能量數字 or 施放提示
                    if (isReady)
                      const Text(
                        '▶ 點擊施放技能',
                        style: TextStyle(
                          color: Colors.amber,
                          fontSize: 7,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    else
                      Text(
                        '能量 ${agent.currentEnergy}/${agent.maxEnergy}  SPD ${agent.speed}',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 7,
                        ),
                      ),
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
        color: _gamePanelBg,
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
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // 步數
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.directions_walk, size: 14, color: Colors.white70),
              const SizedBox(width: 3),
              Text(
                '${gameState?.actionPoints ?? 0}',
                style: const TextStyle(
                  color: Color(0xFFFBBF24),
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          // 分數
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star, size: 14, color: Colors.amber),
              const SizedBox(width: 3),
              Text(
                '${gameState?.score ?? 0}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          // 操作次數
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.touch_app, size: 14, color: Colors.white54),
              const SizedBox(width: 3),
              Text(
                '${gameState?.actionCount ?? 0}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
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

  const _BattleEndOverlay({
    required this.isVictory,
    required this.stage,
    required this.score,
    this.reward,
    required this.onExit,
    required this.onRetry,
  });

  int get _stars => reward?.stars ?? (isVictory ? 1 : 0);

  @override
  Widget build(BuildContext context) {
    final borderColor =
        isVictory ? Colors.amber.withAlpha(150) : Colors.red.withAlpha(150);
    final titleColor = isVictory ? Colors.amber : Colors.red;

    return Container(
      color: Colors.black.withAlpha(180),
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
                    // 分數
                    _RewardSection(
                      icon: Icons.scoreboard_outlined,
                      label: '分數',
                      value: '$score',
                    ),
                    const SizedBox(height: 10),

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
                                color: Colors.white.withAlpha(15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: Colors.white.withAlpha(30)),
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

                      // 新特工解鎖
                      if (reward!.agentUnlocked &&
                          reward!.unlockedAgentId != null) ...[
                        const SizedBox(height: 12),
                        Container(
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
                                '新特工加入！',
                                style: TextStyle(
                                  color: Colors.amber.shade300,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ],
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
                    Row(
                      children: [
                        // 返回地圖
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
                        // 重試
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
