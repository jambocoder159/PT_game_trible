import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../config/bottle_dessert_map.dart';
import '../../../config/ingredient_data.dart';
import '../../../config/theme.dart';
import '../../../core/models/block.dart';
import '../../../core/models/bottle_data.dart';
import '../../agents/providers/player_provider.dart';
import '../providers/bottle_provider.dart';

/// 工坊詳情面板 — 查看/切換每個瓶子的甜點產線
class WorkshopDetailPanel extends StatefulWidget {
  const WorkshopDetailPanel({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.bgSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const WorkshopDetailPanel(),
    );
  }

  @override
  State<WorkshopDetailPanel> createState() => _WorkshopDetailPanelState();
}

class _WorkshopDetailPanelState extends State<WorkshopDetailPanel> {
  BlockColor _selectedColor = BlockColor.coral;

  @override
  Widget build(BuildContext context) {
    return Consumer2<BottleProvider, PlayerProvider>(
      builder: (context, bottleProvider, playerProvider, _) {
        final bottle = bottleProvider.getBottle(_selectedColor);
        final bottleDef = BottleDefinitions.getByColor(_selectedColor);
        final currentDessert = bottleProvider.getCurrentDessert(_selectedColor);
        final allTiers = BottleDessertMap.getAll(_selectedColor);

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 拖曳指示條
                Container(
                  width: 36, height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.accentSecondary.withAlpha(60),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),

                const Text(
                  '🧁 甜點工坊',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: AppTheme.fontTitleMd,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),

                // 瓶子選擇條
                SizedBox(
                  height: 40,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: BlockColor.values.map((color) {
                      final def = BottleDefinitions.getByColor(color);
                      final isSelected = color == _selectedColor;
                      final b = bottleProvider.getBottle(color);
                      return GestureDetector(
                        onTap: () => setState(() => _selectedColor = color),
                        child: Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? color.color.withAlpha(30)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? color.color.withAlpha(180)
                                  : AppTheme.accentSecondary.withAlpha(40),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(def.emoji, style: const TextStyle(fontSize: AppTheme.fontTitleMd)),
                              Text(
                                'Lv.${b.level}',
                                style: TextStyle(
                                  color: isSelected ? color.color : AppTheme.textSecondary,
                                  fontSize: AppTheme.fontLabelSm,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 12),

                // 當前瓶子資訊卡
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.bgCard,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _selectedColor.color.withAlpha(60)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(bottleDef.emoji, style: const TextStyle(fontSize: AppTheme.fontDisplayLg)),
                          const SizedBox(width: 8),
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
                                if (currentDessert != null)
                                  Text(
                                    '目前生產：${currentDessert.emoji} ${currentDessert.name}  售價 ${currentDessert.sellPrice}🍬',
                                    style: TextStyle(
                                      color: AppTheme.textSecondary.withAlpha(180),
                                      fontSize: AppTheme.fontLabelLg,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // 能量進度條
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: bottle.fillProgress,
                          minHeight: 8,
                          backgroundColor: AppTheme.bgSecondary,
                          valueColor: AlwaysStoppedAnimation(
                            _selectedColor.color.withAlpha(bottle.isFull ? 220 : 140),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '能量 ${bottle.currentEnergy} / ${bottle.capacity}',
                        style: TextStyle(
                          color: AppTheme.textSecondary.withAlpha(130),
                          fontSize: AppTheme.fontLabelSm,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // 可選甜點列表
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 240),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: allTiers.length,
                    itemBuilder: (context, index) {
                      final tier = allTiers[index];
                      final recipe = DessertDefinitions.getById(tier.dessertId);
                      if (recipe == null) return const SizedBox.shrink();

                      final isUnlocked = tier.requiredLevel <= bottle.level;
                      final isCurrent = currentDessert?.id == tier.dessertId;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? _selectedColor.color.withAlpha(15)
                              : AppTheme.bgCard,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isCurrent
                                ? _selectedColor.color.withAlpha(120)
                                : AppTheme.accentSecondary.withAlpha(30),
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              recipe.emoji,
                              style: TextStyle(
                                fontSize: AppTheme.fontDisplayMd,
                                color: isUnlocked ? null : AppTheme.textSecondary.withAlpha(60),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    recipe.name,
                                    style: TextStyle(
                                      color: isUnlocked
                                          ? AppTheme.textPrimary
                                          : AppTheme.textSecondary.withAlpha(80),
                                      fontSize: AppTheme.fontBodyMd,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    isUnlocked
                                        ? '售價 ${recipe.sellPrice}🍬 · 耗能 ${tier.energyCost}'
                                        : '🔒 需 Lv.${tier.requiredLevel}',
                                    style: TextStyle(
                                      color: AppTheme.textSecondary.withAlpha(isUnlocked ? 150 : 80),
                                      fontSize: AppTheme.fontLabelSm,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isCurrent)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF51CF66).withAlpha(20),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  '生產中 ✓',
                                  style: TextStyle(
                                    color: Color(0xFF51CF66),
                                    fontSize: AppTheme.fontLabelSm,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                            else if (isUnlocked)
                              GestureDetector(
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  bottleProvider.setCurrentDessert(
                                    _selectedColor,
                                    tier.dessertId,
                                  );
                                  setState(() {});
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _selectedColor.color.withAlpha(20),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: _selectedColor.color.withAlpha(100)),
                                  ),
                                  child: Text(
                                    '切換',
                                    style: TextStyle(
                                      color: _selectedColor.color,
                                      fontSize: AppTheme.fontLabelLg,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // 瓶子升級按鈕（永遠顯示）
                if (bottle.level < BottleDefinitions.maxLevel) ...[
                  const SizedBox(height: 8),
                  _buildUpgradeButton(context, bottle, bottleDef, bottleProvider, playerProvider),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildUpgradeButton(
    BuildContext context,
    BottleStatus bottle,
    BottleDefinition bottleDef,
    BottleProvider bottleProvider,
    PlayerProvider playerProvider,
  ) {
    final canUpgrade = bottleProvider.canUpgrade(_selectedColor, playerProvider.data);
    final targetLevel = bottle.level + 1;
    final levelData = BottleDefinitions.getLevelData(targetLevel);
    final materials = BottleDefinitions.getUpgradeMaterials(targetLevel, _selectedColor);

    // 判斷缺什麼
    String? blockReason;
    if (!canUpgrade) {
      if (levelData.stageGateId != null) {
        final progress = playerProvider.data.stageProgress[levelData.stageGateId!];
        if (progress == null || !progress.cleared) {
          blockReason = '需通關 ${levelData.stageGateId}';
        }
      }
      if (blockReason == null && playerProvider.data.gold < levelData.upgradeCostGold) {
        blockReason = '金幣不足 (需 ${levelData.upgradeCostGold})';
      }
      if (blockReason == null) {
        for (final entry in materials.entries) {
          if ((playerProvider.data.materials[entry.key] ?? 0) < entry.value) {
            blockReason = '素材不足';
            break;
          }
        }
      }
      blockReason ??= '條件不足';
    }

    return GestureDetector(
      onTap: canUpgrade
          ? () {
              if (bottleProvider.upgradeBottle(_selectedColor, playerProvider.data)) {
                HapticFeedback.mediumImpact();
                playerProvider.notifyAndSave();
                setState(() {});
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
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          gradient: canUpgrade
              ? LinearGradient(colors: [_selectedColor.color.withAlpha(180), _selectedColor.color])
              : null,
          color: canUpgrade ? null : AppTheme.bgSecondary,
          borderRadius: BorderRadius.circular(8),
          border: canUpgrade
              ? null
              : Border.all(color: AppTheme.accentSecondary.withAlpha(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '⬆ 升級至 Lv.$targetLevel',
              style: TextStyle(
                color: canUpgrade ? Colors.white : AppTheme.textSecondary.withAlpha(120),
                fontSize: AppTheme.fontBodyMd,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (!canUpgrade && blockReason != null) ...[
              const SizedBox(height: 2),
              Text(
                blockReason,
                style: TextStyle(
                  color: AppTheme.textSecondary.withAlpha(100),
                  fontSize: AppTheme.fontLabelSm,
                ),
              ),
            ],
            if (canUpgrade && levelData.upgradeCostGold > 0) ...[
              const SizedBox(height: 2),
              Text(
                '${levelData.upgradeCostGold} 🍬',
                style: TextStyle(
                  color: Colors.white.withAlpha(200),
                  fontSize: AppTheme.fontLabelSm,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
