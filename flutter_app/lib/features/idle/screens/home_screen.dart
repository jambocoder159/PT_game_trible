import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/image_assets.dart';
import '../../../config/theme.dart';
import '../../agents/providers/player_provider.dart';
import '../../agents/screens/agent_list_screen.dart';
import '../../backpack/screens/backpack_screen.dart';
import '../../quest/screens/stage_select_screen.dart';
import '../../shop/screens/shop_screen.dart';
import '../../daily/screens/daily_quest_screen.dart';
import '../../settings/screens/settings_screen.dart';
import '../../profile/screens/player_profile_screen.dart';
import '../../../core/services/local_storage.dart';
import '../../../core/models/cat_data.dart';
import '../../../core/models/block.dart';
import '../providers/idle_provider.dart';
import '../providers/cat_provider.dart';
import '../widgets/player_info_bar.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/idle_mini_game.dart';
import '../widgets/cat_panel.dart';
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
  bool _boardOnLeft = true;

  // 能量球動畫
  final EnergyOrbController _orbController = EnergyOrbController();

  // 技能 VFX 特效
  bool _showSkillVfx = false;
  AgentAttribute? _skillVfxAttribute;
  String? _skillVfxAgentName;

  // 貓咪 GlobalKey（用於定位能量球目標位置）
  final Map<String, GlobalKey> _catKeys = {};

  // 遊戲區域 GlobalKey（用於定位能量球起點）
  final GlobalKey _gameAreaKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBoardPosition();
      _startIdleGame();
      _setupFoodListener();
    });
  }

  void _loadBoardPosition() {
    final storage = LocalStorageService.instance;
    final saved = storage.getJson('board_on_left');
    if (saved is bool) {
      setState(() => _boardOnLeft = saved);
    }
  }

  void _toggleBoardPosition() {
    setState(() => _boardOnLeft = !_boardOnLeft);
    LocalStorageService.instance.setJson('board_on_left', _boardOnLeft);
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

  void _setupFoodListener() {
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

    final catProvider = context.read<CatProvider>();
    final playerProvider = context.read<PlayerProvider>();

    if (!playerProvider.isInitialized || !catProvider.isInitialized) return;

    final events = idle.consumeFoodEvents();
    if (events.isEmpty) return;

    final playerLevel = playerProvider.data.playerLevel;

    // 為每個食物事件發射能量球
    for (final event in events) {
      _spawnEnergyOrbs(event.foodByColor);
    }

    // 餵食（延遲一點，讓能量球先飛一會兒）
    Future.delayed(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      for (final event in events) {
        catProvider.feedMultiple(event.foodByColor, playerLevel);
      }
    });
  }

  /// 發射能量球：從遊戲區中心飛向對應貓咪
  void _spawnEnergyOrbs(Map<BlockColor, int> foodByColor) {
    // 取得遊戲區域中心位置（螢幕座標）
    final gameBox =
        _gameAreaKey.currentContext?.findRenderObject() as RenderBox?;
    if (gameBox == null) return;
    final gameCenter = gameBox.localToGlobal(
      Offset(gameBox.size.width / 2, gameBox.size.height / 2),
    );

    for (final entry in foodByColor.entries) {
      final color = entry.key;
      final amount = entry.value;

      // 找到對應貓咪的位置
      final catDef = CatDefinitions.getByColor(color);
      if (catDef == null) continue;
      final catKey = _catKeys[catDef.id];
      if (catKey == null) continue;

      final catBox =
          catKey.currentContext?.findRenderObject() as RenderBox?;
      if (catBox == null) continue;
      final catCenter = catBox.localToGlobal(
        Offset(catBox.size.width / 2, catBox.size.height / 2),
      );

      // 發射能量球（最多顯示 3 顆，避免太多）
      _orbController.spawnOrbs(
        color: color,
        start: gameCenter,
        end: catCenter,
        count: amount.clamp(1, 3),
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
    ).then((_) {
      // 返回時重新載入棋盤位置（可能在設定頁被更改）
      _loadBoardPosition();
    });
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

              // ─── 主體：遊戲 + 貓咪（可切換左右） ───
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Row(
                    children: _boardOnLeft
                        ? [
                            Expanded(
                              flex: 6,
                              child: IdleMiniGame(key: _gameAreaKey),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              flex: 4,
                              child: CatPanel(catKeys: _catKeys),
                            ),
                          ]
                        : [
                            Expanded(
                              flex: 4,
                              child: CatPanel(catKeys: _catKeys),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              flex: 6,
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
