import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/models/block.dart';

/// 吸收事件資料
class DrainEventData {
  final int id;
  final BlockColor color;
  final Offset source; // 方塊消除處
  final Offset target; // 貓咪位置

  const DrainEventData({
    required this.id,
    required this.color,
    required this.source,
    required this.target,
  });
}

/// 能量吸收動畫控制器
class EnergyOrbController {
  final List<DrainEventData> _activeEvents = [];
  int _idCounter = 0;
  VoidCallback? _onChange;

  List<DrainEventData> get activeEvents => _activeEvents;

  void addListener(VoidCallback listener) => _onChange = listener;
  void removeListener(VoidCallback listener) {
    if (_onChange == listener) _onChange = null;
  }

  /// 發射一組碎片吸收效果（取代舊的 spawnOrb）
  void spawnOrb({
    required BlockColor color,
    required Offset start,
    required Offset end,
  }) {
    _activeEvents.add(DrainEventData(
      id: _idCounter++,
      color: color,
      source: start,
      target: end,
    ));
    _onChange?.call();
  }

  /// 批量發射
  void spawnOrbs({
    required BlockColor color,
    required Offset start,
    required Offset end,
    int count = 1,
  }) {
    // 吸收效果本身就有很多粒子，一次事件就夠
    _activeEvents.add(DrainEventData(
      id: _idCounter++,
      color: color,
      source: start,
      target: end,
    ));
    _onChange?.call();
  }

  void removeEvent(int id) {
    _activeEvents.removeWhere((e) => e.id == id);
  }
}

/// 覆蓋層
class EnergyOrbOverlay extends StatefulWidget {
  final EnergyOrbController controller;

  const EnergyOrbOverlay({super.key, required this.controller});

  @override
  State<EnergyOrbOverlay> createState() => _EnergyOrbOverlayState();
}

class _EnergyOrbOverlayState extends State<EnergyOrbOverlay> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: widget.controller.activeEvents.map((event) {
          return _DrainEffect(
            key: ValueKey('drain_${event.id}'),
            data: event,
            onComplete: () {
              widget.controller.removeEvent(event.id);
              if (mounted) setState(() {});
            },
          );
        }).toList(),
      ),
    );
  }
}

// ═══════════════════════════════════════════
// 吸收效果 — 碎片先爆散，再收束匯聚到目標
// 靈感：寶可夢「吸取」技能
// ═══════════════════════════════════════════

class _DrainEffect extends StatefulWidget {
  final DrainEventData data;
  final VoidCallback onComplete;

  const _DrainEffect({
    super.key,
    required this.data,
    required this.onComplete,
  });

  @override
  State<_DrainEffect> createState() => _DrainEffectState();
}

class _DrainEffectState extends State<_DrainEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_DrainParticle> _particles;

  static const _totalDuration = Duration(milliseconds: 700);

  // 時間分段
  static const _burstEnd = 0.25;   // 0~25%: 爆散
  static const _hoverEnd = 0.35;   // 25~35%: 短暫漂浮
  // 35~100%: 收束匯聚

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _totalDuration,
    );
    _particles = _generateParticles();
    _controller.forward().then((_) => widget.onComplete());
  }

  List<_DrainParticle> _generateParticles() {
    final rng = Random();
    final count = 10 + rng.nextInt(6); // 10~15 顆碎片
    return List.generate(count, (i) {
      // 爆散方向（全方位，但稍微偏向遠離目標的方向）
      final baseAngle = (i / count) * 2 * pi;
      final jitter = (rng.nextDouble() - 0.5) * 0.8;
      final angle = baseAngle + jitter;

      // 爆散距離（每顆不同，製造散射感）
      final burstDist = 25.0 + rng.nextDouble() * 35.0;

      // 粒子大小
      final size = 2.5 + rng.nextDouble() * 3.5;

      // 收束時的延遲（讓粒子不同時抵達，製造拖尾流感）
      final convergeDelay = rng.nextDouble() * 0.15;

      // 收束路徑的彎曲度（螺旋感）
      final curveBias = (rng.nextDouble() - 0.5) * 60.0;

      return _DrainParticle(
        burstAngle: angle,
        burstDist: burstDist,
        size: size,
        convergeDelay: convergeDelay,
        curveBias: curveBias,
        brightness: 0.6 + rng.nextDouble() * 0.4,
      );
    });
  }

  @override
  void dispose() {
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
          painter: _DrainPainter(
            progress: _controller.value,
            particles: _particles,
            source: widget.data.source,
            target: widget.data.target,
            color: widget.data.color.color,
          ),
        );
      },
    );
  }
}

/// 單顆碎片的參數
class _DrainParticle {
  final double burstAngle;    // 爆散方向
  final double burstDist;     // 爆散距離
  final double size;          // 粒子大小
  final double convergeDelay; // 收束延遲 (0~0.15)
  final double curveBias;     // 收束彎曲偏移
  final double brightness;    // 亮度 (0.6~1.0)

  const _DrainParticle({
    required this.burstAngle,
    required this.burstDist,
    required this.size,
    required this.convergeDelay,
    required this.curveBias,
    required this.brightness,
  });
}

/// 自訂繪製器 — 高效能繪製所有碎片
class _DrainPainter extends CustomPainter {
  final double progress;
  final List<_DrainParticle> particles;
  final Offset source;
  final Offset target;
  final Color color;

  const _DrainPainter({
    required this.progress,
    required this.particles,
    required this.source,
    required this.target,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const burstEnd = _DrainEffectState._burstEnd;
    const hoverEnd = _DrainEffectState._hoverEnd;

    for (final p in particles) {
      // 計算這顆碎片的位置
      final pos = _calcParticlePos(p, progress, burstEnd, hoverEnd);

      // 計算透明度：開頭快速出現，接近目標時漸消
      double alpha;
      if (progress < 0.05) {
        alpha = progress / 0.05; // 淡入
      } else if (progress > 0.85) {
        alpha = (1.0 - progress) / 0.15; // 淡出
      } else {
        alpha = 1.0;
      }

      // 越接近目標越亮
      final convergePhase = ((progress - hoverEnd) / (1.0 - hoverEnd))
          .clamp(0.0, 1.0);
      final glowIntensity = convergePhase * 0.5;

      // 粒子大小：收束時略縮小
      final drawSize = p.size * (1.0 - convergePhase * 0.3);
      if (drawSize <= 0 || alpha <= 0) continue;

      final alphaInt = (alpha * 255 * p.brightness).round().clamp(0, 255);

      // 繪製光暈
      final glowRadius = drawSize * (1.8 + glowIntensity * 2.0);
      final glowPaint = Paint()
        ..color = color.withAlpha((alphaInt * 0.4).round().clamp(0, 255))
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, glowRadius * 0.5);
      canvas.drawCircle(pos, glowRadius, glowPaint);

      // 繪製核心（白色帶顏色）
      final coreColor = Color.lerp(color, Colors.white, 0.3 + glowIntensity * 0.4)!;
      final corePaint = Paint()
        ..color = coreColor.withAlpha(alphaInt);
      canvas.drawCircle(pos, drawSize, corePaint);

      // 收束階段繪製拖尾
      if (convergePhase > 0.1) {
        _drawTrail(canvas, p, progress, burstEnd, hoverEnd, alphaInt, drawSize);
      }
    }

    // 到達目標時的閃光
    if (progress > 0.8) {
      final flashT = ((progress - 0.8) / 0.2).clamp(0.0, 1.0);
      final flashAlpha = (sin(flashT * pi) * 180).round().clamp(0, 255);
      final flashRadius = 12.0 + flashT * 8.0;
      final flashPaint = Paint()
        ..color = color.withAlpha(flashAlpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(target, flashRadius, flashPaint);

      // 白色核心閃光
      final coreFlashPaint = Paint()
        ..color = Colors.white.withAlpha((flashAlpha * 0.6).round().clamp(0, 255));
      canvas.drawCircle(target, flashRadius * 0.4, coreFlashPaint);
    }
  }

  /// 計算某顆碎片在 progress 時刻的位置
  Offset _calcParticlePos(
    _DrainParticle p,
    double progress,
    double burstEnd,
    double hoverEnd,
  ) {
    if (progress <= burstEnd) {
      // ── 爆散階段：從 source 往外飛 ──
      final t = (progress / burstEnd).clamp(0.0, 1.0);
      final eased = Curves.easeOutCubic.transform(t);
      final dx = cos(p.burstAngle) * p.burstDist * eased;
      final dy = sin(p.burstAngle) * p.burstDist * eased;
      return Offset(source.dx + dx, source.dy + dy);
    }

    // 爆散結束時的位置
    final burstPos = Offset(
      source.dx + cos(p.burstAngle) * p.burstDist,
      source.dy + sin(p.burstAngle) * p.burstDist,
    );

    if (progress <= hoverEnd) {
      // ── 漂浮階段：微小飄動 ──
      final t = ((progress - burstEnd) / (hoverEnd - burstEnd)).clamp(0.0, 1.0);
      final drift = sin(t * pi * 2) * 3.0;
      return Offset(burstPos.dx + drift, burstPos.dy + drift * 0.5);
    }

    // ── 收束階段：從 burstPos 匯聚到 target ──
    final rawT = ((progress - hoverEnd - p.convergeDelay) /
            (1.0 - hoverEnd - p.convergeDelay))
        .clamp(0.0, 1.0);
    // 加速曲線 — 越接近目標越快（像被吸進去）
    final eased = Curves.easeInQuart.transform(rawT);

    // 用二次貝茲曲線加彎曲（螺旋吸入感）
    final midX = (burstPos.dx + target.dx) / 2 + p.curveBias;
    final midY = (burstPos.dy + target.dy) / 2 - p.curveBias * 0.5;

    final x = _quadBezier(burstPos.dx, midX, target.dx, eased);
    final y = _quadBezier(burstPos.dy, midY, target.dy, eased);
    return Offset(x, y);
  }

  /// 繪製收束拖尾（在粒子後方畫幾個漸淡的殘影）
  void _drawTrail(
    Canvas canvas,
    _DrainParticle p,
    double progress,
    double burstEnd,
    double hoverEnd,
    int baseAlpha,
    double baseSize,
  ) {
    const trailSteps = 3;
    const trailGap = 0.03;

    for (int i = 1; i <= trailSteps; i++) {
      final trailProgress = (progress - i * trailGap).clamp(0.0, 1.0);
      if (trailProgress <= hoverEnd) continue;

      final trailPos = _calcParticlePos(p, trailProgress, burstEnd, hoverEnd);
      final trailAlpha = (baseAlpha * (1.0 - i / (trailSteps + 1)) * 0.4)
          .round()
          .clamp(0, 255);
      final trailSize = baseSize * (1.0 - i * 0.15);

      if (trailSize <= 0) continue;

      final paint = Paint()
        ..color = color.withAlpha(trailAlpha);
      canvas.drawCircle(trailPos, trailSize, paint);
    }
  }

  double _quadBezier(double p0, double p1, double p2, double t) {
    return (1 - t) * (1 - t) * p0 + 2 * (1 - t) * t * p1 + t * t * p2;
  }

  @override
  bool shouldRepaint(_DrainPainter old) => old.progress != progress;
}
