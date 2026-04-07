import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../core/models/block.dart';
import '../../../core/models/bottle_data.dart';
import '../providers/bottle_provider.dart';

/// 5 個魔法瓶橫排顯示
class BottleRow extends StatelessWidget {
  final Map<BlockColor, GlobalKey> bottleKeys;
  final void Function(BlockColor color)? onBottleTap;

  const BottleRow({
    super.key,
    required this.bottleKeys,
    this.onBottleTap,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<BottleProvider>(
      builder: (context, bottleProvider, _) {
        if (!bottleProvider.isInitialized) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: BottleDefinitions.all.map((def) {
              final bottle = bottleProvider.getBottle(def.color);
              bottleKeys.putIfAbsent(def.color, () => GlobalKey());
              return _BottleWidget(
                key: bottleKeys[def.color],
                definition: def,
                status: bottle,
                onTap: () {
                  HapticFeedback.lightImpact();
                  onBottleTap?.call(def.color);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

class _BottleWidget extends StatelessWidget {
  final BottleDefinition definition;
  final BottleStatus status;
  final VoidCallback onTap;

  const _BottleWidget({
    super.key,
    required this.definition,
    required this.status,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final blockColor = definition.color.color;
    final fillProgress = status.fillProgress;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 瓶子圖示 + 填充動畫
          Stack(
            alignment: Alignment.center,
            children: [
              // 瓶子背景
              Container(
                width: 44,
                height: 52,
                decoration: BoxDecoration(
                  color: AppTheme.bgCard,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: blockColor.withAlpha(status.isFull ? 200 : 80),
                    width: status.isFull ? 1.5 : 1.0,
                  ),
                  boxShadow: status.isFull
                      ? [BoxShadow(color: blockColor.withAlpha(40), blurRadius: 6)]
                      : null,
                ),
                child: Column(
                  children: [
                    // 瓶頂（空白區域）
                    Expanded(
                      flex: ((1 - fillProgress) * 100).round().clamp(1, 100),
                      child: const SizedBox.shrink(),
                    ),
                    // 填充區域
                    Expanded(
                      flex: (fillProgress * 100).round().clamp(1, 100),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: blockColor.withAlpha(status.isFull ? 150 : 80),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(7),
                            bottomRight: Radius.circular(7),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // 瓶子 emoji
              Text(definition.emoji, style: const TextStyle(fontSize: AppTheme.fontTitleLg)),
              // 等級徽章
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                  decoration: BoxDecoration(
                    color: blockColor.withAlpha(200),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${status.level}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: AppTheme.fontLabelSm,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          // 能量數字
          Text(
            '${status.currentEnergy}',
            style: TextStyle(
              color: AppTheme.textSecondary.withAlpha(150),
              fontSize: AppTheme.fontLabelSm,
            ),
          ),
        ],
      ),
    );
  }
}
