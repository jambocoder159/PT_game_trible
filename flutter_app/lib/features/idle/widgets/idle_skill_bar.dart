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
          clipBehavior: Clip.none,
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

class _SkillButton extends StatefulWidget {
  final String agentId;
  final CatAgentDefinition def;
  final IdleProvider idle;

  const _SkillButton({
    required this.agentId,
    required this.def,
    required this.idle,
  });

  @override
  State<_SkillButton> createState() => _SkillButtonState();
}

class _SkillButtonState extends State<_SkillButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _vfxController;
  late Animation<double> _vfxScale;
  late Animation<double> _vfxOpacity;
  bool _showVfx = false;

  @override
  void initState() {
    super.initState();
    _vfxController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _vfxScale = Tween<double>(begin: 0.3, end: 1.8).animate(
      CurvedAnimation(parent: _vfxController, curve: Curves.easeOut),
    );
    _vfxOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _vfxController, curve: Curves.easeIn),
    );
    _vfxController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _showVfx = false);
        _vfxController.reset();
      }
    });
  }

  @override
  void dispose() {
    _vfxController.dispose();
    super.dispose();
  }

  void _onActivate() {
    HapticFeedback.mediumImpact();
    setState(() => _showVfx = true);
    _vfxController.forward();
    widget.idle.activateSkill(widget.agentId);
  }

  @override
  Widget build(BuildContext context) {
    final energy = widget.idle.getEnergy(widget.agentId);
    final cost = widget.def.skill.energyCost;
    final progress = (energy / cost).clamp(0.0, 1.0);
    final isReady = widget.idle.isSkillReady(widget.agentId);
    final attrColor = _attrColor(widget.def.attribute);

    return GestureDetector(
      onTap: isReady ? _onActivate : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 角色圖示 + 能量環 + VFX
            Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                SizedBox(
                  width: 38,
                  height: 38,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 3,
                    backgroundColor: AppTheme.bgSecondary,
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
                      color: isReady ? attrColor : AppTheme.accentSecondary.withAlpha(40),
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
                      assetPath: ImageAssets.attributeIcon(widget.def.attribute),
                      fallbackEmoji: widget.def.attribute.emoji,
                      size: 14,
                    ),
                  ),
                ),
                // VFX 特效層
                if (_showVfx)
                  AnimatedBuilder(
                    animation: _vfxController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _vfxScale.value,
                        child: Opacity(
                          opacity: _vfxOpacity.value,
                          child: SizedBox(
                            width: 48,
                            height: 48,
                            child: Image.asset(
                              ImageAssets.skillVfx(widget.def.attribute),
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => Icon(
                                Icons.auto_awesome,
                                color: attrColor,
                                size: 28,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
            const SizedBox(height: 2),
            // 角色名稱
            Text(
              widget.def.name,
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
