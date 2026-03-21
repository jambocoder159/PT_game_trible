import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../core/models/block.dart';
import '../providers/game_provider.dart';
import 'block_widget.dart';

/// 遊戲棋盤 — 使用 Stack + AnimatedPositioned 實現流暢動畫
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
            final blockByHeight =
                (availableHeight / numRows) - AppTheme.blockGap;

            // 取較小值確保不溢出
            final blockSize = blockByWidth
                .clamp(36.0, AppTheme.blockSize)
                .clamp(36.0, blockByHeight.clamp(36.0, AppTheme.blockSize));

            final cellSize = blockSize + AppTheme.blockGap;
            final boardWidth =
                numCols * cellSize + AppTheme.blockGap;
            final boardHeight = numRows * cellSize + AppTheme.blockGap;

            // 收集所有方塊
            final List<Widget> blockWidgets = [];
            for (int col = 0; col < numCols; col++) {
              for (int row = 0; row < numRows; row++) {
                final block = state.grid[col][row];
                if (block == null) continue;

                final left = AppTheme.blockGap + col * cellSize;
                final top = AppTheme.blockGap + row * cellSize;

                blockWidgets.add(
                  AnimatedPositioned(
                    key: ValueKey(block.id),
                    duration: AppTheme.animDrop,
                    curve: Curves.easeOutCubic,
                    left: left,
                    top: top,
                    width: blockSize,
                    height: blockSize,
                    child: _BlockGestureHandler(
                      col: col,
                      row: row,
                      blockSize: blockSize,
                      game: game,
                      child: BlockWidget(block: block, size: blockSize),
                    ),
                  ),
                );
              }
            }

            return Container(
              width: boardWidth,
              height: boardHeight,
              decoration: BoxDecoration(
                color: AppTheme.bgSecondary.withAlpha(180),
                borderRadius:
                    BorderRadius.circular(AppTheme.radiusLarge),
                border: Border.all(
                  color: AppTheme.accentPrimary.withAlpha(100),
                  width: 1.5,
                ),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // 背景格子（淡色參考線）
                  ...List.generate(numCols * numRows, (i) {
                    final col = i ~/ numRows;
                    final row = i % numRows;
                    return Positioned(
                      left: AppTheme.blockGap + col * cellSize,
                      top: AppTheme.blockGap + row * cellSize,
                      child: Container(
                        width: blockSize,
                        height: blockSize,
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(8),
                          borderRadius: BorderRadius.circular(
                              AppTheme.radiusBlock),
                        ),
                      ),
                    );
                  }),
                  // 方塊層
                  ...blockWidgets,
                ],
              ),
            );
          },
        );
      },
    );
  }
}

/// 處理方塊的滑動和點擊手勢
class _BlockGestureHandler extends StatefulWidget {
  final int col;
  final int row;
  final double blockSize;
  final GameProvider game;
  final Widget child;

  const _BlockGestureHandler({
    required this.col,
    required this.row,
    required this.blockSize,
    required this.game,
    required this.child,
  });

  @override
  State<_BlockGestureHandler> createState() => _BlockGestureHandlerState();
}

class _BlockGestureHandlerState extends State<_BlockGestureHandler> {
  Offset? _dragStart;
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (!_isDragging) {
          widget.game.tapBlock(widget.col, widget.row);
        }
      },
      onVerticalDragStart: (details) {
        _dragStart = details.globalPosition;
        _isDragging = false;
      },
      onVerticalDragUpdate: (details) {
        if (_dragStart == null) return;
        final dy = details.globalPosition.dy - _dragStart!.dy;
        if (dy.abs() > 15) {
          _isDragging = true;
        }
      },
      onVerticalDragEnd: (details) {
        if (_dragStart == null) return;
        final velocity = details.primaryVelocity ?? 0;

        if (_isDragging || velocity.abs() > 100) {
          if (velocity < -80) {
            widget.game.moveBlockToTop(widget.col, widget.row);
          } else if (velocity > 80) {
            widget.game.moveBlockToBottom(widget.col, widget.row);
          }
        }
        _dragStart = null;
        _isDragging = false;
      },
      child: widget.child,
    );
  }
}
