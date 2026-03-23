import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 全域設定服務（音量、震動等）
class SettingsService extends ChangeNotifier {
  static const _bgmVolumeKey = 'settings_bgm_volume';
  static const _sfxVolumeKey = 'settings_sfx_volume';
  static const _isMutedKey = 'settings_is_muted';
  static const _hapticEnabledKey = 'settings_haptic_enabled';

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

  double get bgmVolume => _bgmVolume;
  double get sfxVolume => _sfxVolume;
  bool get isMuted => _isMuted;
  bool get hapticEnabled => _hapticEnabled;

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
}
