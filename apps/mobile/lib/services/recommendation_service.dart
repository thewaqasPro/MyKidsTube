import 'dart:math';
import '../models/video_item.dart';

/// Aggregated watch metrics for a single video used by the recommendation engine
class VideoWatchMetric {
  final int lastWatchedAt;
  final int watchCount;
  final int completedCount;
  final int skippedCount;
  final int totalSeconds;
  final String categoryId;

  const VideoWatchMetric({
    this.lastWatchedAt = 0,
    this.watchCount = 0,
    this.completedCount = 0,
    this.skippedCount = 0,
    this.totalSeconds = 0,
    this.categoryId = '',
  });

  factory VideoWatchMetric.fromMap(Map<String, dynamic> map) {
    return VideoWatchMetric(
      lastWatchedAt: map['last_watched_at'] as int? ?? 0,
      watchCount: map['watch_count'] as int? ?? 0,
      completedCount: map['completed_count'] as int? ?? 0,
      skippedCount: map['skipped_count'] as int? ?? 0,
      totalSeconds: map['total_seconds'] as int? ?? 0,
      categoryId: map['category_id'] as String? ?? '',
    );
  }
}

/// Smart, local-first Recommendation Engine (SKRE) for KidsTube
/// Calculates dynamic relevance, novelty boost, fatigue decay, and fresh rotation.
class RecommendationService {
  static final Set<String> _stopWords = {
    'the', 'a', 'an', 'and', 'or', 'in', 'on', 'at', 'to', 'for', 'of', 'with',
    'is', 'are', 'was', 'were', 'it', 'its', 'video', 'episode', 'part', 'season',
    'kids', 'rhyme', 'rhymes', 'song', 'songs', 'official', 'hd', 'full'
  };

  /// Tokenizes a video title into clean alphanumeric search terms for topic affinity
  static Set<String> extractKeywords(String title) {
    final clean = title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9\s]'), ' ');
    final tokens = clean.split(RegExp(r'\s+')).where((t) => t.length >= 3 && !_stopWords.contains(t));
    return tokens.toSet();
  }

  /// Calculates dynamic score for a single candidate video
  static double calculateScore({
    required VideoItem candidate,
    VideoItem? currentVideo,
    VideoWatchMetric? metric,
    Set<String> favoriteVideoIds = const {},
    List<String> preferredCategoryIds = const [],
    int? nowEpochMs,
    int sessionSeed = 0,
  }) {
    double score = 50.0;
    final now = nowEpochMs ?? DateTime.now().millisecondsSinceEpoch;

    // 1. Contextual Similarity (when watching a specific video)
    if (currentVideo != null) {
      if (candidate.categoryId.isNotEmpty && candidate.categoryId == currentVideo.categoryId) {
        score += 40.0;
      }

      // Keyword token overlap between current title and candidate title
      final currentTokens = extractKeywords(currentVideo.title);
      final candidateTokens = extractKeywords(candidate.title);
      final overlap = currentTokens.intersection(candidateTokens).length;
      if (overlap > 0) {
        score += min(overlap * 12.0, 36.0);
      }
    }

    // 2. Child Affinity (preferred categories based on watch history)
    if (candidate.categoryId.isNotEmpty && preferredCategoryIds.contains(candidate.categoryId)) {
      score += 20.0;
    }

    // 3. Favorite Boost
    if (favoriteVideoIds.contains(candidate.id)) {
      score += 15.0;
    }

    // 4. Novelty & Fatigue Decay
    if (metric == null || metric.watchCount == 0) {
      // High novelty boost: Child has NEVER watched this video
      score += 45.0;
    } else {
      final hoursSinceLastWatch = (now - metric.lastWatchedAt) / (1000 * 3600);

      if (hoursSinceLastWatch < 12) {
        // Watched recently today: heavy fatigue penalty to ensure variety
        score -= 55.0;
      } else if (hoursSinceLastWatch < 48) {
        // Watched in last two days: moderate penalty
        score -= 30.0;
      } else if (hoursSinceLastWatch < 168) {
        // Watched in last week: slight penalty
        score -= 15.0;
      }

      // Penalize skipped videos (less than 10s watch time)
      if (metric.skippedCount > metric.completedCount) {
        score -= 20.0;
      }
    }

    // 5. Session Jitter (Deterministic pseudorandom variance per session seed)
    // Prevents identical static order on consecutive viewings while honoring score tiers
    final jitterHash = (candidate.id.hashCode ^ sessionSeed).abs();
    final jitter = (jitterHash % 1500) / 100.0; // 0.0 to 15.0 pts
    score += jitter;

    return score;
  }

  /// Returns recommended videos for the player screen ("More for Kids" bar & landscape playlist)
  static List<VideoItem> getRecommendationsForVideo({
    required VideoItem currentVideo,
    required List<VideoItem> catalog,
    Map<String, VideoWatchMetric> metrics = const {},
    Set<String> favoriteVideoIds = const {},
    List<String> preferredCategoryIds = const [],
    String? filterCategory,
    int sessionSeed = 0,
    int limit = 25,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;

    // Filter out the currently playing video and shorts
    var candidates = catalog.where((v) => v.id != currentVideo.id && !v.isShort);

    // Apply explicit category filter if selected by child/parent
    if (filterCategory != null && filterCategory.isNotEmpty && filterCategory != 'all') {
      candidates = candidates.where((v) => v.categoryId == filterCategory);
    }

    final scored = candidates.map((item) {
      final metric = metrics[item.id];
      final score = calculateScore(
        candidate: item,
        currentVideo: currentVideo,
        metric: metric,
        favoriteVideoIds: favoriteVideoIds,
        preferredCategoryIds: preferredCategoryIds,
        nowEpochMs: now,
        sessionSeed: sessionSeed,
      );
      return MapEntry(item, score);
    }).toList();

    // Sort descending by calculated score
    scored.sort((a, b) => b.value.compareTo(a.value));

    return scored.take(limit).map((e) => e.key).toList();
  }

  /// Returns personalized, dynamically rotated videos for the Home screen feed
  static List<VideoItem> getPersonalizedFeed({
    required List<VideoItem> catalog,
    Map<String, VideoWatchMetric> metrics = const {},
    Set<String> favoriteVideoIds = const {},
    List<String> preferredCategoryIds = const [],
    String? categoryId,
    String? searchQuery,
    bool? isShort,
    int sessionSeed = 0,
    int limit = 60,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;

    var candidates = catalog.where((v) {
      if (isShort != null) {
        return v.isShort == isShort;
      }
      return !v.isShort;
    });

    if (categoryId != null && categoryId.isNotEmpty && categoryId != 'all') {
      candidates = candidates.where((v) => v.categoryId == categoryId);
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = searchQuery.trim().toLowerCase();
      candidates = candidates.where((v) => v.title.toLowerCase().contains(q));
    }

    final scored = candidates.map((item) {
      final metric = metrics[item.id];
      final score = calculateScore(
        candidate: item,
        currentVideo: null,
        metric: metric,
        favoriteVideoIds: favoriteVideoIds,
        preferredCategoryIds: preferredCategoryIds,
        nowEpochMs: now,
        sessionSeed: sessionSeed,
      );
      return MapEntry(item, score);
    }).toList();

    scored.sort((a, b) => b.value.compareTo(a.value));

    return scored.take(limit).map((e) => e.key).toList();
  }
}
