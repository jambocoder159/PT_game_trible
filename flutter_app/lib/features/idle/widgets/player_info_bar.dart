import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../agents/providers/player_provider.dart';

/// 頂部玩家資訊列 — 名稱、等級、經驗條、金幣、鑽石
class PlayerInfoBar extends StatelessWidget {
  const PlayerInfoBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (_, provider, __) {
        if (!provider.isInitialized) return const SizedBox.shrink();

        final data = provider.data;
        final expNeeded = data.playerLevel * 100;
        final expProgress = expNeeded > 0
            ? (data.playerExp / expNeeded).clamp(0.0, 1.0)
            : 0.0;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.bgCard.withAlpha(180),
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: Border.all(
              color: AppTheme.accentPrimary.withAlpha(60),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 第一行：等級 + 貨幣
              Row(
                children: [
                  // 等級徽章
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.accentPrimary, AppTheme.accentSecondary],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Lv.${data.playerLevel}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // 經驗條
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: expProgress,
                            minHeight: 6,
                            backgroundColor: AppTheme.bgSecondary,
                            valueColor: const AlwaysStoppedAnimation(
                              AppTheme.accentSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${data.playerExp}/$expNeeded',
                          style: TextStyle(
                            color: AppTheme.textSecondary.withAlpha(150),
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 12),

                  // 金幣
                  _CurrencyChip(icon: '🪙', value: data.gold),
                  const SizedBox(width: 8),

                  // 鑽石
                  _CurrencyChip(icon: '💎', value: data.diamonds),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CurrencyChip extends StatelessWidget {
  final String icon;
  final int value;

  const _CurrencyChip({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(icon, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 2),
        Text(
          _formatNumber(value),
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  String _formatNumber(int n) {
    if (n >= 10000) return '${(n / 1000).toStringAsFixed(1)}k';
    return n.toString();
  }
}
