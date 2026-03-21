import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../core/models/block.dart';

/// 單一方塊的視覺元件 — 含消除動畫（縮放 + 閃白 + 色彩光暈）
class BlockWidget extends StatefulWidget {
  final Block block;
  final double size;

  const BlockWidget({
    super.key,
    required this.block,
    this.size = AppTheme.blockSize,
  });

  @override
  State<BlockWidget> createState() => _BlockWidgetState();
}

class _BlockWidgetState extends State<BlockWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _elimController;
  late Animation<double> _scaleAnim;
  late Animation<double> _opacityAnim;
  late Animation<double> _flashAnim;
  late Animation<double> _glowAnim;

  bool _wasEliminating = false;

  @override
  void initState() {
    super.initState();
    _elimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    // 先膨脹再縮小消失
    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.25), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.25, end: 0.0), weight: 80),
    ]).animate(CurvedAnimation(
      parent: _elimController,
      curve: Curves.easeInBack,
    ));

    // 整體淡出
    _opacityAnim = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _elimController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );

    // 閃白：快速亮起再消退（疊加在方塊上的白色遮罩）
    _flashAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.8), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 0.8, end: 0.0), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.0), weight: 50),
    ]).animate(_elimController);

    // 方塊自身顏色的外發光
    _glowAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.0), weight: 30),
    ]).animate(_elimController);

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
    final lighterColor = Color.lerp(color, Colors.white, 0.3)!;
    final size = widget.size;

    if (_wasEliminating) {
      return AnimatedBuilder(
        animation: _elimController,
        builder: (context, child) {
          return Opacity(
            opacity: _opacityAnim.value,
            child: Transform.scale(
              scale: _scaleAnim.value,
              child: _buildBlockContainer(
                color, darkerColor, lighterColor, size,
                glowIntensity: _glowAnim.value,
                flashIntensity: _flashAnim.value,
              ),
            ),
          );
        },
      );
    }

    return _buildBlockContainer(color, darkerColor, lighterColor, size);
  }

  Widget _buildBlockContainer(
    Color color, Color darkerColor, Color lighterColor, double size, {
    double glowIntensity = 0,
    double flashIntensity = 0,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(color, Colors.white, flashIntensity * 0.6)!,
            Color.lerp(darkerColor, Colors.white, flashIntensity * 0.4)!,
          ],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusBlock),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(80),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
          // 用方塊自身顏色發光，而非白色
          if (glowIntensity > 0)
            BoxShadow(
              color: lighterColor.withAlpha((200 * glowIntensity).round()),
              blurRadius: 24 * glowIntensity,
              spreadRadius: 6 * glowIntensity,
            ),
        ],
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
