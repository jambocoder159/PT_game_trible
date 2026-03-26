/// 首頁放置模式技能列
/// 顯示隊伍角色技能按鈕，能量滿時可施放棋盤效果
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../config/cat_agent_data.dart';
import '../../../config/image_assets.dart';
import '../../../config/theme.dart';
import '../../../core/models/cat_agent.dart';
import '../providers/idle_provider.dart';

class IdleSkillBar extends StatelessWidget {
  const IdleSkillBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<IdleProvider>(
      builder: (context, idle, _) {
        final team = idle.teamIds;
        if (team.isEmpty) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.bgSecondary.withAlpha(150),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: team.map((agentId) {
              CatAgentDefinition? def;
              for (final a in CatAgentData.allAgents) {
                if (a.id == agentId) { def = a; break; }
              }
              if (def == null) return const SizedBox.shrink();
              return _SkillButton(agentId: agentId, def: def, idle: idle);
            }).toList(),
          ),
        );
      },
    );
  }
}

class _SkillButton extends StatelessWidget {
  final String agentId;
  final CatAgentDefinition def;
  final IdleProvider idle;

  const _SkillButton({
    required this.agentId,
    required this.def,
    required this.idle,
  });

  @override
  Widget build(BuildContext context) {
    final energy = idle.getEnergy(agentId);
    final cost = def.skill.energyCost;
    final progress = (energy / cost).clamp(0.0, 1.0);
    final isReady = idle.isSkillReady(agentId);
    final attrColor = _attrColor(def.attribute);

    return GestureDetector(
      onTap: isReady
          ? () {
              HapticFeedback.mediumImpact();
              idle.activateSkill(agentId);
            }
          : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 角色圖示 + 能量環
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 38,
                  height: 38,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 3,
                    backgroundColor: Colors.white.withAlpha(20),
                    valueColor: AlwaysStoppedAnimation(
                      isReady ? attrColor : attrColor.withAlpha(120),
                    ),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: isReady
                        ? attrColor.withAlpha(50)
                        : AppTheme.bgCard.withAlpha(180),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isReady ? attrColor : Colors.white.withAlpha(30),
                      width: isReady ? 2 : 1,
                    ),
                    boxShadow: isReady
                        ? [
                            BoxShadow(
                              color: attrColor.withAlpha(60),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: GameIcon(
                      assetPath: ImageAssets.attributeIcon(def.attribute),
                      fallbackEmoji: def.attribute.emoji,
                      size: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            // 角色名稱
            Text(
              def.name,
              style: TextStyle(
                color: isReady ? AppTheme.textPrimary : AppTheme.textSecondary,
                fontSize: 8,
                fontWeight: isReady ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            // Ready 提示
            if (isReady)
              Text(
                '可施放',
                style: TextStyle(
                  color: attrColor,
                  fontSize: 7,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _attrColor(AgentAttribute attr) {
    switch (attr) {
      case AgentAttribute.attributeA:
        return const Color(0xFFFF6B6B);
      case AgentAttribute.attributeB:
        return const Color(0xFF51CF66);
      case AgentAttribute.attributeC:
        return const Color(0xFF4DABF7);
      case AgentAttribute.attributeD:
        return const Color(0xFFFFD43B);
      case AgentAttribute.attributeE:
        return const Color(0xFFCC5DE8);
    }
  }
}
