/// 被動技能 Tab Widget
/// 顯示 4 個被動技能卡片，可解鎖與裝備
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/passive_skill_data.dart';
import '../../../config/theme.dart';
import '../../../core/models/material.dart';
import '../../../core/models/passive_skill.dart';
import '../providers/player_provider.dart';

class PassiveSkillWidget extends StatelessWidget {
  final String agentId;
  final int agentLevel;
  final List<String> unlockedPassiveIds;
  final List<String> equippedPassiveIds;

  const PassiveSkillWidget({
    super.key,
    required this.agentId,
    required this.agentLevel,
    required this.unlockedPassiveIds,
    required this.equippedPassiveIds,
  });

  @override
  Widget build(BuildContext context) {
    final passives = PassiveSkillData.getPassivesForAgent(agentId);

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: passives.length,
      itemBuilder: (context, index) {
        final passive = passives[index];
        final isUnlocked = unlockedPassiveIds.contains(passive.id);
        final isEquipped = equippedPassiveIds.contains(passive.id);
        final canUnlock = !isUnlocked && agentLevel >= passive.unlockAtAgentLevel;

        return _PassiveCard(
          passive: passive,
          isUnlocked: isUnlocked,
          isEquipped: isEquipped,
          canUnlock: canUnlock,
          agentLevel: agentLevel,
          equippedCount: equippedPassiveIds.length,
        );
      },
    );
  }
}

class _PassiveCard extends StatelessWidget {
  final PassiveSkillDefinition passive;
  final bool isUnlocked;
  final bool isEquipped;
  final bool canUnlock;
  final int agentLevel;
  final int equippedCount;

  const _PassiveCard({
    required this.passive,
    required this.isUnlocked,
    required this.isEquipped,
    required this.canUnlock,
    required this.agentLevel,
    required this.equippedCount,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isEquipped
        ? Colors.amber
        : isUnlocked
            ? Colors.green
            : canUnlock
                ? Colors.blue
                : AppTheme.textSecondary.withAlpha(40);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: isUnlocked
          ? AppTheme.bgCard
          : AppTheme.bgCard.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        side: BorderSide(color: borderColor, width: isEquipped ? 2 : 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            passive.name,
                            style: TextStyle(
                              color: isUnlocked
                                  ? AppTheme.textPrimary
                                  : AppTheme.textSecondary,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (isEquipped) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.amber.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                '裝備中',
                                style: TextStyle(
                                  color: Colors.amber,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        passive.description,
                        style: TextStyle(
                          color: isUnlocked
                              ? AppTheme.textSecondary
                              : AppTheme.textSecondary.withValues(alpha: 0.6),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isUnlocked)
                  _EquipButton(
                    passive: passive,
                    isEquipped: isEquipped,
                    equippedCount: equippedCount,
                  ),
              ],
            ),
            if (!isUnlocked) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    'Lv.${passive.unlockAtAgentLevel} 解鎖',
                    style: TextStyle(
                      color: agentLevel >= passive.unlockAtAgentLevel
                          ? Colors.green
                          : Colors.red.shade300,
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  if (canUnlock) _UnlockButton(passive: passive),
                ],
              ),
              if (!canUnlock && agentLevel < passive.unlockAtAgentLevel) ...[
                const SizedBox(height: 4),
                Text(
                  '需要等級 ${passive.unlockAtAgentLevel}（目前 Lv.$agentLevel）',
                  style: TextStyle(
                      color: Colors.red.shade300, fontSize: 11),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _EquipButton extends StatelessWidget {
  final PassiveSkillDefinition passive;
  final bool isEquipped;
  final int equippedCount;

  const _EquipButton({
    required this.passive,
    required this.isEquipped,
    required this.equippedCount,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () async {
        final provider = context.read<PlayerProvider>();
        bool success;
        if (isEquipped) {
          success = await provider.unequipPassive(passive.agentId, passive.id);
        } else {
          if (equippedCount >= 2) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('最多裝備 2 個被動技能'),
                backgroundColor: Colors.orange,
              ),
            );
            return;
          }
          success = await provider.equipPassive(passive.agentId, passive.id);
        }
        if (context.mounted && !success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('操作失敗'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      icon: Icon(
        isEquipped ? Icons.remove_circle : Icons.add_circle_outline,
        color: isEquipped ? Colors.red.shade300 : Colors.green,
        size: 28,
      ),
    );
  }
}

class _UnlockButton extends StatelessWidget {
  final PassiveSkillDefinition passive;

  const _UnlockButton({required this.passive});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        final provider = context.read<PlayerProvider>();
        final success =
            await provider.unlockPassive(passive.agentId, passive.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(success
                  ? '被動「${passive.name}」解鎖成功！'
                  : '資源不足'),
              backgroundColor: success ? Colors.green : Colors.red,
            ),
          );
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue.shade700,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        minimumSize: Size.zero,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('解鎖', style: TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            '(${_costText()})',
            style: TextStyle(
                fontSize: 10, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  String _costText() {
    final parts = <String>[];
    if (passive.goldCost > 0) parts.add('${passive.goldCost}g');
    for (final entry in passive.materialCost.entries) {
      parts.add('${entry.key.emoji}${entry.value}');
    }
    return parts.join(' ');
  }
}
