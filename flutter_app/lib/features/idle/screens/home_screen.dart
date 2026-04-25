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

  // 首頁導覽用 GlobalKey
  final GlobalKey _guideBottleAreaKey = GlobalKey();
  final GlobalKey _guideNavBarKey = GlobalKey();
  bool _showHomeGuide = false;
  bool _showStaminaHint = false;

  @override
  void initState() {
    super.initState();
    _currentNavIndex = widget.initialNavIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startIdleGame();
      _setupEnergyListener();
      _checkHomeGuide();
      _migrateIngredients();
    });
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 教學模式下，外部可以透過 initialNavIndex 切換 Tab
    if (widget.tutorialMode && widget.initialNavIndex != _currentNavIndex) {
      setState(() => _currentNavIndex = widget.initialNavIndex);
    }
  }

  /// 外部切換 Tab（教學模式用）
  void switchTab(int index) {
    if (index == _currentNavIndex) return;
    setState(() => _currentNavIndex = index);
    widget.onTabChanged?.call(index);
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
        count: 1,
      );
    }
  }

  @override
  void dispose() {
    try {
      context.read<IdleProvider>().removeListener(_onIdleUpdate);
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

  Future<void> _startProductionForBottle(BlockColor color) async {
    if (widget.tutorialMode) return;
    final bp = context.read<BottleProvider>();
    final pp = context.read<PlayerProvider>();
    final production = context.read<ProductionProvider>();
    if (!pp.isInitialized || !bp.isInitialized || !production.isInitialized) {
      return;
    }

    final bottle = bp.getBottle(color);
    final dessertId = bottle.currentDessertId ??
        BottleDessertMap.getBestForLevel(color, bottle.level)?.dessertId;
    final recipe =
        dessertId == null ? null : DessertDefinitions.getById(dessertId);
    if (dessertId == null || recipe == null) {
      WorkshopDetailPanel.show(context, initialColor: color);
      return;
    }

    final catId = production.firstIdleCat(pp.data.team);
    if (catId == null) {
      _showProductionSnack('所有貓咪都在製作中');
      return;
    }
    if (!bp.canProduce(color, dessertId)) {
      WorkshopDetailPanel.show(context, initialColor: color);
      return;
    }

    final catLevel = pp.data.agents[catId]?.level ?? 1;
    final didStart = await production.startProduction(
      catId: catId,
      dessertId: dessertId,
      sourceColor: color,
      catLevel: catLevel,
      bottleProvider: bp,
    );
    if (!mounted) return;
    if (didStart) {
      HapticFeedback.mediumImpact();
      final catName = _findAgentDef(catId)?.name ?? '貓咪';
      _showProductionSnack('$catName 開始製作 ${recipe.emoji} ${recipe.name}');
    }
  }

  /// 手動售出展示櫃甜點。
  Future<void> _onHarvest() async {
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
    _showHarvestAnimation(HarvestResult(
      dessertsProduced: result.dessertsSold,
      totalGold: result.totalGold,
      critBonusGold: result.critBonusGold,
    ));
  }

  void _showProductionSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 1)),
    );
  }

  /// 收成動畫：甜點圖示飛出 → 金幣數字放大
  void _showHarvestAnimation(HarvestResult result,
      {VoidCallback? onParticlesArrived}) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => _HarvestAnimationOverlay(
        totalGold: result.totalGold,
        critBonusGold: result.critBonusGold,
        dessertCount: result.dessertsProduced.values.fold(0, (a, b) => a + b),
        onParticlesArrived: onParticlesArrived,
        onComplete: () => entry.remove(),
      ),
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
                stageMode: _stageMode,
                stageColor: _stageColor,
                onHarvest: _onHarvest,
                externalHarvestButtonKey: widget.externalConvertButtonKey,
                tutorialAutoSwitchKey: widget.tutorialAutoSwitchKey,
                tutorialMode: widget.tutorialMode,
                bottleKeys: _bottleKeys,
                bottleAreaKey:
                    widget.externalBottleAreaKey ?? _guideBottleAreaKey,
                onBottleTap:
                    widget.tutorialMode ? null : _startProductionForBottle,
              ),

              // ─── 棋盤 ───
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
                  child: IdleMiniGame(key: _gameAreaKey),
                ),
              ),
              if (!widget.tutorialMode)
                _DisplayCaseStrip(onSellAll: _onHarvest),
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

  const _HorizontalBottleStrip({
    required this.bottleKeys,
    this.onBottleTap,
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

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onBottleTap?.call(def.color);
                  },
                  child: KeyedSubtree(
                    key: bottleKeys[def.color]!,
                    child: Container(
                      height: 56,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: AppTheme.bgCard,
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusSmall),
                        border: Border.all(
                          color: canProduce
                              ? clr.withAlpha(210)
                              : isFull
                                  ? clr.withAlpha(180)
                                  : clr.withAlpha(30),
                          width: canProduce || isFull ? 1.5 : 0.5,
                        ),
                        boxShadow: canProduce || isFull
                            ? [
                                BoxShadow(
                                    color: clr.withAlpha(40), blurRadius: 6)
                              ]
                            : [
                                BoxShadow(
                                    color: Colors.black.withAlpha(6),
                                    blurRadius: 2)
                              ],
                      ),
                      child: Stack(
                        children: [
                          // 進度填充（底→頂）
                          Positioned.fill(
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: FractionallySizedBox(
                                widthFactor: 1.0,
                                heightFactor: bottle.fillProgress,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                      colors: [
                                        clr.withAlpha(isFull ? 140 : 65),
                                        clr.withAlpha(isFull ? 80 : 35),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // 內容：emoji + 數字
                          Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(def.emoji,
                                    style: const TextStyle(
                                        fontSize: AppTheme.fontTitleMd)),
                                const SizedBox(height: 2),
                                Text(
                                  canProduce
                                      ? '製作'
                                      : isFull
                                          ? '滿'
                                          : '${bottle.currentEnergy}',
                                  style: TextStyle(
                                    fontSize: AppTheme.fontLabelLg,
                                    fontWeight: FontWeight.bold,
                                    color: canProduce || isFull
                                        ? clr
                                        : AppTheme.textPrimary,
                                  ),
                                ),
                                Text(
                                  'Lv${bottle.level}',
                                  style: TextStyle(
                                    fontSize: AppTheme.fontLabelSm,
                                    color:
                                        AppTheme.textSecondary.withAlpha(140),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // 升級紅點
                          if (canUpgrade)
                            Positioned(
                              top: 2,
                              right: 2,
                              child: Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: AppTheme.accentPrimary,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: AppTheme.bgCard, width: 1),
                                ),
                              ),
                            ),
                        ],
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
}

// ═══════════════════════════════════════════
// 演出區 + 瓶子合體
// ═══════════════════════════════════════════

class _StageAndBottles extends StatelessWidget {
  final String stageMode;
  final BlockColor? stageColor;
  final VoidCallback onHarvest;
  final GlobalKey? externalHarvestButtonKey;
  final GlobalKey? tutorialAutoSwitchKey;
  final bool tutorialMode;
  final Map<BlockColor, GlobalKey> bottleKeys;
  final GlobalKey bottleAreaKey;
  final void Function(BlockColor color)? onBottleTap;

  const _StageAndBottles({
    required this.stageMode,
    this.stageColor,
    required this.onHarvest,
    this.externalHarvestButtonKey,
    this.tutorialAutoSwitchKey,
    this.tutorialMode = false,
    required this.bottleKeys,
    required this.bottleAreaKey,
    this.onBottleTap,
  });

  bool get _isExpanded => stageMode == 'serving';
  // 演出區固定高度 + 瓶子高度
  static const _stageHeight = 120.0;
  static const _bottleHeight = 60.0;

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
                        onTap: onHarvest,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(220),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: AppTheme.accentSecondary.withAlpha(40)),
                          ),
                          child: Consumer<ProductionProvider>(
                            builder: (_, production, __) {
                              final ready =
                                  production.displayCase.totalCount > 0;
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(ready ? '💰' : '🏠',
                                      style: const TextStyle(fontSize: 14)),
                                  const SizedBox(width: 4),
                                  Text(
                                    ready ? '售出' : '廚房',
                                    style: TextStyle(
                                      fontSize: AppTheme.fontLabelLg,
                                      fontWeight: FontWeight.w900,
                                      color: ready
                                          ? AppTheme.accentPrimary
                                          : AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              );
                            },
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
      key: tutorialKey ?? GlobalKey(),
      child: GestureDetector(
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
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(220),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.accentSecondary.withAlpha(40)),
          ),
          child: Stack(
            children: [
              Center(
                  child: Icon(Icons.tune_rounded,
                      size: 16, color: AppTheme.textSecondary.withAlpha(160))),
              if (hasAutoActive)
                Positioned(
                  top: 2,
                  right: 2,
                  child: Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                          color: Color(0xFF4CAF50), shape: BoxShape.circle)),
                ),
            ],
          ),
        ),
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

  const _DisplayCaseStrip({required this.onSellAll});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductionProvider>(
      builder: (context, production, _) {
        if (!production.isInitialized) return const SizedBox(height: 50);
        final display = production.displayCase;
        final items = display.desserts.entries.toList();

        return Container(
          height: 54,
          margin: const EdgeInsets.fromLTRB(8, 0, 8, 4),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: AppTheme.bgCard,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: Border.all(color: AppTheme.accentSecondary.withAlpha(35)),
          ),
          child: Row(
            children: [
              Text(
                '展示櫃 ${display.totalCount}/${display.maxCapacity}',
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: AppTheme.fontLabelLg,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: items.isEmpty
                    ? Text(
                        '完成的甜點會放在這裡',
                        style: TextStyle(
                          color: AppTheme.textSecondary.withAlpha(130),
                          fontSize: AppTheme.fontLabelLg,
                        ),
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
              const SizedBox(width: 8),
              GestureDetector(
                onTap: display.totalCount > 0 ? onSellAll : null,
                child: Container(
                  height: 34,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: display.totalCount > 0
                        ? AppTheme.accentPrimary
                        : AppTheme.bgSecondary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '售出',
                    style: TextStyle(
                      color: display.totalCount > 0
                          ? Colors.white
                          : AppTheme.textSecondary.withAlpha(120),
                      fontSize: AppTheme.fontLabelLg,
                      fontWeight: FontWeight.bold,
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
// 收成動畫 — 糖果粒子散開 → 飛向資源區 + 計數器跳動
// ═══════════════════════════════════════════

class _HarvestAnimationOverlay extends StatefulWidget {
  final int totalGold;
  final int critBonusGold;
  final int dessertCount;
  final VoidCallback? onParticlesArrived;
  final VoidCallback onComplete;

  const _HarvestAnimationOverlay({
    required this.totalGold,
    required this.critBonusGold,
    required this.dessertCount,
    this.onParticlesArrived,
    required this.onComplete,
  });

  @override
  State<_HarvestAnimationOverlay> createState() =>
      _HarvestAnimationOverlayState();
}

class _HarvestAnimationOverlayState extends State<_HarvestAnimationOverlay>
    with TickerProviderStateMixin {
  late AnimationController _burstCtrl; // 粒子散開
  late AnimationController _flyCtrl; // 粒子飛向資源區

  late List<_CandyParticle> _particles;
  static const _particleCount = 12;
  static const _candyEmojis = ['🍬', '🍭', '🧁', '🍪', '🍩'];

  @override
  void initState() {
    super.initState();

    // Phase 1: 粒子爆開 (600ms)
    _burstCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    // Phase 2: 粒子飛向右上角 (800ms)
    _flyCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _particles = _generateParticles();

    _startSequence();
  }

  List<_CandyParticle> _generateParticles() {
    final rng = math.Random();
    return List.generate(_particleCount, (i) {
      final angle = (i / _particleCount) * 2 * math.pi + rng.nextDouble() * 0.5;
      return _CandyParticle(
        emoji: _candyEmojis[rng.nextInt(_candyEmojis.length)],
        angle: angle,
        burstRadius: 40 + rng.nextDouble() * 60,
        delay: rng.nextDouble() * 0.15,
      );
    });
  }

  bool _arrivedFired = false;

  Future<void> _startSequence() async {
    HapticFeedback.heavyImpact();
    // Phase 1: 爆開
    await _burstCtrl.forward();
    if (!mounted) return;
    // Phase 2: 飛行 — 粒子到達錢幣區域時才觸發計數器
    _flyCtrl.addListener(_checkArrival);
    _flyCtrl.forward();
    if (widget.critBonusGold > 0) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) HapticFeedback.heavyImpact();
      });
    }
    await _flyCtrl.forward();
    if (!mounted) return;
    // 確保到達回呼一定觸發
    _fireArrived();
    // 短暫停留讓計數器跑完
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) widget.onComplete();
  }

  void _checkArrival() {
    // easeInCubic 在 85% 時間時粒子已視覺到達目標附近
    if (_flyCtrl.value >= 0.85) {
      _fireArrived();
    }
  }

  void _fireArrived() {
    if (_arrivedFired) return;
    _arrivedFired = true;
    _flyCtrl.removeListener(_checkArrival);
    widget.onParticlesArrived?.call();
  }

  @override
  void dispose() {
    _burstCtrl.dispose();
    _flyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final safeTop = MediaQuery.of(context).padding.top;
    final isCrit = widget.critBonusGold > 0;

    // 起始位置：左側面板中下方（收成按鈕附近）
    final originX = screenSize.width * 0.16;
    final originY = screenSize.height * 0.65;
    // 目標位置：右上方資源區（金幣 🪙 位置）
    final targetX = screenSize.width * 0.85;
    final targetY = safeTop + 20;

    return AnimatedBuilder(
      animation: Listenable.merge([_burstCtrl, _flyCtrl]),
      builder: (context, _) {
        return IgnorePointer(
          child: Stack(
            children: [
              // 糖果粒子
              ..._particles.map((p) {
                final burstT = (_burstCtrl.value - p.delay).clamp(0.0, 1.0) /
                    (1.0 - p.delay);
                final flyT = Curves.easeInCubic.transform(_flyCtrl.value);

                // Phase 1: 從中心爆開
                final burstX =
                    originX + math.cos(p.angle) * p.burstRadius * burstT;
                final burstY =
                    originY + math.sin(p.angle) * p.burstRadius * burstT;

                // Phase 2: 從爆開位置飛向目標
                final currentX = burstX + (targetX - burstX) * flyT;
                final currentY = burstY + (targetY - burstY) * flyT;

                // 透明度：爆開時漸入，飛行末段漸出
                final alpha =
                    burstT > 0 ? (1.0 - flyT * flyT).clamp(0.0, 1.0) : 0.0;
                // 縮放：飛行時逐漸縮小
                final scale = 1.0 - flyT * 0.6;

                return Positioned(
                  left: currentX - 12,
                  top: currentY - 12,
                  child: Opacity(
                    opacity: alpha,
                    child: Transform.scale(
                      scale: scale,
                      child: Text(p.emoji,
                          style:
                              const TextStyle(fontSize: AppTheme.fontTitleLg)),
                    ),
                  ),
                );
              }),

              // 暴擊提示（僅暴擊時短暫顯示）
              if (isCrit && _burstCtrl.value > 0.3 && _flyCtrl.value < 0.8)
                Positioned(
                  left: originX - 40,
                  top: originY - 45,
                  width: 80,
                  child: Text(
                    '暴擊！✨',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: const Color(0xFFFFD43B),
                      fontSize: AppTheme.fontTitleMd,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                            color: Colors.black.withAlpha(200), blurRadius: 6)
                      ],
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

  const _CandyParticle({
    required this.emoji,
    required this.angle,
    required this.burstRadius,
    required this.delay,
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
