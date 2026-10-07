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

export async function recordWatchMetric(videoId: string, profileId: string = 'kids_all', secondsWatched: number = 5, context?: any) {
  const db = await getDatabase(context);
  if (!db) return false;

  try {
    const eventId = 'ev_' + Math.random().toString(36).substring(2, 10);
    const now = new Date().toISOString();

    await db.batch([
      db.prepare('INSERT INTO watch_events (id, video_id, profile_id, seconds_watched, created_at) VALUES (?, ?, ?, ?, ?)')
        .bind(eventId, videoId, profileId, secondsWatched, now),
      db.prepare('UPDATE videos SET views = COALESCE(views, 0) + 1, watch_seconds = COALESCE(watch_seconds, 0) + ? WHERE id = ?')
        .bind(secondsWatched, videoId),
    ]);
    return true;
  } catch (e) {
    console.error('Error recording watch metric:', e);
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
      storage_used_bytes: 2500000000,
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

export function extractYoutubeId(inputUrl: string): string | null {
  const match = inputUrl.match(/(?:v=|\/shorts\/|youtu\.be\/|\/embed\/)([a-zA-Z0-9_-]{11})/);
  return match ? match[1] : null;
}

export async function fetchYoutubeOembed(youtubeId: string) {
  try {
    const url = `https://www.youtube.com/watch?v=${youtubeId}`;
    const res = await fetch(`https://www.youtube.com/oembed?url=${encodeURIComponent(url)}&format=json`);
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
    console.error('oEmbed fetch error:', e);
  }

  return {
    id: youtubeId,
    title: 'Kids Video',
    channel_name: 'KidsTube',
    channel_url: '',
    thumbnail_url: `https://i.ytimg.com/vi/${youtubeId}/hqdefault.jpg`,
  };
}
