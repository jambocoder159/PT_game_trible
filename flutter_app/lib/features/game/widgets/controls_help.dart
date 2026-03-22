import 'package:flutter/material.dart';
import '../../../config/theme.dart';

/// 操作說明 Dialog
class ControlsHelpDialog extends StatelessWidget {
  const ControlsHelpDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (_) => const ControlsHelpDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.bgSecondary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        side: BorderSide(color: AppTheme.accentPrimary.withAlpha(150)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '操作說明',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _HelpItem(
              icon: Icons.touch_app,
              title: '點擊方塊',
              description: '直接消除該方塊，觸發重力掉落與連鎖消除',
            ),
            const Divider(color: AppTheme.textSecondary, height: 24),
            _HelpItem(
              icon: Icons.arrow_upward,
              title: '長按 + 上滑',
              description: '將方塊移到同列最頂部',
            ),
            const Divider(color: AppTheme.textSecondary, height: 24),
            _HelpItem(
              icon: Icons.arrow_downward,
              title: '長按 + 下滑',
              description: '將方塊移到同列最底部',
            ),
            const Divider(color: AppTheme.textSecondary, height: 24),
            _HelpItem(
              icon: Icons.auto_awesome,
              title: '連鎖 Combo',
              description: '消除後若產生三個以上同色相鄰，會自動連鎖消除並加分',
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('了解'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HelpItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _HelpItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.accentPrimary.withAlpha(80),
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          ),
          child: Icon(icon, color: AppTheme.textPrimary, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
