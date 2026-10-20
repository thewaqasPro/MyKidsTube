import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:safe_tube/services/database_service.dart';
import 'package:safe_tube/services/catalog_rotator_service.dart';
import 'package:safe_tube/services/youtube_explorer_service.dart';
import 'package:safe_tube/models/followed_channel.dart';
import 'package:safe_tube/models/video_item.dart';

class MockYouTubeExplorerService extends YouTubeExplorerService {
  final Map<String, YouTubeChannelResult> channelResults;

  MockYouTubeExplorerService({required this.channelResults});

  @override
  Future<YouTubeChannelResult?> getChannelVideos(String channelInput, {int limit = 40}) async {
    return channelResults[channelInput];
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('Followed Channels and CatalogRotatorService Tests', () {
    late Database db;
    late DatabaseService dbService;

    setUp(() async {
      db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
      dbService = await DatabaseService.createTestInstance(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('persists, retrieves, and removes followed channels', () async {
      final channel = const FollowedChannel(
        channelId: 'UC123',
        title: 'Peppa Pig Official',
        handle: '@peppapig',
        logoUrl: 'https://img.com/peppa.jpg',
      );

      await dbService.saveFollowedChannel(channel);
      final list = await dbService.getFollowedChannels();

      expect(list.length, equals(1));
      expect(list.first.handle, equals('@peppapig'));
      expect(list.first.title, equals('Peppa Pig Official'));

      await dbService.removeFollowedChannel('UC123');
      final afterRemove = await dbService.getFollowedChannels();
      expect(afterRemove.isEmpty, isTrue);
    });

    test('fetchFreshChannelVideos filters existing and tombstoned videos', () async {
      final channel = const FollowedChannel(
        channelId: 'UC123',
        title: 'Peppa Pig Official',
        handle: '@peppapig',
      );
      await dbService.saveFollowedChannel(channel);

      // Existing video in catalog
      await dbService.upsertVideo(VideoItem(
        id: 'vid_existing',
        title: 'Existing Video',
        categoryId: 'cartoons',
        streamUrl: 'https://example.com/1.mp4',
        thumbnailUrl: 'https://example.com/1.jpg',
      ));

      // Tombstoned video (deleted previously by parent)
      await dbService.deleteVideos(['vid_deleted']);

      final mockChannelResult = YouTubeChannelResult(
        channel: const YouTubeChannelInfo(id: 'UC123', title: 'Peppa Pig Official'),
        videos: const [
          YouTubeSearchResult(
            id: 'vid_existing',
            title: 'Existing Video',
            channelName: 'Peppa Pig',
            channelId: 'UC123',
            thumbnailUrl: 'https://img.com/existing.jpg',
            isShort: false,
          ),
          YouTubeSearchResult(
            id: 'vid_deleted',
            title: 'Deleted Video',
            channelName: 'Peppa Pig',
            channelId: 'UC123',
            thumbnailUrl: 'https://img.com/deleted.jpg',
            isShort: false,
          ),
          YouTubeSearchResult(
            id: 'vid_fresh_1',
            title: 'Fresh Video 1',
            channelName: 'Peppa Pig',
            channelId: 'UC123',
            thumbnailUrl: 'https://img.com/fresh1.jpg',
            isShort: false,
          ),
          YouTubeSearchResult(
            id: 'vid_fresh_2',
            title: 'Fresh Video 2',
            channelName: 'Peppa Pig',
            channelId: 'UC123',
            thumbnailUrl: 'https://img.com/fresh2.jpg',
            isShort: false,
          ),
        ],
      );

      final mockExplorer = MockYouTubeExplorerService(
        channelResults: {'@peppapig': mockChannelResult},
      );

      final rotator = CatalogRotatorService(
        db: dbService,
        explorer: mockExplorer,
      );

      final freshVideos = await rotator.fetchFreshChannelVideos(maxPerChannel: 5);

      // Should ONLY contain vid_fresh_1 and vid_fresh_2
      expect(freshVideos.length, equals(2));
      expect(freshVideos.map((v) => v.id).toSet(), equals({'vid_fresh_1', 'vid_fresh_2'}));
      expect(freshVideos.first.channelName, equals('Peppa Pig'));
    });
  });
}
