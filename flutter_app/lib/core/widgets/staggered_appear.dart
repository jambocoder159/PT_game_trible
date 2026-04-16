import 'package:flutter/material.dart';

/// 列表 / 網格元素的 stagger 進場動畫
/// 使用 index 計算延遲，配合 fade + 由下往上輕推
///
/// ```dart
/// StaggeredAppear(
///   index: i,
///   child: AgentCard(...),
/// )
/// ```
class StaggeredAppear extends StatefulWidget {
  final int index;
  final Widget child;

  /// 每一個 index 之間的錯開時間
  final Duration step;

  /// 動畫本身時長
  final Duration duration;

  /// 起始位移（往下偏移多少 px）
  final double offsetY;

  /// 最多錯開幾個 index — 超過此值的 index 不再增加延遲
  final int maxStagger;

  const StaggeredAppear({
    super.key,
    required this.index,
    required this.child,
    this.step = const Duration(milliseconds: 55),
    this.duration = const Duration(milliseconds: 380),
    this.offsetY = 24,
    this.maxStagger = 14,
  });

  @override
  State<StaggeredAppear> createState() => _StaggeredAppearState();
}

class _StaggeredAppearState extends State<StaggeredAppear>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;
  late Animation<double> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    final curved =
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(curved);
    _slide = Tween<double>(begin: widget.offsetY, end: 0.0).animate(curved);

    final cappedIndex =
        widget.index.clamp(0, widget.maxStagger);
    final delay = widget.step * cappedIndex;
    Future.delayed(delay, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) {
        if (_ctrl.isCompleted) return child!;
        return Opacity(
          opacity: _opacity.value,
          child: Transform.translate(
            offset: Offset(0, _slide.value),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
