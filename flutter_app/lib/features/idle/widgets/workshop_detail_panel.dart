import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../config/bottle_dessert_map.dart';
import '../../../config/ingredient_data.dart';
import '../../../config/theme.dart';
import '../../../core/models/block.dart';
import '../../../core/models/bottle_data.dart';
import '../../../core/models/dessert.dart';
import '../../../core/models/material.dart' as game_material;
import '../../agents/providers/player_provider.dart';
import '../providers/bottle_provider.dart';
import '../providers/production_provider.dart';

/// 工坊詳情面板 — 查看/切換每個瓶子的甜點產線
class WorkshopDetailPanel extends StatefulWidget {
  final BlockColor initialColor;

  const WorkshopDetailPanel({
    super.key,
    this.initialColor = BlockColor.coral,
  });

  static void show(BuildContext context,
      {BlockColor initialColor = BlockColor.coral}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => WorkshopDetailPanel(initialColor: initialColor),
    );
  }

  @override
  State<WorkshopDetailPanel> createState() => _WorkshopDetailPanelState();
}

class _WorkshopDetailPanelState extends State<WorkshopDetailPanel> {
  late BlockColor _selectedColor;

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.initialColor;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<BottleProvider, PlayerProvider, ProductionProvider>(
      builder: (context, bottleProvider, playerProvider, production, _) {
        final bottle = bottleProvider.getBottle(_selectedColor);
        final bottleDef = BottleDefinitions.getByColor(_selectedColor);
        final currentDessert = bottleProvider.getCurrentDessert(_selectedColor);
        final tiers = BottleDessertMap.getAll(_selectedColor);

        return SafeArea(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.76,
              ),
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFFFF0D0), Color(0xFFEADDC0)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x4D000000),
                      offset: Offset(0, -8),
                      blurRadius: 24,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.accentSecondary.withAlpha(70),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _Header(color: _selectedColor),
                    const SizedBox(height: 12),
                    _BottleTabs(
                      selectedColor: _selectedColor,
                      bottleProvider: bottleProvider,
                      onSelected: (color) {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedColor = color);
                      },
                    ),
                    const SizedBox(height: 12),
                    _BottleSummaryCard(
                      bottle: bottle,
                      bottleDef: bottleDef,
                      dessert: currentDessert,
                      color: _selectedColor,
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: tiers.length,
                        itemBuilder: (context, index) {
                          final tier = tiers[index];
                          final recipe =
                              DessertDefinitions.getById(tier.dessertId);
                          if (recipe == null) return const SizedBox.shrink();

                          final isUnlocked = tier.requiredLevel <= bottle.level;
                          final isCurrent =
                              currentDessert?.id == tier.dessertId;
                          final catId =
                              production.firstIdleCat(playerProvider.data.team);
                          final canProduce = isUnlocked &&
                              catId != null &&
                              bottleProvider.canProduce(
                                  _selectedColor, tier.dessertId) &&
                              !production.displayCase.isFull;

                          return _DessertTile(
                            recipe: recipe,
                            tier: tier,
                            color: _selectedColor,
                            isUnlocked: isUnlocked,
                            isCurrent: isCurrent,
                            canProduce: canProduce,
                            onSwitch: isUnlocked && !isCurrent
                                ? () {
                                    HapticFeedback.lightImpact();
                                    bottleProvider.setCurrentDessert(
                                      _selectedColor,
                                      tier.dessertId,
                                    );
                                    setState(() {});
                                  }
                                : null,
                            onProduce: canProduce
                                ? () async {
                                    HapticFeedback.mediumImpact();
                                    bottleProvider.setCurrentDessert(
                                      _selectedColor,
                                      tier.dessertId,
                                    );
                                    final agent =
                                        playerProvider.data.agents[catId];
                                    final didStart =
                                        await production.startProduction(
                                      catId: catId,
                                      dessertId: tier.dessertId,
                                      sourceColor: _selectedColor,
                                      catLevel: agent?.level ?? 1,
                                      bottleProvider: bottleProvider,
                                    );
                                    if (!context.mounted) return;
                                    if (didStart) Navigator.of(context).pop();
                                  }
                                : null,
                          );
                        },
                      ),
                    ),
                    if (bottle.level < BottleDefinitions.maxLevel) ...[
                      const SizedBox(height: 10),
                      _UpgradeButton(
                        bottle: bottle,
                        bottleDef: bottleDef,
                        color: _selectedColor,
                        bottleProvider: bottleProvider,
                        playerProvider: playerProvider,
                        onUpgraded: () => setState(() {}),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  final BlockColor color;

  const _Header({required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, color.color.withAlpha(58)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withAlpha(210)),
            boxShadow: [
              BoxShadow(
                color: color.color.withAlpha(62),
                offset: const Offset(0, 4),
                blurRadius: 9,
              ),
            ],
          ),
          child: const Center(
            child: Text('🧁', style: TextStyle(fontSize: 17)),
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Text(
            '甜點工坊',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: AppTheme.fontTitleMd,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(132),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppTheme.accentSecondary.withAlpha(32)),
          ),
          child: Text(
            '魔法瓶設定',
            style: TextStyle(
              color: AppTheme.textSecondary.withAlpha(190),
              fontSize: AppTheme.fontLabelLg,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

class _BottleTabs extends StatelessWidget {
  final BlockColor selectedColor;
  final BottleProvider bottleProvider;
  final ValueChanged<BlockColor> onSelected;

  const _BottleTabs({
    required this.selectedColor,
    required this.bottleProvider,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: BlockColor.values.map((color) {
        final def = BottleDefinitions.getByColor(color);
        final bottle = bottleProvider.getBottle(color);
        final isSelected = color == selectedColor;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onSelected(color),
              child: AnimatedContainer(
                duration: AppTheme.animSwap,
                height: 48,
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          colors: [Colors.white, color.color.withAlpha(56)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        )
                      : null,
                  color: isSelected ? null : Colors.white.withAlpha(86),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: isSelected
                        ? color.color.withAlpha(190)
                        : AppTheme.accentSecondary.withAlpha(34),
                    width: isSelected ? 1.7 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isSelected
                          ? color.color.withAlpha(48)
                          : AppTheme.accentSecondary.withAlpha(14),
                      offset: const Offset(0, 4),
                      blurRadius: isSelected ? 9 : 5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(def.emoji,
                        style: const TextStyle(fontSize: AppTheme.fontTitleMd)),
                    const SizedBox(height: 1),
                    Text(
                      'Lv.${bottle.level}',
                      style: TextStyle(
                        color: isSelected
                            ? color.color
                            : AppTheme.textSecondary.withAlpha(150),
                        fontSize: AppTheme.fontLabelSm,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _BottleSummaryCard extends StatelessWidget {
  final BottleStatus bottle;
  final BottleDefinition bottleDef;
  final DessertRecipe? dessert;
  final BlockColor color;

  const _BottleSummaryCard({
    required this.bottle,
    required this.bottleDef,
    required this.dessert,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white.withAlpha(232), color.color.withAlpha(38)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.color.withAlpha(74)),
        boxShadow: [
          BoxShadow(
            color: color.color.withAlpha(36),
            offset: const Offset(0, 6),
            blurRadius: 14,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(180),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withAlpha(230)),
                ),
                child: Center(
                  child: Text(
                    bottleDef.emoji,
                    style: const TextStyle(fontSize: AppTheme.fontDisplayLg),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bottleDef.name,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: AppTheme.fontBodyLg,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      dessert == null
                          ? '尚未指定甜點'
                          : '目前：${dessert!.emoji} ${dessert!.name}  售價 ${dessert!.sellPrice}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppTheme.textSecondary.withAlpha(175),
                        fontSize: AppTheme.fontLabelLg,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: bottle.fillProgress,
              minHeight: 9,
              backgroundColor: AppTheme.accentSecondary.withAlpha(28),
              valueColor: AlwaysStoppedAnimation(
                color.color.withAlpha(bottle.isFull ? 235 : 175),
              ),
            ),
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              Text(
                '能量 ${bottle.currentEnergy} / ${bottle.capacity}',
                style: TextStyle(
                  color: AppTheme.textSecondary.withAlpha(145),
                  fontSize: AppTheme.fontLabelSm,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (bottle.isFull)
                const _SmallPill(label: '已滿', color: Color(0xFFE86B30)),
            ],
          ),
        ],
      ),
    );
  }
}

class _DessertTile extends StatelessWidget {
  final DessertRecipe recipe;
  final BottleDessertTier tier;
  final BlockColor color;
  final bool isUnlocked;
  final bool isCurrent;
  final bool canProduce;
  final VoidCallback? onSwitch;
  final VoidCallback? onProduce;

  const _DessertTile({
    required this.recipe,
    required this.tier,
    required this.color,
    required this.isUnlocked,
    required this.isCurrent,
    required this.canProduce,
    required this.onSwitch,
    required this.onProduce,
  });

  @override
  Widget build(BuildContext context) {
    final muted = !isUnlocked;

    return AnimatedContainer(
      duration: AppTheme.animSwap,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color:
            isCurrent ? color.color.withAlpha(24) : Colors.white.withAlpha(185),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCurrent
              ? color.color.withAlpha(128)
              : AppTheme.accentSecondary.withAlpha(32),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentSecondary.withAlpha(isCurrent ? 26 : 14),
            offset: const Offset(0, 4),
            blurRadius: 9,
          ),
        ],
      ),
      child: Row(
        children: [
          Opacity(
            opacity: muted ? 0.38 : 1,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppTheme.bgSecondary.withAlpha(150),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withAlpha(180)),
              ),
              child: Center(
                child: Text(
                  recipe.emoji,
                  style: const TextStyle(fontSize: AppTheme.fontDisplayMd),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recipe.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: muted
                        ? AppTheme.textSecondary.withAlpha(85)
                        : AppTheme.textPrimary,
                    fontSize: AppTheme.fontBodyMd,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isUnlocked
                      ? '售價 ${recipe.sellPrice} · 耗能 ${tier.energyCost} · ${recipe.craftDurationSec}s'
                      : '需 Lv.${tier.requiredLevel}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color:
                        AppTheme.textSecondary.withAlpha(isUnlocked ? 150 : 82),
                    fontSize: AppTheme.fontLabelSm,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (isUnlocked)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isCurrent)
                  const _SmallPill(label: '目前', color: Color(0xFF41B96D))
                else
                  _ActionChipButton(
                    label: '切換',
                    color: color,
                    filled: false,
                    onTap: onSwitch,
                  ),
                const SizedBox(width: 6),
                _ActionChipButton(
                  label: '製作',
                  color: color,
                  filled: canProduce,
                  onTap: onProduce,
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ActionChipButton extends StatelessWidget {
  final String label;
  final BlockColor color;
  final bool filled;
  final VoidCallback? onTap;

  const _ActionChipButton({
    required this.label,
    required this.color,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minWidth: 43),
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: enabled
              ? (filled ? color.color : color.color.withAlpha(22))
              : AppTheme.accentSecondary.withAlpha(22),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: enabled
                ? color.color.withAlpha(filled ? 0 : 95)
                : AppTheme.accentSecondary.withAlpha(28),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: enabled
                ? (filled ? Colors.white : color.color)
                : AppTheme.textSecondary.withAlpha(95),
            fontSize: AppTheme.fontLabelLg,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _UpgradeButton extends StatelessWidget {
  final BottleStatus bottle;
  final BottleDefinition bottleDef;
  final BlockColor color;
  final BottleProvider bottleProvider;
  final PlayerProvider playerProvider;
  final VoidCallback onUpgraded;

  const _UpgradeButton({
    required this.bottle,
    required this.bottleDef,
    required this.color,
    required this.bottleProvider,
    required this.playerProvider,
    required this.onUpgraded,
  });

  @override
  Widget build(BuildContext context) {
    final canUpgrade = bottleProvider.canUpgrade(color, playerProvider.data);
    final targetLevel = bottle.level + 1;
    final levelData = BottleDefinitions.getLevelData(targetLevel);
    final blockReason = _upgradeBlockReason(canUpgrade, levelData);
    final materials =
        BottleDefinitions.getUpgradeMaterials(levelData.level, color);
    final summary =
        canUpgrade ? '${levelData.upgradeCostGold} 金幣' : blockReason ?? '條件不足';

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: canUpgrade
          ? () {
              if (bottleProvider.upgradeBottle(color, playerProvider.data)) {
                HapticFeedback.mediumImpact();
                playerProvider.notifyAndSave();
                onUpgraded();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${bottleDef.name} 升級至 Lv.${bottle.level}！'),
                    duration: const Duration(seconds: 1),
                  ),
                );
              }
            }
          : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 12),
        decoration: BoxDecoration(
          gradient: canUpgrade
              ? LinearGradient(
                  colors: [color.color.withAlpha(205), color.color],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: canUpgrade ? null : Colors.white.withAlpha(92),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: canUpgrade
                ? Colors.white.withAlpha(120)
                : AppTheme.accentSecondary.withAlpha(32),
          ),
          boxShadow: [
            BoxShadow(
              color: canUpgrade
                  ? color.color.withAlpha(45)
                  : AppTheme.accentSecondary.withAlpha(12),
              offset: const Offset(0, 4),
              blurRadius: 9,
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '升級至 Lv.$targetLevel',
                        style: TextStyle(
                          color: canUpgrade
                              ? Colors.white
                              : AppTheme.textSecondary.withAlpha(120),
                          fontSize: AppTheme.fontBodyMd,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        summary,
                        style: TextStyle(
                          color: canUpgrade
                              ? Colors.white.withAlpha(210)
                              : AppTheme.textSecondary.withAlpha(95),
                          fontSize: AppTheme.fontLabelSm,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _showUpgradeDetails(
                    context,
                    levelData,
                    materials,
                  ),
                  child: Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: (canUpgrade ? Colors.white : AppTheme.bgCard)
                          .withAlpha(canUpgrade ? 48 : 180),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: canUpgrade
                            ? Colors.white.withAlpha(100)
                            : AppTheme.accentSecondary.withAlpha(38),
                      ),
                    ),
                    child: Icon(
                      Icons.info_outline_rounded,
                      size: 18,
                      color: canUpgrade
                          ? Colors.white
                          : AppTheme.textSecondary.withAlpha(150),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showUpgradeDetails(
    BuildContext context,
    BottleLevelData levelData,
    Map<String, int> materials,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 22),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.textSecondary.withAlpha(80),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                '${bottleDef.name} 升級至 Lv.${levelData.level}',
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: AppTheme.fontTitleMd,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              _UpgradeRequirementList(
                levelData: levelData,
                materials: materials,
                playerProvider: playerProvider,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _upgradeBlockReason(bool canUpgrade, BottleLevelData levelData) {
    if (canUpgrade) return null;
    if (levelData.stageGateId != null) {
      final progress =
          playerProvider.data.stageProgress[levelData.stageGateId!];
      if (progress == null || !progress.cleared) {
        return '需通關 ${levelData.stageGateId}';
      }
    }
    if (playerProvider.data.gold < levelData.upgradeCostGold) {
      return '金幣不足';
    }
    final materials =
        BottleDefinitions.getUpgradeMaterials(levelData.level, color);
    for (final entry in materials.entries) {
      if ((playerProvider.data.materials[entry.key] ?? 0) < entry.value) {
        return '素材不足';
      }
    }
    return '條件不足';
  }
}

class _UpgradeRequirementList extends StatelessWidget {
  final BottleLevelData levelData;
  final Map<String, int> materials;
  final PlayerProvider playerProvider;

  const _UpgradeRequirementList({
    required this.levelData,
    required this.materials,
    required this.playerProvider,
  });

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    if (levelData.stageGateId != null) {
      final progress =
          playerProvider.data.stageProgress[levelData.stageGateId!];
      final ok = progress != null && progress.cleared;
      rows.add(_RequirementRow(
        icon: Icons.flag_rounded,
        label: '通關 ${levelData.stageGateId}',
        owned: ok ? 1 : 0,
        required: 1,
        source: '從闖關頁完成指定關卡',
      ));
    }
    rows.add(_RequirementRow(
      icon: Icons.monetization_on_rounded,
      label: '金幣',
      owned: playerProvider.data.gold,
      required: levelData.upgradeCostGold,
      source: '售出展示櫃甜點、任務、關卡獎勵',
    ));
    for (final entry in materials.entries) {
      final material = _materialFromKey(entry.key);
      rows.add(_RequirementRow(
        icon: material?.iconData ?? Icons.inventory_2_rounded,
        label: material?.label ?? entry.key,
        owned: playerProvider.data.materials[entry.key] ?? 0,
        required: entry.value,
        source: _materialSource(material),
        color: material?.iconColor,
      ));
    }
    return Column(children: rows);
  }

  static game_material.GameMaterial? _materialFromKey(String key) {
    for (final material in game_material.GameMaterial.values) {
      if (material.name == key) return material;
    }
    return null;
  }

  static String _materialSource(game_material.GameMaterial? material) {
    if (material == null) return '查看背包或關卡獎勵';
    switch (material.category) {
      case game_material.MaterialCategory.shard:
        return '闖關寶箱、每日任務、新手任務';
      case game_material.MaterialCategory.functional:
        return '每日任務、商店、較高章節關卡';
      case game_material.MaterialCategory.essence:
        return '對應屬性關卡、進階寶箱、商店';
      case game_material.MaterialCategory.universal:
        return '任務、活動、商店兌換';
    }
  }
}

class _RequirementRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final int owned;
  final int required;
  final String source;
  final Color? color;

  const _RequirementRow({
    required this.icon,
    required this.label,
    required this.owned,
    required this.required,
    required this.source,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final missing = (required - owned).clamp(0, required);
    final ok = missing == 0;
    final iconColor =
        ok ? const Color(0xFF66BB6A) : color ?? AppTheme.accentPrimary;
    return Container(
      margin: const EdgeInsets.only(top: 5),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(72),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: ok
              ? const Color(0xFF66BB6A).withAlpha(80)
              : AppTheme.accentSecondary.withAlpha(40),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$label  $owned/$required${ok ? '' : '  缺 $missing'}',
                  style: TextStyle(
                    color: ok
                        ? AppTheme.textSecondary.withAlpha(150)
                        : AppTheme.textPrimary,
                    fontSize: AppTheme.fontLabelLg,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  source,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppTheme.textSecondary.withAlpha(120),
                    fontSize: AppTheme.fontLabelSm,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallPill extends StatelessWidget {
  final String label;
  final Color color;

  const _SmallPill({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(56)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: AppTheme.fontLabelSm,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
