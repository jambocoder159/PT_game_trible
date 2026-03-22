import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../agents/providers/player_provider.dart';
import '../../agents/screens/agent_list_screen.dart';
import '../../game/providers/game_provider.dart';
import '../../game/screens/game_screen.dart';
import '../../quest/screens/stage_select_screen.dart';
import '../../shop/screens/shop_screen.dart';
import '../../daily/screens/daily_quest_screen.dart';
import '../../gm/screens/gm_screen.dart';
import '../../../config/app_version.dart';
import '../../../config/game_modes.dart';
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

/// 首頁 — 放置型遊戲大廳
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentNavIndex = 0;
  int _versionTapCount = 0;
  bool _boardOnLeft = true;

  // 能量球動畫
  final EnergyOrbController _orbController = EnergyOrbController();

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
    if (idle.state == null) {
      idle.startIdleGame();
    }
  }

  void _setupFoodListener() {
    final idle = context.read<IdleProvider>();
    idle.addListener(_onIdleUpdate);
  }

  void _onIdleUpdate() {
    if (!mounted) return;

    final idle = context.read<IdleProvider>();
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
    if (index == _currentNavIndex && index == 0) return;

    switch (index) {
      case 0:
        setState(() => _currentNavIndex = 0);
        break;
      case 1:
        context.read<GameProvider>().startGame(GameModes.triple);
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const GameScreen()),
        );
        break;
      case 2:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const StageSelectScreen()),
        );
        break;
      case 3:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ShopScreen()),
        );
        break;
      case 4:
        _showMoreMenu();
        break;
    }
  }

  void _showMoreMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _MoreMenuItem(
                icon: Icons.pets,
                label: '特工名冊',
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AgentListScreen(),
                    ),
                  );
                },
              ),
              _MoreMenuItem(
                icon: Icons.task_alt,
                label: '每日任務',
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const DailyQuestScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () {
                  _versionTapCount++;
                  if (_versionTapCount >= 5) {
                    _versionTapCount = 0;
                    Navigator.pop(ctx);
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const GmScreen()),
                    );
                  }
                },
                child: Text(
                  AppVersion.displayVersion,
                  style: TextStyle(
                    color: AppTheme.textSecondary.withAlpha(100),
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // 主要內容
            Column(
              children: [
                // ─── 頂部玩家資訊列 ───
                const Padding(
                  padding: EdgeInsets.fromLTRB(8, 6, 8, 4),
                  child: PlayerInfoBar(),
                ),

                // ─── 切換按鈕 ───
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: _toggleBoardPosition,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.bgCard.withAlpha(120),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.white.withAlpha(20),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.swap_horiz,
                                color: AppTheme.textSecondary,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _boardOnLeft ? '棋盤←→貓咪' : '貓咪←→棋盤',
                                style: TextStyle(
                                  color: AppTheme.textSecondary.withAlpha(180),
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
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

                // ─── 底部導航列 ───
                GameBottomNavBar(
                  currentIndex: _currentNavIndex,
                  onTap: _onNavTap,
                ),
              ],
            ),

            // ─── 能量球飛行動畫覆蓋層 ───
            EnergyOrbOverlay(controller: _orbController),
          ],
        ),
      ),
    );
  }
}

class _MoreMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MoreMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.textPrimary),
      title: Text(
        label,
        style: const TextStyle(
          color: AppTheme.textPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: AppTheme.textSecondary.withAlpha(120),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      onTap: onTap,
    );
  }
}
