import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../agents/providers/player_provider.dart';
import '../../agents/screens/agent_list_screen.dart';
import '../../backpack/screens/backpack_screen.dart';
import '../../quest/screens/stage_select_screen.dart';
import '../../shop/screens/shop_screen.dart';
import '../../daily/screens/daily_quest_screen.dart';
import '../../gm/screens/gm_screen.dart';
import '../../../config/app_version.dart';
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
  int _currentNavIndex = 2; // 放置（首頁）為預設
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
              const Text(
                '設置',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              // 棋盤位置切換
              ListTile(
                leading: const Icon(Icons.swap_horiz, color: AppTheme.textPrimary),
                title: const Text(
                  '棋盤位置',
                  style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  _boardOnLeft ? '棋盤在左' : '棋盤在右',
                  style: TextStyle(color: AppTheme.textSecondary.withAlpha(150), fontSize: 12),
                ),
                trailing: const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                onTap: () {
                  _toggleBoardPosition();
                  Navigator.pop(ctx);
                },
              ),
              const SizedBox(height: 16),
              // 版本號（隱藏 GM 入口）
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

  void _showCareerStatsModal() {
    final playerProvider = context.read<PlayerProvider>();
    if (!playerProvider.isInitialized) return;
    final data = playerProvider.data;

    // 計算統計數據
    final totalStages = data.stageProgress.length;
    final clearedStages = data.stageProgress.values.where((s) => s.cleared).length;
    final totalStars = data.stageProgress.values.fold<int>(0, (sum, s) => sum + s.stars);
    final totalAgents = data.agents.length;
    final unlockedAgents = data.agents.values.where((a) => a.isUnlocked).length;

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
              const Text(
                '個人生涯數據',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              // 等級 & 經驗
              _StatRow(label: '等級', value: 'Lv.${data.playerLevel}'),
              _StatRow(label: '經驗值', value: '${data.playerExp} / ${data.playerLevel * 100}'),
              const Divider(color: Colors.white12, height: 24),
              // 貨幣
              _StatRow(label: '🪙 金幣', value: '${data.gold}'),
              _StatRow(label: '💎 鑽石', value: '${data.diamonds}'),
              const Divider(color: Colors.white12, height: 24),
              // 關卡進度
              _StatRow(label: '已通關', value: '$clearedStages / $totalStages 關'),
              _StatRow(label: '總星數', value: '$totalStars ⭐'),
              const Divider(color: Colors.white12, height: 24),
              // 特工
              _StatRow(label: '已解鎖特工', value: '$unlockedAgents / $totalAgents'),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
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
          color: AppTheme.bgCard.withAlpha(120),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withAlpha(20)),
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

/// 生涯數據行
class _StatRow extends StatelessWidget {
  final String label;
  final String value;

  const _StatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppTheme.textSecondary.withAlpha(200),
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
