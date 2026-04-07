import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../core/models/game_state.dart';
import '../providers/game_provider.dart';

/// 遊戲 HUD — 顯示分數、行動點、Combo 等資訊
class GameHud extends StatelessWidget {
  const GameHud({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, game, child) {
        final state = game.state;
        if (state == null) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            children: [
              // 第一行：分數
              Text(
                '${state.score}',
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),

              // 第二行：行動點 / 計時器 + Combo
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // 行動點或計時器
                  if (state.mode.hasTimer)
                    _InfoChip(
                      icon: Icons.timer,
                      label: _formatTime(state.timeLeftMs),
                      color: state.timeLeftMs < 10000
                          ? AppTheme.accentSecondary
                          : AppTheme.blockTeal,
                    )
                  else if (state.mode.actionPointsStart > 0)
                    _InfoChip(
                      icon: Icons.favorite,
                      label: '${state.actionPoints}',
                      color: state.actionPoints <= 1
                          ? AppTheme.accentSecondary
                          : AppTheme.blockCoral,
                    ),

                  // 操作次數
                  _InfoChip(
                    icon: Icons.touch_app,
                    label: '${state.actionCount}',
                    color: AppTheme.blockRose,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatTime(int ms) {
    final seconds = (ms / 1000).ceil();
    return '${seconds}s';
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(40),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        border: Border.all(color: color.withAlpha(100)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: AppTheme.fontBodyLg,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
