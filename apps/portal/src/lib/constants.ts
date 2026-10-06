export const API_BASE = "https://kidsapi.waqas.pro";
export const MEDIA_BASE = "https://kidsapi.waqas.pro/media";

export function getThumbnailUrl(video: { thumbnail_file?: string; thumbnail_url?: string }): string {
  if (video.thumbnail_url) return video.thumbnail_url;
  if (!video.thumbnail_file) return "/placeholder-thumb.webp";
  if (video.thumbnail_file.startsWith("http")) return video.thumbnail_file;
  return `${MEDIA_BASE}/thumbs/${video.thumbnail_file}?v=1`;
}

export function getStreamUrl(video: { video_file?: string; stream_url?: string }): string {
  if (video.stream_url) return video.stream_url;
  if (!video.video_file) return "";
  if (video.video_file.startsWith("http")) return video.video_file;
  return `${MEDIA_BASE}/videos/${video.video_file}`;
}

export function getChannelIconUrl(video: { channel_icon?: string; channel_icon_url?: string }): string | null {
  if (video.channel_icon_url) return video.channel_icon_url;
  if (!video.channel_icon) return null;
  if (video.channel_icon.startsWith("http")) return video.channel_icon;
  return `${MEDIA_BASE}/thumbs/${video.channel_icon}`;
}
