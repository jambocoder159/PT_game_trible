/// GM 工具畫面（開發 / 測試用）
/// 長按版本號 5 次進入
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/app_version.dart';
import '../../../config/theme.dart';
import '../../agents/providers/player_provider.dart';
import '../../tutorial/screens/tutorial_screen.dart';

class GmScreen extends StatelessWidget {
  const GmScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(
        title: const Text('GM 工具'),
        backgroundColor: Colors.red.shade900,
      ),
      body: Consumer<PlayerProvider>(
        builder: (context, provider, _) {
          final data = provider.data;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 警告
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withAlpha(100)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '開發者工具 — 僅供測試用',
                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 目前狀態
              _SectionTitle('目前狀態'),
              _StatusRow('玩家等級', 'Lv.${data.playerLevel}'),
              _StatusRow('金幣', '🪙 ${data.gold}'),
              _StatusRow('鑽石', '💎 ${data.diamonds}'),
              _StatusRow('體力', '⚡ ${data.stamina}/${data.maxStamina}'),
              _StatusRow('已解鎖角色', '${data.agents.values.where((a) => a.isUnlocked).length}/5'),
              _StatusRow('已通關', '${data.stageProgress.values.where((s) => s.cleared).length} 關'),
              _StatusRow('教學', data.tutorialCompleted ? '已完成' : '未完成'),
              _StatusRow('版本', AppVersion.displayVersion),
              const SizedBox(height: 20),

              // 體力
              _SectionTitle('體力'),
              _GmButton(
                icon: Icons.battery_charging_full,
                label: '體力補滿',
                color: Colors.green,
                onTap: () {
                  provider.gmRefillStamina();
                  _showDone(context, '體力已補滿');
                },
              ),
              const SizedBox(height: 10),

              // 貨幣
              _SectionTitle('貨幣'),
              Row(
                children: [
                  Expanded(
                    child: _GmButton(
                      icon: Icons.monetization_on,
                      label: '+5,000 金幣',
                      color: Colors.orange,
                      onTap: () {
                        provider.gmAddGold(5000);
                        _showDone(context, '+5,000 金幣');
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _GmButton(
                      icon: Icons.diamond,
                      label: '+500 鑽石',
                      color: Colors.blue,
                      onTap: () {
                        provider.gmAddDiamonds(500);
                        _showDone(context, '+500 鑽石');
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // 角色
              _SectionTitle('角色'),
              _GmButton(
                icon: Icons.lock_open,
                label: '解鎖全角色',
                color: Colors.purple,
                onTap: () {
                  provider.gmUnlockAllAgents();
                  _showDone(context, '全角色已解鎖');
                },
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _GmButton(
                      icon: Icons.arrow_upward,
                      label: '全角色 Lv.10',
                      color: Colors.teal,
                      onTap: () {
                        provider.gmSetAllAgentLevel(10);
                        _showDone(context, '全角色已升到 Lv.10');
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _GmButton(
                      icon: Icons.arrow_upward,
                      label: '全角色 Lv.30',
                      color: Colors.teal,
                      onTap: () {
                        provider.gmSetAllAgentLevel(30);
                        _showDone(context, '全角色已升到 Lv.30');
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // 關卡
              _SectionTitle('關卡'),
              _GmButton(
                icon: Icons.restart_alt,
                label: '重置所有關卡進度',
                color: Colors.amber,
                onTap: () => _confirmAction(
                  context,
                  '確定重置所有關卡進度？',
                  () {
                    provider.gmResetStages();
                    _showDone(context, '關卡進度已重置');
                  },
                ),
              ),
              const SizedBox(height: 8),
              _GmButton(
                icon: Icons.school,
                label: '重新體驗教學',
                color: Colors.cyan,
                onTap: () {
                  provider.gmResetTutorial();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (_) => const TutorialScreen(),
                    ),
                    (route) => false,
                  );
                },
              ),
              const SizedBox(height: 20),

              // 危險區
              _SectionTitle('危險區域'),
              _GmButton(
                icon: Icons.delete_forever,
                label: '重置所有資料（回到新玩家）',
                color: Colors.red,
                onTap: () => _confirmAction(
                  context,
                  '確定重置所有資料？\n這將刪除所有進度、角色、貨幣！',
                  () {
                    provider.gmResetAll();
                    _showDone(context, '已重置為新玩家');
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDone(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.green),
    );
  }

  void _confirmAction(BuildContext context, String msg, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgSecondary,
        title: const Text('確認', style: TextStyle(color: AppTheme.textPrimary)),
        content: Text(msg, style: const TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm();
            },
            child: const Text('確定', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        text,
        style: const TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final String label;
  final String value;
  const _StatusRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          Text(value, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13)),
        ],
      ),
    );
  }
}

class _GmButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _GmButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontSize: 13)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withAlpha(40),
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: color.withAlpha(100)),
        ),
      ),
    );
  }
}
