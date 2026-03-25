/// 角色詳情頁
/// 包含角色資訊 + 進化/天賦樹/技能強化/被動技能四個 Tab
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/cat_agent_data.dart';
import '../../../config/evolution_data.dart';
import '../../../config/theme.dart';
import '../../../core/models/cat_agent.dart';
import '../providers/player_provider.dart';
import '../widgets/material_inventory.dart';
import '../widgets/evolution_widget.dart';
import '../widgets/talent_tree_widget.dart';
import '../widgets/skill_enhance_widget.dart';
import '../widgets/passive_skill_widget.dart';

class AgentDetailScreen extends StatelessWidget {
  final CatAgentDefinition definition;

  const AgentDetailScreen({super.key, required this.definition});

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (context, provider, _) {
        final agentInfo = AgentInfo(
          definition: definition,
          instance: provider.data.agents[definition.id],
        );
        final level = agentInfo.level;

        return Scaffold(
          backgroundColor: AppTheme.bgPrimary,
          appBar: AppBar(
            title: Text('${definition.attribute.emoji} ${agentInfo.displayName}'),
            backgroundColor: AppTheme.bgSecondary,
          ),
          body: Column(
            children: [
              // 素材背包
              const Padding(
                padding: EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: MaterialInventoryBar(),
              ),
              // 角色基本資訊
              _AgentHeader(definition: definition, level: level, instance: agentInfo.instance, displayName: agentInfo.displayName),
              // 經驗值 + 訓練按鈕
              _TrainingBar(definition: definition, agentInfo: agentInfo),
              // Tab 區域
              Expanded(
                child: _TabSection(
                  agentId: definition.id,
                  agentLevel: level,
                  instance: agentInfo.instance,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AgentHeader extends StatelessWidget {
  final CatAgentDefinition definition;
  final int level;
  final CatAgentInstance? instance;
  final String displayName;

  const _AgentHeader({
    required this.definition,
    required this.level,
    this.instance,
    required this.displayName,
  });

  double get _evoMult {
    final stage = instance?.evolutionStage ?? 0;
    if (stage == 0) return 1.0;
    final evo = EvolutionData.getEvolution(definition.rarity.name, stage);
    return evo?.atkMultiplier ?? 1.0;
  }

  int _getAdjustedAtk() => (definition.atkAtLevel(level) * _evoMult).round();
  int _getAdjustedDef() => (definition.defAtLevel(level) * _evoMult).round();
  int _getAdjustedHp() => (definition.hpAtLevel(level) * _evoMult).round();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppTheme.bgSecondary.withValues(alpha: 0.5),
      child: Row(
        children: [
          // 頭像
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: definition.attribute.blockColor.color.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              border: Border.all(
                color: definition.attribute.blockColor.color.withValues(alpha: 0.6),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                definition.attribute.emoji,
                style: const TextStyle(fontSize: 28),
              ),
            ),
          ),
          const SizedBox(width: 14),
          // 資訊
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '$displayName Lv.$level',
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _RarityBadge(rarity: definition.rarity),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${definition.breed} · ${definition.role.label}',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // 數值
          Row(
            children: [
              _StatChip('ATK', _getAdjustedAtk()),
              const SizedBox(width: 4),
              _StatChip('DEF', _getAdjustedDef()),
              const SizedBox(width: 4),
              _StatChip('HP', _getAdjustedHp()),
            ],
          ),
        ],
      ),
    );
  }
}

class _TabSection extends StatefulWidget {
  final String agentId;
  final int agentLevel;
  final CatAgentInstance? instance;

  const _TabSection({
    required this.agentId,
    required this.agentLevel,
    this.instance,
  });

  @override
  State<_TabSection> createState() => _TabSectionState();
}

class _TabSectionState extends State<_TabSection>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (context, provider, _) {
        final instance = provider.data.agents[widget.agentId];

        return Column(
          children: [
            TabBar(
              controller: _tabController,
              indicatorColor: Colors.amber,
              labelColor: Colors.amber,
              unselectedLabelColor: AppTheme.textSecondary,
              isScrollable: true,
              tabs: const [
                Tab(text: '進化'),
                Tab(text: '天賦樹'),
                Tab(text: '技能強化'),
                Tab(text: '被動技能'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  EvolutionWidget(
                    definition: CatAgentData.getById(widget.agentId)!,
                    currentStage: instance?.evolutionStage ?? 0,
                    currentLevel: instance?.level ?? 1,
                  ),
                  TalentTreeWidget(
                    agentId: widget.agentId,
                    unlockedTalentIds: instance?.unlockedTalentIds ?? [],
                  ),
                  SkillEnhanceWidget(
                    agentId: widget.agentId,
                    currentTier: instance?.skillTier ?? 1,
                  ),
                  PassiveSkillWidget(
                    agentId: widget.agentId,
                    agentLevel: instance?.level ?? 1,
                    unlockedPassiveIds: instance?.unlockedPassiveIds ?? [],
                    equippedPassiveIds: instance?.equippedPassiveIds ?? [],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _RarityBadge extends StatelessWidget {
  final AgentRarity rarity;

  const _RarityBadge({required this.rarity});

  Color get _color {
    switch (rarity) {
      case AgentRarity.n:
        return Colors.grey;
      case AgentRarity.r:
        return Colors.blue;
      case AgentRarity.sr:
        return Colors.purple;
      case AgentRarity.ssr:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: _color, width: 1),
      ),
      child: Text(
        rarity.display,
        style: TextStyle(
          color: _color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final int value;

  const _StatChip(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$label $value',
        style: const TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 11,
        ),
      ),
    );
  }
}

/// 經驗值條 + 訓練按鈕
class _TrainingBar extends StatelessWidget {
  final CatAgentDefinition definition;
  final AgentInfo agentInfo;

  const _TrainingBar({required this.definition, required this.agentInfo});

  @override
  Widget build(BuildContext context) {
    final level = agentInfo.level;
    final currentExp = agentInfo.currentExp;
    final expForNext = definition.expRequiredForLevel(level + 1) -
        definition.expRequiredForLevel(level);
    final progress = expForNext > 0
        ? (currentExp / expForNext).clamp(0.0, 1.0)
        : 1.0;
    final isMaxLevel = level >= definition.maxLevel;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppTheme.bgSecondary.withValues(alpha: 0.3),
      child: Row(
        children: [
          // 經驗條
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'EXP',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      isMaxLevel ? 'MAX' : '$currentExp / $expForNext',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: Colors.white10,
                    valueColor: AlwaysStoppedAnimation(
                      isMaxLevel ? Colors.amber : Colors.green.shade400,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // 訓練按鈕
          ElevatedButton(
            onPressed: isMaxLevel
                ? null
                : () {
                    final provider = context.read<PlayerProvider>();
                    if (provider.data.gold >= 50) {
                      provider.addGold(-50);
                      provider.levelUpAgent(definition.id, 30);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('獲得 30 EXP！(消耗 50 金幣)'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('金幣不足！'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: Size.zero,
            ),
            child: Text(
              isMaxLevel ? '已滿級' : '訓練 🪙50',
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
