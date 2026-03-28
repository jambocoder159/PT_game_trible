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
import '../../../core/models/cat_agent.dart';

/// 首頁 — 放置型遊戲大廳
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startIdleGame();
      _setupEnergyListener();
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
    });
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
    return Scaffold(
      // ─── 固定底部導航列 ───
      bottomNavigationBar: SafeArea(
        top: false,
        child: GameBottomNavBar(
          currentIndex: _currentNavIndex,
          onTap: _onNavTap,
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

              // ─── 主體：左面板 + 右棋盤 ───
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
                          onConvertAll: _onConvertAll,
                          onConvertIngredient: () => IngredientPanel.show(context),
                          onCraftDessert: () => CraftingPanel.show(context),
                          onSettings: _showSettingsModal,
                          onStats: _showCareerStatsModal,
                          onDailyQuest: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const DailyQuestScreen()),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 4),
                      // ════ 右側棋盤 ════
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
  final VoidCallback onConvertAll;
  final VoidCallback onConvertIngredient;
  final VoidCallback onCraftDessert;
  final VoidCallback onSettings;
  final VoidCallback onStats;
  final VoidCallback onDailyQuest;

  const _LeftPanel({
    required this.bottleKeys,
    required this.onConvertAll,
    required this.onConvertIngredient,
    required this.onCraftDessert,
    required this.onSettings,
    required this.onStats,
    required this.onDailyQuest,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer3<PlayerProvider, IdleProvider, BottleProvider>(
      builder: (context, playerProvider, idleProvider, bottleProvider, _) {
        if (!playerProvider.isInitialized) return const SizedBox.shrink();

        return Column(
          children: [
            // ── 1. 角色區（緊湊） ──
            _buildCharacterSection(playerProvider, idleProvider),
            const SizedBox(height: 6),

            // ── 2. 瓶子區 ──
            _buildBottleSection(bottleProvider),
            const SizedBox(height: 8),

            // ── 3. CTA 區（核心操作） ──
            _buildCtaSection(),

            const Spacer(),

            // ── 4. 功能列（設定/數據/任務） ──
            _buildToolbar(),
            const SizedBox(height: 4),

            // ── 5. 自動消除開關 ──
            const AutoEliminateBar(),
            const SizedBox(height: 4),
          ],
        );
      },
    );
  }

  /// 角色：圖像 + 名稱 + 技能條
  Widget _buildCharacterSection(PlayerProvider pp, IdleProvider idle) {
    final team = pp.data.team;
    if (team.isEmpty) {
      return const SizedBox(height: 64, child: Center(child: Text('?', style: TextStyle(fontSize: 20, color: AppTheme.textSecondary))));
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
          // 角色圖
          Container(
            width: 56, height: 56,
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
              child: _buildAgentImg(agentId, agentDef, 56),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(agentDef.name, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
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
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
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

  /// 5 個瓶子進度條
  Widget _buildBottleSection(BottleProvider bp) {
    if (!bp.isInitialized) return const SizedBox.shrink();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: BottleDefinitions.all.map((def) {
        final bottle = bp.getBottle(def.color);
        bottleKeys.putIfAbsent(def.color, () => GlobalKey());
        return Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: GestureDetector(
            key: bottleKeys[def.color],
            onTap: () {
              HapticFeedback.lightImpact();
              onConvertIngredient();
            },
            child: Row(
              children: [
                Text(def.emoji, style: const TextStyle(fontSize: 12)),
                const SizedBox(width: 3),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: bottle.fillProgress, minHeight: 6,
                      backgroundColor: AppTheme.bgSecondary,
                      valueColor: AlwaysStoppedAnimation(def.color.color.withAlpha(bottle.isFull ? 200 : 100)),
                    ),
                  ),
                ),
                const SizedBox(width: 3),
                SizedBox(
                  width: 16,
                  child: Text(
                    '${bottle.level}',
                    style: TextStyle(color: def.color.color, fontSize: 9, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  /// CTA 按鈕區
  Widget _buildCtaSection() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ★ 一鍵兌換 — 最大 CTA
        GestureDetector(
          onTap: () { HapticFeedback.mediumImpact(); onConvertAll(); },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF6BAF5B), const Color(0xFF4CAF50)],
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [BoxShadow(color: const Color(0xFF6BAF5B).withAlpha(60), blurRadius: 6)],
            ),
            child: const Column(
              children: [
                Text('🧪', style: TextStyle(fontSize: 18)),
                SizedBox(height: 2),
                Text('一鍵兌換', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        // 選擇兌換（詳細面板）
        GestureDetector(
          onTap: () { HapticFeedback.lightImpact(); onConvertIngredient(); },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF6BAF5B).withAlpha(20),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF6BAF5B).withAlpha(80)),
            ),
            child: const Center(
              child: Text('選擇兌換...', style: TextStyle(color: Color(0xFF6BAF5B), fontSize: 10)),
            ),
          ),
        ),
        const SizedBox(height: 6),
        // 製作甜點
        GestureDetector(
          onTap: () { HapticFeedback.lightImpact(); onCraftDessert(); },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFFF0B0C8), const Color(0xFFE8A0B8)],
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [BoxShadow(color: const Color(0xFFF0B0C8).withAlpha(60), blurRadius: 6)],
            ),
            child: const Column(
              children: [
                Text('🧁', style: TextStyle(fontSize: 18)),
                SizedBox(height: 2),
                Text('製作甜點', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 功能圖示列
  Widget _buildToolbar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _ToolbarIcon(icon: Icons.settings_rounded, label: '設置', onTap: onSettings),
        _ToolbarIcon(icon: Icons.bar_chart_rounded, label: '數據', onTap: onStats),
        _ToolbarIcon(icon: Icons.task_alt_rounded, label: '任務', onTap: onDailyQuest),
      ],
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

/// 功能列小圖示
class _ToolbarIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ToolbarIcon({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.accentSecondary.withAlpha(40)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppTheme.textSecondary, size: 16),
            const SizedBox(height: 1),
            Text(label, style: TextStyle(color: AppTheme.textSecondary.withAlpha(150), fontSize: 8)),
          ],
        ),
      ),
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
