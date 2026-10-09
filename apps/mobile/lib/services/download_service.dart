import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../models/video_item.dart';
import '../utils/format_utils.dart';
import 'database_service.dart';

typedef DownloadProgressCallback = void Function(String videoId, double progress);

class DownloadService {
  static final DownloadService instance = DownloadService._init();

  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 45),
  ));

  // Concurrency cap: max 2 concurrent downloads
  static const int _maxConcurrent = 2;
  final List<VideoItem> _downloadQueue = [];
  final Map<String, CancelToken> _activeDownloads = {};
  final Map<String, DownloadProgressCallback?> _progressCallbacks = {};

  // Throttling progress notifications (250ms or 1% delta)
  final Map<String, DateTime> _lastProgressTime = {};
  final Map<String, double> _lastProgressValue = {};

  // Storage error reporting
  String? lastErrorMessage;

  static int? Function(String path)? freeDiskSpaceOverride;

  DownloadService._init();

  Future<String> get _mediaDirectory async {
    final docsDir = await getApplicationDocumentsDirectory();
    final mediaDir = Directory(p.join(docsDir.path, 'kidstube_media'));
    if (!await mediaDir.exists()) {
      await mediaDir.create(recursive: true);
    }
    return mediaDir.path;
  }

  Future<int?> getFreeDiskSpace([String? targetPath]) async {
    if (freeDiskSpaceOverride != null) {
      return freeDiskSpaceOverride!(targetPath ?? '');
    }
    try {
      final path = targetPath ?? await _mediaDirectory;
      final result = await Process.run('df', ['-k', path]);
      if (result.exitCode == 0) {
        final lines = (result.stdout as String).trim().split('\n');
        if (lines.length >= 2) {
          final tokens = lines[1].trim().split(RegExp(r'\s+'));
          if (tokens.length >= 4) {
            final availKb = int.tryParse(tokens[3]);
            if (availKb != null) {
              return availKb * 1024;
            }
          }
        }
      }
    } catch (_) {}
    return null;
  }

  static String formatBytes(int bytes) => FormatUtils.formatBytes(bytes);

  bool isDownloading(String videoId) {
    return _activeDownloads.containsKey(videoId) || _downloadQueue.any((v) => v.id == videoId);
  }

  void cancelDownload(String videoId) {
    // If queued but not active, remove from queue
    _downloadQueue.removeWhere((v) => v.id == videoId);

    if (_activeDownloads.containsKey(videoId)) {
      _activeDownloads[videoId]?.cancel('Cancelled by user');
      _activeDownloads.remove(videoId);
    }
    _progressCallbacks.remove(videoId);
    _lastProgressTime.remove(videoId);
    _lastProgressValue.remove(videoId);
  }

  /// Enqueues video download with concurrency cap of 2 and pre-flight space check
  Future<bool> downloadVideo(VideoItem video, {DownloadProgressCallback? onProgress}) async {
    if (isDownloading(video.id)) return false;

    // Pre-flight check: ensure sufficient free disk space exists before initiating download
    final freeBytes = await getFreeDiskSpace();
    final requiredBytes = video.fileSizeBytes > 0 ? video.fileSizeBytes : 25 * 1024 * 1024;
    if (freeBytes != null && freeBytes < requiredBytes) {
      final shortfall = requiredBytes - freeBytes;
      lastErrorMessage = "Not enough storage space for '${video.title}'. Short by ${formatBytes(shortfall)}.";
      return false;
    }

    if (onProgress != null) {
      _progressCallbacks[video.id] = onProgress;
    }

    _downloadQueue.add(video);
    _processQueue();
    return true;
  }

  void _processQueue() {
    while (_activeDownloads.length < _maxConcurrent && _downloadQueue.isNotEmpty) {
      final nextVideo = _downloadQueue.removeAt(0);
      _executeDownload(nextVideo);
    }
  }

  Future<void> _executeDownload(VideoItem video) async {
    final cancelToken = CancelToken();
    _activeDownloads[video.id] = cancelToken;
    final onProgress = _progressCallbacks[video.id];

    final baseDir = await _mediaDirectory;
    final videoSavePath = p.join(baseDir, '${video.id}.mp4');
    final partSavePath = p.join(baseDir, '${video.id}.mp4.part');
    final thumbSavePath = p.join(baseDir, '${video.id}.webp');
    final partFile = File(partSavePath);

    IOSink? sink;
    try {
      await DatabaseService.instance.updateDownloadStatus(video.id, DownloadStatus.downloading);

      // Check existing partial bytes for HTTP Range resume
      int existingBytes = 0;
      if (await partFile.exists()) {
        existingBytes = await partFile.length();
      }

      final requestHeaders = <String, dynamic>{};
      if (existingBytes > 0) {
        requestHeaders['Range'] = 'bytes=$existingBytes-';
      }

      // Stream request to support resume and avoid memory buffering
      final response = await _dio.get<ResponseBody>(
        video.streamUrl,
        options: Options(
          responseType: ResponseType.stream,
          headers: requestHeaders,
        ),
        cancelToken: cancelToken,
      );

      final isResume = response.statusCode == 206 && existingBytes > 0;
      final fileMode = isResume ? FileMode.append : FileMode.write;
      sink = partFile.openWrite(mode: fileMode);

      int totalBytes = -1;
      final contentRange = response.headers.value('content-range');
      if (contentRange != null && contentRange.contains('/')) {
        totalBytes = int.tryParse(contentRange.split('/').last) ?? -1;
      } else {
        final cl = response.headers.value('content-length');
        if (cl != null) {
          final len = int.tryParse(cl) ?? -1;
          totalBytes = isResume ? (existingBytes + len) : len;
        }
      }
      if (totalBytes <= 0 && video.fileSizeBytes > 0) {
        totalBytes = video.fileSizeBytes;
      }

      int receivedBytes = isResume ? existingBytes : 0;

      await for (final chunk in response.data!.stream) {
        if (cancelToken.isCancelled) break;
        sink.add(chunk);
        receivedBytes += chunk.length;

        _notifyThrottledProgress(video.id, receivedBytes, totalBytes, onProgress);
      }

      await sink.flush();
      await sink.close();
      sink = null;

      if (cancelToken.isCancelled) {
        // Cancelled mid-stream
        if (await partFile.exists()) await partFile.delete();
        await DatabaseService.instance.clearDownloadedStatus(video.id);
        return;
      }

      // Integrity Check: ensure file size matches expected catalog size (when known)
      final downloadedBytes = await partFile.length();
      if (video.fileSizeBytes > 0 && downloadedBytes < (video.fileSizeBytes * 0.90)) {
        throw Exception('Download truncated: $downloadedBytes bytes received, expected ${video.fileSizeBytes}');
      }

      // Atomically move .part to final .mp4
      final finalVideoFile = File(videoSavePath);
      if (await finalVideoFile.exists()) {
        await finalVideoFile.delete();
      }
      await partFile.rename(videoSavePath);

      // Download thumbnail (clean failure handling)
      String? localThumbPath;
      if (video.thumbnailUrl.isNotEmpty) {
        try {
          await _dio.download(
            video.thumbnailUrl,
            thumbSavePath,
            cancelToken: cancelToken,
          );
          if (await File(thumbSavePath).exists()) {
            localThumbPath = thumbSavePath;
          }
        } catch (_) {
          localThumbPath = null;
        }
      }

      // Mark completed in DB
      await DatabaseService.instance.updateDownloadStatus(
        video.id,
        DownloadStatus.downloaded,
        localPath: videoSavePath,
        localThumb: localThumbPath,
      );
    } on DioException catch (e) {
      if (sink != null) {
        try { await sink.close(); } catch (_) {}
      }

      if (e.type == DioExceptionType.cancel) {
        // User cancelled download
        if (await partFile.exists()) {
          try { await partFile.delete(); } catch (_) {}
        }
        await DatabaseService.instance.clearDownloadedStatus(video.id);
      } else {
        // Check for ENOSPC / storage full
        final isEnospc = e.error?.toString().contains('ENOSPC') == true ||
            e.error?.toString().contains('No space left') == true;
        if (isEnospc) {
          lastErrorMessage = 'Storage full: not enough disk space to download video.';
        } else {
          lastErrorMessage = 'Network error during download.';
        }

        // On failure, delete corrupted partial so it does not count as storage
        if (await partFile.exists()) {
          try { await partFile.delete(); } catch (_) {}
        }
        await DatabaseService.instance.updateDownloadStatus(video.id, DownloadStatus.failed);
      }
    } catch (e) {
      if (sink != null) {
        try { await sink.close(); } catch (_) {}
      }
      if (e.toString().contains('ENOSPC') || e.toString().contains('No space left')) {
        lastErrorMessage = 'Storage full: not enough disk space to download video.';
      } else {
        lastErrorMessage = 'Download failed: $e';
      }
      if (await partFile.exists()) {
        try { await partFile.delete(); } catch (_) {}
      }
      await DatabaseService.instance.updateDownloadStatus(video.id, DownloadStatus.failed);
    } finally {
      _activeDownloads.remove(video.id);
      _progressCallbacks.remove(video.id);
      _lastProgressTime.remove(video.id);
      _lastProgressValue.remove(video.id);
      _processQueue();
    }
  }

  void _notifyThrottledProgress(
    String videoId,
    int received,
    int total,
    DownloadProgressCallback? callback,
  ) {
    if (callback == null) return;

    final progress = total > 0 ? (received / total).clamp(0.0, 1.0) : 0.0;
    final now = DateTime.now();
    final lastTime = _lastProgressTime[videoId];
    final lastVal = _lastProgressValue[videoId] ?? 0.0;

    final timeDeltaMs = lastTime != null ? now.difference(lastTime).inMilliseconds : 9999;
    final valDelta = (progress - lastVal).abs();

    if (timeDeltaMs >= 250 || valDelta >= 0.01 || progress >= 1.0) {
      _lastProgressTime[videoId] = now;
      _lastProgressValue[videoId] = progress;
      callback(videoId, progress);
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
    // Also delete any .part file
    try {
      final baseDir = await _mediaDirectory;
      final partFile = File(p.join(baseDir, '$videoId.mp4.part'));
      if (await partFile.exists()) await partFile.delete();
      final thumbFile = File(p.join(baseDir, '$videoId.webp'));
      if (await thumbFile.exists()) await thumbFile.delete();
    } catch (_) {}

    await DatabaseService.instance.clearDownloadedStatus(videoId);
  }

  Future<void> deleteAllDownloadedMedia() async {
    final downloaded = await DatabaseService.instance.getDownloadedVideos();
    for (final v in downloaded) {
      await deleteDownloadedFile(v.id, v.localFilePath);
    }
    await cleanupOrphanFiles();
  }

  /// Clean up unreferenced files and orphaned .part files on disk
  Future<void> cleanupOrphanFiles() async {
    try {
      final baseDir = await _mediaDirectory;
      final dir = Directory(baseDir);
      if (!await dir.exists()) return;

      final downloaded = await DatabaseService.instance.getDownloadedVideos();
      final validIds = downloaded.map((v) => v.id).toSet();

      await for (final entity in dir.list(recursive: false)) {
        if (entity is File) {
          final filename = p.basename(entity.path);
          if (filename.endsWith('.part')) {
            final id = filename.replaceAll('.mp4.part', '');
            if (!_activeDownloads.containsKey(id)) {
              await entity.delete();
            }
          } else if (filename.endsWith('.mp4') || filename.endsWith('.webp')) {
            final id = filename.replaceAll('.mp4', '').replaceAll('.webp', '');
            if (!validIds.contains(id) && !_activeDownloads.containsKey(id)) {
              await entity.delete();
            }
          }
        }
      }
    } catch (_) {}
  }

  Future<int> getTotalCachedBytes() async {
    int total = 0;
    try {
      final baseDir = await _mediaDirectory;
      final dir = Directory(baseDir);
      if (await dir.exists()) {
        await for (final file in dir.list(recursive: false)) {
          if (file is File && !file.path.endsWith('.part')) {
            total += await file.length();
          }
        }
      }
    } catch (_) {}
    return total;
  }
}
