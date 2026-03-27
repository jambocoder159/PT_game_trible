/// 角色詳情頁（參考 RPG 手遊版型）
/// 上半：角色卡（立繪 + 數值條）；下半：技能/進化/天賦清單
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../config/cat_agent_data.dart';
import '../../../config/evolution_data.dart';
import '../../../config/image_assets.dart';
import '../../../config/theme.dart';
import '../../../core/models/cat_agent.dart';
import '../providers/player_provider.dart';
import '../widgets/material_inventory.dart';
import '../widgets/evolution_widget.dart';
import '../widgets/talent_tree_widget.dart';
import '../widgets/skill_enhance_widget.dart';
import '../widgets/passive_skill_widget.dart';

// ─── 配色常數（暖色點心屋風格） ───
const _cardBg = Color(0xFF7A5240);      // 暖可可 (= AppTheme.bgCard)
const _cardBorder = Color(0xFF5C3A28);  // 牛奶巧克力 (= AppTheme.bgSecondary)
const _statBarBg = Color(0xFF5C3A28);   // 深棕色（搭配深色主題）
const _statBarHp = Color(0xFF4CAF50);
const _statBarAtk = Color(0xFFFF9800);
const _statBarDef = Color(0xFF42A5F5);
const _statBarSpd = Color(0xFFAB47BC);

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
        final attrColor = definition.attribute.blockColor.color;

        return Scaffold(
          backgroundColor: AppTheme.bgPrimary,
          body: SafeArea(
            child: Column(
              children: [
                // ── 頂部彩色名稱欄 ──
                _NameBanner(
                  definition: definition,
                  displayName: agentInfo.displayName,
                  level: agentInfo.level,
                  attrColor: attrColor,
                  onBack: () => Navigator.of(context).pop(),
                ),
                // ── 素材背包 ──
                const Padding(
                  padding: EdgeInsets.fromLTRB(12, 6, 12, 0),
                  child: MaterialInventoryBar(),
                ),
                // ── 角色卡片（立繪 + 數值） ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                  child: _CharacterCard(
                    definition: definition,
                    agentInfo: agentInfo,
                    attrColor: attrColor,
                  ),
                ),
                // ── 經驗值 + 訓練 ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: _TrainingBar(
                    definition: definition,
                    agentInfo: agentInfo,
                    attrColor: attrColor,
                  ),
                ),
                const SizedBox(height: 4),
                // ── Tab 區域（進化/天賦/技能/被動） ──
                Expanded(
                  child: _TabSection(
                    agentId: definition.id,
                    agentLevel: agentInfo.level,
                    instance: agentInfo.instance,
                    attrColor: attrColor,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════
// 頂部彩色名稱欄
// ═══════════════════════════════════════════

class _NameBanner extends StatelessWidget {
  final CatAgentDefinition definition;
  final String displayName;
  final int level;
  final Color attrColor;
  final VoidCallback onBack;

  const _NameBanner({
    required this.definition,
    required this.displayName,
    required this.level,
    required this.attrColor,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            attrColor.withAlpha(180),
            attrColor.withAlpha(100),
            attrColor.withAlpha(180),
          ],
        ),
        border: Border(
          bottom: BorderSide(color: attrColor.withAlpha(200), width: 2),
        ),
      ),
      child: Row(
        children: [
          // 返回按鈕
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary, size: 22),
            onPressed: onBack,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          // 角色名稱
          Expanded(
            child: Center(
              child: Text(
                displayName,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
          // 等級資訊 icon
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppTheme.bgCard.withAlpha(180),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Lv.$level',
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════
// 角色卡片（立繪左 + 數值右）
// ═══════════════════════════════════════════

class _CharacterCard extends StatelessWidget {
  final CatAgentDefinition definition;
  final AgentInfo agentInfo;
  final Color attrColor;

  const _CharacterCard({
    required this.definition,
    required this.agentInfo,
    required this.attrColor,
  });

  double get _evoMult {
    final stage = agentInfo.instance?.evolutionStage ?? 0;
    if (stage == 0) return 1.0;
    final evo = EvolutionData.getEvolution(definition.rarity.name, stage);
    return evo?.atkMultiplier ?? 1.0;
  }

  int get _atk => (definition.atkAtLevel(agentInfo.level) * _evoMult).round();
  int get _def => (definition.defAtLevel(agentInfo.level) * _evoMult).round();
  int get _hp => (definition.hpAtLevel(agentInfo.level) * _evoMult).round();
  int get _spd => definition.baseSpeed;

  @override
  Widget build(BuildContext context) {
    final charPath = ImageAssets.characterImage(definition.id);

    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _cardBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: attrColor.withAlpha(30),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ─── 左半：角色立繪 + 職業/品種/稀有度 ───
            SizedBox(
              width: 140,
              child: Column(
                children: [
                  // 職業標籤
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: attrColor.withAlpha(40),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(11),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(_roleIcon(definition.role),
                            color: attrColor, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '${definition.role.label}型',
                          style: TextStyle(
                            color: attrColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 品種
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '種族：${definition.breed}',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  // 角色立繪（背景圖 + 立繪疊加）
                  Expanded(
                    child: Stack(
                      children: [
                        // 角色卡背景圖（不影響 layout）
                        Positioned.fill(
                          child: Opacity(
                            opacity: 0.35,
                            child: Image.asset(
                              ImageAssets.agentInfoBackground,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                            ),
                          ),
                        ),
                        // 角色立繪
                        Positioned.fill(
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: charPath != null
                                ? Image.asset(
                                    charPath,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => _fallbackImage(),
                                  )
                                : _fallbackImage(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 稀有度星星
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _RarityStars(rarity: definition.rarity, color: attrColor),
                  ),
                ],
              ),
            ),

            // 分隔線
            Container(width: 1, color: _cardBorder),

            // ─── 右半：數值面板 ───
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // HP
                    _StatRow(
                      icon: Icons.favorite,
                      iconColor: _statBarHp,
                      label: 'HP',
                      value: _hp,
                      maxValue: _maxStat(_hp),
                      barColor: _statBarHp,
                    ),
                    const SizedBox(height: 8),
                    // ATK
                    _StatRow(
                      icon: Icons.flash_on,
                      iconColor: _statBarAtk,
                      label: 'ATK',
                      value: _atk,
                      maxValue: _maxStat(_atk),
                      barColor: _statBarAtk,
                    ),
                    const SizedBox(height: 8),
                    // DEF
                    _StatRow(
                      icon: Icons.shield,
                      iconColor: _statBarDef,
                      label: 'DEF',
                      value: _def,
                      maxValue: _maxStat(_def),
                      barColor: _statBarDef,
                    ),
                    const SizedBox(height: 8),
                    // SPD
                    _StatRow(
                      icon: Icons.speed,
                      iconColor: _statBarSpd,
                      label: 'SPD',
                      value: _spd,
                      maxValue: 5,
                      barColor: _statBarSpd,
                      invert: true, // 速度越小越快
                    ),
                    const SizedBox(height: 12),
                    // 技能簡介
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.bgSecondary,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: attrColor.withAlpha(40),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.auto_awesome,
                                  color: attrColor, size: 14),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  definition.skill.name,
                                  style: TextStyle(
                                    color: attrColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withAlpha(50),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${definition.skill.energyCost}',
                                  style: TextStyle(
                                    color: Colors.amber.shade300,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            definition.passiveDescription,
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 10,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fallbackImage() {
    return Center(
      child: GameIcon(
        assetPath: ImageAssets.attributeIcon(definition.attribute),
        fallbackEmoji: definition.attribute.emoji,
        size: 48,
      ),
    );
  }

  /// 估算最大值（用於進度條比例）
  int _maxStat(int value) {
    if (value > 300) return (value * 1.5).round();
    if (value > 100) return (value * 2.0).round();
    return (value * 3.0).round();
  }

  IconData _roleIcon(AgentRole role) {
    switch (role) {
      case AgentRole.striker:
        return Icons.bolt;
      case AgentRole.defender:
        return Icons.shield;
      case AgentRole.supporter:
        return Icons.healing;
      case AgentRole.destroyer:
        return Icons.local_fire_department;
      case AgentRole.infiltrator:
        return Icons.visibility;
    }
  }
}

// ═══════════════════════════════════════════
// 數值列（圖示 + 標籤 + 數值條 + 數字）
// ═══════════════════════════════════════════

class _StatRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final int value;
  final int maxValue;
  final Color barColor;
  final bool invert;

  const _StatRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.maxValue,
    required this.barColor,
    this.invert = false,
  });

  @override
  Widget build(BuildContext context) {
    final displayValue = invert ? (maxValue - value + 1) : value;
    final ratio = maxValue > 0 ? (displayValue / maxValue).clamp(0.0, 1.0) : 0.0;

    return Row(
      children: [
        Icon(icon, color: iconColor, size: 16),
        const SizedBox(width: 6),
        // 進度條
        Expanded(
          child: Stack(
            children: [
              // 背景
              Container(
                height: 16,
                decoration: BoxDecoration(
                  color: _statBarBg,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              // 填充
              FractionallySizedBox(
                widthFactor: ratio,
                child: Container(
                  height: 16,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        barColor.withAlpha(200),
                        barColor,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              // 數值文字（疊在條上）
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '$value',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        shadows: [Shadow(color: Colors.black, blurRadius: 3)],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════
// 稀有度星星
// ═══════════════════════════════════════════

class _RarityStars extends StatelessWidget {
  final AgentRarity rarity;
  final Color color;

  const _RarityStars({required this.rarity, required this.color});

  @override
  Widget build(BuildContext context) {
    final starCount = rarity.tier;
    final starColors = [
      Colors.grey.shade400, // N
      Colors.blue.shade300,  // R
      Colors.purple.shade300, // SR
      Colors.amber.shade400, // SSR
    ];
    final starColor = starColors[rarity.tier - 1];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 稀有度文字
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          margin: const EdgeInsets.only(right: 4),
          decoration: BoxDecoration(
            color: starColor.withAlpha(40),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: starColor.withAlpha(100)),
          ),
          child: Text(
            rarity.display,
            style: TextStyle(
              color: starColor,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        // 星星
        ...List.generate(starCount, (_) => Icon(
          Icons.star,
          color: starColor,
          size: 14,
        )),
      ],
    );
  }
}

// ═══════════════════════════════════════════
// 經驗值條 + 訓練按鈕
// ═══════════════════════════════════════════

class _TrainingBar extends StatelessWidget {
  final CatAgentDefinition definition;
  final AgentInfo agentInfo;
  final Color attrColor;

  const _TrainingBar({
    required this.definition,
    required this.agentInfo,
    required this.attrColor,
  });

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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _cardBorder),
      ),
      child: Row(
        children: [
          // EXP 標籤
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.green.withAlpha(30),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'EXP',
              style: TextStyle(
                color: Colors.green.shade300,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // 經驗條
          Expanded(
            child: Stack(
              children: [
                Container(
                  height: 14,
                  decoration: BoxDecoration(
                    color: _statBarBg,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: progress,
                  child: Container(
                    height: 14,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isMaxLevel
                            ? [Colors.amber.shade600, Colors.amber]
                            : [Colors.green.shade700, Colors.green.shade400],
                      ),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Center(
                    child: Text(
                      isMaxLevel ? 'MAX' : '$currentExp / $expForNext',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        shadows: [Shadow(color: Colors.black, blurRadius: 2)],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // 訓練按鈕
          _ActionButton(
            label: isMaxLevel ? '已滿級' : '訓練',
            cost: isMaxLevel ? null : 50,
            costIcon: '🪙',
            enabled: !isMaxLevel,
            onTap: () {
              final provider = context.read<PlayerProvider>();
              if (provider.data.gold >= 50) {
                HapticFeedback.lightImpact();
                provider.addGold(-50);
                provider.levelUpAgent(definition.id, 30);
                ScaffoldMessenger.of(context)
                  ..clearSnackBars()
                  ..showSnackBar(
                    const SnackBar(
                      content: Text('獲得 30 EXP！(消耗 50 金幣)'),
                      backgroundColor: Colors.green,
                    ),
                  );
              } else {
                ScaffoldMessenger.of(context)
                  ..clearSnackBars()
                  ..showSnackBar(
                    const SnackBar(
                      content: Text('金幣不足！'),
                      backgroundColor: Colors.red,
                    ),
                  );
              }
            },
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════
// 通用動作按鈕（模仿截圖中「強化」「獲得」按鈕）
// ═══════════════════════════════════════════

class _ActionButton extends StatelessWidget {
  final String label;
  final int? cost;
  final String? costIcon;
  final bool enabled;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    this.cost,
    this.costIcon,
    this.enabled = true,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: enabled ? Colors.green.shade700 : AppTheme.bgCard,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: enabled ? Colors.green.shade800 : AppTheme.accentSecondary.withAlpha(60),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: enabled ? Colors.white : AppTheme.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (cost != null)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (costIcon != null)
                    Text(costIcon!, style: const TextStyle(fontSize: 10)),
                  Text(
                    '$cost',
                    style: TextStyle(
                      color: enabled ? Colors.white70 : AppTheme.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════
// Tab 區域（進化 / 天賦樹 / 技能強化 / 被動技能）
// ═══════════════════════════════════════════

class _TabSection extends StatefulWidget {
  final String agentId;
  final int agentLevel;
  final CatAgentInstance? instance;
  final Color attrColor;

  const _TabSection({
    required this.agentId,
    required this.agentLevel,
    this.instance,
    required this.attrColor,
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
            // Tab 標籤列
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: _cardBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _cardBorder),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorColor: widget.attrColor,
                indicatorWeight: 3,
                labelColor: widget.attrColor,
                unselectedLabelColor: AppTheme.textSecondary,
                labelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
                unselectedLabelStyle: const TextStyle(fontSize: 12),
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: '進化', height: 36),
                  Tab(text: '天賦', height: 36),
                  Tab(text: '技能', height: 36),
                  Tab(text: '被動', height: 36),
                ],
              ),
            ),
            const SizedBox(height: 4),
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
