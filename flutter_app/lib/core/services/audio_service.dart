import 'package:audioplayers/audioplayers.dart';
import 'settings_service.dart';

/// 音效服務（BGM + SFX）
/// 音效檔案尚未就緒時自動 no-op
class AudioService {
  static AudioService? _instance;
  static AudioService get instance {
    _instance ??= AudioService._();
    return _instance!;
  }

  AudioService._();

  final AudioPlayer _bgmPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer();

  bool _bgmPlaying = false;

  /// 播放背景音樂（循環）
  Future<void> playBGM(String assetPath) async {
    try {
      await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
      await _bgmPlayer.setVolume(SettingsService.instance.effectiveBgmVolume);
      await _bgmPlayer.play(AssetSource(assetPath));
      _bgmPlaying = true;
    } catch (_) {
      // 音檔不存在時靜默失敗
    }
  }

  /// 停止背景音樂
  Future<void> stopBGM() async {
    try {
      await _bgmPlayer.stop();
      _bgmPlaying = false;
    } catch (_) {}
  }

  /// 暫停背景音樂
  Future<void> pauseBGM() async {
    if (!_bgmPlaying) return;
    try {
      await _bgmPlayer.pause();
    } catch (_) {}
  }

  /// 恢復背景音樂
  Future<void> resumeBGM() async {
    if (!_bgmPlaying) return;
    try {
      await _bgmPlayer.resume();
    } catch (_) {}
  }

  /// 播放音效（一次性）
  Future<void> playSFX(String assetPath) async {
    final volume = SettingsService.instance.effectiveSfxVolume;
    if (volume <= 0) return;
    try {
      await _sfxPlayer.setVolume(volume);
      await _sfxPlayer.play(AssetSource(assetPath));
    } catch (_) {
      // 音檔不存在時靜默失敗
    }
  }

  /// 更新音量（設定變更時呼叫）
  Future<void> applyVolumeSettings() async {
    try {
      await _bgmPlayer.setVolume(SettingsService.instance.effectiveBgmVolume);
    } catch (_) {}
  }

  void dispose() {
    _bgmPlayer.dispose();
    _sfxPlayer.dispose();
  }
}
