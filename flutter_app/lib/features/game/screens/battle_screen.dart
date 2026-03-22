/// 戰鬥畫面（手機版優化）
/// 闖關模式：左側角色面板 + 右側棋盤，木質風格 UI
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

  const _WoodTopBar({
    required this.stage,
    required this.gameState,
    required this.onBack,
    required this.onToggle,
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
// 左側面板：敵人卡牌（上）+ 我方角色（下）
// ═══════════════════════════════════════════

class _CatAgentPanel extends StatelessWidget {
  final BattleState battleState;
  final BattleProvider battleProvider;

  const _CatAgentPanel({
    required this.battleState,
    required this.battleProvider,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
            child: _EnemyCardsSection(battleState: battleState),
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
            child: _PlayerCardsSection(
              battleState: battleState,
              battleProvider: battleProvider,
            ),
          ),
        ],
      ),
    );
  }
}

/// 敵人卡牌區域
class _EnemyCardsSection extends StatelessWidget {
  final BattleState battleState;

  const _EnemyCardsSection({required this.battleState});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      children: battleState.enemies.asMap().entries.map((entry) {
        final enemy = entry.value;
        final isCurrent = entry.key == battleState.currentEnemyIndex;
        return _EnemyCard(enemy: enemy, isCurrent: isCurrent);
      }).toList(),
    );
  }
}

/// 單一敵人卡牌
class _EnemyCard extends StatelessWidget {
  final EnemyInstance enemy;
  final bool isCurrent;

  const _EnemyCard({required this.enemy, required this.isCurrent});

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
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isCurrent ? Colors.black38 : Colors.black12,
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
    );
  }
}

/// 我方角色卡牌區域
class _PlayerCardsSection extends StatelessWidget {
  final BattleState battleState;
  final BattleProvider battleProvider;

  const _PlayerCardsSection({
    required this.battleState,
    required this.battleProvider,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      children: battleState.team.asMap().entries.map((entry) {
        final index = entry.key;
        final agent = entry.value;
        return _CatAgentCard(
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

  const _CatAgentCard({required this.agent, required this.onTap});

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

  const _BattleEndOverlay({
    required this.isVictory,
    required this.stage,
    required this.score,
    this.reward,
    required this.onExit,
  });

  int get _stars => reward?.stars ?? (isVictory ? 1 : 0);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withAlpha(180),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.bgSecondary,
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            border: Border.all(
              color: isVictory
                  ? Colors.amber.withAlpha(150)
                  : Colors.red.withAlpha(150),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isVictory ? '任務完成！' : '任務失敗',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: isVictory ? Colors.amber : Colors.red,
                ),
              ),
              const SizedBox(height: 16),
              if (isVictory) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (i) {
                    return Icon(
                      i < _stars ? Icons.star : Icons.star_border,
                      color: i < _stars ? Colors.amber : Colors.grey,
                      size: 36,
                    );
                  }),
                ),
                const SizedBox(height: 16),
              ],
              if (isVictory && reward != null) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('🪙 +${reward!.gold}',
                        style: const TextStyle(
                            color: AppTheme.textPrimary, fontSize: 16)),
                    const SizedBox(width: 16),
                    Text('✨ +${reward!.exp} EXP',
                        style: const TextStyle(
                            color: AppTheme.textPrimary, fontSize: 16)),
                  ],
                ),
                if (!reward!.isFirstClear)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      '(重複通關 — 半額獎勵)',
                      style: TextStyle(
                        color: AppTheme.textSecondary, fontSize: 12,
                      ),
                    ),
                  ),
                if (reward!.agentUnlocked && reward!.unlockedAgentId != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.amber.withAlpha(40),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.withAlpha(100)),
                      ),
                      child: Text(
                        '🎉 新特工加入！',
                        style: TextStyle(
                          color: Colors.amber.shade300,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
              ],
              if (reward != null && reward!.materialDrops.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  alignment: WrapAlignment.center,
                  children: reward!.materialDrops.entries.map((e) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(10),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.white.withAlpha(20)),
                      ),
                      child: Text(
                        '${e.key.emoji}x${e.value}',
                        style: const TextStyle(
                          color: AppTheme.textPrimary, fontSize: 12,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                '分數：$score',
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onExit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isVictory
                      ? AppTheme.accentPrimary
                      : AppTheme.accentSecondary,
                ),
                child: const Text('返回'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
