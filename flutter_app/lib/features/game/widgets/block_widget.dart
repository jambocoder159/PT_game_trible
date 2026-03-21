import 'dart:math';
import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../core/models/block.dart';

/// 單一方塊的視覺元件 — 含消除動畫（縮放 + 旋轉 + 閃光）
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
  late Animation<double> _rotateAnim;
  late Animation<double> _opacityAnim;
  late Animation<double> _glowAnim;

  bool _wasEliminating = false;

  @override
  void initState() {
    super.initState();
    _elimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.2), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 0.0), weight: 75),
    ]).animate(CurvedAnimation(
      parent: _elimController,
      curve: Curves.easeInBack,
    ));

    _rotateAnim = Tween<double>(begin: 0, end: 0.3).animate(
      CurvedAnimation(parent: _elimController, curve: Curves.easeIn),
    );

    _opacityAnim = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _elimController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );

    _glowAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: 1.0), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 70),
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
    final size = widget.size;

    if (_wasEliminating) {
      return AnimatedBuilder(
        animation: _elimController,
        builder: (context, child) {
          return Opacity(
            opacity: _opacityAnim.value,
            child: Transform.scale(
              scale: _scaleAnim.value,
              child: Transform.rotate(
                angle: _rotateAnim.value,
                child: _buildBlockContainer(color, darkerColor, size,
                    glowIntensity: _glowAnim.value),
              ),
            ),
          );
        },
      );
    }

    return _buildBlockContainer(color, darkerColor, size);
  }

  Widget _buildBlockContainer(Color color, Color darkerColor, double size,
      {double glowIntensity = 0}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, darkerColor],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusBlock),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(80),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
          if (glowIntensity > 0)
            BoxShadow(
              color: Colors.white.withAlpha((180 * glowIntensity).round()),
              blurRadius: 20 * glowIntensity,
              spreadRadius: 4 * glowIntensity,
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
