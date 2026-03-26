/// 屬性圖標浮動徽章
/// 顯示在角色卡片左上角的屬性標記
import 'package:flutter/material.dart';
import '../../config/image_assets.dart';
import '../../config/theme.dart';
import '../models/cat_agent.dart';

class AttributeBadge extends StatelessWidget {
  final AgentAttribute attribute;
  final double size;

  const AttributeBadge({
    super.key,
    required this.attribute,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: attribute.blockColor.color.withAlpha(200),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withAlpha(120),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(100),
            blurRadius: 4,
          ),
        ],
      ),
      child: Center(
        child: GameIcon(
          assetPath: ImageAssets.attributeIcon(attribute),
          fallbackEmoji: attribute.emoji,
          size: size * 0.6,
        ),
      ),
    );
  }
}
