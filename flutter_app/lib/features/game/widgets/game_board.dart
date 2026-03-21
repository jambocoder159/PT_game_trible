import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../providers/game_provider.dart';
import 'block_widget.dart';

/// 遊戲棋盤 — 顯示所有方塊並處理觸控輸入
class GameBoard extends StatelessWidget {
  const GameBoard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, game, child) {
        final state = game.state;
        if (state == null) {
          return const Center(child: Text('等待遊戲開始...'));
        }

        final numCols = state.mode.numCols;
        final numRows = state.mode.numRows;

        return LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = MediaQuery.of(context).size.width;

            // 根據寬度計算方塊大小
            final totalGapsW = (numCols + 1) * AppTheme.blockGap;
            final availableWidth = screenWidth * 0.85 - totalGapsW;
            final blockByWidth = availableWidth / numCols;

            // 根據高度計算方塊大小（預留預覽列 + 間距）
            final previewHeight = 40.0;
            final boardPadding = 16.0; // padding * 2
            final availableHeight = constraints.maxHeight - previewHeight - 12 - boardPadding;
            final blockByHeight = (availableHeight / numRows) - AppTheme.blockGap;

            // 取較小值確保不溢出
            final blockSize = blockByWidth.clamp(36.0, AppTheme.blockSize)
                .clamp(36.0, blockByHeight.clamp(36.0, AppTheme.blockSize));

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 下一個方塊預覽
                _NextBlockPreview(
                  nextColors: state.nextBlockColors,
                  blockSize: blockSize * 0.6,
                ),
                const SizedBox(height: 12),

                // 棋盤
                GestureDetector(
                  onTapUp: (details) {
                    // 計算點擊了哪一列
                    final boardWidth = numCols * (blockSize + AppTheme.blockGap) - AppTheme.blockGap;
                    final boardLeft = (screenWidth - boardWidth) / 2;
                    final localX = details.globalPosition.dx - boardLeft;
                    final col = (localX / (blockSize + AppTheme.blockGap)).floor();
                    if (col >= 0 && col < numCols) {
                      game.placeBlock(col);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.bgSecondary.withAlpha(180),
                      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                      border: Border.all(
                        color: AppTheme.accentPrimary.withAlpha(100),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: List.generate(numCols, (col) {
                        return Padding(
                          padding: EdgeInsets.only(
                            left: col > 0 ? AppTheme.blockGap : 0,
                          ),
                          child: _buildColumn(state.grid[col], numRows, blockSize),
                        );
                      }),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildColumn(List<dynamic> column, int numRows, double blockSize) {
    return SizedBox(
      width: blockSize,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(numRows, (row) {
          final block = column[row];
          if (block == null) {
            return SizedBox(
              width: blockSize,
              height: blockSize + AppTheme.blockGap,
            );
          }
          return Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.blockGap),
            child: BlockWidget(block: block, size: blockSize),
          );
        }),
      ),
    );
  }
}

class _NextBlockPreview extends StatelessWidget {
  final List<dynamic> nextColors;
  final double blockSize;

  const _NextBlockPreview({
    required this.nextColors,
    required this.blockSize,
  });

  @override
  Widget build(BuildContext context) {
    if (nextColors.isEmpty) return const SizedBox.shrink();

    final color = nextColors.first;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '下一個：',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(width: 8),
        Container(
          width: blockSize,
          height: blockSize,
          decoration: BoxDecoration(
            color: color.color,
            borderRadius: BorderRadius.circular(AppTheme.radiusBlock * 0.6),
            boxShadow: [
              BoxShadow(
                color: color.color.withAlpha(100),
                blurRadius: 6,
              ),
            ],
          ),
          child: Center(
            child: Text(
              color.symbol,
              style: TextStyle(
                fontSize: blockSize * 0.4,
                color: Colors.white.withAlpha(200),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
