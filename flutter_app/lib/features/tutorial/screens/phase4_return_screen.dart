import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../agents/providers/player_provider.dart';
import '../config/tutorial_config.dart';
import '../models/tutorial_dialogue_data.dart';
import '../providers/tutorial_provider.dart';
import '../widgets/tutorial_dialogue_box.dart';
import '../widgets/tutorial_highlight_overlay.dart';

/// Phase 4：回首頁收尾教學
/// 教隊伍編成、升級、自動消除、每日任務、元氣系統
class Phase4ReturnScreen extends StatefulWidget {
  const Phase4ReturnScreen({super.key});

  @override
  State<Phase4ReturnScreen> createState() => _Phase4ReturnScreenState();
}

class _Phase4ReturnScreenState extends State<Phase4ReturnScreen> {
  // step 0: 隊伍編成
  // step 1: 角色升級
  // step 2: 自動消除
  // step 3: 每日任務
  // step 4: 元氣系統
  // step 5: 教學結束
  int _step = 0;
  int _dialogueIndex = 0;
  bool _showDialogue = true;
  bool _actionDone = false;

  // 模擬的 UI 狀態
  bool _luluAddedToTeam = false;
  int _wheatLevel = 1;
  bool _autoEliminateOn = false;
  bool _dailyQuestClaimed = false;

  // GlobalKey
  final _teamSlotKey = GlobalKey();
  final _upgradeButtonKey = GlobalKey();
  final _autoToggleKey = GlobalKey();
  final _dailyQuestKey = GlobalKey();
  final _staminaBarKey = GlobalKey();

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

    // 恢復已完成狀態
    if (tutorial.state.teamSetupDone) _luluAddedToTeam = true;
    if (tutorial.state.upgradeDone) _wheatLevel = 2;
    if (tutorial.state.autoEliminateDone) _autoEliminateOn = true;
    if (tutorial.state.dailyQuestDone) _dailyQuestClaimed = true;
  }

  void _onDialogueTap() {
    final dialogues = _stepDialogues[_step];
    if (_dialogueIndex < dialogues.length - 1) {
      setState(() => _dialogueIndex++);
    } else {
      // 對話完畢，等待操作
      setState(() {
        _showDialogue = false;
        _actionDone = false;
      });
    }
  }

  void _onActionComplete() {
    HapticFeedback.lightImpact();
    final tutorial = context.read<TutorialProvider>();

    // 標記完成
    switch (_step) {
      case 0:
        tutorial.markTeamSetupDone();
        // 顯示完成對話
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
      _showDialogue = true;
      _dialogueIndex = 0;
      _actionDone = true;
    });
    // 用自動推進的方式顯示完成對話
    _showSequentialDialogues(dialogues, 0);
  }

  void _showSequentialDialogues(List<TutorialDialogue> dialogues, int index) {
    if (index >= dialogues.length) {
      _advanceStep();
      return;
    }
    setState(() {
      _currentCompletionDialogue = dialogues[index];
      _showDialogue = true;
    });
  }

  TutorialDialogue? _currentCompletionDialogue;

  void _advanceStep() {
    final tutorial = context.read<TutorialProvider>();
    tutorial.advanceStep();
    setState(() {
      _step++;
      _dialogueIndex = 0;
      _showDialogue = true;
      _actionDone = false;
      _currentCompletionDialogue = null;
    });

    if (_step >= _stepDialogues.length) {
      _completeTutorial();
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
                  // 獎勵展示
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
                        // 完成教學
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
      body: SafeArea(
        child: Stack(
          children: [
            // 主內容
            _buildStepContent(),

            // 高亮 overlay
            if (!_showDialogue && !_actionDone) _buildHighlight(),

            // 對話框
            if (_showDialogue)
              TutorialDialogueBox(
                dialogue: _actionDone && _currentCompletionDialogue != null
                    ? _currentCompletionDialogue!
                    : _stepDialogues[_step][_dialogueIndex],
                onTap: _actionDone
                    ? () {
                        // 完成對話 → 推進步驟
                        _advanceStep();
                      }
                    : _onDialogueTap,
                onComplete: () {
                  final d = _actionDone && _currentCompletionDialogue != null
                      ? _currentCompletionDialogue!
                      : _stepDialogues[_step][_dialogueIndex];
                  if (d.autoAdvanceDelay != null) {
                    if (_actionDone) {
                      _advanceStep();
                    } else {
                      _onDialogueTap();
                    }
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHighlight() {
    GlobalKey? key;
    switch (_step) {
      case 0:
        key = _teamSlotKey;
      case 1:
        key = _upgradeButtonKey;
      case 2:
        key = _autoToggleKey;
      case 3:
        key = _dailyQuestKey;
      case 4:
        key = _staminaBarKey;
    }
    if (key == null) return const SizedBox.shrink();
    return TutorialHighlightOverlay(
      highlightKey: key,
      blockInput: false,
    );
  }

  Widget _buildStepContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 頂部狀態欄（模擬）
          _buildSimulatedTopBar(),
          const SizedBox(height: 24),

          // 根據步驟顯示不同內容
          if (_step == 0) _buildTeamSetup(),
          if (_step == 1) _buildUpgradePanel(),
          if (_step == 2) _buildAutoEliminate(),
          if (_step == 3) _buildDailyQuest(),
          if (_step == 4) _buildStaminaInfo(),
          if (_step == 5) _buildCompletionScene(),
        ],
      ),
    );
  }

  Widget _buildSimulatedTopBar() {
    return Container(
      key: _staminaBarKey,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Text('🐱 Lv.1', style: TextStyle(color: AppTheme.textPrimary)),
          const Spacer(),
          const Text('🔥 58/60',
              style: TextStyle(color: AppTheme.textPrimary, fontSize: 13)),
          const SizedBox(width: 12),
          const Text('🍬 150',
              style: TextStyle(color: AppTheme.textPrimary, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildTeamSetup() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '隊伍編成',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            // 小麥（已在隊伍）
            _buildTeamSlot(
              name: '小麥',
              emoji: '☀️',
              color: AppTheme.blockCoral,
              filled: true,
            ),
            const SizedBox(width: 12),
            // 露露（待加入）
            GestureDetector(
              key: _teamSlotKey,
              onTap: () {
                if (!_luluAddedToTeam && !_showDialogue) {
                  setState(() => _luluAddedToTeam = true);
                  _onActionComplete();
                }
              },
              child: _buildTeamSlot(
                name: _luluAddedToTeam ? '露露' : '空位',
                emoji: _luluAddedToTeam ? '💧' : '➕',
                color: _luluAddedToTeam
                    ? AppTheme.blockTeal
                    : AppTheme.textSecondary.withAlpha(60),
                filled: _luluAddedToTeam,
                highlight: !_luluAddedToTeam && !_showDialogue,
              ),
            ),
            const SizedBox(width: 12),
            _buildTeamSlot(
              name: '空位',
              emoji: '🔒',
              color: AppTheme.textSecondary.withAlpha(30),
              filled: false,
            ),
          ],
        ),
        if (!_luluAddedToTeam) ...[
          const SizedBox(height: 24),
          // 可用角色列表
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.bgSecondary.withAlpha(100),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD54F),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('NEW!',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 8),
                const Text('💧', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 8),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('露露',
                        style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.bold)),
                    Text('💧水滴 | 支援者',
                        style: TextStyle(
                            color: AppTheme.textSecondary, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTeamSlot({
    required String name,
    required String emoji,
    required Color color,
    required bool filled,
    bool highlight = false,
  }) {
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 100,
        decoration: BoxDecoration(
          color: filled ? color.withAlpha(30) : AppTheme.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: highlight
                ? AppTheme.accentPrimary
                : filled
                    ? color.withAlpha(100)
                    : AppTheme.textSecondary.withAlpha(30),
            width: highlight ? 2.5 : 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 4),
            Text(
              name,
              style: TextStyle(
                color: filled ? AppTheme.textPrimary : AppTheme.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpgradePanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '角色升級',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.bgCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.blockCoral.withAlpha(80)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Text('☀️', style: TextStyle(fontSize: 40)),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('小麥',
                          style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                      Text('Lv.$_wheatLevel ☀️突擊手',
                          style: const TextStyle(
                              color: AppTheme.textSecondary, fontSize: 13)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_wheatLevel >= 2)
                const Text(
                  '✅ 已升級！ATK +5, HP +10',
                  style: TextStyle(color: AppTheme.stageCleared, fontSize: 14),
                )
              else
                GestureDetector(
                  key: _upgradeButtonKey,
                  onTap: () {
                    if (!_showDialogue) {
                      setState(() => _wheatLevel = 2);
                      _onActionComplete();
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.accentPrimary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                      child: Text(
                        '⬆️ 升級（消耗 ☕×1）',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAutoEliminate() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '自動消除',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.bgCard,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              const Text('🤖', style: TextStyle(fontSize: 32)),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('自動揉麵機',
                        style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.bold)),
                    Text('離線時也會自動收集食材',
                        style: TextStyle(
                            color: AppTheme.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              GestureDetector(
                key: _autoToggleKey,
                onTap: () {
                  if (!_autoEliminateOn && !_showDialogue) {
                    setState(() => _autoEliminateOn = true);
                    _onActionComplete();
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 56,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _autoEliminateOn
                        ? AppTheme.stageCleared
                        : AppTheme.textSecondary.withAlpha(60),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: AnimatedAlign(
                    duration: const Duration(milliseconds: 300),
                    alignment: _autoEliminateOn
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      width: 28,
                      height: 28,
                      margin: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDailyQuest() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '每日任務',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          key: _dailyQuestKey,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.bgCard,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              _buildQuestRow('每日登入', '登入遊戲', '50 🍬', true),
              const Divider(height: 20),
              _buildQuestRow('完成 3 關', '通關任意 3 關', '100 🍬', true),
              const Divider(height: 20),
              _buildQuestRow('消除 200 個', '消除方塊', '1 ☕', false),
              const SizedBox(height: 16),
              if (!_dailyQuestClaimed)
                GestureDetector(
                  onTap: () {
                    if (!_showDialogue) {
                      setState(() => _dailyQuestClaimed = true);
                      _onActionComplete();
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.accentPrimary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                      child: Text(
                        '領取已完成獎勵！',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                )
              else
                const Text(
                  '✅ 獎勵已領取',
                  style: TextStyle(color: AppTheme.stageCleared),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuestRow(
      String name, String desc, String reward, bool completed) {
    return Row(
      children: [
        Icon(
          completed ? Icons.check_circle : Icons.radio_button_unchecked,
          color: completed ? AppTheme.stageCleared : AppTheme.textSecondary,
          size: 20,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name,
                  style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
              Text(desc,
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 12)),
            ],
          ),
        ),
        Text(reward,
            style: const TextStyle(
                color: AppTheme.accentPrimary, fontSize: 13)),
      ],
    );
  }

  Widget _buildStaminaInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '元氣系統',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.bgCard,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Text('🔥', style: TextStyle(fontSize: 32)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('元氣 58/60',
                            style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: const LinearProgressIndicator(
                            value: 58 / 60,
                            backgroundColor: Color(0x30000000),
                            valueColor: AlwaysStoppedAnimation<Color>(
                                AppTheme.accentPrimary),
                            minHeight: 8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '每 8 分鐘恢復 1 點元氣\n探索地下室消耗 4-8 元氣',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () {
                  if (!_showDialogue) _onActionComplete();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.accentPrimary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '了解！',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompletionScene() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 60),
          Text('🎉', style: TextStyle(fontSize: 64)),
          SizedBox(height: 20),
          Text(
            '所有教學完成！',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
