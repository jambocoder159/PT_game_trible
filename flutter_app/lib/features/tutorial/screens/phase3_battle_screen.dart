import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/stage_data.dart';
import '../../../config/theme.dart';
import '../../../core/models/block.dart';
import '../../../core/models/cat_agent.dart';
import '../../../core/models/enemy.dart';
import '../../agents/providers/player_provider.dart';
import '../../game/screens/battle_screen.dart';
import '../config/tutorial_config.dart';
import '../models/tutorial_dialogue_data.dart';
import '../providers/tutorial_provider.dart';
import '../widgets/tutorial_dialogue_box.dart';

/// Phase 3：闘關教學
/// 2 句戰前對話 → 1 場戰鬥 → 直接完成教學
class Phase3BattleScreen extends StatefulWidget {
  const Phase3BattleScreen({super.key});

  @override
  State<Phase3BattleScreen> createState() => _Phase3BattleScreenState();
}

class _Phase3BattleScreenState extends State<Phase3BattleScreen> {
  bool _showPreDialogue = true;
  bool _battleInProgress = false;
  int _dialogueIndex = 0;

  static final _tutorialStage = StageDefinition(
    id: 'tutorial-1-1',
    name: '推開店門',
    chapter: 1,
    stageNumber: 1,
    staminaCost: 0,
    moveLimit: 0,
    enemies: [
      EnemyDefinition(
        id: 'moldy_bun',
        name: '發霉小餐包',
        emoji: '🍞',
        attribute: AgentAttribute.attributeA,
        baseHp: (80 * TutorialConfig.enemyHpMultiplier).toInt(),
        baseAtk: 10,
        attackInterval: 6,
      ),
    ],
    reward: const StageReward(gold: 50, exp: 10),
    twoStarScore: 100,
    threeStarScore: 200,
  );

  static const _c = BlockColor.coral;
  static const _m = BlockColor.mint;
  static const _t = BlockColor.teal;
  static const _g = BlockColor.gold;
  static const _r = BlockColor.rose;

  // 教學棋盤設計：
  // col 1 row 0 是 _t (水滴)，往下滑後 col 1 頂部露出 c c c → 3 連消！
  // 提示玩家：「長按 col 1 row 0 的水滴方塊，往下滑」
  static final _tutorialGrid = [
    [_c, _m, _t, _c, _g, _c, _r, _m, _c, _t],
    [_t, _c, _c, _c, _m, _g, _t, _r, _m, _g],
    [_m, _g, _c, _t, _r, _c, _m, _c, _g, _c],
  ];

  // 教學提示：長按 col 1 row 0 的方塊，往下滑
  static const tutorialHintCol = 1;
  static const tutorialHintRow = 0;

  static const _preDialogues = [
    TutorialDialogues.t017,
    TutorialDialogues.t022,
  ];

  @override
  void initState() {
    super.initState();
    final tutorial = context.read<TutorialProvider>();
    final player = context.read<PlayerProvider>();

    if (tutorial.state.currentBattleStage > 0 || tutorial.state.luluRescued) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) tutorial.completeTutorial(player, skipAgentUnlock: true);
      });
    }
  }

  void _onPreDialogueTap() {
    if (_dialogueIndex < _preDialogues.length - 1) {
      setState(() => _dialogueIndex++);
    } else {
      setState(() {
        _showPreDialogue = false;
        _battleInProgress = true;
      });
    }
  }

  void _onBattleComplete() {
    final player = context.read<PlayerProvider>();
    player.markTutorialStageCleared('1-1');
    // 教學精簡版：不提前解鎖露露，讓 1-3 自然解鎖
    context.read<TutorialProvider>().completeTutorial(
      player,
      skipAgentUnlock: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_showPreDialogue) return _buildPreDialogue();
    if (_battleInProgress) return _buildBattle();
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }

  Widget _buildPreDialogue() {
    final dialogue = _preDialogues[_dialogueIndex];
    return Scaffold(
      backgroundColor: const Color(0xFF4E342E),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 背景圖（地下室入口）
          Image.asset(
            'assets/images/output/background/bg_tutorial_basement.png',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF6D4C41), Color(0xFF3E2723)],
                ),
              ),
            ),
          ),
          // 底部漸層遮罩
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: MediaQuery.of(context).size.height * 0.5,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withAlpha(0),
                    Colors.black.withAlpha(140),
                    Colors.black.withAlpha(200),
                  ],
                ),
              ),
            ),
          ),
          // 關卡標題
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('第 1 關',
                    style: TextStyle(
                      color: Colors.white.withAlpha(180),
                      fontSize: AppTheme.fontTitleMd,
                      shadows: [Shadow(color: Colors.black.withAlpha(180), blurRadius: 6)],
                    )),
                const SizedBox(height: 4),
                Text('推開店門',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: AppTheme.fontDisplayMd,
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(color: Colors.black.withAlpha(200), blurRadius: 8)],
                    )),
              ],
            ),
          ),
          TutorialDialogueBox(
            dialogue: dialogue,
            onTap: _onPreDialogueTap,
            onComplete: () {
              if (dialogue.autoAdvanceDelay != null) _onPreDialogueTap();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBattle() {
    return PopScope(
      canPop: false,
      child: BattleScreen(
        stage: _tutorialStage,
        onBattleEnd: _onBattleComplete,
        initialColors: _tutorialGrid,
        tutorialBattleIndex: 0,
        tutorialSwipeHint: (col: tutorialHintCol, row: tutorialHintRow),
      ),
    );
  }
}
