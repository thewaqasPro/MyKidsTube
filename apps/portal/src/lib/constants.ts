export const API_BASE = "https://kidsapi.waqas.pro";
export const MEDIA_BASE = "https://kidsapi.waqas.pro/media";
export const EDGE_BASE = "https://mykidstube.kidstube.workers.dev";

export function getThumbnailUrl(video: { id?: string; thumbnail_file?: string; thumbnail_url?: string; youtube_id?: string }): string {
  if (video.thumbnail_url && !video.thumbnail_url.includes('placeholder') && video.thumbnail_url.startsWith('http')) {
    return video.thumbnail_url;
  }
  const file = video.thumbnail_file || (video.youtube_id || video.id ? `${video.youtube_id || video.id}.webp` : '');
  if (!file) return "/placeholder-thumb.webp";
  if (file.startsWith("http")) return file;
  return `/api/assets/thumbs/${file}`;
}

export function getStreamUrl(video: { video_file?: string; stream_url?: string }): string {
  if (video.stream_url) return video.stream_url;
  if (!video.video_file) return "";
  if (video.video_file.startsWith("http")) return video.video_file;
  return `${MEDIA_BASE}/videos/${video.video_file}`;
}

export function getChannelIconUrl(video: { channel_icon?: string; channel_icon_url?: string }): string | null {
  const icon = video.channel_icon_url || video.channel_icon;
  if (!icon) return null;
  if (icon.startsWith("http")) return icon;
  return `/api/assets/thumbs/${icon}`;
}

export function getYoutubeId(video: { id: string; youtube_id?: string }): string {
  const raw = video.youtube_id || video.id;
  return raw.startsWith("short_") ? raw.replace("short_", "") : raw;
}

export function getYoutubeEmbedUrl(youtubeId: string, autoplay: boolean = true): string {
  return `https://www.youtube-nocookie.com/embed/${youtubeId}?autoplay=${autoplay ? 1 : 0}&modestbranding=1&rel=0&iv_load_policy=3&playsinline=1`;
}

export function isSelfHosted(video: { status?: string; file_verified?: number; video_file?: string }): boolean {
  return video.status === 'ready' && Boolean(video.file_verified) && Boolean(video.video_file);
}

export function isVideoShort(video?: { id?: string; duration?: number; category_id?: string; source_url?: string } | null): boolean {
  if (!video) return false;
  if (video.id?.startsWith('short_') || video.source_url?.includes('/shorts/')) return true;
  if (video.duration && video.duration > 0) return video.duration <= 70;
  return video.category_id === 'shorts';
}

