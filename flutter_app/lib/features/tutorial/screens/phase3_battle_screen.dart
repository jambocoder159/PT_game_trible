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

/// Phase 3：闘關教學
/// 先顯示劇情對話（原 Phase 2 過場），然後進入教學戰鬥
class Phase3BattleScreen extends StatefulWidget {
  const Phase3BattleScreen({super.key});

  @override
  State<Phase3BattleScreen> createState() => _Phase3BattleScreenState();
}

class _Phase3BattleScreenState extends State<Phase3BattleScreen> {
  int _battleIndex = 0;
  bool _showPreDialogue = true;
  bool _battleInProgress = false;
  int _dialogueIndex = 0;
  bool _showLuluRescue = false;
  int _rescueDialogueIndex = 0;

  // 教學戰鬥關卡（弱化敵人）
  static final _tutorialStages = [
    StageDefinition(
      id: 'tutorial-1-1',
      name: '推開店門',
      chapter: 1,
      stageNumber: 1,
      staminaCost: 0,
      moveLimit: 0, // 無限行動
      enemies: [
        EnemyDefinition(
          id: 'moldy_bun',
          name: '發霉小餐包',
          emoji: '🍞',
          attribute: AgentAttribute.attributeA,
          baseHp: (80 * TutorialConfig.enemyHpMultiplier).toInt(),
          baseAtk: 10,
          attackInterval: 6, // 給更多時間
        ),
      ],
      reward: const StageReward(gold: 50, exp: 10),
      twoStarScore: 100,
      threeStarScore: 200,
    ),
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
          baseHp: (100 * TutorialConfig.enemyHpMultiplier).toInt(),
          baseAtk: 15,
          attackInterval: 5,
        ),
        EnemyDefinition(
          id: 'moldy_bun_2',
          name: '發霉小餐包',
          emoji: '🍞',
          attribute: AgentAttribute.attributeA,
          baseHp: (100 * TutorialConfig.enemyHpMultiplier).toInt(),
          baseAtk: 15,
          attackInterval: 6,
        ),
      ],
      reward: const StageReward(gold: 80, exp: 15),
      twoStarScore: 200,
      threeStarScore: 400,
    ),
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
          baseHp: (60 * TutorialConfig.enemyHpMultiplier).toInt(),
          baseAtk: 10,
          attackInterval: 6,
        ),
        EnemyDefinition(
          id: 'burnt_baguette',
          name: '焦黑法棍',
          emoji: '🥖',
          attribute: AgentAttribute.attributeB,
          baseHp: (150 * TutorialConfig.enemyHpMultiplier).toInt(),
          baseAtk: 20,
          attackInterval: 5,
        ),
      ],
      reward: const StageReward(
        gold: 100,
        exp: 20,
        unlockAgentId: 'tide',
      ),
      twoStarScore: 300,
      threeStarScore: 600,
    ),
  ];

  // 第一關前：包含原 Phase 2 的劇情（地下室聲響）
  static const _stage1PreDialogues = [
    TutorialDialogues.t017, // 小貓：地下室有聲音
    TutorialDialogues.t018, // 爺爺：鑰匙
    TutorialDialogues.t019, // 爺爺：壞掉的食物精靈
    TutorialDialogues.t020, // 爺爺：別擔心
    TutorialDialogues.t021, // 爺爺：小心麵包精靈
    TutorialDialogues.t022, // 爺爺：消除 = 攻擊
  ];

  static const _stage2PreDialogues = [
    TutorialDialogues.t028, // 爺爺：再往裡面走
    TutorialDialogues.t029, // 爺爺：注意能量條
  ];

  static const _stage3PreDialogues = [
    TutorialDialogues.t035, // 爺爺：深處有聲音
  ];

  static const _preDialogues = [
    _stage1PreDialogues,
    _stage2PreDialogues,
    _stage3PreDialogues,
  ];

  static const _rescueDialogues = [
    TutorialDialogues.t036,
    TutorialDialogues.t037,
    TutorialDialogues.t038,
    TutorialDialogues.t039,
    TutorialDialogues.t040,
  ];

  @override
  void initState() {
    super.initState();
    final tutorial = context.read<TutorialProvider>();
    _battleIndex = tutorial.state.currentBattleStage.clamp(0, 2);
  }

  void _onPreDialogueTap() {
    final dialogues = _preDialogues[_battleIndex];
    if (_dialogueIndex < dialogues.length - 1) {
      setState(() => _dialogueIndex++);
    } else {
      setState(() {
        _showPreDialogue = false;
        _battleInProgress = true;
      });
    }
  }

  void _onBattleComplete() {
    setState(() => _battleInProgress = false);

    // 記錄通關
    final player = context.read<PlayerProvider>();
    player.markTutorialStageCleared('1-${_battleIndex + 1}');

    if (_battleIndex == 2) {
      setState(() => _showLuluRescue = true);
    } else {
      _goToNextBattle();
    }
  }

  void _goToNextBattle() {
    context.read<TutorialProvider>().advanceBattleStage();
    setState(() {
      _battleIndex++;
      _dialogueIndex = 0;
      _showPreDialogue = true;
      _battleInProgress = false;
    });
  }

  void _onRescueDialogueTap() {
    if (_rescueDialogueIndex < _rescueDialogues.length - 1) {
      setState(() => _rescueDialogueIndex++);
    } else {
      _unlockLuluAndAdvance();
    }
  }

  void _unlockLuluAndAdvance() {
    final player = context.read<PlayerProvider>();
    final tutorial = context.read<TutorialProvider>();
    player.unlockAgentForTutorial(TutorialConfig.luluAgentId);
    tutorial.markLuluRescued();
    tutorial.advancePhase();
  }

  @override
  Widget build(BuildContext context) {
    if (_showLuluRescue) return _buildLuluRescueScene();
    if (_showPreDialogue) return _buildPreDialogueScene();
    if (_battleInProgress) return _buildBattleScene();
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }

  Widget _buildPreDialogueScene() {
    final dialogues = _preDialogues[_battleIndex];
    final dialogue = dialogues[_dialogueIndex];

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
                  child: Center(
                    child: Text(
                      _battleIndex == 0
                          ? '🔑'
                          : _battleIndex == 1
                              ? '⚔️'
                              : '🔦',
                      style: const TextStyle(fontSize: 64),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('第 ${_battleIndex + 1} 關',
                    style: const TextStyle(color: Colors.white60, fontSize: 16)),
                Text(_tutorialStages[_battleIndex].name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
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
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
                        ? Border.all(color: const Color(0xFF81D4FA), width: 3)
                        : null,
                    boxShadow: _rescueDialogueIndex >= 2
                        ? [BoxShadow(
                            color: const Color(0xFF81D4FA).withAlpha(60),
                            blurRadius: 24,
                            spreadRadius: 4)]
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
                  const Text('露露',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('💧水滴屬性 | 支援者',
                      style: TextStyle(color: Colors.white.withAlpha(180), fontSize: 14)),
                  const SizedBox(height: 4),
                  const Text('技能：果汁補給站～',
                      style: TextStyle(color: Color(0xFF81D4FA), fontSize: 13)),
                ],
              ],
            ),
          ),
          if (_rescueDialogueIndex >= 4)
            Positioned(
              top: MediaQuery.of(context).padding.top + 40,
              left: 0,
              right: 0,
              child: const Center(
                child: Text('🎉 獲得新夥伴！',
                    style: TextStyle(
                        color: Color(0xFFFFD54F),
                        fontSize: 22,
                        fontWeight: FontWeight.bold)),
              ),
            ),
          TutorialDialogueBox(
            dialogue: dialogue,
            onTap: _onRescueDialogueTap,
            onComplete: () {
              if (dialogue.autoAdvanceDelay != null) _onRescueDialogueTap();
            },
          ),
        ],
      ),
    );
  }
}
