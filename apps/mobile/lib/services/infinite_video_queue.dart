import 'dart:math';
import '../models/video_item.dart';

/// Manages an infinite, non-repeating, category-balanced round-robin video queue.
///
/// Prevents repetitive playback for kids by enforcing a FIFO history avoidance
/// buffer, cycling across diverse categories, and dynamically appending batches
/// as the user scrolls.
class InfiniteVideoQueue {
  final List<VideoItem> _pool;
  final List<VideoItem> _queue = [];
  final List<String> _historyBuffer = [];
  final Random _random;

  InfiniteVideoQueue({
    required List<VideoItem> pool,
    VideoItem? initialVideo,
    Random? random,
  })  : _pool = List.unmodifiable(pool),
        _random = random ?? Random() {
    _initialize(initialVideo);
  }

  /// Current queue of videos available to the PageView.
  List<VideoItem> get items => List.unmodifiable(_queue);

  /// Total number of items currently materialized in the queue.
  int get length => _queue.length;

  /// Whether the queue contains no items.
  bool get isEmpty => _queue.isEmpty;

  /// Whether the queue contains at least one item.
  bool get isNotEmpty => _queue.isNotEmpty;

  /// Retrieves the video item at the specified index.
  VideoItem operator [](int index) => _queue[index];

  /// Buffer capacity: min 1, up to 10 or half the pool size.
  int get _historyCapacity {
    if (_pool.length <= 1) return 0;
    if (_pool.length <= 3) return 1;
    final half = (_pool.length / 2).floor();
    return half.clamp(2, 10);
  }

  void _initialize(VideoItem? initialVideo) {
    if (_pool.isEmpty && initialVideo == null) return;

    if (initialVideo != null) {
      _queue.add(initialVideo);
      _recordHistory(initialVideo.id);
    }

    _generateBatch(batchSize: 15);
  }

  /// Appends more videos if the current index is close to the queue tail.
  void ensureCapacity(int currentIndex, {int threshold = 4, int batchSize = 10}) {
    if (_pool.isEmpty) return;
    if (currentIndex >= _queue.length - threshold) {
      _generateBatch(batchSize: batchSize);
    }
  }

  /// Re-randomizes upcoming items after [currentIndex] without disrupting currently playing video.
  void shuffleUpcoming(int currentIndex) {
    if (_pool.isEmpty || currentIndex < 0 || currentIndex >= _queue.length) return;

    // Retain history up to current index
    _queue.removeRange(currentIndex + 1, _queue.length);
    _generateBatch(batchSize: 15);
  }

  void _recordHistory(String id) {
    if (_historyCapacity <= 0) return;
    _historyBuffer.add(id);
    while (_historyBuffer.length > _historyCapacity) {
      _historyBuffer.removeAt(0);
    }
  }

  void _generateBatch({required int batchSize}) {
    if (_pool.isEmpty) return;

    // Single item pool edge case
    if (_pool.length == 1) {
      for (int i = 0; i < batchSize; i++) {
        _queue.add(_pool.first);
      }
      return;
    }

    // Group available pool by category
    final Map<String, List<VideoItem>> byCategory = {};
    for (final v in _pool) {
      final cat = (v.categoryId.isEmpty ? 'default' : v.categoryId);
      byCategory.putIfAbsent(cat, () => []).add(v);
    }

    final categories = byCategory.keys.toList()..shuffle(_random);
    int catIndex = 0;

    for (int i = 0; i < batchSize; i++) {
      VideoItem? chosen;

      // Try category-balanced pick first
      for (int attempt = 0; attempt < categories.length; attempt++) {
        final currentCat = categories[(catIndex + attempt) % categories.length];
        final candidatesInCat = byCategory[currentCat]!
            .where((v) => !_historyBuffer.contains(v.id))
            .toList();

        if (candidatesInCat.isNotEmpty) {
          chosen = candidatesInCat[_random.nextInt(candidatesInCat.length)];
          catIndex = (catIndex + attempt + 1) % categories.length;
          break;
        }
      }

      // Fallback: Pick from any item in the pool not in recent history
      if (chosen == null) {
        final anyCandidates = _pool.where((v) => !_historyBuffer.contains(v.id)).toList();
        if (anyCandidates.isNotEmpty) {
          chosen = anyCandidates[_random.nextInt(anyCandidates.length)];
        }
      }

      // If still null because history buffer holds all pool items, pop oldest history
      if (chosen == null) {
        if (_historyBuffer.isNotEmpty) {
          _historyBuffer.removeAt(0);
        }
        final relaxed = _pool.where((v) => !_historyBuffer.contains(v.id)).toList();
        chosen = relaxed.isNotEmpty ? relaxed[_random.nextInt(relaxed.length)] : _pool[_random.nextInt(_pool.length)];
      }

      _queue.add(chosen);
      _recordHistory(chosen.id);
    }
  }
}
