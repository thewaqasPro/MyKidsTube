/// Data model representing the state of an app update check.
class AppUpdateInfo {
  final bool hasUpdate;
  final String currentVersion;
  final String latestVersion;
  final int? latestVersionCode;
  final String releaseTitle;
  final String releaseNotes;
  final String apkDownloadUrl;
  final String downloadPageUrl;
  final String? errorMessage;

  const AppUpdateInfo({
    required this.hasUpdate,
    required this.currentVersion,
    required this.latestVersion,
    this.latestVersionCode,
    this.releaseTitle = '',
    this.releaseNotes = '',
    this.apkDownloadUrl = '',
    this.downloadPageUrl = '',
    this.errorMessage,
  });

  factory AppUpdateInfo.upToDate({required String currentVersion}) {
    return AppUpdateInfo(
      hasUpdate: false,
      currentVersion: currentVersion,
      latestVersion: currentVersion,
    );
  }

  factory AppUpdateInfo.error({
    required String currentVersion,
    required String message,
  }) {
    return AppUpdateInfo(
      hasUpdate: false,
      currentVersion: currentVersion,
      latestVersion: currentVersion,
      errorMessage: message,
    );
  }

  bool get hasError => errorMessage != null && errorMessage!.isNotEmpty;
}
