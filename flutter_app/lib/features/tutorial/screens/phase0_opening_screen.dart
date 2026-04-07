import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../models/tutorial_dialogue_data.dart';
import '../providers/tutorial_provider.dart';
import '../../agents/providers/player_provider.dart';

/// Phase 0：開場動畫
/// 4 頁故事幻燈片 + 信件內容，可跳過
class Phase0OpeningScreen extends StatefulWidget {
  const Phase0OpeningScreen({super.key});

  @override
  State<Phase0OpeningScreen> createState() => _Phase0OpeningScreenState();
}

class _Phase0OpeningScreenState extends State<Phase0OpeningScreen>
    with SingleTickerProviderStateMixin {
  final _pageController = PageController();
  int _currentPage = 0;
  Timer? _autoTimer;
  late AnimationController _fadeController;

  // 每頁的主題配色 + 背景圖 + fallback emoji
  static const _slides = [
    _SlideData(
      emoji: '🏘️',
      bgImage: 'assets/images/output/background/bg_tutorial_town.png',
      colors: [Color(0xFFFFF3E0), Color(0xFFFFE0B2)],
      dialogue: TutorialDialogues.t001,
    ),
    _SlideData(
      emoji: '🌙',
      bgImage: 'assets/images/output/background/bg_tutorial_night.png',
      colors: [Color(0xFFFFE0B2), Color(0xFFBCAAA4)],
      dialogue: TutorialDialogues.t002,
    ),
    // 信件特寫
    _SlideData(
      emoji: '✉️',
      bgImage: 'assets/images/output/background/bg_tutorial_letter.png',
      colors: [Color(0xFFFFF9C4), Color(0xFFFFE082)],
      dialogue: TutorialDialogues.t005,
      isLetter: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _startAutoAdvance();
  }

  void _startAutoAdvance() {
    _autoTimer?.cancel();
    _autoTimer = Timer(const Duration(seconds: 4), () {
      if (_currentPage < _slides.length - 1) {
        _goToPage(_currentPage + 1);
      }
    });
  }

  void _goToPage(int page) {
    if (page >= _slides.length) {
      _complete();
      return;
    }
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
    setState(() => _currentPage = page);
    _startAutoAdvance();
  }

  void _complete() {
    context.read<TutorialProvider>().advancePhase();
  }

  void _skip() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgSecondary,
        title: const Text('跳過開場？',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: const Text('您可以稍後在設定中重新觀看。',
            style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('繼續觀看'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _complete();
            },
            child: const Text('跳過',
                style: TextStyle(color: AppTheme.accentPrimary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context
                  .read<TutorialProvider>()
                  .skipEntireTutorial(context.read<PlayerProvider>());
            },
            child:
                const Text('跳過全部教學', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _fadeController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FadeTransition(
        opacity: _fadeController,
        child: Stack(
          children: [
            // 幻燈片
            PageView.builder(
              controller: _pageController,
              itemCount: _slides.length,
              onPageChanged: (page) {
                setState(() => _currentPage = page);
                _startAutoAdvance();
              },
              itemBuilder: (context, index) {
                final slide = _slides[index];
                return _buildSlide(slide);
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
                    style: TextStyle(color: Colors.white70, fontSize: AppTheme.fontBodyLg),
                  ),
                ),
              ),
            ),

            // 頁面指示器
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 40,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_slides.length, (i) {
                  final isActive = i == _currentPage;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: isActive ? 20 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isActive
                          ? Colors.white
                          : Colors.white.withAlpha(80),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),

            // 最後一頁的「開始」按鈕
            if (_currentPage == _slides.length - 1)
              Positioned(
                bottom: MediaQuery.of(context).padding.bottom + 70,
                left: 40,
                right: 40,
                child: ElevatedButton(
                  onPressed: _complete,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    '開始冒險！',
                    style: TextStyle(fontSize: AppTheme.fontTitleLg, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlide(_SlideData slide) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 背景圖（全螢幕）
        if (slide.bgImage != null)
          Image.asset(
            slide.bgImage!,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: slide.colors,
                ),
              ),
              child: Center(
                child: Text(slide.emoji, style: const TextStyle(fontSize: 80)),
              ),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: slide.colors,
              ),
            ),
          ),
        // 底部漸層遮罩（讓文字更清楚）
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: MediaQuery.of(context).size.height * 0.55,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withAlpha(0),
                  Colors.black.withAlpha(120),
                  Colors.black.withAlpha(180),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
        ),
        // 對話文字
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (slide.isLetter)
                  _buildLetterCard(slide)
                else
                  _buildNarration(slide),
                SizedBox(height: MediaQuery.of(context).size.height * 0.15),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNarration(_SlideData slide) {
    return Text(
      slide.dialogue.content,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: Colors.white,
        fontSize: AppTheme.fontTitleLg,
        height: 1.8,
        fontWeight: FontWeight.w500,
        shadows: [
          Shadow(color: Colors.black.withAlpha(180), blurRadius: 6),
        ],
      ),
    );
  }

  Widget _buildLetterCard(_SlideData slide) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFD7CCC8),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.brown.withAlpha(30),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        slide.dialogue.content,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xFF4E342E),
          fontSize: AppTheme.fontTitleLg,
          height: 2.0,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}

class _SlideData {
  final String emoji;
  final String? bgImage;
  final List<Color> colors;
  final TutorialDialogue dialogue;
  final bool isLetter;

  const _SlideData({
    required this.emoji,
    this.bgImage,
    required this.colors,
    required this.dialogue,
    this.isLetter = false,
  });
}
