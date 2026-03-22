/// 角色詳情頁
/// 包含角色資訊 + 天賦樹/技能強化/被動技能三個 Tab
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../core/models/cat_agent.dart';
import '../providers/player_provider.dart';
import '../widgets/material_inventory.dart';
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
        final instance = provider.data.agents[definition.id];
        final level = instance?.level ?? 1;

        return Scaffold(
          backgroundColor: AppTheme.bgPrimary,
          appBar: AppBar(
            title: Text('${definition.attribute.emoji} ${definition.name}'),
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
              _AgentHeader(definition: definition, level: level, instance: instance),
              // Tab 區域
              Expanded(
                child: _TabSection(
                  agentId: definition.id,
                  agentLevel: level,
                  instance: instance,
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

  const _AgentHeader({
    required this.definition,
    required this.level,
    this.instance,
  });

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
                      '${definition.name} Lv.$level',
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
              _StatChip('ATK', definition.atkAtLevel(level)),
              const SizedBox(width: 4),
              _StatChip('DEF', definition.defAtLevel(level)),
              const SizedBox(width: 4),
              _StatChip('HP', definition.hpAtLevel(level)),
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
    _tabController = TabController(length: 3, vsync: this);
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
              tabs: const [
                Tab(text: '天賦樹'),
                Tab(text: '技能強化'),
                Tab(text: '被動技能'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
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
