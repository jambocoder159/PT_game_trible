import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../../config/cat_agent_data.dart';
import '../../../config/game_modes.dart';
import '../../../core/models/block.dart';
import '../../../core/models/cat_agent.dart';
import '../../../core/models/game_state.dart';
import '../../../core/models/auto_eliminate_config.dart';
import '../../../core/engine/match_detector.dart';
import '../../../core/services/local_storage.dart';

/// 能量產出事件（給 BottleProvider 消費）
class EnergyEvent {
  final Map<BlockColor, int> energyByColor;
  final int combo;
  final EliminationSource source;

  const EnergyEvent({
    required this.energyByColor,
    required this.combo,
    this.source = EliminationSource.manual,
  });
}

/// 能量計算：全加成制，無懲罰
class EnergyCalculator {
  static const int baseEnergy = 10;
  static const int matchBonus = 5;
  static const int maxComboBonus = 5;
  static const int maxVolumeExtraBlocks = 6;

  /// 計算單次消除的每顆能量
  /// [isMatch] 是否為三消匹配（而非單點消除）
  /// [combo] 當前連擊數
  /// [totalBlocksInOperation] 本次操作消除的總方塊數
  static int perBlockEnergy({
    required bool isMatch,
    required int combo,
    required int totalBlocksInOperation,
  }) {
    int energy = baseEnergy;
    if (isMatch) energy += matchBonus;
    energy += combo.clamp(0, maxComboBonus) * 3;
    energy += (totalBlocksInOperation - 4).clamp(0, maxVolumeExtraBlocks) * 2;
    return energy;
  }
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

  /// 每次消除方塊的回呼（用於每日任務計數）
  void Function(int count)? onBlocksEliminated;

  // ─── 自動消除系統 ───

  AutoEliminateConfig _autoConfig = AutoEliminateConfig();
  AutoEliminateConfig get autoConfig => _autoConfig;

  Timer? _autoTimer;

  /// 自動消除倒計時（毫秒，供 UI 顯示）
  int _autoCountdownMs = 0;
  int get autoCountdownMs => _autoCountdownMs;

  // 能量事件佇列（取代舊的飼料事件）
  final List<EnergyEvent> _energyEvents = [];
  List<EnergyEvent> consumeEnergyEvents() {
    final events = List<EnergyEvent>.from(_energyEvents);
    _energyEvents.clear();
    return events;
  }

  // 向後兼容：保留 consumeFoodEvents 別名
  List<EnergyEvent> consumeFoodEvents() => consumeEnergyEvents();

  /// 啟動放置模式遊戲
  void startIdleGame() {
    _gameGeneration++;
    _isProcessing = false;
    _energyEvents.clear();

    _state = GameState.initial(GameModes.idle);
    _state!.status = GameStatus.playing;
    _fillGrid();

    // 若自動消除已開啟，啟動 timer
    if (_autoConfig.isAutoActive) {
      _startAutoTimer();
    }

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

    // 產出能量（點擊消除的方塊，非三消，基礎能量）
    final perBlock = EnergyCalculator.perBlockEnergy(
      isMatch: false, combo: 0, totalBlocksInOperation: 1,
    );
    final tapEnergy = {tappedColor: perBlock};
    _energyEvents.add(EnergyEvent(
      energyByColor: tapEnergy,
      combo: 0,
      source: EliminationSource.manual,
    ));
    onBlocksEliminated?.call(1);
    _accumulateSkillEnergy(tapEnergy);

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

  /// 連鎖消除迴圈 — 產出能量（全加成制）
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

      // 統計消除的方塊顏色
      final colorCount = <BlockColor, int>{};
      for (final match in matches) {
        for (final block in match.blocks) {
          colorCount[block.color] = (colorCount[block.color] ?? 0) + 1;
        }
      }

      // 用新加成公式計算能量
      final totalBlocks = colorCount.values.fold(0, (a, b) => a + b);
      final perBlock = EnergyCalculator.perBlockEnergy(
        isMatch: true,
        combo: s.combo,
        totalBlocksInOperation: totalBlocks,
      );
      final energyMap = <BlockColor, int>{};
      for (final entry in colorCount.entries) {
        energyMap[entry.key] = entry.value * perBlock;
      }

      _energyEvents.add(EnergyEvent(
        energyByColor: energyMap,
        combo: s.combo,
        source: EliminationSource.chain,
      ));
      _accumulateSkillEnergy(energyMap);

      // 分數（僅用於展示）
      s.score += totalBlocks;
      onBlocksEliminated?.call(totalBlocks);

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

  // ─── 放置模式技能系統 ───

  /// 隊伍角色 ID
  List<String> _teamIds = [];
  List<String> get teamIds => _teamIds;

  /// 各角色能量（0 ~ energyCost）
  Map<String, int> _energy = {};
  int getEnergy(String agentId) => _energy[agentId] ?? 0;

  /// 設定隊伍（由 HomeScreen 呼叫）
  void setTeam(List<String> team) {
    _teamIds = team;
    for (final id in team) {
      _energy.putIfAbsent(id, () => 0);
    }
    notifyListeners();
  }

  CatAgentDefinition? _findAgent(String id) {
    for (final a in CatAgentData.allAgents) {
      if (a.id == id) return a;
    }
    return null;
  }

  /// 消除方塊時累積角色技能能量（與瓶子能量獨立）
  void _accumulateSkillEnergy(Map<BlockColor, int> energyByColor) {
    for (final agentId in _teamIds) {
      final def = _findAgent(agentId);
      if (def == null) continue;

      final agentColor = def.attribute.blockColor;
      final matched = energyByColor[agentColor] ?? 0;
      final otherBlocks = energyByColor.entries
          .where((e) => e.key != agentColor)
          .fold(0, (sum, e) => sum + e.value);
      // 技能能量：同色 +1，異色 +0.5（簡化計算，不受瓶子能量影響）
      final gain = matched + (otherBlocks * 0.5).round();

      if (gain > 0) {
        final cost = def.skill.energyCost;
        _energy[agentId] = ((_energy[agentId] ?? 0) + gain).clamp(0, cost);
      }
    }
  }

  /// 角色技能是否可用
  bool isSkillReady(String agentId) {
    final def = _findAgent(agentId);
    if (def == null) return false;
    return (_energy[agentId] ?? 0) >= def.skill.energyCost;
  }

  /// 最近施放技能的屬性（供 UI 層讀取 VFX）
  AgentAttribute? _lastSkillAttribute;
  String? _lastSkillAgentName;
  AgentAttribute? get lastSkillAttribute => _lastSkillAttribute;
  String? get lastSkillAgentName => _lastSkillAgentName;

  void consumeSkillVfx() {
    _lastSkillAttribute = null;
    _lastSkillAgentName = null;
  }

  /// 施放技能（只執行棋盤效果）
  Future<void> activateSkill(String agentId) async {
    final s = _state;
    if (s == null || s.status != GameStatus.playing || _isProcessing) return;
    if (!isSkillReady(agentId)) return;

    final def = _findAgent(agentId);
    if (def == null) return;

    // 記錄技能施放資訊供 VFX 使用
    _lastSkillAttribute = def.attribute;
    _lastSkillAgentName = def.name;

    final effect = def.skill.boardEffect;
    if (effect == null) return;

    // 扣除能量
    _energy[agentId] = 0;
    _isProcessing = true;
    final gen = _gameGeneration;
    notifyListeners();

    // 執行棋盤效果
    final agentColor = def.attribute.blockColor;
    switch (effect.type) {
      case BoardEffectType.convertColor:
        _convertRandomBlocks(effect.value, agentColor);
        break;
      case BoardEffectType.eliminateRandom:
        _eliminateRandomBlocksByCount(effect.value);
        break;
      case BoardEffectType.eliminateRow:
        final row = effect.value == -1 ? s.mode.numRows - 1 : effect.value;
        _eliminateRow(row);
        break;
      case BoardEffectType.eliminateColumn:
        final col = _random.nextInt(s.mode.numCols);
        _eliminateColumn(col);
        break;
      case BoardEffectType.shuffleBoard:
        _shuffleBoard();
        break;
    }

    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 400));
    if (_gameGeneration != gen) { _isProcessing = false; return; }

    // 消除類效果需要重力 + 補充 + 連鎖
    if (effect.type == BoardEffectType.eliminateRandom ||
        effect.type == BoardEffectType.eliminateRow ||
        effect.type == BoardEffectType.eliminateColumn) {
      _removeEliminatedBlocks();
      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 80));
      if (_gameGeneration != gen) { _isProcessing = false; return; }

      _applyGravity();
      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 350));
      if (_gameGeneration != gen) { _isProcessing = false; return; }

      _refillGrid();
      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 250));
      if (_gameGeneration != gen) { _isProcessing = false; return; }

      await _processMatchLoop();
    }

    if (effect.type == BoardEffectType.convertColor) {
      await _processMatchLoop();
    }

    _isProcessing = false;
    notifyListeners();
  }

  void _convertRandomBlocks(int count, BlockColor targetColor) {
    final s = _state!;
    final candidates = <Point<int>>[];
    for (int col = 0; col < s.mode.numCols; col++) {
      for (int row = 0; row < s.mode.numRows; row++) {
        final block = s.grid[col][row];
        if (block != null && block.color != targetColor) {
          candidates.add(Point(col, row));
        }
      }
    }
    candidates.shuffle(_random);
    for (final p in candidates.take(count)) {
      final old = s.grid[p.x][p.y]!;
      s.grid[p.x][p.y] = old.copyWith(color: targetColor);
    }
  }

  void _eliminateRandomBlocksByCount(int count) {
    final s = _state!;
    final candidates = <Point<int>>[];
    for (int col = 0; col < s.mode.numCols; col++) {
      for (int row = 0; row < s.mode.numRows; row++) {
        if (s.grid[col][row] != null) candidates.add(Point(col, row));
      }
    }
    candidates.shuffle(_random);
    for (final p in candidates.take(count)) {
      s.grid[p.x][p.y] = s.grid[p.x][p.y]!.copyWith(isEliminating: true);
    }
  }

  void _eliminateRow(int row) {
    final s = _state!;
    for (int col = 0; col < s.mode.numCols; col++) {
      if (s.grid[col][row] != null) {
        s.grid[col][row] = s.grid[col][row]!.copyWith(isEliminating: true);
      }
    }
  }

  void _eliminateColumn(int col) {
    final s = _state!;
    for (int row = 0; row < s.mode.numRows; row++) {
      if (s.grid[col][row] != null) {
        s.grid[col][row] = s.grid[col][row]!.copyWith(isEliminating: true);
      }
    }
  }

  void _shuffleBoard() {
    final s = _state!;
    final blocks = <Block>[];
    for (int col = 0; col < s.mode.numCols; col++) {
      for (int row = 0; row < s.mode.numRows; row++) {
        if (s.grid[col][row] != null) blocks.add(s.grid[col][row]!);
      }
    }
    blocks.shuffle(_random);
    int idx = 0;
    for (int col = 0; col < s.mode.numCols; col++) {
      for (int row = 0; row < s.mode.numRows; row++) {
        if (idx < blocks.length) {
          s.grid[col][row] = blocks[idx].copyWith(col: col, row: row);
          idx++;
        }
      }
    }
  }

  // ─── 自動消除系統 ───

  /// 載入自動消除設定（從本地存儲）
  void loadAutoConfig() {
    final json = LocalStorageService.instance.getJson('auto_eliminate_config');
    if (json is Map<String, dynamic>) {
      _autoConfig = AutoEliminateConfig.fromJson(json);
    }
  }

  /// 儲存自動消除設定
  void _saveAutoConfig() {
    LocalStorageService.instance.setJson(
      'auto_eliminate_config',
      _autoConfig.toJson(),
    );
  }

  /// 根據玩家等級檢查並解鎖階段
  void checkStageUnlock(int playerLevel) {
    AutoEliminateStage highest = AutoEliminateStage.stage1;
    for (final entry in AutoEliminateConfig.unlockLevelRequirements.entries) {
      if (playerLevel >= entry.value && entry.key.index > highest.index) {
        highest = entry.key;
      }
    }
    if (highest.index > _autoConfig.unlockedStage.index) {
      _autoConfig.unlockedStage = highest;
      _saveAutoConfig();
      notifyListeners();
    }
  }

  /// 開關自動消除
  void toggleAutoEliminate(bool enabled) {
    if (_autoConfig.unlockedStage == AutoEliminateStage.stage1) return;
    _autoConfig.isEnabled = enabled;
    _saveAutoConfig();

    if (enabled && _state?.status == GameStatus.playing) {
      _startAutoTimer();
    } else {
      _stopAutoTimer();
    }
    notifyListeners();
  }

  /// 設定 Stage 3 主要目標顏色
  void setTargetColor(BlockColor color) {
    _autoConfig.targetColor = color;
    _saveAutoConfig();
    notifyListeners();
  }

  /// 設定 Stage 3 備用顏色
  void setFallbackColor(BlockColor color) {
    _autoConfig.fallbackColor = color;
    _saveAutoConfig();
    notifyListeners();
  }

  /// 升級自動消除週期，回傳是否成功
  /// [deductGold] 外部提供的扣金幣函數，回傳是否扣款成功
  bool upgradeInterval(bool Function(int cost) deductGold) {
    if (_autoConfig.isMaxIntervalLevel) return false;
    final cost = _autoConfig.nextUpgradeCost;
    if (!deductGold(cost)) return false;

    _autoConfig.intervalLevel++;
    _saveAutoConfig();

    // 重啟 timer 以套用新週期
    if (_autoConfig.isAutoActive && _state?.status == GameStatus.playing) {
      _stopAutoTimer();
      _startAutoTimer();
    }
    notifyListeners();
    return true;
  }

  /// 啟動自動消除計時器
  void _startAutoTimer() {
    _stopAutoTimer();
    _autoCountdownMs = _autoConfig.intervalMs;
    const tickMs = 100;
    _autoTimer = Timer.periodic(const Duration(milliseconds: tickMs), (timer) {
      if (_state == null || _state!.status != GameStatus.playing) {
        return;
      }
      _autoCountdownMs -= tickMs;
      if (_autoCountdownMs <= 0) {
        _autoCountdownMs = _autoConfig.intervalMs;
        _autoEliminate();
      }
      notifyListeners();
    });
  }

  /// 停止自動消除計時器
  void _stopAutoTimer() {
    _autoTimer?.cancel();
    _autoTimer = null;
    _autoCountdownMs = 0;
  }

  /// 自動消除核心邏輯（選方塊 → 消除 → 重力 → 補充 → 連鎖）
  Future<void> _autoEliminate() async {
    final s = _state;
    if (s == null || s.status != GameStatus.playing || _isProcessing) return;

    final target = _autoSelectBlock();
    if (target == null) return;
    final (col, row) = target;

    _isProcessing = true;
    final gen = _gameGeneration;

    final eliminatedColor = s.grid[col][row]!.color;

    // 消除動畫（自動消除稍慢，視覺區分）
    s.grid[col][row] = s.grid[col][row]!.copyWith(isEliminating: true);
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 400));
    if (_gameGeneration != gen) { _isProcessing = false; return; }

    // 移除
    s.grid[col][row] = null;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 80));
    if (_gameGeneration != gen) { _isProcessing = false; return; }

    // 產出能量（自動消除也給完整能量，不打折）
    final perBlock = EnergyCalculator.perBlockEnergy(
      isMatch: false, combo: 0, totalBlocksInOperation: 1,
    );
    final autoEnergy = {eliminatedColor: perBlock};
    _energyEvents.add(EnergyEvent(
      energyByColor: autoEnergy,
      combo: 0,
      source: EliminationSource.auto_,
    ));
    onBlocksEliminated?.call(1);
    _accumulateSkillEnergy(autoEnergy);

    // 重力 + 補充
    _applyGravity();
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 350));
    if (_gameGeneration != gen) { _isProcessing = false; return; }

    _refillGrid();
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 250));
    if (_gameGeneration != gen) { _isProcessing = false; return; }

    // 連鎖消除（自動消除觸發的連鎖也給完整能量）
    await _processMatchLoop();
    if (_gameGeneration != gen) { _isProcessing = false; return; }

    // 自動消除後重置 combo
    s.combo = 0;

    _isProcessing = false;
    notifyListeners();
  }

  /// 根據當前階段選擇要消除的方塊
  (int, int)? _autoSelectBlock() {
    final s = _state;
    if (s == null) return null;

    if (_autoConfig.unlockedStage == AutoEliminateStage.stage3) {
      // Stage 3: 優先指定顏色 → 備用顏色 → 隨機
      final target = _findBlockOfColor(_autoConfig.targetColor);
      if (target != null) return target;
      final fallback = _findBlockOfColor(_autoConfig.fallbackColor);
      if (fallback != null) return fallback;
    }

    // Stage 2 或 Stage 3 fallback: 隨機
    return _findRandomBlock();
  }

  /// 在棋盤上找一個指定顏色的方塊（隨機選一個）
  (int, int)? _findBlockOfColor(BlockColor? color) {
    if (color == null) return null;
    final s = _state!;
    final candidates = <(int, int)>[];
    for (int col = 0; col < s.mode.numCols; col++) {
      for (int row = 0; row < s.mode.numRows; row++) {
        final block = s.grid[col][row];
        if (block != null && block.color == color) {
          candidates.add((col, row));
        }
      }
    }
    if (candidates.isEmpty) return null;
    return candidates[_random.nextInt(candidates.length)];
  }

  /// 在棋盤上隨機找一個非空方塊
  (int, int)? _findRandomBlock() {
    final s = _state!;
    final candidates = <(int, int)>[];
    for (int col = 0; col < s.mode.numCols; col++) {
      for (int row = 0; row < s.mode.numRows; row++) {
        if (s.grid[col][row] != null) {
          candidates.add((col, row));
        }
      }
    }
    if (candidates.isEmpty) return null;
    return candidates[_random.nextInt(candidates.length)];
  }

  @override
  void dispose() {
    _stopAutoTimer();
    super.dispose();
  }
}
