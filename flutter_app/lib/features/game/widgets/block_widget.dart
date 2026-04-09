import 'package:flutter/material.dart';
import '../../../config/image_assets.dart';
import '../../../config/theme.dart';
import '../../../core/models/block.dart';

/// 單一方塊的視覺元件 — 含消除動畫（膨脹 pop + 淡出）
/// 粒子飛射效果由上層 BoardAttackEffect 負責
class BlockWidget extends StatefulWidget {
  final Block block;
  final double size;
  final int combo;

  const BlockWidget({
    super.key,
    required this.block,
    this.size = AppTheme.blockSize,
    this.combo = 0,
  });

  @override
  State<BlockWidget> createState() => _BlockWidgetState();
}

class _BlockWidgetState extends State<BlockWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _elimController;
  late Animation<double> _scaleAnim;
  late Animation<double> _opacityAnim;

  bool _wasEliminating = false;

  @override
  void initState() {
    super.initState();
    _elimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    // 快速膨脹然後消失（pop 效果）
    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.35), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.35, end: 0.0), weight: 80),
    ]).animate(CurvedAnimation(
      parent: _elimController,
      curve: Curves.easeOutCubic,
    ));

    _opacityAnim = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _elimController,
        curve: const Interval(0.25, 1.0, curve: Curves.easeIn),
      ),
    );

    if (widget.block.isEliminating) {
      _wasEliminating = true;
      _elimController.forward();
    }
  }

  @override
  void didUpdateWidget(covariant BlockWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.block.isEliminating && !_wasEliminating) {
      _wasEliminating = true;
      _elimController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _elimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color =
        widget.block.isBlackened ? Colors.grey.shade800 : widget.block.color.color;
    final darkerColor = Color.lerp(color, Colors.black, 0.3)!;
    final size = widget.size;

    if (_wasEliminating) {
      return AnimatedBuilder(
        animation: _elimController,
        builder: (context, child) {
          return Center(
            child: Opacity(
              opacity: _opacityAnim.value,
              child: Transform.scale(
                scale: _scaleAnim.value,
                child: child!,
              ),
            ),
          );
        },
        child: _buildBlockContainer(color, darkerColor, size),
      );
    }

    return _buildBlockContainer(color, darkerColor, size);
  }

  Widget _buildBlockContainer(Color color, Color darkerColor, double size) {
    final imagePath = ImageAssets.blockImage(
      widget.block.color,
      dark: widget.block.isBlackened,
    );

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusBlock),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(80),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusBlock),
        child: Image.asset(
          imagePath,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildFallbackBlock(color, darkerColor, size),
        ),
      ),
    );
  }

  /// 圖片載入失敗時的 fallback（原始漸層樣式）
  Widget _buildFallbackBlock(Color color, Color darkerColor, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, darkerColor],
        ),
      ),
      child: Center(
        child: Text(
          widget.block.isBlackened ? '✕' : widget.block.color.symbol,
          style: TextStyle(
            fontSize: size * 0.4,
            color: Colors.white.withAlpha(200),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

