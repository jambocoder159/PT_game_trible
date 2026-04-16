import 'dart:async';
import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../core/widgets/paper_dialog.dart';
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
      left: 12,
      right: 12,
      bottom: MediaQuery.of(context).padding.bottom + 16,
      child: GestureDetector(
        onTap: _handleTap,
        child: PaperBody(
          style: PaperStyle.note,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 說話者徽章 + 名稱（含上下裝飾線）
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildSpeakerAvatar(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.dialogue.speaker,
                          style: TextStyle(
                            color: const Color(0xFF8B4F1A),
                            fontSize: AppTheme.fontTitleMd,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                            shadows: [
                              Shadow(
                                color: Colors.white.withAlpha(180),
                                offset: const Offset(0, -0.5),
                              ),
                              Shadow(
                                color: Colors.black.withAlpha(50),
                                offset: const Offset(0, 1),
                                blurRadius: 1,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 2),
                        // 裝飾線
                        Container(
                          height: 1,
                          width: 60,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFFB18A4A),
                                const Color(0xFFB18A4A).withAlpha(0),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // 對話內容（打字機效果，加微浮雕）
              Text(
                _displayedText,
                style: TextStyle(
                  color: const Color(0xFF3D2817),
                  fontSize: AppTheme.fontTitleMd,
                  height: 1.65,
                  shadows: [
                    Shadow(
                      color: Colors.white.withAlpha(140),
                      offset: const Offset(0, -0.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              // 點擊提示
              if (_isComplete &&
                  widget.showTapHint &&
                  widget.dialogue.autoAdvanceDelay == null)
                FadeTransition(
                  opacity: _blinkController,
                  child: Center(
                    child: Text(
                      '▼ 點擊繼續',
                      style: TextStyle(
                        color: const Color(0xFF8B6230),
                        fontSize: AppTheme.fontBodyMd,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
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

    // 金屬框徽章 — 雙層邊框 + 內外陰影 + 漸層
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          center: Alignment(-0.4, -0.4),
          colors: [
            Color(0xFFFFE9B0),
            Color(0xFFD9B96A),
            Color(0xFFB18A4A),
          ],
          stops: [0.0, 0.6, 1.0],
        ),
        boxShadow: [
          // 外光暈
          BoxShadow(
            color: const Color(0xFFE8723A).withAlpha(60),
            blurRadius: 8,
            spreadRadius: 0.5,
          ),
          // 落地陰影
          BoxShadow(
            color: Colors.black.withAlpha(80),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(2.5),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: fallback.$2,
          border: Border.all(
            color: const Color(0xFF6B4226).withAlpha(120),
            width: 0.8,
          ),
        ),
        child: ClipOval(
          child: avatarPath != null
              ? Image.asset(
                  avatarPath,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Center(
                    child: Text(fallback.$1,
                        style: const TextStyle(
                            fontSize: AppTheme.fontDisplayMd)),
                  ),
                )
              : Center(
                  child: Text(fallback.$1,
                      style: const TextStyle(fontSize: AppTheme.fontDisplayMd)),
                ),
        ),
      ),
    );
  }
}
