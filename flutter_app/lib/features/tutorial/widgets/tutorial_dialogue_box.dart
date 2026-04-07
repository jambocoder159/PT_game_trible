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

  // 說話者 → 頭像圖片路徑（對應 tutorial_assets_spec.md）
  static const _speakerAvatars = {
    Speakers.grandpa: 'assets/images/output/avatars/avatar_grandpa.png',
    Speakers.kitten: 'assets/images/output/avatars/avatar_kitten.png',
    Speakers.letter: 'assets/images/output/avatars/avatar_letter.png',
    Speakers.narrator: 'assets/images/output/avatars/avatar_narrator.png',
  };

  // 說話者 → fallback emoji + 背景色
  static const _speakerFallbacks = {
    Speakers.grandpa: ('👴', Color(0xFFFFE0B2)),
    Speakers.note: ('📝', Color(0xFFFFF3E0)),
    Speakers.kitten: ('🐱', Color(0xFFFFCC80)),
    Speakers.lulu: ('💧', Color(0xFFB3E5FC)),
    Speakers.narrator: ('📖', Color(0xFFE0E0E0)),
    Speakers.letter: ('✉️', Color(0xFFFFF9C4)),
    Speakers.unknown: ('❓', Color(0xFFE0E0E0)),
  };

  Widget _buildSpeakerAvatar() {
    final speaker = widget.dialogue.speaker;
    final avatarPath = _speakerAvatars[speaker];
    final fallback = _speakerFallbacks[speaker] ?? ('💬', const Color(0xFFE0E0E0));

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: fallback.$2,
        shape: BoxShape.circle,
        border: Border.all(
          color: AppTheme.accentSecondary.withAlpha(80),
          width: 1.5,
        ),
      ),
      child: ClipOval(
        child: avatarPath != null
            ? Image.asset(
                avatarPath,
                width: 40,
                height: 40,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Center(
                  child: Text(fallback.$1,
                      style: const TextStyle(fontSize: AppTheme.fontDisplayMd)),
                ),
              )
            : Center(
                child: Text(fallback.$1,
                    style: const TextStyle(fontSize: AppTheme.fontDisplayMd)),
              ),
      ),
    );
  }
}
