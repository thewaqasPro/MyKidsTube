import 'package:flutter_test/flutter_test.dart';
import 'package:safe_tube/models/app_update_info.dart';
import 'package:safe_tube/providers/app_provider.dart';
import 'package:safe_tube/services/app_update_service.dart';

class MockAppUpdateService extends AppUpdateService {
  final AppUpdateInfo mockResult;
  int checkCount = 0;

  MockAppUpdateService(this.mockResult);

  @override
  Future<AppUpdateInfo> checkForUpdate({String? currentVersionOverride}) async {
    checkCount++;
    return mockResult;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppProvider Update Checking Tests', () {
    test('Initial state has no available update and isCheckingForUpdate is false', () {
      final provider = AppProvider();
      expect(provider.availableUpdate, isNull);
      expect(provider.isCheckingForUpdate, isFalse);
    });

    test('checkForUpdate updates state when an update is available', () async {
      final mockInfo = AppUpdateInfo(
        hasUpdate: true,
        currentVersion: '1.3.0',
        latestVersion: '1.4.0',
        latestVersionCode: 4,
        releaseTitle: 'Version 1.4.0',
        releaseNotes: 'Awesome features',
        apkDownloadUrl: 'https://example.com/app.apk',
        downloadPageUrl: 'https://example.com/release',
      );

      final mockService = MockAppUpdateService(mockInfo);
      final provider = AppProvider();
      provider.setUpdateServiceForTesting(mockService);

      bool notifiedWhileChecking = false;
      provider.addListener(() {
        if (provider.isCheckingForUpdate) {
          notifiedWhileChecking = true;
        }
      });

      final result = await provider.checkForUpdate(manual: true);

      expect(mockService.checkCount, equals(1));
      expect(notifiedWhileChecking, isTrue);
      expect(provider.isCheckingForUpdate, isFalse);
      expect(result, isNotNull);
      expect(result!.hasUpdate, isTrue);
      expect(provider.availableUpdate, equals(mockInfo));
      expect(provider.availableUpdate!.latestVersion, equals('1.4.0'));
    });

    test('checkForUpdate handles up to date state correctly', () async {
      final mockInfo = AppUpdateInfo.upToDate(currentVersion: '1.4.0');
      final mockService = MockAppUpdateService(mockInfo);
      final provider = AppProvider();
      provider.setUpdateServiceForTesting(mockService);

      final result = await provider.checkForUpdate(manual: true);

      expect(result!.hasUpdate, isFalse);
      expect(provider.availableUpdate!.hasUpdate, isFalse);
    });
  });
}
