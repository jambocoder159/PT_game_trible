/// 戰鬥畫面
/// 闖關模式的完整畫面：上方敵人 + 左側角色 + 中央棋盤 + 技能按鈕
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/game_modes.dart';
import '../../../config/stage_data.dart';
import '../../../config/theme.dart';
import '../../../core/models/battle_state.dart';
import '../../../core/models/game_state.dart';
import '../../../core/models/material.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initBattle();
    });
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
    };
    gameProvider.onTurnEnd = () {
      battleProvider.onTurnEnd();
    };
    battleProvider.onBoardEffectRequested = (effect, agentColor) {
      return gameProvider.applyBoardEffect(effect, agentColor);
    };

    gameProvider.startGame(battleMode);
  }

  /// 儲存戰鬥結果（只執行一次）
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
                    _TopBar(stage: widget.stage, gameState: gameState),

                    // 敵人區
                    if (battleState != null)
                      _EnemyPanel(battleState: battleState),

                    // 隊伍 HP
                    if (battleState != null) _TeamHpBar(battleState: battleState),

                    // Combo 顯示（棋盤外部）
                    if (gameState != null && gameState.combo > 0)
                      _ComboBar(combo: gameState.combo),

                    // 遊戲區：左側角色 + 中央棋盤
                    Expanded(
                      child: Row(
                        children: [
                          // 左側角色面板
                          if (battleState != null)
                            _AgentSidePanel(
                              battleState: battleState,
                              onSkillTap: (index) {
                                battle.activateSkill(index);
                              },
                            ),
                          // 中央棋盤
                          const Expanded(
                            child: Center(child: GameBoard()),
                          ),
                        ],
                      ),
                    ),

                    // 技能效果提示
                    if (battleState != null)
                      _SkillEffectBar(battleProvider: battle),

                    // 底部：分數 + 回合
                    _BottomBar(gameState: gameState),
                  ],
                ),

                // 戰鬥結束覆蓋層
                if (battle.isBattleOver) ...[
                  Builder(builder: (_) {
                    // 延遲到 frame 結束後再儲存（避免 build 中觸發 setState）
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

                // 遊戲結束（行動點用完）但敵人還在
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

// ─── 頂部工具列 ───

class _TopBar extends StatelessWidget {
  final StageDefinition stage;
  final GameState? gameState;

  const _TopBar({required this.stage, required this.gameState});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              context.read<BattleProvider>().endBattle();
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.arrow_back, size: 22),
          ),
          Text(
            '任務 ${stage.id}',
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            stage.name,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
          ),
          const Spacer(),
          // 行動點
          if (gameState != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.blockCoral.withAlpha(40),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.favorite, size: 16, color: AppTheme.blockCoral),
                  const SizedBox(width: 4),
                  Text(
                    '${gameState?.actionPoints ?? 0}',
                    style: const TextStyle(
                      color: AppTheme.blockCoral,
                      fontWeight: FontWeight.bold,
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

// ─── 敵人面板 ───

class _EnemyPanel extends StatelessWidget {
  final BattleState battleState;

  const _EnemyPanel({required this.battleState});

  @override
  Widget build(BuildContext context) {
    final enemy = battleState.currentEnemy;
    if (enemy == null) {
      return const SizedBox(height: 60);
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.bgCard.withAlpha(180),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: enemy.definition.attribute.blockColor.color.withAlpha(80),
        ),
      ),
      child: Row(
        children: [
          // 敵人圖示
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: enemy.definition.attribute.blockColor.color.withAlpha(40),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: Center(
              child: Text(
                enemy.definition.emoji,
                style: const TextStyle(fontSize: 26),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // 敵人資訊
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      enemy.definition.name,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      enemy.definition.attribute.emoji,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // HP 條
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: enemy.hpPercent,
                          minHeight: 10,
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
                    const SizedBox(width: 8),
                    Text(
                      '${enemy.currentHp}/${enemy.maxHp}',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // 攻擊倒數
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: enemy.attackCountdown <= 1
                  ? Colors.red.withAlpha(60)
                  : Colors.white10,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.bolt,
                  size: 16,
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

// ─── 隊伍 HP 條 ───

class _TeamHpBar extends StatelessWidget {
  final BattleState battleState;

  const _TeamHpBar({required this.battleState});

  @override
  Widget build(BuildContext context) {
    final hpPercent = battleState.teamMaxHp > 0
        ? battleState.teamCurrentHp / battleState.teamMaxHp
        : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Row(
        children: [
          const Text(
            '隊伍',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: hpPercent,
                minHeight: 6,
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
          const SizedBox(width: 6),
          Text(
            '${battleState.teamCurrentHp}/${battleState.teamMaxHp}',
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 11,
            ),
          ),
          if (battleState.shieldTurnsLeft > 0) ...[
            const SizedBox(width: 6),
            Icon(Icons.shield, size: 14, color: Colors.blue.shade300),
            Text(
              '${battleState.shieldTurnsLeft}',
              style: TextStyle(
                color: Colors.blue.shade300,
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── 左側角色面板 ───

class _AgentSidePanel extends StatelessWidget {
  final BattleState battleState;
  final void Function(int index) onSkillTap;

  const _AgentSidePanel({
    required this.battleState,
    required this.onSkillTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          ...battleState.team.asMap().entries.map((entry) {
            final index = entry.key;
            final agent = entry.value;
            return _AgentSlot(
              agent: agent,
              onTap: () => onSkillTap(index),
            );
          }),
        ],
      ),
    );
  }
}

class _AgentSlot extends StatelessWidget {
  final BattleAgent agent;
  final VoidCallback onTap;

  const _AgentSlot({required this.agent, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = agent.definition.attribute.blockColor.color;
    final isReady = agent.isSkillReady;

    return GestureDetector(
      onTap: isReady ? onTap : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8, left: 4),
        child: Column(
          children: [
            // 頭像
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withAlpha(isReady ? 80 : 30),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isReady ? color : color.withAlpha(60),
                  width: isReady ? 2.5 : 1,
                ),
                boxShadow: isReady
                    ? [BoxShadow(color: color.withAlpha(100), blurRadius: 8)]
                    : null,
              ),
              child: Center(
                child: Text(
                  agent.definition.attribute.emoji,
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
            const SizedBox(height: 2),
            // 能量條
            SizedBox(
              width: 44,
              height: 4,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: agent.energyPercent,
                  backgroundColor: Colors.white10,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isReady ? Colors.amber : color.withAlpha(150),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 1),
            // 名稱
            Text(
              agent.definition.name,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 9,
              ),
            ),
            // 放技能提示
            if (isReady)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.amber.withAlpha(60),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '放',
                  style: TextStyle(
                    color: Colors.amber,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── 底部狀態列 ───

class _BottomBar extends StatelessWidget {
  final GameState? gameState;

  const _BottomBar({required this.gameState});

  @override
  Widget build(BuildContext context) {
    if (gameState == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppTheme.bgSecondary.withAlpha(100),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatDisplay(
            icon: Icons.star,
            value: '${gameState!.score}',
            color: AppTheme.blockGold,
          ),
          _StatDisplay(
            icon: Icons.touch_app,
            value: '${gameState!.actionCount}',
            color: AppTheme.textSecondary,
          ),
        ],
      ),
    );
  }
}

class _StatDisplay extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;

  const _StatDisplay({
    required this.icon,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

// ─── Combo 顯示條（棋盤上方） ───

class _ComboBar extends StatelessWidget {
  final int combo;

  const _ComboBar({required this.combo});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.orange.withAlpha(180),
              AppTheme.blockGold.withAlpha(180),
            ],
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.local_fire_department, size: 16, color: Colors.white),
            const SizedBox(width: 4),
            Text(
              '${combo}x Combo!',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 技能效果提示條 ───

class _SkillEffectBar extends StatelessWidget {
  final BattleProvider battleProvider;

  const _SkillEffectBar({required this.battleProvider});

  @override
  Widget build(BuildContext context) {
    final events = battleProvider.consumeEvents();
    if (events.isEmpty) return const SizedBox.shrink();

    // 取最新的事件顯示
    final event = events.last;
    final (icon, color) = _eventStyle(event.type);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: color.withAlpha(40),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withAlpha(100)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                event.message,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
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

// ─── 戰鬥結束覆蓋層 ───

/// 戰鬥獎勵結果
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
              // 星星
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
              // 獎勵
              if (isVictory && reward != null) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '🪙 +${reward!.gold}',
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      '✨ +${reward!.exp} EXP',
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                if (!reward!.isFirstClear)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      '(重複通關 — 半額獎勵)',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                if (reward!.agentUnlocked && reward!.unlockedAgentId != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
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
              // 素材掉落
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
                          color: AppTheme.textPrimary,
                          fontSize: 12,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                '分數：$score',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                ),
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
