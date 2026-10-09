import 'package:flutter_test/flutter_test.dart';
import 'package:safe_tube/models/video_item.dart';
import 'package:safe_tube/services/recommendation_service.dart';

void main() {
  group('RecommendationService Unit Tests', () {
    final now = DateTime.now().millisecondsSinceEpoch;

    final videoA = VideoItem(
      id: 'v_unseen',
      title: 'Peppa Pig Fun Park Adventure',
      youtubeId: 'yt1',
      categoryId: 'cartoons',
      streamUrl: 'https://stream.example/1',
      thumbnailUrl: 'https://thumb.example/1.jpg',
      sourceUrl: 'https://www.youtube.com/watch?v=yt1',
      duration: 300,
    );

    final videoB = VideoItem(
      id: 'v_watched_recently',
      title: 'Peppa Pig Bedtime Story',
      youtubeId: 'yt2',
      categoryId: 'cartoons',
      streamUrl: 'https://stream.example/2',
      thumbnailUrl: 'https://thumb.example/2.jpg',
      sourceUrl: 'https://www.youtube.com/watch?v=yt2',
      duration: 320,
    );

    final videoC = VideoItem(
      id: 'v_other_cat',
      title: 'Math Numbers and Shapes',
      youtubeId: 'yt3',
      categoryId: 'learning',
      streamUrl: 'https://stream.example/3',
      thumbnailUrl: 'https://thumb.example/3.jpg',
      sourceUrl: 'https://www.youtube.com/watch?v=yt3',
      duration: 400,
    );

    final videoShort = VideoItem(
      id: 'short_bear',
      title: 'Dancing Bear Short',
      youtubeId: 'yt4',
      categoryId: 'cartoons',
      streamUrl: 'https://stream.example/4',
      thumbnailUrl: 'https://thumb.example/4.jpg',
      sourceUrl: 'https://youtube.com/shorts/yt4',
      duration: 35,
    );

    test('Unseen videos receive novelty boost over recently watched videos', () {
      final metrics = {
        'v_watched_recently': VideoWatchMetric(
          categoryId: 'cartoons',
          lastWatchedAt: now - const Duration(hours: 2).inMilliseconds,
          watchCount: 3,
          completedCount: 2,
          skippedCount: 0,
          totalSeconds: 640,
        ),
      };

      final scoreUnseen = RecommendationService.calculateScore(
        candidate: videoA,
        metric: metrics['v_unseen'],
        nowEpochMs: now,
      );

      final scoreWatched = RecommendationService.calculateScore(
        candidate: videoB,
        metric: metrics['v_watched_recently'],
        nowEpochMs: now,
      );

      // Unseen should receive +45 novelty boost while recently watched receives -55 fatigue penalty
      expect(scoreUnseen, greaterThan(scoreWatched));
    });

    test('Category matching and title token overlap increase recommendation score', () {
      final scoreRelated = RecommendationService.calculateScore(
        candidate: videoA,
        currentVideo: videoB,
        nowEpochMs: now,
      );

      final scoreUnrelated = RecommendationService.calculateScore(
        candidate: videoC,
        currentVideo: videoB,
        nowEpochMs: now,
      );

      // videoA shares 'cartoons' category and 'Peppa', 'Pig' tokens with videoB
      expect(scoreRelated, greaterThan(scoreUnrelated));
    });

    test('Favorite videos and preferred category videos receive positive weight boosts', () {
      final baseScore = RecommendationService.calculateScore(
        candidate: videoC,
        nowEpochMs: now,
      );

      final favScore = RecommendationService.calculateScore(
        candidate: videoC,
        favoriteVideoIds: {'v_other_cat'},
        nowEpochMs: now,
      );

      final preferredScore = RecommendationService.calculateScore(
        candidate: videoC,
        preferredCategoryIds: ['learning'],
        nowEpochMs: now,
      );

      expect(favScore, greaterThan(baseScore));
      expect(preferredScore, greaterThan(baseScore));
    });

    test('getRecommendationsForVideo excludes the current playing video and shorts', () {
      final catalog = [videoA, videoB, videoC, videoShort];

      final recs = RecommendationService.getRecommendationsForVideo(
        currentVideo: videoA,
        catalog: catalog,
      );

      // currentVideo videoA must not be in the recommendations
      expect(recs.any((v) => v.id == videoA.id), isFalse);
      // shorts must not appear in standard landscape / player playlist recommendations
      expect(recs.any((v) => v.isShort), isFalse);
    });

    test('getRecommendationsForVideo respects filterCategory when specified', () {
      final catalog = [videoA, videoB, videoC];

      final learningRecs = RecommendationService.getRecommendationsForVideo(
        currentVideo: videoA,
        catalog: catalog,
        filterCategory: 'learning',
      );

      expect(learningRecs.length, equals(1));
      expect(learningRecs.first.id, equals('v_other_cat'));
    });

    test('getPersonalizedFeed filters out shorts for main feed and respects search', () {
      final catalog = [videoA, videoB, videoC, videoShort];

      final feed = RecommendationService.getPersonalizedFeed(
        catalog: catalog,
        searchQuery: 'Peppa',
        isShort: false,
      );

      expect(feed.every((v) => !v.isShort), isTrue);
      expect(feed.every((v) => v.title.contains('Peppa')), isTrue);
    });

    test('getPersonalizedFeed supports isShort: true for dedicated shorts feed', () {
      final catalog = [videoA, videoB, videoC, videoShort];

      final shortsFeed = RecommendationService.getPersonalizedFeed(
        catalog: catalog,
        isShort: true,
      );

      expect(shortsFeed.length, equals(1));
      expect(shortsFeed.first.id, equals('short_bear'));
    });

    test('Session seeds produce non-static jitter variance', () {
      final list1 = List.generate(
        15,
        (i) => VideoItem(
          id: 'v_$i',
          title: 'Video Title $i',
          youtubeId: 'yt_$i',
          categoryId: 'cartoons',
          streamUrl: 'https://stream.example/$i',
          thumbnailUrl: 'https://thumb.example/$i.jpg',
          sourceUrl: 'https://www.youtube.com/watch?v=yt_$i',
          duration: 200,
        ),
      );

      final feedSeed1 = RecommendationService.getPersonalizedFeed(
        catalog: list1,
        sessionSeed: 101,
      );

      final feedSeed2 = RecommendationService.getPersonalizedFeed(
        catalog: list1,
        sessionSeed: 9999,
      );

      final ids1 = feedSeed1.map((v) => v.id).toList();
      final ids2 = feedSeed2.map((v) => v.id).toList();

      // Different seeds should produce varied ordering among equal-scoring candidate items
      expect(ids1, isNot(equals(ids2)));
    });
  });
}
