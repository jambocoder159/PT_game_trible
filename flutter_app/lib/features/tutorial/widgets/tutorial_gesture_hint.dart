import 'package:flutter/material.dart';
import '../../../config/theme.dart';

/// 手勢引導動畫 Widget
/// 支援 tap、swipe-up、swipe-down 動畫，可指定位置
class TutorialGestureHint extends StatefulWidget {
  /// 手勢類型：'tap', 'up', 'down'
  final String gestureType;

  /// 手勢動畫的中心位置（螢幕座標）
  final Offset? position;

  /// 目標元素的 GlobalKey（會自動計算位置）
  final GlobalKey? targetKey;

  const TutorialGestureHint({
    super.key,
    required this.gestureType,
    this.position,
    this.targetKey,
  });

  @override
  State<TutorialGestureHint> createState() => _TutorialGestureHintState();
}

class _TutorialGestureHintState extends State<TutorialGestureHint>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Offset _resolvePosition() {
    if (widget.position != null) return widget.position!;
    if (widget.targetKey != null) {
      final renderBox =
          widget.targetKey!.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        final offset = renderBox.localToGlobal(Offset.zero);
        return Offset(
          offset.dx + renderBox.size.width / 2,
          offset.dy + renderBox.size.height / 2,
        );
      }
    }
    // 預設在螢幕中央偏上
    return Offset(
      MediaQuery.of(context).size.width / 2,
      MediaQuery.of(context).size.height * 0.35,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final pos = _resolvePosition();
        double dy = 0;
        IconData icon = Icons.touch_app;

        switch (widget.gestureType) {
          case 'up':
            dy = -40 * _animation.value;
            icon = Icons.swipe_up;
          case 'down':
            dy = 40 * _animation.value;
            icon = Icons.swipe_down;
          case 'tap':
            dy = -5 * _animation.value;
            icon = Icons.touch_app;
        }

        return Positioned(
          left: pos.dx - 36,
          top: pos.dy + dy - 36,
          child: IgnorePointer(
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppTheme.accentPrimary.withAlpha(60),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 36,
                color: AppTheme.accentPrimary,
              ),
            ),
          ),
        );
      },
    );
  }
}
