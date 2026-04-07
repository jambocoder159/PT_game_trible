import 'package:flutter/material.dart';
import '../../../config/theme.dart';

/// 教學小任務面板（Phase 1 Step 1.7 使用）
class TutorialTaskPanel extends StatelessWidget {
  final String title;
  final int current;
  final int target;
  final String? reward;

  const TutorialTaskPanel({
    super.key,
    required this.title,
    required this.current,
    required this.target,
    this.reward,
  });

  @override
  Widget build(BuildContext context) {
    final isComplete = current >= target;

    return Container(
      margin: const EdgeInsets.only(right: 12, top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary.withAlpha(230),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isComplete
              ? AppTheme.stageCleared.withAlpha(150)
              : AppTheme.accentPrimary.withAlpha(100),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isComplete ? Icons.check_circle : Icons.assignment,
                size: 16,
                color:
                    isComplete ? AppTheme.stageCleared : AppTheme.accentPrimary,
              ),
              const SizedBox(width: 6),
              Text(
                '📋 新手任務',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: AppTheme.fontLabelLg,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: AppTheme.fontBodyLg,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          // 進度條
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: target > 0 ? (current / target).clamp(0.0, 1.0) : 0,
              backgroundColor: AppTheme.textSecondary.withAlpha(30),
              valueColor: AlwaysStoppedAnimation<Color>(
                isComplete ? AppTheme.stageCleared : AppTheme.accentPrimary,
              ),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '進度：$current/$target',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: AppTheme.fontLabelLg,
            ),
          ),
          if (reward != null) ...[
            const SizedBox(height: 2),
            Text(
              '獎勵：$reward',
              style: TextStyle(
                color: AppTheme.accentPrimary,
                fontSize: AppTheme.fontLabelLg,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
