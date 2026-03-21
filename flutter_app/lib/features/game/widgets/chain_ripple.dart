import 'package:flutter/material.dart';

/// 連鎖消除時的放射狀波紋效果 — CustomPainter 繪製
class ChainRipple extends StatefulWidget {
  final Offset position;
  final Color color;
  final double maxRadius;
  final VoidCallback onComplete;

  const ChainRipple({
    super.key,
    required this.position,
    required this.color,
    required this.maxRadius,
    required this.onComplete,
  });

  @override
  State<ChainRipple> createState() => _ChainRippleState();
}

class _ChainRippleState extends State<ChainRipple>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _controller.forward().then((_) => widget.onComplete());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.position.dx - widget.maxRadius,
      top: widget.position.dy - widget.maxRadius,
      width: widget.maxRadius * 2,
      height: widget.maxRadius * 2,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _RipplePainter(
              progress: _controller.value,
              color: widget.color,
              maxRadius: widget.maxRadius,
            ),
          );
        },
      ),
    );
  }
}

class _RipplePainter extends CustomPainter {
  final double progress;
  final Color color;
  final double maxRadius;

  _RipplePainter({
    required this.progress,
    required this.color,
    required this.maxRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final center = Offset(cx, cy);

    // 兩層波紋，第二層延遲出現
    _drawRing(canvas, center, progress, 1.0);
    if (progress > 0.15) {
      _drawRing(canvas, center, (progress - 0.15) / 0.85, 0.6);
    }
  }

  void _drawRing(Canvas canvas, Offset center, double t, double alphaFactor) {
    final clampedT = t.clamp(0.0, 1.0);
    final radius = maxRadius * Curves.easeOutCubic.transform(clampedT);
    final alpha = ((1.0 - clampedT) * 180 * alphaFactor).round();
    if (alpha <= 0 || radius <= 0) return;

    final strokeWidth = (3.0 * (1.0 - clampedT * 0.7)).clamp(0.5, 3.0);
    final paint = Paint()
      ..color = color.withAlpha(alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(_RipplePainter old) => old.progress != progress;
}
