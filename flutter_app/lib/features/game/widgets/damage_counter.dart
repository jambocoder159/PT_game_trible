/// Balatro 風格傷害計算演出 Widget
/// 基礎跑數 → ×消除 → ×Combo 重擊 → ×屬性克制 → 最終定格
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../config/theme.dart';

class DamageCounterWidget extends StatefulWidget {
  final Offset position;
  final int finalDamage;
  final int baseDamage;
  final double attributeMult;
  final int matchCount;
  final int combo;
  final double comboMult;
  final Color color;
  final VoidCallback onComplete;

  const DamageCounterWidget({
    super.key,
    required this.position,
    required this.finalDamage,
    required this.baseDamage,
    required this.attributeMult,
    required this.matchCount,
    required this.combo,
    required this.comboMult,
    required this.color,
    required this.onComplete,
  });

  @override
  State<DamageCounterWidget> createState() => _DamageCounterWidgetState();
}

class _DamageCounterWidgetState extends State<DamageCounterWidget>
    with TickerProviderStateMixin {
  late AnimationController _mainController;

  // 各階段動畫
  late Animation<double> _baseCountAnim;     // 基礎跑數
  late Animation<double> _matchSlamAnim;     // 消除加成 slam
  late Animation<double> _comboSlamAnim;     // Combo 重擊
  late Animation<double> _attrSlamAnim;      // 屬性克制
  late Animation<double> _finalSlamAnim;     // 最終定格
  late Animation<double> _opacityAnim;       // 整體淡出
  late Animation<double> _flashAnim;         // 白閃

  // 計算各階段數值
  late int _afterBase;
  late int _afterMatch;
  late int _afterCombo;
  late int _afterAttr;
  late bool _hasMatch;
  late bool _hasCombo;
  late bool _hasAttr;
  late int _totalDuration;

  @override
  void initState() {
    super.initState();

    _hasMatch = widget.matchCount > 1;
    _hasCombo = widget.combo > 1;
    _hasAttr = widget.attributeMult > 1.0;

    // 計算各階段傷害值
    _afterBase = widget.baseDamage;
    _afterMatch = _hasMatch
        ? (widget.baseDamage * (1 + (widget.matchCount - 1) * 0.2)).round()
        : _afterBase;
    _afterCombo = _hasCombo
        ? (_afterMatch * widget.comboMult).round()
        : _afterMatch;
    _afterAttr = widget.finalDamage; // 最終值

    // 動態時長：步驟越多越長
    int steps = 1; // 基礎跑數
    if (_hasMatch) steps++;
    if (_hasCombo) steps++;
    if (_hasAttr) steps++;
    _totalDuration = 400 + steps * 250; // 最少 650ms，最多 1400ms

    _mainController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: _totalDuration),
    );

    // Timeline 計算（百分比分段）
    final segmentSize = 1.0 / (steps + 1); // +1 是最終定格
    double cursor = 0.0;

    // 基礎跑數（前段）
    _baseCountAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: Interval(cursor, cursor + segmentSize * 0.8,
            curve: Curves.easeOutCubic),
      ),
    );
    cursor += segmentSize;

    // 消除加成 slam
    if (_hasMatch) {
      _matchSlamAnim = TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.5), weight: 30),
        TweenSequenceItem(tween: Tween(begin: 1.5, end: 1.0), weight: 70),
      ]).animate(CurvedAnimation(
        parent: _mainController,
        curve: Interval(cursor, cursor + segmentSize,
            curve: Curves.easeOut),
      ));
      cursor += segmentSize;
    } else {
      _matchSlamAnim = const AlwaysStoppedAnimation(0.0);
    }

    // Combo 重擊
    if (_hasCombo) {
      _comboSlamAnim = TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.8), weight: 25),
        TweenSequenceItem(tween: Tween(begin: 1.8, end: 1.0), weight: 75),
      ]).animate(CurvedAnimation(
        parent: _mainController,
        curve: Interval(cursor, cursor + segmentSize,
            curve: Curves.easeOut),
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
        curve: Interval(cursor, cursor + segmentSize,
            curve: Curves.easeOut),
      ));
      cursor += segmentSize;
    } else {
      _attrSlamAnim = const AlwaysStoppedAnimation(0.0);
    }

    // 最終定格 slam
    final finalStart = cursor.clamp(0.0, 0.85);
    _finalSlamAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.5), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.5, end: 1.0), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(
      parent: _mainController,
      curve: Interval(finalStart, 1.0, curve: Curves.easeOut),
    ));

    // 整體淡出（最後 20%）
    _opacityAnim = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.8, 1.0, curve: Curves.easeIn),
      ),
    );

    // 白閃（每次 slam 時觸發）
    _flashAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.0), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.4), weight: 10),
      TweenSequenceItem(tween: Tween(begin: 0.4, end: 0.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.0), weight: 30),
    ]).animate(_mainController);

    _mainController.forward().then((_) {
      widget.onComplete();
    });

    // 最終定格時的觸覺反饋
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

  /// 根據動畫進度計算當前顯示的傷害值
  int _currentDamage() {
    final t = _mainController.value;
    final segmentSize = 1.0 / ((_hasMatch ? 1 : 0) + (_hasCombo ? 1 : 0) +
        (_hasAttr ? 1 : 0) + 2);

    double cursor = segmentSize;

    // 基礎跑數階段
    if (t < cursor) {
      return (_afterBase * _baseCountAnim.value).round();
    }

    // 消除加成階段
    if (_hasMatch) {
      cursor += segmentSize;
      if (t < cursor) return _afterMatch;
    }

    // Combo 階段
    if (_hasCombo) {
      cursor += segmentSize;
      if (t < cursor) return _afterCombo;
    }

    // 屬性克制階段
    if (_hasAttr) {
      cursor += segmentSize;
      if (t < cursor) return _afterAttr;
    }

    return widget.finalDamage;
  }

  /// 判斷當前正在展示的乘數標籤
  String? _currentMultLabel() {
    final t = _mainController.value;
    final segmentSize = 1.0 / ((_hasMatch ? 1 : 0) + (_hasCombo ? 1 : 0) +
        (_hasAttr ? 1 : 0) + 2);

    double cursor = segmentSize;

    if (_hasMatch) {
      final matchStart = cursor;
      cursor += segmentSize;
      if (t >= matchStart && t < cursor && _matchSlamAnim.value > 0) {
        return '×${widget.matchCount}';
      }
    }

    if (_hasCombo) {
      final comboStart = cursor;
      cursor += segmentSize;
      if (t >= comboStart && t < cursor && _comboSlamAnim.value > 0) {
        return '×${widget.comboMult.toStringAsFixed(1)}';
      }
    }

    if (_hasAttr) {
      final attrStart = cursor;
      cursor += segmentSize;
      if (t >= attrStart && t < cursor && _attrSlamAnim.value > 0) {
        return '×${widget.attributeMult.toStringAsFixed(1)}';
      }
    }

    return null;
  }

  Color _multColor() {
    final t = _mainController.value;
    final segmentSize = 1.0 / ((_hasMatch ? 1 : 0) + (_hasCombo ? 1 : 0) +
        (_hasAttr ? 1 : 0) + 2);

    double cursor = segmentSize;

    if (_hasMatch) {
      cursor += segmentSize;
    }
    if (_hasCombo) {
      final comboStart = cursor - segmentSize;
      if (t >= comboStart && t < cursor) {
        return const Color(0xFFFFD700); // 金色
      }
      cursor += segmentSize;
    }
    if (_hasAttr) {
      final attrStart = cursor - segmentSize;
      if (t >= attrStart && t < cursor) {
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
                  // 乘數標籤
                  if (multLabel != null)
                    _buildMultLabel(multLabel),
                  // 主傷害數字
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
    // 取當前 slam 的 scale
    double slamScale = 1.0;
    if (_hasMatch && _matchSlamAnim.value > 0) slamScale = _matchSlamAnim.value;
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
            BoxShadow(
              color: color.withAlpha(100),
              blurRadius: 8,
            ),
          ],
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: AppTheme.fontBodyLg,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            shadows: [
              Shadow(color: Colors.black54, blurRadius: 3),
            ],
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
