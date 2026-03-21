import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../../config/game_modes.dart';
import '../../../core/models/block.dart';
import '../../../core/models/game_state.dart';
import '../../../core/engine/match_detector.dart';
import '../../../core/engine/score_calculator.dart';

/// 分數彈出事件
class ScorePopupEvent {
  final int points;
  final int col;
  final int row;
  final int combo;

  const ScorePopupEvent({
    required this.points,
    required this.col,
    required this.row,
    required this.combo,
  });
}

/// 連鎖波紋事件
class ChainRippleEvent {
  final int col;
  final int row;
  final int chainCount; // 第幾次連鎖

  const ChainRippleEvent({
    required this.col,
    required this.row,
    required this.chainCount,
  });
}

/// 遊戲核心 Provider — 管理整個遊戲流程
class GameProvider extends ChangeNotifier {
  static const _uuid = Uuid();
  final _random = Random();

  GameState? _state;
  GameState? get state => _state;

  Timer? _timer;
  bool _isProcessing = false;

  // 分數彈出事件佇列
  final List<ScorePopupEvent> _scorePopups = [];
  List<ScorePopupEvent> consumeScorePopups() {
    final popups = List<ScorePopupEvent>.from(_scorePopups);
    _scorePopups.clear();
    return popups;
  }

  // 連鎖波紋事件佇列
  final List<ChainRippleEvent> _chainRipples = [];
  List<ChainRippleEvent> consumeChainRipples() {
    final ripples = List<ChainRippleEvent>.from(_chainRipples);
    _chainRipples.clear();
    return ripples;
  }

  // ─── 遊戲生命週期 ───

  void startGame(GameModeConfig mode) {
    _timer?.cancel();
    _state = GameState.initial(mode);
    _state!.status = GameStatus.playing;

    _fillGrid();

    if (mode.hasTimer && mode.gameDuration > 0) {
      _startTimer();
    }

    notifyListeners();
  }

  void endGame() {
    _timer?.cancel();
    if (_state != null) {
      _state!.status = GameStatus.gameOver;
      _state!.selectedCol = null;
      _state!.selectedRow = null;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ─── 玩家操作 ───

  /// 點擊方塊 → 直接消除（若無產生連鎖才扣行動點）
  Future<void> tapBlock(int col, int row) async {
    final s = _state;
    if (s == null || s.status != GameStatus.playing || _isProcessing) return;
    if (s.grid[col][row] == null) return;

    _isProcessing = true;
    s.actionCount++;

    // 標記消除動畫
    s.grid[col][row] = s.grid[col][row]!.copyWith(isEliminating: true);
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 350));

    // 移除方塊
    s.grid[col][row] = null;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 100));

    // 重力掉落（不補充，先讓玩家看到掉落效果）
    _applyGravity();
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 400));

    // 補充新方塊
    _refillGrid();
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 300));

    // 連鎖消除處理
    final hadMatches = await _processMatchLoop();

    if (!hadMatches) {
      // 沒有產生連鎖 → 扣行動點
      s.combo = 0;
      if (s.mode.actionPointsStart > 0) {
        s.actionPoints--;
        notifyListeners();
        if (s.actionPoints <= 0) {
          _isProcessing = false;
          endGame();
          return;
        }
      }
    }

    _isProcessing = false;
    notifyListeners();
  }

  /// 上滑方塊 → 移到同列最頂部
  Future<void> moveBlockToTop(int col, int row) async {
    final s = _state;
    if (s == null || s.status != GameStatus.playing || _isProcessing) return;
    if (s.grid[col][row] == null) return;
    if (row == 0) return;

    _isProcessing = true;
    s.actionCount++;

    // 取出方塊
    final block = s.grid[col][row]!;
    s.grid[col][row] = null;

    // 把該列方塊往下移一格（從 row-1 到 0）
    for (int r = row; r > 0; r--) {
      s.grid[col][r] = s.grid[col][r - 1];
      if (s.grid[col][r] != null) {
        s.grid[col][r]!.row = r;
      }
    }

    // 放到最頂部
    s.grid[col][0] = block;
    block.row = 0;
    block.col = col;

    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 350));

    // 連鎖消除處理
    final hadMatches = await _processMatchLoop();

    if (!hadMatches) {
      s.combo = 0;
      if (s.mode.actionPointsStart > 0) {
        s.actionPoints--;
        notifyListeners();
        if (s.actionPoints <= 0) {
          _isProcessing = false;
          endGame();
          return;
        }
      }
    }

    _isProcessing = false;
    notifyListeners();
  }

  /// 下滑方塊 → 移到同列最底部
  Future<void> moveBlockToBottom(int col, int row) async {
    final s = _state;
    if (s == null || s.status != GameStatus.playing || _isProcessing) return;
    if (s.grid[col][row] == null) return;
    if (row == s.mode.numRows - 1) return;

    _isProcessing = true;
    s.actionCount++;

    // 取出方塊
    final block = s.grid[col][row]!;
    s.grid[col][row] = null;

    // 把該列方塊往上移一格（從 row+1 到 numRows-1）
    for (int r = row; r < s.mode.numRows - 1; r++) {
      s.grid[col][r] = s.grid[col][r + 1];
      if (s.grid[col][r] != null) {
        s.grid[col][r]!.row = r;
      }
    }

    // 放到最底部
    final lastRow = s.mode.numRows - 1;
    s.grid[col][lastRow] = block;
    block.row = lastRow;
    block.col = col;

    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 350));

    // 連鎖消除處理
    final hadMatches = await _processMatchLoop();

    if (!hadMatches) {
      s.combo = 0;
      if (s.mode.actionPointsStart > 0) {
        s.actionPoints--;
        notifyListeners();
        if (s.actionPoints <= 0) {
          _isProcessing = false;
          endGame();
          return;
        }
      }
    }

    _isProcessing = false;
    notifyListeners();
  }

  // ─── 連鎖消除處理（回傳是否有任何消除） ───

  Future<bool> _processMatchLoop() async {
    final s = _state!;
    int chainCount = 0;
    bool everHadMatch = false;

    while (true) {
      final matches = MatchDetector.findMatches(
        s.grid,
        numCols: s.mode.numCols,
        numRows: s.mode.numRows,
        enableHorizontalMatches: s.mode.enableHorizontalMatches,
      );

      if (matches.isEmpty) break;

      everHadMatch = true;
      chainCount++;
      s.combo++;
      if (s.combo > s.maxCombo) s.maxCombo = s.combo;

      // 計分
      final scoreResult = ScoreCalculator.calculate(
        matches: matches,
        currentCombo: s.combo,
        chainCount: chainCount,
        scoring: s.mode.scoring,
      );
      s.score += scoreResult.totalPoints;

      // 發送分數彈出事件（取第一個 match 的中間方塊位置）
      final firstMatch = matches.first;
      final midBlock = firstMatch.blocks[firstMatch.blocks.length ~/ 2];
      _scorePopups.add(ScorePopupEvent(
        points: scoreResult.totalPoints,
        col: midBlock.col,
        row: midBlock.row,
        combo: s.combo,
      ));

      // 連鎖 >= 2 時發送波紋事件
      if (chainCount >= 2) {
        _chainRipples.add(ChainRippleEvent(
          col: midBlock.col,
          row: midBlock.row,
          chainCount: chainCount,
        ));
      }

      // 標記消除（閃爍動畫）
      final idsToRemove = MatchDetector.getBlockIdsToEliminate(matches);
      _markBlocksForElimination(idsToRemove);
      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 350));

      // 移除方塊
      _removeEliminatedBlocks();
      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 100));

      // 重力掉落
      _applyGravity();
      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 400));

      // 補充新方塊
      _refillGrid();
      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 300));
    }

    return everHadMatch;
  }

  // ─── 內部邏輯 ───

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
