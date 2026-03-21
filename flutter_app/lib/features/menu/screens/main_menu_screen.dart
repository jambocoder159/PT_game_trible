import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/game_modes.dart';
import '../../../config/theme.dart';
import '../../game/providers/game_provider.dart';
import '../../game/screens/game_screen.dart';

/// 主選單畫面
class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 遊戲標題
                const Text(
                  '三消挑戰',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Match-3 Puzzle',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.textSecondary.withAlpha(180),
                    letterSpacing: 6,
                  ),
                ),
                const SizedBox(height: 60),

                // 模式選擇按鈕
                ...GameModes.allModes.map((mode) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ModeButton(mode: mode),
                )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final GameModeConfig mode;

  const _ModeButton({required this.mode});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          context.read<GameProvider>().startGame(mode);
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const GameScreen()),
          );
        },
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 18),
          backgroundColor: AppTheme.bgCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            side: BorderSide(
              color: AppTheme.accentPrimary.withAlpha(100),
            ),
          ),
        ),
        child: Column(
          children: [
            Text(
              mode.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              mode.description,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary.withAlpha(180),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
