export interface ChildProfile {
  id: string;
  name: string;
  avatarIcon: string; // 'bear' | 'rocket' | 'lion' | 'unicorn' | 'panda' | 'star' | 'teddy'
  ageBracket: string; // 'all' | 'toddler' | 'older'
}

export function getProfileEmoji(avatarIcon: string): string {
  switch (avatarIcon) {
    case 'rocket':
      return '🚀';
    case 'lion':
      return '🦁';
    case 'unicorn':
      return '🦄';
    case 'panda':
      return '🐼';
    case 'star':
    case 'stars':
      return '⭐';
    case 'teddy':
      return '🧸';
    case 'bear':
    default:
      return '🐻';
  }
}

export interface LocalWatchEvent {
  id: string;
  videoId: string;
  videoTitle?: string;
  categoryId?: string;
  deviceId: string;
  profileId?: string;
  profileName?: string;
  secondsWatched: number;
  videoDuration: number;
  completionRate: number;
  isCompleted: boolean;
  isSkipped: boolean;
  watchedAt: number; // timestamp in ms
  isSynced: boolean;
}

export interface WatchAnalytics {
  totalSeconds: number;
  totalWatchedFormatted: string;
  totalViews: number;
  completionRate: number;
  mostWatchedCategory: string;
  recentTitles: string[];
}
