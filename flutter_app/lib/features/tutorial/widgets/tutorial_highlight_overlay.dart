import 'package:flutter/material.dart';
import '../../../config/theme.dart';

/// 教學聚光燈高亮 Overlay
/// 在半透明遮罩上挖出高亮區域，支援觸控穿透和重試機制
class TutorialHighlightOverlay extends StatefulWidget {
  final GlobalKey? highlightKey;
  final Rect? highlightRect;
  final Color overlayColor;
  /// 高亮區域點擊回調（可選）
  final VoidCallback? onTapHighlight;
  /// 是否允許觸控穿透到底層 widget（預設 true）
  final bool passthrough;
  /// 高亮區域額外 padding
  final double highlightPadding;

  const TutorialHighlightOverlay({
    super.key,
    this.highlightKey,
    this.highlightRect,
    this.overlayColor = const Color(0xA0000000),
    this.onTapHighlight,
    this.passthrough = true,
    this.highlightPadding = 6,
  });

  @override
  State<TutorialHighlightOverlay> createState() =>
      _TutorialHighlightOverlayState();
}

class _TutorialHighlightOverlayState extends State<TutorialHighlightOverlay> {
  Rect? _resolvedRect;
  int _retryCount = 0;
  static const _maxRetries = 10;

  @override
  void initState() {
    super.initState();
    _tryResolve();
  }

  @override
  void didUpdateWidget(covariant TutorialHighlightOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.highlightKey != widget.highlightKey ||
        oldWidget.highlightRect != widget.highlightRect) {
      _retryCount = 0;
      _tryResolve();
    }
  }

  void _tryResolve() {
    final rect = _resolveRect();
    if (rect != null) {
      setState(() => _resolvedRect = rect);
    } else if (_retryCount < _maxRetries && widget.highlightKey != null) {
      _retryCount++;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _tryResolve();
      });
    } else {
      setState(() => _resolvedRect = null);
    }
  }

  Rect? _resolveRect() {
    if (widget.highlightRect != null) return widget.highlightRect;
    if (widget.highlightKey == null) return null;
    final renderBox =
        widget.highlightKey!.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return null;
    final offset = renderBox.localToGlobal(Offset.zero);
    return Rect.fromLTWH(
      offset.dx,
      offset.dy,
      renderBox.size.width,
      renderBox.size.height,
    );
  }

  @override
  Widget build(BuildContext context) {
    final rect = _resolvedRect;
    final holeRect = rect?.inflate(widget.highlightPadding);

    return Stack(
      children: [
        // ─── 遮罩 + 挖孔（純視覺，不攔截觸控） ───
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: SpotlightPainter(
                highlightRect: holeRect,
                overlayColor: widget.overlayColor,
              ),
            ),
          ),
        ),

        // ─── 脈動邊框（純視覺） ───
        if (holeRect != null)
          Positioned(
            left: holeRect.left - 2,
            top: holeRect.top - 2,
            width: holeRect.width + 4,
            height: holeRect.height + 4,
            child: const IgnorePointer(
              child: PulseBorder(color: AppTheme.accentPrimary),
            ),
          ),

        // ─── 4 個矩形阻擋非目標區域的點擊 ───
        if (holeRect != null) ..._buildBlockingRegions(context, holeRect),

        // ─── 高亮區域：根據 passthrough 決定行為 ───
        if (holeRect != null && !widget.passthrough && widget.onTapHighlight != null)
          Positioned(
            left: holeRect.left,
            top: holeRect.top,
            width: holeRect.width,
            height: holeRect.height,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onTapHighlight,
            ),
          ),

        // 無高亮目標時：僅顯示半透明遮罩，不擋住觸控
        // 避免目標尚未渲染或找不到時造成死鎖

      ],
    );
  }

  /// 在高亮區域四周建立 4 個阻擋觸控的矩形
  List<Widget> _buildBlockingRegions(BuildContext context, Rect hole) {
    final screen = MediaQuery.of(context).size;
    final screenRect = Rect.fromLTWH(0, 0, screen.width, screen.height);

    return [
      // 上方
      if (hole.top > 0)
        Positioned(
          left: 0,
          top: 0,
          right: 0,
          height: hole.top,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {},
          ),
        ),
      // 下方
      if (hole.bottom < screenRect.height)
        Positioned(
          left: 0,
          top: hole.bottom,
          right: 0,
          bottom: 0,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {},
          ),
        ),
      // 左方
      if (hole.left > 0)
        Positioned(
          left: 0,
          top: hole.top,
          width: hole.left,
          height: hole.height,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {},
          ),
        ),
      // 右方
      if (hole.right < screenRect.width)
        Positioned(
          left: hole.right,
          top: hole.top,
          right: 0,
          height: hole.height,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {},
          ),
        ),
    ];
  }
}

/// 高亮挖孔畫布
class SpotlightPainter extends CustomPainter {
  final Rect? highlightRect;
  final Color overlayColor;

  SpotlightPainter({
    this.highlightRect,
    required this.overlayColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = overlayColor;

    if (highlightRect == null) {
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
      return;
    }

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(
        highlightRect!,
        const Radius.circular(12),
      ))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant SpotlightPainter old) {
    return old.highlightRect != highlightRect ||
        old.overlayColor != overlayColor;
  }
}

/// 脈動邊框動畫
class PulseBorder extends StatefulWidget {
  final Color color;

  const PulseBorder({super.key, required this.color});

  @override
  State<PulseBorder> createState() => _PulseBorderState();
}

class _PulseBorderState extends State<PulseBorder>
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
    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.color.withAlpha((_animation.value * 200).toInt()),
              width: 2.5,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.color.withAlpha((_animation.value * 60).toInt()),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
        );
      },
    );
  }
}
