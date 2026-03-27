/// 素材背包畫面 — 全新設計
/// 3列大格子 + 橫向滾動藥丸式分類 + 排序功能
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../config/image_assets.dart';
import '../../../config/theme.dart';
import '../../../core/models/material.dart';
import '../../agents/providers/player_provider.dart';

// ─── 排序方式 ───
enum MaterialSortBy { rarity, count, category }

class BackpackScreen extends StatefulWidget {
  const BackpackScreen({super.key});

  @override
  State<BackpackScreen> createState() => _BackpackScreenState();
}

class _BackpackScreenState extends State<BackpackScreen> {
  MaterialCategory? _selectedCategory;
  MaterialSortBy _sortBy = MaterialSortBy.rarity;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('素材背包'),
        backgroundColor: AppTheme.bgSecondary,
        actions: [
          // 排序按鈕
          PopupMenuButton<MaterialSortBy>(
            icon: const Icon(Icons.sort, size: 20),
            color: AppTheme.bgSecondary,
            onSelected: (v) => setState(() => _sortBy = v),
            itemBuilder: (_) => [
              _sortMenuItem(MaterialSortBy.rarity, '依稀有度'),
              _sortMenuItem(MaterialSortBy.count, '依數量'),
              _sortMenuItem(MaterialSortBy.category, '依分類'),
            ],
          ),
          // 貨幣
          Consumer<PlayerProvider>(
            builder: (_, p, __) => Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Row(
                children: [
                  _CurrencyBadge(
                    iconPath: ImageAssets.coin,
                    fallback: '🪙',
                    amount: p.data.gold,
                  ),
                  const SizedBox(width: 8),
                  _CurrencyBadge(
                    iconPath: ImageAssets.diamond,
                    fallback: '💎',
                    amount: p.data.diamonds,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Consumer<PlayerProvider>(
        builder: (context, provider, _) {
          return Column(
            children: [
              // ─── 分類標籤（橫向滾動藥丸） ───
              _CategoryTabBar(
                selected: _selectedCategory,
                onSelect: (cat) => setState(() {
                  _selectedCategory = _selectedCategory == cat ? null : cat;
                }),
                provider: provider,
              ),

              // ─── 排序指示器 ───
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                child: Row(
                  children: [
                    Icon(Icons.sort, size: 14,
                        color: AppTheme.textSecondary.withAlpha(120)),
                    const SizedBox(width: 4),
                    Text(
                      _sortLabel(),
                      style: TextStyle(
                        color: AppTheme.textSecondary.withAlpha(150),
                        fontSize: 11,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${_getFilteredMaterials(provider).where((e) => e.$2 > 0).length} 種素材',
                      style: TextStyle(
                        color: AppTheme.textSecondary.withAlpha(120),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),

              // ─── 素材網格 ───
              Expanded(
                child: _buildGrid(provider),
              ),
            ],
          );
        },
      ),
    );
  }

  PopupMenuItem<MaterialSortBy> _sortMenuItem(
      MaterialSortBy value, String label) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          if (_sortBy == value)
            const Icon(Icons.check, size: 16, color: AppTheme.accentSecondary)
          else
            const SizedBox(width: 16),
          const SizedBox(width: 8),
          Text(label,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14)),
        ],
      ),
    );
  }

  String _sortLabel() {
    switch (_sortBy) {
      case MaterialSortBy.rarity:
        return '依稀有度排序';
      case MaterialSortBy.count:
        return '依數量排序';
      case MaterialSortBy.category:
        return '依分類排序';
    }
  }

  List<(GameMaterial, int)> _getFilteredMaterials(PlayerProvider provider) {
    var materials = GameMaterial.values
        .where((m) => _selectedCategory == null || m.category == _selectedCategory)
        .map((m) => (m, provider.getMaterialCount(m)))
        .toList();

    // 排序
    materials.sort((a, b) {
      // 有數量的優先
      if ((a.$2 > 0) != (b.$2 > 0)) return a.$2 > 0 ? -1 : 1;
      switch (_sortBy) {
        case MaterialSortBy.rarity:
          return b.$1.rarity.compareTo(a.$1.rarity);
        case MaterialSortBy.count:
          return b.$2.compareTo(a.$2);
        case MaterialSortBy.category:
          final catCmp = a.$1.category.index.compareTo(b.$1.category.index);
          if (catCmp != 0) return catCmp;
          return b.$1.rarity.compareTo(a.$1.rarity);
      }
    });

    return materials;
  }

  Widget _buildGrid(PlayerProvider provider) {
    final materials = _getFilteredMaterials(provider);

    if (materials.isEmpty) {
      return _EmptyState(category: _selectedCategory);
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.82,
      ),
      itemCount: materials.length,
      itemBuilder: (context, index) {
        final (material, count) = materials[index];
        return _MaterialCard(
          material: material,
          count: count,
          onTap: () => _showDetail(context, material, count),
        );
      },
    );
  }

  void _showDetail(BuildContext context, GameMaterial material, int count) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _MaterialDetailSheet(
        material: material,
        count: count,
      ),
    );
  }
}

// ═══════════════════════════════════════
// 分類標籤欄
// ═══════════════════════════════════════

class _CategoryTabBar extends StatelessWidget {
  final MaterialCategory? selected;
  final ValueChanged<MaterialCategory> onSelect;
  final PlayerProvider provider;

  const _CategoryTabBar({
    required this.selected,
    required this.onSelect,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary.withAlpha(120),
        border: Border(
          bottom: BorderSide(color: AppTheme.accentSecondary.withAlpha(20)),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            // 全部
            _CategoryPill(
              label: '全部',
              emoji: '📋',
              isSelected: selected == null,
              count: _totalCount(),
              onTap: () {
                // 選中某分類時，點「全部」取消篩選
                if (selected != null) onSelect(selected!);
              },
            ),
            const SizedBox(width: 8),
            ...MaterialCategory.values.map((cat) {
              final count = _categoryCount(cat);
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _CategoryPill(
                  label: cat.label,
                  emoji: cat.emoji,
                  isSelected: selected == cat,
                  count: count,
                  onTap: () => onSelect(cat),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  int _totalCount() {
    int total = 0;
    for (final m in GameMaterial.values) {
      total += provider.getMaterialCount(m);
    }
    return total;
  }

  int _categoryCount(MaterialCategory cat) {
    int total = 0;
    for (final m in GameMaterial.values) {
      if (m.category == cat) total += provider.getMaterialCount(m);
    }
    return total;
  }
}

class _CategoryPill extends StatelessWidget {
  final String label;
  final String emoji;
  final bool isSelected;
  final int count;
  final VoidCallback onTap;

  const _CategoryPill({
    required this.label,
    required this.emoji,
    required this.isSelected,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.accentPrimary.withAlpha(50)
              : AppTheme.bgCard.withAlpha(120),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppTheme.accentPrimary.withAlpha(160)
                : AppTheme.accentSecondary.withAlpha(25),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.accentPrimary.withAlpha(30),
                    blurRadius: 8,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? AppTheme.textPrimary
                    : AppTheme.textSecondary,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.accentPrimary.withAlpha(80)
                      : AppTheme.accentSecondary.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: isSelected
                        ? AppTheme.textPrimary
                        : AppTheme.textSecondary.withAlpha(150),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════
// 素材卡片（3列）
// ═══════════════════════════════════════

class _MaterialCard extends StatelessWidget {
  final GameMaterial material;
  final int count;
  final VoidCallback onTap;

  const _MaterialCard({
    required this.material,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isEmpty = count == 0;
    final rarityColor = _rarityColor(material.rarity);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isEmpty
              ? AppTheme.bgCard.withAlpha(60)
              : AppTheme.bgCard,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(
            color: isEmpty
                ? AppTheme.accentSecondary.withAlpha(15)
                : rarityColor.withAlpha(80),
            width: isEmpty ? 0.5 : 1.5,
          ),
          boxShadow: isEmpty
              ? null
              : [
                  BoxShadow(
                    color: rarityColor.withAlpha(25),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 6),
            // 圖標（大圓形 + 光暈）
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isEmpty
                      ? [
                          Colors.grey.withAlpha(30),
                          Colors.grey.withAlpha(15),
                        ]
                      : [
                          material.iconColor.withAlpha(50),
                          material.iconColor.withAlpha(25),
                        ],
                ),
                border: Border.all(
                  color: isEmpty
                      ? AppTheme.accentSecondary.withAlpha(20)
                      : material.iconColor.withAlpha(100),
                  width: 2,
                ),
                boxShadow: isEmpty
                    ? null
                    : [
                        BoxShadow(
                          color: material.iconColor.withAlpha(40),
                          blurRadius: 10,
                        ),
                      ],
              ),
              child: Icon(
                material.iconData,
                size: 24,
                color: isEmpty
                    ? AppTheme.accentSecondary.withAlpha(60)
                    : material.iconColor,
              ),
            ),
            const SizedBox(height: 6),

            // 名稱
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                material.label,
                style: TextStyle(
                  color: isEmpty
                      ? AppTheme.textSecondary.withAlpha(80)
                      : AppTheme.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 4),

            // 數量（帶稀有度色帶）
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: isEmpty
                    ? Colors.transparent
                    : rarityColor.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isEmpty ? '-' : 'x$count',
                style: TextStyle(
                  color: isEmpty
                      ? AppTheme.textSecondary.withAlpha(60)
                      : rarityColor,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 4),

            // 稀有度底邊條
            if (!isEmpty)
              Container(
                height: 3,
                margin: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      rarityColor.withAlpha(0),
                      rarityColor.withAlpha(120),
                      rarityColor.withAlpha(0),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _rarityColor(int rarity) {
    switch (rarity) {
      case 3:
        return const Color(0xFFBF6FFF);
      case 2:
        return const Color(0xFF4FAAFF);
      default:
        return const Color(0xFFAABBCC);
    }
  }
}

// ═══════════════════════════════════════
// 空狀態
// ═══════════════════════════════════════

class _EmptyState extends StatelessWidget {
  final MaterialCategory? category;

  const _EmptyState({this.category});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 56,
            color: AppTheme.textSecondary.withAlpha(60),
          ),
          const SizedBox(height: 12),
          Text(
            category != null ? '${category!.label} 分類暫無素材' : '背包空空如也',
            style: TextStyle(
              color: AppTheme.textSecondary.withAlpha(120),
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '通關闘卡來獲得素材吧！',
            style: TextStyle(
              color: AppTheme.textSecondary.withAlpha(80),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════
// 素材詳情 BottomSheet
// ═══════════════════════════════════════

class _MaterialDetailSheet extends StatelessWidget {
  final GameMaterial material;
  final int count;

  const _MaterialDetailSheet({
    required this.material,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final rarityColor = _rarityColor(material.rarity);
    final rarityLabel = _rarityLabel(material.rarity);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 拉條
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.accentSecondary.withAlpha(60),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // 圖標（更大）
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    material.iconColor.withAlpha(50),
                    rarityColor.withAlpha(30),
                  ],
                ),
                border: Border.all(color: rarityColor.withAlpha(120), width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: material.iconColor.withAlpha(50),
                    blurRadius: 16,
                    spreadRadius: 3,
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  material.iconData,
                  size: 40,
                  color: material.iconColor,
                ),
              ),
            ),
            const SizedBox(height: 14),

            // 名稱
            Text(
              material.label,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),

            // 稀有度 + 分類
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _InfoTag(
                  label: rarityLabel,
                  color: rarityColor,
                  filled: true,
                ),
                const SizedBox(width: 8),
                _InfoTag(
                  label: '${material.category.emoji} ${material.category.label}',
                  color: AppTheme.textSecondary,
                  filled: false,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 說明
            Text(
              material.description,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // 持有數量（醒目顯示）
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.bgCard,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                border: Border.all(color: AppTheme.accentSecondary.withAlpha(25)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '持有數量',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    '$count',
                    style: TextStyle(
                      color: count > 0
                          ? AppTheme.textPrimary
                          : AppTheme.textSecondary,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 獲取途徑提示
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.accentSecondary.withAlpha(10),
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 16,
                      color: AppTheme.textSecondary.withAlpha(100)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '通過闘關模式通關可獲得此素材',
                      style: TextStyle(
                        color: AppTheme.textSecondary.withAlpha(120),
                        fontSize: 12,
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

  Color _rarityColor(int rarity) {
    switch (rarity) {
      case 3:
        return const Color(0xFFBF6FFF);
      case 2:
        return const Color(0xFF4FAAFF);
      default:
        return const Color(0xFFAABBCC);
    }
  }

  String _rarityLabel(int rarity) {
    switch (rarity) {
      case 3:
        return '★★★ 稀有';
      case 2:
        return '★★ 進階';
      default:
        return '★ 普通';
    }
  }
}

class _InfoTag extends StatelessWidget {
  final String label;
  final Color color;
  final bool filled;

  const _InfoTag({
    required this.label,
    required this.color,
    required this.filled,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: filled ? color.withAlpha(30) : AppTheme.accentSecondary.withAlpha(15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: filled ? color.withAlpha(80) : AppTheme.accentSecondary.withAlpha(30),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: filled ? color : AppTheme.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════
// 貨幣徽章
// ═══════════════════════════════════════

class _CurrencyBadge extends StatelessWidget {
  final String iconPath;
  final String fallback;
  final int amount;

  const _CurrencyBadge({
    required this.iconPath,
    required this.fallback,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GameIcon(assetPath: iconPath, fallbackEmoji: fallback, size: 16),
        const SizedBox(width: 3),
        Text(
          '$amount',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
