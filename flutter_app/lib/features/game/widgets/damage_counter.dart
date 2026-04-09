/// 神魔風格傷害計數器演出 Widget
/// 累積跑數 → ×Combo 重擊 → ×屬性克制爆色 → 最終定格
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../config/theme.dart';

class DamageCounterWidget extends StatefulWidget {
  final Offset position;
  final int finalDamage;
  final int preComboDamage;   // combo 前累積傷害
  final int combo;
  final double comboMult;
  final double attributeMult;
  final Color color;
  final VoidCallback onComplete;

  const DamageCounterWidget({
    super.key,
    required this.position,
    required this.finalDamage,
    required this.preComboDamage,
    required this.combo,
    required this.comboMult,
    required this.attributeMult,
    required this.color,
    required this.onComplete,
  });

  @override
  State<DamageCounterWidget> createState() => _DamageCounterWidgetState();
}

class _DamageCounterWidgetState extends State<DamageCounterWidget>
    with TickerProviderStateMixin {
  late AnimationController _mainController;

  late Animation<double> _baseCountAnim;     // 累積跑數
  late Animation<double> _comboSlamAnim;     // Combo 重擊
  late Animation<double> _attrSlamAnim;      // 屬性克制
  late Animation<double> _finalSlamAnim;     // 最終定格
  late Animation<double> _opacityAnim;

  late int _afterBase;
  late int _afterCombo;
  late bool _hasCombo;
  late bool _hasAttr;
  late int _totalDuration;

  @override
  void initState() {
    super.initState();

    _hasCombo = widget.combo > 1;
    _hasAttr = widget.attributeMult > 1.0;

    _afterBase = widget.preComboDamage;
    _afterCombo = _hasCombo
        ? (widget.preComboDamage * widget.comboMult).round()
        : _afterBase;

    int steps = 1; // 累積跑數
    if (_hasCombo) steps++;
    if (_hasAttr) steps++;
    _totalDuration = 400 + steps * 250;

    _mainController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: _totalDuration),
    );

    final segmentSize = 1.0 / (steps + 1);
    double cursor = 0.0;

    // 累積跑數
    _baseCountAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: Interval(cursor, cursor + segmentSize * 0.8,
            curve: Curves.easeOutCubic),
      ),
    );
    cursor += segmentSize;

    // Combo 重擊
    if (_hasCombo) {
      _comboSlamAnim = TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.8), weight: 25),
        TweenSequenceItem(tween: Tween(begin: 1.8, end: 1.0), weight: 75),
      ]).animate(CurvedAnimation(
        parent: _mainController,
        curve: Interval(cursor, cursor + segmentSize, curve: Curves.easeOut),
      ));
      cursor += segmentSize;
    } else {
      _comboSlamAnim = const AlwaysStoppedAnimation(0.0);
    }

    // 屬性克制
    if (_hasAttr) {
      _attrSlamAnim = TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.6), weight: 30),
        TweenSequenceItem(tween: Tween(begin: 1.6, end: 1.0), weight: 70),
      ]).animate(CurvedAnimation(
        parent: _mainController,
        curve: Interval(cursor, cursor + segmentSize, curve: Curves.easeOut),
      ));
      cursor += segmentSize;
    } else {
      _attrSlamAnim = const AlwaysStoppedAnimation(0.0);
    }

    // 最終定格
    final finalStart = cursor.clamp(0.0, 0.85);
    _finalSlamAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.5), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.5, end: 1.0), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(
      parent: _mainController,
      curve: Interval(finalStart, 1.0, curve: Curves.easeOut),
    ));

    _opacityAnim = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.8, 1.0, curve: Curves.easeIn),
      ),
    );

    _mainController.forward().then((_) => widget.onComplete());

    _mainController.addListener(() {
      if (_mainController.value >= finalStart &&
          _mainController.value < finalStart + 0.05) {
        HapticFeedback.heavyImpact();
      }
    });
  }

  @override
  void dispose() {
    _mainController.dispose();
    super.dispose();
  }

  int _currentDamage() {
    final t = _mainController.value;
    final segCount = 1 + (_hasCombo ? 1 : 0) + (_hasAttr ? 1 : 0);
    final seg = 1.0 / (segCount + 1);
    double cursor = seg;

    if (t < cursor) {
      return (_afterBase * _baseCountAnim.value).round();
    }

    if (_hasCombo) {
      cursor += seg;
      if (t < cursor) return _afterCombo;
    }

    if (_hasAttr) {
      cursor += seg;
      if (t < cursor) return widget.finalDamage;
    }

    return widget.finalDamage;
  }

  String? _currentMultLabel() {
    final t = _mainController.value;
    final segCount = 1 + (_hasCombo ? 1 : 0) + (_hasAttr ? 1 : 0);
    final seg = 1.0 / (segCount + 1);
    double cursor = seg;

    if (_hasCombo) {
      final start = cursor;
      cursor += seg;
      if (t >= start && t < cursor && _comboSlamAnim.value > 0) {
        return '×${widget.comboMult.toStringAsFixed(1)}';
      }
    }

    if (_hasAttr) {
      final start = cursor;
      cursor += seg;
      if (t >= start && t < cursor && _attrSlamAnim.value > 0) {
        return '×${widget.attributeMult.toStringAsFixed(1)}';
      }
    }

    return null;
  }

  Color _multColor() {
    final t = _mainController.value;
    final segCount = 1 + (_hasCombo ? 1 : 0) + (_hasAttr ? 1 : 0);
    final seg = 1.0 / (segCount + 1);
    double cursor = seg;

    if (_hasCombo) {
      final start = cursor;
      cursor += seg;
      if (t >= start && t < cursor) {
        return const Color(0xFFFFD700); // 金色
      }
    }
    if (_hasAttr) {
      final start = cursor;
      cursor += seg;
      if (t >= start && t < cursor) {
        return const Color(0xFFFF6B6B); // 紅色克制
      }
    }
    return Colors.cyan;
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.position.dx - 30,
      top: widget.position.dy - 10,
      width: 80,
      child: AnimatedBuilder(
        animation: _mainController,
        builder: (_, __) {
          final damage = _currentDamage();
          final multLabel = _currentMultLabel();
          final scale = _finalSlamAnim.value;

          return Opacity(
            opacity: _opacityAnim.value.clamp(0.0, 1.0),
            child: Transform.scale(
              scale: scale.clamp(0.5, 2.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (multLabel != null)
                    _buildMultLabel(multLabel),
                  Text(
                    '-$damage',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: _getDamageFont(),
                      fontWeight: FontWeight.w900,
                      color: widget.color,
                      shadows: [
                        Shadow(
                          color: widget.color.withAlpha(200),
                          blurRadius: 16,
                        ),
                        const Shadow(
                          color: Colors.black,
                          blurRadius: 6,
                          offset: Offset(1, 1),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMultLabel(String label) {
    final color = _multColor();
    double slamScale = 1.0;
    if (_hasCombo && _comboSlamAnim.value > 0) slamScale = _comboSlamAnim.value;
    if (_hasAttr && _attrSlamAnim.value > 0) slamScale = _attrSlamAnim.value;

    return Transform.scale(
      scale: slamScale.clamp(0.5, 2.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        margin: const EdgeInsets.only(bottom: 2),
        decoration: BoxDecoration(
          color: color.withAlpha(180),
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(color: color.withAlpha(100), blurRadius: 8),
          ],
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: AppTheme.fontBodyLg,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            shadows: [Shadow(color: Colors.black54, blurRadius: 3)],
          ),
        ),
      ),
    );
  }

  double _getDamageFont() {
    final d = widget.finalDamage;
    if (d >= 100) return 34;
    if (d >= 50) return 30;
    return 26;
  }
}
