import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/stage_data.dart';
import '../../../core/models/cat_agent.dart';
import '../../../core/models/enemy.dart';
import '../../agents/providers/player_provider.dart';
import '../../game/screens/battle_screen.dart';
import '../config/tutorial_config.dart';
import '../models/tutorial_dialogue_data.dart';
import '../providers/tutorial_provider.dart';
import '../widgets/tutorial_dialogue_box.dart';

/// Phase 3：闖關教學
/// 3 場教學戰鬥 + 救出露露的劇情
class Phase3BattleScreen extends StatefulWidget {
  const Phase3BattleScreen({super.key});

  @override
  State<Phase3BattleScreen> createState() => _Phase3BattleScreenState();
}

class _Phase3BattleScreenState extends State<Phase3BattleScreen> {
  int _battleIndex = 0; // 0=1-1, 1=1-2, 2=1-3
  bool _showPreDialogue = true;
  bool _battleInProgress = false;
  int _dialogueIndex = 0;
  bool _showLuluRescue = false;
  int _rescueDialogueIndex = 0;

  // 教學戰鬥關卡定義（弱化敵人）
  static final _tutorialStages = [
    // 1-1：1 隻發霉小餐包
    StageDefinition(
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
          baseAtk: 15,
          attackInterval: 5,
        ),
      ],
      reward: const StageReward(gold: 50, exp: 10),
      twoStarScore: 200,
      threeStarScore: 400,
    ),
    // 1-2：2 隻發霉小餐包
    StageDefinition(
      id: 'tutorial-1-2',
      name: '麵粉倉巡查',
      chapter: 1,
      stageNumber: 2,
      staminaCost: 0,
      moveLimit: 0,
      enemies: [
        EnemyDefinition(
          id: 'moldy_bun_1',
          name: '發霉小餐包',
          emoji: '🍞',
          attribute: AgentAttribute.attributeA,
          baseHp: (120 * TutorialConfig.enemyHpMultiplier).toInt(),
          baseAtk: 20,
          attackInterval: 4,
        ),
        EnemyDefinition(
          id: 'moldy_bun_2',
          name: '發霉小餐包',
          emoji: '🍞',
          attribute: AgentAttribute.attributeA,
          baseHp: (120 * TutorialConfig.enemyHpMultiplier).toInt(),
          baseAtk: 20,
          attackInterval: 5,
        ),
      ],
      reward: const StageReward(gold: 80, exp: 15),
      twoStarScore: 300,
      threeStarScore: 600,
    ),
    // 1-3：1 隻發霉小餐包 + 1 隻焦黑法棍
    StageDefinition(
      id: 'tutorial-1-3',
      name: '發現夥伴',
      chapter: 1,
      stageNumber: 3,
      staminaCost: 0,
      moveLimit: 0,
      enemies: [
        EnemyDefinition(
          id: 'moldy_bun',
          name: '發霉小餐包',
          emoji: '🍞',
          attribute: AgentAttribute.attributeA,
          baseHp: (80 * TutorialConfig.enemyHpMultiplier).toInt(),
          baseAtk: 15,
          attackInterval: 5,
        ),
        EnemyDefinition(
          id: 'burnt_baguette',
          name: '焦黑法棍',
          emoji: '🥖',
          attribute: AgentAttribute.attributeB,
          baseHp: (180 * TutorialConfig.enemyHpMultiplier).toInt(),
          baseAtk: 25,
          attackInterval: 4,
        ),
      ],
      reward: const StageReward(
        gold: 100,
        exp: 20,
        unlockAgentId: 'tide', // 解鎖露露
      ),
      twoStarScore: 400,
      threeStarScore: 800,
    ),
  ];

  // 各戰鬥的戰前對話
  static const _preDialogues = [
    [TutorialDialogues.t021, TutorialDialogues.t022],
    [TutorialDialogues.t028, TutorialDialogues.t029],
    [TutorialDialogues.t035],
  ];

  @override
  void initState() {
    super.initState();
    final tutorial = context.read<TutorialProvider>();
    _battleIndex = tutorial.state.currentBattleStage;
    if (_battleIndex >= _tutorialStages.length) {
      _battleIndex = _tutorialStages.length - 1;
    }
  }

  void _onPreDialogueTap() {
    if (_dialogueIndex < _preDialogues[_battleIndex].length - 1) {
      setState(() => _dialogueIndex++);
    } else {
      setState(() {
        _showPreDialogue = false;
        _battleInProgress = true;
      });
    }
  }

  void _onBattleComplete() {
    setState(() {
      _battleInProgress = false;
    });

    // 記錄通關（不改 tutorialCompleted 旗標）
    final player = context.read<PlayerProvider>();
    final stageId = '1-${_battleIndex + 1}';
    player.markTutorialStageCleared(stageId);

    if (_battleIndex == 2) {
      // 1-3 完成 → 救出露露
      setState(() => _showLuluRescue = true);
    } else {
      _goToNextBattle();
    }
  }

  void _goToNextBattle() {
    final tutorial = context.read<TutorialProvider>();
    tutorial.advanceBattleStage();

    setState(() {
      _battleIndex++;
      _dialogueIndex = 0;
      _showPreDialogue = true;
      _battleInProgress = false;
    });
  }

  static const _rescueDialogues = [
    TutorialDialogues.t036,
    TutorialDialogues.t037,
    TutorialDialogues.t038,
    TutorialDialogues.t039,
    TutorialDialogues.t040,
  ];

  void _onRescueDialogueTap() {
    if (_rescueDialogueIndex < _rescueDialogues.length - 1) {
      setState(() => _rescueDialogueIndex++);
    } else {
      // 解鎖露露 → 進入 Phase 4
      _unlockLuluAndAdvance();
    }
  }

  void _unlockLuluAndAdvance() {
    final player = context.read<PlayerProvider>();
    final tutorial = context.read<TutorialProvider>();

    // 解鎖露露
    player.unlockAgentForTutorial(TutorialConfig.luluAgentId);
    tutorial.markLuluRescued();
    tutorial.advancePhase();
  }

  @override
  Widget build(BuildContext context) {
    // 救出露露劇情
    if (_showLuluRescue) {
      return _buildLuluRescueScene();
    }

    // 戰前對話
    if (_showPreDialogue) {
      return _buildPreDialogueScene();
    }

    // 戰鬥中
    if (_battleInProgress) {
      return _buildBattleScene();
    }

    // 不應該到這裡
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }

  Widget _buildPreDialogueScene() {
    final dialogues = _preDialogues[_battleIndex];
    final dialogue = dialogues[_dialogueIndex];

    return Scaffold(
      backgroundColor: const Color(0xFF4E342E),
      body: Stack(
        children: [
          // 背景
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF6D4C41), Color(0xFF3E2723)],
              ),
            ),
          ),

          // 場景 placeholder
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
                  child: Center(
                    child: Text(
                      _battleIndex == 0
                          ? '🍞'
                          : _battleIndex == 1
                              ? '⚔️'
                              : '🔦',
                      style: const TextStyle(fontSize: 64),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '第 ${_battleIndex + 1} 關',
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 16,
                  ),
                ),
                Text(
                  _tutorialStages[_battleIndex].name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // 對話框
          TutorialDialogueBox(
            dialogue: dialogue,
            onTap: _onPreDialogueTap,
            onComplete: () {
              if (dialogue.autoAdvanceDelay != null) {
                _onPreDialogueTap();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBattleScene() {
    return PopScope(
      canPop: false,
      child: BattleScreen(
        stage: _tutorialStages[_battleIndex],
        onBattleEnd: _onBattleComplete,
      ),
    );
  }

  Widget _buildLuluRescueScene() {
    final dialogue = _rescueDialogues[_rescueDialogueIndex];

    return Scaffold(
      backgroundColor: const Color(0xFF3E2723),
      body: Stack(
        children: [
          // 背景漸變
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF5D4037),
                  _rescueDialogueIndex >= 2
                      ? const Color(0xFF81D4FA).withAlpha(40)
                      : const Color(0xFF3E2723),
                ],
              ),
            ),
          ),

          // 露露 placeholder
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 角色展示
                AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  width: _rescueDialogueIndex >= 2 ? 180 : 120,
                  height: _rescueDialogueIndex >= 2 ? 180 : 120,
                  decoration: BoxDecoration(
                    color: _rescueDialogueIndex >= 2
                        ? const Color(0xFF81D4FA).withAlpha(60)
                        : Colors.white.withAlpha(15),
                    shape: BoxShape.circle,
                    border: _rescueDialogueIndex >= 2
                        ? Border.all(
                            color: const Color(0xFF81D4FA),
                            width: 3,
                          )
                        : null,
                    boxShadow: _rescueDialogueIndex >= 2
                        ? [
                            BoxShadow(
                              color: const Color(0xFF81D4FA).withAlpha(60),
                              blurRadius: 24,
                              spreadRadius: 4,
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      _rescueDialogueIndex >= 2 ? '💧' : '❓',
                      style: TextStyle(
                          fontSize: _rescueDialogueIndex >= 2 ? 64 : 48),
                    ),
                  ),
                ),
                if (_rescueDialogueIndex >= 2) ...[
                  const SizedBox(height: 16),
                  const Text(
                    '露露',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '💧水滴屬性 | 支援者',
                    style: TextStyle(
                      color: Colors.white.withAlpha(180),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '技能：果汁補給站～',
                    style: TextStyle(
                      color: const Color(0xFF81D4FA),
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // 新夥伴加入標題
          if (_rescueDialogueIndex >= 4)
            Positioned(
              top: MediaQuery.of(context).padding.top + 40,
              left: 0,
              right: 0,
              child: const Center(
                child: Text(
                  '🎉 獲得新夥伴！',
                  style: TextStyle(
                    color: Color(0xFFFFD54F),
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

          // 對話框
          TutorialDialogueBox(
            dialogue: dialogue,
            onTap: _onRescueDialogueTap,
            onComplete: () {
              if (dialogue.autoAdvanceDelay != null) {
                _onRescueDialogueTap();
              }
            },
          ),
        ],
      ),
    );
  }
}
