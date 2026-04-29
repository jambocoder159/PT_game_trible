import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../config/image_assets.dart';
import '../../../config/cat_agent_data.dart';
import '../../../config/bottle_dessert_map.dart';
import '../../../config/theme.dart';
import '../../agents/providers/player_provider.dart';
import '../../agents/screens/agent_list_screen.dart';
import '../../backpack/screens/backpack_screen.dart';
import '../../quest/screens/stage_select_screen.dart';
import '../../shop/screens/shop_screen.dart';
import '../../daily/screens/daily_quest_screen.dart';
import '../../settings/screens/settings_screen.dart';
import '../../profile/screens/player_profile_screen.dart';
import '../../../core/models/block.dart';
import '../../../core/models/bottle_data.dart';
import '../../../core/models/production.dart';
import '../providers/idle_provider.dart';
import '../providers/bottle_provider.dart';
import '../providers/production_provider.dart';
import '../widgets/player_info_bar.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/idle_mini_game.dart';
import '../../../core/models/auto_eliminate_config.dart';
import '../../../core/services/audio_service.dart';
import '../widgets/auto_eliminate_settings.dart';
import '../widgets/workshop_detail_panel.dart';
import '../widgets/energy_orb_overlay.dart';
import '../widgets/home_guide_overlay.dart';
import '../../tutorial/widgets/tutorial_floating_hint.dart';
import '../providers/crafting_provider.dart';
import '../../../config/ingredient_data.dart';
import '../../../core/models/cat_agent.dart';

/// 首頁 — 放置型遊戲大廳
class HomeScreen extends StatefulWidget {
  /// 教學模式：跳過內建 HomeGuide，由外部 overlay 控制
  final bool tutorialMode;

  /// 教學模式下，攔截導航列點擊（僅闖關 Tab 回調）
  final VoidCallback? onTutorialNavTap;

  /// 起始 Tab（預設 2 = 放置頁）
  final int initialNavIndex;

  /// 外部 GlobalKey — 供高亮定位
  final GlobalKey? externalBottleAreaKey;
  final GlobalKey? externalConvertButtonKey;
  final GlobalKey? externalCraftButtonKey;
  final GlobalKey? externalNavBarKey;

  /// 教學高亮的 agent id（傳給 AgentListScreen）
  final String? tutorialHighlightAgentId;

  /// Tab 切換回調
  final ValueChanged<int>? onTabChanged;

  /// 教學用：自動消除 Switch 的 GlobalKey
  final GlobalKey? tutorialAutoSwitchKey;

  /// 教學用：元氣區域的 GlobalKey
  final GlobalKey? tutorialStaminaKey;

  const HomeScreen({
    super.key,
    this.tutorialMode = false,
    this.onTutorialNavTap,
    this.initialNavIndex = 2,
    this.externalBottleAreaKey,
    this.externalConvertButtonKey,
    this.externalCraftButtonKey,
    this.externalNavBarKey,
    this.tutorialHighlightAgentId,
    this.onTabChanged,
    this.tutorialAutoSwitchKey,
    this.tutorialStaminaKey,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _currentNavIndex;

  // 能量球動畫
  final EnergyOrbController _orbController = EnergyOrbController();

  // 技能 VFX 特效
  bool _showSkillVfx = false;
  AgentAttribute? _skillVfxAttribute;
  String? _skillVfxAgentName;

  // 演出區狀態：idle / serving。製作中維持 idle 舞台，不再展開演出框。
  String _stageMode = 'idle'; // 'idle' | 'serving'
  BlockColor? _stageColor;

  // 瓶子 GlobalKey（用於定位能量球目標位置）
  final Map<BlockColor, GlobalKey> _bottleKeys = {};

  // 遊戲區域 GlobalKey（用於定位能量球起點）
  final GlobalKey _gameAreaKey = GlobalKey();
  final GlobalKey _stageAreaKey = GlobalKey();
  final GlobalKey _displayCaseKey = GlobalKey();

  // 首頁導覽用 GlobalKey
  final GlobalKey _guideBottleAreaKey = GlobalKey();
  final GlobalKey _guideNavBarKey = GlobalKey();
  bool _showHomeGuide = false;
  bool _showStaminaHint = false;
  bool _hasDisplayCaseBaseline = false;
  Map<String, int> _displayCaseSnapshot = {};
  bool _autoCraftInFlight = false;
  bool _autoSellInFlight = false;

  @override
  void initState() {
    super.initState();
    _currentNavIndex = widget.initialNavIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startIdleGame();
      _setupEnergyListener();
      _setupProductionListener();
      _checkHomeGuide();
      _migrateIngredients();
      _playBgmForCurrentTab();
    });
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 教學模式下，外部可以透過 initialNavIndex 切換 Tab
    if (widget.tutorialMode && widget.initialNavIndex != _currentNavIndex) {
      setState(() => _currentNavIndex = widget.initialNavIndex);
      _playBgmForCurrentTab();
    }
  }

  /// 外部切換 Tab（教學模式用）
  void switchTab(int index) {
    if (index == _currentNavIndex) return;
    setState(() => _currentNavIndex = index);
    widget.onTabChanged?.call(index);
    _playBgmForCurrentTab();
  }

  void _playBgmForCurrentTab() {
    AudioService.instance.playBGM(AudioService.normalBgm);
  }

  void _startIdleGame() {
    final idle = context.read<IdleProvider>();

    // 載入自動消除設定 & 檢查階段解鎖
    idle.loadAutoConfig();
    final playerLevel = context.read<PlayerProvider>().data.playerLevel;
    idle.checkStageUnlock(playerLevel);

    if (idle.state == null) {
      idle.startIdleGame();
    }
    // 綁定每日任務消除計數
    idle.onBlocksEliminated = (count) {
      if (mounted) {
        context.read<PlayerProvider>().addBlocksEliminated(count);
      }
    };
    // 設定隊伍（技能系統用）
    final player = context.read<PlayerProvider>();
    final team = player.data.team;
    idle.setTeam(team);
  }

  /// 一次性遷移：舊版食材自動售出換金幣
  void _migrateIngredients() {
    if (widget.tutorialMode) return;
    final player = context.read<PlayerProvider>();
    if (!player.isInitialized || player.data.ingredientsMigrated) return;
    final crafting = context.read<CraftingProvider>();
    final income = crafting.migrateIngredients(player.data);
    if (income > 0) {
      player.notifyAndSave();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('系統更新：食材已自動售出，獲得 $income 🍬'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _checkHomeGuide() {
    if (widget.tutorialMode) return; // 教學模式由外部控制
    final player = context.read<PlayerProvider>();
    if (player.isInitialized && !player.data.homeGuideCompleted) {
      // 延遲一幀讓 UI 完全渲染後再顯示導覽
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) {
          setState(() => _showHomeGuide = true);
        }
      });
    }
    // 延遲教學：元氣系統提示
    if (player.isInitialized &&
        player.data.tutorialCompleted &&
        !player.data.shownFeatureHints.contains('staminaSystem')) {
      player.markFeatureHintShown('staminaSystem');
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) setState(() => _showStaminaHint = true);
      });
    }
  }

  void _onHomeGuideComplete() {
    context.read<PlayerProvider>().completeHomeGuide();
    setState(() => _showHomeGuide = false);
  }

  void _setupEnergyListener() {
    final idle = context.read<IdleProvider>();
    idle.addListener(_onIdleUpdate);
  }

  void _setupProductionListener() {
    final production = context.read<ProductionProvider>();
    production.addListener(_onProductionUpdate);
  }

  void _onIdleUpdate() {
    if (!mounted) return;

    final idle = context.read<IdleProvider>();

    // 偵測技能施放 → 觸發 VFX
    if (idle.lastSkillAttribute != null && !_showSkillVfx) {
      setState(() {
        _showSkillVfx = true;
        _skillVfxAttribute = idle.lastSkillAttribute;
        _skillVfxAgentName = idle.lastSkillAgentName;
      });
      idle.consumeSkillVfx();
    }

    final bottleProvider = context.read<BottleProvider>();
    final playerProvider = context.read<PlayerProvider>();

    if (!playerProvider.isInitialized || !bottleProvider.isInitialized) return;

    final events = idle.consumeEnergyEvents();
    if (events.isEmpty) return;

    // 為每個能量事件發射能量球（飛向瓶子）
    for (final event in events) {
      _spawnEnergyOrbs(event.energyByColor);
    }

    // 延遲一點讓能量球先飛，再填充瓶子
    Future.delayed(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      for (final event in events) {
        bottleProvider.addEnergyBatch(event.energyByColor);
      }
      _checkBottleFull(bottleProvider);
      _tryAutoProduction();
    });
  }

  /// 檢查瓶子狀態。滿瓶只代表容量已達上限，不再自動製作。
  void _checkBottleFull(BottleProvider bp) {
    if (_showHomeGuide || _currentNavIndex != 2) return;
  }

  /// 發射能量球：從遊戲區中心飛向對應顏色的瓶子
  void _spawnEnergyOrbs(Map<BlockColor, int> energyByColor) {
    final gameBox =
        _gameAreaKey.currentContext?.findRenderObject() as RenderBox?;
    if (gameBox == null) return;
    final gameCenter = gameBox.localToGlobal(
      Offset(gameBox.size.width / 2, gameBox.size.height / 2),
    );
    final combo = context.read<IdleProvider>().state?.combo ?? 0;
    final comboTier = combo >= 12
        ? 4
        : combo >= 8
            ? 3
            : combo >= 4
                ? 2
                : 1;

    for (final entry in energyByColor.entries) {
      final color = entry.key;

      final bottleKey = _bottleKeys[color];
      if (bottleKey == null) continue;

      final bottleBox =
          bottleKey.currentContext?.findRenderObject() as RenderBox?;
      if (bottleBox == null) continue;
      final bottleCenter = bottleBox.localToGlobal(
        Offset(bottleBox.size.width / 2, bottleBox.size.height / 2),
      );

      _orbController.spawnOrbs(
        color: color,
        start: gameCenter,
        end: bottleCenter,
        count: (entry.value + comboTier - 1).clamp(1, 8),
        intensity: comboTier,
      );
    }
  }

  void _onProductionUpdate() {
    if (!mounted || _currentNavIndex != 2) return;
    final production = context.read<ProductionProvider>();
    if (!production.isInitialized) return;

    final current = Map<String, int>.from(production.displayCase.desserts);
    if (!_hasDisplayCaseBaseline) {
      _displayCaseSnapshot = current;
      _hasDisplayCaseBaseline = true;
      final total = production.displayCase.totalCount;
      if (total > 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _showLoopToast('甜點堆疊 x$total 已在展示櫃');
          _tryAutoSell();
        });
      }
      return;
    }

    var addedCount = 0;
    for (final entry in current.entries) {
      final previous = _displayCaseSnapshot[entry.key] ?? 0;
      if (entry.value > previous) {
        final added = entry.value - previous;
        addedCount += added;
        _spawnDessertToDisplayCase(entry.key, added);
      }
    }
    _displayCaseSnapshot = current;
    if (addedCount > 0) {
      Future.delayed(const Duration(milliseconds: 700), () {
        if (mounted) _tryAutoSell();
      });
    }
    _tryAutoProduction();
  }

  void _spawnBottleToStageEnergy(BlockColor color) {
    final bottleBox =
        _bottleKeys[color]?.currentContext?.findRenderObject() as RenderBox?;
    final stageBox =
        _stageAreaKey.currentContext?.findRenderObject() as RenderBox?;
    if (bottleBox == null || stageBox == null) return;

    final start = bottleBox.localToGlobal(
      Offset(bottleBox.size.width / 2, bottleBox.size.height / 2),
    );
    final end = stageBox.localToGlobal(
      Offset(stageBox.size.width / 2, stageBox.size.height * 0.52),
    );
    _orbController.spawnOrbs(color: color, start: start, end: end, count: 2);
    _showLoopToast('能量送進廚房');
  }

  void _spawnDessertToDisplayCase(String dessertId, int count) {
    final recipe = DessertDefinitions.getById(dessertId);
    final stageBox =
        _stageAreaKey.currentContext?.findRenderObject() as RenderBox?;
    final caseBox =
        _displayCaseKey.currentContext?.findRenderObject() as RenderBox?;
    if (stageBox == null || caseBox == null) return;

    final start = stageBox.localToGlobal(
      Offset(stageBox.size.width / 2, stageBox.size.height * 0.45),
    );
    final end = caseBox.localToGlobal(
      Offset(caseBox.size.width * 0.22, caseBox.size.height / 2),
    );

    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _DessertToDisplayCaseOverlay(
        emoji: recipe?.emoji ?? '🧁',
        start: start,
        end: end,
        count: count,
        onComplete: () => entry.remove(),
      ),
    );
    overlay.insert(entry);
    _showLoopToast('${recipe?.name ?? '甜點'} 放進展示櫃');
  }

  void _showLoopToast(String message) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _LoopToastOverlay(
        message: message,
        onComplete: () => entry.remove(),
      ),
    );
    overlay.insert(entry);
  }

  bool get _isAutoProductionEnabled {
    final bp = context.read<BottleProvider>();
    final pp = context.read<PlayerProvider>();
    final unlocked = pp
            .data
            .stageProgress[AutoEliminateConfig.autoHarvestUnlockStage]
            ?.cleared ??
        false;
    return unlocked && bp.autoHarvestEnabled;
  }

  void _tryAutoProduction() {
    if (!mounted || _autoCraftInFlight || !_isAutoProductionEnabled) return;
    _autoCraftInFlight = true;
    Future.microtask(() async {
      try {
        if (!mounted) return;
        for (final def in BottleDefinitions.all) {
          final didStart = await _startProductionForBottle(
            def.color,
            automatic: true,
          );
          if (didStart) break;
        }
      } finally {
        _autoCraftInFlight = false;
      }
    });
  }

  void _tryAutoSell() {
    if (!mounted || _autoSellInFlight || !_isAutoProductionEnabled) return;
    final production = context.read<ProductionProvider>();
    if (!production.isInitialized || production.displayCase.totalCount <= 0) {
      return;
    }
    _autoSellInFlight = true;
    Future.delayed(const Duration(milliseconds: 450), () async {
      try {
        if (mounted) await _onHarvest(automatic: true);
      } finally {
        _autoSellInFlight = false;
      }
    });
  }

  @override
  void dispose() {
    try {
      context.read<IdleProvider>().removeListener(_onIdleUpdate);
    } catch (_) {}
    try {
      context.read<ProductionProvider>().removeListener(_onProductionUpdate);
    } catch (_) {}
    super.dispose();
  }

  void _onNavTap(int index) {
    // 教學模式：只允許闖關 Tab，並通知外部
    if (widget.tutorialMode) {
      if (index == 3 && widget.onTutorialNavTap != null) {
        widget.onTutorialNavTap!();
      }
      return;
    }
    if (index == _currentNavIndex) return;
    setState(() => _currentNavIndex = index);
    widget.onTabChanged?.call(index);
    _playBgmForCurrentTab();
  }

  void _showSettingsModal() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
  }

  void _showCareerStatsModal() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PlayerProfileScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          // ─── 固定底部導航列 ───
          bottomNavigationBar: SafeArea(
            top: false,
            child: KeyedSubtree(
              key: _guideNavBarKey,
              child: Consumer<PlayerProvider>(
                builder: (_, player, __) {
                  final badges = <int>{};
                  if (player.isInitialized) {
                    // 新手任務有可領取獎勵 → 闖關 Tab 紅點
                    player.refreshNewbieQuests();
                    final nq = player.data.newbieQuests;
                    final hasUnclaimedNewbie = nq.completedIds.any(
                      (id) => !nq.claimedIds.contains(id),
                    );
                    if (hasUnclaimedNewbie) badges.add(3);

                    // 每日任務有可領取 → 也在闖關 Tab（引導玩家進入任務中心）
                    final dq = player.data.dailyQuests;
                    if (!dq.needsReset &&
                        dq.allCompleted &&
                        !dq.rewardsClaimed) {
                      badges.add(3);
                    }
                  }
                  return GameBottomNavBar(
                    currentIndex: _currentNavIndex,
                    onTap: _showHomeGuide ? null : _onNavTap,
                    badges: badges,
                    highlightTabIndex:
                        widget.externalNavBarKey != null ? 3 : -1,
                    highlightTabKey: widget.externalNavBarKey,
                  );
                },
              ),
            ),
          ),
          body: IndexedStack(
            index: _currentNavIndex,
            children: [
              const BackpackScreen(), // 0: 背包
              AgentListScreen(
                tutorialHighlightAgentId: widget.tutorialHighlightAgentId,
              ), // 1: 角色
              _buildIdleContent(), // 2: 放置
              const StageSelectScreen(), // 3: 闖關
              const ShopScreen(), // 4: 商店
            ],
          ),
        ),

        // ─── 首頁導覽 Overlay ───
        if (_showHomeGuide)
          HomeGuideOverlay(
            steps: [
              HomeGuideStep(
                title: '🎮 這是你的採集棋盤！',
                description: '方塊會自動掉落，你可以點擊消除它們。\n'
                    '消除方塊會產生能量，餵養左邊的瓶子！',
                buttonText: '原來如此！',
                highlightKey: _gameAreaKey,
              ),
              HomeGuideStep(
                title: '🧪 能量瓶子系統',
                description: '5 個顏色的瓶子會收集對應的能量。\n'
                    '瓶子滿了就按「收成！」直接賣甜點賺錢！',
                buttonText: '了解！',
                highlightKey: _guideBottleAreaKey,
              ),
              const HomeGuideStep(
                title: '🔄 經營與冒險',
                description: '消除 → 收成賺錢 → 升級夥伴\n'
                    '→ 挑戰更難的關卡 → 解鎖更貴的甜點！\n\n'
                    '店鋪經營和地下室冒險，缺一不可！',
                buttonText: '我懂了！',
              ),
              HomeGuideStep(
                title: '⚔️ 去闖關吧！',
                description: '闖關可以解鎖新夥伴、獲得金幣和經驗！\n'
                    '先來挑戰第一關，看看你的實力！',
                buttonText: '出發闖關！',
                highlightKey: _guideNavBarKey,
              ),
            ],
            onComplete: _onHomeGuideComplete,
            onSwitchTab: (index) {
              setState(() => _currentNavIndex = index);
              _playBgmForCurrentTab();
            },
          ),

        // 延遲教學：元氣系統提示
        if (_showStaminaHint)
          TutorialFloatingHint(
            text: '探索地下室需要🔥元氣，會自動恢復的！',
            emoji: '💡',
            position: TutorialHintPosition.top,
            displayDuration: const Duration(seconds: 5),
            onDismissed: () {
              if (mounted) setState(() => _showStaminaHint = false);
            },
          ),
      ],
    );
  }

  Future<bool> _startProductionForBottle(
    BlockColor color, {
    bool automatic = false,
  }) async {
    final bp = context.read<BottleProvider>();
    final pp = context.read<PlayerProvider>();
    final production = context.read<ProductionProvider>();
    if (!pp.isInitialized || !bp.isInitialized || !production.isInitialized) {
      return false;
    }

    final bottle = bp.getBottle(color);
    final dessertId = bottle.currentDessertId ??
        BottleDessertMap.getBestForLevel(color, bottle.level)?.dessertId;
    final recipe =
        dessertId == null ? null : DessertDefinitions.getById(dessertId);
    if (dessertId == null || recipe == null) {
      if (!automatic) WorkshopDetailPanel.show(context, initialColor: color);
      return false;
    }

    final catId = production.firstIdleCat(pp.data.team);
    if (catId == null) {
      if (!automatic) _showProductionSnack('所有貓咪都在製作中');
      return false;
    }
    if (!bp.canProduce(color, dessertId)) {
      if (!automatic) WorkshopDetailPanel.show(context, initialColor: color);
      return false;
    }

    final catLevel =
        widget.tutorialMode ? 999 : (pp.data.agents[catId]?.level ?? 1);
    final didStart = await production.startProduction(
      catId: catId,
      dessertId: dessertId,
      sourceColor: color,
      catLevel: catLevel,
      bottleProvider: bp,
    );
    if (!mounted) return false;
    if (didStart) {
      if (!automatic) HapticFeedback.mediumImpact();
      final catName = _findAgentDef(catId)?.name ?? '貓咪';
      _spawnBottleToStageEnergy(color);
      if (automatic) {
        _showLoopToast('自動製作 ${recipe.emoji}');
      } else {
        _showProductionSnack('$catName 開始製作 ${recipe.emoji} ${recipe.name}');
      }
    }
    return didStart;
  }

  /// 手動售出展示櫃甜點。
  Future<void> _onHarvest({bool automatic = false}) async {
    final production = context.read<ProductionProvider>();
    final pp = context.read<PlayerProvider>();
    if (!production.isInitialized || production.displayCase.totalCount <= 0) {
      return;
    }
    final result = await production.sellAll(pp.data);
    if (!mounted || result.isEmpty) return;
    await pp.notifyAndSave();
    setState(() {
      _stageMode = 'idle';
      _stageColor = null;
    });
    _showHarvestAnimation(
        HarvestResult(
          dessertsProduced: result.dessertsSold,
          totalGold: result.totalGold,
          critBonusGold: result.critBonusGold,
        ),
        automatic: automatic);
  }

  void _showProductionSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 1)),
    );
  }

  /// 收成動畫：甜點圖示飛出 → 金幣數字放大
  void _showHarvestAnimation(HarvestResult result,
      {VoidCallback? onParticlesArrived, bool automatic = false}) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) {
        final dessertCount =
            result.dessertsProduced.values.fold(0, (a, b) => a + b);
        if (automatic) {
          return _SaleRewardChipOverlay(
            totalGold: result.totalGold,
            critBonusGold: result.critBonusGold,
            dessertCount: dessertCount,
            automatic: true,
            onParticlesArrived: onParticlesArrived,
            onComplete: () => entry.remove(),
          );
        }
        return _HarvestAnimationOverlay(
          totalGold: result.totalGold,
          critBonusGold: result.critBonusGold,
          dessertCount: dessertCount,
          onComplete: () => entry.remove(),
        );
      },
    );

    overlay.insert(entry);
  }

  /// 放置頁（首頁）內容
  Widget _buildIdleContent() {
    return SafeArea(
      bottom: false,
      child: Stack(
        children: [
          Column(
            children: [
              // ─── 頂部玩家資訊列 ───
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
                child: KeyedSubtree(
                  key: widget.tutorialStaminaKey ?? GlobalKey(),
                  child: PlayerInfoBar(
                    onSettings: _showSettingsModal,
                    onStats: _showCareerStatsModal,
                    onDailyQuest: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const DailyQuestScreen()),
                      );
                    },
                  ),
                ),
              ),

              // ─── 演出區（固定高度）+ 瓶子 ───
              _StageAndBottles(
                stageKey: _stageAreaKey,
                stageMode: _stageMode,
                stageColor: _stageColor,
                onHarvest: _onHarvest,
                externalHarvestButtonKey: widget.externalConvertButtonKey,
                externalCraftButtonKey: widget.externalCraftButtonKey,
                tutorialAutoSwitchKey: widget.tutorialAutoSwitchKey,
                tutorialMode: widget.tutorialMode,
                bottleKeys: _bottleKeys,
                bottleAreaKey:
                    widget.externalBottleAreaKey ?? _guideBottleAreaKey,
                onBottleTap: !widget.tutorialMode ||
                        widget.externalCraftButtonKey != null
                    ? _startProductionForBottle
                    : null,
              ),

              // ─── 棋盤 ───
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
                  child: IdleMiniGame(key: _gameAreaKey),
                ),
              ),
              if (!widget.tutorialMode)
                _DisplayCaseStrip(
                  key: _displayCaseKey,
                  onSellAll: _onHarvest,
                ),
            ],
          ),

          // ─── 左側快捷吊墜 ───
          if (!widget.tutorialMode)
            _SideCharm(
              onQuest: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const DailyQuestScreen()),
              ),
              onStats: _showCareerStatsModal,
              onSettings: _showSettingsModal,
              onShop: () => _onNavTap(4),
            ),

          // ─── 能量球飛行動畫覆蓋層 ───
          EnergyOrbOverlay(controller: _orbController),

          // ─── Combo 浮動動畫覆蓋層 ───
          _ComboOverlay(gameAreaKey: _gameAreaKey),

          // ─── 技能施放 VFX 覆蓋層 ───
          if (_showSkillVfx && _skillVfxAttribute != null)
            _SkillVfxOverlay(
              attribute: _skillVfxAttribute!,
              agentName: _skillVfxAgentName ?? '',
              onComplete: () {
                if (mounted) setState(() => _showSkillVfx = false);
              },
            ),
        ],
      ),
    );
  }
}

/// 技能施放 VFX 全屏覆蓋特效
class _SkillVfxOverlay extends StatefulWidget {
  final AgentAttribute attribute;
  final String agentName;
  final VoidCallback onComplete;

  const _SkillVfxOverlay({
    required this.attribute,
    required this.agentName,
    required this.onComplete,
  });

  @override
  State<_SkillVfxOverlay> createState() => _SkillVfxOverlayState();
}

class _SkillVfxOverlayState extends State<_SkillVfxOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _flashOpacity;
  late Animation<double> _vfxScale;
  late Animation<double> _vfxOpacity;
  late Animation<double> _textOpacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    // 閃光：0~20% 快閃
    _flashOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.5), weight: 10),
      TweenSequenceItem(tween: Tween(begin: 0.5, end: 0.0), weight: 20),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 70),
    ]).animate(_controller);

    // VFX 圖片：從小放大
    _vfxScale = Tween<double>(begin: 0.5, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    // VFX 透明度：先出現再消失
    _vfxOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 40),
    ]).animate(_controller);

    // 文字：稍晚出現
    _textOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 15),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(_controller);

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete();
      }
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _attrColor() {
    switch (widget.attribute) {
      case AgentAttribute.attributeA:
        return const Color(0xFFFF6B6B);
      case AgentAttribute.attributeB:
        return const Color(0xFF51CF66);
      case AgentAttribute.attributeC:
        return const Color(0xFF4DABF7);
      case AgentAttribute.attributeD:
        return const Color(0xFFFFD43B);
      case AgentAttribute.attributeE:
        return const Color(0xFFCC5DE8);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _attrColor();

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return IgnorePointer(
          child: Stack(
            children: [
              // 全屏閃光
              if (_flashOpacity.value > 0)
                Positioned.fill(
                  child: Opacity(
                    opacity: _flashOpacity.value,
                    child: Container(color: color),
                  ),
                ),

              // 中央 VFX 特效圖
              Center(
                child: Opacity(
                  opacity: _vfxOpacity.value,
                  child: Transform.scale(
                    scale: _vfxScale.value,
                    child: SizedBox(
                      width: 120,
                      height: 120,
                      child: Image.asset(
                        ImageAssets.skillVfx(widget.attribute),
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.auto_awesome,
                          color: color,
                          size: 64,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // 技能名稱文字
              Positioned(
                bottom: MediaQuery.of(context).size.height * 0.35,
                left: 0,
                right: 0,
                child: Opacity(
                  opacity: _textOpacity.value,
                  child: Text(
                    '${widget.agentName} 技能發動！',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: AppTheme.fontDisplayMd,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(color: color, blurRadius: 16),
                        Shadow(color: color, blurRadius: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════
// 5 色瓶子橫排
// ═══════════════════════════════════════════

class _HorizontalBottleStrip extends StatelessWidget {
  final Map<BlockColor, GlobalKey> bottleKeys;
  final void Function(BlockColor color)? onBottleTap;
  final GlobalKey? craftButtonKey;

  const _HorizontalBottleStrip({
    required this.bottleKeys,
    this.onBottleTap,
    this.craftButtonKey,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer2<BottleProvider, PlayerProvider>(
      builder: (context, bp, pp, _) {
        if (!bp.isInitialized) return const SizedBox.shrink();

        for (final def in BottleDefinitions.all) {
          bottleKeys.putIfAbsent(def.color, () => GlobalKey());
        }

        return Row(
          children: BottleDefinitions.all.map((def) {
            final bottle = bp.getBottle(def.color);
            final isFull = bottle.isFull;
            final dessertId = bottle.currentDessertId ??
                BottleDessertMap.getBestForLevel(def.color, bottle.level)
                    ?.dessertId;
            final canProduce =
                dessertId != null && bp.canProduce(def.color, dessertId);
            final canUpgrade = bp.canUpgrade(def.color, pp.data);
            final clr = def.color.color;

            final statusText = canProduce
                ? '可製作'
                : isFull
                    ? '已滿'
                    : '能量 ${bottle.currentEnergy}/${bottle.capacity}';

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: _wrapTutorialCraftKey(
                  def.color,
                  canProduce,
                  Tooltip(
                    message:
                        '${def.name} Lv${bottle.level}\n$statusText${canUpgrade ? '\n可升級' : ''}',
                    waitDuration: const Duration(milliseconds: 350),
                    child: Semantics(
                      button: onBottleTap != null,
                      label:
                          '${def.name}，等級 ${bottle.level}，$statusText${canUpgrade ? '，可升級' : ''}',
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: onBottleTap == null
                            ? null
                            : () {
                                HapticFeedback.lightImpact();
                                onBottleTap?.call(def.color);
                              },
                        child: KeyedSubtree(
                          key: bottleKeys[def.color]!,
                          child: _CompactBottleMeter(
                            emoji: def.emoji,
                            color: clr,
                            level: bottle.level,
                            progress: bottle.fillProgress,
                            isFull: isFull,
                            canProduce: canProduce,
                            canUpgrade: canUpgrade,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _wrapTutorialCraftKey(
      BlockColor color, bool canProduce, Widget child) {
    if (craftButtonKey == null || color != BlockColor.coral || !canProduce) {
      return child;
    }
    return KeyedSubtree(key: craftButtonKey, child: child);
  }
}

class _CompactBottleMeter extends StatefulWidget {
  final String emoji;
  final Color color;
  final int level;
  final double progress;
  final bool isFull;
  final bool canProduce;
  final bool canUpgrade;

  const _CompactBottleMeter({
    required this.emoji,
    required this.color,
    required this.level,
    required this.progress,
    required this.isFull,
    required this.canProduce,
    required this.canUpgrade,
  });

  @override
  State<_CompactBottleMeter> createState() => _CompactBottleMeterState();
}

class _CompactBottleMeterState extends State<_CompactBottleMeter>
    with SingleTickerProviderStateMixin {
  late AnimationController _impactCtrl;

  @override
  void initState() {
    super.initState();
    _impactCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
  }

  @override
  void didUpdateWidget(covariant _CompactBottleMeter oldWidget) {
    super.didUpdateWidget(oldWidget);
    final gainedEnergy = widget.progress > oldWidget.progress;
    final becameReady = widget.canProduce && !oldWidget.canProduce;
    if (gainedEnergy || becameReady) {
      _impactCtrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _impactCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.canProduce || widget.isFull;
    final tier = _bottleVisualTier(widget.level);
    final premium = tier >= 3;
    final legendary = tier >= 4;

    return AnimatedBuilder(
      animation: _impactCtrl,
      builder: (context, child) {
        final hit = math.sin(_impactCtrl.value * math.pi);
        return Transform.scale(
          scale: 1 + hit * 0.06,
          child: SizedBox(
            height: 42,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.bgCard.withAlpha(240),
                    Color.lerp(
                        AppTheme.bgCard, widget.color, 0.08 + tier * 0.035)!,
                  ],
                ),
                borderRadius: BorderRadius.circular(8 + tier * 0.8),
                border: Border.all(
                  color: active || premium
                      ? Color.lerp(widget.color, const Color(0xFFFFD43B),
                              premium ? 0.32 : 0.0)!
                          .withAlpha(210)
                      : widget.color.withAlpha(42),
                  width: active ? 1.4 + tier * 0.18 : 0.7 + tier * 0.12,
                ),
                boxShadow: active || hit > 0
                    ? [
                        BoxShadow(
                          color: widget.color
                              .withAlpha(active ? 44 + (hit * 28).round() : 32),
                          blurRadius: 6 + hit * 8 + tier * 2.2,
                        ),
                        if (premium)
                          BoxShadow(
                            color: const Color(0xFFFFD43B)
                                .withAlpha(20 + tier * 8),
                            blurRadius: 8 + tier * 2,
                          ),
                      ]
                    : null,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(7 + tier * 0.8),
                child: Stack(
                  children: [
                    if (premium)
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(7 + tier * 0.8),
                            border: Border.all(
                              color: Colors.white.withAlpha(80),
                              width: 0.7,
                            ),
                          ),
                        ),
                      ),
                    Positioned.fill(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: FractionallySizedBox(
                          widthFactor: 1,
                          heightFactor: widget.progress.clamp(0.0, 1.0),
                          alignment: Alignment.bottomCenter,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  widget.color.withAlpha(
                                      active ? 132 + tier * 12 : 78 + tier * 8),
                                  Color.lerp(widget.color, Colors.white,
                                          premium ? 0.24 : 0.08)!
                                      .withAlpha(active
                                          ? 62 + tier * 8
                                          : 32 + tier * 6),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (hit > 0)
                      Positioned.fill(
                        child: Opacity(
                          opacity: hit * 0.34,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(7),
                            ),
                          ),
                        ),
                      ),
                    Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (legendary)
                            Transform.rotate(
                              angle: math.sin(_impactCtrl.value * math.pi * 2) *
                                  0.2,
                              child: Icon(
                                Icons.auto_awesome_rounded,
                                size: 28,
                                color: const Color(0xFFFFD43B).withAlpha(95),
                              ),
                            ),
                          Text(
                            widget.emoji,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 17 + tier * 0.5,
                              height: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (tier >= 2)
                      Positioned(
                        left: 5,
                        top: 4,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(
                            tier - 1,
                            (index) => Container(
                              width: 3.5,
                              height: 3.5,
                              margin: const EdgeInsets.only(right: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFD43B)
                                    .withAlpha(170 + index * 18),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        const Color(0xFFFFD43B).withAlpha(55),
                                    blurRadius: 3,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (legendary)
                      Positioned(
                        left: 5,
                        right: 5,
                        top: 5,
                        child: Opacity(
                          opacity: 0.5 + hit * 0.3,
                          child: const Icon(Icons.star_rounded,
                              size: 9, color: Color(0xFFFFD43B)),
                        ),
                      ),
                    Positioned(
                      left: 5,
                      right: 5,
                      bottom: 4,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: widget.progress.clamp(0.0, 1.0),
                          minHeight: 3,
                          backgroundColor: AppTheme.textSecondary.withAlpha(18),
                          valueColor:
                              AlwaysStoppedAnimation<Color>(widget.color),
                        ),
                      ),
                    ),
                    if (widget.canProduce)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: _BottleStatusDot(
                          color: widget.color,
                          icon: Icons.restaurant_rounded,
                        ),
                      )
                    else if (widget.canUpgrade)
                      const Positioned(
                        top: 4,
                        right: 4,
                        child: _BottleStatusDot(
                          color: AppTheme.accentPrimary,
                          icon: Icons.arrow_upward_rounded,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  int _bottleVisualTier(int level) {
    if (level >= 9) return 4;
    if (level >= 6) return 3;
    if (level >= 3) return 2;
    return 1;
  }
}

class _BottleStatusDot extends StatelessWidget {
  final Color color;
  final IconData icon;

  const _BottleStatusDot({
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.bgCard, width: 1),
      ),
      child: Icon(icon, size: 9, color: Colors.white),
    );
  }
}

class _DessertToDisplayCaseOverlay extends StatefulWidget {
  final String emoji;
  final Offset start;
  final Offset end;
  final int count;
  final VoidCallback onComplete;

  const _DessertToDisplayCaseOverlay({
    required this.emoji,
    required this.start,
    required this.end,
    required this.count,
    required this.onComplete,
  });

  @override
  State<_DessertToDisplayCaseOverlay> createState() =>
      _DessertToDisplayCaseOverlayState();
}

class _DessertToDisplayCaseOverlayState
    extends State<_DessertToDisplayCaseOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 760),
    )..forward().whenComplete(widget.onComplete);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) {
          final t = Curves.easeInOutCubic.transform(_ctrl.value);
          final arc = math.sin(t * math.pi) * 42;
          final pos = Offset.lerp(widget.start, widget.end, t)!;
          final scale = 1.0 + math.sin(t * math.pi) * 0.24;
          final opacity = _ctrl.value > 0.86
              ? ((1 - _ctrl.value) / 0.14).clamp(0.0, 1.0)
              : 1.0;

          return Stack(
            children: [
              Positioned(
                left: pos.dx - 18,
                top: pos.dy - 18 - arc,
                child: Opacity(
                  opacity: opacity,
                  child: Transform.scale(
                    scale: scale,
                    child: Text(
                      widget.emoji,
                      style: const TextStyle(fontSize: 30),
                    ),
                  ),
                ),
              ),
              if (widget.count > 1 && t > 0.2)
                Positioned(
                  left: pos.dx + 8,
                  top: pos.dy - 28 - arc,
                  child: Opacity(
                    opacity: opacity,
                    child: Text(
                      'x${widget.count}',
                      style: TextStyle(
                        color: AppTheme.accentPrimary,
                        fontSize: AppTheme.fontLabelLg,
                        fontWeight: FontWeight.w900,
                        shadows: [
                          Shadow(
                            color: Colors.white.withAlpha(240),
                            blurRadius: 5,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _LoopToastOverlay extends StatefulWidget {
  final String message;
  final VoidCallback onComplete;

  const _LoopToastOverlay({
    required this.message,
    required this.onComplete,
  });

  @override
  State<_LoopToastOverlay> createState() => _LoopToastOverlayState();
}

class _LoopToastOverlayState extends State<_LoopToastOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1150),
    )..forward().whenComplete(widget.onComplete);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final safeTop = MediaQuery.of(context).padding.top;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final intro = Curves.easeOutCubic.transform(
          (_ctrl.value / 0.2).clamp(0.0, 1.0),
        );
        final outro = _ctrl.value > 0.72
            ? (1 - ((_ctrl.value - 0.72) / 0.28)).clamp(0.0, 1.0)
            : 1.0;
        return Positioned(
          top: safeTop + 72 - intro * 8,
          left: 0,
          right: 0,
          child: IgnorePointer(
            child: Opacity(
              opacity: intro * outro,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppTheme.textPrimary.withAlpha(220),
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(28),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Text(
                    widget.message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: AppTheme.fontLabelLg,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════
// 演出區 + 瓶子合體
// ═══════════════════════════════════════════

class _StageAndBottles extends StatelessWidget {
  final GlobalKey stageKey;
  final String stageMode;
  final BlockColor? stageColor;
  final VoidCallback onHarvest;
  final GlobalKey? externalHarvestButtonKey;
  final GlobalKey? externalCraftButtonKey;
  final GlobalKey? tutorialAutoSwitchKey;
  final bool tutorialMode;
  final Map<BlockColor, GlobalKey> bottleKeys;
  final GlobalKey bottleAreaKey;
  final void Function(BlockColor color)? onBottleTap;

  const _StageAndBottles({
    required this.stageKey,
    required this.stageMode,
    this.stageColor,
    required this.onHarvest,
    this.externalHarvestButtonKey,
    this.externalCraftButtonKey,
    this.tutorialAutoSwitchKey,
    this.tutorialMode = false,
    required this.bottleKeys,
    required this.bottleAreaKey,
    this.onBottleTap,
  });

  bool get _isExpanded => stageMode == 'serving';
  // 演出區固定高度 + 瓶子高度
  static const _stageHeight = 120.0;
  static const _bottleHeight = 46.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _stageHeight + _bottleHeight,
      child: Stack(
        children: [
          // 底層：瓶子（固定在底部）
          Positioned(
            left: 10,
            right: 10,
            bottom: 0,
            height: _bottleHeight,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: _isExpanded ? 0.0 : 1.0,
              child: KeyedSubtree(
                key: bottleAreaKey,
                child: _HorizontalBottleStrip(
                  bottleKeys: bottleKeys,
                  onBottleTap: onBottleTap,
                  craftButtonKey: externalCraftButtonKey,
                ),
              ),
            ),
          ),

          // 上層：演出區（製作中不展開，只在售出演出時覆蓋瓶子）
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 380),
              curve: Curves.easeInOutCubic,
              height: _isExpanded ? _stageHeight + _bottleHeight : _stageHeight,
              child: _StageArea(
                key: stageKey,
                stageMode: stageMode,
                stageColor: stageColor,
                onHarvest: onHarvest,
                externalHarvestButtonKey: externalHarvestButtonKey,
                tutorialAutoSwitchKey: tutorialAutoSwitchKey,
                tutorialMode: tutorialMode,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════
// 角色演出區 — idle / serving，製作狀態由 ProductionProvider 驅動
// ═══════════════════════════════════════════

class _StageArea extends StatelessWidget {
  final String stageMode; // 'idle' | 'serving'
  final BlockColor? stageColor;
  final VoidCallback onHarvest;
  final GlobalKey? externalHarvestButtonKey;
  final GlobalKey? tutorialAutoSwitchKey;
  final bool tutorialMode;

  const _StageArea({
    super.key,
    required this.stageMode,
    this.stageColor,
    required this.onHarvest,
    this.externalHarvestButtonKey,
    this.tutorialAutoSwitchKey,
    this.tutorialMode = false,
  });

  bool get _isExpanded => stageMode == 'serving';

  @override
  Widget build(BuildContext context) {
    return Consumer4<PlayerProvider, IdleProvider, BottleProvider,
        ProductionProvider>(
      builder: (context, pp, idle, bp, production, _) {
        if (!pp.isInitialized) return const SizedBox.shrink();
        final team = pp.data.team;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: _isExpanded
                  ? [const Color(0xFFFFE9C2), const Color(0xFFFFD79A)]
                  : [const Color(0xFFFFF1D6), AppTheme.bgSecondary],
            ),
            border: Border.all(color: AppTheme.accentSecondary.withAlpha(30)),
          ),
          child: Stack(
            children: [
              // 背景圖
              Positioned.fill(
                child: Opacity(
                  opacity: 0.4,
                  child: Image.asset(
                    ImageAssets.homeBackground,
                    fit: BoxFit.cover,
                    alignment: Alignment.bottomCenter,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),

              // 地面漸層
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 30,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        AppTheme.bgSecondary.withAlpha(200)
                      ],
                    ),
                  ),
                ),
              ),

              // ── idle：角色走動；製作中的角色維持在同一水平舞台製作 ──
              if (stageMode == 'idle' && team.isNotEmpty)
                Positioned.fill(
                  child: LayoutBuilder(
                    builder: (_, c) => Stack(
                      children: List.generate(team.length.clamp(0, 3), (i) {
                        final agentId = team[i];
                        final agentDef = _findAgentDef(agentId);
                        if (agentDef == null) return const SizedBox.shrink();
                        final instance = pp.data.agents[agentId];
                        final productionSlot =
                            _productionSlotForCat(production, agentId);
                        return _StageCharacter(
                          key: ValueKey(agentId),
                          agentId: agentId,
                          agentDef: agentDef,
                          evolutionStage: instance?.evolutionStage ?? 0,
                          index: i,
                          totalCharacters: team.length.clamp(1, 3),
                          stageWidth: c.maxWidth,
                          stageHeight: c.maxHeight,
                          productionSlot: productionSlot,
                          productionNow: production.now,
                        );
                      }),
                    ),
                  ),
                ),

              // ── serving：上菜動畫 ──
              if (stageMode == 'serving') _ServingScene(stageColor: stageColor),

              // ── 左上：廚房按鈕 ──
              if (stageMode == 'idle')
                Positioned(
                  left: 8,
                  top: 8,
                  child: _wrapWithKey(
                      externalHarvestButtonKey,
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => WorkshopDetailPanel.show(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(220),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: AppTheme.accentSecondary.withAlpha(40)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('🏠', style: TextStyle(fontSize: 14)),
                              SizedBox(width: 4),
                              Text(
                                '廚房',
                                style: TextStyle(
                                  fontSize: AppTheme.fontLabelLg,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )),
                ),

              // ── 右上：齒輪（自動設定） ──
              if (stageMode == 'idle')
                Positioned(
                  right: 8,
                  top: 8,
                  child: _buildGearButton(
                      context, idle, bp, tutorialAutoSwitchKey),
                ),

              if (stageMode == 'idle' &&
                  (bp.autoHarvestEnabled || idle.autoConfig.isAutoActive))
                Positioned(
                  right: 56,
                  top: 8,
                  child: IgnorePointer(
                    child: _AutoStatusPill(
                      autoCraft: bp.autoHarvestEnabled,
                      autoEliminate: idle.autoConfig.isAutoActive,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _wrapWithKey(GlobalKey? key, Widget child) {
    if (key == null) return child;
    return KeyedSubtree(key: key, child: child);
  }

  static Widget _buildGearButton(BuildContext context, IdleProvider idle,
      BottleProvider bp, GlobalKey? tutorialKey) {
    final config = idle.autoConfig;
    final progress = context.read<PlayerProvider>().data.stageProgress;
    final isHarvestUnlocked =
        progress[AutoEliminateConfig.autoHarvestUnlockStage]?.cleared ?? false;
    final isEliminateUnlocked =
        progress[AutoEliminateConfig.autoEliminateUnlockStage]?.cleared ??
            false;
    final hasAutoActive = (isHarvestUnlocked && bp.autoHarvestEnabled) ||
        (isEliminateUnlocked && config.isAutoActive);

    return KeyedSubtree(
      key: tutorialKey,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: AppTheme.bgSecondary,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (_) => const AutoEliminateSettings(),
          );
        },
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(232),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: AppTheme.accentSecondary.withAlpha(44)),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accentSecondary.withAlpha(28),
                    offset: const Offset(0, 3),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Center(
                      child: Icon(Icons.tune_rounded,
                          size: 18,
                          color: AppTheme.textSecondary.withAlpha(175))),
                  if (hasAutoActive)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                              color: Color(0xFF4CAF50),
                              shape: BoxShape.circle)),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AutoStatusPill extends StatelessWidget {
  final bool autoCraft;
  final bool autoEliminate;

  const _AutoStatusPill({
    required this.autoCraft,
    required this.autoEliminate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 7),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(218),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.accentSecondary.withAlpha(32)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (autoEliminate)
            Icon(Icons.auto_awesome_rounded,
                size: 13, color: AppTheme.accentPrimary.withAlpha(210)),
          if (autoEliminate && autoCraft) const SizedBox(width: 4),
          if (autoCraft)
            const Icon(Icons.local_dining_rounded,
                size: 13, color: Color(0xFF4CAF50)),
        ],
      ),
    );
  }
}

ProductionSlot? _productionSlotForCat(
    ProductionProvider production, String catId) {
  for (final slot in production.activeSlots) {
    if (slot.catId == catId) return slot;
  }
  return null;
}

class _DisplayCaseStrip extends StatelessWidget {
  final VoidCallback onSellAll;

  const _DisplayCaseStrip({super.key, required this.onSellAll});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ProductionProvider, BottleProvider>(
      builder: (context, production, bp, _) {
        if (!production.isInitialized) return const SizedBox(height: 50);
        final display = production.displayCase;
        final items = display.desserts.entries.toList();
        final ready = display.totalCount > 0;
        final autoSell = bp.autoHarvestEnabled;
        final estimatedGold = items.fold<int>(0, (sum, entry) {
          final recipe = DessertDefinitions.getById(entry.key);
          return sum + (recipe?.sellPrice ?? 0) * entry.value;
        });

        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          height: ready ? 54 : 32,
          margin: const EdgeInsets.fromLTRB(8, 0, 8, 4),
          padding: EdgeInsets.symmetric(
            horizontal: 10,
            vertical: ready ? 7 : 5,
          ),
          decoration: BoxDecoration(
            color: ready ? const Color(0xFFFFFCF2) : AppTheme.bgCard,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: Border.all(
              color: ready
                  ? AppTheme.accentPrimary.withAlpha(135)
                  : AppTheme.accentSecondary.withAlpha(35),
              width: ready ? 1.2 : 1,
            ),
            boxShadow: ready
                ? [
                    BoxShadow(
                      color: AppTheme.accentPrimary.withAlpha(28),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: ready ? 58 : 30,
                alignment: Alignment.centerLeft,
                child: ready
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            autoSell ? '自動售出' : '可售出',
                            style: const TextStyle(
                              color: AppTheme.accentPrimary,
                              fontSize: AppTheme.fontLabelLg,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${display.totalCount}/${display.maxCapacity}',
                            style: TextStyle(
                              color: AppTheme.textSecondary.withAlpha(145),
                              fontSize: AppTheme.fontLabelSm,
                              height: 1.1,
                            ),
                          ),
                        ],
                      )
                    : Icon(
                        Icons.storefront_rounded,
                        size: 17,
                        color: AppTheme.textSecondary.withAlpha(120),
                      ),
              ),
              if (ready) const SizedBox(width: 8),
              Expanded(
                child: items.isEmpty
                    ? Row(
                        children: [
                          Text(
                            '展示櫃待機',
                            style: TextStyle(
                              color: AppTheme.textSecondary.withAlpha(120),
                              fontSize: AppTheme.fontLabelLg,
                            ),
                          ),
                          if (autoSell) ...[
                            const SizedBox(width: 6),
                            const Icon(Icons.local_dining_rounded,
                                size: 13, color: Color(0xFF4CAF50)),
                          ],
                        ],
                      )
                    : ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 6),
                        itemBuilder: (context, index) {
                          final entry = items[index];
                          final recipe = DessertDefinitions.getById(entry.key);
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.bgSecondary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(recipe?.emoji ?? '🧁'),
                                const SizedBox(width: 3),
                                Text(
                                  'x${entry.value}',
                                  style: const TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: AppTheme.fontLabelLg,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              if (ready) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onSellAll,
                  child: Container(
                    height: 34,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppTheme.accentPrimary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (autoSell) ...[
                          const Icon(Icons.bolt_rounded,
                              size: 13, color: Colors.white),
                          const SizedBox(width: 3),
                        ],
                        Text(
                          estimatedGold > 0 ? '+$estimatedGold' : '售出',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: AppTheme.fontLabelLg,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

// ── 上菜場景 ──
class _ServingScene extends StatefulWidget {
  final BlockColor? stageColor;
  const _ServingScene({this.stageColor});

  @override
  State<_ServingScene> createState() => _ServingSceneState();
}

class _ServingSceneState extends State<_ServingScene>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _riseAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _riseAnim = Tween(begin: 0.0, end: -40.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _fadeAnim = Tween(begin: 1.0, end: 0.0).animate(
        CurvedAnimation(parent: _ctrl, curve: const Interval(0.5, 1.0)));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorDef = widget.stageColor != null
        ? BottleDefinitions.all.firstWhere((d) => d.color == widget.stageColor,
            orElse: () => BottleDefinitions.all.first)
        : BottleDefinitions.all.first;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Stack(
        children: [
          // 甜點上升
          Positioned(
            left: 0,
            right: 0,
            top: 60 + _riseAnim.value,
            child: Opacity(
              opacity: _fadeAnim.value,
              child: Center(
                  child: Text(colorDef.emoji,
                      style: const TextStyle(fontSize: 40))),
            ),
          ),
          // 金幣飛出
          Positioned(
            left: 0,
            right: 0,
            top: 80 + _riseAnim.value * 1.3,
            child: Opacity(
              opacity: _fadeAnim.value,
              child: const Center(
                  child: Text('🪙 +金幣',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFD4A017)))),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════
// 單個演出角色 — 狀態機：idle / walking / cooking
// ═══════════════════════════════════════════

class _StageCharacter extends StatefulWidget {
  final String agentId;
  final CatAgentDefinition agentDef;
  final int evolutionStage;
  final int index;
  final int totalCharacters;
  final double stageWidth;
  final double stageHeight;
  final ProductionSlot? productionSlot;
  final DateTime productionNow;

  const _StageCharacter({
    super.key,
    required this.agentId,
    required this.agentDef,
    required this.evolutionStage,
    required this.index,
    required this.totalCharacters,
    required this.stageWidth,
    required this.stageHeight,
    required this.productionSlot,
    required this.productionNow,
  });

  @override
  State<_StageCharacter> createState() => _StageCharacterState();
}

class _CharacterSpriteSet {
  final List<String> moveFrames;
  final List<String> cookFrames;
  final List<String> doneFrames;

  const _CharacterSpriteSet({
    required this.moveFrames,
    required this.cookFrames,
    required this.doneFrames,
  });
}

class _StageCharacterState extends State<_StageCharacter>
    with TickerProviderStateMixin {
  static const _charSize = 56.0;
  static const Map<String, _CharacterSpriteSet> _spriteSets = {
    'blaze': _CharacterSpriteSet(
      moveFrames: [
        'assets/images/output/characters/char_wheat_move_1.png',
        'assets/images/output/characters/char_wheat_move_2.png',
        'assets/images/output/characters/char_wheat_move_3.png',
        'assets/images/output/characters/char_wheat_move_4.png',
      ],
      cookFrames: [
        'assets/images/output/characters/char_wheat_cook_1.png',
        'assets/images/output/characters/char_wheat_cook_2.png',
        'assets/images/output/characters/char_wheat_cook_3.png',
        'assets/images/output/characters/char_wheat_cook_4.png',
      ],
      doneFrames: [
        'assets/images/output/characters/char_wheat_done_1.png',
        'assets/images/output/characters/char_wheat_done_2.png',
        'assets/images/output/characters/char_wheat_done_3.png',
        'assets/images/output/characters/char_wheat_done_4.png',
      ],
    ),
    'tide': _CharacterSpriteSet(
      moveFrames: [
        'assets/images/output/characters/char_dew_move_1.png',
        'assets/images/output/characters/char_dew_move_2.png',
        'assets/images/output/characters/char_dew_move_3.png',
        'assets/images/output/characters/char_dew_move_4.png',
      ],
      cookFrames: [
        'assets/images/output/characters/char_dew_cook_1.png',
        'assets/images/output/characters/char_dew_cook_2.png',
        'assets/images/output/characters/char_dew_cook_3.png',
        'assets/images/output/characters/char_dew_cook_4.png',
      ],
      doneFrames: [
        'assets/images/output/characters/char_dew_done_1.png',
        'assets/images/output/characters/char_dew_done_2.png',
        'assets/images/output/characters/char_dew_done_3.png',
        'assets/images/output/characters/char_dew_done_4.png',
      ],
    ),
  };

  late double _posX;
  bool _facingRight = true;
  bool _isWalking = false;

  // 呼吸動畫
  late AnimationController _breathCtrl;
  late Animation<double> _breathAnim;

  // 跳動動畫（cooking）
  late AnimationController _bounceCtrl;
  late Animation<double> _bounceAnim;

  // 走動 Timer
  Timer? _walkTimer;
  AnimationController? _regularMoveCtrl;
  AnimationController? _spriteFrameCtrl;
  AnimationController? _doneEffectCtrl;
  bool _showDoneEffect = false;
  String _doneLabel = '甜點 +1';
  final _rng = math.Random();

  bool get _isCooking => widget.productionSlot != null;
  double get _productionProgress =>
      widget.productionSlot?.progress(widget.productionNow) ?? 0.0;
  _CharacterSpriteSet? get _spriteSet => _spriteSets[widget.agentId];
  bool get _usesSpriteSet => _spriteSet != null;
  bool get _usesRegularHorizontalMotion =>
      _usesSpriteSet && !_isCooking && !_showDoneEffect;
  bool get _usesCookSprite => _usesSpriteSet && _isCooking;

  @override
  void initState() {
    super.initState();
    // 初始位置：依 index 均勻分布
    final segment = widget.stageWidth / (widget.totalCharacters + 1);
    _posX = segment * (widget.index + 1) - _charSize / 2;

    // 呼吸
    _breathCtrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 2400 + _rng.nextInt(400)),
    );
    _breathAnim = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(parent: _breathCtrl, curve: Curves.easeInOut),
    );
    _breathCtrl.repeat(reverse: true);

    // 跳動
    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _bounceAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -12), weight: 40),
      TweenSequenceItem(tween: Tween(begin: -12, end: 0), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0, end: -6), weight: 20),
      TweenSequenceItem(tween: Tween(begin: -6, end: 0), weight: 10),
    ]).animate(CurvedAnimation(parent: _bounceCtrl, curve: Curves.easeOut));

    if (_usesRegularHorizontalMotion) {
      _startRegularHorizontalMotion();
    } else if (_isCooking) {
      if (_usesCookSprite) {
        _startSpriteFrames();
      }
    } else {
      // 啟動隨機走動
      _scheduleNextWalk();
    }
  }

  @override
  void didUpdateWidget(_StageCharacter old) {
    super.didUpdateWidget(old);
    final wasCooking = old.productionSlot != null;
    final isCooking = _isCooking;
    if (isCooking && !wasCooking) {
      if (_regularMoveCtrl != null) {
        _posX = _xForRegularMotion(_regularMoveCtrl!.value);
        _facingRight = _regularMoveCtrl!.status != AnimationStatus.reverse;
      }
      _walkTimer?.cancel();
      _isWalking = false;
      _startCooking();
      _stopRegularHorizontalMotion(resetPosition: false);
      if (_usesCookSprite) {
        _startSpriteFrames();
      }
    } else if (!isCooking && wasCooking) {
      final recipe = DessertDefinitions.getById(old.productionSlot!.dessertId);
      _doneLabel = '${recipe?.name ?? '甜點'} +1';
      _stopRegularHorizontalMotion();
      if (_usesSpriteSet) {
        _startDoneEffect();
      } else {
        _scheduleNextWalk();
      }
    }
  }

  @override
  void dispose() {
    _walkTimer?.cancel();
    _regularMoveCtrl?.dispose();
    _spriteFrameCtrl?.dispose();
    _doneEffectCtrl?.dispose();
    _breathCtrl.dispose();
    _bounceCtrl.dispose();
    super.dispose();
  }

  void _scheduleNextWalk() {
    _walkTimer?.cancel();
    final delay = Duration(seconds: 3 + _rng.nextInt(5));
    _walkTimer = Timer(delay, _walkToRandomPosition);
  }

  void _walkToRandomPosition() {
    if (!mounted || _isCooking) {
      _scheduleNextWalk();
      return;
    }
    const margin = _charSize;
    final maxX = widget.stageWidth - margin;
    final targetX = margin / 2 + _rng.nextDouble() * (maxX - margin);

    setState(() {
      _facingRight = targetX > _posX;
      _posX = targetX;
      _isWalking = true;
    });

    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) setState(() => _isWalking = false);
      _scheduleNextWalk();
    });
  }

  void _startCooking() {
    _bounceCtrl.forward(from: 0);
  }

  void _startRegularHorizontalMotion({bool preservePosition = false}) {
    _regularMoveCtrl ??= AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5200),
    );
    if (preservePosition) {
      _regularMoveCtrl!.value = _regularValueForX(_posX);
    }
    _startSpriteFrames();
    if (!_regularMoveCtrl!.isAnimating) {
      _regularMoveCtrl!.repeat(reverse: true);
    }
  }

  void _startSpriteFrames() {
    _spriteFrameCtrl ??= AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 560),
    );
    if (!_spriteFrameCtrl!.isAnimating) {
      _spriteFrameCtrl!.repeat();
    }
  }

  void _stopRegularHorizontalMotion({bool resetPosition = true}) {
    _regularMoveCtrl?.stop();
    if (resetPosition) {
      _regularMoveCtrl?.reset();
    }
    _spriteFrameCtrl?.stop();
    _spriteFrameCtrl?.reset();
  }

  double _xForRegularMotion(double value) {
    final margin = math.min(24.0, widget.stageWidth * 0.08);
    final minX = margin;
    final maxX = math.max(minX, widget.stageWidth - _charSize - margin);
    final eased = Curves.easeInOut.transform(value);
    return minX + (maxX - minX) * eased;
  }

  double _regularValueForX(double x) {
    final margin = math.min(24.0, widget.stageWidth * 0.08);
    final minX = margin;
    final maxX = math.max(minX, widget.stageWidth - _charSize - margin);
    if (maxX <= minX) return 0.0;
    final target = ((x - minX) / (maxX - minX)).clamp(0.0, 1.0);
    var low = 0.0;
    var high = 1.0;
    for (var i = 0; i < 12; i++) {
      final mid = (low + high) / 2;
      if (Curves.easeInOut.transform(mid) < target) {
        low = mid;
      } else {
        high = mid;
      }
    }
    return (low + high) / 2;
  }

  void _startDoneEffect() {
    _doneEffectCtrl ??= AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    );
    _doneEffectCtrl!
      ..stop()
      ..reset();
    _showDoneEffect = true;
    _doneEffectCtrl!.forward().whenComplete(() {
      if (!mounted) return;
      setState(() => _showDoneEffect = false);
      _startRegularHorizontalMotion(preservePosition: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final groundY = widget.stageHeight - _charSize - widget.stageHeight * 0.12;

    if (_usesRegularHorizontalMotion) {
      final moveCtrl = _regularMoveCtrl!;
      final frameCtrl = _spriteFrameCtrl!;
      final moveFrames = _spriteSet!.moveFrames;

      return AnimatedBuilder(
        animation:
            Listenable.merge([moveCtrl, frameCtrl, _breathAnim, _bounceAnim]),
        builder: (_, __) {
          final x = _xForRegularMotion(moveCtrl.value);
          final frameIndex = math.min(
            moveFrames.length - 1,
            (frameCtrl.value * moveFrames.length).floor(),
          );
          final facingRight = moveCtrl.status != AnimationStatus.reverse;

          return Positioned(
            left: x,
            top: groundY,
            child: Transform.translate(
              offset: Offset(0, _bounceAnim.value),
              child: Transform.scale(
                scale: _breathAnim.value,
                child: Transform.flip(
                  flipX: !facingRight,
                  child: SizedBox(
                    width: _charSize,
                    height: _charSize,
                    child: Image.asset(
                      moveFrames[frameIndex],
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => _buildFallbackCharacter(),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
    }

    if (_usesCookSprite) {
      final frameCtrl = _spriteFrameCtrl!;
      final cookFrames = _spriteSet!.cookFrames;
      const ringPadding = 7.0;
      const ringSize = _charSize + ringPadding * 2;

      return AnimatedBuilder(
        animation: Listenable.merge([frameCtrl, _breathAnim, _bounceAnim]),
        builder: (_, __) {
          final frameIndex = math.min(
            cookFrames.length - 1,
            (frameCtrl.value * cookFrames.length).floor(),
          );
          final labelDy =
              -4.0 * math.sin(frameCtrl.value * math.pi * 2.0).abs();

          return Positioned(
            left: _posX - ringPadding - 24,
            top: groundY - ringPadding - 22,
            child: SizedBox(
              width: ringSize + 48,
              height: ringSize + 22,
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  Transform.translate(
                    offset: Offset(0, labelDy),
                    child: Text(
                      '製作中...',
                      maxLines: 1,
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: AppTheme.fontLabelLg,
                        height: 1.0,
                        fontWeight: FontWeight.w900,
                        shadows: [
                          Shadow(
                            color: Colors.white.withAlpha(230),
                            blurRadius: 5,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 24,
                    top: 22,
                    child: Transform.translate(
                      offset: Offset(0, _bounceAnim.value),
                      child: Transform.scale(
                        scale: _breathAnim.value,
                        child: SizedBox(
                          width: ringSize,
                          height: ringSize,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Positioned.fill(
                                child: CircularProgressIndicator(
                                  value: _productionProgress,
                                  strokeWidth: 3,
                                  backgroundColor: Colors.white.withAlpha(190),
                                  valueColor: AlwaysStoppedAnimation(
                                    AppTheme.accentPrimary.withAlpha(230),
                                  ),
                                ),
                              ),
                              Transform.flip(
                                flipX: !_facingRight,
                                child: SizedBox(
                                  width: _charSize,
                                  height: _charSize,
                                  child: Image.asset(
                                    cookFrames[frameIndex],
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) =>
                                        _buildFallbackCharacter(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    if (_showDoneEffect && _usesSpriteSet) {
      final doneCtrl = _doneEffectCtrl!;
      final doneFrames = _spriteSet!.doneFrames;

      return AnimatedBuilder(
        animation: Listenable.merge([doneCtrl, _breathAnim]),
        builder: (_, __) {
          final frameIndex = math.min(
            doneFrames.length - 1,
            (doneCtrl.value * doneFrames.length).floor(),
          );
          final labelCurve = Curves.easeOutCubic.transform(doneCtrl.value);
          final labelOpacity =
              (1.0 - Curves.easeIn.transform(doneCtrl.value)).clamp(0.0, 1.0);

          return Positioned(
            left: _posX - 36,
            top: groundY - 28,
            child: SizedBox(
              width: _charSize + 72,
              height: _charSize + 28,
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  Transform.translate(
                    offset: Offset(0, -18 * labelCurve),
                    child: Opacity(
                      opacity: labelOpacity,
                      child: Text(
                        _doneLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppTheme.accentPrimary,
                          fontSize: AppTheme.fontLabelLg,
                          height: 1.0,
                          fontWeight: FontWeight.w900,
                          shadows: [
                            Shadow(
                              color: Colors.white.withAlpha(240),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 28,
                    child: Transform.scale(
                      scale: _breathAnim.value,
                      child: Transform.flip(
                        flipX: !_facingRight,
                        child: SizedBox(
                          width: _charSize,
                          height: _charSize,
                          child: Image.asset(
                            doneFrames[frameIndex],
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) =>
                                _buildFallbackCharacter(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    if (_isCooking) {
      const ringPadding = 7.0;
      const ringSize = _charSize + ringPadding * 2;

      return AnimatedBuilder(
        animation: _breathAnim,
        builder: (_, __) {
          final labelDy =
              -4.0 * math.sin(_breathAnim.value * math.pi * 12.0).abs();

          return Positioned(
            left: _posX - ringPadding - 24,
            top: groundY - ringPadding - 22,
            child: SizedBox(
              width: ringSize + 48,
              height: ringSize + 22,
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  Transform.translate(
                    offset: Offset(0, labelDy),
                    child: Text(
                      '製作中...',
                      maxLines: 1,
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: AppTheme.fontLabelLg,
                        height: 1.0,
                        fontWeight: FontWeight.w900,
                        shadows: [
                          Shadow(
                            color: Colors.white.withAlpha(230),
                            blurRadius: 5,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 24,
                    top: 22,
                    child: Transform.translate(
                      offset: Offset(0, _bounceAnim.value),
                      child: Transform.scale(
                        scale: _breathAnim.value,
                        child: SizedBox(
                          width: ringSize,
                          height: ringSize,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Positioned.fill(
                                child: CircularProgressIndicator(
                                  value: _productionProgress,
                                  strokeWidth: 3,
                                  backgroundColor: Colors.white.withAlpha(190),
                                  valueColor: AlwaysStoppedAnimation(
                                    AppTheme.accentPrimary.withAlpha(230),
                                  ),
                                ),
                              ),
                              Transform.flip(
                                flipX: !_facingRight,
                                child: SizedBox(
                                  width: _charSize,
                                  height: _charSize,
                                  child: _buildFallbackCharacter(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    return AnimatedPositioned(
      duration: _isWalking
          ? const Duration(milliseconds: 2500)
          : const Duration(milliseconds: 100),
      curve: Curves.easeInOut,
      left: _posX,
      top: groundY,
      child: AnimatedBuilder(
        animation: Listenable.merge([_breathAnim, _bounceAnim]),
        builder: (_, child) {
          return Transform.translate(
            offset: Offset(0, _bounceAnim.value),
            child: Transform.scale(
              scale: _breathAnim.value,
              child: child,
            ),
          );
        },
        child: Transform.flip(
          flipX: !_facingRight,
          child: SizedBox(
            width: _charSize,
            height: _charSize,
            child: _buildFallbackCharacter(),
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackCharacter() {
    return Image.asset(
      ImageAssets.characterImage(widget.agentId,
              evolutionStage: widget.evolutionStage) ??
          '',
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Center(
        child: Text(
          widget.agentDef.attribute.emoji,
          style: const TextStyle(fontSize: 28),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════
// 左側快捷吊墜 — 可展開的浮動按鈕群
// ═══════════════════════════════════════════

class _SideCharm extends StatefulWidget {
  final VoidCallback onQuest;
  final VoidCallback onStats;
  final VoidCallback onSettings;
  final VoidCallback onShop;

  const _SideCharm({
    required this.onQuest,
    required this.onStats,
    required this.onSettings,
    required this.onShop,
  });

  @override
  State<_SideCharm> createState() => _SideCharmState();
}

class _SideCharmState extends State<_SideCharm>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late AnimationController _ctrl;
  late Animation<double> _expandAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _expandAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggle() {
    HapticFeedback.lightImpact();
    setState(() => _expanded = !_expanded);
    if (_expanded) {
      _ctrl.forward();
    } else {
      _ctrl.reverse();
    }
  }

  void _tapItem(VoidCallback action) {
    _toggle();
    action();
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top + 56;

    return Positioned(
      left: 0,
      top: topPad,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 展開的按鈕列
          AnimatedBuilder(
            animation: _expandAnim,
            builder: (_, __) {
              return ClipRect(
                child: Align(
                  alignment: Alignment.topLeft,
                  heightFactor: _expandAnim.value,
                  child: Opacity(
                    opacity: _expandAnim.value,
                    child: Container(
                      margin: const EdgeInsets.only(left: 4, bottom: 4),
                      padding: const EdgeInsets.symmetric(
                          vertical: 6, horizontal: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.bgCard.withAlpha(240),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppTheme.accentSecondary.withAlpha(40)),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withAlpha(20),
                              blurRadius: 8,
                              offset: const Offset(2, 2))
                        ],
                      ),
                      child: Consumer<PlayerProvider>(
                        builder: (context, pp, _) {
                          final dq = pp.data.dailyQuests;
                          final nq = pp.data.newbieQuests;
                          final hasQuestReward = nq.completedIds
                                  .any((id) => !nq.claimedIds.contains(id)) ||
                              (!dq.needsReset &&
                                  dq.allCompleted &&
                                  !dq.rewardsClaimed);
                          return Column(
                            children: [
                              _charmItem(
                                  Icons.task_alt_rounded, '任務', widget.onQuest,
                                  badge: hasQuestReward),
                              const SizedBox(height: 6),
                              _charmItem(Icons.bar_chart_rounded, '統計',
                                  widget.onStats),
                              const SizedBox(height: 6),
                              _charmItem(Icons.shopping_bag_rounded, '商店',
                                  widget.onShop),
                              const SizedBox(height: 6),
                              _charmItem(Icons.settings_rounded, '設定',
                                  widget.onSettings),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // 吊墜觸發按鈕
          GestureDetector(
            onTap: _toggle,
            child: Container(
              margin: const EdgeInsets.only(left: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              decoration: BoxDecoration(
                color: _expanded
                    ? AppTheme.accentSecondary.withAlpha(200)
                    : AppTheme.bgCard.withAlpha(220),
                borderRadius:
                    const BorderRadius.horizontal(right: Radius.circular(16)),
                border:
                    Border.all(color: AppTheme.accentSecondary.withAlpha(60)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withAlpha(15),
                      blurRadius: 6,
                      offset: const Offset(2, 1))
                ],
              ),
              child: Icon(
                _expanded ? Icons.chevron_left_rounded : Icons.menu_rounded,
                size: 18,
                color: _expanded ? Colors.white : AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _charmItem(IconData icon, String label, VoidCallback onTap,
      {bool badge = false}) {
    return GestureDetector(
      onTap: () => _tapItem(onTap),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.bgSecondary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: AppTheme.accentSecondary),
              ),
              const SizedBox(height: 2),
              Text(label,
                  style: const TextStyle(
                      fontSize: AppTheme.fontLabelSm,
                      color: AppTheme.textSecondary)),
            ],
          ),
          if (badge)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppTheme.accentPrimary,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.bgCard, width: 1),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════
// 收成按鈕 — 4 態 + 脈衝 + 按壓縮放
// ═══════════════════════════════════════════

class _HarvestButton extends StatefulWidget {
  final BottleProvider bottleProvider;
  final VoidCallback onTap;

  const _HarvestButton({
    required this.bottleProvider,
    required this.onTap,
  });

  @override
  State<_HarvestButton> createState() => _HarvestButtonState();
}

class _HarvestButtonState extends State<_HarvestButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _glowAnim;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _glowAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bp = widget.bottleProvider;
    final harvestable = bp.getHarvestableCount();
    final fullCount = bp.getFullBottleCount();
    final nearestProgress = bp.getNearestProgress();
    final estimatedGold = bp.estimateHarvestGold();

    final bool isReady = harvestable > 0;
    final bool isRich = isReady && estimatedGold >= 100;

    // 脈衝控制
    if (isReady && !_pulseCtrl.isAnimating) {
      _pulseCtrl.repeat(reverse: true);
    } else if (!isReady && _pulseCtrl.isAnimating) {
      _pulseCtrl.stop();
      _pulseCtrl.value = 0;
    }

    // 4 態視覺
    final LinearGradient gradient;
    final Color textColor;

    if (isRich) {
      gradient =
          const LinearGradient(colors: [Color(0xFFFFD43B), Color(0xFFFCC419)]);
      textColor = const Color(0xFF7C5E10);
    } else if (isReady) {
      gradient =
          const LinearGradient(colors: [Color(0xFF6BAF5B), Color(0xFF4CAF50)]);
      textColor = Colors.white;
    } else {
      gradient =
          const LinearGradient(colors: [Color(0xFF4A5A48), Color(0xFF3E4E3C)]);
      textColor = Colors.white38;
    }

    return GestureDetector(
      onTapDown: isReady ? (_) => setState(() => _pressed = true) : null,
      onTapUp: isReady
          ? (_) {
              setState(() => _pressed = false);
              widget.onTap();
            }
          : null,
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedBuilder(
        animation: _glowAnim,
        builder: (context, _) {
          final glowAlpha = isReady ? (_glowAnim.value * 100).toInt() : 0;
          final glowColor = gradient.colors.first;

          return AnimatedScale(
            scale: _pressed ? 0.95 : 1.0,
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOut,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: glowAlpha > 0
                        ? [
                            BoxShadow(
                                color: glowColor.withAlpha(glowAlpha),
                                blurRadius: 12 + _glowAnim.value * 6,
                                spreadRadius: _glowAnim.value * 2)
                          ]
                        : null,
                  ),
                  child: isReady
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              isRich ? '💰 收成！' : '🧪 收成！',
                              style: TextStyle(
                                  color: textColor,
                                  fontSize: AppTheme.fontBodyLg,
                                  fontWeight: FontWeight.bold),
                            ),
                            if (isRich) ...[
                              const SizedBox(width: 6),
                              Text(
                                '+$estimatedGold🍬',
                                style: TextStyle(
                                    color: textColor.withAlpha(200),
                                    fontSize: AppTheme.fontLabelLg),
                              ),
                            ],
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                value: nearestProgress,
                                strokeWidth: 2,
                                backgroundColor: Colors.white.withAlpha(20),
                                valueColor: const AlwaysStoppedAnimation(
                                    Color(0xFF6BAF5B)),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${(nearestProgress * 100).toInt()}%',
                              style: TextStyle(
                                  color: textColor,
                                  fontSize: AppTheme.fontLabelLg),
                            ),
                          ],
                        ),
                ),
                // 徽章
                if (isReady && fullCount > 0)
                  Positioned(
                    top: -4,
                    right: 6,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6B6B),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.bgCard, width: 1.5),
                      ),
                      child: Center(
                        child: Text('$fullCount',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: AppTheme.fontLabelSm,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════
// 收成動畫 — 開寶箱式結算 → 獎勵爆光 → 金幣飛向資源區
// ═══════════════════════════════════════════

class _SaleRewardChipOverlay extends StatefulWidget {
  final int totalGold;
  final int critBonusGold;
  final int dessertCount;
  final bool automatic;
  final VoidCallback? onParticlesArrived;
  final VoidCallback onComplete;

  const _SaleRewardChipOverlay({
    required this.totalGold,
    required this.critBonusGold,
    required this.dessertCount,
    required this.automatic,
    this.onParticlesArrived,
    required this.onComplete,
  });

  @override
  State<_SaleRewardChipOverlay> createState() => _SaleRewardChipOverlayState();
}

class _SaleRewardChipOverlayState extends State<_SaleRewardChipOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late List<_CandyParticle> _particles;
  bool _arrivedFired = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1350),
    );
    _particles = _generateParticles();
    _start();
  }

  List<_CandyParticle> _generateParticles() {
    final rng = math.Random();
    final count = widget.automatic ? 8 : 11;
    return List.generate(count, (i) {
      return _CandyParticle(
        emoji: i.isEven ? '🪙' : '🍬',
        angle: -math.pi / 2 + (rng.nextDouble() - 0.5) * 1.35,
        burstRadius: 28 + rng.nextDouble() * 54,
        delay: rng.nextDouble() * 0.1,
        size: 15 + rng.nextDouble() * 5,
      );
    });
  }

  Future<void> _start() async {
    if (!widget.automatic) HapticFeedback.mediumImpact();
    _ctrl.addListener(_checkArrival);
    await _ctrl.forward();
    if (!mounted) return;
    _fireArrived();
    widget.onComplete();
  }

  void _checkArrival() {
    if (_ctrl.value >= 0.78) _fireArrived();
  }

  void _fireArrived() {
    if (_arrivedFired) return;
    _arrivedFired = true;
    _ctrl.removeListener(_checkArrival);
    widget.onParticlesArrived?.call();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final safeTop = MediaQuery.of(context).padding.top;
    final origin = Offset(screenSize.width / 2, screenSize.height - 92);
    final target = Offset(screenSize.width * 0.85, safeTop + 20);
    final isCrit = widget.critBonusGold > 0;

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          final t = _ctrl.value;
          final enter = Curves.easeOutBack.transform((t / 0.22).clamp(0, 1));
          final flyT =
              Curves.easeInCubic.transform(((t - 0.34) / 0.44).clamp(0, 1));
          final fade =
              t > 0.76 ? (1 - ((t - 0.76) / 0.24)).clamp(0.0, 1.0) : 1.0;
          final chipDy = -10 * enter - 10 * flyT;

          return Stack(
            children: [
              Positioned(
                left: 20,
                right: 20,
                bottom: 74 + chipDy,
                child: Opacity(
                  opacity: fade,
                  child: Transform.scale(
                    scale: 0.82 + enter * 0.18,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 9),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(242),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: (isCrit
                                    ? const Color(0xFFFFD43B)
                                    : AppTheme.accentPrimary)
                                .withAlpha(220),
                            width: 1.4,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.accentPrimary.withAlpha(35),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(widget.automatic ? '⚙️' : '💰'),
                            const SizedBox(width: 6),
                            Text(
                              '${widget.automatic ? '自動售出' : '售出'} +${widget.totalGold}',
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: AppTheme.fontBodyMd,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            if (widget.dessertCount > 0) ...[
                              const SizedBox(width: 6),
                              Text(
                                'x${widget.dessertCount}',
                                style: TextStyle(
                                  color: AppTheme.textSecondary.withAlpha(180),
                                  fontSize: AppTheme.fontLabelLg,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                            if (isCrit) ...[
                              const SizedBox(width: 6),
                              const Text(
                                'CRIT',
                                style: TextStyle(
                                  color: Color(0xFF7C5E10),
                                  fontSize: AppTheme.fontLabelLg,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              ..._particles.map((p) {
                final burstT = Curves.easeOutCubic.transform(
                  ((t - 0.12 - p.delay) / 0.24).clamp(0.0, 1.0),
                );
                final burst = Offset(
                  math.cos(p.angle) * p.burstRadius,
                  math.sin(p.angle) * p.burstRadius,
                );
                final pos = Offset.lerp(
                  origin + burst * burstT,
                  target,
                  flyT,
                )!;
                final arc = math.sin(flyT * math.pi) * 18;
                final alpha = burstT <= 0
                    ? 0.0
                    : ((1 - flyT * 0.75) * fade).clamp(0.0, 1.0);
                return Positioned(
                  left: pos.dx - p.size / 2,
                  top: pos.dy - p.size / 2 - arc,
                  child: Opacity(
                    opacity: alpha,
                    child: Text(p.emoji, style: TextStyle(fontSize: p.size)),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

class _HarvestAnimationOverlay extends StatefulWidget {
  final int totalGold;
  final int critBonusGold;
  final int dessertCount;
  final VoidCallback onComplete;

  const _HarvestAnimationOverlay({
    required this.totalGold,
    required this.critBonusGold,
    required this.dessertCount,
    required this.onComplete,
  });

  @override
  State<_HarvestAnimationOverlay> createState() =>
      _HarvestAnimationOverlayState();
}

class _HarvestAnimationOverlayState extends State<_HarvestAnimationOverlay>
    with TickerProviderStateMixin {
  late AnimationController _ctrl;

  late List<_CandyParticle> _particles;
  static const _particleCount = 18;
  static const _rewardEmojis = ['🍬', '🍭', '🧁', '🍪', '🍩', '🪙'];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _particles = _generateParticles();
    _startSequence();
  }

  List<_CandyParticle> _generateParticles() {
    final rng = math.Random();
    return List.generate(_particleCount, (i) {
      final angle =
          (i / _particleCount) * 2 * math.pi + rng.nextDouble() * 0.45;
      final isCoin = i % 3 == 0;
      return _CandyParticle(
        emoji: isCoin
            ? '🪙'
            : _rewardEmojis[rng.nextInt(_rewardEmojis.length - 1)],
        angle: angle,
        burstRadius: 46 + rng.nextDouble() * 88,
        delay: rng.nextDouble() * 0.12,
        size: isCoin ? 20 + rng.nextDouble() * 6 : 18 + rng.nextDouble() * 7,
      );
    });
  }

  Future<void> _startSequence() async {
    HapticFeedback.heavyImpact();
    Future.delayed(const Duration(milliseconds: 420), () {
      if (mounted) HapticFeedback.mediumImpact();
    });
    Future.delayed(const Duration(milliseconds: 650), () {
      if (mounted) HapticFeedback.heavyImpact();
    });
    if (widget.critBonusGold > 0) {
      Future.delayed(const Duration(milliseconds: 880), () {
        if (mounted) HapticFeedback.heavyImpact();
      });
    }
    await _ctrl.forward();
    if (!mounted) return;
    if (mounted) widget.onComplete();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final safeTop = MediaQuery.of(context).padding.top;
    final isCrit = widget.critBonusGold > 0;

    final originX = screenSize.width * 0.5;
    final originY = screenSize.height - 150;
    // 目標位置：右上方資源區（金幣 🪙 位置）
    final targetX = screenSize.width * 0.85;
    final targetY = safeTop + 20;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final t = _ctrl.value;
        final appearT = Curves.elasticOut.transform((t / 0.24).clamp(0.0, 1.0));
        final flashT = ((t - 0.34) / 0.22).clamp(0.0, 1.0);
        final rewardT =
            Curves.easeOutBack.transform(((t - 0.40) / 0.18).clamp(0.0, 1.0));
        final flyT =
            Curves.easeInCubic.transform(((t - 0.56) / 0.30).clamp(0.0, 1.0));
        final fadeOut =
            t > 0.84 ? (1 - ((t - 0.84) / 0.16)).clamp(0.0, 1.0) : 1.0;
        final servingFrame =
            (((t / 0.56).clamp(0.0, 1.0)) * 5).floor().clamp(0, 5) + 1;
        final backdropOpacity =
            (0.42 * (t / 0.16).clamp(0.0, 1.0) * fadeOut).clamp(0.0, 0.42);

        return IgnorePointer(
          child: Stack(
            children: [
              Positioned.fill(
                child: ColoredBox(
                  color:
                      Colors.black.withAlpha((255 * backdropOpacity).round()),
                ),
              ),
              if (flashT > 0 && flashT < 1)
                Positioned(
                  left: originX - 110 - flashT * 28,
                  top: originY - 118 - flashT * 28,
                  child: Opacity(
                    opacity: math.sin(flashT * math.pi) * 0.9,
                    child: Container(
                      width: 220 + flashT * 56,
                      height: 220 + flashT * 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.white.withAlpha(230),
                            const Color(0xFFFFD43B).withAlpha(120),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              Positioned(
                left: originX - 78,
                top: originY - 106,
                width: 156,
                child: Opacity(
                  opacity: fadeOut,
                  child: Transform.scale(
                    scale: 0.55 + appearT * 0.45,
                    child: Transform.rotate(
                      angle: math.sin(t * math.pi * 10) * 0.015 * (1 - t),
                      child: Image.asset(
                        'assets/images/output/vfx/serving_reward_reveal/serve-$servingFrame.png',
                        width: 156,
                        height: 156,
                        fit: BoxFit.contain,
                        gaplessPlayback: true,
                        errorBuilder: (_, __, ___) => const Text(
                          '🍰',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 80),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (rewardT > 0)
                Positioned(
                  left: 24,
                  right: 24,
                  top: originY - 176 - rewardT * 14,
                  child: Opacity(
                    opacity: rewardT * fadeOut,
                    child: Transform.scale(
                      scale: 0.72 + rewardT * 0.28,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            isCrit ? '驚喜加成！' : '售出成功！',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: const Color(0xFFFFF3BF),
                              fontSize: AppTheme.fontDisplayMd,
                              fontWeight: FontWeight.w900,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withAlpha(190),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(235),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: const Color(0xFFFFD43B).withAlpha(220),
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              '+${widget.totalGold} 金幣${isCrit ? '  暴擊 +${widget.critBonusGold}' : ''}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF7C5E10),
                                fontSize: AppTheme.fontBodyLg,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ..._particles.map((p) {
                final burstT = Curves.easeOutCubic.transform(
                  ((t - 0.32 - p.delay) / 0.24).clamp(0.0, 1.0),
                );
                final burstX = originX + math.cos(p.angle) * p.burstRadius;
                final burstY = originY - 28 + math.sin(p.angle) * p.burstRadius;

                final currentX = originX +
                    (burstX - originX) * burstT +
                    (targetX - burstX) * flyT;
                final currentY = originY -
                    28 +
                    (burstY - originY + 28) * burstT -
                    math.sin(burstT * math.pi) * 28 +
                    (targetY - burstY) * flyT;

                final alpha = burstT > 0
                    ? ((1.0 - flyT * 0.85) * fadeOut).clamp(0.0, 1.0)
                    : 0.0;
                final scale = (1.0 - flyT * 0.42) *
                    (0.75 + math.sin(burstT * math.pi) * 0.35);

                return Positioned(
                  left: currentX - p.size / 2,
                  top: currentY - p.size / 2,
                  child: Opacity(
                    opacity: alpha,
                    child: Transform.scale(
                      scale: scale,
                      child: Text(p.emoji, style: TextStyle(fontSize: p.size)),
                    ),
                  ),
                );
              }),
              if (isCrit && t > 0.48 && t < 0.78)
                Positioned(
                  left: originX + 36,
                  top: originY - 118,
                  child: Transform.rotate(
                    angle: -0.16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD43B),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: const Text(
                        'CRIT!',
                        style: TextStyle(
                          color: Color(0xFF7C5E10),
                          fontSize: AppTheme.fontLabelLg,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// 糖果粒子資料
class _CandyParticle {
  final String emoji;
  final double angle;
  final double burstRadius;
  final double delay;
  final double size;

  const _CandyParticle({
    required this.emoji,
    required this.angle,
    required this.burstRadius,
    required this.delay,
    required this.size,
  });
}

// ═══════════════════════════════════════════
// Combo 浮動動畫覆蓋層（不占版面高度）
// ═══════════════════════════════════════════

class _ComboOverlay extends StatefulWidget {
  final GlobalKey gameAreaKey;

  const _ComboOverlay({required this.gameAreaKey});

  @override
  State<_ComboOverlay> createState() => _ComboOverlayState();
}

class _ComboOverlayState extends State<_ComboOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _opacityAnim;
  int _lastCombo = 0;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.5, end: 1.3), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 60),
    ]).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _opacityAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 80),
    ]).animate(_animCtrl);
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _onComboChanged(int combo) {
    if (combo > 1 && combo != _lastCombo) {
      _animCtrl.forward(from: 0);
    }
    _lastCombo = combo;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<IdleProvider>(
      builder: (context, idle, _) {
        final combo = idle.state?.combo ?? 0;
        // 觸發動畫
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _onComboChanged(combo);
        });

        if (combo <= 1) return const SizedBox.shrink();

        // 定位到棋盤區域上方（使用全屏覆蓋 + 手動偏移）
        final gameBox =
            widget.gameAreaKey.currentContext?.findRenderObject() as RenderBox?;
        if (gameBox == null) return const SizedBox.shrink();
        final gamePos = gameBox.localToGlobal(Offset.zero);
        final gameCenterX = gamePos.dx + gameBox.size.width / 2;

        return IgnorePointer(
          child: Stack(
            children: [
              Positioned(
                left: gameCenterX - 80,
                top: gamePos.dy + 6,
                width: 160,
                child: Center(
                  child: AnimatedBuilder(
                    animation: _animCtrl,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _opacityAnim.value,
                        child: Transform.scale(
                          scale: _scaleAnim.value,
                          child: child,
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 5),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF6B6B), Color(0xFFFFAA5B)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF6B6B).withAlpha(120),
                            blurRadius: 12,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Text(
                        '${combo}x Combo!',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: AppTheme.fontTitleMd,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(color: Colors.black54, blurRadius: 4),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

CatAgentDefinition? _findAgentDef(String agentId) {
  for (final a in CatAgentData.allAgents) {
    if (a.id == agentId) return a;
  }
  return null;
}
