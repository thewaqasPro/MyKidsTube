import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../models/video_item.dart';
import 'database_service.dart';

typedef DownloadProgressCallback = void Function(String videoId, double progress);

class DownloadService {
  static final DownloadService instance = DownloadService._init();
  final Dio _dio = Dio();
  final Map<String, CancelToken> _activeDownloads = {};

  DownloadService._init();

  Future<String> get _mediaDirectory async {
    final docsDir = await getApplicationDocumentsDirectory();
    final mediaDir = Directory(p.join(docsDir.path, 'kidstube_media'));
    if (!await mediaDir.exists()) {
      await mediaDir.create(recursive: true);
    }
    return mediaDir.path;
  }

  bool isDownloading(String videoId) {
    return _activeDownloads.containsKey(videoId);
  }

  void cancelDownload(String videoId) {
    if (_activeDownloads.containsKey(videoId)) {
      _activeDownloads[videoId]?.cancel('Cancelled by user');
      _activeDownloads.remove(videoId);
    }
  }

  Future<bool> downloadVideo(VideoItem video, {DownloadProgressCallback? onProgress}) async {
    if (isDownloading(video.id)) return false;

    final cancelToken = CancelToken();
    _activeDownloads[video.id] = cancelToken;

    try {
      final baseDir = await _mediaDirectory;
      final videoSavePath = p.join(baseDir, '${video.id}.mp4');
      final thumbSavePath = p.join(baseDir, '${video.id}.webp');

      // Update status in DB
      await DatabaseService.instance.updateDownloadStatus(video.id, DownloadStatus.downloading);

      // 1. Download video
      await _dio.download(
        video.streamUrl,
        videoSavePath,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            final progress = (received / total);
            onProgress?.call(video.id, progress);
          }
        },
      );

      // 2. Download thumbnail
      try {
        await _dio.download(video.thumbnailUrl, thumbSavePath, cancelToken: cancelToken);
      } catch (_) {
        // Thumbnail download is non-fatal
      }

      // Mark completed in DB
      await DatabaseService.instance.updateDownloadStatus(
        video.id,
        DownloadStatus.downloaded,
        localPath: videoSavePath,
        localThumb: thumbSavePath,
      );

      _activeDownloads.remove(video.id);
      return true;
    } catch (e) {
      _activeDownloads.remove(video.id);
      await DatabaseService.instance.updateDownloadStatus(video.id, DownloadStatus.failed);
      return false;
    }
  }

  Future<void> deleteDownloadedFile(String videoId, String? localPath) async {
    cancelDownload(videoId);
    if (localPath != null && localPath.isNotEmpty) {
      final file = File(localPath);
      if (await file.exists()) {
        try {
          await file.delete();
        } catch (_) {}
      }
    }
    // Also delete thumb
    try {
      final baseDir = await _mediaDirectory;
      final thumbFile = File(p.join(baseDir, '$videoId.webp'));
      if (await thumbFile.exists()) {
        await thumbFile.delete();
      }
    } catch (_) {}

    await DatabaseService.instance.clearDownloadedStatus(videoId);
  }

  Future<void> deleteAllDownloadedMedia() async {
    final downloaded = await DatabaseService.instance.getDownloadedVideos();
    for (final v in downloaded) {
      await deleteDownloadedFile(v.id, v.localFilePath);
    }
  }

  Future<int> getTotalCachedBytes() async {
    int total = 0;
    try {
      final baseDir = await _mediaDirectory;
      final dir = Directory(baseDir);
      if (await dir.exists()) {
        await for (final file in dir.list(recursive: false)) {
          if (file is File) {
            total += await file.length();
          }
        }
      }
    } catch (_) {}
    return total;
  }
}
