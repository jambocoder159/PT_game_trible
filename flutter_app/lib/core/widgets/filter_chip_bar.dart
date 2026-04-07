/// 通用篩選條 Widget
/// 水平滾動的 Chip 列表，支持單選/多選
import 'package:flutter/material.dart';
import '../../config/theme.dart';

class FilterChipBar<T> extends StatelessWidget {
  final List<FilterChipItem<T>> items;
  final T? selectedValue;
  final ValueChanged<T?> onSelected;
  final String? allLabel;

  const FilterChipBar({
    super.key,
    required this.items,
    required this.selectedValue,
    required this.onSelected,
    this.allLabel,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          if (allLabel != null) ...[
            _buildChip(
              label: allLabel!,
              isSelected: selectedValue == null,
              onTap: () => onSelected(null),
            ),
            const SizedBox(width: 6),
          ],
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(right: 6),
                child: _buildChip(
                  label: item.label,
                  emoji: item.emoji,
                  color: item.color,
                  isSelected: selectedValue == item.value,
                  onTap: () => onSelected(
                    selectedValue == item.value ? null : item.value,
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildChip({
    required String label,
    String? emoji,
    Color? color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? (color ?? AppTheme.accentPrimary).withAlpha(50)
              : AppTheme.bgCard.withAlpha(150),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? (color ?? AppTheme.accentPrimary).withAlpha(180)
                : AppTheme.accentSecondary.withAlpha(30),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (emoji != null) ...[
              Text(emoji, style: const TextStyle(fontSize: AppTheme.fontBodyLg)),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? (color ?? AppTheme.accentPrimary)
                    : AppTheme.textSecondary,
                fontSize: AppTheme.fontBodyMd,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FilterChipItem<T> {
  final T value;
  final String label;
  final String? emoji;
  final Color? color;

  const FilterChipItem({
    required this.value,
    required this.label,
    this.emoji,
    this.color,
  });
}
