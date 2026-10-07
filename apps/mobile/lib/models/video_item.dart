enum DownloadStatus {
  notDownloaded,
  downloading,
  downloaded,
  failed,
}

class VideoItem {
  final String id;
  final String title;
  final int duration;
  final String durationFormatted;
  final String categoryId;
  final String sourceUrl;
  final String streamUrl;
  final String thumbnailUrl;
  final String? channelName;
  final String? channelIconUrl;
  final String? localFilePath;
  final String? localThumbnailPath;
  final int fileSizeBytes;
  final String quality;
  final DownloadStatus downloadStatus;
  final double downloadProgress;
  final String status;
  final String? youtubeId;

  VideoItem({
    required this.id,
    required this.title,
    this.duration = 0,
    this.durationFormatted = '00:00',
    required this.categoryId,
    this.sourceUrl = '',
    required this.streamUrl,
    required this.thumbnailUrl,
    this.channelName,
    this.channelIconUrl,
    this.localFilePath,
    this.localThumbnailPath,
    this.fileSizeBytes = 0,
    this.quality = '720p',
    this.downloadStatus = DownloadStatus.notDownloaded,
    this.downloadProgress = 0.0,
    this.status = 'pending_download',
    this.youtubeId,
  });

  bool get isOfflineReady =>
      downloadStatus == DownloadStatus.downloaded &&
      localFilePath != null &&
      localFilePath!.isNotEmpty;

  /// Returns true if this video is a short (<= 70s / vertical short)
  bool get isShort {
    if (id.startsWith('short_') || sourceUrl.contains('/shorts/')) {
      return true;
    }
    if (duration > 0) {
      return duration <= 70;
    }
    return categoryId == 'shorts';
  }

  /// Extracts or computes the reliable YouTube video ID for embed playback
  String get effectiveYoutubeId {
    if (youtubeId != null && youtubeId!.isNotEmpty) {
      return youtubeId!;
    }
    if (id.startsWith('short_')) {
      return id.replaceFirst('short_', '');
    }
    if (sourceUrl.contains('v=')) {
      final uri = Uri.tryParse(sourceUrl);
      final v = uri?.queryParameters['v'];
      if (v != null && v.isNotEmpty) return v;
    }
    return id;
  }

  /// Whether the video has verified local MP4 or verified self-hosted VPS MP4
  bool get isSelfHosted => status == 'ready' && streamUrl.isNotEmpty;

  /// Whether the video requires sandboxed YouTube embed playback
  bool get needsEmbed => !isOfflineReady && status != 'ready';

  VideoItem copyWith({
    String? id,
    String? title,
    int? duration,
    String? durationFormatted,
    String? categoryId,
    String? sourceUrl,
    String? streamUrl,
    String? thumbnailUrl,
    String? channelName,
    String? channelIconUrl,
    String? localFilePath,
    String? localThumbnailPath,
    int? fileSizeBytes,
    String? quality,
    DownloadStatus? downloadStatus,
    double? downloadProgress,
    String? status,
    String? youtubeId,
  }) {
    return VideoItem(
      id: id ?? this.id,
      title: title ?? this.title,
      duration: duration ?? this.duration,
      durationFormatted: durationFormatted ?? this.durationFormatted,
      categoryId: categoryId ?? this.categoryId,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      streamUrl: streamUrl ?? this.streamUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      channelName: channelName ?? this.channelName,
      channelIconUrl: channelIconUrl ?? this.channelIconUrl,
      localFilePath: localFilePath ?? this.localFilePath,
      localThumbnailPath: localThumbnailPath ?? this.localThumbnailPath,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      quality: quality ?? this.quality,
      downloadStatus: downloadStatus ?? this.downloadStatus,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      status: status ?? this.status,
      youtubeId: youtubeId ?? this.youtubeId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'duration': duration,
      'duration_formatted': durationFormatted,
      'category_id': categoryId,
      'source_url': sourceUrl,
      'stream_url': streamUrl,
      'thumbnail_url': thumbnailUrl,
      'channel_name': channelName,
      'channel_icon_url': channelIconUrl,
      'local_file_path': localFilePath,
      'local_thumbnail_path': localThumbnailPath,
      'file_size_bytes': fileSizeBytes,
      'quality': quality,
      'download_status': downloadStatus.index,
      'status': status,
      'youtube_id': youtubeId ?? effectiveYoutubeId,
    };
  }

  static VideoItem? fromMap(Map<String, dynamic> map) {
    final id = map['id'];
    if (id == null || id.toString().trim().isEmpty) return null;

    final rawStatus = map['download_status'];
    final statusIndex = rawStatus is int ? rawStatus : int.tryParse(rawStatus?.toString() ?? '0') ?? 0;
    final downloadStatus = (statusIndex >= 0 && statusIndex < DownloadStatus.values.length)
        ? DownloadStatus.values[statusIndex]
        : DownloadStatus.notDownloaded;

    return VideoItem(
      id: id.toString(),
      title: (map['title'] ?? 'Untitled Video').toString(),
      duration: (map['duration'] as num?)?.toInt() ?? 0,
      durationFormatted: (map['duration_formatted'] ?? '00:00').toString(),
      categoryId: (map['category_id'] ?? 'cartoons').toString(),
      sourceUrl: (map['source_url'] ?? '').toString(),
      streamUrl: (map['stream_url'] ?? '').toString(),
      thumbnailUrl: (map['thumbnail_url'] ?? '').toString(),
      channelName: map['channel_name']?.toString(),
      channelIconUrl: map['channel_icon_url']?.toString(),
      localFilePath: map['local_file_path']?.toString(),
      localThumbnailPath: map['local_thumbnail_path']?.toString(),
      fileSizeBytes: (map['file_size_bytes'] as num?)?.toInt() ?? 0,
      quality: (map['quality'] ?? '720p').toString(),
      downloadStatus: downloadStatus,
      status: (map['status'] ?? 'pending_download').toString(),
      youtubeId: map['youtube_id']?.toString(),
    );
  }

  static VideoItem? fromApi(Map<String, dynamic> json, {String? localPath, String? localThumb, DownloadStatus? status}) {
    final id = json['id'];
    if (id == null || id.toString().trim().isEmpty) return null;

    final title = (json['title'] ?? 'Untitled Video').toString();
    String? chName = json['channel_name']?.toString();
    if (chName == null || chName.isEmpty) {
      if (title.contains('•')) {
        chName = title.split('•').first.trim();
      }
    }
    return VideoItem(
      id: id.toString(),
      title: title,
      duration: (json['duration'] as num?)?.toInt() ?? 0,
      durationFormatted: (json['duration_formatted'] ?? '00:00').toString(),
      categoryId: (json['category_id'] ?? 'cartoons').toString(),
      sourceUrl: (json['source_url'] ?? '').toString(),
      streamUrl: (json['stream_url'] ?? '').toString(),
      thumbnailUrl: (json['thumbnail_url'] ?? '').toString(),
      channelName: chName,
      channelIconUrl: json['channel_icon_url']?.toString(),
      localFilePath: localPath,
      localThumbnailPath: localThumb,
      fileSizeBytes: (json['file_size_bytes'] as num?)?.toInt() ?? 0,
      quality: (json['quality'] ?? '720p').toString(),
      downloadStatus: status ?? DownloadStatus.notDownloaded,
      status: (json['status'] ?? 'pending_download').toString(),
      youtubeId: json['youtube_id']?.toString(),
    );
  }
}
