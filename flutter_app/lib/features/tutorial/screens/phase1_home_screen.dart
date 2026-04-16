import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../config/game_modes.dart';
import '../../../config/theme.dart';
import '../../../core/models/block.dart';
import '../../../core/models/bottle_data.dart';
import '../../../core/widgets/paper_dialog.dart';
import '../../agents/providers/player_provider.dart';
import '../../game/providers/game_provider.dart';
import '../../game/widgets/game_board.dart';
import '../../idle/providers/bottle_provider.dart';
import '../../idle/screens/home_screen.dart';
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
  // 0: 高亮「收成！」+ 浮動提示 + 等用戶點擊收成
  // 1: 高亮底部導航「闖關」→ 阻斷對話 → 等用戶點擊 → 完成 Phase 1
  int _homeTutorialStep = 0;
  bool _showHomeTutorialDialogue = false; // 只有 step 1 用阻斷對話

  bool _waitingForHomeTutorialAction = false;
  bool _hasHarvested = false;

  // HomeScreen 的 GlobalKey
  final GlobalKey<State> _homeScreenKey = GlobalKey();

  // Part B 高亮用 GlobalKey
  final GlobalKey _highlightBottleAreaKey = GlobalKey();
  final GlobalKey _highlightHarvestButtonKey = GlobalKey();
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
      _homeTutorialStep = (_step - 4).clamp(0, 1);
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
        break;
      case 0:
        _waitingForHomeTutorialAction = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _ensureBottleFull();
        });
      case 1:
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
  //    0: 瓶子滿了 → 高亮「收成！」
  //    1: 收成完 → 高亮闖關 Tab

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
    _showFloatingHint('瓶子滿了！點「收成！」收穫甜點', emoji: '🧪');
  }

  /// 用戶按了收成按鈕（偵測金幣增加）
  void _onUserHarvested() {
    if (_homeTutorialStep == 0 && !_hasHarvested) {
      setState(() {
        _hasHarvested = true;
        _waitingForHomeTutorialAction = false;
        _floatingHintText = null;
      });
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _goToStep(5);
          setState(() {
            _homeTutorialStep = 1;
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

  /// 教學用：確保至少一個瓶子能量已滿
  void _ensureBottleFull() {
    final bottleProvider = context.read<BottleProvider>();
    final coralBottle = bottleProvider.getBottle(BlockColor.coral);
    if (!coralBottle.isFull) {
      coralBottle.currentEnergy = coralBottle.capacity;
      bottleProvider.addEnergyBatch({}); // 觸發 notifyListeners + save
    }
  }

  GlobalKey? _highlightKeyForStep() {
    switch (_homeTutorialStep) {
      case 0:  // 瓶子滿→高亮收成
        return _highlightHarvestButtonKey;
      case 1:  // 收成完→高亮闖關
        return _highlightNavBarKey;
      default: // -1 自由探索，不高亮
        return null;
    }
  }

  void _skipTutorial() {
    PaperConfirmDialog.show(
      context: context,
      title: '跳過教學？',
      content: '您可以稍後在設定中重新體驗教學。',
      cancelText: '繼續學習',
      confirmText: '跳過全部教學',
      isDestructive: true,
      onConfirm: () {
        context
            .read<TutorialProvider>()
            .skipEntireTutorial(context.read<PlayerProvider>());
      },
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
          onTutorialNavTap: _homeTutorialStep == 1 ? _onUserTappedBattle : null,
          externalBottleAreaKey: _highlightBottleAreaKey,
          externalConvertButtonKey: _highlightHarvestButtonKey,
          externalNavBarKey: _highlightNavBarKey,
        ),

        // 監聽瓶子滿、收成狀態
        _HomeActionListener(
          onBottleFull: _onBottleFull,
          onHarvested: _onUserHarvested,
          listenBottleFull: _homeTutorialStep == -1,
          listenHarvest: _homeTutorialStep == 0 && !_hasHarvested,
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
        if (_showHomeTutorialDialogue && _homeTutorialStep == 1)
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
                style: TextStyle(color: AppTheme.textSecondary, fontSize: AppTheme.fontBodyLg)),
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
                                  color: AppTheme.textSecondary, fontSize: AppTheme.fontBodyLg)),
                          const Spacer(),
                          TextButton(
                            onPressed: _skipTutorial,
                            child: const Text('跳過教學 →',
                                style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: AppTheme.fontBodyLg)),
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
                            child: GameBoard(
                              // Step 2：高亮 col 1 row 7 的 coral 方塊，引導向下滑
                              tutorialHintBlock: _step == 2
                                  ? (col: 1, row: 7)
                                  : null,
                            ),
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
                          fontSize: AppTheme.fontTitleMd,
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
          // 背景圖（麵包店門口）
          Positioned.fill(
            child: Image.asset(
              'assets/images/output/background/bg_ch1_shop.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFA1887F), Color(0xFF6D4C41)],
                  ),
                ),
              ),
            ),
          ),
          // Spotlight 暗角 + 發光大門 + 浮動手指
          _DoorSpotlightScene(
            isOpened: _doorOpened,
            onTap: _onDoorTap,
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
                    style: TextStyle(color: Colors.white70, fontSize: AppTheme.fontBodyLg)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 監聽瓶子滿、收成狀態
class _HomeActionListener extends StatefulWidget {
  final VoidCallback? onBottleFull;
  final VoidCallback onHarvested;
  final bool listenBottleFull;
  final bool listenHarvest;

  const _HomeActionListener({
    this.onBottleFull,
    required this.onHarvested,
    this.listenBottleFull = false,
    required this.listenHarvest,
  });

  @override
  State<_HomeActionListener> createState() => _HomeActionListenerState();
}

class _HomeActionListenerState extends State<_HomeActionListener> {
  int _lastGold = 0;

  @override
  void initState() {
    super.initState();
    final player = context.read<PlayerProvider>();
    _lastGold = player.data.gold;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<PlayerProvider, BottleProvider>(
      builder: (context, player, bottleProvider, _) {
        // 偵測瓶子滿
        if (widget.listenBottleFull && bottleProvider.isInitialized) {
          final hasAnyFull = BottleDefinitions.all.any(
            (def) => bottleProvider.getBottle(def.color).isFull,
          );
          if (hasAnyFull) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              widget.onBottleFull?.call();
            });
          }
        }

        // 偵測收成（金幣增加 = 已收成）
        if (widget.listenHarvest) {
          final currentGold = player.data.gold;
          if (currentGold > _lastGold) {
            _lastGold = currentGold;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              widget.onHarvested();
            });
          }
        }

        return const SizedBox.shrink();
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// 推門場景 — spotlight 暗角 + 發光大門 + 浮動手指提示
// ═══════════════════════════════════════════════════════════════

class _DoorSpotlightScene extends StatefulWidget {
  final bool isOpened;
  final VoidCallback onTap;

  const _DoorSpotlightScene({
    required this.isOpened,
    required this.onTap,
  });

  @override
  State<_DoorSpotlightScene> createState() => _DoorSpotlightSceneState();
}

class _DoorSpotlightSceneState extends State<_DoorSpotlightScene>
    with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late AnimationController _fingerCtrl;
  late AnimationController _openCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _fingerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _openCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    if (widget.isOpened) _openCtrl.value = 1.0;
  }

  @override
  void didUpdateWidget(covariant _DoorSpotlightScene old) {
    super.didUpdateWidget(old);
    if (widget.isOpened && !old.isOpened) {
      _openCtrl.forward(from: 0);
      _pulseCtrl.stop();
      _fingerCtrl.stop();
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _fingerCtrl.dispose();
    _openCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseCtrl, _fingerCtrl, _openCtrl]),
      builder: (context, _) {
        final pulseT = Curves.easeInOut.transform(_pulseCtrl.value);
        final openT = Curves.easeOutCubic.transform(_openCtrl.value);
        // 開門過程：spotlight 半徑放大、整層 fade out
        final spotlightRadius = 130.0 + openT * 600;
        final dimAlpha = (180 * (1 - openT * 0.9)).toInt();

        return Stack(
          fit: StackFit.expand,
          children: [
            // ── 1. Spotlight 暗角 ──
            IgnorePointer(
              child: CustomPaint(
                painter: _SpotlightPainter(
                  centerOffset: const Offset(0, -40),
                  radius: spotlightRadius,
                  dimColor: Colors.black.withAlpha(dimAlpha),
                ),
              ),
            ),
            // ── 2. 中央：發光大門 + 點擊區 ──
            if (openT < 0.95)
              Center(
                child: Transform.translate(
                  offset: const Offset(0, -40),
                  child: GestureDetector(
                    onTap: widget.isOpened ? null : widget.onTap,
                    behavior: HitTestBehavior.opaque,
                    child: SizedBox(
                      width: 200,
                      height: 240,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // 外光暈（pulse 中）
                          Container(
                            width: 180,
                            height: 180,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFFD43B)
                                      .withAlpha((100 + pulseT * 120).toInt()),
                                  blurRadius: 40 + pulseT * 30,
                                  spreadRadius: 8 + pulseT * 8,
                                ),
                              ],
                            ),
                          ),
                          // 大門 emoji（呼吸縮放）
                          Transform.scale(
                            scale: 1.0 + pulseT * 0.06 + openT * 0.4,
                            child: Opacity(
                              opacity: 1 - openT * 0.6,
                              child: Text(
                                widget.isOpened ? '🌟' : '🚪',
                                style: const TextStyle(fontSize: 96),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            // ── 3. 浮動手指 + 「點擊開門」提示 ──
            if (!widget.isOpened)
              Positioned(
                left: 0,
                right: 0,
                bottom: MediaQuery.of(context).size.height * 0.4 - 60,
                child: IgnorePointer(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Transform.translate(
                        offset: Offset(0, -10 * pulseT),
                        child: const Text('👆', style: TextStyle(fontSize: 36)),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(140),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFFFFD43B)
                                .withAlpha((150 + pulseT * 100).toInt()),
                            width: 1.2,
                          ),
                        ),
                        child: const Text(
                          '點擊開門',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: AppTheme.fontTitleMd,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Spotlight 暗角 painter — 整個畫面變暗，挖出中央徑向亮區
class _SpotlightPainter extends CustomPainter {
  final Offset centerOffset; // 相對於畫面中心的偏移
  final double radius;
  final Color dimColor;

  _SpotlightPainter({
    required this.centerOffset,
    required this.radius,
    required this.dimColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2) + centerOffset;
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    // 用 SaveLayer + dst-out 挖洞
    canvas.saveLayer(rect, Paint());
    // 整個畫面填暗色
    canvas.drawRect(rect, Paint()..color = dimColor);
    // 中央挖出徑向漸層（亮區）
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..blendMode = BlendMode.dstOut
        ..shader = RadialGradient(
          colors: [
            Colors.black,
            Colors.black.withAlpha(180),
            Colors.black.withAlpha(0),
          ],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SpotlightPainter old) =>
      old.radius != radius || old.dimColor != dimColor;
}
