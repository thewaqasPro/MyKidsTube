import 'package:flutter_test/flutter_test.dart';
import 'package:safe_tube/services/youtube_metadata_service.dart';

void main() {
  group('YouTubeMetadataService Unit Tests', () {
    test('extractVideoId correctly parses all standard YouTube URL formats', () {
      // Standard watch URLs
      expect(
        YouTubeMetadataService.extractVideoId('https://www.youtube.com/watch?v=dQw4w9WgXcQ'),
        equals('dQw4w9WgXcQ'),
      );
      expect(
        YouTubeMetadataService.extractVideoId('https://m.youtube.com/watch?v=dQw4w9WgXcQ&t=42s'),
        equals('dQw4w9WgXcQ'),
      );

      // Short URLs (youtu.be)
      expect(
        YouTubeMetadataService.extractVideoId('https://youtu.be/dQw4w9WgXcQ'),
        equals('dQw4w9WgXcQ'),
      );
      expect(
        YouTubeMetadataService.extractVideoId('https://youtu.be/dQw4w9WgXcQ?si=abc123xyz'),
        equals('dQw4w9WgXcQ'),
      );

      // YouTube Shorts URLs
      expect(
        YouTubeMetadataService.extractVideoId('https://www.youtube.com/shorts/dQw4w9WgXcQ'),
        equals('dQw4w9WgXcQ'),
      );

      // Embed URLs
      expect(
        YouTubeMetadataService.extractVideoId('https://www.youtube.com/embed/dQw4w9WgXcQ'),
        equals('dQw4w9WgXcQ'),
      );

      // Raw 11-character video ID
      expect(
        YouTubeMetadataService.extractVideoId('dQw4w9WgXcQ'),
        equals('dQw4w9WgXcQ'),
      );

      // Invalid inputs
      expect(YouTubeMetadataService.extractVideoId(''), isNull);
      expect(YouTubeMetadataService.extractVideoId('https://google.com'), isNull);
      expect(YouTubeMetadataService.extractVideoId('invalid_id_too_short'), isNull);
    });

    test('isShortUrl accurately detects shorts URLs', () {
      expect(
        YouTubeMetadataService.isShortUrl('https://www.youtube.com/shorts/dQw4w9WgXcQ'),
        isTrue,
      );
      expect(
        YouTubeMetadataService.isShortUrl('https://www.youtube.com/watch?v=dQw4w9WgXcQ#shorts'),
        isTrue,
      );
      expect(
        YouTubeMetadataService.isShortUrl('https://www.youtube.com/watch?v=dQw4w9WgXcQ'),
        isFalse,
      );
      expect(
        YouTubeMetadataService.isShortUrl('https://youtu.be/dQw4w9WgXcQ'),
        isFalse,
      );
    });

    test('YouTubeMetadata converts to VideoItem correctly for standalone mode', () {
      const meta = YouTubeMetadata(
        id: 'dQw4w9WgXcQ',
        title: 'Never Gonna Give You Up',
        authorName: 'Rick Astley',
        thumbnailUrl: 'https://i.ytimg.com/vi/dQw4w9WgXcQ/hqdefault.jpg',
        isShort: false,
        sourceUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
      );

      final video = meta.toVideoItem(categoryId: 'music');

      expect(video.id, equals('dQw4w9WgXcQ'));
      expect(video.youtubeId, equals('dQw4w9WgXcQ'));
      expect(video.title, equals('Never Gonna Give You Up'));
      expect(video.channelName, equals('Rick Astley'));
      expect(video.categoryId, equals('music'));
      expect(video.status, equals('embed'));
      expect(video.needsEmbed, isTrue);
      expect(video.isShort, isFalse);
    });
  });
}
