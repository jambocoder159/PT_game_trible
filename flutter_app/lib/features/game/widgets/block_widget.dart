import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../core/models/block.dart';

/// 單一方塊的視覺元件
class BlockWidget extends StatelessWidget {
  final Block block;
  final double size;
  final bool isSelected;

  const BlockWidget({
    super.key,
    required this.block,
    this.size = AppTheme.blockSize,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = block.isBlackened ? Colors.grey.shade800 : block.color.color;
    final darkerColor = Color.lerp(color, Colors.black, 0.3)!;

    return AnimatedOpacity(
      opacity: block.isEliminating ? 0.0 : 1.0,
      duration: AppTheme.animEliminate,
      child: AnimatedScale(
        scale: block.isEliminating ? 0.3 : (isSelected ? 1.1 : 1.0),
        duration: AppTheme.animEliminate,
        curve: Curves.easeInBack,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color, darkerColor],
            ),
            borderRadius: BorderRadius.circular(AppTheme.radiusBlock),
            border: isSelected
                ? Border.all(color: Colors.white, width: 2.5)
                : null,
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? Colors.white.withAlpha(150)
                    : color.withAlpha(80),
                blurRadius: isSelected ? 12 : 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Center(
            child: Text(
              block.isBlackened ? '✕' : block.color.symbol,
              style: TextStyle(
                fontSize: size * 0.4,
                color: Colors.white.withAlpha(200),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
