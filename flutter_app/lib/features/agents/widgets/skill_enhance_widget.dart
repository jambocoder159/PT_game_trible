/// 技能強化 Tab Widget
/// 顯示 5 階技能升級路線
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/skill_tier_data.dart';
import '../../../config/theme.dart';
import '../../../core/models/material.dart';
import '../../../core/models/skill_enhancement.dart';
import '../providers/player_provider.dart';

class SkillEnhanceWidget extends StatelessWidget {
  final String agentId;
  final int currentTier;

  const SkillEnhanceWidget({
    super.key,
    required this.agentId,
    required this.currentTier,
  });

  @override
  Widget build(BuildContext context) {
    final tiers = SkillTierData.getTiersForAgent(agentId);

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tiers.length,
      itemBuilder: (context, index) {
        final tier = tiers[index];
        final isCurrentTier = tier.tier == currentTier;
        final isUnlocked = tier.tier <= currentTier;
        final isNext = tier.tier == currentTier + 1;

        return _SkillTierCard(
          tier: tier,
          isCurrentTier: isCurrentTier,
          isUnlocked: isUnlocked,
          isNext: isNext,
          agentId: agentId,
        );
      },
    );
  }
}

class _SkillTierCard extends StatelessWidget {
  final SkillTierDefinition tier;
  final bool isCurrentTier;
  final bool isUnlocked;
  final bool isNext;
  final String agentId;

  const _SkillTierCard({
    required this.tier,
    required this.isCurrentTier,
    required this.isUnlocked,
    required this.isNext,
    required this.agentId,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isCurrentTier
        ? Colors.amber
        : isUnlocked
            ? Colors.green
            : isNext
                ? Colors.blue
                : AppTheme.textSecondary.withAlpha(40);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: isUnlocked
          ? AppTheme.bgCard
          : AppTheme.bgCard.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        side: BorderSide(color: borderColor, width: isCurrentTier ? 2 : 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: borderColor.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Tier ${tier.tier}',
                    style: TextStyle(
                      color: borderColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tier.name,
                    style: TextStyle(
                      color: isUnlocked
                          ? AppTheme.textPrimary
                          : AppTheme.textSecondary,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (isCurrentTier)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      '當前',
                      style: TextStyle(
                          color: Colors.amber,
                          fontSize: 11,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              tier.description,
              style: TextStyle(
                color: isUnlocked
                    ? AppTheme.textSecondary
                    : AppTheme.textSecondary.withValues(alpha: 0.6),
                fontSize: 13,
              ),
            ),
            if (tier.newMechanic != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.auto_awesome, size: 14, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text(
                    '新機制：${tier.newMechanic!.label}',
                    style: TextStyle(
                      color: Colors.amber.shade300,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
            if (isNext) ...[
              const SizedBox(height: 12),
              _UpgradeButton(agentId: agentId, tier: tier),
            ],
          ],
        ),
      ),
    );
  }
}

class _UpgradeButton extends StatelessWidget {
  final String agentId;
  final SkillTierDefinition tier;

  const _UpgradeButton({required this.agentId, required this.tier});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () async {
          final provider = context.read<PlayerProvider>();
          final success = await provider.upgradeSkillTier(agentId);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(success
                    ? '技能升級至 Tier ${tier.tier} 成功！'
                    : '資源不足'),
                backgroundColor: success ? Colors.green : Colors.red,
              ),
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.shade700,
          padding: const EdgeInsets.symmetric(vertical: 10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('升級', style: TextStyle(fontSize: 14)),
            const SizedBox(width: 8),
            Text(
              '(${_costText()})',
              style: TextStyle(
                  fontSize: 11, color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  String _costText() {
    final parts = <String>[];
    if (tier.goldCost > 0) parts.add('${tier.goldCost}g');
    for (final entry in tier.materialCost.entries) {
      parts.add('${entry.key.emoji}${entry.value}');
    }
    return parts.join(' ');
  }
}
