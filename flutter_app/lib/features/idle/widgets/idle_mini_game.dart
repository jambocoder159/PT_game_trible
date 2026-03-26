import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../core/models/block.dart';
import '../../game/widgets/block_widget.dart';
import '../providers/idle_provider.dart';
import 'auto_eliminate_bar.dart';

/// 首頁簡化版消除遊戲（3×8 棋盤，支援點擊消除 + 長按/滑動移動）
class IdleMiniGame extends StatefulWidget {
  const IdleMiniGame({super.key});

  @override
  State<IdleMiniGame> createState() => _IdleMiniGameState();
}

class _IdleMiniGameState extends State<IdleMiniGame>
    with SingleTickerProviderStateMixin {
  // 拖曳狀態
  bool _isDragging = false;
  int _dragCol = 0;
  int _dragRow = 0;
  Block? _dragBlock;
  Offset _dragLocalPos = Offset.zero;
  Offset _dragOriginCenter = Offset.zero;

  // 箭頭動畫
  late AnimationController _arrowBounce;
  late Animation<double> _arrowOffset;

  @override
  void initState() {
    super.initState();
    _arrowBounce = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _arrowOffset = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -8), weight: 50),
      TweenSequenceItem(tween: Tween(begin: -8, end: 0), weight: 50),
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

  _BoardLayout _calcLayout(BoxConstraints constraints, int numCols, int numRows) {
    final gap = 3.0;
    final availableWidth = constraints.maxWidth - (numCols + 1) * gap;
    final availableHeight = constraints.maxHeight - (numRows + 1) * gap;
    final blockByWidth = availableWidth / numCols;
    final blockByHeight = availableHeight / numRows;
    final blockSize = blockByWidth.clamp(28.0, blockByHeight.clamp(28.0, 48.0));
    final cellSize = blockSize + gap;
    return _BoardLayout(
      blockSize: blockSize,
      cellSize: cellSize,
      gap: gap,
      boardWidth: numCols * cellSize + gap,
      boardHeight: numRows * cellSize + gap,
    );
  }

  Offset _cellTopLeft(_BoardLayout l, int col, int row) {
    return Offset(l.gap + col * l.cellSize, l.gap + row * l.cellSize);
  }

  int _dragDirection(_BoardLayout layout) {
    final dy = _dragLocalPos.dy - _dragOriginCenter.dy;
    final threshold = layout.blockSize * 0.5;
    if (dy < -threshold) return -1;
    if (dy > threshold) return 1;
    return 0;
  }

  void _startDrag(int col, int row, Block block, _BoardLayout layout, Offset localPos) {
    setState(() {
      _isDragging = true;
      _dragCol = col;
      _dragRow = row;
      _dragBlock = block;
      _dragLocalPos = localPos;
      final origin = _cellTopLeft(layout, col, row);
      _dragOriginCenter = Offset(
        origin.dx + layout.blockSize / 2,
        origin.dy + layout.blockSize / 2,
      );
    });
    _arrowBounce.repeat();
    HapticFeedback.mediumImpact();
  }

  void _endDrag(IdleProvider game, _BoardLayout layout) {
    if (!_isDragging) return;
    final dir = _dragDirection(layout);
    if (dir == -1) {
      game.moveBlockToTop(_dragCol, _dragRow);
    } else if (dir == 1) {
      game.moveBlockToBottom(_dragCol, _dragRow);
    }
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
    return Consumer<IdleProvider>(
      builder: (context, game, child) {
        final state = game.state;
        if (state == null) {
          return const Center(
            child: Text('載入中...', style: TextStyle(color: AppTheme.textSecondary)),
          );
        }

        final numCols = state.mode.numCols;
        final numRows = state.mode.numRows;

        return LayoutBuilder(
          builder: (context, constraints) {
            final layout = _calcLayout(constraints, numCols, numRows);

            // 方塊 widgets
            final List<Widget> blockWidgets = [];
            for (int col = 0; col < numCols; col++) {
              for (int row = 0; row < numRows; row++) {
                final block = state.grid[col][row];
                if (block == null) continue;
                final pos = _cellTopLeft(layout, col, row);
                final isBeingDragged = _isDragging && col == _dragCol && row == _dragRow;

                blockWidgets.add(
                  AnimatedPositioned(
                    key: ValueKey(block.id),
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.bounceOut,
                    left: pos.dx,
                    top: pos.dy,
                    width: layout.blockSize,
                    height: layout.blockSize,
                    child: OverflowBox(
                      maxWidth: layout.blockSize * 2.5,
                      maxHeight: layout.blockSize * 2.5,
                      child: AnimatedOpacity(
                        opacity: isBeingDragged ? 0.25 : 1.0,
                        duration: const Duration(milliseconds: 150),
                        child: BlockWidget(block: block, size: layout.blockSize),
                      ),
                    ),
                  ),
                );
              }
            }

            // 箭頭
            final List<Widget> arrowWidgets = [];
            if (_isDragging && _dragBlock != null) {
              final dir = _dragDirection(layout);
              final originPos = _cellTopLeft(layout, _dragCol, _dragRow);
              final arrowSize = layout.blockSize * 0.55;

              arrowWidgets.addAll([
                AnimatedBuilder(
                  animation: _arrowOffset,
                  builder: (_, __) => Positioned(
                    left: originPos.dx + (layout.blockSize - arrowSize) / 2,
                    top: originPos.dy - arrowSize - 2 + _arrowOffset.value,
                    child: _ArrowIcon(
                      direction: -1,
                      size: arrowSize,
                      isSolid: dir == -1,
                      color: _dragBlock!.color.color,
                    ),
                  ),
                ),
                AnimatedBuilder(
                  animation: _arrowOffset,
                  builder: (_, __) => Positioned(
                    left: originPos.dx + (layout.blockSize - arrowSize) / 2,
                    top: originPos.dy + layout.blockSize + 2 - _arrowOffset.value,
                    child: _ArrowIcon(
                      direction: 1,
                      size: arrowSize,
                      isSolid: dir == 1,
                      color: _dragBlock!.color.color,
                    ),
                  ),
                ),
              ]);
            }

            // 浮動拖曳方塊
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
                        child: BlockWidget(block: _dragBlock!, size: layout.blockSize),
                      ),
                    ),
                  ),
                ),
              );
            }

            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 操作提示
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.touch_app, size: 10, color: AppTheme.textSecondary.withAlpha(120)),
                        const SizedBox(width: 3),
                        Text(
                          '點擊消除',
                          style: TextStyle(color: AppTheme.textSecondary.withAlpha(120), fontSize: 9),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.swap_vert, size: 10, color: AppTheme.textSecondary.withAlpha(120)),
                        const SizedBox(width: 3),
                        Text(
                          '滑動放置',
                          style: TextStyle(color: AppTheme.textSecondary.withAlpha(120), fontSize: 9),
                        ),
                      ],
                    ),
                  ),
                  // 自動消除狀態列
                  const Padding(
                    padding: EdgeInsets.only(bottom: 3),
                    child: AutoEliminateBar(),
                  ),
                  // Combo 顯示（棋盤外部）
                  if (state.combo > 1)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.accentSecondary.withAlpha(200),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${state.combo}x Combo',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  _IdleInteractionLayer(
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
                  if (!_isDragging) return;
                  setState(() => _dragLocalPos = localPos);
                },
                onDragEnd: () => _endDrag(game, layout),
                child: Container(
                  width: layout.boardWidth,
                  height: layout.boardHeight,
                  decoration: BoxDecoration(
                    color: AppTheme.bgSecondary.withAlpha(200),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    border: Border.all(
                      color: AppTheme.accentPrimary.withAlpha(80),
                      width: 1,
                    ),
                  ),
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
                              color: Colors.white.withAlpha(6),
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusBlock * 0.8,
                              ),
                            ),
                          ),
                        );
                      }),
                      ...blockWidgets,
                      ...arrowWidgets,
                      ...floatingWidgets,
                    ],
                  ),
                ),
              ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

/// 觸控互動層（與 GameBoard 相同邏輯但操作 IdleProvider）
class _IdleInteractionLayer extends StatefulWidget {
  final _BoardLayout layout;
  final int numCols;
  final int numRows;
  final IdleProvider game;
  final bool isDragging;
  final void Function(int col, int row, Block block) onTapBlock;
  final void Function(int col, int row, Block block, Offset localPos) onLongPressStart;
  final void Function(Offset localPos) onDragUpdate;
  final VoidCallback onDragEnd;
  final Widget child;

  const _IdleInteractionLayer({
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
  State<_IdleInteractionLayer> createState() => _IdleInteractionLayerState();
}

class _IdleInteractionLayerState extends State<_IdleInteractionLayer> {
  Offset? _downPos;
  int? _downCol;
  int? _downRow;
  Block? _downBlock;
  bool _isSwipeDetected = false;
  bool _longPressActivated = false;

  static const _longPressDuration = Duration(milliseconds: 150);

  (int, int)? _hitTest(Offset localPos) {
    final l = widget.layout;
    for (int col = 0; col < widget.numCols; col++) {
      for (int row = 0; row < widget.numRows; row++) {
        final left = l.gap + col * l.cellSize;
        final top = l.gap + row * l.cellSize;
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

  void _onPointerDown(PointerDownEvent event) {
    if (widget.isDragging) return;
    final hit = _hitTest(event.localPosition);
    if (hit == null) { _downPos = null; return; }
    final (col, row) = hit;
    final state = widget.game.state;
    if (state == null) return;
    final block = state.grid[col][row];
    if (block == null) return;

    _downPos = event.localPosition;
    _downCol = col;
    _downRow = row;
    _downBlock = block;
    _isSwipeDetected = false;
    _longPressActivated = false;

    Future.delayed(_longPressDuration, () {
      if (_downPos != null && !_isSwipeDetected && !_longPressActivated) {
        _longPressActivated = true;
        widget.onLongPressStart(_downCol!, _downRow!, _downBlock!, _downPos!);
      }
    });
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (_downPos == null) return;
    if ((_longPressActivated || _isSwipeDetected) && widget.isDragging) {
      widget.onDragUpdate(event.localPosition);
      return;
    }
    if (!_longPressActivated && !_isSwipeDetected) {
      final dy = event.localPosition.dy - _downPos!.dy;
      final dx = (event.localPosition.dx - _downPos!.dx).abs();
      final threshold = widget.layout.blockSize * 0.35;
      if (dy.abs() > threshold && dy.abs() > dx) {
        _isSwipeDetected = true;
        HapticFeedback.lightImpact();
        widget.onLongPressStart(_downCol!, _downRow!, _downBlock!, event.localPosition);
      }
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    if (_downPos == null && !widget.isDragging) return;
    if ((_longPressActivated || _isSwipeDetected) && widget.isDragging) {
      widget.onDragEnd();
      _resetState();
      return;
    }
    if (!_isSwipeDetected && !_longPressActivated) {
      if (_downCol != null && _downRow != null && _downBlock != null) {
        widget.onTapBlock(_downCol!, _downRow!, _downBlock!);
      }
    }
    _resetState();
  }

  void _onPointerCancel(PointerCancelEvent event) {
    if ((_longPressActivated || _isSwipeDetected) && widget.isDragging) {
      widget.onDragEnd();
    }
    _resetState();
  }

  void _resetState() {
    _downPos = null;
    _downCol = null;
    _downRow = null;
    _downBlock = null;
    _isSwipeDetected = false;
    _longPressActivated = false;
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: _onPointerDown,
      onPointerMove: _onPointerMove,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerCancel,
      child: widget.child,
    );
  }
}

class _ArrowIcon extends StatelessWidget {
  final int direction;
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
            BoxShadow(color: color.withAlpha(150), blurRadius: 8, spreadRadius: 1),
          ],
        ),
        child: Icon(icon, size: size * 0.65, color: Colors.white),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color.withAlpha(80), width: 1.5),
      ),
      child: Icon(icon, size: size * 0.65, color: color.withAlpha(80)),
    );
  }
}

class _BoardLayout {
  final double blockSize;
  final double cellSize;
  final double gap;
  final double boardWidth;
  final double boardHeight;

  const _BoardLayout({
    required this.blockSize,
    required this.cellSize,
    required this.gap,
    required this.boardWidth,
    required this.boardHeight,
  });
}
