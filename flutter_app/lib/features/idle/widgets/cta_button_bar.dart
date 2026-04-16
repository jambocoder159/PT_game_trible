import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../core/widgets/pressable_scale.dart';

/// 三個 CTA 按鈕：消方塊 | 轉換食材 | 製作甜點
class CtaButtonBar extends StatelessWidget {
  final VoidCallback onMatchBlocks;
  final VoidCallback onConvertIngredient;
  final VoidCallback onCraftDessert;

  const CtaButtonBar({
    super.key,
    required this.onMatchBlocks,
    required this.onConvertIngredient,
    required this.onCraftDessert,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: _CtaButton(
              label: '消方塊',
              emoji: '🧩',
              color: AppTheme.accentPrimary,
              onTap: onMatchBlocks,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _CtaButton(
              label: '轉換食材',
              emoji: '🧪',
              color: const Color(0xFF6BAF5B),
              onTap: onConvertIngredient,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _CtaButton(
              label: '製作甜點',
              emoji: '🧁',
              color: const Color(0xFFF0B0C8),
              onTap: onCraftDessert,
            ),
          ),
        ],
      ),
    );
  }
}

class _CtaButton extends StatelessWidget {
  final String label;
  final String emoji;
  final Color color;
  final VoidCallback onTap;

  const _CtaButton({
    required this.label,
    required this.emoji,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withAlpha(25),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withAlpha(100), width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: AppTheme.fontTitleLg)),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: AppTheme.fontLabelLg,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
