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
import '../widgets/tutorial_floating_hint.dart';
import '../widgets/tutorial_gesture_hint.dart';
import '../widgets/tutorial_highlight_overlay.dart';

/// Phase 1：首頁教學（精簡版）
/// Part A（steps 0-3）：推門 → 點擊 → 三連消 → 進首頁
/// Part B（steps 4-6）：兌換 → 製作甜點 → 去闖關
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
  // 0: 高亮「一鍵兌換」+ 浮動提示 + 等用戶點擊
  // 1: 高亮「製作甜點」+ 浮動提示 + 等用戶點擊
  // 2: 高亮底部導航「闖關」→ 阻斷對話 → 等用戶點擊 → 完成 Phase 1
  int _homeTutorialStep = 0;
  bool _showHomeTutorialDialogue = false; // 只有 step 2 用阻斷對話

  bool _waitingForHomeTutorialAction = false; // 恢復狀態追蹤用
  bool _hasConverted = false;
  bool _hasCrafted = false;

  // HomeScreen 的 GlobalKey
  final GlobalKey<State> _homeScreenKey = GlobalKey();

  // Part B 高亮用 GlobalKey
  final GlobalKey _highlightBottleAreaKey = GlobalKey();
  final GlobalKey _highlightConvertButtonKey = GlobalKey();
  final GlobalKey _highlightCraftButtonKey = GlobalKey();
  final GlobalKey _highlightNavBarKey = GlobalKey();

  // 浮動提示控制
  String? _floatingHintText;
  String? _floatingHintEmoji;
  TutorialHintPosition _floatingHintPosition = TutorialHintPosition.bottom;

  /// 預設棋盤（3 列 × 10 行），確保三連消容易觸發
  /// C=coral, M=mint, T=teal, G=gold, R=rose
  static const _c = BlockColor.coral;
  static const _m = BlockColor.mint;
  static const _t = BlockColor.teal;
  static const _g = BlockColor.gold;
  static const _r = BlockColor.rose;

  // 教學棋盤（全程共用一個，不切換）
  // 設計要點：
  //   row 9（底部）：col0=coral, col1=mint, col2=coral — 差一個就橫向三連
  //   col 1 row 7 = coral — 這是 Step 2 要玩家「向下滑」的目標方塊
  //   玩家下滑 col1 row7 的 coral → 移到底部 → row 9 全 coral → 橫向三連！
  //   其他位置無即時三連（縱向 & 橫向都安全）
  static final _tutorialGrid = [
    //  row: 0   1   2   3   4   5   6   7   8   9
    [_t, _m, _g, _r, _t, _m, _g, _r, _m, _c], // col 0 — row9=coral
    [_m, _g, _t, _m, _r, _g, _t, _c, _g, _m], // col 1 — row7=coral(目標), row9=mint
    [_g, _t, _r, _g, _m, _t, _r, _m, _t, _c], // col 2 — row9=coral
  ];

  @override
  void initState() {
    super.initState();
    final tutorial = context.read<TutorialProvider>();
    _step = tutorial.currentStep;

    // ─── 向下相容：舊版 Part A step > 3 但 < 4（舊版 12 步），直接進首頁 ───
    if (_step > 3 && _step < 4) {
      _step = 3;
      _doorOpened = true;
    }
    // 舊版 steps 4-11 對應舊 Part A 的中後段，也跳到首頁
    if (_step >= 4 && _step < 12) {
      _doorOpened = true;
      _showHomeScreen = true;
      _homeTutorialStep = 0;
      _restoreHomeTutorialState();
      return;
    }

    if (_step > 0) _doorOpened = true;

    // 新版 Part B（step >= 4，對應 homeTutorialStep = step - 4）
    if (_step >= 4) {
      _showHomeScreen = true;
      _homeTutorialStep = (_step - 4).clamp(0, 2);
      _restoreHomeTutorialState();
    }

    if (_step >= 1 && _step <= 2) {
      _waitingForAction = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startGame();
      });
    }
  }

  /// 恢復 Part B 首頁教學的中斷狀態
  void _restoreHomeTutorialState() {
    switch (_homeTutorialStep) {
      case -1:
        // 自由探索中，不做特殊處理
        break;
      case 0:
        _waitingForHomeTutorialAction = true;
      case 1:
        _waitingForHomeTutorialAction = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _ensureCanCraft();
        });
      case 2:
        _waitingForHomeTutorialAction = true;
        _showHomeTutorialDialogue = true;
    }
  }

  // ═══════════════════════════════════
  // Part A：基礎操作（4 步）
  // ═══════════════════════════════════

  void _startGame() {
    final game = context.read<GameProvider>();
    game.startGame(GameModes.idle, initialColors: _tutorialGrid);
    _lastActionCount = game.state?.actionCount ?? 0;
    _lastCombo = game.state?.combo ?? 0;
  }

  void _goToStep(int step) {
    if (_transitioning) return;
    context.read<TutorialProvider>().setStep(step);
    setState(() => _step = step);
  }

  void _onDoorTap() {
    if (_step == 0 && !_doorOpened) {
      HapticFeedback.mediumImpact();
      setState(() => _doorOpened = true);
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) {
          _startGame();
          _goToStep(1);
          setState(() => _waitingForAction = true);
        }
      });
    }
  }

  void _onActionDetected() {
    if (_transitioning) return;
    HapticFeedback.lightImpact();
    setState(() => _waitingForAction = false);
    switch (_step) {
      case 1:
        // 點擊完成 → 同一盤面，教下滑三連消
        _goToStep(2);
        _startWaiting();
      case 2:
        // 三連消完成 → 成功提示 → 進首頁
        _goToStep(3);
        _showFloatingHint('太棒了！基礎操作掌握了！', emoji: '🎉');
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) _enterHomeScreen();
        });
    }
  }

  void _startWaiting() {
    final game = context.read<GameProvider>();
    _lastActionCount = game.state?.actionCount ?? 0;
    _lastCombo = game.state?.combo ?? 0;
    setState(() => _waitingForAction = true);
  }

  String _waitingHint() {
    switch (_step) {
      case 1:
        return '👆 點擊方塊就能採集食材！';
      case 2:
        return '👇 把那個食材往下滑到底部！';
      default:
        return '👆 請在棋盤上操作';
    }
  }

  String? _gestureType() {
    switch (_step) {
      case 1:
        return 'tap';
      case 2:
        return 'down';
      default:
        return null;
    }
  }

  // ═══════════════════════════════════
  // Part B：首頁自由探索 + 條件觸發教學
  // ═══════════════════════════════════
  // homeTutorialStep:
  //   -1: 自由探索（等瓶子滿）
  //    0: 瓶子滿了 → 高亮一鍵兌換
  //    1: 兌換完 → 高亮製作甜點
  //    2: 製作完 → 高亮闖關 Tab

  void _enterHomeScreen() {
    _goToStep(4);
    setState(() {
      _showHomeScreen = true;
      _homeTutorialStep = -1; // 自由探索
    });
    _showFloatingHint('自由消除方塊，收集能量吧！', emoji: '✨');
  }

  /// 瓶子滿了（由 _HomeActionListener 偵測）
  void _onBottleFull() {
    if (_homeTutorialStep != -1) return;
    setState(() {
      _homeTutorialStep = 0;
      _waitingForHomeTutorialAction = true;
    });
    _showFloatingHint('瓶子滿了！點「一鍵兌換」獲得食材', emoji: '🧪');
  }

  void _onUserConverted() {
    if (_homeTutorialStep == 0 && !_hasConverted) {
      setState(() {
        _hasConverted = true;
        _waitingForHomeTutorialAction = false;
        _floatingHintText = null;
      });
      _ensureCanCraft();
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _goToStep(5);
          setState(() {
            _homeTutorialStep = 1;
            _waitingForHomeTutorialAction = true;
          });
          _showFloatingHint('有食材了！點「製作甜點」', emoji: '🧁');
        }
      });
    }
  }

  void _onUserCrafted() {
    if (_homeTutorialStep == 1 && !_hasCrafted) {
      setState(() {
        _hasCrafted = true;
        _waitingForHomeTutorialAction = false;
        _floatingHintText = null;
      });
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _goToStep(6);
          setState(() {
            _homeTutorialStep = 2;
            _waitingForHomeTutorialAction = true;
            _showHomeTutorialDialogue = true;
          });
        }
      });
    }
  }

  void _onUserTappedBattle() {
    _transitioning = true;
    context.read<TutorialProvider>().advancePhase();
  }

  /// 浮動提示輔助
  void _showFloatingHint(String text, {String? emoji, TutorialHintPosition position = TutorialHintPosition.bottom}) {
    setState(() {
      _floatingHintText = text;
      _floatingHintEmoji = emoji;
      _floatingHintPosition = position;
    });
  }

  /// 教學用：確保有食材可以製作甜點
  /// 直接補足「薄荷茶」所需的食材（最簡單的配方：mint_leaf x2 + milk x1）
  void _ensureCanCraft() {
    final player = context.read<PlayerProvider>();
    final crafting = context.read<CraftingProvider>();
    final canCraft = DessertDefinitions.all.any(
      (r) => crafting.canCraft(r.id, player.data),
    );
    if (!canCraft) {
      // 直接補薄荷茶的材料
      player.data.ingredients['mint_leaf'] =
          (player.data.ingredients['mint_leaf'] ?? 0) + 4;
      player.data.ingredients['milk'] =
          (player.data.ingredients['milk'] ?? 0) + 2;
      player.notifyAndSave();
    }
  }

  GlobalKey? _highlightKeyForStep() {
    switch (_homeTutorialStep) {
      case 0:  // 瓶子滿→高亮兌換
        return _highlightConvertButtonKey;
      case 1:  // 有食材→高亮製作
        return _highlightCraftButtonKey;
      case 2:  // 做完→高亮闖關
        return _highlightNavBarKey;
      default: // -1 自由探索，不高亮
        return null;
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

  // ═══════════════════════════════════
  // Build
  // ═══════════════════════════════════

  @override
  Widget build(BuildContext context) {
    if (_showHomeScreen) return _buildHomeScreenWithGuide();
    if (!_doorOpened) return _buildDoorScene();
    return _buildOperationTutorial();
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
          onTutorialNavTap: _homeTutorialStep == 2 ? _onUserTappedBattle : null,
          externalBottleAreaKey: _highlightBottleAreaKey,
          externalConvertButtonKey: _highlightConvertButtonKey,
          externalCraftButtonKey: _highlightCraftButtonKey,
          externalNavBarKey: _highlightNavBarKey,
        ),

        // 監聯瓶子滿、兌換、製作狀態
        _HomeActionListener(
          onBottleFull: _onBottleFull,
          onConverted: _onUserConverted,
          onCrafted: _onUserCrafted,
          listenBottleFull: _homeTutorialStep == -1,
          listenConvert: _homeTutorialStep == 0 && !_hasConverted,
          listenCraft: _homeTutorialStep == 1 && !_hasCrafted,
        ),

        // 高亮 overlay
        if (highlightKey != null)
          TutorialHighlightOverlay(
            highlightKey: highlightKey,
            passthrough: true,
          ),

        // 浮動提示（非阻斷）
        if (_floatingHintText != null && !_showHomeTutorialDialogue)
          TutorialFloatingHint(
            key: ValueKey('home_hint_$_homeTutorialStep'),
            text: _floatingHintText!,
            emoji: _floatingHintEmoji,
            position: _floatingHintPosition,
            displayDuration: const Duration(seconds: 30),
          ),

        // 阻斷對話框（只有最後一步：去闘關）
        if (_showHomeTutorialDialogue && _homeTutorialStep == 2)
          TutorialDialogueBox(
            dialogue: const TutorialDialogue(
              id: 'H06',
              speaker: Speakers.grandpa,
              content: '地下室好像有什麼動靜……\n去「闘關」看看吧！',
            ),
            onTap: () {
              setState(() => _showHomeTutorialDialogue = false);
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
              if (_step == 2) {
                // 三連消偵測（combo 從 0→1 即通過）
                if (game.state!.combo > _lastCombo) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted && _waitingForAction) _onActionDetected();
                  });
                }
              } else {
                // Step 1：點擊偵測
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
                // 手勢提示動畫
                if (_waitingForAction && _gestureType() != null)
                  TutorialGestureHint(gestureType: _gestureType()!),
                // 等待操作時的底部提示
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
                // 成功時的浮動提示（step 3）
                if (_step == 3 && _floatingHintText != null)
                  TutorialFloatingHint(
                    text: _floatingHintText!,
                    emoji: _floatingHintEmoji,
                    displayDuration: const Duration(seconds: 2),
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

/// 監聽瓶子滿、兌換、製作狀態
class _HomeActionListener extends StatefulWidget {
  final VoidCallback? onBottleFull;
  final VoidCallback onConverted;
  final VoidCallback onCrafted;
  final bool listenBottleFull;
  final bool listenConvert;
  final bool listenCraft;

  const _HomeActionListener({
    this.onBottleFull,
    required this.onConverted,
    required this.onCrafted,
    this.listenBottleFull = false,
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
    // 偵測瓶子滿
    if (widget.listenBottleFull) {
      return Consumer2<PlayerProvider, BottleProvider>(
        builder: (context, player, bottleProvider, _) {
          if (bottleProvider.isInitialized) {
            final hasAnyFull = BottleDefinitions.all.any(
              (def) => bottleProvider.getBottle(def.color).isFull,
            );
            if (hasAnyFull) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                widget.onBottleFull?.call();
              });
            }
          }
          return _buildPlayerListener(player);
        },
      );
    }
    return Consumer<PlayerProvider>(
      builder: (context, player, _) => _buildPlayerListener(player),
    );
  }

  Widget _buildPlayerListener(PlayerProvider player) {
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
  }
}
