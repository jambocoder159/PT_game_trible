import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/tutorial_dialogue_data.dart';
import '../providers/tutorial_provider.dart';
import '../widgets/tutorial_dialogue_box.dart';

/// Phase 2：劇情過場 — 地下室有聲音 → 拿鑰匙 → 開門
/// 可跳過的劇情過場
class Phase2CutsceneScreen extends StatefulWidget {
  const Phase2CutsceneScreen({super.key});

  @override
  State<Phase2CutsceneScreen> createState() => _Phase2CutsceneScreenState();
}

class _Phase2CutsceneScreenState extends State<Phase2CutsceneScreen>
    with SingleTickerProviderStateMixin {
  int _dialogueIndex = 0;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  static const _dialogues = TutorialDialogues.phase2;

  // 每段對話的場景配色 + emoji
  static const _sceneEmojis = ['🔊', '🔑', '🚪', '⚔️'];
  static const _sceneColors = [
    [Color(0xFF5D4037), Color(0xFF3E2723)],
    [Color(0xFF6D4C41), Color(0xFF4E342E)],
    [Color(0xFF4E342E), Color(0xFF3E2723)],
    [Color(0xFF3E2723), Color(0xFF212121)],
  ];

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 8).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
    // 第一段對話：地下室震動
    _shakeController.repeat(reverse: true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) _shakeController.stop();
    });
  }

  void _nextDialogue() {
    if (_dialogueIndex >= _dialogues.length - 1) {
      _complete();
      return;
    }
    setState(() => _dialogueIndex++);
  }

  void _complete() {
    context.read<TutorialProvider>().advancePhase();
  }

  void _skip() {
    context.read<TutorialProvider>().skipPhase();
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = _sceneColors[_dialogueIndex.clamp(0, _sceneColors.length - 1)];
    final emoji = _sceneEmojis[_dialogueIndex.clamp(0, _sceneEmojis.length - 1)];

    return Scaffold(
      backgroundColor: Colors.black,
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: colors.map((c) => c).toList(),
          ),
        ),
        child: Stack(
          children: [
            // 場景插圖 placeholder
            Center(
              child: AnimatedBuilder(
                animation: _shakeAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(_shakeAnimation.value, 0),
                    child: child,
                  );
                },
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(20),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(emoji, style: const TextStyle(fontSize: 72)),
                  ),
                ),
              ),
            ),

            // 對話框
            TutorialDialogueBox(
              dialogue: _dialogues[_dialogueIndex],
              onTap: _nextDialogue,
              onComplete: () {
                if (_dialogues[_dialogueIndex].autoAdvanceDelay != null) {
                  _nextDialogue();
                }
              },
            ),

            // 跳過按鈕
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              right: 16,
              child: TextButton(
                onPressed: _skip,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(80),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    '跳過 →',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
