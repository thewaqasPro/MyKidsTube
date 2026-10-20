import '../models/video_item.dart';
import '../models/followed_channel.dart';
import 'database_service.dart';
import 'youtube_explorer_service.dart';

/// Service responsible for fetching fresh uploads from followed channels,
/// avoiding previously deleted videos (tombstones) and existing catalog items.
class CatalogRotatorService {
  final DatabaseService _db;
  final YouTubeExplorerService _explorer;

  CatalogRotatorService({
    DatabaseService? db,
    YouTubeExplorerService? explorer,
  })  : _db = db ?? DatabaseService(),
        _explorer = explorer ?? YouTubeExplorerService();

  /// Fetches fresh videos from all active followed channels.
  /// Skips videos that already exist in the database or have been tombstoned in deleted_videos.
  Future<List<VideoItem>> fetchFreshChannelVideos({
    int maxPerChannel = 5,
    String defaultCategory = 'cartoons',
    String profileId = 'kids_all',
  }) async {
    final channels = await _db.getFollowedChannels();
    final activeChannels = channels.where((c) => c.autoSync).toList();
    if (activeChannels.isEmpty) return [];

    final existingVideos = await _db.getAllVideos();
    final existingIds = existingVideos.map((v) => v.id).toSet();
    final deletedIds = await _db.getDeletedVideoIds();

    final freshVideos = <VideoItem>[];
    final now = DateTime.now().millisecondsSinceEpoch;

    for (final channel in activeChannels) {
      try {
        final query = channel.handle.isNotEmpty ? channel.handle : channel.channelId;
        final channelResult = await _explorer.getChannelVideos(query, limit: maxPerChannel * 3);
        if (channelResult == null || channelResult.videos.isEmpty) continue;

        int addedForThisChannel = 0;
        for (final item in channelResult.videos) {
          if (addedForThisChannel >= maxPerChannel) break;
          // Filter out existing and deleted videos
          if (existingIds.contains(item.id) || deletedIds.contains(item.id)) {
            continue;
          }

          final video = item.toVideoItem(
            categoryId: defaultCategory,
            profileId: profileId,
          );
          freshVideos.add(video);
          existingIds.add(video.id); // Prevent duplicate within same sync batch
          addedForThisChannel++;
        }

        await _db.updateChannelLastSynced(channel.channelId, now);
      } catch (_) {}
    }

    return freshVideos;
  }
}
