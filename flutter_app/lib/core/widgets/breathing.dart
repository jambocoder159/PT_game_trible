import 'dart:math';
import 'package:flutter/material.dart';

/// 待機呼吸動畫 — 緩慢 scale 變化，模擬生物呼吸
/// 每個實例有微小的隨機相位差，避免多個元件動作完全同步
class Breathing extends StatefulWidget {
  final Widget child;

  /// 呼吸的最大 scale（預設 1.04）
  final double maxScale;

  /// 一次呼吸週期（預設 2.6 秒）
  final Duration period;

  const Breathing({
    super.key,
    required this.child,
    this.maxScale = 1.04,
    this.period = const Duration(milliseconds: 2600),
  });

  @override
  State<Breathing> createState() => _BreathingState();
}

class _BreathingState extends State<Breathing>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _curve;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.period);
    _curve = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);

    // 隨機初始相位 — 避免多個 Breathing 完全同步
    final rand = Random();
    _ctrl.value = rand.nextDouble();
    _ctrl.repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curve,
      builder: (_, child) {
        final scale = 1.0 + (widget.maxScale - 1.0) * _curve.value;
        return Transform.scale(scale: scale, child: child);
      },
      child: widget.child,
    );
  }
}
