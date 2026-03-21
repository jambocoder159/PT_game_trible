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

            // 根據高度計算方塊大小
            final boardPadding = 16.0;
            final availableHeight = constraints.maxHeight - boardPadding;
            final blockByHeight = (availableHeight / numRows) - AppTheme.blockGap;

            // 取較小值確保不溢出
            final blockSize = blockByWidth.clamp(36.0, AppTheme.blockSize)
                .clamp(36.0, blockByHeight.clamp(36.0, AppTheme.blockSize));

            return Container(
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
                    child: _buildColumn(
                      state.grid[col],
                      numRows,
                      blockSize,
                      col,
                      state.selectedCol,
                      state.selectedRow,
                      game,
                    ),
                  );
                }),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildColumn(
    List<dynamic> column,
    int numRows,
    double blockSize,
    int col,
    int? selectedCol,
    int? selectedRow,
    GameProvider game,
  ) {
    return SizedBox(
      width: blockSize,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(numRows, (row) {
          final block = column[row];
          final isSelected = selectedCol == col && selectedRow == row;

          return Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.blockGap),
            child: GestureDetector(
              onTap: () {
                game.selectBlock(col, row);
              },
              child: block != null
                  ? BlockWidget(
                      block: block,
                      size: blockSize,
                      isSelected: isSelected,
                    )
                  : SizedBox(
                      width: blockSize,
                      height: blockSize,
                    ),
            ),
          );
        }),
      ),
    );
  }
}
