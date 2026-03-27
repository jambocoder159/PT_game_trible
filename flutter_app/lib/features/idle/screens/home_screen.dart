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

              // ─── 頂部功能圖示列 ───
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _TopIconButton(
                      icon: Icons.settings_rounded,
                      label: '設置',
                      onTap: _showSettingsModal,
                    ),
                    const SizedBox(width: 8),
                    _TopIconButton(
                      icon: Icons.bar_chart_rounded,
                      label: '數據',
                      onTap: _showCareerStatsModal,
                    ),
                    const SizedBox(width: 8),
                    _TopIconButton(
                      icon: Icons.task_alt_rounded,
                      label: '任務',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const DailyQuestScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 2),

              // ─── 主體：左側角色+瓶子+CTA / 右側棋盤 ───
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ─── 左側面板：角色 + 瓶子 + CTA ───
                      SizedBox(
                        width: 110,
                        child: Column(
                          children: [
                            // 角色展示（緊湊版）
                            const _CompactCharacterDisplay(),
                            const Spacer(),
                            // 魔法瓶（垂直排列）
                            _VerticalBottleColumn(
                              bottleKeys: _bottleKeys,
                              onBottleTap: (color) {
                                IngredientPanel.show(context, initialColor: color);
                              },
                            ),
                            const Spacer(),
                            // CTA 按鈕（垂直排列）
                            _VerticalCtaButtons(
                              onConvertIngredient: () => IngredientPanel.show(context),
                              onCraftDessert: () => CraftingPanel.show(context),
                            ),
                            const SizedBox(height: 4),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      // ─── 右側棋盤（佔滿剩餘高度） ───
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

/// 頂部功能圖示按鈕
class _TopIconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _TopIconButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.accentSecondary.withAlpha(60)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppTheme.textSecondary, size: 14),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: AppTheme.textSecondary.withAlpha(180),
                fontSize: 10,
              ),
            ),
          ],
        ),
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
// 左側面板用的緊湊版角色展示
// ═══════════════════════════════════════════

class _CompactCharacterDisplay extends StatelessWidget {
  const _CompactCharacterDisplay();

  @override
  Widget build(BuildContext context) {
    return Consumer2<PlayerProvider, IdleProvider>(
      builder: (context, playerProvider, idleProvider, _) {
        if (!playerProvider.isInitialized) return const SizedBox.shrink();

        final team = playerProvider.data.team;
        if (team.isEmpty) {
          return const SizedBox(
            height: 100,
            child: Center(
              child: Text('?', style: TextStyle(fontSize: 24, color: AppTheme.textSecondary)),
            ),
          );
        }

        final agentId = team.first;
        final agentDef = _findAgentDef(agentId);
        if (agentDef == null) return const SizedBox.shrink();

        final isReady = idleProvider.isSkillReady(agentId);
        final energy = idleProvider.getEnergy(agentId);
        final cost = agentDef.skill.energyCost;
        final attrColor = _attrColorFor(agentDef.attribute);

        return GestureDetector(
          onTap: isReady
              ? () {
                  HapticFeedback.mediumImpact();
                  idleProvider.activateSkill(agentId);
                }
              : null,
          child: Column(
            children: [
              // 角色圖像
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: attrColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isReady ? attrColor.withAlpha(200) : attrColor.withAlpha(60),
                    width: isReady ? 2.0 : 1.0,
                  ),
                  boxShadow: isReady
                      ? [BoxShadow(color: attrColor.withAlpha(60), blurRadius: 8)]
                      : null,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: _buildAgentImg(agentId, agentDef, 80),
                ),
              ),
              const SizedBox(height: 4),
              // 名稱
              Text(
                agentDef.name,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              // 能量條
              SizedBox(
                width: 80,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: (energy / cost).clamp(0.0, 1.0),
                    minHeight: 5,
                    backgroundColor: AppTheme.bgSecondary,
                    valueColor: AlwaysStoppedAnimation(
                      isReady ? attrColor : attrColor.withAlpha(120),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 2),
              if (isReady)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: attrColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    '施放！',
                    style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                )
              else
                Text(
                  '$energy/$cost',
                  style: TextStyle(color: AppTheme.textSecondary.withAlpha(130), fontSize: 9),
                ),
            ],
          ),
        );
      },
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
// 左側垂直瓶子列
// ═══════════════════════════════════════════

class _VerticalBottleColumn extends StatelessWidget {
  final Map<BlockColor, GlobalKey> bottleKeys;
  final void Function(BlockColor color)? onBottleTap;

  const _VerticalBottleColumn({
    required this.bottleKeys,
    this.onBottleTap,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<BottleProvider>(
      builder: (context, bottleProvider, _) {
        if (!bottleProvider.isInitialized) return const SizedBox.shrink();

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: BottleDefinitions.all.map((def) {
            final bottle = bottleProvider.getBottle(def.color);
            bottleKeys.putIfAbsent(def.color, () => GlobalKey());
            return Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: GestureDetector(
                key: bottleKeys[def.color],
                onTap: () {
                  HapticFeedback.lightImpact();
                  onBottleTap?.call(def.color);
                },
                child: Container(
                  width: 90,
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.bgCard,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: def.color.color.withAlpha(bottle.isFull ? 180 : 60),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(def.emoji, style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 填充進度條
                            ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: LinearProgressIndicator(
                                value: bottle.fillProgress,
                                minHeight: 4,
                                backgroundColor: AppTheme.bgSecondary,
                                valueColor: AlwaysStoppedAnimation(
                                  def.color.color.withAlpha(bottle.isFull ? 200 : 100),
                                ),
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              '${bottle.currentEnergy}',
                              style: TextStyle(
                                color: AppTheme.textSecondary.withAlpha(130),
                                fontSize: 8,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // 等級徽章
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                        decoration: BoxDecoration(
                          color: def.color.color.withAlpha(180),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          '${bottle.level}',
                          style: const TextStyle(
                            color: Colors.white, fontSize: 7, fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
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
// 左側垂直 CTA 按鈕
// ═══════════════════════════════════════════

class _VerticalCtaButtons extends StatelessWidget {
  final VoidCallback onConvertIngredient;
  final VoidCallback onCraftDessert;

  const _VerticalCtaButtons({
    required this.onConvertIngredient,
    required this.onCraftDessert,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _SmallCtaButton(
          label: '轉換食材',
          emoji: '🧪',
          color: const Color(0xFF6BAF5B),
          onTap: onConvertIngredient,
        ),
        const SizedBox(height: 4),
        _SmallCtaButton(
          label: '製作甜點',
          emoji: '🧁',
          color: const Color(0xFFF0B0C8),
          onTap: onCraftDessert,
        ),
      ],
    );
  }
}

class _SmallCtaButton extends StatelessWidget {
  final String label;
  final String emoji;
  final Color color;
  final VoidCallback onTap;

  const _SmallCtaButton({
    required this.label,
    required this.emoji,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: 90,
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: color.withAlpha(25),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withAlpha(100)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 3),
            Text(
              label,
              style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
            ),
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
