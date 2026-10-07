export interface Video {
  id: string;
  title: string;
  duration: number;
  duration_formatted: string;
  category_id: string;
  source_url?: string;
  video_file: string;
  thumbnail_file: string;
  channel_name: string;
  channel_icon: string;
  stream_url?: string;
  thumbnail_url?: string;
  channel_icon_url?: string;
  views?: number;
  watch_seconds?: number;
  file_verified?: number;
  youtube_id?: string;
  status?: 'pending_download' | 'downloading' | 'processing' | 'ready' | 'error';
  created_at?: string;
}

export interface Category {
  id: string;
  name: string;
  icon?: string;
  display_order?: number;
}

export interface ChildProfile {
  id: string;
  family_id: string;
  name: string;
  avatar_icon?: string;
  age_bracket?: string;
}
