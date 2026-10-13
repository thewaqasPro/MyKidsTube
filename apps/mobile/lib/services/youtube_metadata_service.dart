import 'dart:convert';
import 'package:dio/dio.dart';
import '../models/video_item.dart';

class YouTubeMetadata {
  final String id;
  final String title;
  final String authorName;
  final String thumbnailUrl;
  final bool isShort;
  final String sourceUrl;

  const YouTubeMetadata({
    required this.id,
    required this.title,
    required this.authorName,
    required this.thumbnailUrl,
    required this.isShort,
    required this.sourceUrl,
  });

  VideoItem toVideoItem({
    required String categoryId,
    String profileId = 'kids_all',
  }) {
    return VideoItem(
      id: id,
      youtubeId: id,
      title: title,
      channelName: authorName,
      categoryId: categoryId,
      profileId: profileId,
      sourceUrl: sourceUrl,
      streamUrl: 'https://www.youtube.com/watch?v=$id',
      thumbnailUrl: thumbnailUrl,
      status: 'embed',
      durationFormatted: isShort ? 'Short' : 'YouTube',
      quality: '720p',
    );
  }
}

class YouTubeMetadataService {
  final Dio _dio;

  YouTubeMetadataService({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 8),
              receiveTimeout: const Duration(seconds: 8),
              headers: {
                'User-Agent': 'Mozilla/5.0 (Mobile; MyKidsTube)',
              },
            ));

  /// Extracts 11-character YouTube video ID from any format:
  /// - https://www.youtube.com/watch?v=dQw4w9WgXcQ
  /// - https://youtu.be/dQw4w9WgXcQ
  /// - https://www.youtube.com/shorts/dQw4w9WgXcQ
  /// - https://www.youtube.com/embed/dQw4w9WgXcQ
  /// - dQw4w9WgXcQ
  static String? extractVideoId(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;

    // Check if it's already an 11-char ID
    final rawIdRegExp = RegExp(r'^[a-zA-Z0-9_-]{11}$');
    if (rawIdRegExp.hasMatch(trimmed)) {
      return trimmed;
    }

    // Standard watch?v= format
    final watchRegExp = RegExp(r'[?&]v=([a-zA-Z0-9_-]{11})');
    final watchMatch = watchRegExp.firstMatch(trimmed);
    if (watchMatch != null) {
      return watchMatch.group(1);
    }

    // youtu.be / shorts / embed paths
    final pathRegExp = RegExp(r'(?:youtu\.be\/|youtube\.com\/(?:shorts\/|embed\/|v\/))([a-zA-Z0-9_-]{11})');
    final pathMatch = pathRegExp.firstMatch(trimmed);
    if (pathMatch != null) {
      return pathMatch.group(1);
    }

    return null;
  }

  /// Checks if URL points to a vertical YouTube Short
  static bool isShortUrl(String url) {
    final lower = url.toLowerCase();
    return lower.contains('/shorts/') || lower.contains('#shorts');
  }

  /// Fetches public metadata via YouTube's zero-auth oEmbed endpoint
  Future<YouTubeMetadata?> fetchMetadata(String urlOrId) async {
    final videoId = extractVideoId(urlOrId);
    if (videoId == null) return null;

    final isShort = isShortUrl(urlOrId);
    final canonicalUrl = isShort
        ? 'https://www.youtube.com/shorts/$videoId'
        : 'https://www.youtube.com/watch?v=$videoId';

    final defaultThumbnail = 'https://i.ytimg.com/vi/$videoId/hqdefault.jpg';

    try {
      final oEmbedUrl = 'https://www.youtube.com/oembed?url=${Uri.encodeComponent(canonicalUrl)}&format=json';
      final response = await _dio.get(oEmbedUrl);

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : jsonDecode(response.data.toString()) as Map<String, dynamic>;

        final title = (data['title'] as String?)?.trim() ?? 'YouTube Video';
        final author = (data['author_name'] as String?)?.trim() ?? 'YouTube Channel';
        final thumbnail = (data['thumbnail_url'] as String?)?.trim() ?? defaultThumbnail;

        return YouTubeMetadata(
          id: videoId,
          title: title,
          authorName: author,
          thumbnailUrl: thumbnail,
          isShort: isShort,
          sourceUrl: canonicalUrl,
        );
      }
    } catch (_) {
      // Fallback gracefully without throwing
    }

    // Graceful offline/timeout fallback with standard YouTube metadata
    return YouTubeMetadata(
      id: videoId,
      title: 'YouTube Video ($videoId)',
      authorName: 'YouTube Creator',
      thumbnailUrl: defaultThumbnail,
      isShort: isShort,
      sourceUrl: canonicalUrl,
    );
  }
}
