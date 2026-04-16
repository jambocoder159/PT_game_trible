import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../core/widgets/paper_dialog.dart';

/// 操作說明 Dialog — 紙質風
class ControlsHelpDialog {
  ControlsHelpDialog._();

  static Future<void> show(BuildContext context) {
    return PaperInfoDialog.show(
      context: context,
      title: '操作說明',
      closeText: '了解',
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _HelpItem(
            icon: Icons.touch_app,
            title: '點擊方塊',
            description: '直接消除該方塊，觸發重力掉落與連鎖消除',
          ),
          _HelpDivider(),
          _HelpItem(
            icon: Icons.arrow_upward,
            title: '長按 + 上滑',
            description: '將方塊移到同列最頂部',
          ),
          _HelpDivider(),
          _HelpItem(
            icon: Icons.arrow_downward,
            title: '長按 + 下滑',
            description: '將方塊移到同列最底部',
          ),
          _HelpDivider(),
          _HelpItem(
            icon: Icons.auto_awesome,
            title: '連鎖 Combo',
            description: '消除後若產生三個以上同色相鄰，會自動連鎖消除並加分',
          ),
        ],
      ),
    );
  }
}

class _HelpDivider extends StatelessWidget {
  const _HelpDivider();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Container(
        height: 1,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFFB18A4A).withAlpha(0),
              const Color(0xFFB18A4A).withAlpha(120),
              const Color(0xFFB18A4A).withAlpha(0),
            ],
          ),
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
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFE8A547),
                Color(0xFFC07A2A),
              ],
            ),
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8B4F1A).withAlpha(120),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: AppTheme.fontTitleMd,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF3D2817),
                  shadows: [
                    Shadow(
                      color: Colors.white.withAlpha(160),
                      offset: const Offset(0, -0.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: const TextStyle(
                  fontSize: AppTheme.fontBodyLg,
                  color: Color(0xFF6B4226),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
