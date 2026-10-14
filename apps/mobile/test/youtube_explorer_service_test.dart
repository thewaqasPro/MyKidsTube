import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:safe_tube/providers/app_provider.dart';
import 'package:safe_tube/services/youtube_explorer_service.dart';
import 'package:safe_tube/screens/parent_youtube_search_screen.dart';

void main() {
  group('YouTubeExplorerService & Model Unit Tests', () {
    test('YouTubeSearchResult converts to VideoItem accurately for long-form video', () {
      final result = YouTubeSearchResult(
        id: 'dQw4w9WgXcQ',
        title: 'Test Video',
        channelName: 'Test Channel',
        channelId: 'UC1234567890',
        duration: const Duration(minutes: 3, seconds: 45),
        thumbnailUrl: 'https://i.ytimg.com/vi/dQw4w9WgXcQ/hqdefault.jpg',
        isShort: false,
      );

      expect(result.durationFormatted, equals('3:45'));

      final video = result.toVideoItem(categoryId: 'cartoons', profileId: 'leo_kid');
      expect(video.id, equals('dQw4w9WgXcQ'));
      expect(video.youtubeId, equals('dQw4w9WgXcQ'));
      expect(video.title, equals('Test Video'));
      expect(video.channelName, equals('Test Channel'));
      expect(video.categoryId, equals('cartoons'));
      expect(video.profileId, equals('leo_kid'));
      expect(video.status, equals('embed'));
      expect(video.streamUrl, equals('https://www.youtube.com/watch?v=dQw4w9WgXcQ'));
      expect(video.durationFormatted, equals('3:45'));
    });

    test('YouTubeSearchResult handles Shorts correctly', () {
      final shortResult = YouTubeSearchResult(
        id: 'abc12345678',
        title: 'Fun Short Reel',
        channelName: 'Kids Shorts',
        channelId: 'UC9876543210',
        duration: const Duration(seconds: 45),
        thumbnailUrl: 'https://i.ytimg.com/vi/abc12345678/hqdefault.jpg',
        isShort: true,
      );

      expect(shortResult.durationFormatted, equals('Short'));

      final video = shortResult.toVideoItem(categoryId: 'learning');
      expect(video.sourceUrl, equals('https://www.youtube.com/shorts/abc12345678'));
      expect(video.durationFormatted, equals('Short'));
    });

    test('YouTubeSearchResult formats zero or null duration gracefully', () {
      final noDurResult = YouTubeSearchResult(
        id: 'xyz12345678',
        title: 'Live Stream or Premiere',
        channelName: 'Live Channel',
        channelId: 'UC111',
        duration: null,
        thumbnailUrl: 'https://i.ytimg.com/vi/xyz12345678/hqdefault.jpg',
        isShort: false,
      );

      expect(noDurResult.durationFormatted, equals('YouTube'));
    });
  });

  group('ParentYouTubeSearchScreen Widget Tests', () {
    testWidgets('renders search bar, mode chips, and suggestion chips', (tester) async {
      final provider = AppProvider();

      await tester.pumpWidget(
        ChangeNotifierProvider<AppProvider>.value(
          value: provider,
          child: const MaterialApp(
            home: ParentYouTubeSearchScreen(),
          ),
        ),
      );

      expect(find.text('Search & Add YouTube Videos'), findsOneWidget);
      expect(find.text('Search Channel'), findsOneWidget);
      expect(find.text('Keyword Search'), findsOneWidget);
      expect(find.text('Popular Kid Channels:'), findsOneWidget);
      expect(find.text('@peppapig'), findsOneWidget);
      expect(find.text('@CoComelon'), findsOneWidget);
    });
  });
}
