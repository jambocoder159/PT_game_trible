import 'package:flutter/material.dart';
import '../../../config/theme.dart';

/// 分數飛出動畫 — SlideTransition + ScaleTransition
/// 數字從消除位置向上飛出並放大
class ScorePopup extends StatefulWidget {
  final int points;
  final int combo;
  final Offset position;
  final VoidCallback onComplete;

  const ScorePopup({
    super.key,
    required this.points,
    required this.combo,
    required this.position,
    required this.onComplete,
  });

  @override
  State<ScorePopup> createState() => _ScorePopupState();
}

class _ScorePopupState extends State<ScorePopup>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnim;
  late Animation<double> _scaleAnim;
  late Animation<double> _opacityAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // 向上飛出
    _slideAnim = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -2.0),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    // 從小到大再稍微縮回
    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.3), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 40),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    // 後半段淡出
    _opacityAnim = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 1.0, curve: Curves.easeIn),
      ),
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
    final color = widget.combo > 1 ? AppTheme.blockGold : Colors.white;
    final fontSize = widget.combo > 1 ? 22.0 : 18.0;
    final text = widget.combo > 1
        ? '+${widget.points}\n${widget.combo}x Combo!'
        : '+${widget.points}';

    return Positioned(
      left: widget.position.dx,
      top: widget.position.dy,
      child: SlideTransition(
        position: _slideAnim,
        child: ScaleTransition(
          scale: _scaleAnim,
          child: FadeTransition(
            opacity: _opacityAnim,
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: color,
                shadows: [
                  Shadow(
                    color: color.withAlpha(180),
                    blurRadius: 12,
                  ),
                  const Shadow(
                    color: Colors.black,
                    blurRadius: 4,
                    offset: Offset(1, 1),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
