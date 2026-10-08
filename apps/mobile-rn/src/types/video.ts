export enum DownloadStatus {
  notDownloaded = 0,
  downloading = 1,
  downloaded = 2,
  failed = 3,
}

export interface VideoItem {
  id: string;
  title: string;
  duration: number; // in seconds
  durationFormatted: string;
  categoryId: string;
  sourceUrl: string;
  streamUrl: string;
  thumbnailUrl: string;
  channelName?: string;
  channelIconUrl?: string;
  localFilePath?: string;
  localThumbnailPath?: string;
  fileSizeBytes: number;
  quality: string;
  downloadStatus: DownloadStatus;
  downloadProgress: number; // 0.0 to 1.0
  status: string; // 'ready' | 'pending_download' | 'processing'
  youtubeId?: string;
}

export interface CategoryItem {
  id: string;
  name: string;
  icon: string;
  displayOrder: number;
}
