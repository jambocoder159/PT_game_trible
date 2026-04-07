import 'package:flutter/material.dart';
import '../../../config/theme.dart';

/// 底部遊戲導航列
class GameBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int>? onTap;
  /// 需要顯示紅點的 Tab index 集合
  final Set<int> badges;
  /// 教學高亮的 Tab index（-1 表示無）
  final int highlightTabIndex;
  /// 教學高亮的 GlobalKey
  final GlobalKey? highlightTabKey;

  const GameBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.badges = const {},
    this.highlightTabIndex = -1,
    this.highlightTabKey,
  });

  static const _items = [
    _NavItem(icon: Icons.inventory_2_rounded, label: '背包'),
    _NavItem(icon: Icons.pets, label: '角色'),
    _NavItem(icon: Icons.home_rounded, label: '放置'),
    _NavItem(icon: Icons.map_rounded, label: '闖關'),
    _NavItem(icon: Icons.shopping_bag_rounded, label: '商店'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary,
        border: Border(
          top: BorderSide(
            color: AppTheme.accentPrimary.withAlpha(60),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(80),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: List.generate(_items.length, (index) {
          final item = _items[index];
          final isSelected = index == currentIndex;

          Widget tab = Expanded(
            child: GestureDetector(
              onTap: onTap != null ? () => onTap!(index) : null,
              behavior: HitTestBehavior.opaque,
              child: _NavBarItem(
                icon: item.icon,
                label: item.label,
                isSelected: isSelected,
                showBadge: badges.contains(index),
              ),
            ),
          );

          // 教學高亮：包上 KeyedSubtree
          if (index == highlightTabIndex && highlightTabKey != null) {
            tab = KeyedSubtree(key: highlightTabKey!, child: tab);
          }

          return tab;
        }),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final bool showBadge;

  const _NavBarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    this.showBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected
        ? AppTheme.accentSecondary
        : AppTheme.textSecondary.withAlpha(150);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.accentSecondary.withAlpha(30)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            // 紅點 Badge
            if (showBadge)
              Positioned(
                right: 8,
                top: 0,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF4444),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: AppTheme.fontLabelLg,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
