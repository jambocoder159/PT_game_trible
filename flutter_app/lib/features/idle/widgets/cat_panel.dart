import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../core/models/cat_data.dart';
import '../../agents/providers/player_provider.dart';
import '../providers/cat_provider.dart';

/// 右側貓咪面板 — 5 隻貓咪的飽食度 + 收穫按鈕
class CatPanel extends StatelessWidget {
  const CatPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<CatProvider, PlayerProvider>(
      builder: (context, catProvider, playerProvider, _) {
        if (!catProvider.isInitialized || !playerProvider.isInitialized) {
          return const SizedBox.shrink();
        }

        final playerLevel = playerProvider.data.playerLevel;

        return Column(
          children: CatDefinitions.all.map((def) {
            final cat = catProvider.cats[def.id];
            if (cat == null) return const SizedBox.shrink();
            return Expanded(
              child: _CatCard(
                definition: def,
                status: cat,
                playerLevel: playerLevel,
                onCollect: cat.isFull(playerLevel)
                    ? () => _collectReward(context, catProvider, def.id, playerLevel)
                    : null,
              ),
            );
          }).toList(),
        );
      },
    );
  }

  void _collectReward(
    BuildContext context,
    CatProvider catProvider,
    String catId,
    int playerLevel,
  ) {
    final reward = catProvider.collectReward(catId, playerLevel);
    if (reward == null) return;

    // 獎勵金幣加到玩家
    final player = context.read<PlayerProvider>();
    player.addGold(reward.quantity);

    // 顯示獎勵提示
    final rarityColors = {
      1: Colors.grey,
      2: Colors.blue,
      3: Colors.purple,
    };
    final color = rarityColors[reward.rarity] ?? Colors.grey;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.card_giftcard, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              '獲得 ${reward.name} +${reward.quantity} 🪙',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        backgroundColor: AppTheme.bgCard,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

/// 單隻貓咪卡片
class _CatCard extends StatelessWidget {
  final CatDefinition definition;
  final CatStatus status;
  final int playerLevel;
  final VoidCallback? onCollect;

  const _CatCard({
    required this.definition,
    required this.status,
    required this.playerLevel,
    this.onCollect,
  });

  @override
  Widget build(BuildContext context) {
    final progress = status.progress(playerLevel);
    final isFull = status.isFull(playerLevel);
    final blockColor = definition.color.color;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.bgCard.withAlpha(isFull ? 220 : 140),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        border: isFull
            ? Border.all(color: blockColor.withAlpha(180), width: 1.5)
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 貓咪 emoji + 名稱
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                definition.emoji,
                style: TextStyle(fontSize: isFull ? 18 : 14),
              ),
              const SizedBox(width: 2),
              Flexible(
                child: Text(
                  definition.name,
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),

          // 飽食度進度條
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: Colors.white.withAlpha(20),
              valueColor: AlwaysStoppedAnimation(
                isFull ? blockColor : blockColor.withAlpha(180),
              ),
            ),
          ),

          // 數值
          Text(
            '${status.currentFood}/${status.maxFood(playerLevel)}',
            style: TextStyle(
              color: AppTheme.textSecondary.withAlpha(150),
              fontSize: 8,
            ),
          ),

          // 收穫按鈕（吃飽時顯示）
          if (isFull)
            GestureDetector(
              onTap: onCollect,
              child: Container(
                margin: const EdgeInsets.only(top: 2),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [blockColor, blockColor.withAlpha(180)],
                  ),
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: blockColor.withAlpha(80),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: const Text(
                  '收穫',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
