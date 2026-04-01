import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../config/game_modes.dart';
import '../../../config/theme.dart';
import '../../../core/models/block.dart';
import '../../../core/models/bottle_data.dart';
import '../../agents/providers/player_provider.dart';
import '../../game/providers/game_provider.dart';
import '../../game/widgets/game_board.dart';
import '../../idle/providers/bottle_provider.dart';
import '../../idle/providers/crafting_provider.dart';
import '../../idle/screens/home_screen.dart';
import '../../../config/ingredient_data.dart';
import '../models/tutorial_dialogue_data.dart';
import '../providers/tutorial_provider.dart';
import '../widgets/tutorial_dialogue_box.dart';
import '../widgets/tutorial_gesture_hint.dart';
import '../widgets/tutorial_highlight_overlay.dart';

/// Phase 1：首頁教學
/// Part A（steps 0-11）：基礎操作（點擊/上拖/下拖/三連消）
/// Part B（steps 12-17）：真正首頁上引導瓶子→兌換→製作甜點→闖關入口
class Phase1HomeScreen extends StatefulWidget {
  const Phase1HomeScreen({super.key});

  @override
  State<Phase1HomeScreen> createState() => _Phase1HomeScreenState();
}

class _Phase1HomeScreenState extends State<Phase1HomeScreen> {
  int _step = 0;
  bool _waitingForAction = false;
  bool _doorOpened = false;
  int _lastActionCount = 0;
  int _lastCombo = 0;
  bool _transitioning = false;

  // Part B
  bool _showHomeScreen = false;
  // Part B 步驟：
  // 12: 歡迎來到首頁（對話）
  // 13: 高亮瓶子區 + 等待瓶子滿 + 對話
  // 14: 高亮「一鍵兌換」 + 等用戶點擊 + 對話
  // 15: 高亮「製作甜點」 + 等用戶點擊 + 對話
  // 16: 完成甜點製作 + 對話
  // 17: 高亮底部導航「闖關」→ 等用戶點擊 → 完成 Phase 1
  int _homeTutorialStep = 0; // 0-5 對應 step 12-17
  bool _showHomeTutorialDialogue = true;
  bool _waitingForHomeTutorialAction = false;
  // 追蹤用戶是否已執行操作
  bool _hasConverted = false;
  bool _hasCrafted = false;

  // HomeScreen 的 GlobalKey — 用來取得 HomeScreen State
  final GlobalKey<State> _homeScreenKey = GlobalKey();

  // Part B 高亮用 GlobalKey
  final GlobalKey _highlightBottleAreaKey = GlobalKey();
  final GlobalKey _highlightConvertButtonKey = GlobalKey();
  final GlobalKey _highlightCraftButtonKey = GlobalKey();
  final GlobalKey _highlightNavBarKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    final tutorial = context.read<TutorialProvider>();
    _step = tutorial.currentStep;
    if (_step > 0) _doorOpened = true;
    if (_step >= 12) {
      _showHomeScreen = true;
      _homeTutorialStep = (_step - 12).clamp(0, 5);
      // 恢復 Part B 等待狀態
      _restoreHomeTutorialState();
    }

    if (_step >= 3 && _step < 12) {
      // 恢復 Part A 等待操作步驟的狀態
      if (_step == 3 || _step == 5 || _step == 7 || _step == 9) {
        _waitingForAction = true;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startGame();
      });
    }
  }

  /// 恢復 Part B 首頁教學的中斷狀態
  void _restoreHomeTutorialState() {
    switch (_homeTutorialStep) {
      case 2:
        // 兌換步驟：需要等待用戶操作 + 確保瓶子有能量
        _waitingForHomeTutorialAction = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _ensureBottlesFilled();
        });
      case 3:
        // 製作甜點步驟：需要等待用戶操作 + 確保有食材
        _waitingForHomeTutorialAction = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _ensureCanCraft();
        });
      case 5:
        // 闖關入口步驟：等待用戶點擊
        _waitingForHomeTutorialAction = true;
    }
  }

  // ═══════════════════════════════════
  // Part A：基礎操作
  // ═══════════════════════════════════

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
        return;
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

  // ═══════════════════════════════════
  // Part B：首頁甜點教學
  // ═══════════════════════════════════

  void _enterHomeScreen() {
    _goToStep(12);
    setState(() {
      _showHomeScreen = true;
      _homeTutorialStep = 0;
      _showHomeTutorialDialogue = true;
    });
  }

  void _onHomeTutorialDialogueTap() {
    switch (_homeTutorialStep) {
      case 0:
        // 歡迎完畢 → 高亮瓶子區
        setState(() {
          _homeTutorialStep = 1;
          _showHomeTutorialDialogue = true;
        });
        _goToStep(13);
      case 1:
        // 瓶子說明完畢 → 確保瓶子有能量 → 高亮兌換按鈕
        _ensureBottlesFilled();
        setState(() {
          _homeTutorialStep = 2;
          _showHomeTutorialDialogue = true;
          _waitingForHomeTutorialAction = true;
        });
        _goToStep(14);
      case 2:
        // 兌換說明完畢（已經兌換過了） → 確保有食材 → 製作甜點
        if (_hasConverted) {
          _ensureCanCraft();
          setState(() {
            _homeTutorialStep = 3;
            _showHomeTutorialDialogue = true;
            _waitingForHomeTutorialAction = true;
          });
          _goToStep(15);
        }
      case 3:
        // 已製作過甜點 → 完成對話
        if (_hasCrafted) {
          setState(() {
            _homeTutorialStep = 4;
            _showHomeTutorialDialogue = true;
          });
          _goToStep(16);
        }
      case 4:
        // 完成對話 → 高亮闖關入口
        setState(() {
          _homeTutorialStep = 5;
          _showHomeTutorialDialogue = true;
          _waitingForHomeTutorialAction = true;
        });
        _goToStep(17);
      case 5:
        // 闖關入口 — 等待用戶自行點擊
        break;
    }
  }

  void _onUserConverted() {
    if (_homeTutorialStep == 2 && !_hasConverted) {
      setState(() {
        _hasConverted = true;
        _waitingForHomeTutorialAction = false;
        _showHomeTutorialDialogue = true;
      });
      // 顯示成功對話，然後自動進入下一步
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _onHomeTutorialDialogueTap();
      });
    }
  }

  void _onUserCrafted() {
    if (_homeTutorialStep == 3 && !_hasCrafted) {
      setState(() {
        _hasCrafted = true;
        _waitingForHomeTutorialAction = false;
        _showHomeTutorialDialogue = true;
      });
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _onHomeTutorialDialogueTap();
      });
    }
  }

  void _onUserTappedBattle() {
    // 用戶點了闖關 Tab → 完成 Phase 1
    _transitioning = true;
    context.read<TutorialProvider>().advancePhase();
  }

  /// 教學用：確保瓶子有足夠能量讓兌換可以執行
  void _ensureBottlesFilled() {
    final bp = context.read<BottleProvider>();
    if (!bp.isInitialized) return;
    final hasAnyFull = BottleDefinitions.all.any(
      (def) => bp.getBottle(def.color).isFull,
    );
    if (!hasAnyFull) {
      for (final color in BlockColor.values) {
        final bottle = bp.getBottle(color);
        final needed = bottle.capacity - bottle.currentEnergy;
        if (needed > 0) bp.addEnergy(color, needed);
      }
    }
  }

  /// 教學用：確保有食材可以製作甜點
  void _ensureCanCraft() {
    final player = context.read<PlayerProvider>();
    final crafting = context.read<CraftingProvider>();
    final canCraft = DessertDefinitions.all.any(
      (r) => crafting.canCraft(r.id, player.data),
    );
    if (!canCraft) {
      for (final color in BlockColor.values) {
        final available = IngredientDefinitions.getAvailable(color, 1);
        if (available.isNotEmpty) {
          final ingId = available.first.id;
          player.data.ingredients[ingId] =
              (player.data.ingredients[ingId] ?? 0) + 5;
        }
      }
      player.notifyAndSave();
    }
  }

  TutorialDialogue _homeDialogue() {
    switch (_homeTutorialStep) {
      case 0:
        return const TutorialDialogue(
          id: 'H01', speaker: Speakers.grandpa,
          content: '歡迎來到你的麵包店！\n這裡就是你經營甜點的地方。',
        );
      case 1:
        return const TutorialDialogue(
          id: 'H02', speaker: Speakers.grandpa,
          content: '看到左邊的瓶子了嗎？消除方塊會產生能量，\n瓶子滿了就能兌換食材喔！',
        );
      case 2:
        return _hasConverted
            ? const TutorialDialogue(
                id: 'H03b', speaker: Speakers.grandpa,
                content: '太棒了！你獲得了食材！\n現在來做甜點吧。',
              )
            : const TutorialDialogue(
                id: 'H03a', speaker: Speakers.grandpa,
                content: '試試點擊「一鍵兌換」，\n把瓶子裡的能量變成食材！',
              );
      case 3:
        return _hasCrafted
            ? const TutorialDialogue(
                id: 'H04b', speaker: Speakers.grandpa,
                content: '好吃的甜點完成了！\n客人們一定會很開心的。',
              )
            : const TutorialDialogue(
                id: 'H04a', speaker: Speakers.grandpa,
                content: '有了食材，就能製作甜點了！\n點擊「製作甜點」試試看。',
              );
      case 4:
        return const TutorialDialogue(
          id: 'H05', speaker: Speakers.grandpa,
          content: '你已經學會經營的基本流程了！\n消除方塊 → 收集能量 → 兌換食材 → 製作甜點',
        );
      case 5:
        return const TutorialDialogue(
          id: 'H06', speaker: Speakers.grandpa,
          content: '接下來，地下室好像有什麼動靜……\n去「闖關」看看吧！',
        );
      default:
        return TutorialDialogues.t006;
    }
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

  // ═══════════════════════════════════
  // Build
  // ═══════════════════════════════════

  @override
  Widget build(BuildContext context) {
    if (_showHomeScreen) return _buildHomeScreenWithGuide();
    if (!_doorOpened) return _buildDoorScene();
    return _buildOperationTutorial();
  }

  /// 根據 _homeTutorialStep 取得高亮目標 key
  GlobalKey? _highlightKeyForStep() {
    if (!_waitingForHomeTutorialAction || _showHomeTutorialDialogue) return null;
    switch (_homeTutorialStep) {
      case 1: return _highlightBottleAreaKey;    // 瓶子區域
      case 2: return _highlightConvertButtonKey; // 一鍵兌換
      case 3: return _highlightCraftButtonKey;   // 製作甜點
      case 5: return _highlightNavBarKey;        // 闖關 Tab
      default: return null;
    }
  }

  // ─── Part B：HomeScreen + 逐步引導 ───
  Widget _buildHomeScreenWithGuide() {
    final highlightKey = _highlightKeyForStep();

    return Stack(
      children: [
        // 真正的首頁
        HomeScreen(
          key: _homeScreenKey,
          tutorialMode: true,
          onTutorialNavTap: _homeTutorialStep == 5 ? _onUserTappedBattle : null,
          externalBottleAreaKey: _highlightBottleAreaKey,
          externalConvertButtonKey: _highlightConvertButtonKey,
          externalCraftButtonKey: _highlightCraftButtonKey,
          externalNavBarKey: _highlightNavBarKey,
        ),

        // 監聽瓶子和製作狀態
        _HomeActionListener(
          onConverted: _onUserConverted,
          onCrafted: _onUserCrafted,
          listenConvert: _homeTutorialStep == 2 && !_hasConverted,
          listenCraft: _homeTutorialStep == 3 && !_hasCrafted,
        ),

        // 高亮 overlay
        if (highlightKey != null)
          TutorialHighlightOverlay(
            highlightKey: highlightKey,
            passthrough: true,
          ),

        // 對話框（不擋住操作）
        if (_showHomeTutorialDialogue)
          TutorialDialogueBox(
            dialogue: _homeDialogue(),
            onTap: () {
              if (_waitingForHomeTutorialAction) {
                // 等待用戶操作，先關閉對話
                setState(() => _showHomeTutorialDialogue = false);
              } else {
                _onHomeTutorialDialogueTap();
              }
            },
          ),

        // 跳過按鈕
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          right: 12,
          child: TextButton(
            onPressed: _skipTutorial,
            child: const Text('跳過教學 →',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          ),
        ),
      ],
    );
  }

  // ─── Part A：操作教學 ───
  Widget _buildOperationTutorial() {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      body: SafeArea(
        child: Consumer<GameProvider>(
          builder: (context, game, _) {
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
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          const Text('🏪 教學模式',
                              style: TextStyle(
                                  color: AppTheme.textSecondary, fontSize: 14)),
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
                if (_waitingForAction && _gestureType() != null)
                  TutorialGestureHint(gestureType: _gestureType()!),
                if (!_waitingForAction)
                  TutorialDialogueBox(
                    dialogue: _currentDialogue(),
                    onTap: _onDialogueTap,
                    onComplete: () {
                      final d = _currentDialogue();
                      if (d.autoAdvanceDelay != null) _onDialogueTap();
                    },
                  ),
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

  // ─── 推開店門 ───
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
                  borderRadius: BorderRadius.circular(_doorOpened ? 0 : 16),
                  border: _doorOpened
                      ? null
                      : Border.all(color: const Color(0xFFD7CCC8), width: 3),
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

/// 監聽瓶子兌換和甜點製作狀態
class _HomeActionListener extends StatefulWidget {
  final VoidCallback onConverted;
  final VoidCallback onCrafted;
  final bool listenConvert;
  final bool listenCraft;

  const _HomeActionListener({
    required this.onConverted,
    required this.onCrafted,
    required this.listenConvert,
    required this.listenCraft,
  });

  @override
  State<_HomeActionListener> createState() => _HomeActionListenerState();
}

class _HomeActionListenerState extends State<_HomeActionListener> {
  int _lastIngredientCount = 0;
  int _lastDessertCount = 0;

  @override
  void initState() {
    super.initState();
    final player = context.read<PlayerProvider>();
    _lastIngredientCount = _totalIngredients(player);
    _lastDessertCount = _totalDesserts(player);
  }

  int _totalIngredients(PlayerProvider p) {
    return p.data.ingredients.values.fold(0, (a, b) => a + b);
  }

  int _totalDesserts(PlayerProvider p) {
    return p.data.desserts.values.fold(0, (a, b) => a + b);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (context, player, _) {
        if (widget.listenConvert) {
          final current = _totalIngredients(player);
          if (current > _lastIngredientCount) {
            _lastIngredientCount = current;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              widget.onConverted();
            });
          }
        }
        if (widget.listenCraft) {
          final current = _totalDesserts(player);
          if (current > _lastDessertCount) {
            _lastDessertCount = current;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              widget.onCrafted();
            });
          }
        }
        return const SizedBox.shrink();
      },
    );
  }
}
