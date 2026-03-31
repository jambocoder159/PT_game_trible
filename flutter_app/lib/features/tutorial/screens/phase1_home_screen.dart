import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../config/game_modes.dart';
import '../../../config/theme.dart';
import '../../game/providers/game_provider.dart';
import '../../game/widgets/game_board.dart';
import '../config/tutorial_config.dart';
import '../models/tutorial_dialogue_data.dart';
import '../providers/tutorial_provider.dart';
import '../widgets/tutorial_dialogue_box.dart';
import '../widgets/tutorial_gesture_hint.dart';
import '../widgets/tutorial_highlight_overlay.dart';
import '../widgets/tutorial_task_panel.dart';

/// Phase 1：首頁教學
/// 簡化版首頁 + 教學 overlay，教方塊操作 → 做點心 → 出售
class Phase1HomeScreen extends StatefulWidget {
  const Phase1HomeScreen({super.key});

  @override
  State<Phase1HomeScreen> createState() => _Phase1HomeScreenState();
}

class _Phase1HomeScreenState extends State<Phase1HomeScreen> {
  // ─── 步驟狀態 ───
  // 0: 推開店門
  // 1: 認識方塊
  // 2: 點擊採集
  // 3: 滑動移動 (sub 0=上, 1=下)
  // 4: 三連消
  // 5: 能量充滿
  // 6: 做成點心
  // 7: 出售點心
  // 8: 小任務（做出 3 份）
  int _step = 0;
  int _subStep = 0;
  bool _waitingForAction = false;
  bool _doorOpened = false;
  int _lastActionCount = 0;
  int _lastCombo = 0;

  // 對話相關
  TutorialDialogue? _currentDialogue;
  bool _showDialogue = true;

  // 小任務
  int _pastriesMade = 0;
  bool _ingredientReady = false;
  bool _pastryReady = false;

  // 模擬的資源
  int _energy = 0;
  int _coins = 0;
  static const int _maxEnergy = 100;

  // 高亮 Key
  final _boardKey = GlobalKey();
  final _energyBarKey = GlobalKey();
  final _craftButtonKey = GlobalKey();
  final _sellButtonKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    final tutorial = context.read<TutorialProvider>();
    _step = tutorial.currentStep;
    _subStep = tutorial.state.currentSubStep;
    _pastriesMade = tutorial.state.pastriesSold;

    if (_step > 0) _doorOpened = true;
    if (_step >= 5) _ingredientReady = true;
    if (_step >= 6) _pastryReady = true;

    _updateDialogue();

    if (_step >= 1) {
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

  void _updateDialogue() {
    setState(() {
      _showDialogue = true;
      switch (_step) {
        case 0:
          _currentDialogue = TutorialDialogues.t006;
          _waitingForAction = false;
        case 1:
          _currentDialogue = TutorialDialogues.t007;
          _waitingForAction = false;
        case 2:
          _currentDialogue = TutorialDialogues.t009a;
          _waitingForAction = false;
        case 3:
          if (_subStep == 0) {
            _currentDialogue = TutorialDialogues.t009c;
          } else {
            _currentDialogue = TutorialDialogues.t009e;
          }
          _waitingForAction = false;
        case 4:
          _currentDialogue = TutorialDialogues.t009f;
          _waitingForAction = false;
        case 5:
          _currentDialogue = TutorialDialogues.t011;
          _waitingForAction = false;
        case 6:
          _currentDialogue = TutorialDialogues.t012;
          _waitingForAction = false;
        case 7:
          _currentDialogue = TutorialDialogues.t013;
          _waitingForAction = false;
        case 8:
          _currentDialogue = TutorialDialogues.t015;
          _waitingForAction = false;
        default:
          _currentDialogue = null;
      }
    });
  }

  void _onDialogueTap() {
    switch (_step) {
      case 0:
        // 等玩家點門
        setState(() => _showDialogue = false);
      case 1:
        // 顯示第二段對話（五色方塊）
        if (_currentDialogue?.id == 'T007') {
          setState(() {
            _currentDialogue = TutorialDialogues.t008;
          });
        } else {
          _goToStep(2);
        }
      case 2:
        // 進入等待操作
        setState(() {
          _waitingForAction = true;
          _showDialogue = false;
        });
        _recordBaseline();
      case 3:
        setState(() {
          _waitingForAction = true;
          _showDialogue = false;
        });
        _recordBaseline();
      case 4:
        setState(() {
          _waitingForAction = true;
          _showDialogue = false;
        });
        _recordBaseline();
      case 5:
        // 模擬能量充滿
        _simulateEnergyFill();
      case 6:
        _doCraft();
      case 7:
        _doSell();
      case 8:
        // 開始小任務
        setState(() {
          _waitingForAction = true;
          _showDialogue = false;
        });
    }
  }

  void _recordBaseline() {
    final game = context.read<GameProvider>();
    _lastActionCount = game.state?.actionCount ?? 0;
    _lastCombo = game.state?.combo ?? 0;
  }

  void _goToStep(int step, {int subStep = 0}) {
    final tutorial = context.read<TutorialProvider>();
    tutorial.setStep(step, subStep: subStep);
    setState(() {
      _step = step;
      _subStep = subStep;
    });
    _updateDialogue();
  }

  void _onActionDetected() {
    HapticFeedback.lightImpact();
    setState(() => _waitingForAction = false);

    switch (_step) {
      case 2:
        // 點擊成功
        setState(() {
          _currentDialogue = TutorialDialogues.t009b;
          _showDialogue = true;
        });
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) _goToStep(3);
        });
      case 3:
        if (_subStep == 0) {
          // 上拖成功
          setState(() {
            _currentDialogue = TutorialDialogues.t009d;
            _showDialogue = true;
          });
          Future.delayed(const Duration(milliseconds: 1500), () {
            if (mounted) _goToStep(3, subStep: 1);
          });
        } else {
          // 下拖成功
          _goToStep(4);
        }
      case 4:
        // 三連消成功
        setState(() {
          _currentDialogue = TutorialDialogues.t010a;
          _showDialogue = true;
        });
        Future.delayed(const Duration(milliseconds: 2000), () {
          if (mounted) {
            setState(() {
              _currentDialogue = TutorialDialogues.t010b;
            });
            Future.delayed(const Duration(milliseconds: 2500), () {
              if (mounted) _goToStep(5);
            });
          }
        });
    }
  }

  void _simulateEnergyFill() {
    setState(() {
      _showDialogue = false;
      _energy = 0;
    });
    // 模擬能量逐漸充滿
    Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _energy += 5;
        if (_energy >= _maxEnergy) {
          _energy = _maxEnergy;
          timer.cancel();
          _ingredientReady = true;
          HapticFeedback.mediumImpact();
          _goToStep(6);
        }
      });
    });
  }

  void _doCraft() {
    setState(() {
      _showDialogue = false;
      _ingredientReady = false;
    });
    // 模擬製作動畫
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        HapticFeedback.mediumImpact();
        setState(() {
          _pastryReady = true;
        });
        _goToStep(7);
      }
    });
  }

  void _doSell() {
    setState(() {
      _showDialogue = false;
      _pastryReady = false;
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        HapticFeedback.mediumImpact();
        setState(() {
          _coins += 50;
          _pastriesMade++;
        });
        // 出售成功對話
        setState(() {
          _currentDialogue = TutorialDialogues.t014;
          _showDialogue = true;
        });
        Future.delayed(const Duration(milliseconds: 2000), () {
          if (mounted) _goToStep(8);
        });
      }
    });
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

  void _onMiniTaskAction() {
    // 小任務期間的自由操作
    if (_step == 8 && _waitingForAction) {
      // 模擬每次操作累積能量
      setState(() {
        _energy += 25;
        if (_energy >= _maxEnergy) {
          _energy = 0;
          _pastryReady = true;
        }
      });
    }
  }

  void _onMiniTaskSell() {
    if (_step == 8 && _pastryReady) {
      HapticFeedback.lightImpact();
      setState(() {
        _pastryReady = false;
        _coins += 50;
        _pastriesMade++;
      });
      context.read<TutorialProvider>().incrementPastriesSold();

      if (_pastriesMade >= TutorialConfig.pastriesToMake) {
        setState(() => _waitingForAction = false);
        setState(() {
          _currentDialogue = TutorialDialogues.t016;
          _showDialogue = true;
        });
        Future.delayed(const Duration(milliseconds: 2000), () {
          if (mounted) {
            context.read<TutorialProvider>().advancePhase();
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Step 0：推開店門
    if (!_doorOpened) {
      return _buildDoorScene();
    }

    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      body: SafeArea(
        child: Consumer<GameProvider>(
          builder: (context, game, _) {
            // 監聽操作推進
            if (_waitingForAction && game.state != null && _step <= 4) {
              if (_step == 4) {
                // 等三連消
                if (game.state!.combo > _lastCombo) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted && _waitingForAction) _onActionDetected();
                  });
                }
              } else {
                // 等任意操作
                if (game.state!.actionCount > _lastActionCount) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted && _waitingForAction) _onActionDetected();
                  });
                }
              }
            }

            // 小任務期間追蹤操作
            if (_step == 8 && _waitingForAction && game.state != null) {
              final currentActions = game.state!.actionCount;
              if (currentActions > _lastActionCount) {
                _lastActionCount = currentActions;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) _onMiniTaskAction();
                });
              }
            }

            return Stack(
              children: [
                // ─── 主要內容 ───
                Column(
                  children: [
                    // 頂部資訊列
                    _buildTopBar(),

                    // 能量條
                    if (_step >= 5)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _buildEnergyBar(),
                      ),

                    const SizedBox(height: 8),

                    // 遊戲棋盤
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Center(
                          child: AbsorbPointer(
                            absorbing:
                                !_waitingForAction && _step != 8,
                            child: GestureDetector(
                              key: _boardKey,
                              child: const GameBoard(),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // 下方操作區
                    if (_step >= 6) _buildActionBar(),

                    const SizedBox(height: 12),
                  ],
                ),

                // ─── 高亮 Overlay ───
                if (_step == 5 && !_showDialogue)
                  TutorialHighlightOverlay(
                    highlightKey: _energyBarKey,
                    blockInput: false,
                  ),

                if (_step == 6 && !_showDialogue)
                  TutorialHighlightOverlay(
                    highlightKey: _craftButtonKey,
                    blockInput: false,
                  ),

                if (_step == 7 && !_showDialogue)
                  TutorialHighlightOverlay(
                    highlightKey: _sellButtonKey,
                    blockInput: false,
                  ),

                // ─── 手勢引導 ───
                if (_waitingForAction && _step == 2)
                  const TutorialGestureHint(gestureType: 'tap'),
                if (_waitingForAction && _step == 3 && _subStep == 0)
                  const TutorialGestureHint(gestureType: 'up'),
                if (_waitingForAction && _step == 3 && _subStep == 1)
                  const TutorialGestureHint(gestureType: 'down'),
                if (_waitingForAction && _step == 4)
                  const TutorialGestureHint(gestureType: 'tap'),

                // ─── 小任務面板 ───
                if (_step == 8)
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 50,
                    right: 0,
                    child: TutorialTaskPanel(
                      title: '製作並出售 3 份點心',
                      current: _pastriesMade,
                      target: TutorialConfig.pastriesToMake,
                      reward: '100 🍬',
                    ),
                  ),

                // ─── 對話框 ───
                if (_showDialogue && _currentDialogue != null)
                  TutorialDialogueBox(
                    dialogue: _currentDialogue!,
                    onTap: _onDialogueTap,
                    onComplete: () {
                      if (_currentDialogue?.autoAdvanceDelay != null) {
                        _onDialogueTap();
                      }
                    },
                  ),

                // ─── 等待操作提示 ───
                if (_waitingForAction && !_showDialogue && _step <= 4)
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: MediaQuery.of(context).padding.bottom + 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.bgSecondary.withAlpha(220),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getWaitingHint(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppTheme.accentPrimary,
                          fontSize: 14,
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

  String _getWaitingHint() {
    switch (_step) {
      case 2:
        return '👆 點擊棋盤上任一個方塊！';
      case 3:
        return _subStep == 0 ? '☝️ 長按方塊往上拖！' : '👇 長按方塊往下拖！';
      case 4:
        return '🎯 讓三個相同食材排在一起！';
      default:
        return '👆 請在棋盤上操作';
    }
  }

  Widget _buildDoorScene() {
    return Scaffold(
      backgroundColor: const Color(0xFF8D6E63),
      body: Stack(
        children: [
          // 背景
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFA1887F), Color(0xFF6D4C41)],
              ),
            ),
          ),

          // 門的 placeholder
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
                  borderRadius: BorderRadius.circular(
                      _doorOpened ? 0 : 16),
                  border: _doorOpened
                      ? null
                      : Border.all(
                          color: const Color(0xFFD7CCC8),
                          width: 3,
                        ),
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
                      Text(
                        _doorOpened ? '🌟' : '🚪',
                        style: const TextStyle(fontSize: 64),
                      ),
                      if (!_doorOpened) ...[
                        const SizedBox(height: 16),
                        Text(
                          '點擊開門',
                          style: TextStyle(
                            color: AppTheme.bgSecondary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 對話
          if (_showDialogue && _currentDialogue != null)
            TutorialDialogueBox(
              dialogue: _currentDialogue!,
              onTap: () {
                setState(() => _showDialogue = false);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Text(
            '🏪 教學模式',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
          ),
          const Spacer(),
          if (_coins > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.bgSecondary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '🍬 $_coins',
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEnergyBar() {
    return Container(
      key: _energyBarKey,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary.withAlpha(150),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Text('⚡', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _energy / _maxEnergy,
                backgroundColor: AppTheme.textSecondary.withAlpha(30),
                valueColor: AlwaysStoppedAnimation<Color>(
                  _energy >= _maxEnergy
                      ? AppTheme.stageCleared
                      : AppTheme.accentPrimary,
                ),
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$_energy/$_maxEnergy',
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // 製作按鈕
          Expanded(
            child: GestureDetector(
              key: _craftButtonKey,
              onTap: () {
                if (_step == 6) _onDialogueTap();
                if (_step == 8 && _ingredientReady) {
                  setState(() {
                    _ingredientReady = false;
                    _pastryReady = true;
                  });
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: _ingredientReady
                      ? AppTheme.accentPrimary
                      : AppTheme.bgSecondary,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.accentPrimary.withAlpha(100),
                  ),
                ),
                child: Center(
                  child: Text(
                    _ingredientReady ? '🍞 製作點心！' : '🥣 等待食材...',
                    style: TextStyle(
                      color: _ingredientReady
                          ? Colors.white
                          : AppTheme.textSecondary,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // 出售按鈕
          Expanded(
            child: GestureDetector(
              key: _sellButtonKey,
              onTap: () {
                if (_step == 7) _onDialogueTap();
                if (_step == 8 && _pastryReady) _onMiniTaskSell();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: _pastryReady
                      ? const Color(0xFF4CAF50)
                      : AppTheme.bgSecondary,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _pastryReady
                        ? const Color(0xFF4CAF50).withAlpha(150)
                        : AppTheme.textSecondary.withAlpha(40),
                  ),
                ),
                child: Center(
                  child: Text(
                    _pastryReady ? '💰 出售！' : '📦 無點心',
                    style: TextStyle(
                      color:
                          _pastryReady ? Colors.white : AppTheme.textSecondary,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
