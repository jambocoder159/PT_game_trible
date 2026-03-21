import '../../config/game_modes.dart';
import 'block.dart';

/// 遊戲進行中的狀態
enum GameStatus { ready, playing, paused, gameOver }

class GameState {
  final GameModeConfig mode;
  final List<List<Block?>> grid; // grid[col][row]
  final List<BlockColor> nextBlockColors;

  int score;
  int actionPoints;
  int combo; // 連續成功消除次數
  int maxCombo;
  int actionCount;
  int timeLeftMs;

  GameStatus status;

  GameState({
    required this.mode,
    required this.grid,
    List<BlockColor>? nextBlockColors,
    this.score = 0,
    this.actionPoints = 5,
    this.combo = 0,
    this.maxCombo = 0,
    this.actionCount = 0,
    this.timeLeftMs = 0,
    this.status = GameStatus.ready,
  }) : nextBlockColors = nextBlockColors ?? [];

  /// 建立初始空狀態
  factory GameState.initial(GameModeConfig mode) {
    final grid = List.generate(
      mode.numCols,
      (_) => List<Block?>.filled(mode.numRows, null),
    );

    return GameState(
      mode: mode,
      grid: grid,
      actionPoints: mode.actionPointsStart,
      timeLeftMs: mode.gameDuration,
    );
  }
}
