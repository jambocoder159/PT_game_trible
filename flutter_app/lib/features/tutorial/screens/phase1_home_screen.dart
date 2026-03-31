import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../config/game_modes.dart';
import '../../../config/theme.dart';
import '../../agents/providers/player_provider.dart';
import '../../game/providers/game_provider.dart';
import '../../game/widgets/game_board.dart';
import '../../idle/screens/home_screen.dart';
import '../../idle/widgets/home_guide_overlay.dart';
import '../models/tutorial_dialogue_data.dart';
import '../providers/tutorial_provider.dart';
import '../widgets/tutorial_dialogue_box.dart';
import '../widgets/tutorial_gesture_hint.dart';

/// Phase 1：首頁教學
/// 分兩階段：
///   Part A（steps 0-11）：基礎操作（點擊/上拖/下拖/三連消）
///   Part B（steps 12+）：引導到真正的 HomeScreen 學做甜點
class Phase1HomeScreen extends StatefulWidget {
  const Phase1HomeScreen({super.key});

  @override
  State<Phase1HomeScreen> createState() => _Phase1HomeScreenState();
}

class _Phase1HomeScreenState extends State<Phase1HomeScreen> {
  // ─── Part A 步驟定義 ───
  // 0: 推開店門
  // 1: 認識方塊（對話 1）
  // 2: 認識方塊（對話 2 - 五色說明）
  // 3: 點擊採集 → 等待操作
  // 4: 點擊成功回饋
  // 5: 上拖教學 → 等待操作
  // 6: 上拖成功 → 下拖提示
  // 7: 下拖教學 → 等待操作
  // 8: 三連消說明
  // 9: 三連消 → 等待操作
  // 10: 三連消成功回饋
  // 11: 總結 → 進入 Part B
  // 12+: Part B — 真正的 HomeScreen + 導覽
  int _step = 0;
  bool _waitingForAction = false;
  bool _doorOpened = false;
  int _lastActionCount = 0;
  int _lastCombo = 0;
  bool _transitioning = false;

  // Part B
  bool _showHomeScreen = false;

  @override
  void initState() {
    super.initState();
    final tutorial = context.read<TutorialProvider>();
    _step = tutorial.currentStep;
    if (_step > 0) _doorOpened = true;
    if (_step >= 12) _showHomeScreen = true;

    if (_step >= 3 && _step < 12) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startGame();
      });
    }
  }

  void _startGame() {
    final game = context.read<GameProvider>();
    game.startGame(GameModes.idle);
    _lastActionCount = game.state?.actionCount ?? 0;
    _lastCombo = game.state?.combo ?? 0;
  }

  void _goToStep(int step) {
    if (_transitioning) return;
    context.read<TutorialProvider>().setStep(step);
    setState(() => _step = step);
  }

  void _onDialogueTap() {
    if (_transitioning) return;
    switch (_step) {
      case 0:
        return; // 等玩家點門
      case 1:
        _goToStep(2);
      case 2:
        _goToStep(3);
        _startWaiting();
      case 4:
        _goToStep(5);
        _startWaiting();
      case 6:
        _goToStep(7);
        _startWaiting();
      case 8:
        _goToStep(9);
        _startWaiting();
      case 10:
        _goToStep(11);
      case 11:
        // 操作教學完成 → 進入 Part B（真正 HomeScreen）
        _enterHomeScreen();
    }
  }

  void _startWaiting() {
    final game = context.read<GameProvider>();
    _lastActionCount = game.state?.actionCount ?? 0;
    _lastCombo = game.state?.combo ?? 0;
    setState(() => _waitingForAction = true);
  }

  void _onActionDetected() {
    if (_transitioning) return;
    HapticFeedback.lightImpact();
    setState(() => _waitingForAction = false);
    switch (_step) {
      case 3:
        _goToStep(4);
      case 5:
        _goToStep(6);
      case 7:
        _goToStep(8);
      case 9:
        _goToStep(10);
    }
  }

  void _onDoorTap() {
    if (_step == 0 && !_doorOpened) {
      HapticFeedback.mediumImpact();
      setState(() => _doorOpened = true);
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) {
          _startGame();
          _goToStep(1);
        }
      });
    }
  }

  void _enterHomeScreen() {
    _goToStep(12);
    setState(() => _showHomeScreen = true);
  }

  void _onHomeGuideComplete() {
    // HomeScreen 導覽完成 → 進入 Phase 2
    _transitioning = true;
    context.read<TutorialProvider>().advancePhase();
  }

  void _completePhase() {
    _transitioning = true;
    context.read<TutorialProvider>().advancePhase();
  }

  void _skipTutorial() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgSecondary,
        title: const Text('跳過教學？',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: const Text('您可以稍後在設定中重新體驗教學。',
            style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('繼續學習'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context
                  .read<TutorialProvider>()
                  .skipEntireTutorial(context.read<PlayerProvider>());
            },
            child: const Text('跳過全部教學',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  TutorialDialogue _currentDialogue() {
    switch (_step) {
      case 0:
        return TutorialDialogues.t006;
      case 1:
        return TutorialDialogues.t007;
      case 2:
        return TutorialDialogues.t008;
      case 4:
        return TutorialDialogues.t009b;
      case 6:
        return TutorialDialogues.t009d;
      case 8:
        return TutorialDialogues.t009f;
      case 10:
        return TutorialDialogues.t010a;
      case 11:
        return TutorialDialogues.t010b;
      default:
        return TutorialDialogues.t006;
    }
  }

  String _waitingHint() {
    switch (_step) {
      case 3:
        return '👆 點擊棋盤上任一個方塊！';
      case 5:
        return '☝️ 長按方塊往上拖！';
      case 7:
        return '👇 長按方塊往下拖！';
      case 9:
        return '🎯 讓三個相同食材排在一起！';
      default:
        return '👆 請在棋盤上操作';
    }
  }

  String? _gestureType() {
    switch (_step) {
      case 3:
        return 'tap';
      case 5:
        return 'up';
      case 7:
        return 'down';
      case 9:
        return 'tap';
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    // ═══ Part B：真正的 HomeScreen + 甜點製作導覽 ═══
    if (_showHomeScreen) {
      return _buildHomeScreenWithGuide();
    }

    // ═══ Part A Step 0：推開店門 ═══
    if (!_doorOpened) {
      return _buildDoorScene();
    }

    // ═══ Part A Steps 1-11：操作教學 ═══
    return _buildOperationTutorial();
  }

  // ─────────────────────────────────
  // Part B：真正的 HomeScreen + 導覽
  // ─────────────────────────────────
  Widget _buildHomeScreenWithGuide() {
    return Stack(
      children: [
        // 真正的首頁（教學模式：跳過內建 HomeGuide）
        const HomeScreen(tutorialMode: true),

        // 教學導覽 overlay
        HomeGuideOverlay(
          steps: [
            const HomeGuideStep(
              title: '🏠 歡迎來到你的店面！',
              description: '基本操作你已經學會了！\n'
                  '現在來看看如何經營甜點店吧。',
              buttonText: '好的！',
            ),
            const HomeGuideStep(
              title: '🧪 能量瓶子系統',
              description: '消除方塊會產生能量，\n'
                  '5 個顏色的瓶子會收集對應的能量。\n'
                  '瓶子滿了就能兌換食材！',
              buttonText: '原來如此！',
            ),
            const HomeGuideStep(
              title: '🍰 製作甜點',
              description: '有了食材，就能製作甜點出售賺錢！\n'
                  '點擊左側面板的「一鍵兌換」和「製作甜點」按鈕試試。',
              buttonText: '了解！',
            ),
            const HomeGuideStep(
              title: '✨ 自由探索',
              description: '棋盤會自動掉落方塊，你也可以手動消除。\n'
                  '手動消除效率更高喔！\n\n'
                  '接下來，地下室好像有什麼動靜……',
              buttonText: '去看看！',
            ),
          ],
          onComplete: _onHomeGuideComplete,
        ),
      ],
    );
  }

  // ─────────────────────────────────
  // Part A：操作教學
  // ─────────────────────────────────
  Widget _buildOperationTutorial() {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      body: SafeArea(
        child: Consumer<GameProvider>(
          builder: (context, game, _) {
            // 監聽操作推進
            if (_waitingForAction && game.state != null) {
              if (_step == 9) {
                if (game.state!.combo > _lastCombo) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted && _waitingForAction) _onActionDetected();
                  });
                }
              } else {
                if (game.state!.actionCount > _lastActionCount) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted && _waitingForAction) _onActionDetected();
                  });
                }
              }
            }

            return Stack(
              children: [
                Column(
                  children: [
                    // 頂部
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          const Text('🏪 教學模式',
                              style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 14)),
                          const Spacer(),
                          TextButton(
                            onPressed: _skipTutorial,
                            child: const Text('跳過教學 →',
                                style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 13)),
                          ),
                        ],
                      ),
                    ),
                    // 棋盤
                    Expanded(
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
                    const SizedBox(height: 100),
                  ],
                ),

                // 手勢引導
                if (_waitingForAction && _gestureType() != null)
                  TutorialGestureHint(gestureType: _gestureType()!),

                // 對話框
                if (!_waitingForAction)
                  TutorialDialogueBox(
                    dialogue: _currentDialogue(),
                    onTap: _onDialogueTap,
                    onComplete: () {
                      final d = _currentDialogue();
                      if (d.autoAdvanceDelay != null) _onDialogueTap();
                    },
                  ),

                // 等待操作提示
                if (_waitingForAction)
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: MediaQuery.of(context).padding.bottom + 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.bgSecondary.withAlpha(230),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppTheme.accentPrimary.withAlpha(80)),
                      ),
                      child: Text(
                        _waitingHint(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppTheme.accentPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ─────────────────────────────────
  // 推開店門場景
  // ─────────────────────────────────
  Widget _buildDoorScene() {
    return Scaffold(
      backgroundColor: const Color(0xFF8D6E63),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFA1887F), Color(0xFF6D4C41)],
              ),
            ),
          ),
          Center(
            child: GestureDetector(
              onTap: _onDoorTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                width: _doorOpened ? 300 : 180,
                height: _doorOpened ? 400 : 280,
                decoration: BoxDecoration(
                  color: _doorOpened
                      ? AppTheme.bgPrimary
                      : const Color(0xFF5D4037),
                  borderRadius:
                      BorderRadius.circular(_doorOpened ? 0 : 16),
                  border: _doorOpened
                      ? null
                      : Border.all(
                          color: const Color(0xFFD7CCC8), width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(80),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_doorOpened ? '🌟' : '🚪',
                          style: const TextStyle(fontSize: 64)),
                      if (!_doorOpened) ...[
                        const SizedBox(height: 16),
                        const Text('點擊開門',
                            style: TextStyle(
                                color: AppTheme.bgSecondary,
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          TutorialDialogueBox(
            dialogue: TutorialDialogues.t006,
            onTap: () {},
            showTapHint: false,
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            right: 16,
            child: TextButton(
              onPressed: _skipTutorial,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(80),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text('跳過教學 →',
                    style: TextStyle(color: Colors.white70, fontSize: 14)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
