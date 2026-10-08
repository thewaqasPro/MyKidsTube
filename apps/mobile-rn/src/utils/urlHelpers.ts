import { VideoItem } from '../types/video';

export const API_BASE = 'https://kidsapi.waqas.pro';
export const MEDIA_BASE = 'https://kidsapi.waqas.pro/media';
export const EDGE_BASE = 'https://mykidstube.kidstube.workers.dev';
export const DEFAULT_VPS_URL = 'https://mykidstube.kidstube.workers.dev';

export function getThumbnailUrl(
  video: {
    id?: string;
    thumbnailUrl?: string;
    localThumbnailPath?: string;
    youtubeId?: string;
  },
  baseUrl: string = EDGE_BASE
): string {
  if (video.localThumbnailPath && video.localThumbnailPath.length > 0) {
    return video.localThumbnailPath.startsWith('file://')
      ? video.localThumbnailPath
      : `file://${video.localThumbnailPath}`;
  }

  if (
    video.thumbnailUrl &&
    !video.thumbnailUrl.includes('placeholder') &&
    video.thumbnailUrl.startsWith('http')
  ) {
    return video.thumbnailUrl;
  }

  const rawId = video.youtubeId || video.id;
  if (!rawId) return 'https://images.unsplash.com/photo-1534447677768-be436bb09401?w=600&auto=format&fit=crop&q=60';

  const cleanId = rawId.startsWith('short_') ? rawId.replace('short_', '') : rawId;
  const cleanBase = baseUrl.endsWith('/') ? baseUrl.slice(0, -1) : baseUrl;
  return `${cleanBase}/api/assets/thumbs/${cleanId}.webp`;
}

export function getStreamUrl(video: {
  localFilePath?: string;
  streamUrl?: string;
}): string {
  if (video.localFilePath && video.localFilePath.length > 0) {
    return video.localFilePath.startsWith('file://')
      ? video.localFilePath
      : `file://${video.localFilePath}`;
  }
  if (video.streamUrl && video.streamUrl.length > 0) {
    if (video.streamUrl.startsWith('http')) {
      return video.streamUrl;
    }
    return `${MEDIA_BASE}/videos/${video.streamUrl}`;
  }
  return '';
}

export function getYoutubeId(video: {
  id: string;
  youtubeId?: string;
  sourceUrl?: string;
}): string {
  if (video.youtubeId && video.youtubeId.length > 0) {
    return video.youtubeId;
  }
  if (video.id.startsWith('short_')) {
    return video.id.replace('short_', '');
  }
  if (video.sourceUrl && video.sourceUrl.includes('v=')) {
    try {
      const match = video.sourceUrl.match(/[?&]v=([^&#]+)/);
      if (match && match[1]) {
        return match[1];
      }
    } catch (_) {}
  }
  return video.id;
}

export function getYoutubeEmbedUrl(youtubeId: string, autoplay: boolean = true): string {
  return `https://www.youtube-nocookie.com/embed/${youtubeId}?autoplay=${
    autoplay ? 1 : 0
  }&modestbranding=1&rel=0&iv_load_policy=3&playsinline=1&disablekb=1`;
}

export function isVideoShort(video?: {
  id?: string;
  duration?: number;
  categoryId?: string;
  sourceUrl?: string;
} | null): boolean {
  if (!video) return false;
  if (video.sourceUrl?.includes('watch?v=')) return false;
  if (video.duration && video.duration > 70) return false;

  if (video.sourceUrl?.includes('/shorts/')) return true;
  if (video.id?.startsWith('short_')) return true;

  if (video.categoryId === 'shorts') {
    return Boolean(video.duration && video.duration > 0 && video.duration <= 70);
  }
  return false;
}

export function formatBytes(bytes: number): string {
  if (!bytes || bytes <= 0) return '0 B';
  if (bytes < 1024 * 1024) {
    return `${(bytes / 1024).toFixed(1)} KB`;
  } else if (bytes < 1024 * 1024 * 1024) {
    return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
  } else {
    return `${(bytes / (1024 * 1024 * 1024)).toFixed(2)} GB`;
  }
}

export function formatDuration(seconds: number): string {
  if (!seconds || seconds <= 0) return '00:00';
  const mins = Math.floor(seconds / 60);
  const secs = seconds % 60;
  if (mins >= 60) {
    const hrs = Math.floor(mins / 60);
    const remMins = mins % 60;
    return `${hrs.toString().padStart(2, '0')}:${remMins.toString().padStart(2, '0')}:${secs
      .toString()
      .padStart(2, '0')}`;
  }
  return `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
}

export function normalizeServerUrl(url: string): string {
  let trimmed = url.trim();
  if (trimmed.endsWith('/')) {
    trimmed = trimmed.substring(0, trimmed.length - 1);
  }
  if (trimmed.startsWith('http://')) {
    console.warn('⚠️ Warning: Using explicit cleartext HTTP connection for ' + trimmed);
    return trimmed;
  }
  if (!trimmed.startsWith('https://')) {
    trimmed = 'https://' + trimmed;
  }
  return trimmed;
}
