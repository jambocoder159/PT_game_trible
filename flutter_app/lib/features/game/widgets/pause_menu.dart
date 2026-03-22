import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../core/services/audio_service.dart';
import '../../../core/services/settings_service.dart';
import 'controls_help.dart';

/// 暫停選單 Overlay
class PauseMenu extends StatefulWidget {
  final VoidCallback onResume;
  final VoidCallback onExitToMenu;

  const PauseMenu({
    super.key,
    required this.onResume,
    required this.onExitToMenu,
  });

  @override
  State<PauseMenu> createState() => _PauseMenuState();
}

class _PauseMenuState extends State<PauseMenu> {
  late final SettingsService _settings;

  @override
  void initState() {
    super.initState();
    _settings = SettingsService.instance;
    _settings.addListener(_onSettingsChanged);
  }

  @override
  void dispose() {
    _settings.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() {
    setState(() {});
    AudioService.instance.applyVolumeSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withAlpha(180),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 340),
          decoration: BoxDecoration(
            color: AppTheme.bgSecondary,
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            border: Border.all(
              color: AppTheme.accentPrimary.withAlpha(150),
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 標題
                const Text(
                  '暫停',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),

                // 繼續遊戲
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: widget.onResume,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('繼續遊戲'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 音量設定區
                const SettingsPanel(),
                const SizedBox(height: 20),

                // 操作說明
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => ControlsHelpDialog.show(context),
                    icon: const Icon(Icons.help_outline),
                    label: const Text('操作說明'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textPrimary,
                      side: BorderSide(color: Colors.white.withAlpha(60)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // 返回主選單
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _confirmExit(context),
                    icon: const Icon(Icons.exit_to_app),
                    label: const Text('返回主選單'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.accentSecondary,
                      side: BorderSide(
                          color: AppTheme.accentSecondary.withAlpha(120)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmExit(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgSecondary,
        title: const Text('確認離開'),
        content: const Text('離開後此局進度將不會保存，確定要返回主選單嗎？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              widget.onExitToMenu();
            },
            child: Text(
              '確定離開',
              style: TextStyle(color: AppTheme.accentSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

/// 共用設定面板（音量 + 震動），可用於暫停選單和主選單
class SettingsPanel extends StatefulWidget {
  const SettingsPanel({super.key});

  @override
  State<SettingsPanel> createState() => _SettingsPanelState();
}

class _SettingsPanelState extends State<SettingsPanel> {
  late final SettingsService _settings;

  @override
  void initState() {
    super.initState();
    _settings = SettingsService.instance;
    _settings.addListener(_refresh);
  }

  @override
  void dispose() {
    _settings.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 靜音開關
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '音效設定',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            IconButton(
              onPressed: () {
                _settings.toggleMute();
                AudioService.instance.applyVolumeSettings();
              },
              icon: Icon(
                _settings.isMuted ? Icons.volume_off : Icons.volume_up,
                color: _settings.isMuted
                    ? AppTheme.textSecondary
                    : AppTheme.textPrimary,
              ),
            ),
          ],
        ),

        // BGM 音量
        _VolumeRow(
          label: 'BGM',
          value: _settings.bgmVolume,
          muted: _settings.isMuted,
          onChanged: (v) {
            _settings.setBgmVolume(v);
            AudioService.instance.applyVolumeSettings();
          },
        ),
        const SizedBox(height: 8),

        // SFX 音量
        _VolumeRow(
          label: 'SFX',
          value: _settings.sfxVolume,
          muted: _settings.isMuted,
          onChanged: (v) => _settings.setSfxVolume(v),
        ),
        const SizedBox(height: 12),

        // 震動開關
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '震動回饋',
              style: TextStyle(fontSize: 14, color: AppTheme.textPrimary),
            ),
            Switch(
              value: _settings.hapticEnabled,
              onChanged: (v) => _settings.setHapticEnabled(v),
              activeColor: AppTheme.accentPrimary,
            ),
          ],
        ),
      ],
    );
  }
}

class _VolumeRow extends StatelessWidget {
  final String label;
  final double value;
  final bool muted;
  final ValueChanged<double> onChanged;

  const _VolumeRow({
    required this.label,
    required this.value,
    required this.muted,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 36,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: muted ? AppTheme.textSecondary : AppTheme.textPrimary,
            ),
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              activeTrackColor:
                  muted ? AppTheme.textSecondary : AppTheme.accentPrimary,
              inactiveTrackColor: Colors.white.withAlpha(30),
              thumbColor:
                  muted ? AppTheme.textSecondary : AppTheme.accentPrimary,
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
            ),
            child: Slider(
              value: value,
              onChanged: muted ? null : onChanged,
            ),
          ),
        ),
        SizedBox(
          width: 32,
          child: Text(
            '${(value * 100).round()}',
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 12,
              color: muted ? AppTheme.textSecondary : AppTheme.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
