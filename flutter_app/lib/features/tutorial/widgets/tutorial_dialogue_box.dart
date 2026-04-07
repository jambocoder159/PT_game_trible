import 'dart:async';
import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../models/tutorial_dialogue_data.dart';

/// 教學對話框 — 說話者頭像 + 名稱 + 打字機效果文字泡泡
class TutorialDialogueBox extends StatefulWidget {
  final TutorialDialogue dialogue;
  final VoidCallback? onComplete;
  final VoidCallback? onTap;
  final bool showTapHint;

  const TutorialDialogueBox({
    super.key,
    required this.dialogue,
    this.onComplete,
    this.onTap,
    this.showTapHint = true,
  });

  @override
  State<TutorialDialogueBox> createState() => _TutorialDialogueBoxState();
}

class _TutorialDialogueBoxState extends State<TutorialDialogueBox>
    with SingleTickerProviderStateMixin {
  String _displayedText = '';
  int _charIndex = 0;
  Timer? _typeTimer;
  bool _isComplete = false;
  late AnimationController _blinkController;

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _startTyping();
  }

  @override
  void didUpdateWidget(TutorialDialogueBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dialogue.id != widget.dialogue.id) {
      _resetAndType();
    }
  }

  void _resetAndType() {
    _typeTimer?.cancel();
    _displayedText = '';
    _charIndex = 0;
    _isComplete = false;
    _startTyping();
  }

  void _startTyping() {
    final content = widget.dialogue.content;
    _typeTimer = Timer.periodic(const Duration(milliseconds: 40), (timer) {
      if (_charIndex >= content.length) {
        timer.cancel();
        setState(() => _isComplete = true);
        _handleAutoAdvance();
        return;
      }
      setState(() {
        _charIndex++;
        _displayedText = content.substring(0, _charIndex);
      });
    });
  }

  void _handleAutoAdvance() {
    final delay = widget.dialogue.autoAdvanceDelay;
    if (delay != null && widget.onComplete != null) {
      Future.delayed(Duration(milliseconds: (delay * 1000).toInt()), () {
        if (mounted) widget.onComplete?.call();
      });
    }
  }

  void _handleTap() {
    if (!_isComplete) {
      // 快轉：直接顯示全部文字
      _typeTimer?.cancel();
      setState(() {
        _displayedText = widget.dialogue.content;
        _isComplete = true;
      });
      _handleAutoAdvance();
    } else {
      widget.onTap?.call();
    }
  }

  @override
  void dispose() {
    _typeTimer?.cancel();
    _blinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 16,
      right: 16,
      bottom: MediaQuery.of(context).padding.bottom + 20,
      child: GestureDetector(
        onTap: _handleTap,
        child: Container(
          padding: const EdgeInsets.all(16),
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
              // 說話者
              Row(
                children: [
                  _buildSpeakerAvatar(),
                  const SizedBox(width: 10),
                  Text(
                    widget.dialogue.speaker,
                    style: const TextStyle(
                      color: AppTheme.accentPrimary,
                      fontSize: AppTheme.fontTitleMd,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // 對話內容（打字機效果）
              Text(
                _displayedText,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: AppTheme.fontTitleMd,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              // 點擊提示
              if (_isComplete &&
                  widget.showTapHint &&
                  widget.dialogue.autoAdvanceDelay == null)
                FadeTransition(
                  opacity: _blinkController,
                  child: const Center(
                    child: Text(
                      '▼ 點擊繼續',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: AppTheme.fontBodyMd,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpeakerAvatar() {
    final speaker = widget.dialogue.speaker;
    String emoji;
    Color bgColor;
    switch (speaker) {
      case Speakers.grandpa:
        emoji = '👴';
        bgColor = const Color(0xFFFFE0B2);
      case Speakers.note:
        emoji = '📝';
        bgColor = const Color(0xFFFFF3E0);
      case Speakers.kitten:
        emoji = '🐱';
        bgColor = const Color(0xFFFFCC80);
      case Speakers.lulu:
        emoji = '💧';
        bgColor = const Color(0xFFB3E5FC);
      case Speakers.narrator:
        emoji = '📖';
        bgColor = const Color(0xFFE0E0E0);
      case Speakers.letter:
        emoji = '✉️';
        bgColor = const Color(0xFFFFF9C4);
      case Speakers.unknown:
        emoji = '❓';
        bgColor = const Color(0xFFE0E0E0);
      default:
        emoji = '💬';
        bgColor = const Color(0xFFE0E0E0);
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        border: Border.all(
          color: AppTheme.accentSecondary.withAlpha(80),
          width: 1.5,
        ),
      ),
      child: Center(
        child: Text(emoji, style: const TextStyle(fontSize: AppTheme.fontDisplayMd)),
      ),
    );
  }
}
