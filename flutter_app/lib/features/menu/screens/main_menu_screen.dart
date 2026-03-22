import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/app_version.dart';
import '../../../config/game_modes.dart';
import '../../../config/theme.dart';
import '../../game/providers/game_provider.dart';
import '../../game/screens/game_screen.dart';
import '../../agents/screens/agent_list_screen.dart';
import '../../agents/providers/player_provider.dart';
import '../../game/widgets/energy_bar.dart';
import '../../quest/screens/stage_select_screen.dart';
import '../../daily/screens/daily_quest_screen.dart';
import '../../shop/screens/shop_screen.dart';
import '../../gm/screens/gm_screen.dart';
import '../../game/widgets/pause_menu.dart';

/// 主選單畫面
class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  int _versionTapCount = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              children: [
                const SizedBox(height: 24),

                // 遊戲標題
                const Text(
                  '貓咪特工',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Cat Agent Puzzle',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.textSecondary.withAlpha(180),
                    letterSpacing: 6,
                  ),
                ),
                const SizedBox(height: 16),

                // 玩家資訊列
                Consumer<PlayerProvider>(
                  builder: (_, provider, __) {
                    if (!provider.isInitialized) {
                      return const SizedBox.shrink();
                    }
                    final data = provider.data;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.bgCard.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusMedium,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _InfoChip('Lv.${data.playerLevel}', Icons.person),
                          _InfoChip('🪙 ${data.gold}', null),
                          _InfoChip('💎 ${data.diamonds}', null),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),

                // 體力條
                const EnergyBar(),
                const SizedBox(height: 24),

                // ─── 主要按鈕 ───

                // 任務闖關
                _MainButton(
                  icon: '⚔️',
                  label: '任務闖關',
                  description: '6 章 60 關 — 瓦解暗影組織',
                  color: AppTheme.accentPrimary,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const StageSelectScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),

                // 特工名冊
                _MainButton(
                  icon: '🐱',
                  label: '特工名冊',
                  description: '查看 / 升級 / 編排隊伍',
                  color: AppTheme.accentSecondary,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const AgentListScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),

                // 三排挑戰（自由模式）
                _MainButton(
                  icon: '🎮',
                  label: '自由對戰',
                  description: '三排模式 — 練習消除技巧',
                  color: AppTheme.bgCard,
                  borderColor: AppTheme.accentPrimary.withAlpha(100),
                  onTap: () {
                    context.read<GameProvider>().startGame(GameModes.triple);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const GameScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),

                // 每日任務 + 商城（水平排列）
                Row(
                  children: [
                    Expanded(
                      child: _SmallButton(
                        icon: '📋',
                        label: '每日任務',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const DailyQuestScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SmallButton(
                        icon: '🛒',
                        label: '商城',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ShopScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // 設定按鈕
                _SmallButton(
                  icon: '⚙️',
                  label: '設定',
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => Dialog(
                        backgroundColor: AppTheme.bgSecondary,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusLarge),
                          side: BorderSide(
                              color: AppTheme.accentPrimary.withAlpha(150)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                '設定',
                                style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 20),
                              const SettingsPanel(),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(),
                                  child: const Text('關閉'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 20),

                // 版本號（連點 5 次進入 GM 工具）
                GestureDetector(
                  onTap: () {
                    _versionTapCount++;
                    if (_versionTapCount >= 5) {
                      _versionTapCount = 0;
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const GmScreen(),
                        ),
                      );
                    }
                  },
                  child: Text(
                    AppVersion.displayVersion,
                    style: TextStyle(
                      color: AppTheme.textSecondary.withAlpha(100),
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String text;
  final IconData? icon;

  const _InfoChip(this.text, this.icon);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 16, color: AppTheme.textSecondary),
          const SizedBox(width: 4),
        ],
        Text(
          text,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _MainButton extends StatelessWidget {
  final String icon;
  final String label;
  final String description;
  final Color color;
  final Color? borderColor;
  final VoidCallback onTap;

  const _MainButton({
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
    this.borderColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            side: borderColor != null
                ? BorderSide(color: borderColor!)
                : BorderSide.none,
          ),
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withAlpha(150),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.white.withAlpha(120),
            ),
          ],
        ),
      ),
    );
  }
}

class _SmallButton extends StatelessWidget {
  final String icon;
  final String label;
  final VoidCallback onTap;

  const _SmallButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          side: BorderSide(color: Colors.white.withAlpha(30)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
