import 'dart:math';
import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../core/models/block.dart';

/// 單一方塊的視覺元件 — 含消除動畫（膨脹碎裂 + 粒子四散）
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

  bool _wasEliminating = false;

  // 粒子資料（消除時產生）
  late List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    _elimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    // 快速膨脹然後消失（Candy Crush 風格 pop）
    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 0.0), weight: 75),
    ]).animate(CurvedAnimation(
      parent: _elimController,
      curve: Curves.easeOutCubic,
    ));

    _opacityAnim = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _elimController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
      ),
    );

    _particles = _generateParticles();

    if (widget.block.isEliminating) {
      _wasEliminating = true;
      _elimController.forward();
    }
  }

  List<_Particle> _generateParticles() {
    final rng = Random();
    return List.generate(8, (i) {
      final angle = (i / 8) * 2 * pi + rng.nextDouble() * 0.5;
      final speed = 1.5 + rng.nextDouble() * 1.5;
      final size = 0.12 + rng.nextDouble() * 0.15;
      return _Particle(angle: angle, speed: speed, sizeFactor: size);
    });
  }

  @override
  void didUpdateWidget(covariant BlockWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.block.isEliminating && !_wasEliminating) {
      _wasEliminating = true;
      _particles = _generateParticles();
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
          final progress = _elimController.value;
          return LayoutBuilder(
            builder: (context, constraints) {
              final cx = constraints.maxWidth / 2;
              final cy = constraints.maxHeight / 2;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  // 粒子碎片（方塊顏色的小方塊四散）
                  if (progress > 0.15)
                    ..._particles.map((p) {
                      final t =
                          ((progress - 0.15) / 0.85).clamp(0.0, 1.0);
                      final dx = cos(p.angle) * p.speed * size * t;
                      final dy = sin(p.angle) * p.speed * size * t;
                      final pOpacity = (1.0 - t).clamp(0.0, 1.0);
                      final pScale = (1.0 - t * 0.6).clamp(0.0, 1.0);
                      final pSize = size * p.sizeFactor * pScale;

                      return Positioned(
                        left: cx - pSize / 2 + dx,
                        top: cy - pSize / 2 + dy,
                        child: Opacity(
                          opacity: pOpacity,
                          child: Container(
                            width: pSize,
                            height: pSize,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(2),
                              boxShadow: [
                                BoxShadow(
                                  color: color.withAlpha(
                                      (120 * pOpacity).round()),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  // 主方塊（膨脹後消失）
                  Positioned(
                    left: cx - size / 2,
                    top: cy - size / 2,
                    child: Opacity(
                      opacity: _opacityAnim.value,
                      child: Transform.scale(
                        scale: _scaleAnim.value,
                        child: _buildBlockContainer(color, darkerColor, size),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      );
    }

    return _buildBlockContainer(color, darkerColor, size);
  }

  Widget _buildBlockContainer(Color color, Color darkerColor, double size) {
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

/// 粒子碎片資料
class _Particle {
  final double angle;
  final double speed;
  final double sizeFactor;

  const _Particle({
    required this.angle,
    required this.speed,
    required this.sizeFactor,
  });
}
