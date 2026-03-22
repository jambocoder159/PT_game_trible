import 'dart:math';
import 'package:flutter/material.dart';
import '../../../config/theme.dart';

/// 分數飛出動畫 — SlideTransition + ScaleTransition
/// Combo > 1 時額外加入震動效果和更大的縮放
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
  late Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    final isCombo = widget.combo > 1;

    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: isCombo ? 1000 : 800),
    );

    // 向上飛出
    _slideAnim = Tween<Offset>(
      begin: Offset.zero,
      end: Offset(0, isCombo ? -2.5 : -2.0),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    // Combo: 更大的彈跳縮放
    _scaleAnim = isCombo
        ? TweenSequence<double>([
            TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.8), weight: 20),
            TweenSequenceItem(tween: Tween(begin: 1.8, end: 1.2), weight: 15),
            TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.4), weight: 10),
            TweenSequenceItem(tween: Tween(begin: 1.4, end: 1.2), weight: 15),
            TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.2), weight: 40),
          ]).animate(CurvedAnimation(
            parent: _controller,
            curve: Curves.easeOut,
          ))
        : TweenSequence<double>([
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

    // Combo 震動：前 40% 快速左右搖晃（0~1 驅動 sin 震動）
    _shakeAnim = isCombo
        ? Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(
              parent: _controller,
              curve: const Interval(0.0, 0.4, curve: Curves.linear),
            ),
          )
        : const AlwaysStoppedAnimation(0.0);

    _controller.forward().then((_) => widget.onComplete());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCombo = widget.combo > 1;
    final color = isCombo ? AppTheme.blockGold : Colors.white;
    final fontSize = isCombo ? (20.0 + (widget.combo - 1).clamp(0, 5) * 2) : 18.0;
    final text = '+${widget.points}';

    return Positioned(
      left: widget.position.dx,
      top: widget.position.dy,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          // 震動偏移
          final shakeOffset = isCombo
              ? sin(_shakeAnim.value * pi * 6) * 4.0 * (1.0 - _shakeAnim.value)
              : 0.0;

          return SlideTransition(
            position: _slideAnim,
            child: Transform.translate(
              offset: Offset(shakeOffset, 0),
              child: ScaleTransition(
                scale: _scaleAnim,
                child: FadeTransition(
                  opacity: _opacityAnim,
                  child: child,
                ),
              ),
            ),
          );
        },
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
                blurRadius: isCombo ? 16 : 12,
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
    );
  }
}
