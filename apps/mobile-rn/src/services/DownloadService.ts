import * as FileSystem from 'expo-file-system/legacy';
import { VideoItem, DownloadStatus } from '../types/video';
import { databaseService } from './DatabaseService';
import { formatBytes } from '../utils/urlHelpers';

export type DownloadProgressCallback = (videoId: string, progress: number) => void;

class DownloadService {
  private static instance: DownloadService;

  private static readonly MAX_CONCURRENT = 2;
  private downloadQueue: VideoItem[] = [];
  private activeDownloads: Map<string, FileSystem.DownloadResumable> = new Map();
  private progressCallbacks: Map<string, DownloadProgressCallback> = new Map();

  // Throttling progress notifications (250ms or 1% delta)
  private lastProgressTime: Map<string, number> = new Map();
  private lastProgressValue: Map<string, number> = new Map();

  // Storage error reporting
  public lastErrorMessage: string | null = null;

  public static getInstance(): DownloadService {
    if (!DownloadService.instance) {
      DownloadService.instance = new DownloadService();
    }
    return DownloadService.instance;
  }

  private constructor() {}

  public async getMediaDirectory(): Promise<string> {
    const base = FileSystem.documentDirectory || '';
    const dir = `${base}kidstube_media/`;
    const info = await FileSystem.getInfoAsync(dir);
    if (!info.exists) {
      await FileSystem.makeDirectoryAsync(dir, { intermediates: true });
    }
    return dir;
  }

  public async getFreeDiskSpace(): Promise<number | null> {
    try {
      const freeBytes = await FileSystem.getFreeDiskStorageAsync();
      return freeBytes;
    } catch (_) {
      return null;
    }
  }

  public isDownloading(videoId: string): boolean {
    return (
      this.activeDownloads.has(videoId) ||
      this.downloadQueue.some((v) => v.id === videoId)
    );
  }

  public cancelDownload(videoId: string): void {
    // If queued, remove from queue
    this.downloadQueue = this.downloadQueue.filter((v) => v.id !== videoId);

    const task = this.activeDownloads.get(videoId);
    if (task) {
      try {
        task.cancelAsync();
      } catch (_) {}
      this.activeDownloads.delete(videoId);
    }

    this.progressCallbacks.delete(videoId);
    this.lastProgressTime.delete(videoId);
    this.lastProgressValue.delete(videoId);
  }

  public async downloadVideo(
    video: VideoItem,
    onProgress?: DownloadProgressCallback
  ): Promise<boolean> {
    if (this.isDownloading(video.id)) return false;

    // Pre-flight check: ensure sufficient free disk space exists
    const freeBytes = await this.getFreeDiskSpace();
    const requiredBytes =
      video.fileSizeBytes > 0 ? video.fileSizeBytes : 25 * 1024 * 1024; // fallback 25MB
    if (freeBytes !== null && freeBytes < requiredBytes) {
      const shortfall = requiredBytes - freeBytes;
      this.lastErrorMessage = `Not enough storage space for '${video.title}'. Short by ${formatBytes(
        shortfall
      )}.`;
      return false;
    }

    if (onProgress) {
      this.progressCallbacks.set(video.id, onProgress);
    }

    this.downloadQueue.push(video);
    this.processQueue();
    return true;
  }

  private processQueue(): void {
    while (
      this.activeDownloads.size < DownloadService.MAX_CONCURRENT &&
      this.downloadQueue.length > 0
    ) {
      const nextVideo = this.downloadQueue.shift();
      if (nextVideo) {
        this.executeDownload(nextVideo);
      }
    }
  }

  private async executeDownload(video: VideoItem): Promise<void> {
    const baseDir = await this.getMediaDirectory();
    const finalVideoPath = `${baseDir}${video.id}.mp4`;
    const partVideoPath = `${baseDir}${video.id}.mp4.part`;
    const thumbPath = `${baseDir}${video.id}.webp`;

    let isCancelled = false;

    try {
      await databaseService.updateDownloadStatus(video.id, DownloadStatus.downloading);

      const downloadResumable = FileSystem.createDownloadResumable(
        video.streamUrl,
        partVideoPath,
        {
          headers: {
            Accept: 'video/mp4,video/*;q=0.9,*/*;q=0.8',
          },
        },
        (downloadProgress) => {
          const written = downloadProgress.totalBytesWritten;
          const expected =
            downloadProgress.totalBytesExpectedToWrite > 0
              ? downloadProgress.totalBytesExpectedToWrite
              : video.fileSizeBytes;
          this.notifyThrottledProgress(video.id, written, expected);
        }
      );

      this.activeDownloads.set(video.id, downloadResumable);

      const result = await downloadResumable.downloadAsync();
      if (!result || !result.uri) {
        throw new Error('Download failed with empty response');
      }

      // Check if cancelled during download
      if (!this.activeDownloads.has(video.id)) {
        isCancelled = true;
        await this.cleanupPartFile(partVideoPath);
        await databaseService.clearDownloadedStatus(video.id);
        return;
      }

      // Integrity Check: ensure file size matches expected catalog size (when known)
      const partInfo = await FileSystem.getInfoAsync(partVideoPath);
      if (!partInfo.exists) {
        throw new Error('Downloaded part file missing on disk');
      }

      const downloadedBytes = partInfo.size || 0;
      if (video.fileSizeBytes > 0 && downloadedBytes < video.fileSizeBytes * 0.9) {
        throw new Error(
          `Download truncated: ${downloadedBytes} bytes received, expected ${video.fileSizeBytes}`
        );
      }

      // Atomic rename: move .mp4.part to final .mp4
      const existingFinal = await FileSystem.getInfoAsync(finalVideoPath);
      if (existingFinal.exists) {
        await FileSystem.deleteAsync(finalVideoPath, { idempotent: true });
      }
      await FileSystem.moveAsync({
        from: partVideoPath,
        to: finalVideoPath,
      });

      // Download thumbnail if available
      let localThumbPath: string | undefined;
      if (video.thumbnailUrl && video.thumbnailUrl.startsWith('http')) {
        try {
          const thumbResult = await FileSystem.downloadAsync(
            video.thumbnailUrl,
            thumbPath
          );
          if (thumbResult && thumbResult.uri) {
            localThumbPath = thumbResult.uri;
          }
        } catch (_) {
          localThumbPath = undefined;
        }
      }

      // Mark completed in DB
      await databaseService.updateDownloadStatus(
        video.id,
        DownloadStatus.downloaded,
        finalVideoPath,
        localThumbPath
      );
    } catch (e: any) {
      if (isCancelled || !this.activeDownloads.has(video.id)) {
        // User cancelled download
        await this.cleanupPartFile(partVideoPath);
        await databaseService.clearDownloadedStatus(video.id);
      } else {
        const errStr = e?.message || String(e);
        const isStorageFull =
          errStr.includes('ENOSPC') ||
          errStr.includes('No space left') ||
          errStr.includes('storage');

        if (isStorageFull) {
          this.lastErrorMessage =
            'Storage full: not enough disk space to download video.';
        } else {
          this.lastErrorMessage = `Download failed: ${errStr}`;
        }

        // On failure, delete corrupted partial file
        await this.cleanupPartFile(partVideoPath);
        await databaseService.updateDownloadStatus(video.id, DownloadStatus.failed);
      }
    } finally {
      this.activeDownloads.delete(video.id);
      this.progressCallbacks.delete(video.id);
      this.lastProgressTime.delete(video.id);
      this.lastProgressValue.delete(video.id);
      this.processQueue();
    }
  }

  private async cleanupPartFile(path: string): Promise<void> {
    try {
      const info = await FileSystem.getInfoAsync(path);
      if (info.exists) {
        await FileSystem.deleteAsync(path, { idempotent: true });
      }
    } catch (_) {}
  }

  private notifyThrottledProgress(
    videoId: string,
    received: number,
    total: number
  ): void {
    const callback = this.progressCallbacks.get(videoId);
    if (!callback) return;

    const progress = total > 0 ? Math.min(Math.max(received / total, 0.0), 1.0) : 0.0;
    const now = Date.now();
    const lastTime = this.lastProgressTime.get(videoId) || 0;
    const lastVal = this.lastProgressValue.get(videoId) || 0;

    const timeDeltaMs = now - lastTime;
    const valDelta = Math.abs(progress - lastVal);

    if (timeDeltaMs >= 250 || valDelta >= 0.01 || progress >= 1.0) {
      this.lastProgressTime.set(videoId, now);
      this.lastProgressValue.set(videoId, progress);
      callback(videoId, progress);
    }
  }

  public async deleteDownloadedFile(videoId: string, localPath?: string): Promise<void> {
    this.cancelDownload(videoId);

    if (localPath && localPath.length > 0) {
      try {
        await FileSystem.deleteAsync(localPath, { idempotent: true });
      } catch (_) {}
    }

    try {
      const baseDir = await this.getMediaDirectory();
      await FileSystem.deleteAsync(`${baseDir}${videoId}.mp4.part`, { idempotent: true });
      await FileSystem.deleteAsync(`${baseDir}${videoId}.webp`, { idempotent: true });
      await FileSystem.deleteAsync(`${baseDir}${videoId}.mp4`, { idempotent: true });
    } catch (_) {}

    await databaseService.clearDownloadedStatus(videoId);
  }

  public async deleteAllDownloadedMedia(): Promise<void> {
    const downloaded = await databaseService.getDownloadedVideos();
    for (const v of downloaded) {
      await this.deleteDownloadedFile(v.id, v.localFilePath);
    }
    await this.cleanupOrphanFiles();
  }

  public async cleanupOrphanFiles(): Promise<void> {
    try {
      const baseDir = await this.getMediaDirectory();
      const files = await FileSystem.readDirectoryAsync(baseDir);
      const downloaded = await databaseService.getDownloadedVideos();
      const validIds = new Set(downloaded.map((v) => v.id));

      for (const filename of files) {
        const fullPath = `${baseDir}${filename}`;
        if (filename.endsWith('.part')) {
          const id = filename.replace('.mp4.part', '');
          if (!this.activeDownloads.has(id)) {
            await FileSystem.deleteAsync(fullPath, { idempotent: true });
          }
        } else if (filename.endsWith('.mp4') || filename.endsWith('.webp')) {
          const id = filename.replace('.mp4', '').replace('.webp', '');
          if (!validIds.has(id) && !this.activeDownloads.has(id)) {
            await FileSystem.deleteAsync(fullPath, { idempotent: true });
          }
        }
      }
    } catch (_) {}
  }

  public async getTotalCachedBytes(): Promise<number> {
    let total = 0;
    try {
      const baseDir = await this.getMediaDirectory();
      const files = await FileSystem.readDirectoryAsync(baseDir);
      for (const filename of files) {
        if (!filename.endsWith('.part')) {
          const info = await FileSystem.getInfoAsync(`${baseDir}${filename}`);
          if (info.exists && info.size) {
            total += info.size;
          }
        }
      }
    } catch (_) {}
    return total;
  }
}

export const downloadService = DownloadService.getInstance();
