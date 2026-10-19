import 'dart:math';
import '../models/video_item.dart';

/// Manages an infinite, non-repeating, category-balanced round-robin video queue.
///
/// Prevents repetitive playback for kids by enforcing a cycle deck (exhaustion deck)
/// where all pool items are played before repeating, category balancing across draws,
/// and a dynamic FIFO history avoidance buffer across cycle boundaries.
class InfiniteVideoQueue {
  final List<VideoItem> _pool;
  final List<VideoItem> _queue = [];
  final List<String> _historyBuffer = [];
  final List<VideoItem> _cycleDeck = [];
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

  /// Buffer capacity: scales dynamically with pool size to avoid recent repeats.
  int get _historyCapacity {
    if (_pool.length <= 1) return 0;
    if (_pool.length <= 3) return 1;
    // Scale up to 40% of pool size (min 2, max 50)
    final cap = (_pool.length * 0.4).floor();
    return cap.clamp(2, 50);
  }

  void _initialize(VideoItem? initialVideo) {
    if (_pool.isEmpty && initialVideo == null) return;

    _replenishCycleDeck();

    if (initialVideo != null) {
      _queue.add(initialVideo);
      _recordHistory(initialVideo.id);
      _cycleDeck.removeWhere((v) => v.id == initialVideo.id);
    }

    _generateBatch(batchSize: 15);
  }

  void _replenishCycleDeck() {
    _cycleDeck.clear();
    _cycleDeck.addAll(_pool);
    _cycleDeck.shuffle(_random);
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
    _replenishCycleDeck();

    // Remove any items that are in the immediate recent history buffer
    _cycleDeck.removeWhere((v) => _historyBuffer.contains(v.id));
    if (_cycleDeck.isEmpty) {
      _replenishCycleDeck();
    }

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

    for (int i = 0; i < batchSize; i++) {
      if (_cycleDeck.isEmpty) {
        _replenishCycleDeck();
      }

      // Group available deck items by category
      final Map<String, List<VideoItem>> byCategory = {};
      for (final v in _cycleDeck) {
        final cat = (v.categoryId.isEmpty ? 'default' : v.categoryId);
        byCategory.putIfAbsent(cat, () => []).add(v);
      }

      final categories = byCategory.keys.toList()..shuffle(_random);
      VideoItem? chosen;

      // 1. Try category-balanced pick from cycle deck avoiding recent history
      for (final cat in categories) {
        final candidates = byCategory[cat]!
            .where((v) => !_historyBuffer.contains(v.id))
            .toList();
        if (candidates.isNotEmpty) {
          chosen = candidates[_random.nextInt(candidates.length)];
          break;
        }
      }

      // 2. If all deck items in each category are in history, pick any deck item
      if (chosen == null && _cycleDeck.isNotEmpty) {
        final candidates = _cycleDeck.where((v) => !_historyBuffer.contains(v.id)).toList();
        if (candidates.isNotEmpty) {
          chosen = candidates[_random.nextInt(candidates.length)];
        } else {
          chosen = _cycleDeck[_random.nextInt(_cycleDeck.length)];
        }
      }

      // 3. Fallback (safety guard)
      chosen ??= _pool[_random.nextInt(_pool.length)];

      _queue.add(chosen);
      _recordHistory(chosen.id);
      _cycleDeck.removeWhere((v) => v.id == chosen!.id);
    }
  }
}
