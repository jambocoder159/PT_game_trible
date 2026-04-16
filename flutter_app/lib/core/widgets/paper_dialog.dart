import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';

/// 彈窗的紙質風格樣式
enum PaperStyle {
  /// 米黃便條紙（教學/提示）
  note,

  /// 羊皮紙（任務/信件）
  parchment,

  /// 牛皮紙（獎勵/結算）
  kraft,
}

/// 上方裝飾物類型
enum PaperOrnament {
  none,

  /// 紅色蠟封（圓形、浮雕）
  waxSeal,

  /// 鐵製圖釘
  pin,

  /// 麻繩 + 標籤
  twine,
}

/// 紙質彈窗 — 取代所有 showDialog 的 Material 樣板
/// 特色：
/// - 紙質紋理 + 多層陰影
/// - 微傾斜（可關閉）
/// - 撕邊邊緣
/// - 進場 bounce + 輕微擺盪
/// - 可選上方裝飾（蠟封 / 圖釘 / 麻繩）
///
/// 用法：
/// ```dart
/// showDialog(
///   context: context,
///   barrierColor: Colors.transparent, // PaperDialog 自行處理 backdrop
///   builder: (_) => PaperDialog(
///     ornament: PaperOrnament.waxSeal,
///     child: Column(...),
///   ),
/// );
/// ```
class PaperDialog extends StatefulWidget {
  final Widget child;
  final PaperStyle style;
  final PaperOrnament ornament;

  /// 微傾斜角度（預設 -1.5°）
  final double tiltDegrees;

  /// 內距
  final EdgeInsetsGeometry padding;

  /// 最大寬度
  final double maxWidth;

  /// 是否要 backdrop blur + 暖色遮罩
  final bool backdrop;

  const PaperDialog({
    super.key,
    required this.child,
    this.style = PaperStyle.note,
    this.ornament = PaperOrnament.none,
    this.tiltDegrees = -1.5,
    this.padding = const EdgeInsets.fromLTRB(24, 28, 24, 24),
    this.maxWidth = 360,
    this.backdrop = true,
  });

  @override
  State<PaperDialog> createState() => _PaperDialogState();
}

class _PaperDialogState extends State<PaperDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _drop;
  late Animation<double> _scale;
  late Animation<double> _swing;
  late Animation<double> _backdrop;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    // 從上方掉下：-180→0px
    _drop = Tween<double>(begin: -180, end: 0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.55, curve: Curves.easeOutQuart),
      ),
    );
    // 落地後輕微 punch：1.0→0.96→1.0
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.85, end: 1.04), weight: 55),
      TweenSequenceItem(tween: Tween(begin: 1.04, end: 0.98), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 0.98, end: 1.0), weight: 20),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    // 落地後輕微擺盪 ±2°
    _swing = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.5), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 1.5, end: -1.0), weight: 15),
      TweenSequenceItem(tween: Tween(begin: -1.0, end: 0.0), weight: 20),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    // backdrop fade
    _backdrop = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
    );

    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) {
          return Stack(
            children: [
              if (widget.backdrop)
                Positioned.fill(
                  child: IgnorePointer(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(
                        sigmaX: _backdrop.value * 8,
                        sigmaY: _backdrop.value * 8,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            radius: 1.0,
                            colors: [
                              const Color(0xFF3A2418).withAlpha(
                                  (_backdrop.value * 130).toInt()),
                              const Color(0xFF1A0F08).withAlpha(
                                  (_backdrop.value * 200).toInt()),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              // 點擊背景關閉
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.of(context).maybePop(),
                ),
              ),
              Center(
                child: Transform.translate(
                  offset: Offset(0, _drop.value),
                  child: Transform.rotate(
                    angle:
                        (widget.tiltDegrees + _swing.value) * pi / 180,
                    child: Transform.scale(
                      scale: _scale.value,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: widget.maxWidth),
                        child: Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.center,
                          children: [
                            // 紙張本體
                            GestureDetector(
                              onTap: () {}, // 吃掉點擊，避免關閉
                              child: PaperBody(
                                style: widget.style,
                                padding: widget.padding,
                                child: widget.child,
                              ),
                            ),
                            // 上方裝飾
                            if (widget.ornament != PaperOrnament.none)
                              Positioned(
                                top: -22,
                                child: _Ornament(type: widget.ornament),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// 紙張本體 — 用 CustomPaint 畫撕邊 + 紙質紋理
/// 可獨立使用（不一定要在 PaperDialog 中）— 例如教學對話框、卡片
class PaperBody extends StatelessWidget {
  final PaperStyle style;
  final EdgeInsetsGeometry padding;
  final Widget child;

  const PaperBody({
    super.key,
    required this.style,
    required this.padding,
    required this.child,
  });

  Color get _baseColor => switch (style) {
        PaperStyle.note => const Color(0xFFFAF3D8),
        PaperStyle.parchment => const Color(0xFFF1E0B8),
        PaperStyle.kraft => const Color(0xFFE8C99A),
      };

  Color get _edgeColor => switch (style) {
        PaperStyle.note => const Color(0xFFD9B96A),
        PaperStyle.parchment => const Color(0xFFB18A4A),
        PaperStyle.kraft => const Color(0xFF8B6230),
      };

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _PaperEdgePainter(
        baseColor: _baseColor,
        edgeColor: _edgeColor,
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}

/// 紙張邊緣 painter — 撕邊 + 紙質紋理 + 多層陰影
class _PaperEdgePainter extends CustomPainter {
  final Color baseColor;
  final Color edgeColor;

  _PaperEdgePainter({required this.baseColor, required this.edgeColor});

  @override
  void paint(Canvas canvas, Size size) {
    // ── 1. 多層陰影（落在「桌面」上）──
    final shadowPath = _buildPath(size, jitter: 0);
    canvas.drawPath(
      shadowPath.shift(const Offset(0, 12)),
      Paint()
        ..color = Colors.black.withAlpha(50)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24),
    );
    canvas.drawPath(
      shadowPath.shift(const Offset(0, 4)),
      Paint()
        ..color = Colors.black.withAlpha(80)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    // 暖色環境光反射（從烘焙坊環境）
    canvas.drawPath(
      shadowPath.shift(const Offset(0, 18)),
      Paint()
        ..color = const Color(0xFFE8723A).withAlpha(30)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30),
    );

    // ── 2. 紙張本體（撕邊路徑）──
    final paperPath = _buildPath(size, jitter: 2.5);

    // 底色
    canvas.drawPath(
      paperPath,
      Paint()..color = baseColor,
    );

    // ── 3. 紙質紋理（細微噪點）──
    final rand = Random(42);
    final noisePaint = Paint();
    canvas.save();
    canvas.clipPath(paperPath);
    for (int i = 0; i < 80; i++) {
      final x = rand.nextDouble() * size.width;
      final y = rand.nextDouble() * size.height;
      final r = rand.nextDouble() * 0.8 + 0.3;
      noisePaint.color = (rand.nextBool()
          ? Colors.black
          : Colors.white)
          .withAlpha(rand.nextInt(15) + 5);
      canvas.drawCircle(Offset(x, y), r, noisePaint);
    }
    // 邊緣 vignette（四角漸暗）
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..shader = RadialGradient(
          radius: 0.85,
          colors: [
            Colors.transparent,
            edgeColor.withAlpha(45),
          ],
          stops: const [0.6, 1.0],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );
    canvas.restore();

    // ── 4. 邊緣描邊（深一點的紙邊）──
    canvas.drawPath(
      paperPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = edgeColor.withAlpha(120),
    );
  }

  /// 建立撕邊路徑（每邊微微鋸齒）
  Path _buildPath(Size size, {double jitter = 0}) {
    final path = Path();
    final rand = Random(7); // 固定 seed → 形狀穩定
    const steps = 22;

    Offset jitterOffset() {
      if (jitter == 0) return Offset.zero;
      return Offset(
        (rand.nextDouble() - 0.5) * jitter,
        (rand.nextDouble() - 0.5) * jitter,
      );
    }

    // 上邊
    path.moveTo(0, 0);
    for (int i = 1; i <= steps; i++) {
      final t = i / steps;
      path.lineTo(size.width * t + jitterOffset().dx, jitterOffset().dy);
    }
    // 右邊
    for (int i = 1; i <= steps; i++) {
      final t = i / steps;
      path.lineTo(
          size.width + jitterOffset().dx, size.height * t + jitterOffset().dy);
    }
    // 下邊
    for (int i = 1; i <= steps; i++) {
      final t = i / steps;
      path.lineTo(size.width * (1 - t) + jitterOffset().dx,
          size.height + jitterOffset().dy);
    }
    // 左邊
    for (int i = 1; i <= steps; i++) {
      final t = i / steps;
      path.lineTo(
          jitterOffset().dx, size.height * (1 - t) + jitterOffset().dy);
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(_PaperEdgePainter old) =>
      old.baseColor != baseColor || old.edgeColor != edgeColor;
}

/// 上方裝飾物
class _Ornament extends StatelessWidget {
  final PaperOrnament type;
  const _Ornament({required this.type});

  @override
  Widget build(BuildContext context) {
    return switch (type) {
      PaperOrnament.waxSeal => _buildWaxSeal(),
      PaperOrnament.pin => _buildPin(),
      PaperOrnament.twine => _buildTwine(),
      PaperOrnament.none => const SizedBox.shrink(),
    };
  }

  Widget _buildWaxSeal() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        gradient: const RadialGradient(
          center: Alignment(-0.3, -0.3),
          colors: [
            Color(0xFFC0392B),
            Color(0xFF8B1F14),
          ],
        ),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF6B1A10), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(120),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: const Center(
        child: Text(
          '🍪',
          style: TextStyle(fontSize: 22),
        ),
      ),
    );
  }

  Widget _buildPin() {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        gradient: const RadialGradient(
          center: Alignment(-0.4, -0.4),
          colors: [
            Color(0xFFE74C3C),
            Color(0xFF922B21),
          ],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(140),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
    );
  }

  Widget _buildTwine() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF8B6230),
        borderRadius: BorderRadius.circular(2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(100),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Text(
        '★',
        style: TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// 資訊類彈窗 — 任意內容 + 紙質風關閉按鈕
// 用法：PaperInfoDialog.show(context: ..., title: ..., body: Widget)
// ═══════════════════════════════════════════════════════════════

class PaperInfoDialog {
  PaperInfoDialog._();

  /// 顯示一個紙質風資訊彈窗
  /// - [body] 直接放任何 widget（描述、圖示、列表）
  /// - 預設底部有「我知道了」關閉按鈕
  /// - 提供 [actionText] / [onAction] 時，底部變成兩個按鈕：[關閉][動作]
  static Future<void> show({
    required BuildContext context,
    String? title,
    required Widget body,
    String closeText = '我知道了',
    String? actionText,
    VoidCallback? onAction,
    PaperStyle style = PaperStyle.note,
    PaperOrnament ornament = PaperOrnament.none,
    double maxWidth = 360,
  }) {
    final hasAction = actionText != null && onAction != null;
    return showDialog(
      context: context,
      barrierColor: Colors.transparent,
      barrierDismissible: true,
      builder: (ctx) => PaperDialog(
        style: style,
        ornament: ornament,
        maxWidth: maxWidth,
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (title != null) ...[
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color(0xFF3D2817),
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  shadows: [
                    Shadow(
                      color: Colors.white.withAlpha(180),
                      offset: const Offset(0, -1),
                    ),
                    Shadow(
                      color: Colors.black.withAlpha(60),
                      offset: const Offset(0, 1),
                      blurRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Container(
                height: 1.2,
                width: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFB18A4A).withAlpha(0),
                      const Color(0xFFB18A4A),
                      const Color(0xFFB18A4A).withAlpha(0),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ],
            // 內容區（捲動）
            Flexible(
              child: SingleChildScrollView(
                child: DefaultTextStyle(
                  style: TextStyle(
                    color: const Color(0xFF3D2817),
                    fontSize: 14,
                    height: 1.55,
                    shadows: [
                      Shadow(
                        color: Colors.white.withAlpha(120),
                        offset: const Offset(0, -0.5),
                      ),
                    ],
                  ),
                  child: body,
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (hasAction)
              Row(
                children: [
                  Expanded(
                    child: _PaperButton(
                      label: closeText,
                      style: _PaperButtonStyle.secondary,
                      onTap: () => Navigator.of(ctx).pop(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _PaperButton(
                      label: actionText,
                      style: _PaperButtonStyle.primary,
                      onTap: () {
                        Navigator.of(ctx).pop();
                        onAction();
                      },
                    ),
                  ),
                ],
              )
            else
              SizedBox(
                width: double.infinity,
                child: _PaperButton(
                  label: closeText,
                  style: _PaperButtonStyle.primary,
                  onTap: () => Navigator.of(ctx).pop(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// 確認類彈窗 — 統一替換 AlertDialog
// 用法：PaperConfirmDialog.show(context: ..., title: ..., onConfirm: ...)
// ═══════════════════════════════════════════════════════════════

class PaperConfirmDialog {
  PaperConfirmDialog._();

  /// 顯示一個紙質風確認彈窗
  /// - [isDestructive]：true 時確認按鈕為紅色蠟封
  /// - [secondaryConfirmText] / [onSecondaryConfirm]：可選的第三個按鈕（暖橘主色）
  ///   提供時自動改為三按鈕直排版型（confirm > secondary > cancel）
  static Future<void> show({
    required BuildContext context,
    required String title,
    required String content,
    required String confirmText,
    required VoidCallback onConfirm,
    String cancelText = '取消',
    bool isDestructive = false,
    PaperOrnament ornament = PaperOrnament.waxSeal,
    String? secondaryConfirmText,
    VoidCallback? onSecondaryConfirm,
  }) {
    final hasSecondary =
        secondaryConfirmText != null && onSecondaryConfirm != null;
    return showDialog(
      context: context,
      barrierColor: Colors.transparent,
      barrierDismissible: true,
      builder: (ctx) => PaperDialog(
        style: PaperStyle.note,
        ornament: ornament,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            // 標題（含上下裝飾線）
            Text(
              '・ ━━━━━━━━━━━ ・',
              style: TextStyle(
                color: const Color(0xFFB18A4A).withAlpha(140),
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: const Color(0xFF3D2817),
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                shadows: [
                  Shadow(
                    color: Colors.white.withAlpha(180),
                    offset: const Offset(0, -1),
                  ),
                  Shadow(
                    color: Colors.black.withAlpha(60),
                    offset: const Offset(0, 1),
                    blurRadius: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '・ ━━━━━━━━━━━ ・',
              style: TextStyle(
                color: const Color(0xFFB18A4A).withAlpha(140),
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 16),
            // 內容
            Text(
              content,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: const Color(0xFF5D3F25),
                fontSize: 15,
                height: 1.55,
                shadows: [
                  Shadow(
                    color: Colors.white.withAlpha(140),
                    offset: const Offset(0, -0.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            // 按鈕列：3 按鈕直排、2 按鈕橫排
            if (hasSecondary)
              Column(
                children: [
                  // 主要 confirm（destructive 紅 / 一般暖橘）
                  SizedBox(
                    width: double.infinity,
                    child: _PaperButton(
                      label: confirmText,
                      style: isDestructive
                          ? _PaperButtonStyle.destructive
                          : _PaperButtonStyle.primary,
                      onTap: () {
                        Navigator.of(ctx).pop();
                        onConfirm();
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  // 次要 confirm（暖橘主色）
                  SizedBox(
                    width: double.infinity,
                    child: _PaperButton(
                      label: secondaryConfirmText,
                      style: _PaperButtonStyle.primary,
                      onTap: () {
                        Navigator.of(ctx).pop();
                        onSecondaryConfirm();
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  // cancel
                  SizedBox(
                    width: double.infinity,
                    child: _PaperButton(
                      label: cancelText,
                      style: _PaperButtonStyle.secondary,
                      onTap: () => Navigator.of(ctx).pop(),
                    ),
                  ),
                ],
              )
            else
              Row(
                children: [
                  Expanded(
                    child: _PaperButton(
                      label: cancelText,
                      style: _PaperButtonStyle.secondary,
                      onTap: () => Navigator.of(ctx).pop(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _PaperButton(
                      label: confirmText,
                      style: isDestructive
                          ? _PaperButtonStyle.destructive
                          : _PaperButtonStyle.primary,
                      onTap: () {
                        Navigator.of(ctx).pop();
                        onConfirm();
                      },
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// 紙質風按鈕造型
enum _PaperButtonStyle {
  /// 主要 — 暖橘木牌
  primary,

  /// 次要 — 灰棕紙條
  secondary,

  /// 危險 — 紅色蠟印
  destructive,
}

class _PaperButton extends StatefulWidget {
  final String label;
  final _PaperButtonStyle style;
  final VoidCallback onTap;

  const _PaperButton({
    required this.label,
    required this.style,
    required this.onTap,
  });

  @override
  State<_PaperButton> createState() => _PaperButtonState();
}

class _PaperButtonState extends State<_PaperButton> {
  bool _pressed = false;

  ({Color top, Color bottom, Color border, Color text, Color shadow}) get _scheme {
    switch (widget.style) {
      case _PaperButtonStyle.primary:
        return (
          top: const Color(0xFFE8A547),
          bottom: const Color(0xFFC07A2A),
          border: const Color(0xFF8B4F1A),
          text: Colors.white,
          shadow: const Color(0xFFE8723A),
        );
      case _PaperButtonStyle.secondary:
        return (
          top: const Color(0xFFEFE2C0),
          bottom: const Color(0xFFD9C08A),
          border: const Color(0xFFB18A4A),
          text: const Color(0xFF6B4226),
          shadow: const Color(0xFF8B6230),
        );
      case _PaperButtonStyle.destructive:
        return (
          top: const Color(0xFFC0392B),
          bottom: const Color(0xFF8B1F14),
          border: const Color(0xFF6B1A10),
          text: Colors.white,
          shadow: const Color(0xFFC0392B),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _scheme;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 90),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [s.top, s.bottom],
            ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: s.border, width: 1.2),
            boxShadow: [
              // 外光暈
              BoxShadow(
                color: s.shadow.withAlpha(_pressed ? 40 : 100),
                blurRadius: _pressed ? 4 : 10,
                spreadRadius: _pressed ? 0 : 1,
              ),
              // 落地陰影
              BoxShadow(
                color: Colors.black.withAlpha(60),
                blurRadius: _pressed ? 2 : 5,
                offset: Offset(0, _pressed ? 1 : 3),
              ),
            ],
          ),
          child: Center(
            child: Text(
              widget.label,
              style: TextStyle(
                color: s.text,
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
                shadows: widget.style == _PaperButtonStyle.secondary
                    ? [
                        Shadow(
                          color: Colors.white.withAlpha(160),
                          offset: const Offset(0, -0.5),
                        ),
                      ]
                    : [
                        Shadow(
                          color: Colors.black.withAlpha(120),
                          offset: const Offset(0, 1),
                          blurRadius: 1.5,
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
