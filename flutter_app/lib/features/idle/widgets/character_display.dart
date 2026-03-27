import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../config/image_assets.dart';
import '../../../config/cat_agent_data.dart';
import '../../../config/theme.dart';
import '../../../core/models/cat_agent.dart';
import '../../agents/providers/player_provider.dart';
import '../providers/idle_provider.dart';

/// 單一角色放大展示（取代舊的 3 格隊伍面板）
class CharacterDisplay extends StatelessWidget {
  const CharacterDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<PlayerProvider, IdleProvider>(
      builder: (context, playerProvider, idleProvider, _) {
        if (!playerProvider.isInitialized) return const SizedBox.shrink();

        final team = playerProvider.data.team;
        if (team.isEmpty) return _buildEmptyState(context);

        final agentId = team.first;
        final agentDef = _findAgent(agentId);
        if (agentDef == null) return _buildEmptyState(context);

        final isReady = idleProvider.isSkillReady(agentId);
        final energy = idleProvider.getEnergy(agentId);
        final cost = agentDef.skill.energyCost;
        final attrColor = _attrColor(agentDef.attribute);

        return GestureDetector(
          onTap: isReady
              ? () => _activateSkill(context, agentDef, agentId, idleProvider)
              : null,
          child: Container(
            height: 88,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                // 角色圖像（放大）
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: attrColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isReady
                          ? attrColor.withAlpha(200)
                          : attrColor.withAlpha(60),
                      width: isReady ? 2.0 : 1.0,
                    ),
                    boxShadow: isReady
                        ? [BoxShadow(color: attrColor.withAlpha(60), blurRadius: 8)]
                        : null,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: _buildAgentImage(agentId, agentDef, 72),
                  ),
                ),
                const SizedBox(width: 10),
                // 角色資訊
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        agentDef.name,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // 技能能量條
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: LinearProgressIndicator(
                                value: (energy / cost).clamp(0.0, 1.0),
                                minHeight: 6,
                                backgroundColor: AppTheme.bgSecondary,
                                valueColor: AlwaysStoppedAnimation(
                                  isReady ? attrColor : attrColor.withAlpha(120),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          if (isReady)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: attrColor,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                '施放！',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          else
                            Text(
                              '$energy/$cost',
                              style: TextStyle(
                                color: AppTheme.textSecondary.withAlpha(150),
                                fontSize: 10,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        agentDef.skill.name,
                        style: TextStyle(
                          color: AppTheme.textSecondary.withAlpha(150),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      height: 88,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Center(
        child: Text(
          '尚未配置角色',
          style: TextStyle(
            color: AppTheme.textSecondary.withAlpha(120),
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  void _activateSkill(
    BuildContext context,
    CatAgentDefinition agentDef,
    String agentId,
    IdleProvider idleProvider,
  ) {
    HapticFeedback.mediumImpact();
    idleProvider.activateSkill(agentId);
  }

  static Widget _buildAgentImage(String agentId, CatAgentDefinition agentDef, double size) {
    final iconPath = ImageAssets.iconImage(agentId);
    if (iconPath == null) {
      return Center(
        child: GameIcon(
          assetPath: ImageAssets.attributeIcon(agentDef.attribute),
          fallbackEmoji: agentDef.attribute.emoji,
          size: size * 0.5,
        ),
      );
    }
    return Image.asset(
      iconPath,
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Center(
        child: GameIcon(
          assetPath: ImageAssets.attributeIcon(agentDef.attribute),
          fallbackEmoji: agentDef.attribute.emoji,
          size: size * 0.5,
        ),
      ),
    );
  }

  static CatAgentDefinition? _findAgent(String agentId) {
    for (final a in CatAgentData.allAgents) {
      if (a.id == agentId) return a;
    }
    return null;
  }

  static Color _attrColor(AgentAttribute attr) {
    switch (attr) {
      case AgentAttribute.attributeA: return const Color(0xFFFF6B6B);
      case AgentAttribute.attributeB: return const Color(0xFF51CF66);
      case AgentAttribute.attributeC: return const Color(0xFF4DABF7);
      case AgentAttribute.attributeD: return const Color(0xFFFFD43B);
      case AgentAttribute.attributeE: return const Color(0xFFCC5DE8);
    }
  }
}
