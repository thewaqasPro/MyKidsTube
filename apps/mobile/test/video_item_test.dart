import 'package:flutter_test/flutter_test.dart';
import 'package:safe_tube/models/video_item.dart';

void main() {
  group('VideoItem Model & Domain Logic Tests', () {
    test('Standard YouTube watch URL is never treated as a short', () {
      final video = VideoItem(
        id: 'vid1',
        title: 'Regular Landscape Cartoon',
        categoryId: 'cartoons',
        streamUrl: 'https://cdn.example.com/stream.mp4',
        thumbnailUrl: 'https://cdn.example.com/thumb.jpg',
        sourceUrl: 'https://www.youtube.com/watch?v=abc12345',
        duration: 45, // Even if under 70s, watch?v= makes it landscape
      );

      expect(video.isShort, isFalse);
    });

    test('Video longer than 70 seconds is never treated as a short', () {
      final video = VideoItem(
        id: 'short_prefix_long',
        title: 'Long Episode with Short Prefix',
        categoryId: 'shorts',
        streamUrl: 'https://cdn.example.com/stream.mp4',
        thumbnailUrl: 'https://cdn.example.com/thumb.jpg',
        sourceUrl: 'https://youtube.com/shorts/abc12345',
        duration: 120, // > 70s
      );

      expect(video.isShort, isFalse);
    });

    test('Shorts URL format and valid duration correctly qualifies as a short', () {
      final video = VideoItem(
        id: 'v_short_valid',
        title: 'Quick Animal Dance',
        categoryId: 'fun',
        streamUrl: 'https://cdn.example.com/stream.mp4',
        thumbnailUrl: 'https://cdn.example.com/thumb.jpg',
        sourceUrl: 'https://www.youtube.com/shorts/xyz987',
        duration: 35,
      );

      expect(video.isShort, isTrue);
      expect(video.effectiveYoutubeId, 'xyz987');
    });

    test('Video with short_ ID prefix qualifies as a short when duration <= 70', () {
      final video = VideoItem(
        id: 'short_magicDance',
        title: 'Magic Dance',
        categoryId: 'cartoons',
        streamUrl: 'https://cdn.example.com/stream.mp4',
        thumbnailUrl: 'https://cdn.example.com/thumb.jpg',
        duration: 25,
      );

      expect(video.isShort, isTrue);
      expect(video.effectiveYoutubeId, 'magicDance');
    });

    test('isOfflineReady requires downloaded status and non-empty localFilePath', () {
      final onlineVideo = VideoItem(
        id: 'v_online',
        title: 'Online Video',
        categoryId: 'cartoons',
        streamUrl: 'https://cdn.example.com/stream.mp4',
        thumbnailUrl: 'https://cdn.example.com/thumb.jpg',
        downloadStatus: DownloadStatus.notDownloaded,
        localFilePath: null,
      );
      expect(onlineVideo.isOfflineReady, isFalse);

      final downloadedVideo = onlineVideo.copyWith(
        downloadStatus: DownloadStatus.downloaded,
        localFilePath: '/data/user/0/app/media/v_online.mp4',
      );
      expect(downloadedVideo.isOfflineReady, isTrue);
    });

    test('toMap and fromMap serialize and deserialize correctly', () {
      final original = VideoItem(
        id: 'v_test_map',
        title: 'Test Serialization',
        duration: 180,
        durationFormatted: '03:00',
        categoryId: 'learning',
        sourceUrl: 'https://youtube.com/watch?v=test1234',
        streamUrl: 'https://cdn.example.com/test.mp4',
        thumbnailUrl: 'https://cdn.example.com/test.jpg',
        channelName: 'Teacher Dan',
        youtubeId: 'test1234',
        fileSizeBytes: 10485760,
      );

      final map = original.toMap();
      final reconstructed = VideoItem.fromMap(map);
      expect(reconstructed, isNotNull);

      expect(reconstructed!.id, original.id);
      expect(reconstructed.title, original.title);
      expect(reconstructed.duration, original.duration);
      expect(reconstructed.categoryId, original.categoryId);
      expect(reconstructed.channelName, original.channelName);
      expect(reconstructed.youtubeId, original.youtubeId);
      expect(reconstructed.fileSizeBytes, original.fileSizeBytes);
    });
  });
}
