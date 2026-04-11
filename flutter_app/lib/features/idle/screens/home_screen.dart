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

  /// 一鍵收成（含動畫）
  void _onHarvest() {
    final bottleProvider = context.read<BottleProvider>();
    final playerProvider = context.read<PlayerProvider>();
    final result = bottleProvider.harvest(playerProvider.data);
    if (result.isEmpty) return;
    HapticFeedback.mediumImpact();
    // 延遲通知：等粒子飛到錢幣區域後再觸發計數器動畫
    _showHarvestAnimation(result, onParticlesArrived: () {
      playerProvider.notifyAndSave();
    });
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

              // ─── 主體：左面板 + 棋盤 ───
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ════ 左側面板 ════
                      SizedBox(
                        width: 120,
                        child: _LeftPanel(
                          bottleKeys: _bottleKeys,
                          bottleAreaKey: widget.externalBottleAreaKey ?? _guideBottleAreaKey,
                          onHarvest: _onHarvest,
                          onWorkshopDetail: () => WorkshopDetailPanel.show(context),
                          externalHarvestButtonKey: widget.externalConvertButtonKey,
                          tutorialAutoSwitchKey: widget.tutorialAutoSwitchKey,
                          tutorialMode: widget.tutorialMode,
                        ),
                      ),
                      const SizedBox(width: 4),
                      // ════ 中間棋盤 ════
                      Expanded(
                        child: IdleMiniGame(key: _gameAreaKey),
                      ),
                    ],
                  ),
                ),
              ),
            ],
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
// 左側面板
// ═══════════════════════════════════════════

class _LeftPanel extends StatelessWidget {
  final Map<BlockColor, GlobalKey> bottleKeys;
  final GlobalKey? bottleAreaKey;
  final VoidCallback onHarvest;
  final VoidCallback onWorkshopDetail;
  final GlobalKey? externalHarvestButtonKey;
  final GlobalKey? tutorialAutoSwitchKey;
  final bool tutorialMode;

  const _LeftPanel({
    required this.bottleKeys,
    this.bottleAreaKey,
    required this.onHarvest,
    required this.onWorkshopDetail,
    this.externalHarvestButtonKey,
    this.tutorialAutoSwitchKey,
    this.tutorialMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer3<PlayerProvider, IdleProvider, BottleProvider>(
      builder: (context, playerProvider, idleProvider, bottleProvider, _) {
        if (!playerProvider.isInitialized) return const SizedBox.shrink();

        return Column(
          children: [
            // ── A. 角色區（精簡橫排） ──
            _buildCharacterSection(playerProvider, idleProvider),
            const SizedBox(height: 8),

            // ── B. 瓶子區（垂直堆疊，填滿剩餘空間） ──
            Expanded(
              child: _wrapWithKey(bottleAreaKey, _buildBottleColumn(bottleProvider, playerProvider)),
            ),
            const SizedBox(height: 6),

            // ── C. 收成按鈕 ──
            _wrapWithKey(externalHarvestButtonKey, _HarvestButton(
              bottleProvider: bottleProvider,
              onTap: onHarvest,
            )),
            const SizedBox(height: 6),

            // ── D. 自動化區 ──
            _buildAutoSection(context, idleProvider, bottleProvider),
            const SizedBox(height: 4),
          ],
        );
      },
    );
  }

  Widget _wrapWithKey(GlobalKey? key, Widget child) {
    if (key == null) return child;
    return KeyedSubtree(key: key, child: child);
  }

  // ─── A. 角色區：36px 頭像 + 能量條 + 施放 ───
  Widget _buildCharacterSection(PlayerProvider pp, IdleProvider idle) {
    final team = pp.data.team;
    if (team.isEmpty) {
      return const SizedBox(height: 36, child: Center(child: Text('?', style: TextStyle(fontSize: AppTheme.fontTitleLg, color: AppTheme.textSecondary))));
    }
    final agentId = team.first;
    final agentDef = _findAgentDef(agentId);
    if (agentDef == null) return const SizedBox.shrink();

    final isReady = idle.isSkillReady(agentId);
    final energy = idle.getEnergy(agentId);
    final cost = agentDef.skill.energyCost;
    final attrColor = _attrColorFor(agentDef.attribute);

    return GestureDetector(
      onTap: isReady
          ? () { HapticFeedback.mediumImpact(); idle.activateSkill(agentId); }
          : null,
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: attrColor.withAlpha(25),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isReady ? attrColor.withAlpha(200) : attrColor.withAlpha(60),
                width: isReady ? 2 : 1,
              ),
              boxShadow: isReady ? [BoxShadow(color: attrColor.withAlpha(80), blurRadius: 8)] : null,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: _buildAgentImg(agentId, agentDef, 36),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: (energy / cost).clamp(0.0, 1.0), minHeight: 7,
                    backgroundColor: AppTheme.bgSecondary,
                    valueColor: AlwaysStoppedAnimation(isReady ? attrColor : attrColor.withAlpha(120)),
                  ),
                ),
                const SizedBox(height: 3),
                if (isReady)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: attrColor, borderRadius: BorderRadius.circular(6)),
                    child: const Text('施放！', style: TextStyle(color: Colors.white, fontSize: AppTheme.fontLabelLg, fontWeight: FontWeight.bold)),
                  )
                else
                  Text('$energy/$cost', style: TextStyle(color: AppTheme.textSecondary.withAlpha(130), fontSize: AppTheme.fontLabelSm)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── B. 瓶子區：5 張橫式卡片（進度條底色填充） ───
  Widget _buildBottleColumn(BottleProvider bp, PlayerProvider pp) {
    if (!bp.isInitialized) return const SizedBox.shrink();

    for (final def in BottleDefinitions.all) {
      bottleKeys.putIfAbsent(def.color, () => GlobalKey());
    }

    return Column(
      children: BottleDefinitions.all.map((def) {
        final bottle = bp.getBottle(def.color);
        final isFull = bottle.isFull;
        final canUpgrade = bp.canUpgrade(def.color, pp.data);
        final dessert = bp.getCurrentDessert(def.color);
        final clr = def.color.color;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: GestureDetector(
              onTap: tutorialMode ? null : onWorkshopDetail,
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: AppTheme.bgCard,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  border: Border.all(
                    color: isFull ? clr.withAlpha(180) : clr.withAlpha(30),
                    width: isFull ? 1.5 : 0.5,
                  ),
                  boxShadow: isFull
                      ? [BoxShadow(color: clr.withAlpha(40), blurRadius: 8)]
                      : [BoxShadow(color: Colors.black.withAlpha(6), blurRadius: 2)],
                ),
                child: Stack(
                  children: [
                    // 進度條底色（左→右填充）
                    Positioned.fill(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: bottle.fillProgress,
                          heightFactor: 1.0,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  clr.withAlpha(isFull ? 80 : 35),
                                  clr.withAlpha(isFull ? 140 : 65),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // 橫式內容：emoji | 能量文字 | 甜點資訊
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Row(
                        children: [
                          // 左：瓶子 emoji
                          KeyedSubtree(
                            key: bottleKeys[def.color]!,
                            child: Text(def.emoji,
                                style: const TextStyle(fontSize: AppTheme.fontTitleLg)),
                          ),
                          const SizedBox(width: 5),
                          // 中：等級 + 能量
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 能量數字
                                Text(
                                  isFull
                                      ? '${bottle.currentEnergy} ✓'
                                      : '${bottle.currentEnergy}/${bottle.capacity}',
                                  style: TextStyle(
                                    fontSize: AppTheme.fontBodyLg,
                                    fontWeight: FontWeight.bold,
                                    color: isFull ? clr : AppTheme.textPrimary,
                                  ),
                                ),
                                // 等級
                                Text(
                                  'Lv${bottle.level}',
                                  style: TextStyle(
                                    fontSize: AppTheme.fontLabelLg,
                                    color: AppTheme.textSecondary.withAlpha(160),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // 右：甜點 + 售價
                          if (dessert != null)
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(dessert.emoji,
                                    style: const TextStyle(fontSize: AppTheme.fontTitleMd)),
                                Text(
                                  '${dessert.sellPrice}🍬',
                                  style: TextStyle(
                                    fontSize: AppTheme.fontLabelLg,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textSecondary.withAlpha(180),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    // 升級紅點
                    if (canUpgrade)
                      Positioned(
                        top: 3, right: 3,
                        child: Container(
                          width: 8, height: 8,
                          decoration: BoxDecoration(
                            color: AppTheme.accentPrimary,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppTheme.bgCard, width: 1),
                            boxShadow: [BoxShadow(color: AppTheme.accentPrimary.withAlpha(100), blurRadius: 4)],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ─── C. 自動化區：極簡兩行開關（關卡解鎖） ───
  Widget _buildAutoSection(BuildContext context, IdleProvider idle, BottleProvider bp) {
    final config = idle.autoConfig;
    final playerProvider = context.read<PlayerProvider>();
    final progress = playerProvider.data.stageProgress;

    // 自動收成：突破 1-5 解鎖
    final isHarvestUnlocked = progress[AutoEliminateConfig.autoHarvestUnlockStage]?.cleared ?? false;
    // 自動消除：突破 1-10 解鎖
    final isEliminateUnlocked = progress[AutoEliminateConfig.autoEliminateUnlockStage]?.cleared ?? false;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.accentSecondary.withAlpha(40)),
      ),
      child: Column(
        children: [
          // 自動收成（上方）
          Row(
            children: [
              Icon(Icons.autorenew, size: 13,
                color: isHarvestUnlocked && bp.autoHarvestEnabled
                    ? const Color(0xFFFFD43B) : AppTheme.textSecondary.withAlpha(80)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  isHarvestUnlocked ? '自動收成' : '通關 1-5 解鎖',
                  style: TextStyle(
                    color: isHarvestUnlocked ? AppTheme.textPrimary : AppTheme.textSecondary.withAlpha(100),
                    fontSize: AppTheme.fontLabelLg,
                  ),
                ),
              ),
              SizedBox(
                width: 32, height: 18,
                child: FittedBox(
                  child: Switch(
                    value: isHarvestUnlocked && bp.autoHarvestEnabled,
                    onChanged: isHarvestUnlocked ? (v) => bp.setAutoHarvest(v) : null,
                    activeColor: const Color(0xFFFFD43B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // 自動消除（下方）
          GestureDetector(
            onTap: isEliminateUnlocked ? () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: AppTheme.bgSecondary,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (_) => const AutoEliminateSettings(),
              );
            } : null,
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                Icon(Icons.flash_auto, size: 13,
                  color: isEliminateUnlocked && config.isAutoActive
                      ? AppTheme.accentSecondary : AppTheme.textSecondary.withAlpha(80)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    isEliminateUnlocked ? '自動消除' : '通關 1-10 解鎖',
                    style: TextStyle(
                      color: isEliminateUnlocked ? AppTheme.textPrimary : AppTheme.textSecondary.withAlpha(100),
                      fontSize: AppTheme.fontLabelLg,
                    ),
                  ),
                ),
                KeyedSubtree(
                  key: tutorialAutoSwitchKey ?? GlobalKey(),
                  child: SizedBox(
                    width: 32, height: 18,
                    child: FittedBox(
                      child: Switch(
                        value: isEliminateUnlocked && config.isEnabled,
                        onChanged: isEliminateUnlocked ? (v) => idle.toggleAutoEliminate(v) : null,
                        activeColor: AppTheme.accentSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildAgentImg(String agentId, CatAgentDefinition agentDef, double size) {
    final iconPath = ImageAssets.iconImage(agentId);
    if (iconPath == null) {
      return Center(
        child: GameIcon(
          assetPath: ImageAssets.attributeIcon(agentDef.attribute),
          fallbackEmoji: agentDef.attribute.emoji,
          size: size * 0.5,
        ),
      );
    }
    return Image.asset(
      iconPath, width: size, height: size, fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Center(
        child: GameIcon(
          assetPath: ImageAssets.attributeIcon(agentDef.attribute),
          fallbackEmoji: agentDef.attribute.emoji,
          size: size * 0.5,
        ),
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
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: glowAlpha > 0
                        ? [BoxShadow(color: glowColor.withAlpha(glowAlpha), blurRadius: 12 + _glowAnim.value * 6, spreadRadius: _glowAnim.value * 2)]
                        : null,
                  ),
                  child: isReady
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              isRich ? '💰 收成！' : '🧪 收成！',
                              style: TextStyle(color: textColor, fontSize: AppTheme.fontBodyLg, fontWeight: FontWeight.bold),
                            ),
                            if (isRich) ...[
                              const SizedBox(height: 2),
                              Text(
                                '+$estimatedGold🍬',
                                style: TextStyle(color: textColor.withAlpha(200), fontSize: AppTheme.fontLabelLg),
                              ),
                            ],
                          ],
                        )
                      : Center(
                          child: Row(
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

