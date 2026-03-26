/// 稀有度邊框/光暈效果 Widget
/// 根據角色稀有度顯示不同顏色的邊框和光暈
import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../models/cat_agent.dart';

class RarityFrame extends StatelessWidget {
  final AgentRarity rarity;
  final double size;
  final Widget child;
  final bool isLocked;

  const RarityFrame({
    super.key,
    required this.rarity,
    required this.size,
    required this.child,
    this.isLocked = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.rarityGradient(rarity.display);
    final glowColor = AppTheme.rarityColor(rarity.display);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        gradient: isLocked
            ? null
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: colors,
              ),
        color: isLocked ? Colors.grey.shade800 : null,
        boxShadow: isLocked
            ? null
            : [
                BoxShadow(
                  color: glowColor.withAlpha(80),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
      ),
      padding: const EdgeInsets.all(2),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium - 2),
        child: child,
      ),
    );
  }
}
