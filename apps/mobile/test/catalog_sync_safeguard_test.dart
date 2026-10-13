import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:safe_tube/models/category_item.dart';
import 'package:safe_tube/models/child_profile.dart';
import 'package:safe_tube/models/video_item.dart';
import 'package:safe_tube/providers/app_provider.dart';
import 'package:safe_tube/screens/kid_home_screen.dart';
import 'package:safe_tube/screens/parent_dashboard_screen.dart';
import 'package:safe_tube/services/database_service.dart';
import 'package:safe_tube/services/download_service.dart';
import 'package:safe_tube/services/vps_api_service.dart';

class FakeDatabaseService extends Fake implements DatabaseService {
  List<VideoItem> localVideos = [];
  List<CategoryItem> localCategories = [];
  bool pruneRemovedVideosCalled = false;
  List<String> lastValidIdsPassedToPrune = [];
  List<String> deletedVideoIds = [];
  final Set<String> _tombstones = {};

  FakeDatabaseService({List<VideoItem>? initialVideos}) {
    if (initialVideos != null) {
      localVideos = List.from(initialVideos);
    }
  }

  @override
  Future<List<VideoItem>> getAllVideos({String? profileId}) async =>
      localVideos.where((v) => !_tombstones.contains(v.id)).toList();

  @override
  Future<List<VideoItem>> getDownloadedVideos({String? profileId}) async =>
      localVideos.where((v) => v.downloadStatus == DownloadStatus.downloaded && !_tombstones.contains(v.id)).toList();

  @override
  Future<List<CategoryItem>> getAllCategories() async => List.from(localCategories);

  @override
  Future<Set<String>> getFavoriteIds({String? profileId}) async => {};

  @override
  Future<List<ChildProfile>> getAllLocalProfiles() async => [];

  @override
  Future<Map<String, dynamic>> getWatchAnalytics({String? profileId}) async => {'today_seconds': 0};

  @override
  Future<Set<String>> getDeletedVideoIds() async => Set.from(_tombstones);

  @override
  Future<void> recordDeletedVideos(List<String> videoIds) async {
    _tombstones.addAll(videoIds);
  }

  @override
  Future<void> unmarkDeletedVideo(String videoId) async {
    _tombstones.remove(videoId);
  }

  @override
  Future<bool> isVideoDeleted(String videoId) async => _tombstones.contains(videoId);

  @override
  Future<void> clearDeletedVideosHistory() async {
    _tombstones.clear();
  }

  @override
  Future<void> upsertVideo(VideoItem video, {String? profileId}) async {
    _tombstones.remove(video.id);
    localVideos.removeWhere((v) => v.id == video.id);
    localVideos.add(video);
  }

  @override
  Future<void> batchUpsertCatalog(List<CategoryItem> categories, List<VideoItem> videos, {String? profileId}) async {
    for (final v in videos) {
      if (_tombstones.contains(v.id)) continue;
      localVideos.removeWhere((item) => item.id == v.id);
      localVideos.add(v);
    }
    for (final c in categories) {
      localCategories.removeWhere((item) => item.id == c.id);
      localCategories.add(c);
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
    pruneRemovedVideosCalled = true;
    lastValidIdsPassedToPrune = List.from(validServerVideoIds);

    final validSet = validServerVideoIds.toSet();
    final toDelete = localVideos.where((v) => !validSet.contains(v.id)).toList();

    if (validSet.isEmpty && !allowEmpty) {
      return [];
    }

    final ratio = localVideos.isEmpty ? 0.0 : toDelete.length / localVideos.length;
    if (!force && localVideos.length > 2 && ratio > maxPruneRatio) {
      return [];
    }

    final removedIds = toDelete.map((v) => v.id).toList();
    localVideos.removeWhere((v) => !validSet.contains(v.id));
    return removedIds;
  }

  @override
  Future<void> deleteVideos(List<String> videoIds) async {
    deletedVideoIds.addAll(videoIds);
    _tombstones.addAll(videoIds);
    final deleteSet = videoIds.toSet();
    localVideos.removeWhere((v) => deleteSet.contains(v.id));
  }

  @override
  Future<void> deleteVideo(String videoId) async {
    await deleteVideos([videoId]);
  }

  @override
  Future<void> setSetting(String key, String value) async {}

  @override
  Future<String?> getSetting(String key) async => null;

  @override
  Future<void> upsertLocalProfile(ChildProfile profile) async {}
}

class FakeVpsApiService extends Fake implements VpsApiService {
  Map<String, dynamic>? catalogResponse;
  bool healthResult = true;

  @override
  Future<Map<String, dynamic>?> fetchCatalog(String baseUrl, {String? profileId}) async {
    return catalogResponse;
  }

  @override
  Future<bool> checkHealth(String baseUrl) async {
    return healthResult;
  }

  @override
  Future<List<ChildProfile>> fetchProfiles(String baseUrl) async => [];

  @override
  Future<bool> deleteVideos(String baseUrl, List<String> videoIds) async => true;
}

class FakeDownloadService extends Fake implements DownloadService {
  @override
  Future<int> getTotalCachedBytes() async => 0;
}

VideoItem createTestVideo(String id, {String title = 'Video'}) {
  return VideoItem(
    id: id,
    title: '$title $id',
    categoryId: 'cartoons',
    streamUrl: 'https://example.com/$id.mp4',
    thumbnailUrl: 'https://example.com/$id.webp',
  );
}

Map<String, dynamic> createVideoApiJson(String id, {String title = 'Video'}) {
  return {
    'id': id,
    'title': '$title $id',
    'category_id': 'cartoons',
    'stream_url': 'https://example.com/$id.mp4',
    'thumbnail_url': 'https://example.com/$id.webp',
  };
}

void main() {
  group('R5 — Mobile Catalog Sync Safeguard & Safety Cap Tests', () {
    test('Server returns 200 with empty sections -> local videos untouched, refresh-failed notice shown', () async {
      final initialVideos = [
        createTestVideo('v1'),
        createTestVideo('v2'),
        createTestVideo('v3'),
      ];

      final fakeDb = FakeDatabaseService(initialVideos: initialVideos);
      final fakeApi = FakeVpsApiService();
      // Server returns 200 with empty sections
      fakeApi.catalogResponse = {
        'sections': [],
        'all_videos': [],
      };

      final provider = AppProvider(db: fakeDb, api: fakeApi, downloader: FakeDownloadService());
      addTearDown(provider.dispose);

      await provider.syncCatalog(autoRetry: false);

      // Local library must remain completely intact
      expect(provider.allVideos.length, 3);
      expect(provider.allVideos.map((v) => v.id), containsAll(['v1', 'v2', 'v3']));
      expect(fakeDb.pruneRemovedVideosCalled, false, reason: 'Pruning must NOT be called on ambiguous empty response');

      // Refresh-failed notice must be surfaced
      expect(provider.hasRefreshFailedNotice, true);
      expect(provider.refreshNoticeMessage, contains("Couldn't refresh video catalog"));
    });

    test('Unparseable / null catalog response -> local library intact, refresh-failed notice shown', () async {
      final initialVideos = [
        createTestVideo('v1'),
        createTestVideo('v2'),
      ];

      final fakeDb = FakeDatabaseService(initialVideos: initialVideos);
      final fakeApi = FakeVpsApiService();
      fakeApi.catalogResponse = null;

      final provider = AppProvider(db: fakeDb, api: fakeApi, downloader: FakeDownloadService());
      addTearDown(provider.dispose);

      await provider.syncCatalog(autoRetry: false);

      expect(provider.allVideos.length, 2);
      expect(fakeDb.pruneRemovedVideosCalled, false);
      expect(provider.hasRefreshFailedNotice, true);
    });

    test('Genuine removal (video absent from a valid non-empty catalog) prunes correctly', () async {
      final initialVideos = [
        createTestVideo('v1'),
        createTestVideo('v2'),
        createTestVideo('v3'),
        createTestVideo('v4'),
      ];

      final fakeDb = FakeDatabaseService(initialVideos: initialVideos);
      final fakeApi = FakeVpsApiService();
      // Server returns 3 videos (v4 was removed by parent)
      fakeApi.catalogResponse = {
        'sections': [
          {
            'category': {'id': 'cartoons', 'name': 'Cartoons'},
            'videos': [
              createVideoApiJson('v1'),
              createVideoApiJson('v2'),
              createVideoApiJson('v3'),
            ],
          }
        ],
      };

      final provider = AppProvider(db: fakeDb, api: fakeApi, downloader: FakeDownloadService());
      addTearDown(provider.dispose);

      await provider.syncCatalog(autoRetry: false);

      // v4 must be pruned, leaving v1, v2, v3
      expect(fakeDb.pruneRemovedVideosCalled, true);
      expect(fakeDb.lastValidIdsPassedToPrune, containsAll(['v1', 'v2', 'v3']));
      expect(provider.allVideos.length, 3);
      expect(provider.allVideos.map((v) => v.id), isNot(contains('v4')));
      expect(provider.hasRefreshFailedNotice, false);
      expect(provider.hasPendingMassPrune, false);
    });

    test('Safety cap: never delete more than 50% in one sync without parent confirmation', () async {
      final initialVideos = List.generate(10, (i) => createTestVideo('v${i + 1}'));

      final fakeDb = FakeDatabaseService(initialVideos: initialVideos);
      final fakeApi = FakeVpsApiService();
      // Server suddenly returns only 2 videos (attempting to delete 8 of 10 = 80% > 50%)
      fakeApi.catalogResponse = {
        'sections': [
          {
            'category': {'id': 'cartoons', 'name': 'Cartoons'},
            'videos': [
              createVideoApiJson('v1'),
              createVideoApiJson('v2'),
            ],
          }
        ],
      };

      final provider = AppProvider(db: fakeDb, api: fakeApi, downloader: FakeDownloadService());
      addTearDown(provider.dispose);

      await provider.syncCatalog(autoRetry: false);

      // Prune must NOT have executed because safety cap caught it
      expect(fakeDb.pruneRemovedVideosCalled, false);
      expect(provider.hasPendingMassPrune, true);
      expect(provider.pendingPruneCount, 8);
      expect(provider.pendingPruneVideoIds, containsAll(['v3', 'v4', 'v5', 'v6', 'v7', 'v8', 'v9', 'v10']));
      expect(provider.hasRefreshFailedNotice, true);
      expect(provider.refreshNoticeMessage, contains('held for parent confirmation'));
      // Local library intact
      expect(provider.allVideos.length, 10);
    });

    test('Parent confirmation in dashboard triggers the held mass prune', () async {
      final initialVideos = List.generate(10, (i) => createTestVideo('v${i + 1}'));
      final fakeDb = FakeDatabaseService(initialVideos: initialVideos);
      final fakeApi = FakeVpsApiService();
      fakeApi.catalogResponse = {
        'sections': [
          {
            'category': {'id': 'cartoons', 'name': 'Cartoons'},
            'videos': [
              createVideoApiJson('v1'),
              createVideoApiJson('v2'),
            ],
          }
        ],
      };

      final provider = AppProvider(db: fakeDb, api: fakeApi, downloader: FakeDownloadService());
      addTearDown(provider.dispose);

      await provider.syncCatalog(autoRetry: false);
      expect(provider.hasPendingMassPrune, true);

      // Parent explicitly confirms mass prune
      await provider.confirmPendingPrune();

      expect(provider.hasPendingMassPrune, false);
      expect(provider.hasRefreshFailedNotice, false);
      expect(provider.allVideos.length, 2);
      expect(provider.allVideos.map((v) => v.id), containsAll(['v1', 'v2']));
    });

    test('Parent dismissing pending mass prune keeps local offline videos', () async {
      final initialVideos = List.generate(10, (i) => createTestVideo('v${i + 1}'));
      final fakeDb = FakeDatabaseService(initialVideos: initialVideos);
      final fakeApi = FakeVpsApiService();
      fakeApi.catalogResponse = {
        'sections': [
          {
            'category': {'id': 'cartoons', 'name': 'Cartoons'},
            'videos': [createVideoApiJson('v1')],
          }
        ],
      };

      final provider = AppProvider(db: fakeDb, api: fakeApi, downloader: FakeDownloadService());
      addTearDown(provider.dispose);

      await provider.syncCatalog(autoRetry: false);
      expect(provider.hasPendingMassPrune, true);

      // Parent dismisses prune notice without deleting
      provider.dismissPendingPrune();

      expect(provider.hasPendingMassPrune, false);
      expect(provider.hasRefreshFailedNotice, false);
      expect(provider.allVideos.length, 10);
    });

    test('Explicit signal catalog_cleared: true gates total clearing through safety cap', () async {
      final initialVideos = List.generate(5, (i) => createTestVideo('v${i + 1}'));
      final fakeDb = FakeDatabaseService(initialVideos: initialVideos);
      final fakeApi = FakeVpsApiService();
      fakeApi.catalogResponse = {
        'sections': [],
        'all_videos': [],
        'catalog_cleared': true,
      };

      final provider = AppProvider(db: fakeDb, api: fakeApi, downloader: FakeDownloadService());
      addTearDown(provider.dispose);

      await provider.syncCatalog(autoRetry: false);

      // Safety cap holds the complete wipe for parent confirmation
      expect(provider.hasPendingMassPrune, true);
      expect(provider.pendingPruneCount, 5);
      expect(provider.hasRefreshFailedNotice, true);
      expect(provider.allVideos.length, 5);
    });
  });

  group('Persistent Deletion & Resurrection Prevention Tests', () {
    test('Deleting videos records tombstones and removes them from local catalog', () async {
      final initialVideos = [
        createTestVideo('v1'),
        createTestVideo('v2'),
        createTestVideo('v3'),
      ];
      final fakeDb = FakeDatabaseService(initialVideos: initialVideos);
      final fakeApi = FakeVpsApiService();
      fakeApi.catalogResponse = {
        'sections': [
          {
            'category': {'id': 'cartoons', 'name': 'Cartoons'},
            'videos': [
              createVideoApiJson('v1'),
              createVideoApiJson('v2'),
              createVideoApiJson('v3'),
            ],
          }
        ],
      };
      final provider = AppProvider(db: fakeDb, api: fakeApi, downloader: FakeDownloadService());
      addTearDown(provider.dispose);

      await provider.syncCatalog(autoRetry: false);
      expect(provider.allVideos.length, 3);

      // Parent deletes v1 and v2
      final ok = await provider.deleteVideosFromCatalog(['v1', 'v2']);
      expect(ok, true);

      // Deleted videos must be gone immediately
      expect(provider.allVideos.length, 1);
      expect(provider.allVideos.first.id, 'v3');

      // Tombstones must be recorded
      final tombstones = await fakeDb.getDeletedVideoIds();
      expect(tombstones, containsAll(['v1', 'v2']));
    });

    test('Sync catalog on refresh does NOT resurrect previously deleted videos', () async {
      final initialVideos = [
        createTestVideo('v1'),
        createTestVideo('v2'),
        createTestVideo('v3'),
      ];
      final fakeDb = FakeDatabaseService(initialVideos: initialVideos);
      final fakeApi = FakeVpsApiService();
      // Server returns all 3 videos (e.g. static Cloudflare worker demo catalog)
      fakeApi.catalogResponse = {
        'sections': [
          {
            'category': {'id': 'cartoons', 'name': 'Cartoons'},
            'videos': [
              createVideoApiJson('v1'),
              createVideoApiJson('v2'),
              createVideoApiJson('v3'),
            ],
          }
        ],
      };

      final provider = AppProvider(db: fakeDb, api: fakeApi, downloader: FakeDownloadService());
      addTearDown(provider.dispose);

      // Initial catalog sync
      await provider.syncCatalog(autoRetry: false);
      expect(provider.allVideos.length, 3);

      // 1. Delete v1 and v2
      await provider.deleteVideosFromCatalog(['v1', 'v2']);
      expect(provider.allVideos.map((v) => v.id), ['v3']);

      // 2. User pulls to refresh / app refreshes
      await provider.syncCatalog(autoRetry: false);

      // 3. Deleted videos MUST NOT reappear!
      expect(provider.allVideos.map((v) => v.id), ['v3']);
      expect(provider.allVideos.any((v) => v.id == 'v1'), false);
      expect(provider.allVideos.any((v) => v.id == 'v2'), false);
    });

    test('Explicitly re-adding a previously deleted video unmarks tombstone and restores it', () async {
      final initialVideos = [createTestVideo('v1')];
      final fakeDb = FakeDatabaseService(initialVideos: initialVideos);
      final fakeApi = FakeVpsApiService();
      fakeApi.catalogResponse = {
        'sections': [
          {
            'category': {'id': 'cartoons', 'name': 'Cartoons'},
            'videos': [createVideoApiJson('v1')],
          }
        ],
      };
      final provider = AppProvider(db: fakeDb, api: fakeApi, downloader: FakeDownloadService());
      addTearDown(provider.dispose);

      await provider.syncCatalog(autoRetry: false);
      expect(provider.allVideos.length, 1);

      // Delete v1
      await provider.deleteVideosFromCatalog(['v1']);
      expect(provider.allVideos, isEmpty);
      expect(await fakeDb.getDeletedVideoIds(), contains('v1'));

      // Explicitly re-add v1
      final restoredVideo = createTestVideo('v1', title: 'Restored Video');
      await provider.addStandaloneVideo(restoredVideo);

      // Tombstone is cleared and video is restored in catalog
      expect(await fakeDb.getDeletedVideoIds(), isNot(contains('v1')));
      expect(provider.allVideos.length, 1);
      expect(provider.allVideos.first.id, 'v1');
    });
  });

  group('R5 — Widget Tests for Refresh Notice & Dashboard Card', () {
    testWidgets('KidHomeScreen displays refresh-failed notice banner', (WidgetTester tester) async {
      final fakeDb = FakeDatabaseService(initialVideos: [createTestVideo('v1')]);
      final fakeApi = FakeVpsApiService();
      fakeApi.catalogResponse = null; // Forces syncCatalog failure

      final provider = AppProvider(db: fakeDb, api: fakeApi, downloader: FakeDownloadService());
      addTearDown(provider.dispose);

      await provider.syncCatalog(autoRetry: false);
      expect(provider.hasRefreshFailedNotice, true);

      await tester.pumpWidget(
        ChangeNotifierProvider<AppProvider>.value(
          value: provider,
          child: const MaterialApp(
            home: KidHomeScreen(),
          ),
        ),
      );
      await tester.pump();

      // Verify banner appears with appropriate text and icon
      expect(find.text("Couldn't refresh video catalog. Using offline library."), findsOneWidget);
      expect(find.byIcon(Icons.sync_problem_rounded), findsOneWidget);

      // Tap dismiss icon
      await tester.tap(find.byTooltip('Dismiss'));
      await tester.pump();

      // Verify banner dismissed
      expect(find.text("Couldn't refresh video catalog. Using offline library."), findsNothing);
    });

    testWidgets('ParentDashboardScreen displays Safety Cap confirmation card when pending prune exists', (WidgetTester tester) async {
      final fakeDb = FakeDatabaseService(initialVideos: List.generate(10, (i) => createTestVideo('v${i + 1}')));
      final fakeApi = FakeVpsApiService();
      fakeApi.catalogResponse = {
        'sections': [
          {
            'category': {'id': 'cartoons', 'name': 'Cartoons'},
            'videos': [createVideoApiJson('v1')],
          }
        ],
      };

      final provider = AppProvider(db: fakeDb, api: fakeApi, downloader: FakeDownloadService());
      addTearDown(provider.dispose);

      await provider.syncCatalog(autoRetry: false);

      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ChangeNotifierProvider<AppProvider>.value(
          value: provider,
          child: const MaterialApp(
            home: ParentDashboardScreen(),
          ),
        ),
      );
      await tester.pump();

      // Verify safety cap card is displayed
      expect(find.text('Mass Removal Blocked (Safety Cap)'), findsOneWidget);
      expect(find.text('Confirm Deletion'), findsOneWidget);
      expect(find.text('Keep Offline'), findsOneWidget);

      // Tap 'Keep Offline'
      await tester.tap(find.text('Keep Offline'));
      await tester.pump();

      // Card disappears, local library preserved
      expect(find.text('Mass Removal Blocked (Safety Cap)'), findsNothing);
      expect(provider.hasPendingMassPrune, false);
      expect(fakeDb.localVideos.length, 10);
    });
  });
}
