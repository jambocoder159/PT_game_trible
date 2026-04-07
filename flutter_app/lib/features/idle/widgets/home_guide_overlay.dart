import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../config/theme.dart';

/// 首頁導覽步驟
class HomeGuideStep {
  final String title;
  final String description;
  final String buttonText;
  /// 高亮區域的 GlobalKey（null = 不高亮）
  final GlobalKey? highlightKey;

  const HomeGuideStep({
    required this.title,
    required this.description,
    this.buttonText = '了解！',
    this.highlightKey,
  });
}

/// 首頁導覽 Overlay
/// 教學完成後首次進入 HomeScreen 時觸發，
/// 引導玩家認識放置棋盤、瓶子系統、闖關入口。
class HomeGuideOverlay extends StatefulWidget {
  final List<HomeGuideStep> steps;
  final VoidCallback onComplete;
  /// 最後一步完成後要切換到的 Tab index（闖關 = 3）
  final ValueChanged<int>? onSwitchTab;

  const HomeGuideOverlay({
    super.key,
    required this.steps,
    required this.onComplete,
    this.onSwitchTab,
  });

  @override
  State<HomeGuideOverlay> createState() => _HomeGuideOverlayState();
}

class _HomeGuideOverlayState extends State<HomeGuideOverlay>
    with SingleTickerProviderStateMixin {
  int _currentStep = 0;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..forward();
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _nextStep() {
    HapticFeedback.lightImpact();
    if (_currentStep >= widget.steps.length - 1) {
      // 最後一步 → 切換到闖關 Tab 並完成導覽
      widget.onSwitchTab?.call(3);
      widget.onComplete();
      return;
    }
    setState(() {
      _currentStep++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final step = widget.steps[_currentStep];
    final highlightRect = _getHighlightRect(step.highlightKey);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Stack(
        children: [
          // 半透明背景 + 高亮挖孔
          Positioned.fill(
            child: GestureDetector(
              onTap: () {}, // 攔截穿透
              child: CustomPaint(
                painter: _SpotlightPainter(
                  highlightRect: highlightRect,
                  overlayColor: Colors.black.withAlpha(160),
                ),
              ),
            ),
          ),

          // 高亮區域脈動邊框
          if (highlightRect != null)
            Positioned(
              left: highlightRect.left - 4,
              top: highlightRect.top - 4,
              width: highlightRect.width + 8,
              height: highlightRect.height + 8,
              child: IgnorePointer(
                child: _PulseBorder(color: AppTheme.accentPrimary),
              ),
            ),

          // 對話框
          Positioned(
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).padding.bottom + 24,
            child: _buildDialog(step),
          ),

          // 步驟指示器
          Positioned(
            left: 0,
            right: 0,
            bottom: MediaQuery.of(context).padding.bottom + 8,
            child: _buildStepIndicator(),
          ),
        ],
      ),
    );
  }

  Rect? _getHighlightRect(GlobalKey? key) {
    if (key == null) return null;
    final renderBox = key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return null;
    final offset = renderBox.localToGlobal(Offset.zero);
    return Rect.fromLTWH(
      offset.dx,
      offset.dy,
      renderBox.size.width,
      renderBox.size.height,
    );
  }

  Widget _buildDialog(HomeGuideStep step) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.accentSecondary.withAlpha(150),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentSecondary.withAlpha(30),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            step.title,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: AppTheme.fontTitleLg,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            step.description,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: AppTheme.fontBodyLg,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                step.buttonText,
                style: const TextStyle(
                  fontSize: AppTheme.fontTitleMd,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(widget.steps.length, (index) {
        final isActive = index == _currentStep;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 20 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive
                ? AppTheme.accentSecondary
                : AppTheme.textSecondary.withAlpha(60),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

/// 高亮挖孔畫布 — 在半透明遮罩上挖出圓角矩形
class _SpotlightPainter extends CustomPainter {
  final Rect? highlightRect;
  final Color overlayColor;

  _SpotlightPainter({
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

    // 整體矩形 - 挖孔
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
  bool shouldRepaint(covariant _SpotlightPainter old) {
    return old.highlightRect != highlightRect;
  }
}

/// 脈動邊框動畫
class _PulseBorder extends StatefulWidget {
  final Color color;

  const _PulseBorder({required this.color});

  @override
  State<_PulseBorder> createState() => _PulseBorderState();
}

class _PulseBorderState extends State<_PulseBorder>
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
