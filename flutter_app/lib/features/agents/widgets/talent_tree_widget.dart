/// 天賦樹 Tab Widget
/// 顯示 3 條分支的天賦節點，可解鎖
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/talent_tree_data.dart';
import '../../../config/theme.dart';
import '../../../core/models/material.dart';
import '../../../core/models/talent_tree.dart';
import '../providers/player_provider.dart';

class TalentTreeWidget extends StatelessWidget {
  final String agentId;
  final List<String> unlockedTalentIds;

  const TalentTreeWidget({
    super.key,
    required this.agentId,
    required this.unlockedTalentIds,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: TalentBranch.values.map((branch) {
          return _BranchRow(
            agentId: agentId,
            branch: branch,
            unlockedTalentIds: unlockedTalentIds,
          );
        }).toList(),
      ),
    );
  }
}

class _BranchRow extends StatelessWidget {
  final String agentId;
  final TalentBranch branch;
  final List<String> unlockedTalentIds;

  const _BranchRow({
    required this.agentId,
    required this.branch,
    required this.unlockedTalentIds,
  });

  @override
  Widget build(BuildContext context) {
    final nodes = TalentTreeData.getNodesForBranch(agentId, branch);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.bgCard.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${branch.emoji} ${branch.label}分支',
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: AppTheme.fontBodyLg,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (int i = 0; i < nodes.length; i++) ...[
                  _TalentNode(
                    node: nodes[i],
                    isUnlocked: unlockedTalentIds.contains(nodes[i].id),
                    canUnlock: _canUnlock(nodes[i]),
                    agentId: agentId,
                  ),
                  if (i < nodes.length - 1)
                    Container(
                      width: 20,
                      height: 2,
                      color: unlockedTalentIds.contains(nodes[i].id)
                          ? Colors.green
                          : AppTheme.textSecondary.withAlpha(40),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _canUnlock(TalentNodeDefinition node) {
    if (unlockedTalentIds.contains(node.id)) return false;
    if (node.prerequisiteNodeId != null &&
        !unlockedTalentIds.contains(node.prerequisiteNodeId)) {
      return false;
    }
    return true;
  }
}

class _TalentNode extends StatelessWidget {
  final TalentNodeDefinition node;
  final bool isUnlocked;
  final bool canUnlock;
  final String agentId;

  const _TalentNode({
    required this.node,
    required this.isUnlocked,
    required this.canUnlock,
    required this.agentId,
  });

  @override
  Widget build(BuildContext context) {
    final color = isUnlocked
        ? Colors.green
        : canUnlock
            ? Colors.amber
            : Colors.grey;

    return GestureDetector(
      onTap: () => _showNodeDetail(context),
      child: Container(
        width: 72,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          border: Border.all(color: color, width: isUnlocked ? 2 : 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isUnlocked ? Icons.check_circle : Icons.radio_button_unchecked,
              color: color,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              node.name,
              style: TextStyle(
                color: color,
                fontSize: AppTheme.fontLabelLg,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '+${node.effectValue.round()}%',
              style: TextStyle(color: color.withValues(alpha: 0.8), fontSize: AppTheme.fontLabelLg),
            ),
          ],
        ),
      ),
    );
  }

  void _showNodeDetail(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgSecondary,
        title: Text(node.name,
            style: const TextStyle(color: AppTheme.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(node.description,
                style: const TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 12),
            Text('效果：${node.effectType.label} +${node.effectValue}%',
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: AppTheme.fontBodyLg)),
            const SizedBox(height: 8),
            if (!isUnlocked) ...[
              Text('費用：',
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: AppTheme.fontBodyLg)),
              Text('  金幣 ${node.goldCost}',
                  style: TextStyle(color: Colors.amber.shade300, fontSize: AppTheme.fontBodyMd)),
              ...node.materialCost.entries.map((e) => Text(
                    '  ${e.key.emoji} ${e.key.label} x${e.value}',
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: AppTheme.fontBodyMd),
                  )),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('關閉'),
          ),
          if (canUnlock)
            ElevatedButton(
              onPressed: () async {
                final provider = ctx.read<PlayerProvider>();
                final success =
                    await provider.unlockTalentNode(agentId, node.id);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                          Text(success ? '天賦「${node.name}」解鎖成功！' : '資源不足'),
                      backgroundColor: success ? Colors.green : Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700),
              child: const Text('解鎖'),
            ),
        ],
      ),
    );
  }
}
