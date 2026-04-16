import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 通用按壓縮放回饋 — 提供按下 0.94 → 釋放 1.0 的彈跳回彈
/// 用法：把任何可點擊的內容包進 PressableScale，並提供 onTap callback
///
/// ```dart
/// PressableScale(
///   onTap: () { ... },
///   child: Container(...),
/// )
/// ```
class PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// 按下時縮放至此倍率（預設 0.94）
  final double pressedScale;

  /// 按壓動畫時長（預設 90ms）
  final Duration duration;

  /// 是否觸發輕觸震動回饋（預設 true）
  final bool hapticFeedback;

  /// 子元件的 hitTest 行為
  final HitTestBehavior behavior;

  const PressableScale({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.pressedScale = 0.94,
    this.duration = const Duration(milliseconds: 90),
    this.hapticFeedback = true,
    this.behavior = HitTestBehavior.opaque,
  });

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: widget.duration,
      reverseDuration: const Duration(milliseconds: 180),
    );
    _scale = Tween<double>(begin: 1.0, end: widget.pressedScale).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: Curves.easeOut,
        reverseCurve: Curves.easeOutBack,
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _handleTapDown(_) {
    if (widget.onTap == null && widget.onLongPress == null) return;
    _ctrl.forward();
  }

  void _handleTapUp(_) {
    _ctrl.reverse();
  }

  void _handleTapCancel() {
    _ctrl.reverse();
  }

  void _handleTap() {
    if (widget.onTap == null) return;
    if (widget.hapticFeedback) {
      HapticFeedback.lightImpact();
    }
    widget.onTap!();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: widget.behavior,
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.onTap == null ? null : _handleTap,
      onLongPress: widget.onLongPress,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, child) {
          return Transform.scale(scale: _scale.value, child: child);
        },
        child: widget.child,
      ),
    );
  }
}
