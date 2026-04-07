/// 素材背包顯示
/// 顯示玩家擁有的各種素材數量（只顯示有數量的素材）
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../core/models/material.dart';
import '../providers/player_provider.dart';

class MaterialInventoryBar extends StatelessWidget {
  const MaterialInventoryBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (context, provider, _) {
        // 只顯示持有數量 > 0 的素材
        final owned = GameMaterial.values
            .where((m) => provider.getMaterialCount(m) > 0)
            .toList();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.bgSecondary.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          ),
          child: owned.isEmpty
              ? const Text(
                  '暫無素材',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: AppTheme.fontBodyMd),
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: owned.map((type) {
                      final count = provider.getMaterialCount(type);
                      return Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(type.emoji, style: const TextStyle(fontSize: AppTheme.fontBodyLg)),
                            const SizedBox(width: 3),
                            Text(
                              '$count',
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: AppTheme.fontBodyLg,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
        );
      },
    );
  }
}
