import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../../config/game_modes.dart';
import '../../../core/models/block.dart';
import '../../../core/models/game_state.dart';
import '../../../core/engine/match_detector.dart';

/// 飼料產出事件（給 CatProvider 消費）
class FoodEvent {
  final Map<BlockColor, int> foodByColor;
  final int combo;

  const FoodEvent({required this.foodByColor, required this.combo});
}

/// 放置模式遊戲 Provider — 簡化版 GameProvider
/// 無 game over、無行動點限制、持續補充方塊、產出飼料能量
class IdleProvider extends ChangeNotifier {
  static const _uuid = Uuid();
  final _random = Random();

  GameState? _state;
  GameState? get state => _state;

  bool _isProcessing = false;
  bool get isProcessing => _isProcessing;
  int _gameGeneration = 0;

  // 飼料事件佇列
  final List<FoodEvent> _foodEvents = [];
  List<FoodEvent> consumeFoodEvents() {
    final events = List<FoodEvent>.from(_foodEvents);
    _foodEvents.clear();
    return events;
  }

  /// 啟動放置模式遊戲
  void startIdleGame() {
    _gameGeneration++;
    _isProcessing = false;
    _foodEvents.clear();

    _state = GameState.initial(GameModes.idle);
    _state!.status = GameStatus.playing;
    _fillGrid();
    notifyListeners();
  }

  /// 點擊方塊 → 消除 → 產出飼料（無 game over）
  Future<void> tapBlock(int col, int row) async {
    final s = _state;
    if (s == null || s.status != GameStatus.playing || _isProcessing) return;
    if (s.grid[col][row] == null) return;

    _isProcessing = true;
    final gen = _gameGeneration;

    // 記錄被點擊方塊的顏色
    final tappedColor = s.grid[col][row]!.color;
    s.actionCount++;

    // 消除動畫
    s.grid[col][row] = s.grid[col][row]!.copyWith(isEliminating: true);
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 300));
    if (_gameGeneration != gen) return;

    // 移除
    s.grid[col][row] = null;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 80));
    if (_gameGeneration != gen) return;

    // 產出 1 份飼料（點擊消除的方塊）
    _foodEvents.add(FoodEvent(
      foodByColor: {tappedColor: 1},
      combo: 0,
    ));

    // 重力 + 補充
    _applyGravity();
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 350));
    if (_gameGeneration != gen) return;

    _refillGrid();
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 250));
    if (_gameGeneration != gen) return;

    // 連鎖消除
    await _processMatchLoop();
    if (_gameGeneration != gen) return;

    // 放置模式不扣行動點，不 game over，只重置 combo
    if (s.combo > 0) {
      // combo 保留到下次操作
    } else {
      s.combo = 0;
    }

    _isProcessing = false;
    notifyListeners();
  }

  /// 上滑方塊 → 移到頂部
  Future<void> moveBlockToTop(int col, int row) async {
    final s = _state;
    if (s == null || s.status != GameStatus.playing || _isProcessing) return;
    if (s.grid[col][row] == null || row == 0) return;

    _isProcessing = true;
    final gen = _gameGeneration;
    s.actionCount++;

    final block = s.grid[col][row]!;
    s.grid[col][row] = null;
    for (int r = row; r > 0; r--) {
      s.grid[col][r] = s.grid[col][r - 1];
      if (s.grid[col][r] != null) s.grid[col][r]!.row = r;
    }
    s.grid[col][0] = block;
    block.row = 0;
    block.col = col;

    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 300));
    if (_gameGeneration != gen) return;

    await _processMatchLoop();
    if (_gameGeneration != gen) return;

    _isProcessing = false;
    notifyListeners();
  }

  /// 下滑方塊 → 移到底部
  Future<void> moveBlockToBottom(int col, int row) async {
    final s = _state;
    if (s == null || s.status != GameStatus.playing || _isProcessing) return;
    if (s.grid[col][row] == null || row == s.mode.numRows - 1) return;

    _isProcessing = true;
    final gen = _gameGeneration;
    s.actionCount++;

    final block = s.grid[col][row]!;
    s.grid[col][row] = null;
    for (int r = row; r < s.mode.numRows - 1; r++) {
      s.grid[col][r] = s.grid[col][r + 1];
      if (s.grid[col][r] != null) s.grid[col][r]!.row = r;
    }
    final lastRow = s.mode.numRows - 1;
    s.grid[col][lastRow] = block;
    block.row = lastRow;
    block.col = col;

    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 300));
    if (_gameGeneration != gen) return;

    await _processMatchLoop();
    if (_gameGeneration != gen) return;

    _isProcessing = false;
    notifyListeners();
  }

  GameModeConfig get mode => GameModes.idle;

  /// 連鎖消除迴圈 — 產出飼料
  Future<bool> _processMatchLoop() async {
    final s = _state!;
    final gen = _gameGeneration;
    bool everHadMatch = false;

    while (true) {
      if (_gameGeneration != gen) return false;

      final matches = MatchDetector.findMatches(
        s.grid,
        numCols: s.mode.numCols,
        numRows: s.mode.numRows,
        enableHorizontalMatches: s.mode.enableHorizontalMatches,
      );

      if (matches.isEmpty) break;

      everHadMatch = true;
      s.combo++;
      if (s.combo > s.maxCombo) s.maxCombo = s.combo;

      // 統計消除的方塊顏色 → 轉換為飼料
      final foodMap = <BlockColor, int>{};
      for (final match in matches) {
        for (final block in match.blocks) {
          foodMap[block.color] = (foodMap[block.color] ?? 0) + 1;
        }
      }

      // 連擊倍率：foodAmount = base * (1 + combo * 0.3)
      final multiplier = 1.0 + s.combo * 0.3;
      final boostedFood = <BlockColor, int>{};
      for (final entry in foodMap.entries) {
        boostedFood[entry.key] = (entry.value * multiplier).round();
      }

      _foodEvents.add(FoodEvent(
        foodByColor: boostedFood,
        combo: s.combo,
      ));

      // 分數（僅用於展示）
      s.score += foodMap.values.fold(0, (a, b) => a + b);

      // 消除動畫
      final idsToRemove = MatchDetector.getBlockIdsToEliminate(matches);
      _markBlocksForElimination(idsToRemove);
      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 300));
      if (_gameGeneration != gen) return false;

      _removeEliminatedBlocks();
      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 80));
      if (_gameGeneration != gen) return false;

      _applyGravity();
      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 350));
      if (_gameGeneration != gen) return false;

      _refillGrid();
      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 250));
      if (_gameGeneration != gen) return false;
    }

    // 回合結束後重置 combo
    if (!everHadMatch) {
      s.combo = 0;
    }

    return everHadMatch;
  }

  // ─── 內部邏輯（與 GameProvider 相同） ───

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
          BlockColor newColor;
          do {
            newColor = _randomColor();
          } while (newColor == block.color);
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

  BlockColor _randomColor() {
    return BlockColor.values[_random.nextInt(BlockColor.values.length)];
  }
}
