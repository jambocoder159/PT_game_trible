import 'dart:async';
import 'package:flutter/material.dart';
import '../../../config/theme.dart';

/// 浮動提示位置
enum TutorialHintPosition { top, bottom }

/// 非阻斷浮動提示 — 取代大部分 TutorialDialogueBox 使用
/// fade-in → 顯示 → fade-out，不攔截觸控
class TutorialFloatingHint extends StatefulWidget {
  final String text;
  final String? emoji;
  final Duration displayDuration;
  final TutorialHintPosition position;
  final VoidCallback? onDismissed;

  const TutorialFloatingHint({
    super.key,
    required this.text,
    this.emoji,
    this.displayDuration = const Duration(seconds: 3),
    this.position = TutorialHintPosition.bottom,
    this.onDismissed,
  });

  @override
  State<TutorialFloatingHint> createState() => _TutorialFloatingHintState();
}

class _TutorialFloatingHintState extends State<TutorialFloatingHint>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeController.forward();
    _dismissTimer = Timer(widget.displayDuration, _dismiss);
  }

  void _dismiss() {
    _fadeController.reverse().then((_) {
      if (mounted) widget.onDismissed?.call();
    });
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final safePadding = MediaQuery.of(context).padding;
    final isTop = widget.position == TutorialHintPosition.top;

    return Positioned(
      top: isTop ? safePadding.top + 60 : null,
      bottom: isTop ? null : safePadding.bottom + 80,
      left: 24,
      right: 24,
      child: IgnorePointer(
        child: FadeTransition(
          opacity: _fadeController,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.bgSecondary.withAlpha(235),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              border: Border.all(
                color: AppTheme.accentPrimary.withAlpha(80),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(25),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.emoji != null) ...[
                  Text(widget.emoji!, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    widget.text,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
