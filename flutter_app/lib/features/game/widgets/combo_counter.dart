/// Combo 計數器 — 視覺升級系統
/// 1-2: 普通白字 / 3-5: 金色+光暈 / 6-9: 震動+粒子 / 10+: 彩虹+漣漪
import 'dart:math';
import 'package:flutter/material.dart';

class ComboCounter extends StatefulWidget {
  final int combo;

  const ComboCounter({super.key, required this.combo});

  @override
  State<ComboCounter> createState() => _ComboCounterState();
}

class _ComboCounterState extends State<ComboCounter>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _shakeController;
  AnimationController? _rainbowController;

  late Animation<double> _pulseAnim;
  late Animation<double> _shakeAnim;
  int _lastCombo = 0;

  @override
  void initState() {
    super.initState();

    // 持續脈衝
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _pulseAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.15), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // 新 combo 彈入震動
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _shakeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.easeOut),
    );

    _updateForCombo(widget.combo, initial: true);
  }

  @override
  void didUpdateWidget(covariant ComboCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.combo != oldWidget.combo) {
      _updateForCombo(widget.combo);
    }
  }

  void _updateForCombo(int combo, {bool initial = false}) {
    _lastCombo = combo;

    if (combo >= 6) {
      _pulseController.repeat();
    } else if (combo >= 3) {
      _pulseController.repeat();
    } else {
      _pulseController.stop();
      _pulseController.value = 0;
    }

    // 10+ 彩虹效果
    if (combo >= 10) {
      _rainbowController ??= AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 2000),
      );
      _rainbowController!.repeat();
    } else {
      _rainbowController?.stop();
    }

    // 新 combo 彈入（非初始化時）
    if (!initial && combo > 0) {
      _shakeController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _shakeController.dispose();
    _rainbowController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final combo = widget.combo;
    if (combo <= 0) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: Listenable.merge([
        _pulseController,
        _shakeController,
        if (_rainbowController != null) _rainbowController!,
      ]),
      builder: (_, __) {
        // 震動偏移
        final shakeT = _shakeAnim.value;
        final shakeOffset = combo >= 6
            ? sin(shakeT * pi * 4) * 3.0 * (1.0 - shakeT)
            : 0.0;

        // 脈衝縮放
        final pulseScale = combo >= 3 ? _pulseAnim.value : 1.0;

        // 彈入縮放
        final bounceScale = shakeT < 1.0
            ? 0.5 + 0.5 * Curves.elasticOut.transform(shakeT)
            : 1.0;

        return Transform.translate(
          offset: Offset(shakeOffset, 0),
          child: Transform.scale(
            scale: pulseScale * bounceScale,
            child: _buildComboDisplay(combo),
          ),
        );
      },
    );
  }

  Widget _buildComboDisplay(int combo) {
    final tier = _ComboTier.fromCombo(combo);
    final textColor = combo >= 10
        ? _rainbowColor()
        : tier.textColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: tier.bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: tier.borderColor,
          width: combo >= 6 ? 2.0 : 1.0,
        ),
        boxShadow: combo >= 3
            ? [
                BoxShadow(
                  color: tier.glowColor,
                  blurRadius: combo >= 10 ? 16 : (combo >= 6 ? 12 : 8),
                  spreadRadius: combo >= 10 ? 2 : 0,
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'COMBO',
            style: TextStyle(
              fontSize: combo >= 10 ? 10 : 8,
              fontWeight: FontWeight.bold,
              color: textColor.withAlpha(180),
              letterSpacing: 1,
            ),
          ),
          Text(
            '$combo',
            style: TextStyle(
              fontSize: tier.fontSize,
              fontWeight: FontWeight.w900,
              color: textColor,
              shadows: [
                Shadow(
                  color: tier.glowColor,
                  blurRadius: tier.glowRadius,
                ),
                const Shadow(
                  color: Colors.black87,
                  blurRadius: 3,
                  offset: Offset(0.5, 0.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _rainbowColor() {
    final t = _rainbowController?.value ?? 0.0;
    return HSVColor.fromAHSV(1.0, t * 360, 0.8, 1.0).toColor();
  }
}

/// Combo 等級視覺參數
class _ComboTier {
  final double fontSize;
  final Color textColor;
  final Color bgColor;
  final Color borderColor;
  final Color glowColor;
  final double glowRadius;

  const _ComboTier({
    required this.fontSize,
    required this.textColor,
    required this.bgColor,
    required this.borderColor,
    required this.glowColor,
    required this.glowRadius,
  });

  static _ComboTier fromCombo(int combo) {
    if (combo >= 10) {
      return const _ComboTier(
        fontSize: 34,
        textColor: Colors.white, // 被 rainbow 覆蓋
        bgColor: Color(0xDD1A1A2E),
        borderColor: Color(0xFFFFD700),
        glowColor: Color(0x99FFD700),
        glowRadius: 16,
      );
    } else if (combo >= 6) {
      return const _ComboTier(
        fontSize: 26,
        textColor: Color(0xFFFFD700),
        bgColor: Color(0xCC2A2A3E),
        borderColor: Color(0xFFFFB800),
        glowColor: Color(0x66FFB800),
        glowRadius: 12,
      );
    } else if (combo >= 3) {
      return const _ComboTier(
        fontSize: 20,
        textColor: Color(0xFFFFD700),
        bgColor: Color(0xAA333344),
        borderColor: Color(0xFF8B7C2E),
        glowColor: Color(0x44FFD700),
        glowRadius: 8,
      );
    } else {
      return const _ComboTier(
        fontSize: 16,
        textColor: Colors.white,
        bgColor: Color(0x88333344),
        borderColor: Color(0x88FFFFFF),
        glowColor: Color(0x22FFFFFF),
        glowRadius: 0,
      );
    }
  }
}
