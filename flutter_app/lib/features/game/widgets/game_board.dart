import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../core/models/block.dart';
import '../providers/game_provider.dart';
import 'block_widget.dart';

/// 遊戲棋盤 — Stack + AnimatedPositioned + 長按拖曳引導
class GameBoard extends StatefulWidget {
  const GameBoard({super.key});

  @override
  State<GameBoard> createState() => _GameBoardState();
}

class _GameBoardState extends State<GameBoard>
    with SingleTickerProviderStateMixin {
  // 拖曳狀態
  bool _isDragging = false;
  int _dragCol = 0;
  int _dragRow = 0;
  Block? _dragBlock;
  Offset _dragLocalPos = Offset.zero; // 手指在棋盤內的座標
  Offset _dragOriginCenter = Offset.zero; // 原位中心點

  // 箭頭彈跳動畫
  late AnimationController _arrowBounce;
  late Animation<double> _arrowOffset;

  // 長按計時
  bool _longPressActivated = false;

  @override
  void initState() {
    super.initState();
    _arrowBounce = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _arrowOffset = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -10), weight: 50),
      TweenSequenceItem(tween: Tween(begin: -10, end: 0), weight: 50),
    ]).animate(CurvedAnimation(
      parent: _arrowBounce,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _arrowBounce.dispose();
    super.dispose();
  }

  /// 計算方塊佈局參數
  _BoardLayout _calcLayout(
      BoxConstraints constraints, int numCols, int numRows) {
    final screenWidth = MediaQuery.of(context).size.width;
    final totalGapsW = (numCols + 1) * AppTheme.blockGap;
    final availableWidth = screenWidth * 0.85 - totalGapsW;
    final blockByWidth = availableWidth / numCols;
    final boardPadding = 16.0;
    final availableHeight = constraints.maxHeight - boardPadding;
    final blockByHeight = (availableHeight / numRows) - AppTheme.blockGap;
    final blockSize = blockByWidth
        .clamp(36.0, AppTheme.blockSize)
        .clamp(36.0, blockByHeight.clamp(36.0, AppTheme.blockSize));
    final cellSize = blockSize + AppTheme.blockGap;
    return _BoardLayout(
      blockSize: blockSize,
      cellSize: cellSize,
      boardWidth: numCols * cellSize + AppTheme.blockGap,
      boardHeight: numRows * cellSize + AppTheme.blockGap,
    );
  }

  /// 取得格子左上角座標
  Offset _cellTopLeft(_BoardLayout layout, int col, int row) {
    return Offset(
      AppTheme.blockGap + col * layout.cellSize,
      AppTheme.blockGap + row * layout.cellSize,
    );
  }

  /// 判斷拖曳方向：-1=上, 0=原位, 1=下
  int _dragDirection(_BoardLayout layout) {
    final dy = _dragLocalPos.dy - _dragOriginCenter.dy;
    final threshold = layout.blockSize * 0.5;
    if (dy < -threshold) return -1; // 上
    if (dy > threshold) return 1; // 下
    return 0;
  }

  void _startDrag(int col, int row, Block block, _BoardLayout layout,
      Offset localPosition) {
    final origin = _cellTopLeft(layout, col, row);
    setState(() {
      _isDragging = true;
      _dragCol = col;
      _dragRow = row;
      _dragBlock = block;
      _dragLocalPos = localPosition;
      _dragOriginCenter = Offset(
        origin.dx + layout.blockSize / 2,
        origin.dy + layout.blockSize / 2,
      );
    });
    _arrowBounce.repeat();
    HapticFeedback.mediumImpact();
  }

  void _updateDrag(Offset localPosition) {
    if (!_isDragging) return;
    setState(() {
      _dragLocalPos = localPosition;
    });
  }

  void _endDrag(GameProvider game, _BoardLayout layout) {
    if (!_isDragging) return;
    final dir = _dragDirection(layout);
    if (dir == -1) {
      game.moveBlockToTop(_dragCol, _dragRow);
    } else if (dir == 1) {
      game.moveBlockToBottom(_dragCol, _dragRow);
    }
    // dir == 0 → 放回原位 → 取消
    _cancelDrag();
  }

  void _cancelDrag() {
    _arrowBounce.stop();
    setState(() {
      _isDragging = false;
      _dragBlock = null;
    });
  }

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
            final layout = _calcLayout(constraints, numCols, numRows);

            // ── 收集方塊 Widget ──
            final List<Widget> blockWidgets = [];
            for (int col = 0; col < numCols; col++) {
              for (int row = 0; row < numRows; row++) {
                final block = state.grid[col][row];
                if (block == null) continue;

                final pos = _cellTopLeft(layout, col, row);
                final isBeingDragged =
                    _isDragging && col == _dragCol && row == _dragRow;

                blockWidgets.add(
                  AnimatedPositioned(
                    key: ValueKey(block.id),
                    duration: AppTheme.animDrop,
                    curve: Curves.easeOutCubic,
                    left: pos.dx,
                    top: pos.dy,
                    width: layout.blockSize,
                    height: layout.blockSize,
                    child: AnimatedOpacity(
                      opacity: isBeingDragged ? 0.25 : 1.0,
                      duration: const Duration(milliseconds: 150),
                      child: BlockWidget(
                          block: block, size: layout.blockSize),
                    ),
                  ),
                );
              }
            }

            // ── 箭頭指示器 ──
            final List<Widget> arrowWidgets = [];
            if (_isDragging) {
              final dir = _dragDirection(layout);
              final originPos = _cellTopLeft(layout, _dragCol, _dragRow);
              final arrowSize = layout.blockSize * 0.65;

              arrowWidgets.addAll([
                // 上箭頭
                AnimatedBuilder(
                  animation: _arrowOffset,
                  builder: (context, child) {
                    return Positioned(
                      left: originPos.dx +
                          (layout.blockSize - arrowSize) / 2,
                      top: originPos.dy - arrowSize - 4 + _arrowOffset.value,
                      child: _ArrowIcon(
                        direction: -1,
                        size: arrowSize,
                        isSolid: dir == -1,
                        color: _dragBlock?.color.color ??
                            AppTheme.textPrimary,
                      ),
                    );
                  },
                ),
                // 下箭頭
                AnimatedBuilder(
                  animation: _arrowOffset,
                  builder: (context, child) {
                    return Positioned(
                      left: originPos.dx +
                          (layout.blockSize - arrowSize) / 2,
                      top: originPos.dy +
                          layout.blockSize +
                          4 -
                          _arrowOffset.value,
                      child: _ArrowIcon(
                        direction: 1,
                        size: arrowSize,
                        isSolid: dir == 1,
                        color: _dragBlock?.color.color ??
                            AppTheme.textPrimary,
                      ),
                    );
                  },
                ),
              ]);
            }

            // ── 浮動拖曳方塊 ──
            final List<Widget> floatingWidgets = [];
            if (_isDragging && _dragBlock != null) {
              floatingWidgets.add(
                Positioned(
                  left: _dragLocalPos.dx - layout.blockSize / 2,
                  top: _dragLocalPos.dy - layout.blockSize / 2,
                  child: IgnorePointer(
                    child: Transform.scale(
                      scale: 1.1,
                      child: Opacity(
                        opacity: 0.85,
                        child: BlockWidget(
                          block: _dragBlock!,
                          size: layout.blockSize,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }

            return GestureDetector(
              // 點擊棋盤外部取消拖曳
              onTap: () {
                if (_isDragging) _cancelDrag();
              },
              child: Container(
                width: layout.boardWidth,
                height: layout.boardHeight,
                decoration: BoxDecoration(
                  color: AppTheme.bgSecondary.withAlpha(180),
                  borderRadius:
                      BorderRadius.circular(AppTheme.radiusLarge),
                  border: Border.all(
                    color: AppTheme.accentPrimary.withAlpha(100),
                    width: 1.5,
                  ),
                ),
                child: _BoardInteractionLayer(
                  layout: layout,
                  numCols: numCols,
                  numRows: numRows,
                  game: game,
                  isDragging: _isDragging,
                  onTapBlock: (col, row, block) {
                    if (_isDragging) {
                      _cancelDrag();
                      return;
                    }
                    game.tapBlock(col, row);
                  },
                  onLongPressStart: (col, row, block, localPos) {
                    _startDrag(col, row, block, layout, localPos);
                  },
                  onDragUpdate: (localPos) {
                    _updateDrag(localPos);
                  },
                  onDragEnd: () {
                    _endDrag(game, layout);
                  },
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // 背景格子
                      ...List.generate(numCols * numRows, (i) {
                        final col = i ~/ numRows;
                        final row = i % numRows;
                        final pos = _cellTopLeft(layout, col, row);
                        return Positioned(
                          left: pos.dx,
                          top: pos.dy,
                          child: Container(
                            width: layout.blockSize,
                            height: layout.blockSize,
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
                      // 箭頭層
                      ...arrowWidgets,
                      // 浮動拖曳方塊
                      ...floatingWidgets,
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// 處理棋盤觸控事件的透明層
class _BoardInteractionLayer extends StatefulWidget {
  final _BoardLayout layout;
  final int numCols;
  final int numRows;
  final GameProvider game;
  final bool isDragging;
  final void Function(int col, int row, Block block) onTapBlock;
  final void Function(int col, int row, Block block, Offset localPos)
      onLongPressStart;
  final void Function(Offset localPos) onDragUpdate;
  final void Function() onDragEnd;
  final Widget child;

  const _BoardInteractionLayer({
    required this.layout,
    required this.numCols,
    required this.numRows,
    required this.game,
    required this.isDragging,
    required this.onTapBlock,
    required this.onLongPressStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.child,
  });

  @override
  State<_BoardInteractionLayer> createState() =>
      _BoardInteractionLayerState();
}

class _BoardInteractionLayerState extends State<_BoardInteractionLayer> {
  /// 由 local position 找到對應的 col, row
  (int col, int row)? _hitTest(Offset localPos) {
    final l = widget.layout;
    for (int col = 0; col < widget.numCols; col++) {
      for (int row = 0; row < widget.numRows; row++) {
        final left = AppTheme.blockGap + col * l.cellSize;
        final top = AppTheme.blockGap + row * l.cellSize;
        if (localPos.dx >= left &&
            localPos.dx <= left + l.blockSize &&
            localPos.dy >= top &&
            localPos.dy <= top + l.blockSize) {
          return (col, row);
        }
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return RawGestureDetector(
      gestures: <Type, GestureRecognizerFactory>{
        LongPressGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
          () => LongPressGestureRecognizer(
            duration: const Duration(milliseconds: 150),
          ),
          (instance) {
            instance
              ..onLongPressStart = (details) {
                if (widget.isDragging) return;
                final hit = _hitTest(details.localPosition);
                if (hit == null) return;
                final (col, row) = hit;
                final state = widget.game.state;
                if (state == null) return;
                final block = state.grid[col][row];
                if (block == null) return;
                widget.onLongPressStart(
                    col, row, block, details.localPosition);
              }
              ..onLongPressMoveUpdate = (details) {
                if (!widget.isDragging) return;
                widget.onDragUpdate(details.localPosition);
              }
              ..onLongPressEnd = (details) {
                if (!widget.isDragging) return;
                widget.onDragEnd();
              };
          },
        ),
        TapGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
          () => TapGestureRecognizer(),
          (instance) {
            instance.onTapUp = (details) {
        final hit = _hitTest(details.localPosition);
        if (hit == null) return;
        final (col, row) = hit;
        final state = widget.game.state;
        if (state == null) return;
        final block = state.grid[col][row];
        if (block == null) return;
        widget.onTapBlock(col, row, block);
            };
          },
        ),
      },
      behavior: HitTestBehavior.opaque,
      child: widget.child,
    );
  }
}

/// 箭頭圖示（飽滿或空心）
class _ArrowIcon extends StatelessWidget {
  final int direction; // -1=上, 1=下
  final double size;
  final bool isSolid;
  final Color color;

  const _ArrowIcon({
    required this.direction,
    required this.size,
    required this.isSolid,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final icon = direction == -1
        ? Icons.arrow_upward_rounded
        : Icons.arrow_downward_rounded;

    if (isSolid) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withAlpha(150),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(icon, size: size * 0.7, color: Colors.white),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color.withAlpha(80), width: 2),
      ),
      child: Icon(icon, size: size * 0.7, color: color.withAlpha(80)),
    );
  }
}

/// 棋盤佈局參數
class _BoardLayout {
  final double blockSize;
  final double cellSize;
  final double boardWidth;
  final double boardHeight;

  const _BoardLayout({
    required this.blockSize,
    required this.cellSize,
    required this.boardWidth,
    required this.boardHeight,
  });
}
