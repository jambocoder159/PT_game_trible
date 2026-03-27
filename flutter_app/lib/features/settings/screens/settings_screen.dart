/// 設定頁面 — 全新獨立 Screen
/// 音效/遊戲/關於 三大分區，整合 SettingsService
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../config/app_version.dart';
import '../../../config/theme.dart';
import '../../../core/services/local_storage.dart';
import '../../../core/services/settings_service.dart';
import '../../gm/screens/gm_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _settings = SettingsService.instance;
  bool _boardOnLeft = true;
  int _versionTapCount = 0;

  @override
  void initState() {
    super.initState();
    _loadBoardPosition();
  }

  Future<void> _loadBoardPosition() async {
    final storage = LocalStorageService.instance;
    final val = storage.getJson('board_on_left');
    if (val is bool) {
      setState(() => _boardOnLeft = val);
    }
  }

  Future<void> _toggleBoardPosition() async {
    setState(() => _boardOnLeft = !_boardOnLeft);
    final storage = LocalStorageService.instance;
    await storage.setJson('board_on_left', _boardOnLeft);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(
        title: const Text('設定'),
        backgroundColor: AppTheme.bgSecondary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListenableBuilder(
        listenable: _settings,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ═══ 音效設定 ═══
              _SectionHeader(icon: Icons.volume_up_rounded, title: '音效設定'),
              const SizedBox(height: 8),
              _SettingsCard(
                children: [
                  // 靜音
                  _ToggleRow(
                    icon: _settings.isMuted
                        ? Icons.volume_off_rounded
                        : Icons.volume_up_rounded,
                    label: '靜音模式',
                    value: _settings.isMuted,
                    onChanged: (_) => _settings.toggleMute(),
                  ),
                  Divider(color: AppTheme.accentSecondary.withAlpha(20), height: 1),
                  // BGM 音量
                  _SliderRow(
                    icon: Icons.music_note_rounded,
                    label: 'BGM 音量',
                    value: _settings.bgmVolume,
                    enabled: !_settings.isMuted,
                    onChanged: (v) => _settings.setBgmVolume(v),
                  ),
                  Divider(color: AppTheme.accentSecondary.withAlpha(20), height: 1),
                  // SFX 音量
                  _SliderRow(
                    icon: Icons.speaker_rounded,
                    label: '音效音量',
                    value: _settings.sfxVolume,
                    enabled: !_settings.isMuted,
                    onChanged: (v) => _settings.setSfxVolume(v),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ═══ 遊戲設定 ═══
              _SectionHeader(icon: Icons.gamepad_rounded, title: '遊戲設定'),
              const SizedBox(height: 8),
              _SettingsCard(
                children: [
                  // 棋盤位置
                  _OptionRow(
                    icon: Icons.swap_horiz_rounded,
                    label: '棋盤位置',
                    value: _boardOnLeft ? '棋盤在左' : '棋盤在右',
                    onTap: () {
                      _toggleBoardPosition();
                      HapticFeedback.lightImpact();
                    },
                  ),
                  Divider(color: AppTheme.accentSecondary.withAlpha(20), height: 1),
                  // 震動回饋
                  _ToggleRow(
                    icon: Icons.vibration_rounded,
                    label: '震動回饋',
                    value: _settings.hapticEnabled,
                    onChanged: (v) => _settings.setHapticEnabled(v),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ═══ 關於 ═══
              _SectionHeader(icon: Icons.info_outline_rounded, title: '關於'),
              const SizedBox(height: 8),
              _SettingsCard(
                children: [
                  // 版本
                  _InfoRow(
                    icon: Icons.code_rounded,
                    label: '版本',
                    value: AppVersion.displayVersion,
                    onTap: () {
                      _versionTapCount++;
                      if (_versionTapCount >= 5) {
                        _versionTapCount = 0;
                        Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const GmScreen()),
                        );
                      }
                    },
                  ),
                  Divider(color: AppTheme.accentSecondary.withAlpha(20), height: 1),
                  // 遊戲資訊
                  _InfoRow(
                    icon: Icons.pets_rounded,
                    label: '遊戲',
                    value: '貓咪點心屋三消挑戰',
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // ═══ 危險區域 ═══
              _SectionHeader(
                icon: Icons.warning_amber_rounded,
                title: '危險區域',
                color: Colors.red.shade400,
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.bgCard,
                  borderRadius:
                      BorderRadius.circular(AppTheme.radiusMedium),
                  border: Border.all(
                    color: Colors.red.withAlpha(40),
                  ),
                ),
                child: ListTile(
                  leading: Icon(Icons.delete_forever_rounded,
                      color: Colors.red.shade400),
                  title: Text(
                    '重置遊戲進度',
                    style: TextStyle(
                      color: Colors.red.shade400,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    '清除所有資料，無法恢復',
                    style: TextStyle(
                      color: Colors.red.shade400.withAlpha(150),
                      fontSize: 12,
                    ),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                  onTap: () => _showResetConfirmation(context),
                ),
              ),

              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }

  void _showResetConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgSecondary,
        title: const Text(
          '確認重置',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        content: const Text(
          '這將清除你所有的遊戲進度、角色、素材等資料。此操作無法恢復！',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              // 實際重置邏輯需要在 PlayerProvider 中呼叫 gmResetAll
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('請使用 GM 工具重置（開發中）'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            child: Text(
              '確認重置',
              style: TextStyle(color: Colors.red.shade400),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════
// 共用元件
// ═══════════════════════════════════════

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color? color;

  const _SectionHeader({
    required this.icon,
    required this.title,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppTheme.textSecondary;
    return Row(
      children: [
        Icon(icon, size: 18, color: c),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: c,
            fontSize: 13,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;

  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppTheme.accentSecondary.withAlpha(20)),
      ),
      child: Column(
        children: children,
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 15,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.accentSecondary,
          ),
        ],
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final double value;
  final bool enabled;
  final ValueChanged<double> onChanged;

  const _SliderRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      child: Row(
        children: [
          Icon(icon, size: 20,
              color: enabled
                  ? AppTheme.textSecondary
                  : AppTheme.textSecondary.withAlpha(60)),
          const SizedBox(width: 12),
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: TextStyle(
                color: enabled
                    ? AppTheme.textPrimary
                    : AppTheme.textPrimary.withAlpha(80),
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                activeTrackColor: enabled
                    ? AppTheme.accentSecondary
                    : AppTheme.accentSecondary.withAlpha(40),
                inactiveTrackColor: AppTheme.bgSecondary,
                thumbColor: enabled
                    ? AppTheme.accentSecondary
                    : Colors.grey,
                overlayColor: AppTheme.accentSecondary.withAlpha(30),
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 8),
              ),
              child: Slider(
                value: value,
                onChanged: enabled ? onChanged : null,
              ),
            ),
          ),
          SizedBox(
            width: 36,
            child: Text(
              '${(value * 100).round()}',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: enabled
                    ? AppTheme.textSecondary
                    : AppTheme.textSecondary.withAlpha(60),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  const _OptionRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppTheme.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 15,
                ),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                color: AppTheme.accentSecondary.withAlpha(200),
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right,
                color: AppTheme.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppTheme.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 15,
                ),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                color: AppTheme.textSecondary.withAlpha(150),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
