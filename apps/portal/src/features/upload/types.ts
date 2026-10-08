export interface ExtractedVideo {
  id: string;
  title: string;
  channel_name: string;
  thumbnail_url: string;
  youtube_url: string;
}

export interface ExtractedPlaylist {
  playlist_id: string;
  playlist_title: string;
  total_discovered: number;
  count: number;
  videos: ExtractedVideo[];
}

export interface SubmitResult {
  success: boolean;
  message: string;
  count: number;
  videos: any[];
}
