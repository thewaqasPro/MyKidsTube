/**
 * Database Facade & Compatibility Layer
 * Delegates to Drizzle ORM domain repositories while preserving 100% backwards-compatibility.
 */
import type { Video, Category, ChildProfile } from '../types/video';
import { API_BASE } from './constants';
import { getEnv } from './env';
import { getDrizzleDb } from '../db';
import * as schema from '../db/schema';
import { CatalogRepository, type UpsertVideoParams } from '../features/catalog/catalog.repository';
import { isValidYoutubeHost, extractYoutubeId, getYoutubeMetadata } from '../shared/utils/youtube';
import { desc, eq } from 'drizzle-orm';

export { isValidYoutubeHost, extractYoutubeId, getYoutubeMetadata };
export const fetchYoutubeOembed = getYoutubeMetadata;
export type { UpsertVideoParams };

export async function getDatabase(context?: unknown): Promise<D1Database | null> {
  try {
    const env = await getEnv(context);
    if (env?.DB) return env.DB;
  } catch {
    // Expected in local Node environment
  }
  return null;
}

export async function getDbData(context?: unknown): Promise<{
  source: string;
  videos: Video[];
  categories: Category[];
  profiles: ChildProfile[];
}> {
  const drizzleDb = await getDrizzleDb(context);

  if (drizzleDb) {
    try {
      const [videos, categories, profileRows] = await Promise.all([
        CatalogRepository.getAllVideos(drizzleDb),
        CatalogRepository.getAllCategories(drizzleDb),
        drizzleDb.select().from(schema.childProfiles),
      ]);

      const profiles: ChildProfile[] = profileRows.map((p) => ({
        id: p.id,
        family_id: p.familyId || '',
        name: p.name,
        avatar_icon: p.avatarIcon || 'kid',
        age_bracket: p.ageBracket || 'all',
      }));

      if (videos.length > 0) {
        return {
          source: 'cloudflare-d1',
          videos,
          categories,
          profiles,
        };
      }
    } catch (e) {
      console.error('Drizzle getDbData query error:', e);
    }
  }

  // Fallback to VPS backend API if local D1 is unpopulated
  try {
    const [catRes, profRes] = await Promise.all([
      fetch(`${API_BASE}/api/v1/catalog`),
      fetch(`${API_BASE}/api/v1/profiles`).catch(() => null),
    ]);

    let videos: Video[] = [];
    let categories: Category[] = [];
    let profiles: ChildProfile[] = [];

    if (catRes.ok) {
      const catData = (await catRes.json()) as any;
      videos = catData.all_videos || [];
      categories = catData.sections?.map((s: any) => s.category) || [];
    }

    if (profRes && profRes.ok) {
      profiles = (await profRes.json()) as ChildProfile[];
    }

    return { source: 'backend-api', videos, categories, profiles };
  } catch (e) {
    console.error('Fallback fetch error:', e);
    return { source: 'error', videos: [], categories: [], profiles: [] };
  }
}

export async function getVideoById(id: string, context?: unknown): Promise<Video | null> {
  const drizzleDb = await getDrizzleDb(context);
  if (drizzleDb) {
    const video = await CatalogRepository.getVideoById(drizzleDb, id);
    if (video) return video;
  }

  const all = await getDbData(context);
  return all.videos.find((v) => v.id === id || v.youtube_id === id) || null;
}

export async function getPendingVideos(context?: unknown): Promise<Video[]> {
  const drizzleDb = await getDrizzleDb(context);
  if (drizzleDb) {
    try {
      const rows = await drizzleDb
        .select()
        .from(schema.videos)
        .where(eq(schema.videos.status, 'pending_download'))
        .orderBy(desc(schema.videos.createdAt));
      return rows.map((r) => ({
        id: r.id,
        title: r.title,
        duration: r.duration ?? 0,
        duration_formatted: r.durationFormatted ?? '00:00',
        category_id: r.categoryId,
        source_url: r.sourceUrl ?? undefined,
        video_file: r.videoFile,
        thumbnail_file: r.thumbnailFile,
        channel_name: r.channelName ?? '',
        channel_icon: r.channelIcon ?? '',
        status: (r.status as any) ?? 'pending_download',
        created_at: r.createdAt,
      }));
    } catch (e) {
      console.error('D1 getPendingVideos error:', e);
    }
  }

  const all = await getDbData(context);
  return all.videos.filter((v) => v.status === 'pending_download');
}

export async function recordWatchMetric(
  videoId: string,
  deviceId = 'kids_all',
  secondsWatched = 5,
  context?: unknown
): Promise<boolean> {
  const db = await getDatabase(context);
  if (!db) return false;

  try {
    const exists = await db
      .prepare('SELECT id FROM videos WHERE id = ? OR youtube_id = ? LIMIT 1')
      .bind(videoId, videoId)
      .first();

    if (!exists) return false;

    const clampedSeconds = Math.max(0, Math.min(86400, Math.floor(secondsWatched)));
    await db
      .prepare('UPDATE videos SET views = views + 1, watch_seconds = watch_seconds + ? WHERE id = ?')
      .bind(clampedSeconds, videoId)
      .run();

    await db
      .prepare(
        'INSERT INTO watch_events (device_id, video_id, seconds_watched, watched_at) VALUES (?, ?, ?, datetime("now"))'
      )
      .bind(deviceId, videoId, clampedSeconds)
      .run();

    return true;
  } catch (e) {
    console.error('Error recording watch metric:', e);
    return false;
  }
}

export async function getStudioStats(context?: unknown) {
  const drizzleDb = await getDrizzleDb(context);
  if (!drizzleDb) return null;

  try {
    const stats = await CatalogRepository.getStudioStorageStats(drizzleDb);
    const [profiles, topVideos] = await Promise.all([
      drizzleDb.select().from(schema.childProfiles),
      drizzleDb
        .select()
        .from(schema.videos)
        .orderBy(desc(schema.videos.views))
        .limit(5),
    ]);

    return {
      total_videos: stats.totalVideos,
      ready_videos: stats.readyVideos,
      pending_videos: stats.pendingVideos,
      total_views: 0,
      total_watch_seconds: 0,
      storage_used_bytes: stats.storageUsedBytes,
      profiles: profiles.map((p) => ({
        id: p.id,
        family_id: p.familyId || '',
        name: p.name,
        avatar_icon: p.avatarIcon || 'kid',
        age_bracket: p.ageBracket || 'all',
      })),
      top_videos: topVideos.map((r) => ({
        id: r.id,
        title: r.title,
        duration: r.duration ?? 0,
        duration_formatted: r.durationFormatted ?? '00:00',
        category_id: r.categoryId,
        video_file: r.videoFile,
        thumbnail_file: r.thumbnailFile,
        channel_name: r.channelName ?? '',
        channel_icon: r.channelIcon ?? '',
        views: r.views ?? 0,
      })),
    };
  } catch (e) {
    console.error('Error fetching studio stats:', e);
    return null;
  }
}

export async function upsertVideo(db: any, params: UpsertVideoParams): Promise<void> {
  const drizzleDb = await getDrizzleDb();
  if (drizzleDb) {
    await CatalogRepository.upsertVideo(drizzleDb, params);
  }
}
