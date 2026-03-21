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

    // 填滿棋盤（確保初始沒有匹配）
    _fillGrid();

    // 預備下一個方塊
    _generateNextBlocks();

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

  /// 玩家選擇某一列放置方塊
  Future<void> placeBlock(int col) async {
    final s = _state;
    if (s == null || s.status != GameStatus.playing || _isProcessing) return;

    // 找到該列最高的空位
    final targetRow = _findTopEmptyRow(col);
    if (targetRow < 0) return; // 該列已滿

    _isProcessing = true;

    // 放置方塊
    final color = s.nextBlockColors.isNotEmpty
        ? s.nextBlockColors.first
        : BlockColor.values[_random.nextInt(BlockColor.values.length)];

    final block = Block(
      id: _uuid.v4(),
      color: color,
      col: col,
      row: targetRow,
    );
    s.grid[col][targetRow] = block;
    s.actionCount++;

    // 生成下一個方塊
    _generateNextBlocks();
    notifyListeners();

    // 偵測匹配並處理消除
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
      notifyListeners();

      // 等待掉落動畫
      await Future.delayed(const Duration(milliseconds: 300));
    }

    // 沒有匹配 → 重置 combo，扣行動點
    if (chainCount == 0) {
      s.combo = 0;
      if (s.mode.actionPointsStart > 0) {
        s.actionPoints--;
        if (s.actionPoints <= 0) {
          endGame();
        }
      }
    }

    _isProcessing = false;
    notifyListeners();

    // 檢查是否棋盤滿了（所有列的頂部都有方塊）
    _checkBoardFull();
  }

  // ─── 內部邏輯 ───

  void _fillGrid() {
    final s = _state!;
    for (int col = 0; col < s.mode.numCols; col++) {
      for (int row = s.mode.numRows - 1; row >= s.mode.numRows - 3; row--) {
        s.grid[col][row] = Block(
          id: _uuid.v4(),
          color: _randomColor(),
          col: col,
          row: row,
        );
      }
    }
    // 確保初始狀態沒有三消匹配，簡單重試
    _resolveInitialMatches();
  }

  void _resolveInitialMatches() {
    final s = _state!;
    bool hasMatches = true;
    int attempts = 0;
    while (hasMatches && attempts < 100) {
      final matches = MatchDetector.findMatches(
        s.grid,
        numCols: s.mode.numCols,
        numRows: s.mode.numRows,
        enableHorizontalMatches: s.mode.enableHorizontalMatches,
      );
      if (matches.isEmpty) {
        hasMatches = false;
      } else {
        // 替換匹配中的第一個方塊顏色
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

  int _findTopEmptyRow(int col) {
    final s = _state!;
    for (int row = 0; row < s.mode.numRows; row++) {
      if (s.grid[col][row] != null) {
        return row - 1; // 上面那格是空的
      }
    }
    return s.mode.numRows - 1; // 整列都是空的
  }

  void _generateNextBlocks() {
    final s = _state!;
    s.nextBlockColors.clear();
    s.nextBlockColors.add(_randomColor());
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
      // 從底部往上，把空位填上
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

  void _checkBoardFull() {
    final s = _state;
    if (s == null) return;
    for (int col = 0; col < s.mode.numCols; col++) {
      if (s.grid[col][0] == null) return; // 有空位
    }
    endGame(); // 全滿，遊戲結束
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
