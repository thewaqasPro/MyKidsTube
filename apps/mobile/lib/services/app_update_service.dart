import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../models/app_update_info.dart';

/// Service responsible for querying remote release manifests and GitHub
/// releases to notify users of available app updates.
class AppUpdateService {
  static const String defaultManifestUrl =
      'https://raw.githubusercontent.com/thewaqasPro/MyKidsTube/main/version.json';
  static const String defaultGitHubReleasesUrl =
      'https://api.github.com/repos/thewaqasPro/MyKidsTube/releases/latest';

  final Dio _dio;
  final String manifestUrl;
  final String gitHubReleasesUrl;

  AppUpdateService({
    Dio? dio,
    this.manifestUrl = defaultManifestUrl,
    this.gitHubReleasesUrl = defaultGitHubReleasesUrl,
  }) : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 6),
                receiveTimeout: const Duration(seconds: 6),
                headers: {
                  'Accept': 'application/json',
                },
              ),
            );

  /// Compares two semver strings (e.g., '1.3.0', 'v1.4.0', '1.3.0+3').
  /// Returns:
  ///   < 0 if [v1] is older than [v2]
  ///   = 0 if [v1] is equal to [v2]
  ///   > 0 if [v1] is newer than [v2]
  static int compareSemver(String v1, String v2) {
    List<int> parseParts(String v) {
      var cleaned = v.trim();
      if (cleaned.startsWith('v') || cleaned.startsWith('V')) {
        cleaned = cleaned.substring(1);
      }
      // Remove build metadata e.g. +4 or prerelease -beta
      final plusIndex = cleaned.indexOf('+');
      if (plusIndex != -1) cleaned = cleaned.substring(0, plusIndex);
      final dashIndex = cleaned.indexOf('-');
      if (dashIndex != -1) cleaned = cleaned.substring(0, dashIndex);

      final segments = cleaned.split('.');
      final parts = <int>[];
      for (final s in segments) {
        parts.add(int.tryParse(s.trim()) ?? 0);
      }
      while (parts.length < 3) {
        parts.add(0);
      }
      return parts;
    }

    final p1 = parseParts(v1);
    final p2 = parseParts(v2);

    final maxLen = p1.length > p2.length ? p1.length : p2.length;
    for (var i = 0; i < maxLen; i++) {
      final num1 = i < p1.length ? p1[i] : 0;
      final num2 = i < p2.length ? p2[i] : 0;
      if (num1 != num2) {
        return num1.compareTo(num2);
      }
    }
    return 0;
  }

  /// Parses a version.json manifest payload into an [AppUpdateInfo].
  static AppUpdateInfo parseManifestJson(
    Map<String, dynamic> json, {
    required String currentVersion,
  }) {
    final latestVersion = (json['version'] as String? ?? '').trim();
    final latestVersionCode = json['versionCode'] as int?;
    final releaseTitle = json['releaseTitle'] as String? ?? 'New Release Available';
    final releaseNotes = json['releaseNotes'] as String? ?? '';
    final apkDownloadUrl = json['apkDownloadUrl'] as String? ?? '';
    final downloadPageUrl = json['downloadPageUrl'] as String? ?? '';

    final hasUpdate = compareSemver(currentVersion, latestVersion) < 0;

    return AppUpdateInfo(
      hasUpdate: hasUpdate,
      currentVersion: currentVersion,
      latestVersion: latestVersion.isNotEmpty ? latestVersion : currentVersion,
      latestVersionCode: latestVersionCode,
      releaseTitle: releaseTitle,
      releaseNotes: releaseNotes,
      apkDownloadUrl: apkDownloadUrl,
      downloadPageUrl: downloadPageUrl,
    );
  }

  /// Parses GitHub Releases REST API response into an [AppUpdateInfo].
  static AppUpdateInfo parseGitHubReleaseJson(
    Map<String, dynamic> json, {
    required String currentVersion,
  }) {
    var tagName = (json['tag_name'] as String? ?? '').trim();
    if (tagName.startsWith('v') || tagName.startsWith('V')) {
      tagName = tagName.substring(1);
    }
    final latestVersion = tagName;
    final releaseTitle = json['name'] as String? ?? 'Release v$latestVersion';
    final releaseNotes = json['body'] as String? ?? '';
    final downloadPageUrl = json['html_url'] as String? ?? '';

    // Search for apk file in release assets
    var apkDownloadUrl = '';
    final assets = json['assets'] as List<dynamic>? ?? [];
    String? arm64Url;
    String? universalUrl;
    String? anyApkUrl;

    for (final a in assets) {
      if (a is Map<String, dynamic>) {
        final name = (a['name'] as String? ?? '').toLowerCase();
        final url = a['browser_download_url'] as String? ?? '';
        if (name.endsWith('.apk')) {
          if (name.contains('arm64')) {
            arm64Url = url;
          } else if (name.contains('universal')) {
            universalUrl = url;
          }
          anyApkUrl ??= url;
        }
      }
    }

    apkDownloadUrl = arm64Url ?? universalUrl ?? anyApkUrl ?? downloadPageUrl;

    final hasUpdate = compareSemver(currentVersion, latestVersion) < 0;

    return AppUpdateInfo(
      hasUpdate: hasUpdate,
      currentVersion: currentVersion,
      latestVersion: latestVersion.isNotEmpty ? latestVersion : currentVersion,
      releaseTitle: releaseTitle,
      releaseNotes: releaseNotes,
      apkDownloadUrl: apkDownloadUrl,
      downloadPageUrl: downloadPageUrl,
    );
  }

  /// Checks for available updates by checking version.json first, then fallback
  /// to the GitHub Releases API.
  Future<AppUpdateInfo> checkForUpdate({String? currentVersionOverride}) async {
    String currentVersion = currentVersionOverride ?? '';
    if (currentVersion.isEmpty) {
      try {
        final packageInfo = await PackageInfo.fromPlatform();
        currentVersion = packageInfo.version;
      } catch (_) {
        currentVersion = '1.3.0';
      }
    }

    // 1. Try raw manifest on GitHub repository
    try {
      final response = await _dio.get<dynamic>(manifestUrl);
      if (response.statusCode == 200 && response.data != null) {
        dynamic data = response.data;
        if (data is String) {
          data = jsonDecode(data);
        }
        if (data is Map<String, dynamic>) {
          return parseManifestJson(data, currentVersion: currentVersion);
        }
      }
    } catch (_) {
      // Manifest check failed (offline or raw URL unavailable), fallback to GitHub API
    }

    // 2. Fallback to GitHub Releases API
    try {
      final response = await _dio.get<dynamic>(gitHubReleasesUrl);
      if (response.statusCode == 200 && response.data != null) {
        dynamic data = response.data;
        if (data is String) {
          data = jsonDecode(data);
        }
        if (data is Map<String, dynamic>) {
          return parseGitHubReleaseJson(data, currentVersion: currentVersion);
        }
      }
    } catch (e) {
      return AppUpdateInfo.error(
        currentVersion: currentVersion,
        message: 'Could not connect to update server. Please check your internet connection.',
      );
    }

    return AppUpdateInfo.upToDate(currentVersion: currentVersion);
  }
}
