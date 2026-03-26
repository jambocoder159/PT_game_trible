import 'dart:math';
import 'package:flutter/material.dart';
import '../../../config/image_assets.dart';
import '../../../config/theme.dart';
import '../../../core/models/block.dart';

/// 單一方塊的視覺元件 — 含增強消除動畫
/// （膨脹 pop + 重力粒子 + 中心光暈爆發 + combo 升級）
class BlockWidget extends StatefulWidget {
  final Block block;
  final double size;
  final int combo; // combo 等級影響粒子量和效果強度

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

  // 粒子資料（消除時產生）— 預計算好避免動畫中 alloc
  late List<_Particle> _particles;
  int _activeCombo = 0;

  @override
  void initState() {
    super.initState();
    _activeCombo = widget.combo;
    _elimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300), // 稍微延長以容納重力
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

    _particles = _generateParticles();

    if (widget.block.isEliminating) {
      _wasEliminating = true;
      _elimController.forward();
    }
  }

  List<_Particle> _generateParticles() {
    final rng = Random();
    // combo 越高粒子越多（14~24）
    final count = (14 + (_activeCombo.clamp(0, 5)) * 2).clamp(14, 24);
    return List.generate(count, (i) {
      final angle = (i / count) * 2 * pi + rng.nextDouble() * 0.5;
      final speed = 1.0 + rng.nextDouble() * 1.5;
      final radius = 1.5 + rng.nextDouble() * 3.0;
      // 初始 Y 速度（向上偏多，模擬爆炸噴射）
      final vy = -1.0 - rng.nextDouble() * 2.0;
      // 閃光顏色混合比例（0=方塊色, 1=白色）
      final sparkle = rng.nextDouble() * 0.4;
      return _Particle(
        angle: angle,
        speed: speed,
        radius: radius,
        cosA: cos(angle),
        sinA: sin(angle),
        vy: vy,
        sparkle: sparkle,
      );
    });
  }

  @override
  void didUpdateWidget(covariant BlockWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.block.isEliminating && !_wasEliminating) {
      _wasEliminating = true;
      _activeCombo = widget.combo;
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
            painter: _EnhancedParticlePainter(
              progress: _elimController.value,
              particles: _particles,
              color: color,
              blockSize: size,
              combo: _activeCombo,
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

/// 增強型粒子繪製器 — 含重力、彈跳、中心光暈、色彩閃光
class _EnhancedParticlePainter extends CustomPainter {
  final double progress;
  final List<_Particle> particles;
  final Color color;
  final double blockSize;
  final int combo;

  _EnhancedParticlePainter({
    required this.progress,
    required this.particles,
    required this.color,
    required this.blockSize,
    required this.combo,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final center = Offset(cx, cy);

    // 1) 中心光暈爆發（前 40%）
    if (progress < 0.4) {
      final glowT = progress / 0.4;
      final glowRadius = blockSize * 0.5 * glowT;
      final glowAlpha = ((1.0 - glowT) * 180).round().clamp(0, 255);
      // combo 越高光暈越亮
      final intensityMult = 1.0 + (combo.clamp(0, 10)) * 0.08;
      final effectiveAlpha = (glowAlpha * intensityMult).round().clamp(0, 255);

      final glowPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withAlpha(effectiveAlpha),
            color.withAlpha((effectiveAlpha * 0.6).round()),
            Colors.transparent,
          ],
          stops: const [0.0, 0.4, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: glowRadius));
      canvas.drawCircle(center, glowRadius, glowPaint);
    }

    // 2) 粒子（15% 後開始）
    if (progress <= 0.12) return;

    final t = ((progress - 0.12) / 0.88).clamp(0.0, 1.0);
    final dist = blockSize * t;
    final alpha = ((1.0 - t) * 255).round();
    if (alpha <= 0) return;

    // 重力常數
    const gravity = 2.5;
    // combo 越高粒子飛更遠
    final rangeBoost = 1.0 + (combo.clamp(0, 5)) * 0.15;

    for (final p in particles) {
      // 基礎位移
      var px = cx + p.cosA * p.speed * dist * rangeBoost;
      // Y 軸加入重力：初始向上噴射然後被重力拉下
      var py = cy + p.sinA * p.speed * dist * rangeBoost +
          p.vy * dist + gravity * t * t * blockSize * 0.5;

      // 簡易彈跳：超出底部邊界時反彈
      final bottomBound = cy + blockSize * 0.6;
      if (py > bottomBound) {
        py = bottomBound - (py - bottomBound) * 0.4;
      }

      final r = p.radius * (1.0 - t * 0.4);

      // 閃光色彩混合
      final particleColor = Color.lerp(color, Colors.white, p.sparkle)!
          .withAlpha(alpha);

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(px, py), width: r * 2, height: r * 2),
          const Radius.circular(1.5),
        ),
        Paint()..color = particleColor,
      );
    }
  }

  @override
  bool shouldRepaint(_EnhancedParticlePainter old) => old.progress != progress;
}

/// 粒子碎片資料 — 含預計算的三角函數值、重力、閃光
class _Particle {
  final double angle;
  final double speed;
  final double radius;
  final double cosA;
  final double sinA;
  final double vy;      // 初始 Y 速度（重力模擬）
  final double sparkle;  // 白色閃光混合比例 (0~0.4)

  const _Particle({
    required this.angle,
    required this.speed,
    required this.radius,
    required this.cosA,
    required this.sinA,
    required this.vy,
    required this.sparkle,
  });
}
