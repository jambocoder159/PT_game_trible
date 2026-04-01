import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../config/cat_agent_data.dart';
import '../../../config/theme.dart';
import '../../agents/providers/player_provider.dart';
import '../../agents/screens/agent_detail_screen.dart';
import '../../agents/screens/agent_list_screen.dart';
import '../../daily/screens/daily_quest_screen.dart';
import '../../../core/models/auto_eliminate_config.dart';
import '../../idle/providers/idle_provider.dart';
import '../../idle/screens/home_screen.dart';
import '../config/tutorial_config.dart';
import '../models/tutorial_dialogue_data.dart';
import '../providers/tutorial_provider.dart';
import '../widgets/tutorial_dialogue_box.dart';
import '../widgets/tutorial_highlight_overlay.dart';

/// Phase 4：回首頁收尾教學
/// 使用真實 HomeScreen + overlay 引導
class Phase4ReturnScreen extends StatefulWidget {
  const Phase4ReturnScreen({super.key});

  @override
  State<Phase4ReturnScreen> createState() => _Phase4ReturnScreenState();
}

class _Phase4ReturnScreenState extends State<Phase4ReturnScreen> {
  // step 0: 隊伍編成（角色頁，高亮露露）
  // step 1: 角色升級（push AgentDetailScreen）
  // step 2: 自動消除（放置頁，高亮 Switch）
  // step 3: 每日任務（push DailyQuestScreen）
  // step 4: 元氣系統（放置頁，高亮 PlayerInfoBar）
  // step 5: 教學結束
  int _step = 0;
  int _dialogueIndex = 0;
  bool _showDialogue = true;
  bool _actionDone = false;
  TutorialDialogue? _currentCompletionDialogue;

  // 對應各步驟的 GlobalKey
  final _autoSwitchKey = GlobalKey();
  final _staminaKey = GlobalKey();

  // 當前的 nav tab
  int _currentNavIndex = 2;

  // 每個步驟的對話
  static const _stepDialogues = [
    // step 0: 隊伍編成
    [TutorialDialogues.t041],
    // step 1: 角色升級
    [TutorialDialogues.t044],
    // step 2: 自動消除
    [TutorialDialogues.t046, TutorialDialogues.t047],
    // step 3: 每日任務
    [TutorialDialogues.t049],
    // step 4: 元氣系統
    [TutorialDialogues.t051, TutorialDialogues.t052],
    // step 5: 教學結束
    [TutorialDialogues.t053, TutorialDialogues.t054, TutorialDialogues.t055],
  ];

  @override
  void initState() {
    super.initState();
    final tutorial = context.read<TutorialProvider>();
    _step = tutorial.currentStep;
    if (_step >= _stepDialogues.length) _step = 0;

    // 恢復已完成狀態 → 跳過已完成步驟
    final state = tutorial.state;
    if (state.teamSetupDone && _step == 0) _step = 1;
    if (state.upgradeDone && _step == 1) _step = 2;
    // 自動消除未解鎖時跳過
    final idle = context.read<IdleProvider>();
    final isAutoUnlocked =
        idle.autoConfig.unlockedStage.index >= AutoEliminateStage.stage2.index;
    if (!isAutoUnlocked && _step == 2) {
      tutorial.markAutoEliminateDone();
      _step = 3;
    }
    if (state.autoEliminateDone && _step == 2) _step = 3;
    if (state.dailyQuestDone && _step == 3) _step = 4;
    if (state.staminaDone && _step == 4) _step = 5;

    _currentNavIndex = _tabForStep;
  }

  /// 目前步驟對應的 HomeScreen Tab index
  int get _tabForStep {
    switch (_step) {
      case 0: return 1; // 角色頁
      case 1: return 1; // 角色頁（會 push detail）
      case 2: return 2; // 放置頁
      case 3: return 2; // 放置頁（會 push daily quest）
      case 4: return 2; // 放置頁
      default: return 2;
    }
  }

  void _onDialogueTap() {
    final dialogues = _stepDialogues[_step];
    if (_dialogueIndex < dialogues.length - 1) {
      setState(() => _dialogueIndex++);
    } else {
      // 對話完畢，開始操作引導
      setState(() {
        _showDialogue = false;
        _actionDone = false;
      });
      _startStepAction();
    }
  }

  /// 每個步驟對話結束後的動作
  void _startStepAction() {
    switch (_step) {
      case 0:
        // 切到角色頁，高亮由 HomeScreen 的 tutorialHighlightAgentId 控制
        _switchHomeTab(1);
      case 1:
        // push AgentDetailScreen（小麥）
        _pushAgentDetail();
      case 2:
        // 切到放置頁，高亮 auto switch
        _switchHomeTab(2);
      case 3:
        // push DailyQuestScreen
        _pushDailyQuest();
      case 4:
        // 元氣只需顯示說明，上面的對話已經播完了，直接完成
        _onActionComplete();
      case 5:
        // 最後的結束對話播完 → 顯示獎勵
        _completeTutorial();
    }
  }

  void _switchHomeTab(int index) {
    if (_currentNavIndex != index) {
      setState(() => _currentNavIndex = index);
    }
  }

  void _pushAgentDetail() async {
    final def = CatAgentData.getById('blaze');
    if (def == null) {
      _onActionComplete();
      return;
    }
    // 教學用：確保玩家有足夠金幣訓練
    final player = context.read<PlayerProvider>();
    if (player.data.gold < 50) {
      player.addGold(50 - player.data.gold);
    }
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AgentDetailScreen(
          definition: def,
          tutorialMode: true,
        ),
      ),
    );
    if (mounted && (result == true)) {
      _onActionComplete();
    }
  }

  void _pushDailyQuest() async {
    // 教學用：確保每日任務全部完成，讓「全完成獎勵」可以領取
    _ensureDailyQuestsCompleted();
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const DailyQuestScreen(tutorialMode: true),
      ),
    );
    if (mounted && (result == true)) {
      _onActionComplete();
    }
  }

  /// 教學用：自動完成所有每日任務條件，讓全完成獎勵可以領取
  void _ensureDailyQuestsCompleted() {
    final player = context.read<PlayerProvider>();
    final quests = player.data.dailyQuests;
    if (quests.needsReset) quests.reset();
    if (!quests.hasLoggedIn) {
      quests.hasLoggedIn = true;
    }
    if (quests.stagesCompleted < 3) {
      quests.stagesCompleted = 3;
    }
    if (quests.blocksEliminated < 200) {
      quests.blocksEliminated = 200;
    }
    player.notifyAndSave();
  }

  void _onActionComplete() {
    HapticFeedback.lightImpact();
    final tutorial = context.read<TutorialProvider>();

    switch (_step) {
      case 0:
        tutorial.markTeamSetupDone();
        _showCompletionDialogue([
          TutorialDialogues.t042,
          TutorialDialogues.t043,
        ]);
      case 1:
        tutorial.markUpgradeDone();
        _showCompletionDialogue([TutorialDialogues.t045]);
      case 2:
        tutorial.markAutoEliminateDone();
        _showCompletionDialogue([TutorialDialogues.t048]);
      case 3:
        tutorial.markDailyQuestDone();
        _showCompletionDialogue([TutorialDialogues.t050]);
      case 4:
        tutorial.markStaminaDone();
        _advanceStep();
      case 5:
        _completeTutorial();
    }
  }

  void _showCompletionDialogue(List<TutorialDialogue> dialogues) {
    setState(() {
      _currentCompletionDialogue = dialogues.first;
      _showDialogue = true;
      _dialogueIndex = 0;
      _actionDone = true;
    });
    _completionDialogues = dialogues;
    _completionDialogueIndex = 0;
  }

  List<TutorialDialogue> _completionDialogues = [];
  int _completionDialogueIndex = 0;

  void _onCompletionDialogueTap() {
    _completionDialogueIndex++;
    if (_completionDialogueIndex < _completionDialogues.length) {
      setState(() {
        _currentCompletionDialogue = _completionDialogues[_completionDialogueIndex];
      });
    } else {
      _advanceStep();
    }
  }

  void _advanceStep() {
    final tutorial = context.read<TutorialProvider>();
    tutorial.advanceStep();
    setState(() {
      _step++;
      _dialogueIndex = 0;
      _showDialogue = true;
      _actionDone = false;
      _currentCompletionDialogue = null;
      _completionDialogues = [];
      _completionDialogueIndex = 0;
    });

    // 自動消除未解鎖時跳過 step 2
    if (_step == 2) {
      final idle = context.read<IdleProvider>();
      final isAutoUnlocked =
          idle.autoConfig.unlockedStage.index >= AutoEliminateStage.stage2.index;
      if (!isAutoUnlocked) {
        tutorial.markAutoEliminateDone();
        tutorial.advanceStep();
        setState(() {
          _step++;
          _dialogueIndex = 0;
        });
      }
    }

    if (_step >= _stepDialogues.length) {
      _completeTutorial();
    } else {
      // 切換到正確的 tab
      _switchHomeTab(_tabForStep);
    }
  }

  void _completeTutorial() {
    _showRewardDialog();
  }

  void _showRewardDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withAlpha(180),
      transitionDuration: const Duration(milliseconds: 400),
      transitionBuilder: (ctx, anim, _, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
          child: child,
        );
      },
      pageBuilder: (ctx, _, __) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
              decoration: BoxDecoration(
                color: AppTheme.bgSecondary,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFFFD700).withAlpha(160),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFD700).withAlpha(40),
                    blurRadius: 24,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🎉', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 12),
                  const Text(
                    '教學完成！',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '恭喜你掌握了所有基礎！\n甜點街就交給你了！',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.bgPrimary,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.accentPrimary.withAlpha(60),
                      ),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          '🎁 開店禮包',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _rewardItem('🍬', '+${TutorialConfig.rewardGold}'),
                            _rewardItem(
                                '☕', '+${TutorialConfig.rewardCoffee}'),
                            _rewardItem(
                                '🔥', '+${TutorialConfig.rewardEnergy}'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        context.read<TutorialProvider>().completeTutorial(
                              context.read<PlayerProvider>(),
                            );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        '開始冒險！',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _rewardItem(String emoji, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_step >= _stepDialogues.length) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      body: Stack(
        children: [
          // ─── 底層：真實 HomeScreen ───
          HomeScreen(
            tutorialMode: true,
            initialNavIndex: _currentNavIndex,
            tutorialHighlightAgentId:
                _step == 0 ? TutorialConfig.luluAgentId : null,
            tutorialAutoSwitchKey: _step == 2 ? _autoSwitchKey : null,
            tutorialStaminaKey: _step == 4 ? _staminaKey : null,
          ),

          // ─── 動作偵測器 ───
          _TutorialActionListener(
            step: _step,
            showDialogue: _showDialogue,
            actionDone: _actionDone,
            onTeamSetup: () {
              if (_step == 0 && !_showDialogue && !_actionDone) {
                _onActionComplete();
              }
            },
            onAutoEnabled: () {
              if (_step == 2 && !_showDialogue && !_actionDone) {
                _onActionComplete();
              }
            },
          ),

          // ─── 高亮 overlay ───
          if (!_showDialogue && !_actionDone) _buildHighlight(),

          // ─── 對話框 ───
          if (_showDialogue)
            TutorialDialogueBox(
              dialogue: _actionDone && _currentCompletionDialogue != null
                  ? _currentCompletionDialogue!
                  : _stepDialogues[_step][_dialogueIndex],
              onTap: _actionDone
                  ? _onCompletionDialogueTap
                  : _onDialogueTap,
              onComplete: () {
                final d = _actionDone && _currentCompletionDialogue != null
                    ? _currentCompletionDialogue!
                    : _stepDialogues[_step][_dialogueIndex];
                if (d.autoAdvanceDelay != null) {
                  if (_actionDone) {
                    _onCompletionDialogueTap();
                  } else {
                    _onDialogueTap();
                  }
                }
              },
            ),
        ],
      ),
    );
  }

  Widget _buildHighlight() {
    GlobalKey? key;
    switch (_step) {
      case 0:
        // 高亮露露卡片（由 AgentListScreen 管理的靜態 key）
        key = AgentListScreen.tutorialHighlightKey;
      case 2:
        key = _autoSwitchKey;
      case 4:
        key = _staminaKey;
    }
    // Step 1（升級）和 Step 3（每日任務）是 push 頁面，不需要外層 overlay
    if (key == null) return const SizedBox.shrink();
    return TutorialHighlightOverlay(
      highlightKey: key,
      passthrough: true,
    );
  }
}

/// 偵測教學動作完成
class _TutorialActionListener extends StatelessWidget {
  final int step;
  final bool showDialogue;
  final bool actionDone;
  final VoidCallback onTeamSetup;
  final VoidCallback onAutoEnabled;

  const _TutorialActionListener({
    required this.step,
    required this.showDialogue,
    required this.actionDone,
    required this.onTeamSetup,
    required this.onAutoEnabled,
  });

  @override
  Widget build(BuildContext context) {
    if (showDialogue || actionDone) return const SizedBox.shrink();

    switch (step) {
      case 0:
        // 偵測 team 包含 'tide'
        return Consumer<PlayerProvider>(
          builder: (context, player, _) {
            if (player.data.team.contains(TutorialConfig.luluAgentId)) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                onTeamSetup();
              });
            }
            return const SizedBox.shrink();
          },
        );
      case 2:
        // 偵測 autoConfig.isEnabled
        return Consumer<IdleProvider>(
          builder: (context, idle, _) {
            if (idle.autoConfig.isEnabled) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                onAutoEnabled();
              });
            }
            return const SizedBox.shrink();
          },
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
