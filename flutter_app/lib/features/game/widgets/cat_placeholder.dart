/// 貓咪佔位符 Widget
/// 用 CustomPainter 繪製簡化貓咪輪廓，搭配顏色和狀態環圈
import 'package:flutter/material.dart';
import 'dart:math' as math;

/// 貓咪佔位符
class CatPlaceholder extends StatelessWidget {
  final Color color;
  final double size;
  final String? label;

  const CatPlaceholder({
    super.key,
    required this.color,
    this.size = 48,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CatPainter(color: color),
      ),
    );
  }
}

class _CatPainter extends CustomPainter {
  final Color color;

  _CatPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    final bodyPaint = Paint()..color = color;
    final darkerPaint = Paint()..color = Color.lerp(color, Colors.black, 0.25)!;
    final outlinePaint = Paint()
      ..color = Color.lerp(color, Colors.black, 0.3)!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final pinkPaint = Paint()..color = Colors.pink.shade200.withAlpha(150);
    final whitePaint = Paint()..color = Colors.white;
    final eyePaint = Paint()..color = const Color(0xFF333333);
    final nosePaint = Paint()..color = Colors.pink.shade300;

    // 身體
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, h * 0.73), width: w * 0.55, height: h * 0.35),
      bodyPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, h * 0.73), width: w * 0.55, height: h * 0.35),
      outlinePaint,
    );

    // 尾巴
    final tailPath = Path()
      ..moveTo(cx + w * 0.22, h * 0.65)
      ..quadraticBezierTo(cx + w * 0.42, h * 0.45, cx + w * 0.35, h * 0.38);
    canvas.drawPath(
      tailPath,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.07
        ..strokeCap = StrokeCap.round,
    );

    // 頭部
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, h * 0.4), width: w * 0.58, height: h * 0.42),
      bodyPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, h * 0.4), width: w * 0.58, height: h * 0.42),
      outlinePaint,
    );

    // 左耳
    final leftEar = Path()
      ..moveTo(cx - w * 0.2, h * 0.28)
      ..lineTo(cx - w * 0.14, h * 0.1)
      ..lineTo(cx - w * 0.03, h * 0.22)
      ..close();
    canvas.drawPath(leftEar, bodyPaint);
    canvas.drawPath(leftEar, outlinePaint);
    // 耳朵內部
    final leftEarInner = Path()
      ..moveTo(cx - w * 0.17, h * 0.26)
      ..lineTo(cx - w * 0.13, h * 0.14)
      ..lineTo(cx - w * 0.06, h * 0.23)
      ..close();
    canvas.drawPath(leftEarInner, pinkPaint);

    // 右耳
    final rightEar = Path()
      ..moveTo(cx + w * 0.2, h * 0.28)
      ..lineTo(cx + w * 0.14, h * 0.1)
      ..lineTo(cx + w * 0.03, h * 0.22)
      ..close();
    canvas.drawPath(rightEar, bodyPaint);
    canvas.drawPath(rightEar, outlinePaint);
    final rightEarInner = Path()
      ..moveTo(cx + w * 0.17, h * 0.26)
      ..lineTo(cx + w * 0.13, h * 0.14)
      ..lineTo(cx + w * 0.06, h * 0.23)
      ..close();
    canvas.drawPath(rightEarInner, pinkPaint);

    // 眼睛
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx - w * 0.1, h * 0.38), width: w * 0.1, height: w * 0.12),
      whitePaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx + w * 0.1, h * 0.38), width: w * 0.1, height: w * 0.12),
      whitePaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx - w * 0.09, h * 0.39), width: w * 0.06, height: w * 0.08),
      eyePaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx + w * 0.11, h * 0.39), width: w * 0.06, height: w * 0.08),
      eyePaint,
    );
    // 眼睛高光
    canvas.drawCircle(Offset(cx - w * 0.08, h * 0.37), w * 0.015, whitePaint);
    canvas.drawCircle(Offset(cx + w * 0.12, h * 0.37), w * 0.015, whitePaint);

    // 鼻子
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, h * 0.44), width: w * 0.04, height: w * 0.03),
      nosePaint,
    );

    // 嘴巴
    final mouthPath = Path()
      ..moveTo(cx - w * 0.04, h * 0.46)
      ..quadraticBezierTo(cx, h * 0.50, cx + w * 0.04, h * 0.46);
    canvas.drawPath(
      mouthPath,
      Paint()
        ..color = Colors.grey.shade600
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..strokeCap = StrokeCap.round,
    );

    // 鬍鬚
    final whiskerPaint = Paint()
      ..color = Colors.grey.shade400
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6;
    // 左鬍鬚
    canvas.drawLine(Offset(cx - w * 0.25, h * 0.42), Offset(cx - w * 0.12, h * 0.44), whiskerPaint);
    canvas.drawLine(Offset(cx - w * 0.25, h * 0.45), Offset(cx - w * 0.12, h * 0.45), whiskerPaint);
    // 右鬍鬚
    canvas.drawLine(Offset(cx + w * 0.25, h * 0.42), Offset(cx + w * 0.12, h * 0.44), whiskerPaint);
    canvas.drawLine(Offset(cx + w * 0.25, h * 0.45), Offset(cx + w * 0.12, h * 0.45), whiskerPaint);

    // 前腳
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx - w * 0.15, h * 0.88), width: w * 0.13, height: h * 0.1),
      bodyPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx + w * 0.15, h * 0.88), width: w * 0.13, height: h * 0.1),
      bodyPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx - w * 0.15, h * 0.88), width: w * 0.13, height: h * 0.1),
      outlinePaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx + w * 0.15, h * 0.88), width: w * 0.13, height: h * 0.1),
      outlinePaint,
    );
  }

  @override
  bool shouldRepaint(_CatPainter oldDelegate) => color != oldDelegate.color;
}

/// 貓咪狀態環圈
class CatStatusRing extends StatelessWidget {
  final Color ringColor;
  final bool isActive;
  final bool isReady;
  final Widget child;
  final double size;

  const CatStatusRing({
    super.key,
    required this.ringColor,
    this.isActive = false,
    this.isReady = false,
    required this.child,
    this.size = 56,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: ringColor,
          width: isReady ? 3.0 : 2.0,
        ),
        boxShadow: [
          if (isReady)
            BoxShadow(
              color: ringColor.withAlpha(100),
              blurRadius: 8,
              spreadRadius: 1,
            ),
        ],
      ),
      child: ClipOval(child: child),
    );
  }
}
