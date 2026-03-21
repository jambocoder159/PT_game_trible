/// 應用程式版本資訊
/// 每次發版或重要 commit 時更新
class AppVersion {
  AppVersion._();

  static const String version = '0.5.0';
  static const String buildName = 'Sprint 5';

  /// Git commit hash — 手動更新或由 CI 注入
  /// 若為空字串，顯示 version 即可
  static const String commitHash = '';

  static String get displayVersion {
    if (commitHash.isNotEmpty) {
      return 'v$version ($commitHash)';
    }
    return 'v$version';
  }
}
