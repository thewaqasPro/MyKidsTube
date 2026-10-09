import 'package:flutter_test/flutter_test.dart';
import 'package:safe_tube/models/category_item.dart';
import 'package:safe_tube/models/child_profile.dart';
import 'package:safe_tube/models/video_item.dart';
import 'package:safe_tube/providers/app_provider.dart';
import 'package:safe_tube/services/database_service.dart';
import 'package:safe_tube/services/recommendation_service.dart';
import 'package:safe_tube/services/vps_api_service.dart';

class MockBoundaryDatabaseService extends Fake implements DatabaseService {
  final List<VideoItem> _videos = [];
  final List<CategoryItem> _categories = [];
  final Map<String, Set<String>> _favoritesByProfile = {};
  final List<ChildProfile> _profiles = [];
  final Map<String, String> _settings = {};

  MockBoundaryDatabaseService({
    List<VideoItem>? initialVideos,
    List<CategoryItem>? initialCategories,
    List<ChildProfile>? initialProfiles,
  }) {
    if (initialVideos != null) _videos.addAll(initialVideos);
    if (initialCategories != null) _categories.addAll(initialCategories);
    if (initialProfiles != null) _profiles.addAll(initialProfiles);
  }

  @override
  Future<String?> getSetting(String key) async => _settings[key];

  @override
  Future<void> setSetting(String key, String value) async => _settings[key] = value;

  @override
  Future<bool> getAutoplayEnabled() async => true;

  @override
  Future<int> getAutoplaySessionLimitMinutes() async => 60;

  @override
  Future<List<CategoryItem>> getAllCategories() async => List.from(_categories);

  @override
  Future<List<ChildProfile>> getAllLocalProfiles() async => List.from(_profiles);

  @override
  Future<List<VideoItem>> getAllVideos({String? profileId}) async {
    if (profileId == null || profileId.isEmpty || profileId == 'kids_all') {
      return List.from(_videos);
    }
    return _videos.where((v) => DatabaseService.isAssignedToProfile(v.profileId, profileId)).toList();
  }

  @override
  Future<List<VideoItem>> getDownloadedVideos({String? profileId}) async {
    final downloaded = _videos.where((v) => v.downloadStatus == DownloadStatus.downloaded && v.localFilePath != null);
    if (profileId == null || profileId.isEmpty || profileId == 'kids_all') {
      return downloaded.toList();
    }
    return downloaded.where((v) => DatabaseService.isAssignedToProfile(v.profileId, profileId)).toList();
  }

  @override
  Future<List<VideoItem>> searchVideos(String query, {String? profileId}) async {
    final q = query.toLowerCase();
    final matching = _videos.where((v) => v.title.toLowerCase().contains(q));
    if (profileId == null || profileId.isEmpty || profileId == 'kids_all') {
      return matching.toList();
    }
    return matching.where((v) => DatabaseService.isAssignedToProfile(v.profileId, profileId)).toList();
  }

  @override
  Future<void> batchUpsertCatalog(
    List<CategoryItem> categories,
    List<VideoItem> videos, {
    String? profileId,
  }) async {
    for (final v in videos) {
      _videos.removeWhere((item) => item.id == v.id);
      _videos.add(v);
    }
    for (final c in categories) {
      _categories.removeWhere((item) => item.id == c.id);
      _categories.add(c);
    }
  }

  @override
  Future<List<String>> pruneRemovedVideos(
    List<String> validServerVideoIds, {
    String? profileId,
    bool allowEmpty = false,
    double maxPruneRatio = 0.50,
    bool force = false,
  }) async {
    final validSet = validServerVideoIds.toSet();
    final candidatePool = (profileId != null && profileId.isNotEmpty && profileId != 'kids_all')
        ? _videos.where((v) => DatabaseService.isAssignedToProfile(v.profileId, profileId)).toList()
        : List<VideoItem>.from(_videos);

    final toDelete = candidatePool.where((v) => !validSet.contains(v.id)).toList();
    for (final v in toDelete) {
      _videos.removeWhere((item) => item.id == v.id);
    }
    return toDelete.map((v) => v.id).toList();
  }

  @override
  Future<void> toggleFavorite(String videoId, {String? profileId}) async {
    final pId = profileId ?? 'kids_all';
    _favoritesByProfile.putIfAbsent(pId, () => <String>{});
    if (_favoritesByProfile[pId]!.contains(videoId)) {
      _favoritesByProfile[pId]!.remove(videoId);
    } else {
      _favoritesByProfile[pId]!.add(videoId);
    }
  }

  @override
  Future<bool> isFavorite(String videoId, {String? profileId}) async {
    final pId = profileId ?? 'kids_all';
    return _favoritesByProfile[pId]?.contains(videoId) ?? false;
  }

  @override
  Future<Set<String>> getFavoriteIds({String? profileId}) async {
    final pId = profileId ?? 'kids_all';
    return Set<String>.from(_favoritesByProfile[pId] ?? {});
  }

  final List<Map<String, dynamic>> _watchEvents = [];

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
    final effectiveProfileId = (profileId != null && profileId.isNotEmpty && profileId != 'all')
        ? profileId
        : 'no-profile';
    _watchEvents.add({
      'video_id': videoId,
      'category_id': categoryId ?? '',
      'profile_id': effectiveProfileId,
      'seconds_watched': secondsWatched,
      'is_completed': isCompleted ? 1 : 0,
      'is_skipped': isSkipped ? 1 : 0,
      'watched_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  @override
  Future<Map<String, dynamic>> getWatchAnalytics({String? profileId}) async {
    final events = (profileId != null && profileId.isNotEmpty && profileId != 'all')
        ? _watchEvents.where((e) => e['profile_id'] == profileId).toList()
        : _watchEvents.where((e) => e['profile_id'] != 'no-profile').toList();

    final totalSeconds = events.fold<int>(0, (acc, e) => acc + (e['seconds_watched'] as int));
    return {
      'total_seconds': totalSeconds,
      'today_seconds': totalSeconds,
      'total_sessions': events.length,
    };
  }

  @override
  Future<Map<String, Map<String, dynamic>>> getVideoWatchSummaries({String? profileId}) async {
    if (profileId == null || profileId.isEmpty || profileId == 'all' || profileId == 'no-profile') {
      return {};
    }
    final events = _watchEvents.where((e) => e['profile_id'] == profileId).toList();
    final Map<String, Map<String, dynamic>> result = {};
    for (final e in events) {
      final vId = e['video_id'] as String;
      final prev = result[vId];
      final count = (prev?['watch_count'] as int? ?? 0) + 1;
      final total = (prev?['total_seconds'] as int? ?? 0) + (e['seconds_watched'] as int);
      result[vId] = {
        'last_watched_at': e['watched_at'],
        'watch_count': count,
        'completed_count': (prev?['completed_count'] as int? ?? 0) + (e['is_completed'] as int),
        'skipped_count': (prev?['skipped_count'] as int? ?? 0) + (e['is_skipped'] as int),
        'total_seconds': total,
        'category_id': e['category_id'],
      };
    }
    return result;
  }
}

class MockBoundaryApiService extends Fake implements VpsApiService {
  @override
  Future<Map<String, dynamic>?> fetchCatalog(String baseUrl, {String? profileId}) async => null;

  @override
  Future<List<ChildProfile>> fetchProfiles(String baseUrl) async => [];

  @override
  Future<bool> checkHealth(String baseUrl) async => true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Prompt F6 — Per-Profile Content Boundaries & Isolation', () {
    late ChildProfile profileAlice;
    late ChildProfile profileBob;
    late VideoItem videoAlice;
    late VideoItem videoBob;
    late VideoItem videoShared;
    late MockBoundaryDatabaseService db;
    late MockBoundaryApiService api;

    setUp(() {
      profileAlice = ChildProfile(
        id: 'prof_alice',
        name: 'Alice',
        avatarIcon: 'teddy',
        ageBracket: 'toddler',
      );

      profileBob = ChildProfile(
        id: 'prof_bob',
        name: 'Bob',
        avatarIcon: 'stars',
        ageBracket: 'kids',
      );

      videoAlice = VideoItem(
        id: 'vid_alice_1',
        title: 'Alice Toddler Rhymes ABC',
        categoryId: 'cartoons',
        streamUrl: 'https://cdn.example.com/alice.mp4',
        thumbnailUrl: 'https://cdn.example.com/alice.webp',
        profileId: 'prof_alice',
      );

      videoBob = VideoItem(
        id: 'vid_bob_1',
        title: 'Bob Science Experiment LEGO',
        categoryId: 'learning',
        streamUrl: 'https://cdn.example.com/bob.mp4',
        thumbnailUrl: 'https://cdn.example.com/bob.webp',
        profileId: 'prof_bob',
      );

      videoShared = VideoItem(
        id: 'vid_shared_1',
        title: 'Shared Kids Songs All Ages',
        categoryId: 'music',
        streamUrl: 'https://cdn.example.com/shared.mp4',
        thumbnailUrl: 'https://cdn.example.com/shared.webp',
        profileId: 'kids_all',
      );

      db = MockBoundaryDatabaseService(
        initialVideos: [videoAlice, videoBob, videoShared],
        initialCategories: [
          CategoryItem(id: 'cartoons', name: 'Cartoons'),
          CategoryItem(id: 'learning', name: 'Learning'),
          CategoryItem(id: 'music', name: 'Music'),
        ],
        initialProfiles: [profileAlice, profileBob],
      );

      api = MockBoundaryApiService();
    });

    test('isAssignedToProfile logic strictly enforces per-profile boundaries', () {
      // Alice's video
      expect(DatabaseService.isAssignedToProfile(videoAlice.profileId, 'prof_alice'), isTrue);
      expect(DatabaseService.isAssignedToProfile(videoAlice.profileId, 'prof_bob'), isFalse);

      // Bob's video
      expect(DatabaseService.isAssignedToProfile(videoBob.profileId, 'prof_bob'), isTrue);
      expect(DatabaseService.isAssignedToProfile(videoBob.profileId, 'prof_alice'), isFalse);

      // Shared video (kids_all)
      expect(DatabaseService.isAssignedToProfile(videoShared.profileId, 'prof_alice'), isTrue);
      expect(DatabaseService.isAssignedToProfile(videoShared.profileId, 'prof_bob'), isTrue);

      // Multi-profile comma-separated assignment
      const multiAssigned = 'prof_alice,prof_bob';
      expect(DatabaseService.isAssignedToProfile(multiAssigned, 'prof_alice'), isTrue);
      expect(DatabaseService.isAssignedToProfile(multiAssigned, 'prof_bob'), isTrue);
      expect(DatabaseService.isAssignedToProfile(multiAssigned, 'prof_charlie'), isFalse);
    });

    test('Video assigned to Profile A never appears in Profile B feed, search, or recommendations', () async {
      final provider = AppProvider(db: db, api: api);
      await provider.init();

      // Switch to Bob
      await provider.switchProfile(profileBob);
      expect(provider.activeProfile?.id, 'prof_bob');

      // 1. Catalog Feed: Bob sees Bob's video and Shared video, but NEVER Alice's video
      final bobCatalogIds = provider.allVideos.map((v) => v.id).toList();
      expect(bobCatalogIds, contains('vid_bob_1'));
      expect(bobCatalogIds, contains('vid_shared_1'));
      expect(bobCatalogIds, isNot(contains('vid_alice_1')));

      // 2. Personalized Feed: Zero Alice content
      final personalizedBob = provider.getPersonalizedFeed();
      final personalizedBobIds = personalizedBob.map((v) => v.id).toList();
      expect(personalizedBobIds, isNot(contains('vid_alice_1')));
      expect(personalizedBobIds, contains('vid_bob_1'));

      // 3. Search: Searching for "Alice" returns zero results in Bob's feed
      final searchResults = provider.getPersonalizedFeed(searchQuery: 'Alice');
      expect(searchResults, isEmpty);

      // 4. Recommendations: Recommending off Shared video never suggests Alice's video to Bob
      final recommendations = provider.getRecommendationsFor(videoShared);
      final recIds = recommendations.map((v) => v.id).toList();
      expect(recIds, isNot(contains('vid_alice_1')));

      // 5. Autoplay candidate pool: zero Alice content
      final autoplayPool = provider.allVideos;
      for (final v in autoplayPool) {
        expect(v.id, isNot('vid_alice_1'));
      }
    });

    test('Video assigned to Profile B never appears in Profile A feed, search, or recommendations', () async {
      final provider = AppProvider(db: db, api: api);
      await provider.init();

      // Switch to Alice
      await provider.switchProfile(profileAlice);
      expect(provider.activeProfile?.id, 'prof_alice');

      // 1. Catalog Feed: Alice sees Alice's video and Shared video, but NEVER Bob's video
      final aliceCatalogIds = provider.allVideos.map((v) => v.id).toList();
      expect(aliceCatalogIds, contains('vid_alice_1'));
      expect(aliceCatalogIds, contains('vid_shared_1'));
      expect(aliceCatalogIds, isNot(contains('vid_bob_1')));

      // 2. Personalized Feed: Zero Bob content
      final personalizedAlice = provider.getPersonalizedFeed();
      final personalizedAliceIds = personalizedAlice.map((v) => v.id).toList();
      expect(personalizedAliceIds, isNot(contains('vid_bob_1')));
      expect(personalizedAliceIds, contains('vid_alice_1'));

      // 3. Search: Searching for "Science" returns zero results in Alice's feed
      final searchResults = provider.getPersonalizedFeed(searchQuery: 'Science');
      expect(searchResults, isEmpty);

      // 4. Recommendations: Recommending off Shared video never suggests Bob's video to Alice
      final recommendations = provider.getRecommendationsFor(videoShared);
      final recIds = recommendations.map((v) => v.id).toList();
      expect(recIds, isNot(contains('vid_bob_1')));
    });

    test('Favorites are strictly isolated per-profile', () async {
      final provider = AppProvider(db: db, api: api);
      await provider.init();

      // Alice favorites shared video
      await provider.switchProfile(profileAlice);
      await provider.toggleFavorite(videoShared.id);

      expect(provider.isFavorite(videoShared.id), isTrue);
      expect(provider.favoriteVideoIds, contains(videoShared.id));

      // Switch to Bob: videoShared must NOT be favorited for Bob
      await provider.switchProfile(profileBob);
      expect(provider.isFavorite(videoShared.id), isFalse);
      expect(provider.favoriteVideoIds, isNot(contains(videoShared.id)));

      // Bob favorites his own video
      await provider.toggleFavorite(videoBob.id);
      expect(provider.isFavorite(videoBob.id), isTrue);
      expect(provider.favoriteVideoIds, contains(videoBob.id));

      // Switch back to Alice: Bob's favorite is NOT present, Alice's favorite is preserved
      await provider.switchProfile(profileAlice);
      expect(provider.isFavorite(videoShared.id), isTrue);
      expect(provider.isFavorite(videoBob.id), isFalse);
      expect(provider.favoriteVideoIds, contains(videoShared.id));
      expect(provider.favoriteVideoIds, isNot(contains(videoBob.id)));
    });

    test('Prune guard and offline playback: Profile B sync never prunes Profile A offline videos', () async {
      // Give Alice a downloaded offline video
      final downloadedAliceVideo = videoAlice.copyWith(
        downloadStatus: DownloadStatus.downloaded,
        localFilePath: '/data/user/0/app/files/vid_alice_1.mp4',
        localThumbnailPath: '/data/user/0/app/files/vid_alice_1.webp',
      );

      final testDb = MockBoundaryDatabaseService(
        initialVideos: [downloadedAliceVideo, videoBob, videoShared],
        initialCategories: [CategoryItem(id: 'cartoons', name: 'Cartoons')],
        initialProfiles: [profileAlice, profileBob],
      );

      final provider = AppProvider(db: testDb, api: api);
      await provider.init();

      // Bob is active and syncs catalog where server only lists videoBob
      await provider.switchProfile(profileBob);

      // Prune is called for Bob's profile with server IDs containing only videoBob
      final pruned = await testDb.pruneRemovedVideos(
        ['vid_bob_1'],
        profileId: 'prof_bob',
      );

      // videoAlice must NOT be pruned!
      expect(pruned, isNot(contains('vid_alice_1')));

      // Switch back to Alice: her downloaded offline video is 100% intact
      await provider.switchProfile(profileAlice);
      final aliceDownloaded = await testDb.getDownloadedVideos(profileId: 'prof_alice');
      expect(aliceDownloaded.any((v) => v.id == 'vid_alice_1'), isTrue);
      expect(aliceDownloaded.first.isOfflineReady, isTrue);
    });

    test('Switching profile instantaneously updates active boundary and re-seeds recommendations', () async {
      final provider = AppProvider(db: db, api: api);
      await provider.init();

      await provider.switchProfile(profileAlice);
      expect(provider.allVideos.any((v) => v.id == 'vid_alice_1'), isTrue);
      expect(provider.allVideos.any((v) => v.id == 'vid_bob_1'), isFalse);

      await provider.switchProfile(profileBob);
      expect(provider.allVideos.any((v) => v.id == 'vid_bob_1'), isTrue);
      expect(provider.allVideos.any((v) => v.id == 'vid_alice_1'), isFalse);
    });

    test('Prompt F7 — Favoriting under Profile A does not boost Profile B recommendations', () async {
      final provider = AppProvider(db: db, api: api);
      await provider.init();

      // Alice favorites videoShared
      await provider.switchProfile(profileAlice);
      await provider.toggleFavorite(videoShared.id);

      expect(provider.favoriteVideoIds.contains(videoShared.id), isTrue);

      // Score for Alice on videoShared includes the +15 favorite boost
      final scoreAlice = RecommendationService.calculateScore(
        candidate: videoShared,
        favoriteVideoIds: provider.favoriteVideoIds,
      );

      // Switch to Bob: favoriteVideoIds for Bob must NOT contain videoShared
      await provider.switchProfile(profileBob);
      expect(provider.favoriteVideoIds.contains(videoShared.id), isFalse);

      final scoreBob = RecommendationService.calculateScore(
        candidate: videoShared,
        favoriteVideoIds: provider.favoriteVideoIds,
      );

      // Difference must reflect exactly the 15.0 favorite boost
      expect(scoreAlice - scoreBob, closeTo(15.0, 0.001));
    });

    test('Prompt F8 — Scope watch metrics & analytics to active profile, isolate no-profile sessions', () async {
      final provider = AppProvider(db: db, api: api);
      await provider.init();

      // 1. Record Alice session (120s)
      await provider.switchProfile(profileAlice);
      await provider.recordWatchSession(
        videoId: videoAlice.id,
        videoTitle: videoAlice.title,
        categoryId: videoAlice.categoryId,
        secondsWatched: 120,
        videoDuration: 120,
        isCompleted: true,
      );

      // 2. Record Bob session (60s)
      await provider.switchProfile(profileBob);
      await provider.recordWatchSession(
        videoId: videoBob.id,
        videoTitle: videoBob.title,
        categoryId: videoBob.categoryId,
        secondsWatched: 60,
        videoDuration: 60,
        isCompleted: true,
      );

      // 3. Record no-profile session directly on DB (30s)
      await db.recordWatchSession(
        videoId: videoShared.id,
        secondsWatched: 30,
        videoDuration: 30,
        profileId: null, // Should go to 'no-profile' bucket
      );

      // 4. Verification: getVideoWatchSummaries requires a concrete profile context
      final emptyNullSummaries = await db.getVideoWatchSummaries(profileId: null);
      expect(emptyNullSummaries, isEmpty);

      final emptyAllSummaries = await db.getVideoWatchSummaries(profileId: 'all');
      expect(emptyAllSummaries, isEmpty);

      final emptyNoProfileSummaries = await db.getVideoWatchSummaries(profileId: 'no-profile');
      expect(emptyNoProfileSummaries, isEmpty);

      // 5. Alice's summaries contain ONLY Alice's metrics
      final aliceSummaries = await db.getVideoWatchSummaries(profileId: 'prof_alice');
      expect(aliceSummaries.containsKey(videoAlice.id), isTrue);
      expect(aliceSummaries[videoAlice.id]?['total_seconds'], 120);
      expect(aliceSummaries.containsKey(videoBob.id), isFalse);
      expect(aliceSummaries.containsKey(videoShared.id), isFalse);

      // 6. Bob's summaries contain ONLY Bob's metrics
      final bobSummaries = await db.getVideoWatchSummaries(profileId: 'prof_bob');
      expect(bobSummaries.containsKey(videoBob.id), isTrue);
      expect(bobSummaries[videoBob.id]?['total_seconds'], 60);
      expect(bobSummaries.containsKey(videoAlice.id), isFalse);
      expect(bobSummaries.containsKey(videoShared.id), isFalse);

      // 7. Per-profile analytics never include cross-profile or no-profile sessions
      final aliceAnalytics = await db.getWatchAnalytics(profileId: 'prof_alice');
      expect(aliceAnalytics['total_seconds'], 120);
      expect(aliceAnalytics['total_sessions'], 1);

      final bobAnalytics = await db.getWatchAnalytics(profileId: 'prof_bob');
      expect(bobAnalytics['total_seconds'], 60);
      expect(bobAnalytics['total_sessions'], 1);

      // 8. Overall family overview (profileId: 'all') excludes the orphan 'no-profile' bucket
      final allAnalytics = await db.getWatchAnalytics(profileId: 'all');
      expect(allAnalytics['total_seconds'], 180); // Alice (120) + Bob (60), no-profile (30) excluded
      expect(allAnalytics['total_sessions'], 2);
    });
  });
}
