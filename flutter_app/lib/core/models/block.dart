import 'package:flutter/material.dart';
import '../../config/theme.dart';

/// 方塊顏色列舉
enum BlockColor {
  coral,   // 珊瑚橘紅
  teal,    // 翡翠青
  mint,    // 薄荷綠
  gold,    // 琥珀金
  rose;    // 玫瑰紅

  Color get color => AppTheme.blockColors[index];
  String get symbol => AppTheme.blockSymbols[index];
  String get label => ['烈焰', '寒潮', '叢林', '雷光', '暗影'][index];
  String get elementEmoji => ['🔥', '💧', '🌿', '⚡', '🔮'][index];
}

/// 方塊資料模型
class Block {
  final String id;
  final BlockColor color;
  int col;
  int row;

  // 動畫用的即時位置
  double animX;
  double animY;

  // 狀態
  bool isEliminating;
  bool isBlackened; // 存活模式用
  int blackenedTurnsLeft;

  Block({
    required this.id,
    required this.color,
    required this.col,
    required this.row,
    this.animX = 0,
    this.animY = 0,
    this.isEliminating = false,
    this.isBlackened = false,
    this.blackenedTurnsLeft = 0,
  });

  /// 建立一個隨機顏色的方塊
  factory Block.random({required int col, required int row, required String id}) {
    final colors = BlockColor.values;
    final color = colors[(DateTime.now().microsecond + col * 7 + row * 13) % colors.length];
    return Block(id: id, color: color, col: col, row: row);
  }

  Block copyWith({
    BlockColor? color,
    int? col,
    int? row,
    bool? isEliminating,
    bool? isBlackened,
    int? blackenedTurnsLeft,
  }) {
    return Block(
      id: id,
      color: color ?? this.color,
      col: col ?? this.col,
      row: row ?? this.row,
      animX: animX,
      animY: animY,
      isEliminating: isEliminating ?? this.isEliminating,
      isBlackened: isBlackened ?? this.isBlackened,
      blackenedTurnsLeft: blackenedTurnsLeft ?? this.blackenedTurnsLeft,
    );
  }
}
