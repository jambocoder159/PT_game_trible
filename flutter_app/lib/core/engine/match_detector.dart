import '../models/block.dart';

/// 匹配結果
class MatchResult {
  final List<Block> blocks;
  final bool isHorizontal;

  const MatchResult({required this.blocks, this.isHorizontal = false});

  int get count => blocks.length;
}

/// 三消匹配偵測引擎
/// 從 web/js/GameEngine.js 的匹配邏輯移植
class MatchDetector {
  /// 偵測所有可消除的匹配
  /// [blockedPositions] 障礙格等不參與配對的位置集合（"col,row" 格式）
  static List<MatchResult> findMatches(
    List<List<Block?>> grid, {
    required int numCols,
    required int numRows,
    required bool enableHorizontalMatches,
    Set<String> blockedPositions = const {},
  }) {
    final matches = <MatchResult>[];

    // 垂直匹配（所有模式都支援）
    for (int col = 0; col < numCols; col++) {
      matches.addAll(_findVerticalMatches(grid, col, numRows, blockedPositions));
    }

    // 水平匹配（僅三列模式啟用）
    if (enableHorizontalMatches && numCols >= 3) {
      matches.addAll(_findHorizontalMatches(grid, numCols, numRows, blockedPositions));
    }

    return matches;
  }

  /// 在單一列中找垂直匹配（連續 3+ 個同色方塊）
  static List<MatchResult> _findVerticalMatches(
    List<List<Block?>> grid,
    int col,
    int numRows,
    Set<String> blockedPositions,
  ) {
    final matches = <MatchResult>[];
    int i = 0;

    while (i < numRows) {
      final block = grid[col][i];
      if (block == null || block.isBlackened || blockedPositions.contains('$col,$i')) {
        i++;
        continue;
      }

      final matchBlocks = <Block>[block];
      int j = i + 1;

      while (j < numRows) {
        final next = grid[col][j];
        if (next == null || next.isBlackened || next.color != block.color
            || blockedPositions.contains('$col,$j')) break;
        matchBlocks.add(next);
        j++;
      }

      if (matchBlocks.length >= 3) {
        matches.add(MatchResult(blocks: matchBlocks, isHorizontal: false));
      }

      i = j;
    }

    return matches;
  }

  /// 找水平匹配（同一行中連續 3+ 個同色方塊）
  static List<MatchResult> _findHorizontalMatches(
    List<List<Block?>> grid,
    int numCols,
    int numRows,
    Set<String> blockedPositions,
  ) {
    final matches = <MatchResult>[];

    for (int row = 0; row < numRows; row++) {
      int col = 0;
      while (col < numCols) {
        final block = grid[col][row];
        if (block == null || block.isBlackened || blockedPositions.contains('$col,$row')) {
          col++;
          continue;
        }

        final matchBlocks = <Block>[block];
        int nextCol = col + 1;

        while (nextCol < numCols) {
          final next = grid[nextCol][row];
          if (next == null || next.isBlackened || next.color != block.color
              || blockedPositions.contains('$nextCol,$row')) break;
          matchBlocks.add(next);
          nextCol++;
        }

        if (matchBlocks.length >= 3) {
          matches.add(MatchResult(blocks: matchBlocks, isHorizontal: true));
        }

        col = nextCol;
      }
    }

    return matches;
  }

  /// 收集所有需要消除的方塊（去重）
  static Set<String> getBlockIdsToEliminate(List<MatchResult> matches) {
    final ids = <String>{};
    for (final match in matches) {
      for (final block in match.blocks) {
        ids.add(block.id);
      }
    }
    return ids;
  }
}
