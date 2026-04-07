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

  static final _tutorialGrid = [
    [_c, _m, _t, _c, _g, _c, _r, _m, _c, _t],
    [_t, _c, _c, _m, _c, _g, _c, _t, _r, _c],
    [_m, _g, _c, _t, _r, _c, _m, _c, _g, _c],
  ];

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
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF6D4C41), Color(0xFF3E2723)],
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(15),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text('🔑', style: TextStyle(fontSize: 64)),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('第 1 關',
                    style: TextStyle(color: Colors.white60, fontSize: AppTheme.fontTitleMd)),
                const Text('推開店門',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: AppTheme.fontDisplayMd,
                        fontWeight: FontWeight.bold)),
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
      ),
    );
  }
}
