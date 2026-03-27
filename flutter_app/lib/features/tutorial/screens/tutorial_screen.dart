import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/game_modes.dart';
import '../../../config/theme.dart';
import '../../agents/providers/player_provider.dart';
import '../../game/providers/game_provider.dart';
import '../../game/widgets/game_board.dart';
import '../../idle/screens/home_screen.dart';
import '../widgets/tutorial_overlay.dart';

/// 新手引導畫面
/// 在 triple 模式（3x10 三排）上疊加步驟式教學 overlay
class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  int _currentStep = 0;
  bool _waitingForAction = false;
  int _lastActionCount = 0;
  int _lastCombo = 0;

  static const _steps = [
    // Step 0: 歡迎
    TutorialStep(
      title: '歡迎來到貓咪點心屋！',
      description: '這是一個充滿策略性的三消遊戲。\n\n'
          '在 3×10 的棋盤上採集食材、'
          '製造連鎖來擊退搗蛋鬼。\n'
          '讓我們花一分鐘學習基本操作！',
      buttonText: '開始學習',
    ),
    // Step 1: 點擊消除
    TutorialStep(
      title: '基本操作：點擊消除',
      description: '點擊任意方塊可以直接消除它。\n\n'
          '消除後上方的方塊會落下，'
          '新方塊會從頂部補充。\n\n'
          '試試看，點擊棋盤上任一個方塊！',
      gestureHint: 'tap',
    ),
    // Step 2: 長按上移
    TutorialStep(
      title: '進階操作：長按 + 上移',
      description: '長按方塊並向上拖曳，\n'
          '可以將它移動到該列的最頂部。\n\n'
          '這是製造三消的關鍵技巧！\n\n'
          '試試看，長按一個方塊往上拖！',
      gestureHint: 'up',
    ),
    // Step 3: 長按下移
    TutorialStep(
      title: '進階操作：長按 + 下移',
      description: '長按方塊並向下拖曳，\n'
          '可以將它移動到該列的最底部。\n\n'
          '搭配上移使用，能更靈活地排列方塊。\n\n'
          '試試看，長按一個方塊往下拖！',
      gestureHint: 'down',
    ),
    // Step 4: 三消體驗（自由操作直到觸發真正的三消）
    TutorialStep(
      title: '目標：三消連鎖！',
      description: '當同一列有三個或更多相同顏色的方塊'
          '連續排列，就會觸發「三消」！\n\n'
          '同一橫排三個相同顏色也能消除。\n\n'
          '自由操作棋盤，製造一次三消吧！',
      gestureHint: 'tap',
      waitingHint: '🎯 嘗試讓三個相同顏色排成一列！',
    ),
    // Step 5: 完成
    TutorialStep(
      title: '太棒了！教學完成！',
      description: '您已經掌握了基本操作：\n\n'
          '• 點擊 → 消除方塊\n'
          '• 長按 + 上拖 → 移到頂部\n'
          '• 長按 + 下拖 → 移到底部\n'
          '• 三消 → 大量分數！\n\n'
          '準備好開始烘焙了嗎？',
      buttonText: '開始遊戲！',
      showSkip: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startTutorialGame();
    });
  }

  void _startTutorialGame() {
    final game = context.read<GameProvider>();
    game.startGame(GameModes.triple);
    _lastActionCount = 0;
    _lastCombo = 0;
  }

  void _nextStep() {
    if (_currentStep >= _steps.length - 1) {
      _completeTutorial();
      return;
    }

    final game = context.read<GameProvider>();
    setState(() {
      _currentStep++;
      // 步驟 1-4 需要等待玩家操作
      _waitingForAction = _currentStep >= 1 && _currentStep <= 4;
      if (_waitingForAction) {
        _lastActionCount = game.state?.actionCount ?? 0;
        // 步驟 4 記錄 combo 用於偵測三消
        if (_currentStep == 4) {
          _lastCombo = game.state?.combo ?? 0;
        }
      }
    });
  }

  void _skipTutorial() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgSecondary,
        title: const Text('跳過教學？', style: TextStyle(color: AppTheme.textPrimary)),
        content: const Text(
          '您可以之後在設定中重新體驗教學。',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('繼續學習'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _completeTutorial();
            },
            child: const Text('跳過', style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );
  }

  void _completeTutorial() {
    context.read<PlayerProvider>().completeTutorial();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      body: SafeArea(
        child: Consumer<GameProvider>(
          builder: (context, game, _) {
            // 監聽玩家操作 → 推進教學步驟
            if (_waitingForAction && game.state != null) {
              if (_currentStep == 4) {
                // 步驟 4：等待真正觸發三消（combo 增加）
                final currentCombo = game.state!.combo;
                if (currentCombo > _lastCombo) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    setState(() => _waitingForAction = false);
                    Future.delayed(const Duration(milliseconds: 800), () {
                      if (mounted) _nextStep();
                    });
                  });
                }
              } else {
                // 步驟 1-3：任意操作即推進
                final currentActions = game.state!.actionCount;
                if (currentActions > _lastActionCount) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    setState(() => _waitingForAction = false);
                    Future.delayed(const Duration(milliseconds: 600), () {
                      if (mounted) _nextStep();
                    });
                  });
                }
              }
            }

            return Stack(
              children: [
                // 頂部標題
                Positioned(
                  top: 8,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Text(
                      '教學模式',
                      style: TextStyle(
                        color: AppTheme.textSecondary.withAlpha(150),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),

                // 遊戲棋盤（三排自適應寬度）
                Positioned.fill(
                  top: 30,
                  bottom: 200,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Center(
                      child: AbsorbPointer(
                        absorbing: !_waitingForAction,
                        child: const GameBoard(),
                      ),
                    ),
                  ),
                ),

                // 教學 overlay
                TutorialOverlay(
                  step: _steps[_currentStep],
                  onNext: _nextStep,
                  onSkip: _skipTutorial,
                  waitingForAction: _waitingForAction,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
