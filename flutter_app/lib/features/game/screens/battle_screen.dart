/// 戰鬥畫面
/// 闖關模式：敵人資訊 + 棋盤←→角色面板（可切換左右）
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../config/game_modes.dart';
import '../../../config/stage_data.dart';
import '../../../config/theme.dart';
import '../../../core/models/battle_state.dart';
import '../../../core/models/game_state.dart';
import '../../../core/models/material.dart';
import '../../../core/services/local_storage.dart';
import '../../agents/providers/player_provider.dart';
import '../providers/battle_provider.dart';
import '../providers/game_provider.dart';
import '../widgets/game_board.dart';

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
  bool _boardOnLeft = true;

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
      backgroundColor: AppTheme.bgPrimary,
      body: SafeArea(
        child: Consumer2<GameProvider, BattleProvider>(
          builder: (context, game, battle, _) {
            final gameState = game.state;
            final battleState = battle.battleState;

            return Stack(
              children: [
                Column(
                  children: [
                    // 頂部：關卡資訊
                    _TopBar(
                      stage: widget.stage,
                      gameState: gameState,
                      onToggle: _toggleBoardPosition,
                      boardOnLeft: _boardOnLeft,
                    ),

                    // 敵人區
                    if (battleState != null)
                      _EnemyPanel(battleState: battleState),

                    // 隊伍 HP
                    if (battleState != null) _TeamHpBar(battleState: battleState),

                    // Combo
                    if (gameState != null && gameState.combo > 0)
                      _ComboBar(combo: gameState.combo),

                    // 主體：棋盤 ←→ 角色面板
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Row(
                          children: _boardOnLeft
                              ? [
                                  const Expanded(
                                    flex: 6,
                                    child: Center(child: GameBoard()),
                                  ),
                                  const SizedBox(width: 4),
                                  if (battleState != null)
                                    Expanded(
                                      flex: 4,
                                      child: _BattleAgentPanel(
                                        battleState: battleState,
                                        battleProvider: battle,
                                      ),
                                    ),
                                ]
                              : [
                                  if (battleState != null)
                                    Expanded(
                                      flex: 4,
                                      child: _BattleAgentPanel(
                                        battleState: battleState,
                                        battleProvider: battle,
                                      ),
                                    ),
                                  const SizedBox(width: 4),
                                  const Expanded(
                                    flex: 6,
                                    child: Center(child: GameBoard()),
                                  ),
                                ],
                        ),
                      ),
                    ),

                    // 技能效果提示
                    if (battleState != null)
                      _SkillEffectBar(battleProvider: battle),

                    // 底部
                    _BottomBar(gameState: gameState),
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
// 戰鬥角色面板（參考首頁版型，橫向卡片）
// ═══════════════════════════════════════════

class _BattleAgentPanel extends StatelessWidget {
  final BattleState battleState;
  final BattleProvider battleProvider;

  const _BattleAgentPanel({
    required this.battleState,
    required this.battleProvider,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 角色卡片
        ...battleState.team.asMap().entries.map((entry) {
          final index = entry.key;
          final agent = entry.value;
          return _BattleAgentCard(
            agent: agent,
            onTap: () {
              if (agent.isSkillReady) {
                _showSkillConfirm(context, agent, index);
              }
            },
          );
        }),
        const Spacer(),
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
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withAlpha(40),
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withAlpha(150), width: 2),
                ),
                child: Center(
                  child: Text(agent.definition.attribute.emoji,
                      style: const TextStyle(fontSize: 22)),
                ),
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

class _BattleAgentCard extends StatelessWidget {
  final BattleAgent agent;
  final VoidCallback onTap;

  const _BattleAgentCard({required this.agent, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = agent.definition.attribute.blockColor.color;
    final isReady = agent.isSkillReady;

    return GestureDetector(
      onTap: isReady ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 3),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.bgCard.withAlpha(isReady ? 220 : 140),
          borderRadius: BorderRadius.circular(8),
          border: isReady
              ? Border.all(color: color.withAlpha(180), width: 1.5)
              : Border.all(color: Colors.white.withAlpha(10), width: 0.5),
          boxShadow: isReady
              ? [BoxShadow(color: color.withAlpha(60), blurRadius: 6)]
              : null,
        ),
        child: Row(
          children: [
            // 屬性圖示
            Text(
              agent.definition.attribute.emoji,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(width: 5),
            // 名稱 + 能量條
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    agent.definition.name,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  // 能量條
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: agent.energyPercent,
                      minHeight: 4,
                      backgroundColor: Colors.white.withAlpha(15),
                      valueColor: AlwaysStoppedAnimation(
                        isReady ? Colors.amber : color.withAlpha(120),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            // 右側
            if (isReady)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: const Text(
                  '施放',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            else
              Text(
                '${agent.currentEnergy}/${agent.definition.skill.energyCost}',
                style: TextStyle(
                  color: AppTheme.textSecondary.withAlpha(120),
                  fontSize: 8,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════
// 頂部工具列
// ═══════════════════════════════════════════

class _TopBar extends StatelessWidget {
  final StageDefinition stage;
  final GameState? gameState;
  final VoidCallback onToggle;
  final bool boardOnLeft;

  const _TopBar({
    required this.stage,
    required this.gameState,
    required this.onToggle,
    required this.boardOnLeft,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              context.read<BattleProvider>().endBattle();
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.arrow_back, size: 22),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          Text(
            '${stage.id} ${stage.name}',
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          // 左右切換
          GestureDetector(
            onTap: onToggle,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.bgCard.withAlpha(120),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.white.withAlpha(20)),
              ),
              child: Icon(
                Icons.swap_horiz,
                color: AppTheme.textSecondary,
                size: 16,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // 行動點
          if (gameState != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.blockCoral.withAlpha(40),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.favorite, size: 14, color: AppTheme.blockCoral),
                  const SizedBox(width: 3),
                  Text(
                    '${gameState!.actionPoints}',
                    style: const TextStyle(
                      color: AppTheme.blockCoral,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
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

// ═══════════════════════════════════════════
// 敵人面板
// ═══════════════════════════════════════════

class _EnemyPanel extends StatelessWidget {
  final BattleState battleState;

  const _EnemyPanel({required this.battleState});

  @override
  Widget build(BuildContext context) {
    final enemy = battleState.currentEnemy;
    if (enemy == null) return const SizedBox(height: 40);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.bgCard.withAlpha(180),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: enemy.definition.attribute.blockColor.color.withAlpha(80),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: enemy.definition.attribute.blockColor.color.withAlpha(40),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(enemy.definition.emoji, style: const TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${enemy.definition.name} ${enemy.definition.attribute.emoji}',
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: enemy.hpPercent,
                          minHeight: 8,
                          backgroundColor: Colors.white10,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            enemy.hpPercent > 0.5
                                ? Colors.green
                                : enemy.hpPercent > 0.25
                                    ? Colors.orange
                                    : Colors.red,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${enemy.currentHp}/${enemy.maxHp}',
                      style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: enemy.attackCountdown <= 1
                  ? Colors.red.withAlpha(60)
                  : Colors.white10,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.bolt,
                  size: 14,
                  color: enemy.attackCountdown <= 1
                      ? Colors.red
                      : AppTheme.textSecondary,
                ),
                Text(
                  '${enemy.attackCountdown}',
                  style: TextStyle(
                    color: enemy.attackCountdown <= 1
                        ? Colors.red
                        : AppTheme.textSecondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
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

// ═══════════════════════════════════════════
// 隊伍 HP 條
// ═══════════════════════════════════════════

class _TeamHpBar extends StatelessWidget {
  final BattleState battleState;

  const _TeamHpBar({required this.battleState});

  @override
  Widget build(BuildContext context) {
    final hpPercent = battleState.teamMaxHp > 0
        ? battleState.teamCurrentHp / battleState.teamMaxHp
        : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Row(
        children: [
          const Text('隊伍',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
          const SizedBox(width: 4),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: hpPercent,
                minHeight: 5,
                backgroundColor: Colors.white10,
                valueColor: AlwaysStoppedAnimation<Color>(
                  hpPercent > 0.5
                      ? Colors.green.shade400
                      : hpPercent > 0.25
                          ? Colors.orange
                          : Colors.red,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '${battleState.teamCurrentHp}/${battleState.teamMaxHp}',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10),
          ),
          if (battleState.shieldTurnsLeft > 0) ...[
            const SizedBox(width: 4),
            Icon(Icons.shield, size: 12, color: Colors.blue.shade300),
            Text(
              '${battleState.shieldTurnsLeft}',
              style: TextStyle(color: Colors.blue.shade300, fontSize: 10),
            ),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════
// 底部狀態列
// ═══════════════════════════════════════════

class _BottomBar extends StatelessWidget {
  final GameState? gameState;

  const _BottomBar({required this.gameState});

  @override
  Widget build(BuildContext context) {
    if (gameState == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: AppTheme.bgSecondary.withAlpha(100),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star, size: 14, color: AppTheme.blockGold),
              const SizedBox(width: 3),
              Text(
                '${gameState!.score}',
                style: const TextStyle(
                  color: AppTheme.blockGold,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.touch_app, size: 14, color: AppTheme.textSecondary),
              const SizedBox(width: 3),
              Text(
                '${gameState!.actionCount}',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.orange.withAlpha(180), AppTheme.blockGold.withAlpha(180)],
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.local_fire_department, size: 14, color: Colors.white),
            const SizedBox(width: 4),
            Text(
              '${combo}x Combo!',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withAlpha(40),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withAlpha(100)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                event.message,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  (IconData, Color) _eventStyle(BattleEventType type) {
    switch (type) {
      case BattleEventType.damage:
        return (Icons.flash_on, Colors.orange);
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
