import '../models/video_item.dart';
import 'recommendation_service.dart';

/// Evaluates child engagement metrics for catalog videos to identify
/// highly-loved content vs stale, unwatched, or repeatedly skipped content.
class EngagementScoreService {
  /// Calculates a continuous engagement score for a video.
  /// Higher score = loved content.
  /// Lower score = candidate for rotation/pruning.
  /// Returns [double.infinity] if the video is protected (favorite, downloaded, or pinned).
  static double calculateEngagementScore({
    required VideoItem video,
    VideoWatchMetric? metric,
    bool isFavorite = false,
    bool isDownloaded = false,
    bool isPinned = false,
    int? nowEpochMs,
  }) {
    // Protected items must never be candidate for pruning
    if (isFavorite || isDownloaded || isPinned) {
      return double.infinity;
    }

    final now = nowEpochMs ?? DateTime.now().millisecondsSinceEpoch;
    double score = 100.0;

    if (metric == null || metric.watchCount == 0) {
      // Unwatched video: base score remains stable for first 14 days,
      // but decays slowly after 14 days of being in catalog without engagement.
      return score;
    }

    // Positive indicators
    score += (metric.completedCount * 25.0);
    score += (metric.totalSeconds / 60.0); // +1.0 per minute watched

    // Negative indicators
    // Videos skipped early (< 15 seconds) heavily penalized
    score -= (metric.skippedCount * 30.0);

    // Recency penalty if watched long ago without recent repeat
    if (metric.lastWatchedAt > 0) {
      final daysSinceLastWatch = (now - metric.lastWatchedAt) / (1000 * 3600 * 24);
      if (daysSinceLastWatch > 30) {
        score -= 15.0;
      }
    }

    return score;
  }

  /// Returns candidate videos ranked for removal (lowest engagement score first).
  /// Excludes any protected videos (favorites, offline downloads, pinned).
  static List<VideoItem> rankVideosForPruning({
    required List<VideoItem> catalog,
    Map<String, VideoWatchMetric> metrics = const {},
    Set<String> favoriteIds = const {},
    Set<String> downloadedIds = const {},
    Set<String> pinnedIds = const {},
    int? nowEpochMs,
    int limit = 20,
  }) {
    final scored = <MapEntry<VideoItem, double>>[];

    for (final video in catalog) {
      final isFav = favoriteIds.contains(video.id);
      final isDown = downloadedIds.contains(video.id);
      final isPin = pinnedIds.contains(video.id);

      final score = calculateEngagementScore(
        video: video,
        metric: metrics[video.id],
        isFavorite: isFav,
        isDownloaded: isDown,
        isPinned: isPin,
        nowEpochMs: nowEpochMs,
      );

      // Filter out protected items
      if (score != double.infinity) {
        scored.add(MapEntry(video, score));
      }
    }

    // Sort ascending: lowest engagement scores first (worst performing)
    scored.sort((a, b) => a.value.compareTo(b.value));

    return scored.take(limit).map((e) => e.key).toList();
  }
}
