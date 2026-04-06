import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../config/ingredient_data.dart';
import '../../../config/theme.dart';
import '../../../core/models/dessert.dart';
import '../../agents/providers/player_provider.dart';
import '../providers/crafting_provider.dart';

/// 製作甜點 Bottom Sheet
class CraftingPanel extends StatefulWidget {
  const CraftingPanel({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.bgSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const CraftingPanel(),
    );
  }

  @override
  State<CraftingPanel> createState() => _CraftingPanelState();
}

class _CraftingPanelState extends State<CraftingPanel> {
  int _selectedTier = 0; // 0 = all

  @override
  Widget build(BuildContext context) {
    return Consumer2<CraftingProvider, PlayerProvider>(
      builder: (context, craftingProvider, playerProvider, _) {
        final allRecipes = craftingProvider.getAllRecipes();
        final filteredRecipes = _selectedTier == 0
            ? allRecipes
            : allRecipes.where((r) => r.tier == _selectedTier).toList();

        return SafeArea(
          child: DraggableScrollableSheet(
            initialChildSize: 0.7,
            maxChildSize: 0.9,
            minChildSize: 0.4,
            expand: false,
            builder: (context, scrollController) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Column(
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
                    const Text(
                      '🧁 甜點工坊',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // 分類篩選
                    SizedBox(
                      height: 30,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _FilterChip(label: '全部', isSelected: _selectedTier == 0,
                              onTap: () => setState(() => _selectedTier = 0)),
                          _FilterChip(label: '新手', isSelected: _selectedTier == 1,
                              onTap: () => setState(() => _selectedTier = 1)),
                          _FilterChip(label: '中級', isSelected: _selectedTier == 2,
                              onTap: () => setState(() => _selectedTier = 2)),
                          _FilterChip(label: '進階', isSelected: _selectedTier == 3,
                              onTap: () => setState(() => _selectedTier = 3)),
                          _FilterChip(label: '大師', isSelected: _selectedTier == 4,
                              onTap: () => setState(() => _selectedTier = 4)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // 一鍵售出
                    if (playerProvider.data.desserts.values.any((v) => v > 0))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: GestureDetector(
                          onTap: () => _sellAll(context, craftingProvider, playerProvider),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFFD43B), Color(0xFFFCC419)],
                              ),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFFD43B).withAlpha(60),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('💰', style: TextStyle(fontSize: 16)),
                                SizedBox(width: 6),
                                Text(
                                  '一鍵售出全部甜點',
                                  style: TextStyle(
                                    color: Color(0xFF7C5E10),
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                    // 食譜列表
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: filteredRecipes.length,
                        itemBuilder: (context, index) {
                          final recipe = filteredRecipes[index];
                          return _RecipeCard(
                            recipe: recipe,
                            craftingProvider: craftingProvider,
                            playerProvider: playerProvider,
                            onCraft: () => _craft(context, recipe, craftingProvider, playerProvider),
                            onSell: () => _sell(context, recipe, craftingProvider, playerProvider),
                            onBuyRecipe: () => _buyRecipe(context, recipe, craftingProvider, playerProvider),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _craft(BuildContext context, DessertRecipe recipe,
      CraftingProvider craftingProvider, PlayerProvider playerProvider) {
    if (craftingProvider.craftDessert(recipe.id, playerProvider.data)) {
      HapticFeedback.mediumImpact();
      playerProvider.notifyAndSave();
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${recipe.emoji} ${recipe.name} 製作完成！'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  void _sell(BuildContext context, DessertRecipe recipe,
      CraftingProvider craftingProvider, PlayerProvider playerProvider) {
    final income = craftingProvider.sellDessert(recipe.id, 1, playerProvider.data);
    if (income > 0) {
      HapticFeedback.lightImpact();
      playerProvider.notifyAndSave();
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('售出 ${recipe.name}，獲得 $income 🍬'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  void _sellAll(BuildContext context,
      CraftingProvider craftingProvider, PlayerProvider playerProvider) {
    final result = craftingProvider.sellAllDesserts(playerProvider.data);
    if (result.totalIncome > 0) {
      HapticFeedback.mediumImpact();
      playerProvider.notifyAndSave();
      setState(() {});
      final summary = result.items.entries.map((e) => '${e.key} x${e.value}').join('、');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('售出 $summary，共獲得 ${result.totalIncome} 🍬'),
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('目前沒有甜點可以售出'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  void _buyRecipe(BuildContext context, DessertRecipe recipe,
      CraftingProvider craftingProvider, PlayerProvider playerProvider) {
    if (craftingProvider.buyRecipe(recipe.id, playerProvider.data)) {
      HapticFeedback.mediumImpact();
      playerProvider.notifyAndSave();
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${recipe.emoji} ${recipe.name} 食譜已購買！'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.accentPrimary.withAlpha(30)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: isSelected
              ? Border.all(color: AppTheme.accentPrimary.withAlpha(150))
              : Border.all(color: AppTheme.accentSecondary.withAlpha(40)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppTheme.accentPrimary : AppTheme.textSecondary,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _RecipeCard extends StatelessWidget {
  final DessertRecipe recipe;
  final CraftingProvider craftingProvider;
  final PlayerProvider playerProvider;
  final VoidCallback onCraft;
  final VoidCallback onSell;
  final VoidCallback onBuyRecipe;

  const _RecipeCard({
    required this.recipe,
    required this.craftingProvider,
    required this.playerProvider,
    required this.onCraft,
    required this.onSell,
    required this.onBuyRecipe,
  });

  @override
  Widget build(BuildContext context) {
    final isUnlocked = craftingProvider.isRecipeUnlocked(recipe.id, playerProvider.data);
    final canCraft = craftingProvider.canCraft(recipe.id, playerProvider.data);
    final owned = playerProvider.data.desserts[recipe.id] ?? 0;
    final isPurchasable = recipe.unlock.type == DessertUnlockType.purchase && !isUnlocked;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isUnlocked ? AppTheme.bgCard : AppTheme.bgCard.withAlpha(150),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isUnlocked
              ? _tierColor(recipe.tier).withAlpha(80)
              : AppTheme.accentSecondary.withAlpha(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 標題行
          Row(
            children: [
              Text(recipe.emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          recipe.name,
                          style: TextStyle(
                            color: isUnlocked
                                ? AppTheme.textPrimary
                                : AppTheme.textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (owned > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppTheme.accentPrimary.withAlpha(20),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'x$owned',
                              style: const TextStyle(
                                color: AppTheme.accentPrimary,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      '售價 ${recipe.sellPrice} 🍬',
                      style: TextStyle(
                        color: AppTheme.textSecondary.withAlpha(150),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              // 操作按鈕
              if (!isUnlocked)
                _buildLockedButton(isPurchasable)
              else ...[
                if (owned > 0)
                  GestureDetector(
                    onTap: onSell,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      margin: const EdgeInsets.only(right: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD43B).withAlpha(30),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFFFD43B).withAlpha(100)),
                      ),
                      child: const Text(
                        '售出',
                        style: TextStyle(
                          color: Color(0xFFB8860B),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                GestureDetector(
                  onTap: canCraft ? onCraft : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: canCraft
                          ? const Color(0xFF51CF66)
                          : Colors.grey.withAlpha(50),
                      borderRadius: BorderRadius.circular(6),
                      border: canCraft
                          ? Border.all(color: const Color(0xFF40C057), width: 1)
                          : null,
                    ),
                    child: Text(
                      '製作',
                      style: TextStyle(
                        color: canCraft
                            ? Colors.white
                            : AppTheme.textSecondary.withAlpha(100),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),

          // 食材需求
          if (isUnlocked) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 4,
              runSpacing: 2,
              children: recipe.ingredients.entries.map((entry) {
                final ingredientDef = IngredientDefinitions.getById(entry.key);
                final owned = playerProvider.data.ingredients[entry.key] ?? 0;
                final needed = entry.value;
                final hasEnough = owned >= needed;

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: hasEnough
                        ? const Color(0xFF51CF66).withAlpha(15)
                        : const Color(0xFFFF6B6B).withAlpha(15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${ingredientDef?.emoji ?? "?"} ${ingredientDef?.name ?? entry.key} $owned/$needed',
                    style: TextStyle(
                      color: hasEnough
                          ? const Color(0xFF51CF66)
                          : const Color(0xFFFF6B6B),
                      fontSize: 10,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLockedButton(bool isPurchasable) {
    if (isPurchasable) {
      return GestureDetector(
        onTap: onBuyRecipe,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFFFD43B).withAlpha(30),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFFFFD43B).withAlpha(100)),
          ),
          child: Text(
            '${recipe.unlock.purchaseCost} 🍬',
            style: const TextStyle(
              color: Color(0xFFB8860B),
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.lock_outline, size: 14, color: AppTheme.textSecondary.withAlpha(80)),
        const SizedBox(width: 2),
        Text(
          _unlockText(),
          style: TextStyle(
            color: AppTheme.textSecondary.withAlpha(100),
            fontSize: 9,
          ),
        ),
      ],
    );
  }

  String _unlockText() {
    switch (recipe.unlock.type) {
      case DessertUnlockType.stageClear:
        return '通關 ${recipe.unlock.stageId}';
      case DessertUnlockType.purchase:
        return '${recipe.unlock.purchaseCost} 🍬';
      default:
        return '';
    }
  }

  Color _tierColor(int tier) {
    switch (tier) {
      case 4: return const Color(0xFFCC5DE8);
      case 3: return const Color(0xFF4DABF7);
      case 2: return const Color(0xFF51CF66);
      default: return const Color(0xFF888888);
    }
  }
}
