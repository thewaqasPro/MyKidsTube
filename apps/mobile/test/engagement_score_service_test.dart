import 'package:flutter_test/flutter_test.dart';
import 'package:safe_tube/models/video_item.dart';
import 'package:safe_tube/services/recommendation_service.dart';
import 'package:safe_tube/services/engagement_score_service.dart';

VideoItem _makeVideo(String id, {String cat = 'cartoons'}) {
  return VideoItem(
    id: id,
    title: 'Video $id',
    thumbnailUrl: 'https://example.com/$id.jpg',
    streamUrl: 'https://example.com/$id.mp4',
    quality: '720p',
    duration: 120,
    categoryId: cat,
  );
}

void main() {
  group('EngagementScoreService Tests', () {
    test('protects favorite, downloaded, and pinned videos with infinity score', () {
      final v = _makeVideo('fav1');
      final scoreFav = EngagementScoreService.calculateEngagementScore(
        video: v,
        isFavorite: true,
      );
      expect(scoreFav, equals(double.infinity));

      final scoreDown = EngagementScoreService.calculateEngagementScore(
        video: v,
        isDownloaded: true,
      );
      expect(scoreDown, equals(double.infinity));

      final scorePinned = EngagementScoreService.calculateEngagementScore(
        video: v,
        isPinned: true,
      );
      expect(scorePinned, equals(double.infinity));
    });

    test('penalizes frequently skipped videos over watched videos', () {
      final v1 = _makeVideo('skipped_often');
      final v2 = _makeVideo('watched_completed');

      final skippedMetric = const VideoWatchMetric(
        watchCount: 5,
        completedCount: 1,
        skippedCount: 4,
        totalSeconds: 30,
      );

      final completedMetric = const VideoWatchMetric(
        watchCount: 5,
        completedCount: 4,
        skippedCount: 1,
        totalSeconds: 400,
      );

      final scoreSkipped = EngagementScoreService.calculateEngagementScore(
        video: v1,
        metric: skippedMetric,
      );

      final scoreCompleted = EngagementScoreService.calculateEngagementScore(
        video: v2,
        metric: completedMetric,
      );

      expect(scoreSkipped, lessThan(scoreCompleted));
      expect(scoreSkipped, lessThan(80.0));
    });

    test('rankVideosForPruning excludes protected videos and sorts lowest scores first', () {
      final v1 = _makeVideo('disliked');
      final v2 = _makeVideo('favorite');
      final v3 = _makeVideo('downloaded');
      final v4 = _makeVideo('average');

      final metrics = {
        'disliked': const VideoWatchMetric(
          watchCount: 10,
          completedCount: 0,
          skippedCount: 10,
          totalSeconds: 20,
        ),
        'favorite': const VideoWatchMetric(watchCount: 10),
        'downloaded': const VideoWatchMetric(watchCount: 0),
        'average': const VideoWatchMetric(
          watchCount: 3,
          completedCount: 2,
          skippedCount: 1,
          totalSeconds: 180,
        ),
      };

      final candidates = EngagementScoreService.rankVideosForPruning(
        catalog: [v1, v2, v3, v4],
        metrics: metrics,
        favoriteIds: {'favorite'},
        downloadedIds: {'downloaded'},
        limit: 10,
      );

      // Only unprotected items should appear: disliked and average
      expect(candidates.map((c) => c.id).toList(), equals(['disliked', 'average']));
      // Disliked must be ranked FIRST for removal
      expect(candidates.first.id, equals('disliked'));
    });
  });
}
