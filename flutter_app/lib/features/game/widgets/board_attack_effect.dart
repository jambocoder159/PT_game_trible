/// 棋盤攻擊粒子效果
/// 消除方塊時，粒子從方塊原位沿弧線飛向敵人 + 命中閃光圓環
import 'dart:math';
import 'package:flutter/material.dart';

/// 粒子來源（一個被消除的方塊）
class AttackParticleSource {
  final Offset position;
  final Color color;

  const AttackParticleSource({required this.position, required this.color});
}

/// 棋盤攻擊事件資料
class BoardAttackData {
  final int id;
  final Offset target;
  final int damage;
  final int combo;
  final List<AttackParticleSource> sources;

  const BoardAttackData({
    required this.id,
    required this.target,
    required this.damage,
    required this.sources,
    this.combo = 0,
  });
}

/// 棋盤攻擊效果 Widget
class BoardAttackEffect extends StatefulWidget {
  final BoardAttackData data;
  final VoidCallback onHit;
  final VoidCallback onComplete;

  const BoardAttackEffect({
    super.key,
    required this.data,
    required this.onHit,
    required this.onComplete,
  });

  @override
  State<BoardAttackEffect> createState() => _BoardAttackEffectState();
}

class _BoardAttackEffectState extends State<BoardAttackEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_AttackParticle> _particles;
  bool _hitFired = false;

  static const _totalDuration = Duration(milliseconds: 550);
  static const _burstEnd = 0.10;
  static const _convergeStart = 0.10;
  static const _hitPoint = 0.72;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _totalDuration,
    );
    _particles = _generateParticles();
    _controller.addListener(_checkHit);
    _controller.forward().then((_) => widget.onComplete());
  }

  void _checkHit() {
    if (!_hitFired && _controller.value >= _hitPoint) {
      _hitFired = true;
      // 頓幀（Hitstop）：暫停動畫 50ms，強調衝擊瞬間
      _controller.stop();
      widget.onHit();
      Future.delayed(const Duration(milliseconds: 50), () {
        if (mounted) _controller.forward();
      });
    }
  }

  List<_AttackParticle> _generateParticles() {
    final rng = Random();
    final combo = widget.data.combo;
    final sources = widget.data.sources;
    if (sources.isEmpty) return [];

    // 每個 source 的粒子數，總數上限 30
    final perSource = max(2, 3 + combo);
    final totalTarget = (perSource * sources.length).clamp(1, 30);
    final countPerSource = max(1, totalTarget ~/ sources.length);

    final particles = <_AttackParticle>[];
    for (int si = 0; si < sources.length; si++) {
      final n = (si < sources.length - 1)
          ? countPerSource
          : totalTarget - particles.length;
      for (int i = 0; i < n; i++) {
        final baseAngle = (i / n) * 2 * pi;
        final jitter = (rng.nextDouble() - 0.5) * 0.6;
        particles.add(_AttackParticle(
          sourceIndex: si,
          burstAngle: baseAngle + jitter,
          burstDist: 8.0 + rng.nextDouble() * 16.0,
          size: 2.5 + rng.nextDouble() * 2.5,
          convergeDelay: rng.nextDouble() * 0.08,
          curveBias: (rng.nextDouble() - 0.5) * 50.0,
          brightness: 0.85 + rng.nextDouble() * 0.15,
        ));
      }
    }
    return particles;
  }

  @override
  void dispose() {
    _controller.removeListener(_checkHit);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        return CustomPaint(
          size: Size.infinite,
          painter: _BoardAttackPainter(
            progress: _controller.value,
            particles: _particles,
            sources: widget.data.sources,
            target: widget.data.target,
            combo: widget.data.combo,
          ),
        );
      },
    );
  }
}

class _AttackParticle {
  final int sourceIndex;
  final double burstAngle;
  final double burstDist;
  final double size;
  final double convergeDelay;
  final double curveBias;
  final double brightness;

  const _AttackParticle({
    required this.sourceIndex,
    required this.burstAngle,
    required this.burstDist,
    required this.size,
    required this.convergeDelay,
    required this.curveBias,
    required this.brightness,
  });
}

class _BoardAttackPainter extends CustomPainter {
  final double progress;
  final List<_AttackParticle> particles;
  final List<AttackParticleSource> sources;
  final Offset target;
  final int combo;

  const _BoardAttackPainter({
    required this.progress,
    required this.particles,
    required this.sources,
    required this.target,
    required this.combo,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const burstEnd = _BoardAttackEffectState._burstEnd;
    const convergeStart = _BoardAttackEffectState._convergeStart;

    for (final p in particles) {
      if (p.sourceIndex >= sources.length) continue;
      final src = sources[p.sourceIndex];
      final color = src.color;
      final origin = src.position;

      final pos = _calcPos(p, origin, progress, burstEnd, convergeStart);

      double alpha;
      if (progress < 0.05) {
        alpha = progress / 0.05;
      } else if (progress > 0.9) {
        alpha = (1.0 - progress) / 0.1;
      } else {
        alpha = 1.0;
      }

      final convergePhase = ((progress - convergeStart) / (1.0 - convergeStart))
          .clamp(0.0, 1.0);
      final drawSize = p.size * (1.0 - convergePhase * 0.15);
      if (drawSize <= 0 || alpha <= 0) continue;

      final alphaInt = (alpha * 255 * p.brightness).round().clamp(0, 255);

      // 光暈
      final glowRadius = drawSize * 2.0;
      canvas.drawCircle(pos, glowRadius, Paint()
        ..color = color.withAlpha((alphaInt * 0.5).round().clamp(0, 255))
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, glowRadius * 0.6));

      // 核心
      final coreColor = Color.lerp(color, Colors.white, 0.2)!;
      canvas.drawCircle(pos, drawSize, Paint()..color = coreColor.withAlpha(alphaInt));

      // 拖尾
      if (convergePhase > 0.1) {
        for (int i = 1; i <= 3; i++) {
          final tp = (progress - i * 0.02).clamp(0.0, 1.0);
          if (tp <= convergeStart) continue;
          final tPos = _calcPos(p, origin, tp, burstEnd, convergeStart);
          final tAlpha = (alphaInt * (1.0 - i / 4) * 0.4).round().clamp(0, 255);
          canvas.drawCircle(tPos, drawSize * (1.0 - i * 0.15),
            Paint()..color = color.withAlpha(tAlpha));
        }
      }
    }

    // ── 命中閃光圓環 + 爆發粒子 ──
    const hitPoint = _BoardAttackEffectState._hitPoint;
    if (progress > hitPoint) {
      final hitT = ((progress - hitPoint) / (1.0 - hitPoint)).clamp(0.0, 1.0);
      final mainColor = sources.isNotEmpty ? sources.first.color : Colors.amber;

      // 衝擊白光閃現（前 20%）
      if (hitT < 0.2) {
        final flashT = hitT / 0.2;
        final flashAlpha = ((1.0 - flashT) * 255).round().clamp(0, 255);
        final flashRadius = 8.0 + flashT * 20.0;
        canvas.drawCircle(target, flashRadius, Paint()
          ..color = Colors.white.withAlpha(flashAlpha)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
      }

      // 雙層擴散圓環
      final ringRadius = 6.0 + hitT * 32.0;
      final ringAlpha = ((1.0 - hitT) * 255).round().clamp(0, 255);
      final ringWidth = (4.0 * (1.0 - hitT * 0.6)).clamp(0.5, 4.0);

      canvas.drawCircle(target, ringRadius, Paint()
        ..color = mainColor.withAlpha(ringAlpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = ringWidth);

      // 第二層較淡圓環（延遲擴散）
      if (hitT > 0.1) {
        final ring2T = ((hitT - 0.1) / 0.9).clamp(0.0, 1.0);
        final ring2Radius = 4.0 + ring2T * 40.0;
        final ring2Alpha = ((1.0 - ring2T) * 150).round().clamp(0, 255);
        canvas.drawCircle(target, ring2Radius, Paint()
          ..color = mainColor.withAlpha(ring2Alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0);
      }

      // 命中爆發粒子（從目標點向外擴散）
      if (hitT < 0.7) {
        final burstT = Curves.easeOutCubic.transform(hitT / 0.7);
        final burstAlpha = ((1.0 - hitT / 0.7) * 220).round().clamp(0, 255);
        final burstCount = 8 + (combo.clamp(0, 6));
        for (int i = 0; i < burstCount; i++) {
          final angle = (i / burstCount) * 2 * pi;
          final dist = 5.0 + burstT * 35.0;
          final bx = target.dx + cos(angle) * dist;
          final by = target.dy + sin(angle) * dist;
          final bSize = 2.0 * (1.0 - burstT * 0.5);
          // 交替使用主色和白色
          final bColor = i.isEven
              ? Color.lerp(mainColor, Colors.white, 0.3)!
              : mainColor;
          canvas.drawCircle(Offset(bx, by), bSize, Paint()
            ..color = bColor.withAlpha(burstAlpha));
          // 小光暈
          canvas.drawCircle(Offset(bx, by), bSize * 2.0, Paint()
            ..color = bColor.withAlpha((burstAlpha * 0.3).round().clamp(0, 255))
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
        }
      }

      // Combo 6+ 額外光圈
      if (combo >= 6 && hitT < 0.6) {
        final outerRing = ringRadius + 12.0;
        final outerAlpha = ((1.0 - hitT / 0.6) * 150).round().clamp(0, 255);
        canvas.drawCircle(target, outerRing, Paint()
          ..color = mainColor.withAlpha(outerAlpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0);
      }
    }
  }

  Offset _calcPos(_AttackParticle p, Offset origin, double progress,
      double burstEnd, double convergeStart) {
    // Phase 1: 微幅爆發
    if (progress <= burstEnd) {
      final t = Curves.easeOutCubic.transform((progress / burstEnd).clamp(0.0, 1.0));
      return Offset(
        origin.dx + cos(p.burstAngle) * p.burstDist * t,
        origin.dy + sin(p.burstAngle) * p.burstDist * t,
      );
    }

    final burstPos = Offset(
      origin.dx + cos(p.burstAngle) * p.burstDist,
      origin.dy + sin(p.burstAngle) * p.burstDist,
    );

    // Phase 2: Bezier 飛向目標
    final rawT = ((progress - convergeStart - p.convergeDelay) /
            (1.0 - convergeStart - p.convergeDelay))
        .clamp(0.0, 1.0);
    final eased = Curves.easeInQuad.transform(rawT);

    final midX = (burstPos.dx + target.dx) / 2 + p.curveBias;
    final midY = (burstPos.dy + target.dy) / 2 - p.curveBias * 0.5;

    return Offset(
      _qBez(burstPos.dx, midX, target.dx, eased),
      _qBez(burstPos.dy, midY, target.dy, eased),
    );
  }

  double _qBez(double p0, double p1, double p2, double t) =>
      (1 - t) * (1 - t) * p0 + 2 * (1 - t) * t * p1 + t * t * p2;

  @override
  bool shouldRepaint(_BoardAttackPainter old) => old.progress != progress;
}
