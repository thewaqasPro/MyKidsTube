import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:safe_tube/models/video_item.dart';
import 'package:safe_tube/models/category_item.dart';
import 'package:safe_tube/models/child_profile.dart';
import 'package:safe_tube/providers/app_provider.dart';
import 'package:safe_tube/screens/parent_dashboard_screen.dart';
import 'package:safe_tube/screens/parent_gate_dialog.dart';
import 'package:safe_tube/services/database_service.dart';
import 'package:safe_tube/services/download_service.dart';
import 'package:safe_tube/services/vps_api_service.dart';

class InMemoryDatabaseService extends Fake implements DatabaseService {
  final Map<String, String> _settings = {};

  @override
  Future<String?> getSetting(String key) async => _settings[key];

  @override
  Future<void> setSetting(String key, String value) async {
    _settings[key] = value;
  }

  @override
  Future<bool> getAutoplayEnabled() async {
    final val = await getSetting('autoplay_enabled');
    if (val == null) return true;
    return val == 'true';
  }

  @override
  Future<void> setAutoplayEnabled(bool enabled) async {
    await setSetting('autoplay_enabled', enabled ? 'true' : 'false');
  }

  @override
  Future<int> getAutoplaySessionLimitMinutes() async {
    final val = await getSetting('autoplay_session_limit_minutes');
    if (val == null) return 60;
    return int.tryParse(val) ?? 60;
  }

  @override
  Future<void> setAutoplaySessionLimitMinutes(int minutes) async {
    await setSetting('autoplay_session_limit_minutes', minutes.toString());
  }

  @override
  Future<List<CategoryItem>> getAllCategories() async => [];

  @override
  Future<List<VideoItem>> getAllVideos({String? profileId}) async => [];

  @override
  Future<List<VideoItem>> getDownloadedVideos({String? profileId}) async => [];

  @override
  Future<Set<String>> getFavoriteIds({String? profileId}) async => {};

  @override
  Future<List<ChildProfile>> getAllLocalProfiles() async => [];

  @override
  Future<Map<String, dynamic>> getWatchAnalytics({String? profileId}) async => {'today_seconds': 0};

  @override
  Future<Map<String, Map<String, dynamic>>> getVideoWatchSummaries({String? profileId}) async => {};
}

class FakeVpsApiService extends Fake implements VpsApiService {
  @override
  Future<Map<String, dynamic>?> fetchCatalog(String baseUrl, {String? profileId}) async => null;

  @override
  Future<bool> checkHealth(String baseUrl) async => true;
}

class FakeDownloadService extends Fake implements DownloadService {
  @override
  Future<int> getTotalCachedBytes() async => 0;
}

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  group('Prompt F5 — Autoplay & Session Limit Persistence & Logic', () {
    test('Default values: autoplay_enabled is true, session limit is 60 minutes', () async {
      final db = InMemoryDatabaseService();
      expect(await db.getAutoplayEnabled(), isTrue);
      expect(await db.getAutoplaySessionLimitMinutes(), equals(60));

      final provider = AppProvider(db: db, api: FakeVpsApiService(), downloader: FakeDownloadService());
      expect(provider.autoplayEnabled, isTrue);
      expect(provider.autoplaySessionLimitMinutes, equals(60));
      expect(provider.limitFiredThisSession, isFalse);
    });

    test('Updating autoplay settings persists to DatabaseService and notifies listeners', () async {
      final db = InMemoryDatabaseService();
      final provider = AppProvider(db: db, api: FakeVpsApiService(), downloader: FakeDownloadService());

      int notifyCount = 0;
      provider.addListener(() => notifyCount++);

      // Turn autoplay off
      await provider.setAutoplayEnabled(false);
      expect(provider.autoplayEnabled, isFalse);
      expect(await db.getAutoplayEnabled(), isFalse);
      expect(notifyCount, greaterThan(0));

      // Change session limit to 30 min
      await provider.setAutoplaySessionLimitMinutes(30);
      expect(provider.autoplaySessionLimitMinutes, equals(30));
      expect(await db.getAutoplaySessionLimitMinutes(), equals(30));

      // Setting unlimited (0 min)
      await provider.setAutoplaySessionLimitMinutes(0);
      expect(provider.autoplaySessionLimitMinutes, equals(0));
      expect(await db.getAutoplaySessionLimitMinutes(), equals(0));
    });

    test('Session limit calculation: triggers only when limit reached and fires once per session', () async {
      final db = InMemoryDatabaseService();
      final provider = AppProvider(db: db, api: FakeVpsApiService(), downloader: FakeDownloadService());
      await provider.setAutoplaySessionLimitMinutes(60);

      // Session just started: elapsed is 0 minutes
      expect(provider.isAutoplaySessionLimitReached, isFalse);

      // Advance time by 45 minutes: not reached yet
      provider.setSessionStartTimeForTesting(DateTime.now().subtract(const Duration(minutes: 45)));
      expect(provider.isAutoplaySessionLimitReached, isFalse);

      // Advance time by 61 minutes: reached!
      provider.setSessionStartTimeForTesting(DateTime.now().subtract(const Duration(minutes: 61)));
      expect(provider.isAutoplaySessionLimitReached, isTrue);

      // Limit fires once per session
      provider.markAutoplaySessionLimitFired();
      expect(provider.limitFiredThisSession, isTrue);
      expect(provider.isAutoplaySessionLimitReached, isFalse); // Does not fire again!

      // Parent extends/resets session: limit resets
      provider.extendOrResetAutoplaySession();
      expect(provider.limitFiredThisSession, isFalse);
      expect(provider.isAutoplaySessionLimitReached, isFalse);
    });

    test('Unlimited session (0 min) never triggers limit', () async {
      final db = InMemoryDatabaseService();
      final provider = AppProvider(db: db, api: FakeVpsApiService(), downloader: FakeDownloadService());
      await provider.setAutoplaySessionLimitMinutes(0);

      // Even if 300 minutes passed
      provider.setSessionStartTimeForTesting(DateTime.now().subtract(const Duration(minutes: 300)));
      expect(provider.isAutoplaySessionLimitReached, isFalse);
    });

    test('Autoplay off disables limit trigger and auto-advance', () async {
      final db = InMemoryDatabaseService();
      final provider = AppProvider(db: db, api: FakeVpsApiService(), downloader: FakeDownloadService());
      await provider.setAutoplayEnabled(false);
      await provider.setAutoplaySessionLimitMinutes(15);

      // 60 minutes elapsed, but autoplay is off
      provider.setSessionStartTimeForTesting(DateTime.now().subtract(const Duration(minutes: 60)));
      expect(provider.isAutoplaySessionLimitReached, isFalse);
    });

    test('Profile switch resets session timer and fired state', () async {
      final db = InMemoryDatabaseService();
      final provider = AppProvider(db: db, api: FakeVpsApiService(), downloader: FakeDownloadService());
      provider.markAutoplaySessionLimitFired();
      expect(provider.limitFiredThisSession, isTrue);

      await provider.switchProfile(ChildProfile(id: 'kid-2', name: 'Sara', avatarIcon: 'fox'));
      expect(provider.limitFiredThisSession, isFalse);
    });
  });

  group('Prompt F5 — Parent Dashboard UI & Settings Controls', () {
    testWidgets('ParentDashboardScreen displays Autoplay Next Video and Session Watch Limit controls', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final db = InMemoryDatabaseService();
      final provider = AppProvider(db: db, api: FakeVpsApiService(), downloader: FakeDownloadService());

      await tester.pumpWidget(
        ChangeNotifierProvider<AppProvider>.value(
          value: provider,
          child: const MaterialApp(
            home: ParentDashboardScreen(isUsingDefaultPinOverride: false),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify section heading and plain labels
      expect(find.text('Autoplay & Viewing Limits'), findsOneWidget);
      expect(find.text('Autoplay Next Video'), findsOneWidget);
      expect(find.text('Session Watch Limit'), findsOneWidget);
      expect(find.text('Automatically play the next video when playback ends'), findsOneWidget);
      expect(find.text('Stop playback when session limit is reached'), findsOneWidget);

      // Toggle switch to off
      final switchFinder = find.widgetWithText(SwitchListTile, 'Autoplay Next Video');
      expect(switchFinder, findsOneWidget);
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      expect(provider.autoplayEnabled, isFalse);
      expect(await db.getAutoplayEnabled(), isFalse);
    });
  });

  group('Prompt F5 — ParentGateDialog Challenge Mode', () {
    testWidgets('ParentGateDialog.showChallenge returns true when correct math answer entered', (tester) async {
      bool? challengeResult;

      await tester.pumpWidget(
        ChangeNotifierProvider<AppProvider>.value(
          value: AppProvider(db: InMemoryDatabaseService()),
          child: MaterialApp(
            home: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  challengeResult = await ParentGateDialog.showChallenge(context);
                },
                child: const Text('Open Gate'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Gate'));
      await tester.pumpAndSettle();

      expect(find.text('Grown-Ups Only'), findsOneWidget);
      expect(find.text('Please solve this problem or enter PIN to continue:'), findsOneWidget);

      // Parse the dynamic multiplication challenge (e.g. "4 × 5 = ?")
      final mathFinder = find.byWidgetPredicate(
        (w) => w is Text && (w.data?.contains('×') ?? false),
      );
      expect(mathFinder, findsOneWidget);
      final mathText = tester.widget<Text>(mathFinder).data!;
      final parts = mathText.split('×');
      final num1 = int.parse(parts[0].trim());
      final num2 = int.parse(parts[1].split('=').first.trim());
      final answer = (num1 * num2).toString();

      await tester.enterText(find.byType(TextField), answer);
      await tester.tap(find.text('Enter'));
      await tester.pumpAndSettle();

      expect(challengeResult, isTrue);
    });

    testWidgets('ParentGateDialog.showChallenge returns false on Cancel', (tester) async {
      bool? challengeResult;

      await tester.pumpWidget(
        ChangeNotifierProvider<AppProvider>.value(
          value: AppProvider(db: InMemoryDatabaseService()),
          child: MaterialApp(
            home: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  challengeResult = await ParentGateDialog.showChallenge(context);
                },
                child: const Text('Open Gate'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Gate'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(challengeResult, isFalse);
    });
  });
}
