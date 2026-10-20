import 'package:flutter_test/flutter_test.dart';
import 'package:safe_tube/models/video_item.dart';
import 'package:safe_tube/providers/app_provider.dart';
import 'package:safe_tube/widgets/kid_embed_player.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Skip Intro & Branding Feature Tests', () {
    test('Default configuration enables intro skip on long videos and disables on shorts', () {
      final provider = AppProvider();
      expect(provider.skipIntroLongVideos, isTrue);
      expect(provider.skipIntroShorts, isFalse);
      expect(provider.skipIntroSeconds, equals(5));
    });

    test('getStartSecondsFor returns 5s for long videos by default', () {
      final provider = AppProvider();
      final longVideo = VideoItem(
        id: 'long_1',
        title: 'Cocomelon Long Video',
        categoryId: 'cartoons',
        channelName: 'Cocomelon',
        thumbnailUrl: 'https://img.youtube.com/vi/long_1/hqdefault.jpg',
        streamUrl: 'https://youtube.com/watch?v=long_1',
        sourceUrl: 'https://youtube.com/watch?v=long_1',
        duration: 180,
      );

      expect(longVideo.isShort, isFalse);
      final startSec = provider.getStartSecondsFor(longVideo);
      expect(startSec, equals(5));
    });

    test('getStartSecondsFor returns 0s for shorts by default', () {
      final provider = AppProvider();
      final shortVideo = VideoItem(
        id: 'short_1',
        title: 'Fun Short Clip',
        categoryId: 'shorts',
        channelName: 'FunChannel',
        thumbnailUrl: 'https://img.youtube.com/vi/short_1/hqdefault.jpg',
        streamUrl: 'https://youtube.com/shorts/short_1',
        sourceUrl: 'https://youtube.com/shorts/short_1',
        duration: 45,
      );

      expect(shortVideo.isShort, isTrue);
      final startSec = provider.getStartSecondsFor(shortVideo);
      expect(startSec, equals(0));
    });

    test('Toggling skipIntroShorts enables intro skipping on shorts', () {
      final provider = AppProvider();
      provider.setSkipIntroShorts(true);
      expect(provider.skipIntroShorts, isTrue);

      final shortVideo = VideoItem(
        id: 'short_2',
        title: 'Fun Short Clip 2',
        categoryId: 'shorts',
        channelName: 'FunChannel',
        thumbnailUrl: 'https://img.youtube.com/vi/short_2/hqdefault.jpg',
        streamUrl: 'https://youtube.com/shorts/short_2',
        sourceUrl: 'https://youtube.com/shorts/short_2',
        duration: 45,
      );

      expect(shortVideo.isShort, isTrue);
      expect(provider.getStartSecondsFor(shortVideo), equals(5));
    });

    test('Toggling skipIntroLongVideos off disables intro skipping on long videos', () {
      final provider = AppProvider();
      provider.setSkipIntroLongVideos(false);
      expect(provider.skipIntroLongVideos, isFalse);

      final longVideo = VideoItem(
        id: 'long_2',
        title: 'Bedtime Rhymes',
        categoryId: 'rhymes',
        channelName: 'KidsChannel',
        thumbnailUrl: 'https://img.youtube.com/vi/long_2/hqdefault.jpg',
        streamUrl: 'https://youtube.com/watch?v=long_2',
        sourceUrl: 'https://youtube.com/watch?v=long_2',
        duration: 300,
      );

      expect(longVideo.isShort, isFalse);
      expect(provider.getStartSecondsFor(longVideo), equals(0));
    });

    test('Custom skip duration updates return value', () {
      final provider = AppProvider();
      provider.setSkipIntroSeconds(8);
      expect(provider.skipIntroSeconds, equals(8));

      final longVideo = VideoItem(
        id: 'long_3',
        title: 'Nursery Rhyme',
        categoryId: 'rhymes',
        channelName: 'KidsChannel',
        thumbnailUrl: 'https://img.youtube.com/vi/long_3/hqdefault.jpg',
        streamUrl: 'https://youtube.com/watch?v=long_3',
        sourceUrl: 'https://youtube.com/watch?v=long_3',
        duration: 120,
      );

      expect(provider.getStartSecondsFor(longVideo), equals(8));
    });

    test('Video with duration too short does not skip to avoid clipping entire content', () {
      final provider = AppProvider();
      final ultraShortVideo = VideoItem(
        id: 'long_tiny',
        title: 'Tiny Clip',
        categoryId: 'clips',
        channelName: 'KidsChannel',
        thumbnailUrl: 'https://img.youtube.com/vi/long_tiny/hqdefault.jpg',
        streamUrl: 'https://youtube.com/watch?v=long_tiny',
        sourceUrl: 'https://youtube.com/watch?v=long_tiny',
        duration: 6, // 6s <= 5s + 2s
      );

      expect(provider.getStartSecondsFor(ultraShortVideo), equals(0));
    });

    test('KidEmbedPlayer.buildEmbedHtml embeds &start=5 and seekTo(5) correctly', () {
      final html = KidEmbedPlayer.buildEmbedHtml(
        youtubeId: 'abc12345',
        autoPlay: true,
        isMuted: false,
        currentPlaybackSeconds: 5.0,
      );

      expect(html.contains('&start=5'), isTrue);
      expect(html.contains('event.target.seekTo(5, true);'), isTrue);
    });

    test('KidEmbedPlayer.buildEmbedHtml does not add &start when currentPlaybackSeconds is 0', () {
      final html = KidEmbedPlayer.buildEmbedHtml(
        youtubeId: 'abc12345',
        autoPlay: true,
        isMuted: false,
        currentPlaybackSeconds: 0.0,
      );

      expect(html.contains('&start='), isFalse);
      expect(html.contains('event.target.seekTo('), isFalse);
    });
  });
}
