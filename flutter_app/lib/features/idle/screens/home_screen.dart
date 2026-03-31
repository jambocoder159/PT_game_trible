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
import '../widgets/ingredient_panel.dart';
import '../widgets/auto_eliminate_bar.dart';
import '../widgets/crafting_panel.dart';
import '../widgets/energy_orb_overlay.dart';
import '../widgets/home_guide_overlay.dart';
import '../providers/crafting_provider.dart';
import '../../../config/ingredient_data.dart';
import '../../../core/models/cat_agent.dart';

/// 首頁 — 放置型遊戲大廳
class HomeScreen extends StatefulWidget {
  /// 教學模式：跳過內建 HomeGuide，由外部 overlay 控制
  final bool tutorialMode;

  const HomeScreen({super.key, this.tutorialMode = false});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentNavIndex = 2; // 放置（首頁）為預設

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

  // 瓶子滿提示節流（避免重複提醒）
  final Set<BlockColor> _notifiedFullBottles = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startIdleGame();
      _setupEnergyListener();
      _checkHomeGuide();
    });
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
    final team = context.read<PlayerProvider>().data.team;
    idle.setTeam(team);
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

  /// 檢查瓶子是否滿了 → 首次滿時顯示 SnackBar 提示
  void _checkBottleFull(BottleProvider bp) {
    if (_showHomeGuide || _currentNavIndex != 2) return;

    for (final color in BlockColor.values) {
      final bottle = bp.getBottle(color);
      if (bottle.isFull && !_notifiedFullBottles.contains(color)) {
        _notifiedFullBottles.add(color);
        final def = BottleDefinitions.all.firstWhere((d) => d.color == color);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${def.emoji} 瓶子滿了！點擊「一鍵兌換」獲得食材！'),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: '兌換',
              onPressed: _onConvertAll,
            ),
          ),
        );
        return; // 一次只提示一個瓶子
      }
      // 瓶子被兌換後（不再滿），移除記錄以便下次再提醒
      if (!bottle.isFull) {
        _notifiedFullBottles.remove(color);
      }
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
    if (index == _currentNavIndex) return;
    setState(() => _currentNavIndex = index);
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
                  );
                },
              ),
            ),
          ),
          body: IndexedStack(
            index: _currentNavIndex,
            children: [
              const BackpackScreen(),       // 0: 背包
              const AgentListScreen(),      // 1: 角色
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
                    '瓶子滿了就能兌換食材，製作甜點！',
                buttonText: '了解！',
                highlightKey: _guideBottleAreaKey,
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
      ],
    );
  }

  /// 一鍵兌換
  void _onConvertAll() {
    final bottleProvider = context.read<BottleProvider>();
    final playerProvider = context.read<PlayerProvider>();
    final results = bottleProvider.convertAllDefault(playerProvider.data);
    if (results.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('能量不足，無法兌換'), duration: Duration(seconds: 1)),
      );
      return;
    }
    HapticFeedback.mediumImpact();
    playerProvider.notifyAndSave();
    final summary = results.entries.map((e) => '${e.key} x${e.value}').join('、');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('兌換完成：$summary'), duration: const Duration(seconds: 2)),
    );
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
              const Padding(
                padding: EdgeInsets.fromLTRB(8, 6, 8, 4),
                child: PlayerInfoBar(),
              ),

              // ─── 主體：左面板 + 棋盤 + 右工具列 ───
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
                          bottleAreaKey: _guideBottleAreaKey,
                          onConvertAll: _onConvertAll,
                          onConvertIngredient: () => IngredientPanel.show(context),
                          onCraftDessert: () => CraftingPanel.show(context),
                        ),
                      ),
                      const SizedBox(width: 4),
                      // ════ 中間棋盤 ════
                      Expanded(
                        child: IdleMiniGame(key: _gameAreaKey),
                      ),
                      const SizedBox(width: 4),
                      // ════ 右側工具列 ════
                      _RightToolbar(
                        onSettings: _showSettingsModal,
                        onStats: _showCareerStatsModal,
                        onDailyQuest: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const DailyQuestScreen()),
                          );
                        },
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
                      fontSize: 20,
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
// 左側面板 — CTA 優先、功能集中
// ═══════════════════════════════════════════

class _LeftPanel extends StatelessWidget {
  final Map<BlockColor, GlobalKey> bottleKeys;
  final GlobalKey? bottleAreaKey;
  final VoidCallback onConvertAll;
  final VoidCallback onConvertIngredient;
  final VoidCallback onCraftDessert;

  const _LeftPanel({
    required this.bottleKeys,
    this.bottleAreaKey,
    required this.onConvertAll,
    required this.onConvertIngredient,
    required this.onCraftDessert,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer3<PlayerProvider, IdleProvider, BottleProvider>(
      builder: (context, playerProvider, idleProvider, bottleProvider, _) {
        if (!playerProvider.isInitialized) return const SizedBox.shrink();

        final hasFullBottle = BottleDefinitions.all.any(
          (def) => bottleProvider.getBottle(def.color).isFull,
        );
        final crafting = context.read<CraftingProvider>();
        final canCraftAny = DessertDefinitions.all.any(
          (r) => crafting.canCraft(r.id, playerProvider.data),
        );

        return Column(
          children: [
            // ── 1. 角色區（緊湊） ──
            _buildCharacterSection(playerProvider, idleProvider),
            const SizedBox(height: 6),

            // ── 2. 瓶子區（放大，顯示預設食材）──
            _wrapWithKey(bottleAreaKey, _buildBottleSection(bottleProvider)),
            const SizedBox(height: 6),

            // ── 3. CTA 組合鍵：一鍵兌換 + 製作甜點 ──
            _buildCtaGroup(hasFullBottle: hasFullBottle, canCraftAny: canCraftAny),

            const Spacer(),

            // ── 4. 自動消除 ──
            const AutoEliminateBar(),
            const SizedBox(height: 4),
          ],
        );
      },
    );
  }

  /// 角色：圖像 + 名稱 + 技能條
  /// 用 Key 包裝 widget（null 時不包）
  Widget _wrapWithKey(GlobalKey? key, Widget child) {
    if (key == null) return child;
    return KeyedSubtree(key: key, child: child);
  }

  Widget _buildCharacterSection(PlayerProvider pp, IdleProvider idle) {
    final team = pp.data.team;
    if (team.isEmpty) {
      return const SizedBox(height: 48, child: Center(child: Text('?', style: TextStyle(fontSize: 20, color: AppTheme.textSecondary))));
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
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: attrColor.withAlpha(25),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isReady ? attrColor.withAlpha(200) : attrColor.withAlpha(60),
                width: isReady ? 2 : 1,
              ),
              boxShadow: isReady ? [BoxShadow(color: attrColor.withAlpha(60), blurRadius: 6)] : null,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: _buildAgentImg(agentId, agentDef, 44),
            ),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(agentDef.name, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 10, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: (energy / cost).clamp(0.0, 1.0), minHeight: 5,
                    backgroundColor: AppTheme.bgSecondary,
                    valueColor: AlwaysStoppedAnimation(isReady ? attrColor : attrColor.withAlpha(120)),
                  ),
                ),
                const SizedBox(height: 2),
                if (isReady)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(color: attrColor, borderRadius: BorderRadius.circular(4)),
                    child: const Text('施放！', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                  )
                else
                  Text('$energy/$cost', style: TextStyle(color: AppTheme.textSecondary.withAlpha(130), fontSize: 8)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 5 個瓶子（放大版 — 每瓶一行，顯示預設食材）
  Widget _buildBottleSection(BottleProvider bp) {
    if (!bp.isInitialized) return const SizedBox.shrink();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: BottleDefinitions.all.map((def) {
        final bottle = bp.getBottle(def.color);
        final defaultIng = bp.getDefaultIngredient(def.color);
        bottleKeys.putIfAbsent(def.color, () => GlobalKey());
        return Padding(
          padding: const EdgeInsets.only(bottom: 3),
          child: GestureDetector(
            key: bottleKeys[def.color],
            onTap: () {
              HapticFeedback.lightImpact();
              onConvertIngredient();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.bgCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: def.color.color.withAlpha(bottle.isFull ? 180 : 50)),
              ),
              child: Row(
                children: [
                  // 瓶子圖示
                  Text(def.emoji, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 4),
                  // 中間區：進度條 + 預設食材
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 進度條
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: bottle.fillProgress, minHeight: 8,
                            backgroundColor: AppTheme.bgSecondary,
                            valueColor: AlwaysStoppedAnimation(def.color.color.withAlpha(bottle.isFull ? 220 : 120)),
                          ),
                        ),
                        const SizedBox(height: 2),
                        // 預設食材 + 能量值
                        Row(
                          children: [
                            if (defaultIng != null)
                              Text(
                                '${defaultIng.emoji}${defaultIng.name}',
                                style: TextStyle(color: AppTheme.textSecondary.withAlpha(150), fontSize: 8),
                                overflow: TextOverflow.ellipsis,
                              )
                            else
                              Text('點擊選擇', style: TextStyle(color: AppTheme.textSecondary.withAlpha(100), fontSize: 8)),
                            const Spacer(),
                            Text(
                              '${bottle.currentEnergy}',
                              style: TextStyle(color: AppTheme.textSecondary.withAlpha(130), fontSize: 8),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 3),
                  // 等級
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: def.color.color.withAlpha(180),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${bottle.level}',
                      style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// CTA 組合鍵：一鍵兌換 + 製作甜點（帶狀態引導）
  Widget _buildCtaGroup({required bool hasFullBottle, required bool canCraftAny}) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bgCard.withAlpha(200),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.accentSecondary.withAlpha(40)),
      ),
      child: Column(
        children: [
          // 一鍵兌換
          _PulsingCtaButton(
            enabled: hasFullBottle,
            onTap: () { HapticFeedback.mediumImpact(); onConvertAll(); },
            gradient: hasFullBottle
                ? const LinearGradient(colors: [Color(0xFF6BAF5B), Color(0xFF4CAF50)])
                : const LinearGradient(colors: [Color(0xFF4A5A48), Color(0xFF3E4E3C)]),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🧪', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 4),
                Text('一鍵兌換', style: TextStyle(
                  color: hasFullBottle ? Colors.white : Colors.white38,
                  fontSize: 13, fontWeight: FontWeight.bold,
                )),
              ],
            ),
          ),
          // 分隔：選擇兌換
          GestureDetector(
            onTap: () { HapticFeedback.lightImpact(); onConvertIngredient(); },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 4),
              color: const Color(0xFF6BAF5B).withAlpha(15),
              child: const Center(
                child: Text('選擇兌換 ▸', style: TextStyle(color: Color(0xFF6BAF5B), fontSize: 9)),
              ),
            ),
          ),
          // 分隔線
          Container(height: 1, color: AppTheme.accentSecondary.withAlpha(30)),
          // 製作甜點
          _PulsingCtaButton(
            enabled: canCraftAny,
            onTap: () { HapticFeedback.lightImpact(); onCraftDessert(); },
            gradient: canCraftAny
                ? const LinearGradient(colors: [Color(0xFFF0B0C8), Color(0xFFE8A0B8)])
                : const LinearGradient(colors: [Color(0xFF6A5A62), Color(0xFF5E4E56)]),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(11)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🧁', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 4),
                Text('製作甜點', style: TextStyle(
                  color: canCraftAny ? Colors.white : Colors.white38,
                  fontSize: 13, fontWeight: FontWeight.bold,
                )),
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
// CTA 按鈕 — 啟用時脈衝動畫引導
// ═══════════════════════════════════════════

class _PulsingCtaButton extends StatefulWidget {
  final bool enabled;
  final VoidCallback onTap;
  final LinearGradient gradient;
  final BorderRadius borderRadius;
  final Widget child;

  const _PulsingCtaButton({
    required this.enabled,
    required this.onTap,
    required this.gradient,
    required this.borderRadius,
    required this.child,
  });

  @override
  State<_PulsingCtaButton> createState() => _PulsingCtaButtonState();
}

class _PulsingCtaButtonState extends State<_PulsingCtaButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _glowAnim;

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
    if (widget.enabled) _pulseCtrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _PulsingCtaButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled && !_pulseCtrl.isAnimating) {
      _pulseCtrl.repeat(reverse: true);
    } else if (!widget.enabled && _pulseCtrl.isAnimating) {
      _pulseCtrl.stop();
      _pulseCtrl.value = 0;
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _glowAnim,
        builder: (context, child) {
          final glowAlpha = widget.enabled ? (_glowAnim.value * 100).toInt() : 0;
          final glowColor = widget.gradient.colors.first;
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              gradient: widget.gradient,
              borderRadius: widget.borderRadius,
              boxShadow: glowAlpha > 0
                  ? [
                      BoxShadow(
                        color: glowColor.withAlpha(glowAlpha),
                        blurRadius: 12 + _glowAnim.value * 6,
                        spreadRadius: _glowAnim.value * 2,
                      ),
                    ]
                  : null,
            ),
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}

// ═══════════════════════════════════════════
// 右側工具列 — 設置 / 數據 / 任務（垂直排列）
// ═══════════════════════════════════════════

class _RightToolbar extends StatelessWidget {
  final VoidCallback onSettings;
  final VoidCallback onStats;
  final VoidCallback onDailyQuest;

  const _RightToolbar({
    required this.onSettings,
    required this.onStats,
    required this.onDailyQuest,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ToolbarIconVertical(icon: Icons.settings_rounded, label: '設置', onTap: onSettings),
        const SizedBox(height: 8),
        _ToolbarIconVertical(icon: Icons.bar_chart_rounded, label: '數據', onTap: onStats),
        const SizedBox(height: 8),
        _ToolbarIconVertical(icon: Icons.task_alt_rounded, label: '任務', onTap: onDailyQuest),
      ],
    );
  }
}

class _ToolbarIconVertical extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ToolbarIconVertical({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.accentSecondary.withAlpha(40)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppTheme.textSecondary, size: 18),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(color: AppTheme.textSecondary.withAlpha(150), fontSize: 8)),
          ],
        ),
      ),
    );
  }
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
                          fontSize: 16,
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
