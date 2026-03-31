import 'package:flutter/material.dart';
import '../../../config/theme.dart';

/// 教學聚光燈高亮 Overlay
/// 在半透明遮罩上挖出高亮區域，可接受 GlobalKey 或 Rect
class TutorialHighlightOverlay extends StatelessWidget {
  final GlobalKey? highlightKey;
  final Rect? highlightRect;
  final bool blockInput;
  final VoidCallback? onTapOverlay;
  final Color overlayColor;

  const TutorialHighlightOverlay({
    super.key,
    this.highlightKey,
    this.highlightRect,
    this.blockInput = true,
    this.onTapOverlay,
    this.overlayColor = const Color(0xA0000000),
  });

  Rect? _resolveRect() {
    if (highlightRect != null) return highlightRect;
    if (highlightKey == null) return null;
    final renderBox =
        highlightKey!.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return null;
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
    final rect = _resolveRect();

    return Stack(
      children: [
        // 半透明遮罩 + 挖孔
        Positioned.fill(
          child: GestureDetector(
            onTap: blockInput ? () {} : onTapOverlay,
            child: CustomPaint(
              painter: SpotlightPainter(
                highlightRect: rect,
                overlayColor: overlayColor,
              ),
            ),
          ),
        ),

        // 脈動邊框
        if (rect != null)
          Positioned(
            left: rect.left - 4,
            top: rect.top - 4,
            width: rect.width + 8,
            height: rect.height + 8,
            child: const IgnorePointer(
              child: PulseBorder(color: AppTheme.accentPrimary),
            ),
          ),
      ],
    );
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
        highlightRect!.inflate(6),
        const Radius.circular(12),
      ))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant SpotlightPainter old) {
    return old.highlightRect != highlightRect;
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
