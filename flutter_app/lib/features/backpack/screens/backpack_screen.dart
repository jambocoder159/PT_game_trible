/// 素材背包畫面
/// 分類顯示所有素材，支援篩選和詳情查看
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../core/models/material.dart';
import '../../agents/providers/player_provider.dart';

class BackpackScreen extends StatefulWidget {
  const BackpackScreen({super.key});

  @override
  State<BackpackScreen> createState() => _BackpackScreenState();
}

class _BackpackScreenState extends State<BackpackScreen> {
  MaterialCategory? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(
        title: const Text('素材背包'),
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
      body: Consumer<PlayerProvider>(
        builder: (context, provider, _) {
          return Column(
            children: [
              // 分類 Tab
              _CategoryTabs(
                selected: _selectedCategory,
                onSelect: (cat) => setState(() {
                  _selectedCategory = _selectedCategory == cat ? null : cat;
                }),
                provider: provider,
              ),

              // 素材網格
              Expanded(
                child: _MaterialGrid(
                  category: _selectedCategory,
                  provider: provider,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─── 分類 Tab ───

class _CategoryTabs extends StatelessWidget {
  final MaterialCategory? selected;
  final ValueChanged<MaterialCategory> onSelect;
  final PlayerProvider provider;

  const _CategoryTabs({
    required this.selected,
    required this.onSelect,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary.withAlpha(120),
      ),
      child: Row(
        children: [
          // 全部
          _TabChip(
            label: '全部',
            emoji: '📋',
            isSelected: selected == null,
            count: _totalCount(),
            onTap: () => onSelect(selected ?? MaterialCategory.shard),
          ),
          const SizedBox(width: 6),
          ...MaterialCategory.values.map((cat) {
            final count = _categoryCount(cat);
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: _TabChip(
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
      if (m.category == cat) {
        total += provider.getMaterialCount(m);
      }
    }
    return total;
  }
}

class _TabChip extends StatelessWidget {
  final String label;
  final String emoji;
  final bool isSelected;
  final int count;
  final VoidCallback onTap;

  const _TabChip({
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.accentPrimary.withAlpha(40)
              : AppTheme.bgCard.withAlpha(120),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppTheme.accentPrimary.withAlpha(150)
                : Colors.white.withAlpha(20),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 3),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? AppTheme.accentPrimary
                    : AppTheme.textSecondary,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 3),
              Text(
                '$count',
                style: TextStyle(
                  color: isSelected
                      ? AppTheme.accentPrimary
                      : AppTheme.textSecondary.withAlpha(150),
                  fontSize: 10,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── 素材網格 ───

class _MaterialGrid extends StatelessWidget {
  final MaterialCategory? category;
  final PlayerProvider provider;

  const _MaterialGrid({
    required this.category,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final materials = GameMaterial.values
        .where((m) => category == null || m.category == category)
        .toList();

    // 分成有數量和沒數量的
    final owned = materials.where((m) => provider.getMaterialCount(m) > 0).toList();
    final unowned = materials.where((m) => provider.getMaterialCount(m) == 0).toList();
    final sorted = [...owned, ...unowned];

    if (sorted.isEmpty) {
      return const Center(
        child: Text(
          '此分類暫無素材',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.75,
      ),
      itemCount: sorted.length,
      itemBuilder: (context, index) {
        final material = sorted[index];
        final count = provider.getMaterialCount(material);
        return _MaterialCell(
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

class _MaterialCell extends StatelessWidget {
  final GameMaterial material;
  final int count;
  final VoidCallback onTap;

  const _MaterialCell({
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
              ? AppTheme.bgCard.withAlpha(80)
              : AppTheme.bgCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isEmpty
                ? Colors.white.withAlpha(10)
                : rarityColor.withAlpha(100),
            width: isEmpty ? 0.5 : 1.5,
          ),
          boxShadow: isEmpty
              ? null
              : [
                  BoxShadow(
                    color: rarityColor.withAlpha(30),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 圖示
            Text(
              material.emoji,
              style: TextStyle(
                fontSize: 26,
                color: isEmpty ? Colors.white.withAlpha(80) : null,
              ),
            ),
            const SizedBox(height: 2),
            // 名稱
            Text(
              material.label,
              style: TextStyle(
                color: isEmpty
                    ? AppTheme.textSecondary.withAlpha(100)
                    : AppTheme.textPrimary,
                fontSize: 9,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            // 數量
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: isEmpty
                    ? Colors.transparent
                    : rarityColor.withAlpha(30),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                isEmpty ? '-' : 'x$count',
                style: TextStyle(
                  color: isEmpty
                      ? AppTheme.textSecondary.withAlpha(80)
                      : rarityColor,
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

// ─── 素材詳情 ───

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
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 拉條
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // 圖示
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: rarityColor.withAlpha(30),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: rarityColor.withAlpha(120), width: 2),
              ),
              child: Center(
                child: Text(material.emoji, style: const TextStyle(fontSize: 36)),
              ),
            ),
            const SizedBox(height: 12),

            // 名稱
            Text(
              material.label,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),

            // 稀有度 + 分類
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: rarityColor.withAlpha(30),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: rarityColor.withAlpha(80)),
                  ),
                  child: Text(
                    rarityLabel,
                    style: TextStyle(
                      color: rarityColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(10),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${material.category.emoji} ${material.category.label}',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 說明
            Text(
              material.description,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // 擁有數量
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.bgCard,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withAlpha(20)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '持有數量',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '$count',
                    style: TextStyle(
                      color: count > 0 ? AppTheme.textPrimary : AppTheme.textSecondary,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
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
