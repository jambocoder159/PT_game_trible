import 'package:flutter/material.dart';
import '../../../config/theme.dart';

/// 教學步驟資料
class TutorialStep {
  final String title;
  final String description;
  final String buttonText;
  final bool showSkip;
  /// 手指動畫方向：null=無, 'up'=向上拖曳, 'down'=向下拖曳, 'tap'=點擊
  final String? gestureHint;
  /// 等待操作時的自定義提示文字
  final String? waitingHint;

  const TutorialStep({
    required this.title,
    required this.description,
    this.buttonText = '下一步',
    this.showSkip = true,
    this.gestureHint,
    this.waitingHint,
  });
}

/// 教學 Overlay — 半透明背景 + 對話框 + 手勢引導動畫
class TutorialOverlay extends StatefulWidget {
  final TutorialStep step;
  final VoidCallback onNext;
  final VoidCallback onSkip;
  /// 是否等待玩家操作（true 時隱藏「下一步」按鈕）
  final bool waitingForAction;

  const TutorialOverlay({
    super.key,
    required this.step,
    required this.onNext,
    required this.onSkip,
    this.waitingForAction = false,
  });

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _gestureAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _gestureAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 半透明背景（不攔截觸控，讓玩家能操作棋盤）
        if (!widget.waitingForAction)
          Positioned.fill(
            child: GestureDetector(
              onTap: () {}, // 攔截點擊防止穿透
              child: Container(
                color: Colors.black.withAlpha(140),
              ),
            ),
          ),

        // 對話框
        Positioned(
          left: 20,
          right: 20,
          bottom: MediaQuery.of(context).padding.bottom + 24,
          child: _buildDialog(),
        ),

        // 手勢引導動畫
        if (widget.step.gestureHint != null && widget.waitingForAction)
          _buildGestureHint(),

        // 跳過按鈕
        if (widget.step.showSkip)
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 16,
            child: TextButton(
              onPressed: widget.onSkip,
              child: const Text(
                '跳過教學 →',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDialog() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.accentPrimary.withAlpha(150),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentPrimary.withAlpha(30),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 標題
          Text(
            widget.step.title,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),

          // 說明
          Text(
            widget.step.description,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),

          // 按鈕
          if (!widget.waitingForAction)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: widget.onNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  widget.step.buttonText,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            )
          else
            Center(
              child: Text(
                widget.step.waitingHint ?? '👆 請在棋盤上操作',
                style: TextStyle(
                  color: AppTheme.accentPrimary.withAlpha(200),
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGestureHint() {
    return AnimatedBuilder(
      animation: _gestureAnimation,
      builder: (context, child) {
        final hint = widget.step.gestureHint;
        double dy = 0;
        IconData icon = Icons.touch_app;

        if (hint == 'up') {
          dy = -40 * _gestureAnimation.value;
          icon = Icons.swipe_up;
        } else if (hint == 'down') {
          dy = 40 * _gestureAnimation.value;
          icon = Icons.swipe_down;
        } else if (hint == 'tap') {
          // 點擊脈衝效果
          dy = -5 * _gestureAnimation.value;
          icon = Icons.touch_app;
        }

        return Positioned(
          top: MediaQuery.of(context).size.height * 0.35 + dy,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.accentPrimary.withAlpha(60),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 40,
                color: AppTheme.accentPrimary,
              ),
            ),
          ),
        );
      },
    );
  }
}
