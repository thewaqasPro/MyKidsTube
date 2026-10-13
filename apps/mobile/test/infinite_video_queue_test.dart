import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:safe_tube/models/video_item.dart';
import 'package:safe_tube/services/infinite_video_queue.dart';

VideoItem _makeVideo(String id, {String cat = 'catA'}) {
  return VideoItem(
    id: id,
    title: 'Video $id',
    thumbnailUrl: 'https://example.com/$id.jpg',
    streamUrl: 'https://example.com/$id.mp4',
    quality: '1080p',
    duration: 120,
    categoryId: cat,
  );
}

void main() {
  group('InfiniteVideoQueue Tests', () {
    test('initializes with seed video and generates initial batch', () {
      final pool = List.generate(10, (i) => _makeVideo('v$i'));
      final seed = _makeVideo('seed');
      final queue = InfiniteVideoQueue(pool: pool, initialVideo: seed);

      expect(queue.length, greaterThanOrEqualTo(15));
      expect(queue[0].id, equals('seed'));
    });

    test('dynamically expands when ensureCapacity threshold reached', () {
      final pool = List.generate(8, (i) => _makeVideo('v$i'));
      final queue = InfiniteVideoQueue(pool: pool);
      final initialLength = queue.length;

      // When index is far from tail, no extra items added
      queue.ensureCapacity(2);
      expect(queue.length, equals(initialLength));

      // When index gets close to tail, batch is appended
      queue.ensureCapacity(initialLength - 2, batchSize: 10);
      expect(queue.length, equals(initialLength + 10));
    });

    test('prevents immediate consecutive repetition with history buffer', () {
      final pool = List.generate(6, (i) => _makeVideo('v$i'));
      final queue = InfiniteVideoQueue(pool: pool, random: Random(42));

      // Check no 2 consecutive items have the exact same ID
      for (int i = 0; i < queue.length - 1; i++) {
        expect(queue[i].id, isNot(equals(queue[i + 1].id)));
      }
    });

    test('gracefully handles single video pool', () {
      final single = [_makeVideo('only_one')];
      final queue = InfiniteVideoQueue(pool: single);

      expect(queue.length, greaterThanOrEqualTo(15));
      expect(queue.items.every((v) => v.id == 'only_one'), isTrue);

      queue.ensureCapacity(14, batchSize: 5);
      expect(queue.length, equals(20));
    });

    test('shuffleUpcoming randomizes tail without affecting past/current items', () {
      final pool = List.generate(15, (i) => _makeVideo('v$i'));
      final queue = InfiniteVideoQueue(pool: pool, random: Random(123));

      final currentPlaying = queue[3];
      final pastItems = queue.items.sublist(0, 4);

      queue.shuffleUpcoming(3);

      expect(queue[3].id, equals(currentPlaying.id));
      for (int i = 0; i <= 3; i++) {
        expect(queue[i].id, equals(pastItems[i].id));
      }
      expect(queue.length, greaterThan(4));
    });
  });
}
