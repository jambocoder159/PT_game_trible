/// 玩家資料 Provider
/// 管理玩家資料的載入、儲存、角色操作
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../../../config/cat_agent_data.dart';
import '../../../config/evolution_data.dart';
import '../../../config/passive_skill_data.dart';
import '../../../config/skill_tier_data.dart';
import '../../../config/stage_data.dart';
import '../../../config/talent_tree_data.dart';
import '../../../core/models/cat_agent.dart';
import '../../../core/models/material.dart';
import '../../../core/models/player_data.dart';
import '../../../core/services/local_storage.dart';

class PlayerProvider extends ChangeNotifier {
  PlayerData _data = PlayerData.newPlayer();
  PlayerData get data => _data;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// 初始化：載入存檔
  Future<void> init() async {
    await LocalStorageService.instance.init();
    _data = LocalStorageService.instance.loadPlayerData();
    _isInitialized = true;
    notifyListeners();
  }

  /// 儲存資料
  Future<void> _save() async {
    await LocalStorageService.instance.savePlayerData(_data);
  }

  /// 通知 UI 並儲存（外部直接修改 data 後呼叫）
  void notifyAndSave() {
    notifyListeners();
    _save();
  }

  // ─── 角色操作 ───

  /// 取得角色定義 + 實例的完整資訊
  List<AgentInfo> get allAgentInfos {
    return CatAgentData.allAgents.map((def) {
      final instance = _data.agents[def.id];
      return AgentInfo(
        definition: def,
        instance: instance,
      );
    }).toList();
  }

  /// 取得已解鎖的角色
  List<AgentInfo> get unlockedAgents {
    return allAgentInfos.where((a) => a.isUnlocked).toList();
  }

  /// 取得當前隊伍的角色資訊
  List<AgentInfo> get teamAgents {
    return _data.team
        .map((id) {
          final def = CatAgentData.getById(id);
          if (def == null) return null;
          return AgentInfo(
            definition: def,
            instance: _data.agents[id],
          );
        })
        .whereType<AgentInfo>()
        .toList();
  }

  /// 解鎖角色
  Future<bool> unlockAgent(String agentId) async {
    final def = CatAgentData.getById(agentId);
    if (def == null) return false;

    // 檢查是否已解鎖
    if (_data.agents[agentId]?.isUnlocked == true) return false;

    // 檢查金幣
    if (_data.gold < def.unlockCondition.goldCost) return false;

    // 檢查鑽石
    if (_data.diamonds < def.unlockCondition.diamondCost) return false;

    // 檢查關卡進度
    if (def.unlockCondition.stageRequirement != null) {
      final progress = _data.stageProgress[def.unlockCondition.stageRequirement!];
      if (progress == null || !progress.cleared) return false;
      if (def.unlockCondition.requireAllStars == true && progress.stars < 3) {
        return false;
      }
    }

    // 扣除貨幣
    _data.gold -= def.unlockCondition.goldCost;
    _data.diamonds -= def.unlockCondition.diamondCost;

    // 解鎖角色
    _data.agents[agentId] = CatAgentInstance(
      definitionId: agentId,
      isUnlocked: true,
    );

    // 自動加入隊伍（如果隊伍未滿）
    if (_data.team.length < 3 && !_data.team.contains(agentId)) {
      _data.team.add(agentId);
    }

    await _save();
    notifyListeners();
    return true;
  }

  /// 升級角色
  Future<bool> levelUpAgent(String agentId, int expToAdd) async {
    final instance = _data.agents[agentId];
    if (instance == null || !instance.isUnlocked) return false;

    final def = CatAgentData.getById(agentId);
    if (def == null) return false;

    final maxLevel = getAgentMaxLevel(agentId);
    if (instance.level >= maxLevel) return false;

    instance.currentExp += expToAdd;

    // 檢查升級
    while (instance.level < maxLevel) {
      final required = def.expRequiredForLevel(instance.level + 1) -
          def.expRequiredForLevel(instance.level);
      if (instance.currentExp >= required) {
        instance.currentExp -= required;
        instance.level++;
      } else {
        break;
      }
    }

    await _save();
    notifyListeners();
    return true;
  }

  /// 設定隊伍
  Future<void> setTeam(List<String> agentIds) async {
    // 驗證：最多 3 個，且都已解鎖
    final validIds = agentIds.where((id) {
      return _data.agents[id]?.isUnlocked == true;
    }).take(3).toList();

    _data.team = validIds;
    await _save();
    notifyListeners();
  }

  /// 在隊伍中加入/移除角色
  Future<void> toggleTeamMember(String agentId) async {
    if (_data.team.contains(agentId)) {
      // 移除（但至少保留 1 個）
      if (_data.team.length > 1) {
        _data.team.remove(agentId);
      }
    } else if (_data.team.length < 3) {
      // 加入（最多 3 個）
      if (_data.agents[agentId]?.isUnlocked == true) {
        _data.team.add(agentId);
      }
    }
    await _save();
    notifyListeners();
  }

  // ─── 戰鬥結算 ───

  /// 完成戰鬥，儲存進度和發放獎勵
  Future<BattleReward> completeBattle({
    required String stageId,
    required bool isVictory,
    required int score,
    required double hpPercent,
    required int goldReward,
    required int expReward,
    String? unlockAgentId,
  }) async {
    if (!isVictory) {
      return const BattleReward();
    }

    // 計算星級（血量制）
    // 3星：未扣血（100%）
    // 2星：血量 ≥ 20%
    // 1星：血量 < 20%
    int stars;
    if (hpPercent >= 1.0) {
      stars = 3;
    } else if (hpPercent >= 0.2) {
      stars = 2;
    } else {
      stars = 1;
    }

    // 更新關卡進度（只保留最佳）
    final existing = _data.stageProgress[stageId];
    final isFirstClear = existing == null || !existing.cleared;
    final newStars = (existing?.stars ?? 0) > stars ? existing!.stars : stars;
    final newBest = (existing?.bestScore ?? 0) > score ? existing!.bestScore : score;

    _data.stageProgress[stageId] = StageProgress(
      cleared: true,
      stars: newStars,
      bestScore: newBest,
    );

    // 首次通關才發放全額獎勵，重複通關半額
    final actualGold = isFirstClear ? goldReward : (goldReward * 0.5).round();
    final actualExp = isFirstClear ? expReward : (expReward * 0.5).round();

    _data.gold += actualGold;
    _data.addPlayerExp(actualExp);

    // 解鎖角色
    bool agentUnlocked = false;
    if (unlockAgentId != null && _data.agents[unlockAgentId]?.isUnlocked != true) {
      _data.agents[unlockAgentId] = CatAgentInstance(
        definitionId: unlockAgentId,
        isUnlocked: true,
      );
      if (_data.team.length < 3) {
        _data.team.add(unlockAgentId);
      }
      agentUnlocked = true;
    }

    // 素材掉落（根據章節和星級）
    final drops = _generateBattleMaterialDrops(stageId, stars);
    for (final entry in drops.entries) {
      final key = entry.key.name;
      _data.materials[key] = (_data.materials[key] ?? 0) + entry.value;
    }

    // 更新每日任務
    if (_data.dailyQuests.needsReset) {
      _data.dailyQuests.reset();
    }
    _data.dailyQuests.stagesCompleted++;

    await _save();
    notifyListeners();

    return BattleReward(
      gold: actualGold,
      exp: actualExp,
      stars: stars,
      isFirstClear: isFirstClear,
      agentUnlocked: agentUnlocked,
      unlockedAgentId: unlockAgentId,
      materialDrops: drops,
    );
  }

  static final _rng = Random();

  /// 根據關卡 ID 和星級生成素材掉落
  Map<GameMaterial, int> _generateBattleMaterialDrops(String stageId, int stars) {
    final drops = <GameMaterial, int>{};
    // 從 stageId 解析章節 (e.g. "1-3" → chapter 1)
    final chapter = int.tryParse(stageId.split('-').first) ?? 1;

    // 基礎掉落：水晶粉塵
    drops[GameMaterial.crystalDust] = 1 + _rng.nextInt(2) + (stars - 1);

    // 碎片掉落（章節越高越好）
    if (chapter >= 1) {
      drops[GameMaterial.commonShard] = 1 + _rng.nextInt(2);
    }
    if (chapter >= 2 && _rng.nextDouble() < 0.5) {
      drops[GameMaterial.advancedShard] = 1;
    }
    if (chapter >= 3 && _rng.nextDouble() < 0.25) {
      drops[GameMaterial.rareShard] = 1;
    }

    // 屬性精華掉落（隨機一種）
    if (_rng.nextDouble() < 0.3 + stars * 0.1) {
      final essences = [
        GameMaterial.essenceA,
        GameMaterial.essenceB,
        GameMaterial.essenceC,
        GameMaterial.essenceD,
        GameMaterial.essenceE,
      ];
      drops[essences[_rng.nextInt(essences.length)]] = 1;
    }

    // 星級獎勵
    if (stars >= 2 && _rng.nextDouble() < 0.3) {
      drops[GameMaterial.talentScroll] = 1;
    }
    if (stars >= 3 && _rng.nextDouble() < 0.2) {
      final rare = [GameMaterial.skillCore, GameMaterial.passiveGem];
      drops[rare[_rng.nextInt(rare.length)]] = 1;
    }

    return drops;
  }

  // ─── 貨幣操作 ───

  Future<void> addGold(int amount) async {
    _data.gold += amount;
    await _save();
    notifyListeners();
  }

  Future<void> addDiamonds(int amount) async {
    _data.diamonds += amount;
    await _save();
    notifyListeners();
  }

  // ─── 每日任務 ───

  /// 領取每日登入獎勵
  Future<void> claimDailyLogin() async {
    if (_data.dailyQuests.needsReset) {
      _data.dailyQuests.reset();
    }
    if (!_data.dailyQuests.hasLoggedIn) {
      _data.dailyQuests.hasLoggedIn = true;
      _data.gold += 50;
      await _save();
      notifyListeners();
    }
  }

  /// 領取每日全完成獎勵
  Future<void> claimDailyReward() async {
    if (_data.dailyQuests.allCompleted && !_data.dailyQuests.rewardsClaimed) {
      _data.dailyQuests.rewardsClaimed = true;
      _data.diamonds += 10;
      await _save();
      notifyListeners();
    }
  }

  /// 記錄消除方塊數（每日任務用）
  Future<void> addBlocksEliminated(int count) async {
    if (_data.dailyQuests.needsReset) {
      _data.dailyQuests.reset();
    }
    _data.dailyQuests.blocksEliminated += count;
    await _save();
    notifyListeners();
  }

  // ─── 七日打卡 ───

  /// 七日打卡（回傳是否成功）
  Future<bool> weeklyCheckIn() async {
    final wc = _data.weeklyCheckIn;
    // 週期結束自動開新週期
    if (wc.isCycleComplete) {
      wc.resetCycle();
    }
    // 跨日刷新
    if (wc.needsRefresh) {
      wc.refreshDay();
    }
    if (!wc.checkIn()) return false;
    await _save();
    notifyListeners();
    return true;
  }

  /// 領取七日打卡獎勵（根據天數）
  /// 獎勵在 UI 層定義，這裡只負責發放
  Future<void> claimWeeklyReward({int gold = 0, int diamonds = 0}) async {
    _data.gold += gold;
    _data.diamonds += diamonds;
    await _save();
    notifyListeners();
  }

  // ─── 新手任務 ───

  /// 檢查並自動完成新手任務（根據當前進度）
  void refreshNewbieQuests() {
    final nq = _data.newbieQuests;
    final d = _data;

    // 完成教學
    if (d.tutorialCompleted) nq.complete('tutorial');
    // 解鎖第二個角色
    if (d.agents.values.where((a) => a.isUnlocked).length >= 2) nq.complete('unlock_agent');
    // 通關 1-3
    if (d.stageProgress['1-3']?.cleared == true) nq.complete('clear_1_3');
    // 組滿 3 人隊伍
    if (d.team.length >= 3) nq.complete('full_team');
    // 達到 Lv.5
    if (d.playerLevel >= 5) nq.complete('reach_lv5');
    // 消除 500 方塊（累計）
    if (d.dailyQuests.blocksEliminated >= 500) nq.complete('eliminate_500');
    // 完成一次每日全任務
    if (d.dailyQuests.rewardsClaimed) nq.complete('daily_all');
  }

  /// 領取新手任務獎勵
  Future<bool> claimNewbieReward(String questId, {int gold = 0, int diamonds = 0}) async {
    final nq = _data.newbieQuests;
    if (!nq.isCompleted(questId) || nq.isClaimed(questId)) return false;
    nq.claim(questId);
    _data.gold += gold;
    _data.diamonds += diamonds;
    await _save();
    notifyListeners();
    return true;
  }

  // ─── 體力操作 ───

  bool get hasEnoughStamina => _data.stamina > 0;

  Future<bool> consumeStamina(int amount) async {
    if (_data.consumeStamina(amount)) {
      await _save();
      notifyListeners();
      return true;
    }
    return false;
  }

  /// 刷新體力（計算離線恢復）
  void refreshStamina() {
    _data.recoverStamina();
    notifyListeners();
  }

  // ─── 素材操作 ───

  int getMaterialCount(GameMaterial type) {
    return _data.materials[type.name] ?? 0;
  }

  bool hasMaterials(Map<GameMaterial, int> cost) {
    for (final entry in cost.entries) {
      if (getMaterialCount(entry.key) < entry.value) return false;
    }
    return true;
  }

  void _deductMaterials(Map<GameMaterial, int> cost) {
    for (final entry in cost.entries) {
      final key = entry.key.name;
      _data.materials[key] = (_data.materials[key] ?? 0) - entry.value;
    }
  }

  // ─── 進化操作 ───

  /// 進化角色
  Future<bool> evolveAgent(String agentId) async {
    final instance = _data.agents[agentId];
    if (instance == null || !instance.isUnlocked) return false;
    if (instance.evolutionStage >= 2) return false;

    final def = CatAgentData.getById(agentId);
    if (def == null) return false;

    final nextStage = instance.evolutionStage + 1;
    final evo = EvolutionData.getEvolution(def.rarity.name, nextStage);
    if (evo == null) return false;

    // 檢查等級需求
    if (instance.level < evo.requiredLevel) return false;

    // 檢查費用
    if (_data.gold < evo.goldCost) return false;
    if (!hasMaterials(evo.materialCost)) return false;

    // 扣除
    _data.gold -= evo.goldCost;
    _deductMaterials(evo.materialCost);
    instance.evolutionStage = nextStage;

    await _save();
    notifyListeners();
    return true;
  }

  /// 取得角色進化後的等級上限
  int getAgentMaxLevel(String agentId) {
    final def = CatAgentData.getById(agentId);
    if (def == null) return 30;
    final instance = _data.agents[agentId];
    var maxLevel = def.maxLevel;
    if (instance != null) {
      final evolutions = EvolutionData.getEvolutionsForRarity(def.rarity.name);
      for (int i = 0; i < instance.evolutionStage && i < evolutions.length; i++) {
        maxLevel += evolutions[i].maxLevelIncrease;
      }
    }
    return maxLevel;
  }

  // ─── 天賦樹操作 ───

  /// 解鎖天賦節點
  Future<bool> unlockTalentNode(String agentId, String nodeId) async {
    final instance = _data.agents[agentId];
    if (instance == null || !instance.isUnlocked) return false;
    if (instance.unlockedTalentIds.contains(nodeId)) return false;

    final node = TalentTreeData.getNodeById(nodeId);
    if (node == null) return false;

    // 檢查前置條件
    if (node.prerequisiteNodeId != null &&
        !instance.unlockedTalentIds.contains(node.prerequisiteNodeId)) {
      return false;
    }

    // 檢查費用
    if (_data.gold < node.goldCost) return false;
    if (!hasMaterials(node.materialCost)) return false;

    // 扣除
    _data.gold -= node.goldCost;
    _deductMaterials(node.materialCost);
    instance.unlockedTalentIds.add(nodeId);

    await _save();
    notifyListeners();
    return true;
  }

  // ─── 技能強化操作 ───

  /// 升級技能階級
  Future<bool> upgradeSkillTier(String agentId) async {
    final instance = _data.agents[agentId];
    if (instance == null || !instance.isUnlocked) return false;
    if (instance.skillTier >= 5) return false;

    final nextTier = SkillTierData.getTier(agentId, instance.skillTier + 1);
    if (nextTier == null) return false;

    // 檢查費用
    if (_data.gold < nextTier.goldCost) return false;
    if (!hasMaterials(nextTier.materialCost)) return false;

    // 扣除
    _data.gold -= nextTier.goldCost;
    _deductMaterials(nextTier.materialCost);
    instance.skillTier++;

    await _save();
    notifyListeners();
    return true;
  }

  // ─── 被動技能操作 ───

  /// 解鎖被動技能
  Future<bool> unlockPassive(String agentId, String passiveId) async {
    final instance = _data.agents[agentId];
    if (instance == null || !instance.isUnlocked) return false;
    if (instance.unlockedPassiveIds.contains(passiveId)) return false;

    final passive = PassiveSkillData.getPassiveById(passiveId);
    if (passive == null || passive.agentId != agentId) return false;

    // 檢查等級門檻
    if (instance.level < passive.unlockAtAgentLevel) return false;

    // 檢查費用
    if (_data.gold < passive.goldCost) return false;
    if (!hasMaterials(passive.materialCost)) return false;

    // 扣除
    _data.gold -= passive.goldCost;
    _deductMaterials(passive.materialCost);
    instance.unlockedPassiveIds.add(passiveId);

    await _save();
    notifyListeners();
    return true;
  }

  /// 裝備被動技能
  Future<bool> equipPassive(String agentId, String passiveId) async {
    final instance = _data.agents[agentId];
    if (instance == null || !instance.isUnlocked) return false;
    if (!instance.unlockedPassiveIds.contains(passiveId)) return false;
    if (instance.equippedPassiveIds.contains(passiveId)) return false;
    if (instance.equippedPassiveIds.length >= 2) return false;

    instance.equippedPassiveIds.add(passiveId);

    await _save();
    notifyListeners();
    return true;
  }

  /// 卸下被動技能
  Future<bool> unequipPassive(String agentId, String passiveId) async {
    final instance = _data.agents[agentId];
    if (instance == null || !instance.isUnlocked) return false;
    if (!instance.equippedPassiveIds.contains(passiveId)) return false;

    instance.equippedPassiveIds.remove(passiveId);

    await _save();
    notifyListeners();
    return true;
  }

  // ─── GM 工具（開發用） ───

  /// 體力補滿
  Future<void> gmRefillStamina() async {
    _data.stamina = _data.maxStamina;
    _data.lastStaminaRecover = DateTime.now();
    await _save();
    notifyListeners();
  }

  /// 重置所有關卡進度
  Future<void> gmResetStages() async {
    _data.stageProgress.clear();
    await _save();
    notifyListeners();
  }

  /// 設定玩家等級（GM）
  Future<void> gmSetPlayerLevel(int level) async {
    _data.playerLevel = level.clamp(1, 999);
    _data.playerExp = 0;
    await _save();
    notifyListeners();
  }

  /// 增加玩家等級（GM）
  Future<void> gmAddPlayerLevel(int levels) async {
    _data.playerLevel = (_data.playerLevel + levels).clamp(1, 999);
    _data.playerExp = 0;
    await _save();
    notifyListeners();
  }

  /// 通關所有關卡（GM，全 3 星）
  Future<void> gmClearAllStages() async {
    for (final stage in StageData.allStages) {
      _data.stageProgress[stage.id] = const StageProgress(
        cleared: true,
        stars: 3,
        bestScore: 9999,
      );
    }
    await _save();
    notifyListeners();
  }

  /// 通關指定章節所有關卡（GM，全 3 星）
  Future<void> gmClearChapter(int chapter) async {
    for (final stage in StageData.allStages) {
      if (stage.chapter == chapter) {
        _data.stageProgress[stage.id] = const StageProgress(
          cleared: true,
          stars: 3,
          bestScore: 9999,
        );
      }
    }
    await _save();
    notifyListeners();
  }

  /// 加金幣
  Future<void> gmAddGold(int amount) async {
    _data.gold += amount;
    await _save();
    notifyListeners();
  }

  /// 加鑽石
  Future<void> gmAddDiamonds(int amount) async {
    _data.diamonds += amount;
    await _save();
    notifyListeners();
  }

  /// 解鎖全角色
  Future<void> gmUnlockAllAgents() async {
    for (final def in CatAgentData.allAgents) {
      if (_data.agents[def.id]?.isUnlocked != true) {
        _data.agents[def.id] = CatAgentInstance(
          definitionId: def.id,
          isUnlocked: true,
        );
      }
    }
    await _save();
    notifyListeners();
  }

  /// 全角色升到指定等級
  Future<void> gmSetAllAgentLevel(int level) async {
    for (final entry in _data.agents.entries) {
      if (entry.value.isUnlocked) {
        entry.value.level = level;
        entry.value.currentExp = 0;
      }
    }
    await _save();
    notifyListeners();
  }

  /// 發放素材
  Future<void> gmAddMaterials(GameMaterial type, int amount) async {
    final key = type.name;
    _data.materials[key] = (_data.materials[key] ?? 0) + amount;
    await _save();
    notifyListeners();
  }

  /// 發放全部素材（每種 50 個）
  Future<void> gmAddAllMaterials() async {
    for (final type in GameMaterial.values) {
      _data.materials[type.name] = (_data.materials[type.name] ?? 0) + 50;
    }
    await _save();
    notifyListeners();
  }

  /// 重置所有資料（回到新玩家狀態）
  Future<void> gmResetAll() async {
    _data = PlayerData.newPlayer();
    await _save();
    notifyListeners();
  }

  // ─── 教學相關 ───

  /// 完成教學
  Future<void> completeTutorial() async {
    _data.tutorialCompleted = true;
    await _save();
    notifyListeners();
  }

  /// 重置教學（GM 用）
  Future<void> gmResetTutorial() async {
    _data.tutorialCompleted = false;
    await _save();
    notifyListeners();
  }
}

/// 角色資訊（定義 + 實例的組合）
class AgentInfo {
  final CatAgentDefinition definition;
  final CatAgentInstance? instance;

  const AgentInfo({
    required this.definition,
    this.instance,
  });

  bool get isUnlocked => instance?.isUnlocked == true;
  int get level => instance?.level ?? 1;
  int get currentExp => instance?.currentExp ?? 0;
  int get evolutionStage => instance?.evolutionStage ?? 0;

  /// 進化名稱（加後綴）
  String get displayName {
    if (evolutionStage == 0) return definition.name;
    final evolutions = EvolutionData.getEvolutionsForRarity(definition.rarity.name);
    if (evolutionStage <= evolutions.length) {
      return '${definition.name}${evolutions[evolutionStage - 1].nameSuffix}';
    }
    return definition.name;
  }

  /// 進化倍率
  double get _evoAtkMult {
    if (evolutionStage == 0) return 1.0;
    final evo = EvolutionData.getEvolution(definition.rarity.name, evolutionStage);
    return evo?.atkMultiplier ?? 1.0;
  }
  double get _evoDefMult {
    if (evolutionStage == 0) return 1.0;
    final evo = EvolutionData.getEvolution(definition.rarity.name, evolutionStage);
    return evo?.defMultiplier ?? 1.0;
  }
  double get _evoHpMult {
    if (evolutionStage == 0) return 1.0;
    final evo = EvolutionData.getEvolution(definition.rarity.name, evolutionStage);
    return evo?.hpMultiplier ?? 1.0;
  }

  int get atk => (definition.atkAtLevel(level) * _evoAtkMult).round();
  int get def => (definition.defAtLevel(level) * _evoDefMult).round();
  int get hp => (definition.hpAtLevel(level) * _evoHpMult).round();
}

/// 戰鬥結算獎勵
class BattleReward {
  final int gold;
  final int exp;
  final int stars;
  final bool isFirstClear;
  final bool agentUnlocked;
  final String? unlockedAgentId;
  final Map<GameMaterial, int> materialDrops; // 素材掉落

  const BattleReward({
    this.gold = 0,
    this.exp = 0,
    this.stars = 0,
    this.isFirstClear = false,
    this.agentUnlocked = false,
    this.unlockedAgentId,
    this.materialDrops = const {},
  });
}
