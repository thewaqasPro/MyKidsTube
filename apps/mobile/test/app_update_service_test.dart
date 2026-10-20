import 'package:flutter_test/flutter_test.dart';
import 'package:safe_tube/services/app_update_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppUpdateService Semver Comparison Tests', () {
    test('Identifies latest version is greater', () {
      expect(AppUpdateService.compareSemver('1.3.0', '1.4.0'), lessThan(0));
      expect(AppUpdateService.compareSemver('1.3.0', '1.3.1'), lessThan(0));
      expect(AppUpdateService.compareSemver('1.3.9', '2.0.0'), lessThan(0));
      expect(AppUpdateService.compareSemver('0.9.5', '1.0.0'), lessThan(0));
    });

    test('Identifies versions are equal', () {
      expect(AppUpdateService.compareSemver('1.3.0', '1.3.0'), equals(0));
      expect(AppUpdateService.compareSemver('v1.3.0', '1.3.0'), equals(0));
      expect(AppUpdateService.compareSemver('1.3.0+3', '1.3.0'), equals(0));
      expect(AppUpdateService.compareSemver('v1.4.0+4', 'v1.4.0'), equals(0));
    });

    test('Identifies installed version is newer than remote', () {
      expect(AppUpdateService.compareSemver('1.4.0', '1.3.0'), greaterThan(0));
      expect(AppUpdateService.compareSemver('2.0.0', '1.9.9'), greaterThan(0));
      expect(AppUpdateService.compareSemver('v1.3.2', 'v1.3.1'), greaterThan(0));
    });

    test('Handles malformed or partial version strings gracefully', () {
      expect(AppUpdateService.compareSemver('1.3', '1.3.0'), equals(0));
      expect(AppUpdateService.compareSemver('1', '1.0.0'), equals(0));
      expect(AppUpdateService.compareSemver('1.4', '1.3.9'), greaterThan(0));
    });
  });

  group('AppUpdateService Manifest & Release Parsing Tests', () {
    test('parseManifestJson correctly populates AppUpdateInfo', () {
      final json = {
        'version': '1.4.0',
        'versionCode': 4,
        'releaseTitle': 'MyKidsTube v1.4.0 — Update Release',
        'releaseNotes': 'Features added',
        'apkDownloadUrl': 'https://github.com/thewaqasPro/MyKidsTube/releases/download/v1.4.0/app-release.apk',
        'downloadPageUrl': 'https://github.com/thewaqasPro/MyKidsTube/releases/latest',
      };

      final info = AppUpdateService.parseManifestJson(json, currentVersion: '1.3.0');

      expect(info.hasUpdate, isTrue);
      expect(info.currentVersion, equals('1.3.0'));
      expect(info.latestVersion, equals('1.4.0'));
      expect(info.latestVersionCode, equals(4));
      expect(info.releaseTitle, equals('MyKidsTube v1.4.0 — Update Release'));
      expect(info.apkDownloadUrl, contains('.apk'));
    });

    test('parseManifestJson reports hasUpdate false when on same or newer version', () {
      final json = {
        'version': '1.3.0',
        'versionCode': 3,
        'releaseTitle': 'Old Release',
        'releaseNotes': 'None',
        'apkDownloadUrl': 'https://github.com/...',
        'downloadPageUrl': 'https://github.com/...',
      };

      final info = AppUpdateService.parseManifestJson(json, currentVersion: '1.3.0');
      expect(info.hasUpdate, isFalse);
    });

    test('parseGitHubReleaseJson extracts tag and selects arm64 apk', () {
      final gitHubRelease = {
        'tag_name': 'v1.4.0',
        'name': 'MyKidsTube Release v1.4.0',
        'body': 'Intro skip controls added',
        'html_url': 'https://github.com/thewaqasPro/MyKidsTube/releases/tag/v1.4.0',
        'assets': [
          {
            'name': 'app-armeabi-v7a-release.apk',
            'browser_download_url': 'https://github.com/.../app-armeabi-v7a-release.apk'
          },
          {
            'name': 'app-arm64-v8a-release.apk',
            'browser_download_url': 'https://github.com/.../app-arm64-v8a-release.apk'
          },
          {
            'name': 'source_code.zip',
            'browser_download_url': 'https://github.com/.../source_code.zip'
          }
        ]
      };

      final info = AppUpdateService.parseGitHubReleaseJson(gitHubRelease, currentVersion: '1.3.0');

      expect(info.hasUpdate, isTrue);
      expect(info.latestVersion, equals('1.4.0'));
      expect(info.releaseTitle, equals('MyKidsTube Release v1.4.0'));
      expect(info.apkDownloadUrl, equals('https://github.com/.../app-arm64-v8a-release.apk'));
    });
  });
}
