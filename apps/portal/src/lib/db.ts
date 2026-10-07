import type { Video, Category, ChildProfile } from '../types/video';
import { API_BASE, getYoutubeId } from './constants';

export async function getDatabase(context?: any) {
  try {
    const { env } = await import('cloudflare:workers');
    if ((env as any)?.DB) return (env as any).DB;
  } catch {
    // Expected in local Node environment
  }

  return null;
}

export async function getDbData(context?: any) {
  const db = await getDatabase(context);

  if (db) {
    try {
      const [vRes, cRes, pRes] = await Promise.all([
        db.prepare('SELECT * FROM videos ORDER BY created_at DESC').all(),
        db.prepare('SELECT * FROM categories ORDER BY display_order ASC').all(),
        db.prepare('SELECT * FROM child_profiles').all(),
      ]);

      return {
        source: 'cloudflare-d1',
        videos: (vRes.results as unknown as Video[]) || [],
        categories: (cRes.results as unknown as Category[]) || [],
        profiles: (pRes.results as unknown as ChildProfile[]) || [],
      };
    } catch (e) {
      console.error('D1 query error:', e);
    }
  }

  // Fallback to backend API
  try {
    const [catRes, profRes] = await Promise.all([
      fetch(`${API_BASE}/api/v1/catalog`),
      fetch(`${API_BASE}/api/v1/profiles`).catch(() => null),
    ]);

    let videos: Video[] = [];
    let categories: Category[] = [];
    let profiles: ChildProfile[] = [];

    if (catRes.ok) {
      const catData = await catRes.json();
      videos = catData.all_videos || [];
      categories = catData.sections?.map((s: any) => s.category) || [];
    }

    if (profRes && profRes.ok) {
      profiles = await profRes.json();
    }

    return { source: 'backend-api', videos, categories, profiles };
  } catch (e) {
    console.error('Fallback fetch error:', e);
    return { source: 'error', videos: [], categories: [], profiles: [] };
  }
}

export async function getVideoById(id: string, context?: any): Promise<Video | null> {
  const db = await getDatabase(context);
  if (db) {
    try {
      const res = await db.prepare('SELECT * FROM videos WHERE id = ? OR youtube_id = ? LIMIT 1').bind(id, id).first();
      if (res) return res as unknown as Video;
    } catch (e) {
      console.error('D1 getVideoById error:', e);
    }
  }

  // Fallback: search in getDbData
  const all = await getDbData(context);
  return all.videos.find((v) => v.id === id || v.youtube_id === id) || null;
}

export async function getPendingVideos(context?: any): Promise<Video[]> {
  const db = await getDatabase(context);
  if (db) {
    try {
      const res = await db.prepare("SELECT * FROM videos WHERE status = 'pending_download' ORDER BY created_at DESC").all();
      return (res.results as unknown as Video[]) || [];
    } catch (e) {
      console.error('D1 getPendingVideos error:', e);
    }
  }
  const all = await getDbData(context);
  return all.videos.filter((v) => v.status === 'pending_download');
}

export async function recordWatchMetric(
  videoId: string,
  deviceId: string = 'kids_all',
  secondsWatched: number = 5,
  context?: any
): Promise<boolean> {
  const db = await getDatabase(context);
  if (!db) return false;

  try {
    // Validate video existence
    const exists = await db.prepare('SELECT id FROM videos WHERE id = ? OR youtube_id = ? LIMIT 1').bind(videoId, videoId).first();
    if (!exists) {
      console.warn(`recordWatchMetric rejected: Video ${videoId} does not exist`);
      return false;
    }

    // Clamp seconds_watched
    const clampedSeconds = Math.max(0, Math.min(86400, Math.floor(secondsWatched)));
    const eventId = 'ev_' + crypto.randomUUID();
    const now = new Date().toISOString();

    await db.batch([
      db.prepare('INSERT INTO watch_events (id, video_id, device_id, seconds_watched, event_at) VALUES (?, ?, ?, ?, ?)')
        .bind(eventId, videoId, deviceId, clampedSeconds, now),
      db.prepare('UPDATE videos SET views = COALESCE(views, 0) + 1, watch_seconds = COALESCE(watch_seconds, 0) + ? WHERE id = ?')
        .bind(clampedSeconds, videoId),
    ]);
    return true;
  } catch (e: any) {
    console.error('Graceful degradation in recordWatchMetric:', e?.message || e);
    return false;
  }
}

export async function getStudioStats(context?: any) {
  const db = await getDatabase(context);
  if (!db) {
    const all = await getDbData(context);
    const ready = all.videos.filter((v) => v.status === 'ready').length;
    return {
      total_videos: all.videos.length,
      ready_videos: ready,
      pending_videos: all.videos.length - ready,
      total_views: all.videos.reduce((sum, v) => sum + (v.views || 0), 0),
      total_watch_seconds: all.videos.reduce((sum, v) => sum + (v.watch_seconds || 0), 0),
      storage_used_bytes: null, // Unavailable without database connection
      categories_count: all.categories.length,
      profiles_count: all.profiles.length,
      top_videos: all.videos.slice(0, 5),
    };
  }

  try {
    const [counts, topVideos, profiles] = await Promise.all([
      db.prepare(`
        SELECT 
          COUNT(*) as total_videos,
          SUM(CASE WHEN status = 'ready' THEN 1 ELSE 0 END) as ready_videos,
          SUM(CASE WHEN status != 'ready' OR status IS NULL THEN 1 ELSE 0 END) as pending_videos,
          COALESCE(SUM(views), 0) as total_views,
          COALESCE(SUM(watch_seconds), 0) as total_watch_seconds,
          COALESCE(SUM(file_size_bytes), 0) as storage_bytes
        FROM videos
      `).first(),
      db.prepare('SELECT * FROM videos ORDER BY views DESC, watch_seconds DESC LIMIT 5').all(),
      db.prepare('SELECT * FROM child_profiles').all(),
    ]);

    return {
      total_videos: Number(counts?.total_videos || 0),
      ready_videos: Number(counts?.ready_videos || 0),
      pending_videos: Number(counts?.pending_videos || 0),
      total_views: Number(counts?.total_views || 0),
      total_watch_seconds: Number(counts?.total_watch_seconds || 0),
      storage_used_bytes: Number(counts?.storage_bytes || 0),
      profiles: (profiles.results as unknown as ChildProfile[]) || [],
      top_videos: (topVideos.results as unknown as Video[]) || [],
    };
  } catch (e) {
    console.error('Error fetching studio stats:', e);
    return null;
  }
}

export function isValidYoutubeHost(inputUrl: string): boolean {
  try {
    const url = new URL(inputUrl);
    const host = url.hostname.toLowerCase();
    return ['youtube.com', 'www.youtube.com', 'youtu.be', 'm.youtube.com'].includes(host);
  } catch {
    return false;
  }
}

export function extractYoutubeId(inputUrl: string): string | null {
  const trimmed = inputUrl.trim();
  if (/^[a-zA-Z0-9_-]{11}$/.test(trimmed)) {
    return trimmed;
  }

  try {
    const url = new URL(trimmed);
    const host = url.hostname.toLowerCase();
    if (!['youtube.com', 'www.youtube.com', 'youtu.be', 'm.youtube.com'].includes(host)) {
      return null;
    }

    if (host === 'youtu.be') {
      const seg = url.pathname.slice(1).split('/')[0];
      return /^[a-zA-Z0-9_-]{11}$/.test(seg) ? seg : null;
    }

    if (url.pathname.includes('/shorts/')) {
      const match = url.pathname.match(/\/shorts\/([a-zA-Z0-9_-]{11})/);
      return match ? match[1] : null;
    }

    if (url.pathname.includes('/embed/')) {
      const match = url.pathname.match(/\/embed\/([a-zA-Z0-9_-]{11})/);
      return match ? match[1] : null;
    }

    const v = url.searchParams.get('v');
    if (v && /^[a-zA-Z0-9_-]{11}$/.test(v)) {
      return v;
    }
  } catch {
    return null;
  }

  return null;
}

export async function fetchYoutubeOembed(youtubeId: string, timeoutMs = 5000) {
  try {
    const url = `https://www.youtube.com/watch?v=${youtubeId}`;
    const res = await fetch(
      `https://www.youtube.com/oembed?url=${encodeURIComponent(url)}&format=json`,
      { signal: AbortSignal.timeout(timeoutMs) }
    );
    if (res.ok) {
      const data: any = await res.json();
      return {
        id: youtubeId,
        title: data.title || 'Kids Video',
        channel_name: data.author_name || 'YouTube Kids',
        channel_url: data.author_url || '',
        thumbnail_url: data.thumbnail_url || `https://i.ytimg.com/vi/${youtubeId}/hqdefault.jpg`,
      };
    }
  } catch (e) {
    console.error(`oEmbed fetch error for ${youtubeId}:`, e);
  }

  return {
    id: youtubeId,
    title: 'Kids Video',
    channel_name: 'KidsTube',
    channel_url: '',
    thumbnail_url: `https://i.ytimg.com/vi/${youtubeId}/hqdefault.jpg`,
  };
}

export interface UpsertVideoParams {
  id: string; // Plain 11-char YouTube ID
  title: string;
  duration?: number;
  durationFormatted?: string;
  categoryId?: string;
  sourceUrl?: string;
  channelName?: string;
  channelIcon?: string;
  thumbnailUrl?: string;
  quality?: string;
  status?: string;
  allowedProfileIds?: string[];
  fileVerified?: number;
}

export async function upsertVideo(db: any, params: UpsertVideoParams): Promise<void> {
  if (!db) return;

  const now = new Date().toISOString();
  const videoId = params.id;
  const isShort = params.categoryId === 'shorts' || params.sourceUrl?.includes('/shorts/');
  const duration = params.duration !== undefined ? params.duration : 0;
  const durationFormatted = params.durationFormatted || (duration > 0 ? `${Math.floor(duration / 60)}:${(duration % 60).toString().padStart(2, '0')}` : '--:--');
  const categoryId = params.categoryId || (isShort ? 'shorts' : 'cartoons');
  const sourceUrl = params.sourceUrl || (isShort ? `https://www.youtube.com/shorts/${videoId}` : `https://www.youtube.com/watch?v=${videoId}`);
  const videoFile = `${videoId}.mp4`;
  const thumbFile = `${videoId}.webp`;
  const channelIcon = params.channelIcon || params.thumbnailUrl || '';
  const channelName = params.channelName || 'YouTube Kids';
  const quality = params.quality || '720p';
  const status = params.status || 'pending_download';
  const fileVerified = params.fileVerified ?? 0;

  await db.prepare(`
    INSERT INTO videos (
      id, title, duration, duration_formatted, category_id, source_url, 
      video_file, thumbnail_file, file_size_bytes, quality, created_at, 
      channel_name, channel_icon, status, youtube_id, file_verified, views, watch_seconds
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0, 0)
    ON CONFLICT(id) DO UPDATE SET 
      title = excluded.title,
      category_id = excluded.category_id,
      channel_name = excluded.channel_name,
      channel_icon = excluded.channel_icon,
      source_url = excluded.source_url,
      youtube_id = excluded.youtube_id,
      status = excluded.status
  `).bind(
    videoId,
    params.title,
    duration,
    durationFormatted,
    categoryId,
    sourceUrl,
    videoFile,
    thumbFile,
    0,
    quality,
    now,
    channelName,
    channelIcon,
    status,
    videoId,
    fileVerified
  ).run();

  const profileIds = params.allowedProfileIds && params.allowedProfileIds.length > 0 
    ? params.allowedProfileIds 
    : ['kids_all'];

  for (const pId of profileIds) {
    await db.prepare(`
      INSERT OR IGNORE INTO profile_video_assignments (profile_id, video_id, category_id, created_at)
      VALUES (?, ?, ?, ?)
    `).bind(pId, videoId, categoryId, now).run();
  }
}
