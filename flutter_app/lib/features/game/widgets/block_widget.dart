import 'dart:math';
import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../core/models/block.dart';

/// 單一方塊的視覺元件 — 含消除動畫（膨脹 pop + CustomPainter 粒子）
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

  // 粒子資料（消除時產生）— 預計算好避免動畫中 alloc
  late List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    _elimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
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
    return List.generate(6, (i) {
      final angle = (i / 6) * 2 * pi + rng.nextDouble() * 0.6;
      final speed = 1.2 + rng.nextDouble() * 1.3;
      final radius = 2.0 + rng.nextDouble() * 3.0;
      return _Particle(
        angle: angle,
        speed: speed,
        radius: radius,
        // 預計算 cos/sin 避免每幀計算
        cosA: cos(angle),
        sinA: sin(angle),
      );
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
          return CustomPaint(
            painter: _ParticlePainter(
              progress: _elimController.value,
              particles: _particles,
              color: color,
              blockSize: size,
            ),
            child: Center(
              child: Opacity(
                opacity: _opacityAnim.value,
                child: Transform.scale(
                  scale: _scaleAnim.value,
                  child: child!,
                ),
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

/// 用 CustomPainter 繪製粒子 — 比 Stack<Positioned<Container>> 快很多
class _ParticlePainter extends CustomPainter {
  final double progress;
  final List<_Particle> particles;
  final Color color;
  final double blockSize;

  _ParticlePainter({
    required this.progress,
    required this.particles,
    required this.color,
    required this.blockSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0.15) return;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final t = ((progress - 0.15) / 0.85).clamp(0.0, 1.0);
    final dist = blockSize * t;
    final alpha = ((1.0 - t) * 255).round();

    if (alpha <= 0) return;

    final paint = Paint()..color = color.withAlpha(alpha);

    for (final p in particles) {
      final px = cx + p.cosA * p.speed * dist;
      final py = cy + p.sinA * p.speed * dist;
      final r = p.radius * (1.0 - t * 0.5);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(px, py), width: r * 2, height: r * 2),
          const Radius.circular(1.5),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.progress != progress;
}

/// 粒子碎片資料 — 含預計算的三角函數值
class _Particle {
  final double angle;
  final double speed;
  final double radius;
  final double cosA;
  final double sinA;

  const _Particle({
    required this.angle,
    required this.speed,
    required this.radius,
    required this.cosA,
    required this.sinA,
  });
}
