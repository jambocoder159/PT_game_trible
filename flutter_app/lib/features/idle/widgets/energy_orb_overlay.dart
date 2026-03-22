import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/models/block.dart';
import '../../../config/theme.dart';

/// 能量球飛行資料
class EnergyOrbData {
  final int id;
  final BlockColor color;
  final Offset start;
  final Offset end;

  const EnergyOrbData({
    required this.id,
    required this.color,
    required this.start,
    required this.end,
  });
}

/// 能量球飛行動畫控制器
class EnergyOrbController {
  final List<EnergyOrbData> _activeOrbs = [];
  int _idCounter = 0;
  VoidCallback? _onChange;

  List<EnergyOrbData> get activeOrbs => _activeOrbs;

  void addListener(VoidCallback listener) => _onChange = listener;
  void removeListener(VoidCallback listener) {
    if (_onChange == listener) _onChange = null;
  }

  /// 發射一顆能量球
  void spawnOrb({
    required BlockColor color,
    required Offset start,
    required Offset end,
  }) {
    _activeOrbs.add(EnergyOrbData(
      id: _idCounter++,
      color: color,
      start: start,
      end: end,
    ));
    _onChange?.call();
  }

  /// 批量發射（同一顏色多顆，加微小偏移讓它們不重疊）
  void spawnOrbs({
    required BlockColor color,
    required Offset start,
    required Offset end,
    int count = 1,
  }) {
    final rng = Random();
    for (int i = 0; i < count.clamp(1, 5); i++) {
      final jitter = Offset(
        (rng.nextDouble() - 0.5) * 20,
        (rng.nextDouble() - 0.5) * 20,
      );
      _activeOrbs.add(EnergyOrbData(
        id: _idCounter++,
        color: color,
        start: start + jitter,
        end: end,
      ));
    }
    _onChange?.call();
  }

  void removeOrb(int id) {
    _activeOrbs.removeWhere((o) => o.id == id);
  }
}

/// 能量球飛行動畫覆蓋層
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
        children: widget.controller.activeOrbs.map((orb) {
          return _FlyingOrb(
            key: ValueKey('orb_${orb.id}'),
            data: orb,
            onComplete: () {
              widget.controller.removeOrb(orb.id);
              if (mounted) setState(() {});
            },
          );
        }).toList(),
      ),
    );
  }
}

/// 單顆飛行能量球
class _FlyingOrb extends StatefulWidget {
  final EnergyOrbData data;
  final VoidCallback onComplete;

  const _FlyingOrb({
    super.key,
    required this.data,
    required this.onComplete,
  });

  @override
  State<_FlyingOrb> createState() => _FlyingOrbState();
}

class _FlyingOrbState extends State<_FlyingOrb>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _progress = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInCubic,
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
    final color = widget.data.color.color;

    return AnimatedBuilder(
      animation: _progress,
      builder: (_, __) {
        final t = _progress.value;
        // 使用貝茲曲線路徑 — 先向上拱起再落到目標
        final start = widget.data.start;
        final end = widget.data.end;
        final midX = (start.dx + end.dx) / 2;
        final midY = min(start.dy, end.dy) - 40; // 向上拱起
        final control = Offset(midX, midY);

        // 二次貝茲曲線
        final x = _quadBezier(start.dx, control.dx, end.dx, t);
        final y = _quadBezier(start.dy, control.dy, end.dy, t);

        // 大小：開始大 → 結束時縮小並閃爍
        final size = 8.0 * (1.0 - t * 0.4);
        // 不透明度
        final opacity = t < 0.8 ? 1.0 : (1.0 - (t - 0.8) / 0.2);
        // 尾跡光暈
        final glowSize = size * (1.5 + t * 0.5);

        return Positioned(
          left: x - glowSize / 2,
          top: y - glowSize / 2,
          child: Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: SizedBox(
              width: glowSize,
              height: glowSize,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 光暈
                  Container(
                    width: glowSize,
                    height: glowSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          color.withAlpha(120),
                          color.withAlpha(0),
                        ],
                      ),
                    ),
                  ),
                  // 核心
                  Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: color.withAlpha(200),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  double _quadBezier(double p0, double p1, double p2, double t) {
    return (1 - t) * (1 - t) * p0 + 2 * (1 - t) * t * p1 + t * t * p2;
  }
}
