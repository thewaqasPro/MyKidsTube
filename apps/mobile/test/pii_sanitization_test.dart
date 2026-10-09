import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:safe_tube/models/category_item.dart';
import 'package:safe_tube/models/child_profile.dart';
import 'package:safe_tube/models/video_item.dart';
import 'package:safe_tube/providers/app_provider.dart';
import 'package:safe_tube/services/database_service.dart';
import 'package:safe_tube/services/vps_api_service.dart';

class CapturingSyncApiService extends Fake implements VpsApiService {
  List<Map<String, dynamic>> capturedEvents = [];

  @override
  void setAuthToken(String? token) {}

  @override
  Future<Map<String, dynamic>?> syncWatchEvents(String baseUrl, List<Map<String, dynamic>> events) async {
    capturedEvents = events.map((e) => Map<String, dynamic>.from(e)).toList();
    return {
      'success': true,
      'synced_ids': events.map((e) => e['id'] as String).toList(),
    };
  }

  @override
  Future<bool> checkHealth(String baseUrl) async => true;

  @override
  Future<Map<String, dynamic>?> fetchCatalog(String baseUrl, {String? profileId}) async => null;
}

class FakePiiDatabaseService extends Fake implements DatabaseService {
  final List<Map<String, dynamic>> _watchEvents = [];
  final List<ChildProfile> _profiles = [
    ChildProfile(id: 'kid_alice', name: 'Alice', avatarIcon: 'bear', ageBracket: 'preschool'),
  ];

  @override
  Future<String?> getSetting(String key) async => null;

  @override
  Future<void> setSetting(String key, String value) async {}

  @override
  Future<bool> getAutoplayEnabled() async => true;

  @override
  Future<int> getAutoplaySessionLimitMinutes() async => 60;

  @override
  Future<List<CategoryItem>> getAllCategories() async => [];

  @override
  Future<List<VideoItem>> getAllVideos({String? profileId}) async => [];

  @override
  Future<List<VideoItem>> getDownloadedVideos({String? profileId}) async => [];

  @override
  Future<Set<String>> getFavoriteIds({String? profileId}) async => {};

  @override
  Future<List<ChildProfile>> getAllLocalProfiles() async => _profiles;

  @override
  Future<Map<String, dynamic>> getWatchAnalytics({String? profileId}) async => {'today_seconds': 0};

  @override
  Future<Map<String, Map<String, dynamic>>> getVideoWatchSummaries({String? profileId}) async => {};

  @override
  Future<void> recordWatchSession({
    required String videoId,
    String? videoTitle,
    String? categoryId,
    String? profileId,
    String? profileName,
    String? deviceId,
    required int secondsWatched,
    int videoDuration = 0,
    bool isCompleted = false,
    bool isSkipped = false,
  }) async {
    _watchEvents.add({
      'id': 'ev_test_${_watchEvents.length + 1}',
      'video_id': videoId,
      'video_title': videoTitle ?? '',
      'category_id': categoryId ?? '',
      'device_id': deviceId ?? 'raw_hardware_tablet_name',
      'profile_id': profileId ?? 'kid_alice',
      'profile_name': profileName ?? 'Alice PII Name',
      'seconds_watched': secondsWatched,
      'video_duration': videoDuration,
      'completion_rate': 0.85,
      'is_completed': isCompleted ? 1 : 0,
      'is_skipped': isSkipped ? 1 : 0,
      'watched_at': 1728500000000,
      'is_synced': 0,
    });
  }

  @override
  Future<List<Map<String, dynamic>>> getUnsyncedWatchEvents({int limit = 100}) async {
    return _watchEvents.where((e) => e['is_synced'] == 0).toList();
  }

  @override
  Future<void> markWatchEventsSynced(List<String> eventIds) async {
    final idSet = eventIds.toSet();
    for (final e in _watchEvents) {
      if (idSet.contains(e['id'])) {
        e['is_synced'] = 1;
      }
    }
  }
}

class FakeSecureStorage extends Fake implements FlutterSecureStorage {
  final Map<String, String> _data = {};

  FakeSecureStorage([Map<String, String>? initial]) {
    if (initial != null) _data.addAll(initial);
  }

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => _data[key];

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value != null) {
      _data[key] = value;
    } else {
      _data.remove(key);
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Prompt F11 — PII Sanitization in Watch Event Sync', () {
    test('syncWatchEventsToServer drops profile_name and replaces device_id with pairing token', () async {
      final db = FakePiiDatabaseService();
      final api = CapturingSyncApiService();
      final storage = FakeSecureStorage({'device_auth_token': 'pair_tok_998877'});

      final provider = AppProvider(
        db: db,
        api: api,
        secureStorage: storage,
      );
      await provider.init();

      // Record a watch session with child PII name and raw device hardware name
      await provider.recordWatchSession(
        videoId: 'vid_secret_1',
        videoTitle: 'Fun ABC Learning',
        categoryId: 'learning',
        secondsWatched: 120,
        videoDuration: 140,
        isCompleted: true,
      );

      // Perform sync to server
      final result = await provider.syncWatchEventsToServer();
      expect(result['success'], isTrue);
      expect(result['synced_count'], equals(1));

      // Inspect captured outgoing network payload
      expect(api.capturedEvents.length, equals(1));
      final sentEvent = api.capturedEvents.first;

      // 1. profile_name must be completely dropped to protect child privacy
      expect(sentEvent.containsKey('profile_name'), isFalse,
          reason: 'profile_name is PII and must be stripped before outgoing POST');

      // 2. device_id must be replaced with the pairing auth token (NEVER raw device name)
      expect(sentEvent['device_id'], equals('pair_tok_998877'),
          reason: 'device_id must be replaced with pairing auth token');
      expect(sentEvent['device_id'], isNot(equals('raw_hardware_tablet_name')));
      expect(sentEvent['device_id'], isNot(equals('Kids Tablet')));

      // 3. Essential non-PII metrics fields remain intact
      expect(sentEvent['id'], equals('ev_test_1'));
      expect(sentEvent['video_id'], equals('vid_secret_1'));
      expect(sentEvent['video_title'], equals('Fun ABC Learning'));
      expect(sentEvent['category_id'], equals('learning'));
      expect(sentEvent['profile_id'], equals('kid_alice'));
      expect(sentEvent['seconds_watched'], equals(120));
      expect(sentEvent['video_duration'], equals(140));
      expect(sentEvent['is_completed'], equals(1));
      expect(sentEvent['is_skipped'], equals(0));
      expect(sentEvent['watched_at'], equals(1728500000000));

      // 4. Local watch recording & db state remain intact (not corrupted by sync)
      final unsyncedAfter = await db.getUnsyncedWatchEvents();
      expect(unsyncedAfter, isEmpty, reason: 'Event marked synced after successful POST');
    });
  });
}
