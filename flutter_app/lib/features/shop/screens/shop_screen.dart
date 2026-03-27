/// 商城畫面 — 翻修版
/// TabBar 分類（精選/鑽石包/兌換）+ 精選 PageView + 素材兌換網格
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/image_assets.dart';
import '../../../config/theme.dart';
import '../../../core/models/material.dart';
import '../../agents/providers/player_provider.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ─── 頂部標題列 ───
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  const Text(
                    '商城',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  // 貨幣顯示
                  Consumer<PlayerProvider>(
                    builder: (_, p, __) => Row(
                      children: [
                        _CurrencyChip(
                          assetPath: ImageAssets.coin,
                          fallback: '🪙',
                          value: p.data.gold,
                        ),
                        const SizedBox(width: 10),
                        _CurrencyChip(
                          assetPath: ImageAssets.diamond,
                          fallback: '💎',
                          value: p.data.diamonds,
                        ),
                        const SizedBox(width: 10),
                        Consumer<PlayerProvider>(
                          builder: (_, pp, __) => _DustChip(
                            value: pp.getMaterialCount(
                                GameMaterial.crystalDust),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ─── TabBar ───
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppTheme.bgCard,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: AppTheme.accentSecondary.withAlpha(50),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.accentSecondary,
                  ),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerHeight: 0,
                labelColor: AppTheme.accentSecondary,
                unselectedLabelColor: AppTheme.textSecondary,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                tabs: const [
                  Tab(text: '精選推薦'),
                  Tab(text: '鑽石商店'),
                  Tab(text: '素材兌換'),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ─── Tab 內容 ───
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  _FeaturedTab(),
                  _DiamondShopTab(),
                  _MaterialExchangeTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════
// Tab 1: 精選推薦
// ═══════════════════════════════════════

class _FeaturedTab extends StatefulWidget {
  const _FeaturedTab();

  @override
  State<_FeaturedTab> createState() => _FeaturedTabState();
}

class _FeaturedTabState extends State<_FeaturedTab> {
  final PageController _pageController = PageController(viewportFraction: 0.9);

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        // ─── 精選 Banner PageView ───
        SizedBox(
          height: 140,
          child: PageView(
            controller: _pageController,
            children: [
              _FeaturedBanner(
                title: '月卡',
                subtitle: '購買即得 300 鑽石\n每日額外 80 鑽石 × 30 天',
                icon: '🎫',
                gradient: [Colors.amber.shade700, Colors.orange.shade400],
                onTap: () => _showComingSoon(context),
              ),
              _FeaturedBanner(
                title: '新手特惠包',
                subtitle: '600 鑽石 + 10 掃蕩券\n限購一次',
                icon: '🎁',
                gradient: [Colors.purple.shade600, Colors.pink.shade300],
                badge: '限定',
                onTap: () => _showComingSoon(context),
              ),
              _FeaturedBanner(
                title: '每週特惠',
                subtitle: '200 鑽石 + 5000 金幣\n每週重置',
                icon: '🏷️',
                gradient: [Colors.teal.shade600, Colors.cyan.shade300],
                onTap: () => _showComingSoon(context),
              ),
            ],
          ),
        ),

        const SizedBox(height: 6),
        // Page indicator
        Center(
          child: SizedBox(
            height: 16,
            child: AnimatedBuilder(
              animation: _pageController,
              builder: (context, _) {
                final page = _pageController.hasClients
                    ? (_pageController.page ?? 0)
                    : 0.0;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (i) {
                    final distance = (page - i).abs().clamp(0.0, 1.0);
                    return Container(
                      width: 6 + (1 - distance) * 8,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.accentSecondary
                            .withAlpha((255 * (1 - distance * 0.6)).round()),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ),

        const SizedBox(height: 20),

        // ─── 每日特價區 ───
        const Text(
          '每日特價',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),

        Consumer<PlayerProvider>(
          builder: (context, provider, _) => Column(
            children: [
              _QuickBuyCard(
                icon: Icons.bolt_rounded,
                iconColor: Colors.greenAccent,
                title: '體力補充',
                subtitle: '恢復 30 體力',
                price: '💎 30',
                priceColor: Colors.cyan,
                onTap: () => _buyStamina(context, provider),
              ),
              const SizedBox(height: 8),
              _QuickBuyCard(
                icon: Icons.monetization_on_rounded,
                iconColor: Colors.amber,
                title: '金幣袋',
                subtitle: '獲得 500 金幣',
                price: '💎 20',
                priceColor: Colors.cyan,
                onTap: () => _buyGold(context, provider),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  void _buyStamina(BuildContext context, PlayerProvider provider) {
    if (provider.data.diamonds >= 30) {
      provider.addDiamonds(-30);
      provider.data.stamina =
          (provider.data.stamina + 30).clamp(0, provider.data.maxStamina + 30);
      provider.refreshStamina();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('體力 +30！'), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('鑽石不足！'), backgroundColor: Colors.red),
      );
    }
  }

  void _buyGold(BuildContext context, PlayerProvider provider) {
    if (provider.data.diamonds >= 20) {
      provider.addDiamonds(-20);
      provider.addGold(500);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('獲得 🪙 500 金幣！'),
            backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('鑽石不足！'), backgroundColor: Colors.red),
      );
    }
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

class _FeaturedBanner extends StatelessWidget {
  final String title;
  final String subtitle;
  final String icon;
  final List<Color> gradient;
  final String? badge;
  final VoidCallback onTap;

  const _FeaturedBanner({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradient,
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          boxShadow: [
            BoxShadow(
              color: gradient.first.withAlpha(60),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // 背景裝飾
            Positioned(
              right: -20,
              bottom: -20,
              child: Text(
                icon,
                style: TextStyle(
                  fontSize: 100,
                  color: Colors.white.withAlpha(25),
                ),
              ),
            ),
            // 內容
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(icon, style: const TextStyle(fontSize: 28)),
                      const SizedBox(width: 8),
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(8),
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
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withAlpha(220),
                      fontSize: 13,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════
// Tab 2: 鑽石商店
// ═══════════════════════════════════════

class _DiamondShopTab extends StatelessWidget {
  const _DiamondShopTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        const SizedBox(height: 4),
        // 鑽石包 2列網格
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.85,
          children: [
            _DiamondPackCard(
              amount: 60,
              price: 'NT\$30',
              color: Colors.blue.shade400,
              onTap: () => _showComingSoon(context),
            ),
            _DiamondPackCard(
              amount: 180,
              price: 'NT\$90',
              color: Colors.blue.shade600,
              onTap: () => _showComingSoon(context),
            ),
            _DiamondPackCard(
              amount: 300,
              price: 'NT\$150',
              badge: '熱銷',
              color: Colors.purple.shade400,
              onTap: () => _showComingSoon(context),
            ),
            _DiamondPackCard(
              amount: 680,
              price: 'NT\$330',
              badge: '超值',
              color: Colors.purple.shade600,
              onTap: () => _showComingSoon(context),
            ),
            _DiamondPackCard(
              amount: 1280,
              price: 'NT\$590',
              color: Colors.amber.shade700,
              onTap: () => _showComingSoon(context),
            ),
            _DiamondPackCard(
              amount: 3280,
              price: 'NT\$1490',
              badge: '至尊',
              color: Colors.amber.shade900,
              onTap: () => _showComingSoon(context),
            ),
          ],
        ),
        const SizedBox(height: 20),
      ],
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

class _DiamondPackCard extends StatelessWidget {
  final int amount;
  final String price;
  final String? badge;
  final Color color;
  final VoidCallback onTap;

  const _DiamondPackCard({
    required this.amount,
    required this.price,
    this.badge,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(color: color.withAlpha(60)),
        ),
        child: Stack(
          children: [
            // Badge
            if (badge != null)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(AppTheme.radiusMedium),
                      bottomLeft: Radius.circular(8),
                    ),
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
              ),
            // 內容
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 鑽石圖示
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [color, color.withAlpha(150)],
                      ),
                      boxShadow: [
                        BoxShadow(
                            color: color.withAlpha(40), blurRadius: 8),
                      ],
                    ),
                    child: const Center(
                      child: Text('💎', style: TextStyle(fontSize: 24)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$amount',
                    style: TextStyle(
                      color: color,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withAlpha(30),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      price,
                      style: TextStyle(
                        color: color,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════
// Tab 3: 素材兌換
// ═══════════════════════════════════════

class _MaterialExchangeTab extends StatelessWidget {
  const _MaterialExchangeTab();

  static const _exchangeItems = [
    _ExchangeData(GameMaterial.commonShard, 5, 3),
    _ExchangeData(GameMaterial.advancedShard, 2, 5),
    _ExchangeData(GameMaterial.rareShard, 1, 8),
    _ExchangeData(GameMaterial.talentScroll, 1, 8),
    _ExchangeData(GameMaterial.skillCore, 1, 10),
    _ExchangeData(GameMaterial.passiveGem, 1, 10),
    _ExchangeData(GameMaterial.expPotion, 1, 6),
    _ExchangeData(GameMaterial.sweepTicket, 1, 8),
    _ExchangeData(GameMaterial.essenceA, 2, 5),
    _ExchangeData(GameMaterial.essenceB, 2, 5),
    _ExchangeData(GameMaterial.essenceC, 2, 5),
    _ExchangeData(GameMaterial.essenceD, 2, 5),
    _ExchangeData(GameMaterial.essenceE, 2, 5),
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (context, provider, _) {
        final dustCount = provider.getMaterialCount(GameMaterial.crystalDust);

        return Column(
          children: [
            // 水晶粉塵餘額
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.bgCard,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                border: Border.all(color: Colors.cyan.withAlpha(40)),
              ),
              child: Row(
                children: [
                  const Text('✨', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  const Text(
                    '水晶粉塵',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '$dustCount',
                    style: const TextStyle(
                      color: Colors.cyan,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 3列素材兌換網格
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 0.75,
                ),
                itemCount: _exchangeItems.length,
                itemBuilder: (context, index) {
                  final item = _exchangeItems[index];
                  final canAfford = dustCount >= item.dustCost;

                  return _MaterialExchangeCard(
                    material: item.material,
                    amount: item.amount,
                    dustCost: item.dustCost,
                    canAfford: canAfford,
                    onTap: canAfford
                        ? () => _exchange(context, provider, item)
                        : null,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  void _exchange(
      BuildContext context, PlayerProvider provider, _ExchangeData item) {
    final dustKey = GameMaterial.crystalDust.name;
    final matKey = item.material.name;
    provider.data.materials[dustKey] =
        (provider.data.materials[dustKey] ?? 0) - item.dustCost;
    provider.data.materials[matKey] =
        (provider.data.materials[matKey] ?? 0) + item.amount;
    provider.notifyAndSave();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text('兌換成功！${item.material.emoji} ${item.material.label} x${item.amount}'),
        backgroundColor: Colors.green,
      ),
    );
  }
}

class _ExchangeData {
  final GameMaterial material;
  final int amount;
  final int dustCost;
  const _ExchangeData(this.material, this.amount, this.dustCost);
}

class _MaterialExchangeCard extends StatelessWidget {
  final GameMaterial material;
  final int amount;
  final int dustCost;
  final bool canAfford;
  final VoidCallback? onTap;

  const _MaterialExchangeCard({
    required this.material,
    required this.amount,
    required this.dustCost,
    required this.canAfford,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(
            color: canAfford
                ? material.iconColor.withAlpha(60)
                : Colors.white.withAlpha(10),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 素材圖示
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: material.iconColor.withAlpha(30),
              ),
              child: Center(
                child: Text(material.emoji,
                    style: const TextStyle(fontSize: 20)),
              ),
            ),
            const SizedBox(height: 6),
            // 名稱
            Text(
              material.label,
              style: TextStyle(
                color: canAfford
                    ? AppTheme.textPrimary
                    : AppTheme.textSecondary.withAlpha(100),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            // 數量
            Text(
              'x$amount',
              style: TextStyle(
                color: canAfford
                    ? material.iconColor
                    : AppTheme.textSecondary.withAlpha(60),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            // 價格
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: canAfford
                    ? Colors.cyan.withAlpha(20)
                    : Colors.grey.withAlpha(10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '✨ $dustCost',
                style: TextStyle(
                  color: canAfford ? Colors.cyan : Colors.grey,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════
// 共用元件
// ═══════════════════════════════════════

class _CurrencyChip extends StatelessWidget {
  final String assetPath;
  final String fallback;
  final int value;

  const _CurrencyChip({
    required this.assetPath,
    required this.fallback,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GameIcon(assetPath: assetPath, fallbackEmoji: fallback, size: 14),
          const SizedBox(width: 3),
          Text(
            _format(value),
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _format(int n) {
    if (n >= 10000) return '${(n / 1000).toStringAsFixed(1)}k';
    return n.toString();
  }
}

class _DustChip extends StatelessWidget {
  final int value;
  const _DustChip({required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('✨', style: TextStyle(fontSize: 12)),
          const SizedBox(width: 3),
          Text(
            '$value',
            style: const TextStyle(
              color: Colors.cyan,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickBuyCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String price;
  final Color priceColor;
  final VoidCallback onTap;

  const _QuickBuyCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.priceColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(color: iconColor.withAlpha(40)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: iconColor.withAlpha(30),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: priceColor.withAlpha(30),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: priceColor.withAlpha(100)),
              ),
              child: Text(
                price,
                style: TextStyle(
                  color: priceColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
