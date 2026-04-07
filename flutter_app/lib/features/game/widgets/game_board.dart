import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../core/models/block.dart';
import '../providers/game_provider.dart';
import 'block_widget.dart';
import 'chain_ripple.dart';
import 'score_popup.dart';

/// 遊戲棋盤 — Stack + AnimatedPositioned + 長按拖曳引導
class GameBoard extends StatefulWidget {
  /// 教學提示：高亮指定方塊 (col, row)，null 表示不顯示
  final ({int col, int row})? tutorialHintBlock;

  const GameBoard({super.key, this.tutorialHintBlock});

  @override
  State<GameBoard> createState() => _GameBoardState();
}

class _GameBoardState extends State<GameBoard>
    with SingleTickerProviderStateMixin {
  // 分數彈出
  final List<_ScorePopupData> _activePopups = [];
  int _popupIdCounter = 0;

  // 連鎖波紋
  final List<_RippleData> _activeRipples = [];
  int _rippleIdCounter = 0;

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

  // 快取棋盤佈局（第一次計算後鎖定，防止動態 UI 變化導致棋盤大小跳動）
  _BoardLayout? _cachedLayout;
  int _cachedCols = 0;
  int _cachedRows = 0;

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

  /// 計算方塊佈局參數（第一次計算後快取，避免動態 UI 造成棋盤抖動）
  _BoardLayout _calcLayout(
      BoxConstraints constraints, int numCols, int numRows) {
    // 如果行列不變，直接返回快取
    if (_cachedLayout != null && _cachedCols == numCols && _cachedRows == numRows) {
      return _cachedLayout!;
    }

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
    final layout = _BoardLayout(
      blockSize: blockSize,
      cellSize: cellSize,
      boardWidth: numCols * cellSize + AppTheme.blockGap,
      boardHeight: numRows * cellSize + AppTheme.blockGap,
    );

    _cachedLayout = layout;
    _cachedCols = numCols;
    _cachedRows = numRows;
    return layout;
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

            // ── 消費分數彈出事件 ──
            final popups = game.consumeScorePopups();
            for (final popup in popups) {
              final pos = _cellTopLeft(layout, popup.col, popup.row);
              final id = _popupIdCounter++;
              _activePopups.add(_ScorePopupData(
                id: id,
                points: popup.points,
                combo: popup.combo,
                position: Offset(
                  pos.dx + layout.blockSize / 2 - 30,
                  pos.dy,
                ),
              ));
            }

            // ── 消費連鎖波紋事件 ──
            final ripples = game.consumeChainRipples();
            for (final ripple in ripples) {
              final pos = _cellTopLeft(layout, ripple.col, ripple.row);
              final id = _rippleIdCounter++;
              final block = state.grid[ripple.col][ripple.row];
              _activeRipples.add(_RippleData(
                id: id,
                center: Offset(
                  pos.dx + layout.blockSize / 2,
                  pos.dy + layout.blockSize / 2,
                ),
                color: block?.color.color ?? Colors.white,
                maxRadius: layout.blockSize * (1.5 + ripple.chainCount * 0.3),
              ));
            }

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
                    duration: const Duration(milliseconds: 500),
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
                        child: BlockWidget(
                            block: block, size: layout.blockSize),
                      ),
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
                      // 教學遮罩（遮暗其他方塊，挖出目標方塊）
                      if (widget.tutorialHintBlock != null && !_isDragging)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: CustomPaint(
                              painter: _BoardSpotlightPainter(
                                highlightRect: _getBlockRect(layout, widget.tutorialHintBlock!),
                              ),
                            ),
                          ),
                        ),
                      // 教學方塊高亮提示
                      if (widget.tutorialHintBlock != null && !_isDragging)
                        _buildTutorialBlockHint(layout),
                      // 箭頭層
                      ...arrowWidgets,
                      // 浮動拖曳方塊
                      ...floatingWidgets,
                      // 連鎖波紋
                      ..._activeRipples.map((data) => ChainRipple(
                            key: ValueKey('ripple_${data.id}'),
                            position: data.center,
                            color: data.color,
                            maxRadius: data.maxRadius,
                            onComplete: () {
                              setState(() {
                                _activeRipples
                                    .removeWhere((r) => r.id == data.id);
                              });
                            },
                          )),
                      // 分數彈出
                      ..._activePopups.map((data) => ScorePopup(
                            key: ValueKey('popup_${data.id}'),
                            points: data.points,
                            combo: data.combo,
                            position: data.position,
                            onComplete: () {
                              setState(() {
                                _activePopups
                                    .removeWhere((p) => p.id == data.id);
                              });
                            },
                          )),
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

  /// 取得方塊的 Rect
  Rect _getBlockRect(_BoardLayout layout, ({int col, int row}) hint) {
    final pos = _cellTopLeft(layout, hint.col, hint.row);
    return Rect.fromLTWH(pos.dx, pos.dy, layout.blockSize, layout.blockSize);
  }

  /// 教學方塊高亮 — 脈動邊框 + 下箭頭
  Widget _buildTutorialBlockHint(_BoardLayout layout) {
    final hint = widget.tutorialHintBlock!;
    final pos = _cellTopLeft(layout, hint.col, hint.row);

    return Positioned(
      left: pos.dx - 4,
      top: pos.dy - 4,
      width: layout.blockSize + 8,
      height: layout.blockSize + 8,
      child: IgnorePointer(
        child: _TutorialBlockGlow(
          blockSize: layout.blockSize,
        ),
      ),
    );
  }
}

/// 教學方塊發光動畫（脈動邊框 + 下箭頭）
class _TutorialBlockGlow extends StatefulWidget {
  final double blockSize;

  const _TutorialBlockGlow({required this.blockSize});

  @override
  State<_TutorialBlockGlow> createState() => _TutorialBlockGlowState();
}

class _TutorialBlockGlowState extends State<_TutorialBlockGlow>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulse;
  late Animation<double> _arrowBounce;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    _arrowBounce = Tween<double>(begin: 0, end: 8).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            // 脈動邊框
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTheme.radiusBlock + 2),
                border: Border.all(
                  color: Colors.amber.withAlpha((_pulse.value * 230).toInt()),
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withAlpha((_pulse.value * 80).toInt()),
                    blurRadius: 12,
                    spreadRadius: 3,
                  ),
                ],
              ),
            ),
            // 下箭頭
            Positioned(
              left: (widget.blockSize + 8 - 28) / 2,
              bottom: -28 - _arrowBounce.value,
              child: Icon(
                Icons.keyboard_double_arrow_down_rounded,
                color: Colors.amber.withAlpha((_pulse.value * 240).toInt()),
                size: 28,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// 棋盤聚光燈畫筆（遮暗整個棋盤，挖出目標方塊）
class _BoardSpotlightPainter extends CustomPainter {
  final Rect highlightRect;

  _BoardSpotlightPainter({required this.highlightRect});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withAlpha(150);
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(
          highlightRect.inflate(3), const Radius.circular(16)))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _BoardSpotlightPainter old) =>
      old.highlightRect != highlightRect;
}

/// 處理棋盤觸控事件的透明層
/// 使用 Listener 處理原始指標事件，同時支援：
/// - 滑動：進入拖曳模式（與長按相同，放開才執行）
/// - 長按：進入拖曳模式（顯示箭頭引導）
/// - 點擊：消除方塊
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
  // 指標追蹤
  Offset? _downPos;
  int? _downCol;
  int? _downRow;
  Block? _downBlock;
  bool _isSwipeDetected = false;
  bool _longPressActivated = false;

  // 長按計時器
  static const _longPressDuration = Duration(milliseconds: 150);

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

  void _onPointerDown(PointerDownEvent event) {
    if (widget.isDragging) return;
    final hit = _hitTest(event.localPosition);
    if (hit == null) {
      _downPos = null;
      return;
    }
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

    // 啟動長按計時
    Future.delayed(_longPressDuration, () {
      if (_downPos != null && !_isSwipeDetected && !_longPressActivated) {
        _longPressActivated = true;
        widget.onLongPressStart(
            _downCol!, _downRow!, _downBlock!, _downPos!);
      }
    });
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (_downPos == null) return;

    // 已進入拖曳模式（長按或滑動觸發）→ 委託給現有拖曳邏輯
    if ((_longPressActivated || _isSwipeDetected) && widget.isDragging) {
      widget.onDragUpdate(event.localPosition);
      return;
    }

    // 尚未進入任何模式 → 偵測滑動，進入拖曳模式
    if (!_longPressActivated && !_isSwipeDetected) {
      final dy = event.localPosition.dy - _downPos!.dy;
      final dx = (event.localPosition.dx - _downPos!.dx).abs();
      final swipeThreshold = widget.layout.blockSize * 0.35;

      // 垂直滑動距離超過門檻，且垂直 > 水平（確認是上下滑）
      if (dy.abs() > swipeThreshold && dy.abs() > dx) {
        _isSwipeDetected = true;
        HapticFeedback.lightImpact();
        // 進入拖曳模式（與長按相同），放開才執行
        widget.onLongPressStart(
            _downCol!, _downRow!, _downBlock!, event.localPosition);
      }
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    if (_downPos == null && !widget.isDragging) return;

    // 拖曳模式結束（長按或滑動觸發的）
    if ((_longPressActivated || _isSwipeDetected) && widget.isDragging) {
      widget.onDragEnd();
      _resetState();
      return;
    }

    // 沒有滑動也沒有長按 → 視為點擊
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

/// 連鎖波紋資料
class _RippleData {
  final int id;
  final Offset center;
  final Color color;
  final double maxRadius;

  const _RippleData({
    required this.id,
    required this.center,
    required this.color,
    required this.maxRadius,
  });
}

/// 分數彈出資料
class _ScorePopupData {
  final int id;
  final int points;
  final int combo;
  final Offset position;

  const _ScorePopupData({
    required this.id,
    required this.points,
    required this.combo,
    required this.position,
  });
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
