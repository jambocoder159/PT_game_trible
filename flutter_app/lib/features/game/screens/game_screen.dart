import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../core/models/game_state.dart';
import '../providers/game_provider.dart';
import '../widgets/game_board.dart';
import '../widgets/game_hud.dart';

/// 遊戲主畫面
class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer<GameProvider>(
          builder: (context, game, child) {
            final state = game.state;

            return Stack(
              children: [
                // 主遊戲區域
                Column(
                  children: [
                    // 頂部工具列
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.arrow_back),
                          ),
                          Text(
                            state?.mode.title ?? '',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          IconButton(
                            onPressed: () {
                              // TODO: 暫停/設定選單
                            },
                            icon: const Icon(Icons.settings),
                          ),
                        ],
                      ),
                    ),

                    // HUD
                    const GameHud(),

                    // 遊戲棋盤
                    const Expanded(
                      child: Center(
                        child: GameBoard(),
                      ),
                    ),

                    // 底部技能/道具列（預留空間）
                    const SizedBox(height: 80),
                  ],
                ),

                // 遊戲結束覆蓋層
                if (state?.status == GameStatus.gameOver)
                  _GameOverOverlay(
                    score: state!.score,
                    maxCombo: state.maxCombo,
                    actions: state.actionCount,
                    onRestart: () => game.startGame(state.mode),
                    onExit: () => Navigator.of(context).pop(),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _GameOverOverlay extends StatelessWidget {
  final int score;
  final int maxCombo;
  final int actions;
  final VoidCallback onRestart;
  final VoidCallback onExit;

  const _GameOverOverlay({
    required this.score,
    required this.maxCombo,
    required this.actions,
    required this.onRestart,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withAlpha(180),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.bgSecondary,
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            border: Border.all(
              color: AppTheme.accentPrimary.withAlpha(150),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '遊戲結束',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              _ResultRow(label: '分數', value: '$score'),
              _ResultRow(label: '最高 Combo', value: '$maxCombo'),
              _ResultRow(label: '操作次數', value: '$actions'),
              const SizedBox(height: 24),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    onPressed: onRestart,
                    child: const Text('再來一局'),
                  ),
                  const SizedBox(width: 16),
                  OutlinedButton(
                    onPressed: onExit,
                    child: const Text('返回選單'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  final String label;
  final String value;

  const _ResultRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16, color: AppTheme.textSecondary)),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
