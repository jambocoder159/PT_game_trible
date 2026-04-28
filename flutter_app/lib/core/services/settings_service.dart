import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 方塊圖片外觀主題
enum BlockVisualTheme {
  classic('classic', '經典原版', '原本方塊素材'),
  jelly('style_jelly', '果凍糖', '亮面糖果、圓潤可愛'),
  cookie('style_cookie', '烘焙餅乾', '餅乾底與糖霜圖案'),
  gem('style_gem', '魔法寶石', '切面寶石與雕刻徽記'),
  sticker('style_sticker', '紙感貼紙', '白邊貼紙與紙雕圖示'),
  enamel('style_enamel', '琺瑯徽章', '金屬邊框與徽章質感');

  const BlockVisualTheme(this.assetKey, this.label, this.description);

  final String assetKey;
  final String label;
  final String description;

  static BlockVisualTheme fromAssetKey(String? key) {
    return BlockVisualTheme.values.firstWhere(
      (theme) => theme.assetKey == key,
      orElse: () => BlockVisualTheme.classic,
    );
  }
}

/// 全域設定服務（音量、震動等）
class SettingsService extends ChangeNotifier {
  static const _bgmVolumeKey = 'settings_bgm_volume';
  static const _sfxVolumeKey = 'settings_sfx_volume';
  static const _isMutedKey = 'settings_is_muted';
  static const _hapticEnabledKey = 'settings_haptic_enabled';
  static const _blockThemeKey = 'settings_block_theme';

  static SettingsService? _instance;
  static SettingsService get instance {
    _instance ??= SettingsService._();
    return _instance!;
  }

  SettingsService._();

  SharedPreferences? _prefs;

  double _bgmVolume = 0.7;
  double _sfxVolume = 0.8;
  bool _isMuted = false;
  bool _hapticEnabled = true;
  BlockVisualTheme _blockTheme = BlockVisualTheme.classic;

  double get bgmVolume => _bgmVolume;
  double get sfxVolume => _sfxVolume;
  bool get isMuted => _isMuted;
  bool get hapticEnabled => _hapticEnabled;
  BlockVisualTheme get blockTheme => _blockTheme;

  /// 有效的 BGM 音量（考慮靜音）
  double get effectiveBgmVolume => _isMuted ? 0.0 : _bgmVolume;

  /// 有效的 SFX 音量（考慮靜音）
  double get effectiveSfxVolume => _isMuted ? 0.0 : _sfxVolume;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _bgmVolume = _prefs?.getDouble(_bgmVolumeKey) ?? 0.7;
    _sfxVolume = _prefs?.getDouble(_sfxVolumeKey) ?? 0.8;
    _isMuted = _prefs?.getBool(_isMutedKey) ?? false;
    _hapticEnabled = _prefs?.getBool(_hapticEnabledKey) ?? true;
    _blockTheme = BlockVisualTheme.fromAssetKey(
      _prefs?.getString(_blockThemeKey),
    );
  }

  void setBgmVolume(double value) {
    _bgmVolume = value.clamp(0.0, 1.0);
    _prefs?.setDouble(_bgmVolumeKey, _bgmVolume);
    notifyListeners();
  }

  void setSfxVolume(double value) {
    _sfxVolume = value.clamp(0.0, 1.0);
    _prefs?.setDouble(_sfxVolumeKey, _sfxVolume);
    notifyListeners();
  }

  void toggleMute() {
    _isMuted = !_isMuted;
    _prefs?.setBool(_isMutedKey, _isMuted);
    notifyListeners();
  }

  void setHapticEnabled(bool value) {
    _hapticEnabled = value;
    _prefs?.setBool(_hapticEnabledKey, _hapticEnabled);
    notifyListeners();
  }

  void setBlockTheme(BlockVisualTheme theme) {
    if (_blockTheme == theme) return;
    _blockTheme = theme;
    _prefs?.setString(_blockThemeKey, theme.assetKey);
    notifyListeners();
  }
}
