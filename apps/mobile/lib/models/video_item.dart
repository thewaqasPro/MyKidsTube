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

  factory VideoItem.fromMap(Map<String, dynamic> map) {
    return VideoItem(
      id: map['id'] as String,
      title: map['title'] as String,
      duration: map['duration'] as int? ?? 0,
      durationFormatted: map['duration_formatted'] as String? ?? '00:00',
      categoryId: map['category_id'] as String? ?? 'cartoons',
      sourceUrl: map['source_url'] as String? ?? '',
      streamUrl: map['stream_url'] as String? ?? '',
      thumbnailUrl: map['thumbnail_url'] as String? ?? '',
      channelName: map['channel_name'] as String?,
      channelIconUrl: map['channel_icon_url'] as String?,
      localFilePath: map['local_file_path'] as String?,
      localThumbnailPath: map['local_thumbnail_path'] as String?,
      fileSizeBytes: map['file_size_bytes'] as int? ?? 0,
      quality: map['quality'] as String? ?? '720p',
      downloadStatus: DownloadStatus.values[map['download_status'] as int? ?? 0],
      status: map['status'] as String? ?? 'pending_download',
      youtubeId: map['youtube_id'] as String?,
    );
  }

  factory VideoItem.fromApi(Map<String, dynamic> json, {String? localPath, String? localThumb, DownloadStatus? status}) {
    final title = json['title'] as String? ?? 'Untitled Video';
    String? chName = json['channel_name'] as String?;
    if (chName == null || chName.isEmpty) {
      if (title.contains('•')) {
        chName = title.split('•').first.trim();
      }
    }
    return VideoItem(
      id: json['id'] as String,
      title: title,
      duration: json['duration'] as int? ?? 0,
      durationFormatted: json['duration_formatted'] as String? ?? '00:00',
      categoryId: json['category_id'] as String? ?? 'cartoons',
      sourceUrl: json['source_url'] as String? ?? '',
      streamUrl: json['stream_url'] as String? ?? '',
      thumbnailUrl: json['thumbnail_url'] as String? ?? '',
      channelName: chName,
      channelIconUrl: json['channel_icon_url'] as String?,
      localFilePath: localPath,
      localThumbnailPath: localThumb,
      fileSizeBytes: json['file_size_bytes'] as int? ?? 0,
      quality: json['quality'] as String? ?? '720p',
      downloadStatus: status ?? DownloadStatus.notDownloaded,
      status: json['status'] as String? ?? 'pending_download',
      youtubeId: json['youtube_id'] as String?,
    );
  }
}
