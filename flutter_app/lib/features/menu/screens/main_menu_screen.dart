import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/game_modes.dart';
import '../../../config/theme.dart';
import '../../game/providers/game_provider.dart';
import '../../game/screens/game_screen.dart';
import '../../agents/screens/agent_list_screen.dart';
import '../../agents/providers/player_provider.dart';

/// 主選單畫面
class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
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
                          _InfoChip(
                            '⚡ ${data.stamina}/${data.maxStamina}',
                            null,
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),

                // 特工名冊按鈕
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AgentListScreen(),
                        ),
                      );
                    },
                    icon: const Text('🐱', style: TextStyle(fontSize: 20)),
                    label: const Text(
                      '特工名冊',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppTheme.accentSecondary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusMedium,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 模式選擇按鈕
                ...GameModes.allModes.map(
                  (mode) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ModeButton(mode: mode),
                  ),
                ),
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

class _ModeButton extends StatelessWidget {
  final GameModeConfig mode;

  const _ModeButton({required this.mode});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          context.read<GameProvider>().startGame(mode);
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const GameScreen()),
          );
        },
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 18),
          backgroundColor: AppTheme.bgCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            side: BorderSide(
              color: AppTheme.accentPrimary.withAlpha(100),
            ),
          ),
        ),
        child: Column(
          children: [
            Text(
              mode.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              mode.description,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary.withAlpha(180),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
