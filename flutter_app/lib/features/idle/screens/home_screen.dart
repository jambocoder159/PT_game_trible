import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../config/image_assets.dart';
import '../../../config/cat_agent_data.dart';
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
import '../providers/idle_provider.dart';
import '../providers/bottle_provider.dart';
import '../widgets/player_info_bar.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/idle_mini_game.dart';
import '../../../core/models/auto_eliminate_config.dart';
import '../widgets/auto_eliminate_settings.dart';
import '../widgets/crafting_panel.dart';
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

  // 演出區狀態：idle → making (3.5s) → serving (1.3s) → idle
  String _stageMode = 'idle'; // 'idle' | 'making' | 'serving'
  BlockColor? _stageColor; // 哪個瓶子觸發了 making

  // 瓶子 GlobalKey（用於定位能量球目標位置）
  final Map<BlockColor, GlobalKey> _bottleKeys = {};

  // 遊戲區域 GlobalKey（用於定位能量球起點）
  final GlobalKey _gameAreaKey = GlobalKey();

  // 首頁導覽用 GlobalKey
  final GlobalKey _guideBottleAreaKey = GlobalKey();
  final GlobalKey _guideNavBarKey = GlobalKey();
  bool _showHomeGuide = false;
  bool _showStaminaHint = false;

  // 瓶子滿提示節流（避免重複提醒）
  final Set<BlockColor> _notifiedFullBottles = {};

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

  /// 檢查瓶子是否滿了 → 觸發自動收成（如已啟用）
  void _checkBottleFull(BottleProvider bp) {
    if (_showHomeGuide || _currentNavIndex != 2) return;
    // 自動收成
    if (bp.autoHarvestEnabled && bp.getHarvestableCount() > 0) {
      _onHarvest();
    }
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
                    if (!dq.needsReset && dq.allCompleted && !dq.rewardsClaimed) {
                      badges.add(3);
                    }
                  }
                  return GameBottomNavBar(
                    currentIndex: _currentNavIndex,
                    onTap: _showHomeGuide ? null : _onNavTap,
                    badges: badges,
                    highlightTabIndex: widget.externalNavBarKey != null ? 3 : -1,
                    highlightTabKey: widget.externalNavBarKey,
                  );
                },
              ),
            ),
          ),
          body: IndexedStack(
            index: _currentNavIndex,
            children: [
              const BackpackScreen(),       // 0: 背包
              AgentListScreen(
                tutorialHighlightAgentId: widget.tutorialHighlightAgentId,
              ),                            // 1: 角色
              _buildIdleContent(),          // 2: 放置
              const StageSelectScreen(),    // 3: 闖關
              const ShopScreen(),           // 4: 商店
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

  /// 瓶子滿時觸發生產流程
  void _triggerMake(BlockColor color) {
    if (_stageMode != 'idle') return;
    setState(() {
      _stageMode = 'making';
      _stageColor = color;
    });
    // 3.5s 後切換到 serving
    Future.delayed(const Duration(milliseconds: 3500), () {
      if (!mounted || _stageMode != 'making') return;
      // 收穫該瓶的能量
      final bp = context.read<BottleProvider>();
      final pp = context.read<PlayerProvider>();
      bp.harvest(pp.data);
      pp.notifyAndSave();
      setState(() => _stageMode = 'serving');
      // 1.3s 後回到 idle
      Future.delayed(const Duration(milliseconds: 1300), () {
        if (mounted) setState(() { _stageMode = 'idle'; _stageColor = null; });
      });
    });
  }

  /// 手動收成（收成按鈕 / 演出區內按鈕）
  void _onHarvest() {
    if (_stageMode != 'idle') return;
    final bp = context.read<BottleProvider>();
    if (bp.getHarvestableCount() <= 0) return;
    // 找到第一個有能量的瓶子觸發 making
    for (final def in BottleDefinitions.all) {
      final bottle = bp.getBottle(def.color);
      if (bottle.currentEnergy > 0) {
        _triggerMake(def.color);
        return;
      }
    }
  }

  /// 收成動畫：甜點圖示飛出 → 金幣數字放大
  void _showHarvestAnimation(HarvestResult result, {VoidCallback? onParticlesArrived}) {
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
                        MaterialPageRoute(builder: (_) => const DailyQuestScreen()),
                      );
                    },
                  ),
                ),
              ),

              // ─── 演出區（高度隨狀態變化） ───
              _StageArea(
                stageMode: _stageMode,
                stageColor: _stageColor,
                onHarvest: _onHarvest,
                externalHarvestButtonKey: widget.externalConvertButtonKey,
                tutorialAutoSwitchKey: widget.tutorialAutoSwitchKey,
                tutorialMode: widget.tutorialMode,
              ),

              // ─── 5 色瓶子橫排 ───
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 4, 10, 4),
                child: KeyedSubtree(
                  key: widget.externalBottleAreaKey ?? _guideBottleAreaKey,
                  child: _HorizontalBottleStrip(
                    bottleKeys: _bottleKeys,
                    onBottleTap: widget.tutorialMode ? null : () => WorkshopDetailPanel.show(context),
                    onBottleFull: _triggerMake,
                  ),
                ),
              ),

              // ─── 棋盤 ───
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
                  child: IdleMiniGame(key: _gameAreaKey),
                ),
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
  final VoidCallback? onBottleTap;
  final void Function(BlockColor color)? onBottleFull;

  const _HorizontalBottleStrip({
    required this.bottleKeys,
    this.onBottleTap,
    this.onBottleFull,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer2<BottleProvider, PlayerProvider>(
      builder: (context, bp, pp, _) {
        if (!bp.isInitialized) return const SizedBox.shrink();

        for (final def in BottleDefinitions.all) {
          bottleKeys.putIfAbsent(def.color, () => GlobalKey());
        }

        // 檢查是否有瓶子剛滿，觸發 making
        if (onBottleFull != null) {
          for (final def in BottleDefinitions.all) {
            if (bp.getBottle(def.color).isFull) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                onBottleFull!(def.color);
              });
              break;
            }
          }
        }

        return Row(
          children: BottleDefinitions.all.map((def) {
            final bottle = bp.getBottle(def.color);
            final isFull = bottle.isFull;
            final canUpgrade = bp.canUpgrade(def.color, pp.data);
            final clr = def.color.color;

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: GestureDetector(
                  onTap: onBottleTap,
                  child: KeyedSubtree(
                    key: bottleKeys[def.color]!,
                    child: Container(
                      height: 56,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: AppTheme.bgCard,
                        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                        border: Border.all(
                          color: isFull ? clr.withAlpha(180) : clr.withAlpha(30),
                          width: isFull ? 1.5 : 0.5,
                        ),
                        boxShadow: isFull
                            ? [BoxShadow(color: clr.withAlpha(40), blurRadius: 6)]
                            : [BoxShadow(color: Colors.black.withAlpha(6), blurRadius: 2)],
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
                                Text(def.emoji, style: const TextStyle(fontSize: AppTheme.fontTitleMd)),
                                const SizedBox(height: 2),
                                Text(
                                  isFull ? '✓' : '${bottle.currentEnergy}',
                                  style: TextStyle(
                                    fontSize: AppTheme.fontLabelLg,
                                    fontWeight: FontWeight.bold,
                                    color: isFull ? clr : AppTheme.textPrimary,
                                  ),
                                ),
                                Text(
                                  'Lv${bottle.level}',
                                  style: TextStyle(
                                    fontSize: AppTheme.fontLabelSm,
                                    color: AppTheme.textSecondary.withAlpha(140),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // 升級紅點
                          if (canUpgrade)
                            Positioned(
                              top: 2, right: 2,
                              child: Container(
                                width: 7, height: 7,
                                decoration: BoxDecoration(
                                  color: AppTheme.accentPrimary,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppTheme.bgCard, width: 1),
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
// 角色演出區 — idle / making / serving 三態 + 高度動畫
// ═══════════════════════════════════════════

class _StageArea extends StatelessWidget {
  final String stageMode; // 'idle' | 'making' | 'serving'
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

  bool get _isExpanded => stageMode != 'idle';

  @override
  Widget build(BuildContext context) {
    return Consumer3<PlayerProvider, IdleProvider, BottleProvider>(
      builder: (context, pp, idle, bp, _) {
        if (!pp.isInitialized) return const SizedBox.shrink();
        final team = pp.data.team;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 380),
          curve: Curves.easeInOutCubic,
          height: _isExpanded ? 230 : 110,
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
                left: 0, right: 0, bottom: 0, height: 30,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, AppTheme.bgSecondary.withAlpha(200)],
                    ),
                  ),
                ),
              ),

              // ── idle：角色走動 ──
              if (stageMode == 'idle' && team.isNotEmpty)
                Positioned.fill(
                  child: LayoutBuilder(
                    builder: (_, c) => Stack(
                      children: List.generate(team.length.clamp(0, 3), (i) {
                        final agentId = team[i];
                        final agentDef = _findAgentDef(agentId);
                        if (agentDef == null) return const SizedBox.shrink();
                        final instance = pp.data.agents[agentId];
                        return _StageCharacter(
                          agentId: agentId,
                          agentDef: agentDef,
                          evolutionStage: instance?.evolutionStage ?? 0,
                          index: i,
                          totalCharacters: team.length.clamp(1, 3),
                          stageWidth: c.maxWidth,
                          stageHeight: c.maxHeight,
                          isCooking: false,
                        );
                      }),
                    ),
                  ),
                ),

              // ── making：烹飪動畫 ──
              if (stageMode == 'making')
                _MakingScene(team: team, stageColor: stageColor),

              // ── serving：上菜動畫 ──
              if (stageMode == 'serving')
                _ServingScene(stageColor: stageColor),

              // ── 左上：廚房按鈕 ──
              if (stageMode == 'idle')
                Positioned(
                  left: 8, top: 8,
                  child: _wrapWithKey(externalHarvestButtonKey, GestureDetector(
                    onTap: onHarvest,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(220),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.accentSecondary.withAlpha(40)),
                      ),
                      child: Consumer<BottleProvider>(
                        builder: (_, bp, __) {
                          final ready = bp.getHarvestableCount() > 0;
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(ready ? '🍳' : '🏠', style: const TextStyle(fontSize: 14)),
                              const SizedBox(width: 4),
                              Text(
                                ready ? '收成！' : '廚房',
                                style: TextStyle(
                                  fontSize: AppTheme.fontLabelLg,
                                  fontWeight: FontWeight.w900,
                                  color: ready ? AppTheme.accentPrimary : AppTheme.textSecondary,
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
                  right: 8, top: 8,
                  child: _buildGearButton(context, idle, bp, tutorialAutoSwitchKey),
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

  static Widget _buildGearButton(BuildContext context, IdleProvider idle, BottleProvider bp, GlobalKey? tutorialKey) {
    final config = idle.autoConfig;
    final progress = context.read<PlayerProvider>().data.stageProgress;
    final isHarvestUnlocked = progress[AutoEliminateConfig.autoHarvestUnlockStage]?.cleared ?? false;
    final isEliminateUnlocked = progress[AutoEliminateConfig.autoEliminateUnlockStage]?.cleared ?? false;
    final hasAutoActive = (isHarvestUnlocked && bp.autoHarvestEnabled) || (isEliminateUnlocked && config.isAutoActive);

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
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(220),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.accentSecondary.withAlpha(40)),
          ),
          child: Stack(
            children: [
              Center(child: Icon(Icons.tune_rounded, size: 16, color: AppTheme.textSecondary.withAlpha(160))),
              if (hasAutoActive)
                Positioned(
                  top: 2, right: 2,
                  child: Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF4CAF50), shape: BoxShape.circle)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 烹飪場景 ──
class _MakingScene extends StatelessWidget {
  final List<String> team;
  final BlockColor? stageColor;
  const _MakingScene({required this.team, this.stageColor});

  @override
  Widget build(BuildContext context) {
    final colorDef = stageColor != null
        ? BottleDefinitions.all.firstWhere((d) => d.color == stageColor, orElse: () => BottleDefinitions.all.first)
        : BottleDefinitions.all.first;

    return Stack(
      children: [
        // 主角色（中間偏左）
        if (team.isNotEmpty)
          Positioned(
            left: 60, bottom: 30,
            child: _AnimatedCookingCat(agentId: team.first),
          ),
        // 能量瓶（左側）
        Positioned(
          left: 20, top: 20,
          child: Text(colorDef.emoji, style: const TextStyle(fontSize: 32)),
        ),
        // 鍋子（右側）
        Positioned(
          right: 30, bottom: 25,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 蒸汽
              Text('♨️', style: TextStyle(fontSize: 18, color: Colors.white.withAlpha(180))),
              const Text('🍲', style: TextStyle(fontSize: 36)),
            ],
          ),
        ),
        // 助手角色
        ...List.generate((team.length - 1).clamp(0, 2), (i) {
          return Positioned(
            right: 20.0 + i * 40,
            bottom: 60,
            child: _buildSmallAgent(team[i + 1]),
          );
        }),
        // 狀態文字
        Positioned(
          left: 0, right: 0, bottom: 6,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '製作中… ${colorDef.emoji}',
                style: const TextStyle(fontSize: AppTheme.fontLabelLg, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSmallAgent(String agentId) {
    return SizedBox(
      width: 36, height: 36,
      child: Image.asset(
        ImageAssets.characterImage(agentId) ?? '',
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Text('🐱', style: TextStyle(fontSize: 20)),
      ),
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
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _riseAnim = Tween(begin: 0.0, end: -40.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _fadeAnim = Tween(begin: 1.0, end: 0.0).animate(CurvedAnimation(parent: _ctrl, curve: const Interval(0.5, 1.0)));
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final colorDef = widget.stageColor != null
        ? BottleDefinitions.all.firstWhere((d) => d.color == widget.stageColor, orElse: () => BottleDefinitions.all.first)
        : BottleDefinitions.all.first;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Stack(
        children: [
          // 甜點上升
          Positioned(
            left: 0, right: 0,
            top: 60 + _riseAnim.value,
            child: Opacity(
              opacity: _fadeAnim.value,
              child: Center(child: Text(colorDef.emoji, style: const TextStyle(fontSize: 40))),
            ),
          ),
          // 金幣飛出
          Positioned(
            left: 0, right: 0,
            top: 80 + _riseAnim.value * 1.3,
            child: Opacity(
              opacity: _fadeAnim.value,
              child: const Center(child: Text('🪙 +金幣', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFD4A017)))),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 烹飪角色動畫（左右走動 + 跳動） ──
class _AnimatedCookingCat extends StatefulWidget {
  final String agentId;
  const _AnimatedCookingCat({required this.agentId});

  @override
  State<_AnimatedCookingCat> createState() => _AnimatedCookingCatState();
}

class _AnimatedCookingCatState extends State<_AnimatedCookingCat>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _walkAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 3200));
    _walkAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -40), weight: 25), // walk left
      TweenSequenceItem(tween: Tween(begin: -40, end: -40), weight: 10), // pause
      TweenSequenceItem(tween: Tween(begin: -40, end: 60), weight: 40), // walk right (to pot)
      TweenSequenceItem(tween: Tween(begin: 60, end: 60), weight: 10), // pause at pot
      TweenSequenceItem(tween: Tween(begin: 60, end: 0), weight: 15), // return
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    _ctrl.repeat();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _walkAnim,
      builder: (_, __) {
        final goingRight = _walkAnim.value > (_ctrl.value < 0.35 ? -100 : 0);
        return Transform.translate(
          offset: Offset(_walkAnim.value, 0),
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()..scale(goingRight ? 1.0 : -1.0, 1.0),
            child: SizedBox(
              width: 56, height: 56,
              child: Image.asset(
                ImageAssets.characterImage(widget.agentId) ?? '',
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Text('🐱', style: TextStyle(fontSize: 30)),
              ),
            ),
          ),
        );
      },
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
  final bool isCooking;

  const _StageCharacter({
    required this.agentId,
    required this.agentDef,
    required this.evolutionStage,
    required this.index,
    required this.totalCharacters,
    required this.stageWidth,
    required this.stageHeight,
    required this.isCooking,
  });

  @override
  State<_StageCharacter> createState() => _StageCharacterState();
}

class _StageCharacterState extends State<_StageCharacter>
    with TickerProviderStateMixin {
  static const _charSize = 56.0;

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
  final _rng = math.Random();

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

    // 啟動隨機走動
    _scheduleNextWalk();
  }

  @override
  void didUpdateWidget(_StageCharacter old) {
    super.didUpdateWidget(old);
    if (widget.isCooking && !old.isCooking) {
      _startCooking();
    }
  }

  @override
  void dispose() {
    _walkTimer?.cancel();
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
    if (!mounted || widget.isCooking) {
      _scheduleNextWalk();
      return;
    }
    final margin = _charSize;
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

  @override
  Widget build(BuildContext context) {
    final groundY = widget.stageHeight - _charSize - widget.stageHeight * 0.12;

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
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()..scale(_facingRight ? 1.0 : -1.0, 1.0),
          child: SizedBox(
            width: _charSize,
            height: _charSize,
            child: Image.asset(
              ImageAssets.characterImage(widget.agentId, evolutionStage: widget.evolutionStage) ?? '',
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Center(
                child: Text(
                  widget.agentDef.attribute.emoji,
                  style: const TextStyle(fontSize: 28),
                ),
              ),
            ),
          ),
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
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.bgCard.withAlpha(240),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.accentSecondary.withAlpha(40)),
                        boxShadow: [BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 8, offset: const Offset(2, 2))],
                      ),
                      child: Consumer<PlayerProvider>(
                        builder: (context, pp, _) {
                          final dq = pp.data.dailyQuests;
                          final nq = pp.data.newbieQuests;
                          final hasQuestReward = nq.completedIds.any((id) => !nq.claimedIds.contains(id))
                              || (!dq.needsReset && dq.allCompleted && !dq.rewardsClaimed);
                          return Column(
                            children: [
                              _charmItem(Icons.task_alt_rounded, '任務', widget.onQuest, badge: hasQuestReward),
                              const SizedBox(height: 6),
                              _charmItem(Icons.bar_chart_rounded, '統計', widget.onStats),
                              const SizedBox(height: 6),
                              _charmItem(Icons.shopping_bag_rounded, '商店', widget.onShop),
                              const SizedBox(height: 6),
                              _charmItem(Icons.settings_rounded, '設定', widget.onSettings),
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
                borderRadius: const BorderRadius.horizontal(right: Radius.circular(16)),
                border: Border.all(color: AppTheme.accentSecondary.withAlpha(60)),
                boxShadow: [BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 6, offset: const Offset(2, 1))],
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

  Widget _charmItem(IconData icon, String label, VoidCallback onTap, {bool badge = false}) {
    return GestureDetector(
      onTap: () => _tapItem(onTap),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.bgSecondary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: AppTheme.accentSecondary),
              ),
              const SizedBox(height: 2),
              Text(label, style: const TextStyle(fontSize: AppTheme.fontLabelSm, color: AppTheme.textSecondary)),
            ],
          ),
          if (badge)
            Positioned(
              top: -2, right: -2,
              child: Container(
                width: 8, height: 8,
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
      gradient = const LinearGradient(colors: [Color(0xFFFFD43B), Color(0xFFFCC419)]);
      textColor = const Color(0xFF7C5E10);
    } else if (isReady) {
      gradient = const LinearGradient(colors: [Color(0xFF6BAF5B), Color(0xFF4CAF50)]);
      textColor = Colors.white;
    } else {
      gradient = const LinearGradient(colors: [Color(0xFF4A5A48), Color(0xFF3E4E3C)]);
      textColor = Colors.white38;
    }

    return GestureDetector(
      onTapDown: isReady ? (_) => setState(() => _pressed = true) : null,
      onTapUp: isReady ? (_) { setState(() => _pressed = false); widget.onTap(); } : null,
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
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: glowAlpha > 0
                        ? [BoxShadow(color: glowColor.withAlpha(glowAlpha), blurRadius: 12 + _glowAnim.value * 6, spreadRadius: _glowAnim.value * 2)]
                        : null,
                  ),
                  child: isReady
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              isRich ? '💰 收成！' : '🧪 收成！',
                              style: TextStyle(color: textColor, fontSize: AppTheme.fontBodyLg, fontWeight: FontWeight.bold),
                            ),
                            if (isRich) ...[
                              const SizedBox(width: 6),
                              Text(
                                '+$estimatedGold🍬',
                                style: TextStyle(color: textColor.withAlpha(200), fontSize: AppTheme.fontLabelLg),
                              ),
                            ],
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 16, height: 16,
                              child: CircularProgressIndicator(
                                value: nearestProgress,
                                strokeWidth: 2,
                                backgroundColor: Colors.white.withAlpha(20),
                                valueColor: const AlwaysStoppedAnimation(Color(0xFF6BAF5B)),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${(nearestProgress * 100).toInt()}%',
                              style: TextStyle(color: textColor, fontSize: AppTheme.fontLabelLg),
                            ),
                          ],
                        ),
                ),
                // 徽章
                if (isReady && fullCount > 0)
                  Positioned(
                    top: -4, right: 6,
                    child: Container(
                      width: 18, height: 18,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6B6B),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.bgCard, width: 1.5),
                      ),
                      child: Center(
                        child: Text('$fullCount', style: const TextStyle(color: Colors.white, fontSize: AppTheme.fontLabelSm, fontWeight: FontWeight.bold)),
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
  State<_HarvestAnimationOverlay> createState() => _HarvestAnimationOverlayState();
}

class _HarvestAnimationOverlayState extends State<_HarvestAnimationOverlay>
    with TickerProviderStateMixin {
  late AnimationController _burstCtrl;   // 粒子散開
  late AnimationController _flyCtrl;     // 粒子飛向資源區

  late List<_CandyParticle> _particles;
  static const _particleCount = 12;
  static const _candyEmojis = ['🍬', '🍭', '🧁', '🍪', '🍩'];

  @override
  void initState() {
    super.initState();

    // Phase 1: 粒子爆開 (600ms)
    _burstCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 600),
    );

    // Phase 2: 粒子飛向右上角 (800ms)
    _flyCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 800),
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
                final burstT = (_burstCtrl.value - p.delay).clamp(0.0, 1.0) / (1.0 - p.delay);
                final flyT = Curves.easeInCubic.transform(_flyCtrl.value);

                // Phase 1: 從中心爆開
                final burstX = originX + math.cos(p.angle) * p.burstRadius * burstT;
                final burstY = originY + math.sin(p.angle) * p.burstRadius * burstT;

                // Phase 2: 從爆開位置飛向目標
                final currentX = burstX + (targetX - burstX) * flyT;
                final currentY = burstY + (targetY - burstY) * flyT;

                // 透明度：爆開時漸入，飛行末段漸出
                final alpha = burstT > 0
                    ? (1.0 - flyT * flyT).clamp(0.0, 1.0)
                    : 0.0;
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
                          style: const TextStyle(fontSize: AppTheme.fontTitleLg)),
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
                      shadows: [Shadow(color: Colors.black.withAlpha(200), blurRadius: 6)],
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
        final gameBox = widget.gameAreaKey.currentContext?.findRenderObject() as RenderBox?;
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
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
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

Color _attrColorFor(AgentAttribute attr) {
  switch (attr) {
    case AgentAttribute.attributeA: return const Color(0xFFFF6B6B);
    case AgentAttribute.attributeB: return const Color(0xFF51CF66);
    case AgentAttribute.attributeC: return const Color(0xFF4DABF7);
    case AgentAttribute.attributeD: return const Color(0xFFFFD43B);
    case AgentAttribute.attributeE: return const Color(0xFFCC5DE8);
  }
}

