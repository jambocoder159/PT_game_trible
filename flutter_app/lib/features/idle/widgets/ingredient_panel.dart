import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../config/ingredient_data.dart';
import '../../../config/theme.dart';
import '../../../core/models/block.dart';
import '../../../core/models/bottle_data.dart';
import '../../../core/models/ingredient.dart';
import '../../agents/providers/player_provider.dart';
import '../providers/bottle_provider.dart';

/// 轉換食材 Bottom Sheet
class IngredientPanel extends StatefulWidget {
  final BlockColor initialColor;

  const IngredientPanel({super.key, required this.initialColor});

  static void show(BuildContext context, {BlockColor? initialColor}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.bgSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => IngredientPanel(
        initialColor: initialColor ?? BlockColor.coral,
      ),
    );
  }

  @override
  State<IngredientPanel> createState() => _IngredientPanelState();
}

class _IngredientPanelState extends State<IngredientPanel> {
  late BlockColor _selectedColor;

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.initialColor;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<BottleProvider, PlayerProvider>(
      builder: (context, bottleProvider, playerProvider, _) {
        final bottle = bottleProvider.getBottle(_selectedColor);
        final bottleDef = BottleDefinitions.getByColor(_selectedColor);
        final allIngredients = IngredientDefinitions.getByBottleColor(_selectedColor);
        final available = bottleProvider.getAvailableIngredients(_selectedColor);
        final availableIds = available.map((i) => i.id).toSet();

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 拖拽指示條
                Container(
                  width: 36, height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.accentSecondary.withAlpha(60),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),

                // 標題
                Text(
                  '${bottleDef.emoji} ${bottleDef.name}',
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),

                // 能量顯示
                Text(
                  '能量：${bottle.currentEnergy} / ${bottle.capacity}',
                  style: TextStyle(
                    color: AppTheme.textSecondary.withAlpha(180),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 10),

                // 瓶子選擇條
                SizedBox(
                  height: 36,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: BlockColor.values.map((color) {
                      final def = BottleDefinitions.getByColor(color);
                      final isSelected = color == _selectedColor;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedColor = color),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? color.color.withAlpha(40)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: isSelected
                                ? Border.all(color: color.color.withAlpha(150))
                                : null,
                          ),
                          child: Text(
                            def.emoji,
                            style: TextStyle(
                              fontSize: 18,
                              color: isSelected ? null : AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 8),

                // 食材列表
                ...allIngredients.map((ingredient) {
                  final isUnlocked = availableIds.contains(ingredient.id);
                  final canAfford = bottle.currentEnergy >= ingredient.energyCost;
                  final owned = playerProvider.data.ingredients[ingredient.id] ?? 0;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: isUnlocked ? AppTheme.bgCard : AppTheme.bgCard.withAlpha(150),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isUnlocked
                            ? _tierColor(ingredient.tier).withAlpha(80)
                            : AppTheme.accentSecondary.withAlpha(30),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(ingredient.emoji, style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    ingredient.name,
                                    style: TextStyle(
                                      color: isUnlocked
                                          ? AppTheme.textPrimary
                                          : AppTheme.textSecondary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: _tierColor(ingredient.tier).withAlpha(30),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    child: Text(
                                      ingredient.tier.label,
                                      style: TextStyle(
                                        color: _tierColor(ingredient.tier),
                                        fontSize: 9,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isUnlocked
                                    ? '消耗 ${ingredient.energyCost} 能量 · 持有 $owned'
                                    : '需瓶等級 ${ingredient.bottleLevelRequired}',
                                style: TextStyle(
                                  color: AppTheme.textSecondary.withAlpha(130),
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isUnlocked)
                          GestureDetector(
                            onTap: canAfford
                                ? () => _convert(context, bottleProvider, playerProvider, ingredient)
                                : null,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: canAfford
                                    ? _selectedColor.color.withAlpha(canAfford ? 180 : 60)
                                    : AppTheme.bgSecondary,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '轉換',
                                style: TextStyle(
                                  color: canAfford ? Colors.white : AppTheme.textSecondary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          )
                        else
                          Icon(
                            Icons.lock_outline,
                            size: 16,
                            color: AppTheme.textSecondary.withAlpha(80),
                          ),
                      ],
                    ),
                  );
                }),

                // 升級按鈕
                const SizedBox(height: 6),
                if (bottle.level < BottleDefinitions.maxLevel)
                  _UpgradeButton(
                    color: _selectedColor,
                    bottle: bottle,
                    playerProvider: playerProvider,
                    bottleProvider: bottleProvider,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _convert(
    BuildContext context,
    BottleProvider bottleProvider,
    PlayerProvider playerProvider,
    IngredientDefinition ingredient,
  ) {
    final result = bottleProvider.convertIngredient(
      _selectedColor,
      ingredient.id,
      playerProvider.data,
    );
    if (result == null) return;

    HapticFeedback.mediumImpact();
    playerProvider.notifyAndSave();

    // 爆擊提示
    if (result.isCritical) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '爆擊！額外獲得 ${result.bonusIngredient?.name ?? ingredient.name}！',
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: const Color(0xFFFF6B6B),
        ),
      );
    }

    setState(() {});
  }

  Color _tierColor(IngredientTier tier) {
    switch (tier) {
      case IngredientTier.common:   return const Color(0xFF888888);
      case IngredientTier.uncommon: return const Color(0xFF51CF66);
      case IngredientTier.rare:     return const Color(0xFF4DABF7);
      case IngredientTier.epic:     return const Color(0xFFCC5DE8);
    }
  }
}

class _UpgradeButton extends StatelessWidget {
  final BlockColor color;
  final BottleStatus bottle;
  final PlayerProvider playerProvider;
  final BottleProvider bottleProvider;

  const _UpgradeButton({
    required this.color,
    required this.bottle,
    required this.playerProvider,
    required this.bottleProvider,
  });

  @override
  Widget build(BuildContext context) {
    final canUpgrade = bottleProvider.canUpgrade(color, playerProvider.data);
    final nextLevel = bottle.level + 1;
    final levelData = BottleDefinitions.getLevelData(nextLevel);

    return GestureDetector(
      onTap: canUpgrade
          ? () {
              HapticFeedback.mediumImpact();
              bottleProvider.upgradeBottle(color, playerProvider.data);
              playerProvider.notifyAndSave();
            }
          : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: canUpgrade
              ? color.color.withAlpha(30)
              : AppTheme.bgCard.withAlpha(150),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: canUpgrade
                ? color.color.withAlpha(150)
                : AppTheme.accentSecondary.withAlpha(40),
          ),
        ),
        child: Column(
          children: [
            Text(
              '升級到 Lv.$nextLevel (容量 ${levelData.capacity})',
              style: TextStyle(
                color: canUpgrade ? AppTheme.textPrimary : AppTheme.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${levelData.upgradeCostGold} 🍬${levelData.stageGateId != null ? ' · 需通關 ${levelData.stageGateId}' : ''}',
              style: TextStyle(
                color: AppTheme.textSecondary.withAlpha(150),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
