import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../../config/game_modes.dart';
import '../../../core/models/block.dart';
import '../../../core/models/game_state.dart';
import '../../../core/engine/match_detector.dart';
import '../../../core/engine/score_calculator.dart';

/// 遊戲核心 Provider — 管理整個遊戲流程
class GameProvider extends ChangeNotifier {
  static const _uuid = Uuid();
  final _random = Random();

  GameState? _state;
  GameState? get state => _state;

  Timer? _timer;
  bool _isProcessing = false;

  // ─── 遊戲生命週期 ───

  /// 以指定模式開始新遊戲
  void startGame(GameModeConfig mode) {
    _timer?.cancel();
    _state = GameState.initial(mode);
    _state!.status = GameStatus.playing;

    // 填滿整個棋盤（確保初始沒有匹配）
    _fillGrid();

    // 限時模式啟動計時器
    if (mode.hasTimer && mode.gameDuration > 0) {
      _startTimer();
    }

    notifyListeners();
  }

  /// 結束遊戲
  void endGame() {
    _timer?.cancel();
    if (_state != null) {
      _state!.status = GameStatus.gameOver;
      _state!.selectedCol = null;
      _state!.selectedRow = null;
      notifyListeners();
    }
  }

  /// 清理資源
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ─── 玩家操作 ───

  /// 玩家點擊某個方塊
  Future<void> selectBlock(int col, int row) async {
    final s = _state;
    if (s == null || s.status != GameStatus.playing || _isProcessing) return;

    // 確認點擊的位置有方塊
    if (s.grid[col][row] == null) return;

    // 如果已有選擇的方塊
    if (s.selectedCol != null && s.selectedRow != null) {
      final prevCol = s.selectedCol!;
      final prevRow = s.selectedRow!;

      // 點擊同一個方塊 → 取消選擇
      if (prevCol == col && prevRow == row) {
        s.selectedCol = null;
        s.selectedRow = null;
        notifyListeners();
        return;
      }

      // 檢查是否相鄰（上下左右）
      final isAdjacent = (prevCol == col && (prevRow - row).abs() == 1) ||
          (prevRow == row && (prevCol - col).abs() == 1);

      if (isAdjacent) {
        // 嘗試交換
        s.selectedCol = null;
        s.selectedRow = null;
        notifyListeners();
        await _trySwap(prevCol, prevRow, col, row);
        return;
      } else {
        // 不相鄰 → 改選新方塊
        s.selectedCol = col;
        s.selectedRow = row;
        notifyListeners();
        return;
      }
    }

    // 還沒有選擇 → 選擇此方塊
    s.selectedCol = col;
    s.selectedRow = row;
    notifyListeners();
  }

  /// 嘗試交換兩個方塊
  Future<void> _trySwap(int col1, int row1, int col2, int row2) async {
    final s = _state!;
    _isProcessing = true;

    // 執行交換
    _swapBlocks(col1, row1, col2, row2);
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 150));

    // 檢查是否有匹配
    final matches = MatchDetector.findMatches(
      s.grid,
      numCols: s.mode.numCols,
      numRows: s.mode.numRows,
      enableHorizontalMatches: s.mode.enableHorizontalMatches,
    );

    if (matches.isEmpty) {
      // 沒有匹配 → 換回來
      _swapBlocks(col1, row1, col2, row2);
      s.combo = 0;

      // 扣行動點
      if (s.mode.actionPointsStart > 0) {
        s.actionPoints--;
        if (s.actionPoints <= 0) {
          _isProcessing = false;
          endGame();
          return;
        }
      }

      _isProcessing = false;
      notifyListeners();
      return;
    }

    s.actionCount++;

    // 有匹配 → 處理消除鏈
    await _processMatches();

    _isProcessing = false;
    notifyListeners();
  }

  /// 處理消除、掉落、補充的完整流程
  Future<void> _processMatches() async {
    final s = _state!;
    int chainCount = 0;
    bool hasMatch = true;

    while (hasMatch) {
      final matches = MatchDetector.findMatches(
        s.grid,
        numCols: s.mode.numCols,
        numRows: s.mode.numRows,
        enableHorizontalMatches: s.mode.enableHorizontalMatches,
      );

      if (matches.isEmpty) {
        hasMatch = false;
        break;
      }

      chainCount++;

      // 計分
      s.combo++;
      if (s.combo > s.maxCombo) s.maxCombo = s.combo;

      final scoreResult = ScoreCalculator.calculate(
        matches: matches,
        currentCombo: s.combo,
        chainCount: chainCount,
        scoring: s.mode.scoring,
      );
      s.score += scoreResult.totalPoints;

      // 標記消除
      final idsToRemove = MatchDetector.getBlockIdsToEliminate(matches);
      _markBlocksForElimination(idsToRemove);
      notifyListeners();

      // 等待消除動畫
      await Future.delayed(const Duration(milliseconds: 250));

      // 移除方塊
      _removeEliminatedBlocks();

      // 方塊掉落填補空隙
      _applyGravity();

      // 從上方補充新方塊
      _refillGrid();
      notifyListeners();

      // 等待掉落動畫
      await Future.delayed(const Duration(milliseconds: 300));
    }
  }

  // ─── 內部邏輯 ───

  /// 填滿整個棋盤
  void _fillGrid() {
    final s = _state!;
    for (int col = 0; col < s.mode.numCols; col++) {
      for (int row = 0; row < s.mode.numRows; row++) {
        s.grid[col][row] = Block(
          id: _uuid.v4(),
          color: _randomColor(),
          col: col,
          row: row,
        );
      }
    }
    // 確保初始狀態沒有三消匹配
    _resolveInitialMatches();
  }

  void _resolveInitialMatches() {
    final s = _state!;
    bool hasMatches = true;
    int attempts = 0;
    while (hasMatches && attempts < 200) {
      final matches = MatchDetector.findMatches(
        s.grid,
        numCols: s.mode.numCols,
        numRows: s.mode.numRows,
        enableHorizontalMatches: s.mode.enableHorizontalMatches,
      );
      if (matches.isEmpty) {
        hasMatches = false;
      } else {
        for (final match in matches) {
          final block = match.blocks.first;
          final currentColor = block.color;
          BlockColor newColor;
          do {
            newColor = _randomColor();
          } while (newColor == currentColor);
          s.grid[block.col][block.row] = block.copyWith(color: newColor);
        }
        attempts++;
      }
    }
  }

  /// 交換兩個方塊
  void _swapBlocks(int col1, int row1, int col2, int row2) {
    final s = _state!;
    final temp = s.grid[col1][row1];
    s.grid[col1][row1] = s.grid[col2][row2];
    s.grid[col2][row2] = temp;

    // 更新位置資訊
    s.grid[col1][row1]?.col = col1;
    s.grid[col1][row1]?.row = row1;
    s.grid[col2][row2]?.col = col2;
    s.grid[col2][row2]?.row = row2;
  }

  /// 從上方補充空位
  void _refillGrid() {
    final s = _state!;
    for (int col = 0; col < s.mode.numCols; col++) {
      for (int row = 0; row < s.mode.numRows; row++) {
        if (s.grid[col][row] == null) {
          s.grid[col][row] = Block(
            id: _uuid.v4(),
            color: _randomColor(),
            col: col,
            row: row,
          );
        }
      }
    }
  }

  void _markBlocksForElimination(Set<String> ids) {
    final s = _state!;
    for (int col = 0; col < s.mode.numCols; col++) {
      for (int row = 0; row < s.mode.numRows; row++) {
        final block = s.grid[col][row];
        if (block != null && ids.contains(block.id)) {
          s.grid[col][row] = block.copyWith(isEliminating: true);
        }
      }
    }
  }

  void _removeEliminatedBlocks() {
    final s = _state!;
    for (int col = 0; col < s.mode.numCols; col++) {
      for (int row = 0; row < s.mode.numRows; row++) {
        if (s.grid[col][row]?.isEliminating == true) {
          s.grid[col][row] = null;
        }
      }
    }
  }

  void _applyGravity() {
    final s = _state!;
    for (int col = 0; col < s.mode.numCols; col++) {
      int writeRow = s.mode.numRows - 1;
      for (int readRow = s.mode.numRows - 1; readRow >= 0; readRow--) {
        if (s.grid[col][readRow] != null) {
          if (writeRow != readRow) {
            s.grid[col][writeRow] = s.grid[col][readRow];
            s.grid[col][writeRow]!.row = writeRow;
            s.grid[col][readRow] = null;
          }
          writeRow--;
        }
      }
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      final s = _state;
      if (s == null || s.status != GameStatus.playing) {
        timer.cancel();
        return;
      }
      s.timeLeftMs -= 100;
      if (s.timeLeftMs <= 0) {
        s.timeLeftMs = 0;
        endGame();
      }
      notifyListeners();
    });
  }

  BlockColor _randomColor() {
    return BlockColor.values[_random.nextInt(BlockColor.values.length)];
  }
}
