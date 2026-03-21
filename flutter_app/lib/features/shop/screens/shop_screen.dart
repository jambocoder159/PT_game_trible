/// 商城畫面
/// MVP：月卡 + 鑽石包（展示用，IAP 尚未接入）
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../agents/providers/player_provider.dart';

class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(
        title: const Text('商城'),
        backgroundColor: AppTheme.bgSecondary,
        actions: [
          Consumer<PlayerProvider>(
            builder: (_, p, __) => Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Row(
                children: [
                  Text('🪙 ${p.data.gold}',
                      style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 12),
                  Text('💎 ${p.data.diamonds}',
                      style: const TextStyle(fontSize: 14)),
                ],
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 月卡
          _ShopItem(
            title: '月卡',
            description: '購買即得 300 鑽石\n每日額外 80 鑽石 × 30 天',
            price: 'NT\$170',
            icon: '🎫',
            color: Colors.amber,
            onTap: () => _showComingSoon(context),
          ),
          const SizedBox(height: 12),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              '鑽石包',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // 小鑽石包
          _ShopItem(
            title: '小鑽石包',
            description: '60 鑽石',
            price: 'NT\$30',
            icon: '💎',
            color: Colors.blue,
            onTap: () => _showComingSoon(context),
          ),
          const SizedBox(height: 10),

          // 大鑽石包
          _ShopItem(
            title: '大鑽石包',
            description: '300 鑽石',
            price: 'NT\$150',
            icon: '💎💎',
            color: Colors.purple,
            badge: '超值',
            onTap: () => _showComingSoon(context),
          ),

          const SizedBox(height: 24),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              '用鑽石兌換',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // 體力補充
          Consumer<PlayerProvider>(
            builder: (context, provider, _) => _ShopItem(
              title: '體力補充',
              description: '恢復 30 體力',
              price: '💎 30',
              icon: '⚡',
              color: Colors.green,
              onTap: () {
                if (provider.data.diamonds >= 30) {
                  provider.addDiamonds(-30);
                  provider.data.stamina =
                      (provider.data.stamina + 30).clamp(0, provider.data.maxStamina + 30);
                  provider.refreshStamina();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('體力 +30！'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('鑽石不足！'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
          ),
          const SizedBox(height: 10),

          // 金幣包
          Consumer<PlayerProvider>(
            builder: (context, provider, _) => _ShopItem(
              title: '金幣袋',
              description: '獲得 500 金幣',
              price: '💎 20',
              icon: '🪙',
              color: Colors.orange,
              onTap: () {
                if (provider.data.diamonds >= 20) {
                  provider.addDiamonds(-20);
                  provider.addGold(500);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('獲得 🪙 500 金幣！'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('鑽石不足！'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('即將推出 — IAP 尚未接入'),
        backgroundColor: Colors.orange,
      ),
    );
  }
}

class _ShopItem extends StatelessWidget {
  final String title;
  final String description;
  final String price;
  final String icon;
  final Color color;
  final String? badge;
  final VoidCallback onTap;

  const _ShopItem({
    required this.title,
    required this.description,
    required this.price,
    required this.icon,
    required this.color,
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.bgCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // 圖示
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withAlpha(30),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(icon, style: const TextStyle(fontSize: 24)),
                ),
              ),
              const SizedBox(width: 14),
              // 資訊
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              badge!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      description,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              // 價格
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: color.withAlpha(40),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color.withAlpha(100)),
                ),
                child: Text(
                  price,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
