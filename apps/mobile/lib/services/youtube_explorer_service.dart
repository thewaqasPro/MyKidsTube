import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt_exp;
import '../models/video_item.dart';
import 'youtube_metadata_service.dart';

class YouTubeChannelInfo {
  final String id;
  final String title;
  final String? logoUrl;
  final String? bannerUrl;

  const YouTubeChannelInfo({
    required this.id,
    required this.title,
    this.logoUrl,
    this.bannerUrl,
  });
}

class YouTubeSearchResult {
  final String id;
  final String title;
  final String channelName;
  final String channelId;
  final Duration? duration;
  final String thumbnailUrl;
  final bool isShort;
  final String? uploadDate;

  const YouTubeSearchResult({
    required this.id,
    required this.title,
    required this.channelName,
    required this.channelId,
    this.duration,
    required this.thumbnailUrl,
    required this.isShort,
    this.uploadDate,
  });

  String get durationFormatted {
    if (isShort) return 'Short';
    if (duration == null || duration!.inSeconds <= 0) return 'YouTube';
    final m = duration!.inMinutes;
    final s = duration!.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  VideoItem toVideoItem({
    required String categoryId,
    String profileId = 'kids_all',
  }) {
    return VideoItem(
      id: id,
      youtubeId: id,
      title: title,
      channelName: channelName,
      categoryId: categoryId,
      profileId: profileId,
      sourceUrl: isShort
          ? 'https://www.youtube.com/shorts/$id'
          : 'https://www.youtube.com/watch?v=$id',
      streamUrl: 'https://www.youtube.com/watch?v=$id',
      thumbnailUrl: thumbnailUrl,
      status: 'embed',
      durationFormatted: durationFormatted,
      quality: '720p',
    );
  }
}

class YouTubeChannelResult {
  final YouTubeChannelInfo channel;
  final List<YouTubeSearchResult> videos;

  const YouTubeChannelResult({
    required this.channel,
    required this.videos,
  });
}

class YouTubeExplorerService {
  final yt_exp.YoutubeExplode _yt;

  YouTubeExplorerService({yt_exp.YoutubeExplode? yt}) : _yt = yt ?? yt_exp.YoutubeExplode();

  void dispose() {
    _yt.close();
  }

  /// Searches YouTube videos matching [query]
  Future<List<YouTubeSearchResult>> searchVideos(String query, {int limit = 30}) async {
    final clean = query.trim();
    if (clean.isEmpty) return [];

    try {
      final searchResults = await _yt.search.search(clean);
      final list = <YouTubeSearchResult>[];

      for (final video in searchResults) {
        if (list.length >= limit) break;
        final isShort = video.duration != null &&
            video.duration!.inSeconds > 0 &&
            video.duration!.inSeconds <= 60;

        final thumb = video.thumbnails.highResUrl.isNotEmpty
            ? video.thumbnails.highResUrl
            : 'https://i.ytimg.com/vi/${video.id.value}/hqdefault.jpg';

        list.add(YouTubeSearchResult(
          id: video.id.value,
          title: video.title,
          channelName: video.author,
          channelId: video.channelId.value,
          duration: video.duration,
          thumbnailUrl: thumb,
          isShort: isShort,
          uploadDate: video.uploadDateRaw,
        ));
      }

      return list;
    } catch (_) {
      return [];
    }
  }

  /// Loads a YouTube channel and its uploaded videos
  /// Supports:
  /// - Handles: '@peppapig', 'peppapig'
  /// - Full URL: 'https://www.youtube.com/@peppapig'
  /// - Channel ID: 'UC...'
  Future<YouTubeChannelResult?> getChannelVideos(String channelInput, {int limit = 40}) async {
    var query = channelInput.trim();
    if (query.isEmpty) return null;

    // 1. Extract handle from URL if present
    if (query.contains('youtube.com/@')) {
      final parts = query.split('youtube.com/@');
      if (parts.length > 1) {
        query = '@${parts[1].split('/').first.split('?').first}';
      }
    } else if (query.contains('youtube.com/channel/')) {
      final parts = query.split('youtube.com/channel/');
      if (parts.length > 1) {
        query = parts[1].split('/').first.split('?').first;
      }
    }

    yt_exp.Channel? channel;

    // 2. Resolve Channel Entity
    try {
      if (query.startsWith('UC') && query.length >= 20) {
        channel = await _yt.channels.get(query);
      } else if (query.startsWith('@')) {
        channel = await _yt.channels.getByHandle(query);
      } else {
        // Try as handle first
        try {
          channel = await _yt.channels.getByHandle('@$query');
        } catch (_) {
          // Try by username
          try {
            channel = await _yt.channels.getByUsername(query);
          } catch (_) {
            // Search channels
            final searchResults = await _yt.search.searchContent(query);
            final searchChannel = searchResults.whereType<yt_exp.SearchChannel>().firstOrNull;
            if (searchChannel != null) {
              channel = await _yt.channels.get(searchChannel.id);
            }
          }
        }
      }
    } catch (_) {
      channel = null;
    }

    if (channel == null) return null;

    final channelInfo = YouTubeChannelInfo(
      id: channel.id.value,
      title: channel.title,
      logoUrl: channel.logoUrl,
      bannerUrl: channel.bannerUrl,
    );

    // 3. Fetch channel uploads using Uploads playlist (UU...)
    final videoList = <YouTubeSearchResult>[];
    try {
      final uploadsPlaylistId = channel.id.value.replaceFirst('UC', 'UU');
      await for (final video in _yt.playlists.getVideos(uploadsPlaylistId)) {
        final isShort = video.duration != null &&
            video.duration!.inSeconds > 0 &&
            video.duration!.inSeconds <= 60;

        final thumb = video.thumbnails.highResUrl.isNotEmpty
            ? video.thumbnails.highResUrl
            : 'https://i.ytimg.com/vi/${video.id.value}/hqdefault.jpg';

        videoList.add(YouTubeSearchResult(
          id: video.id.value,
          title: video.title,
          channelName: channel.title,
          channelId: channel.id.value,
          duration: video.duration,
          thumbnailUrl: thumb,
          isShort: isShort,
          uploadDate: video.uploadDateRaw,
        ));

        if (videoList.length >= limit) break;
      }
    } catch (_) {
      // Fallback: try searchVideos for this channel title
      if (videoList.isEmpty) {
        final fallback = await searchVideos(channel.title, limit: limit);
        videoList.addAll(fallback);
      }
    }

    return YouTubeChannelResult(
      channel: channelInfo,
      videos: videoList,
    );
  }

  /// Fetches single video details by URL or Video ID
  Future<YouTubeSearchResult?> fetchVideo(String urlOrId) async {
    final videoId = YouTubeMetadataService.extractVideoId(urlOrId);
    if (videoId == null) return null;

    try {
      final video = await _yt.videos.get(videoId);
      final isShort = video.duration != null &&
          video.duration!.inSeconds > 0 &&
          video.duration!.inSeconds <= 60;

      return YouTubeSearchResult(
        id: video.id.value,
        title: video.title,
        channelName: video.author,
        channelId: video.channelId.value,
        duration: video.duration,
        thumbnailUrl: video.thumbnails.highResUrl,
        isShort: isShort,
        uploadDate: video.uploadDateRaw,
      );
    } catch (_) {
      // Fallback to zero-auth oEmbed
      final meta = await YouTubeMetadataService().fetchMetadata(urlOrId);
      if (meta == null) return null;
      return YouTubeSearchResult(
        id: meta.id,
        title: meta.title,
        channelName: meta.authorName,
        channelId: '',
        thumbnailUrl: meta.thumbnailUrl,
        isShort: meta.isShort,
      );
    }
  }
}
