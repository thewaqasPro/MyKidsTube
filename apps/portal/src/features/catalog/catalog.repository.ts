import { eq, inArray, desc, asc, sql } from 'drizzle-orm';
import type { DrizzleDb } from '@/db';
import * as schema from '@/db/schema';
import type { Video, Category } from '@/types/video';

export function mapVideoRowToVideo(row: typeof schema.videos.$inferSelect): Video {
  return {
    id: row.id,
    title: row.title,
    duration: row.duration ?? 0,
    duration_formatted: row.durationFormatted ?? '00:00',
    category_id: row.categoryId,
    source_url: row.sourceUrl ?? undefined,
    video_file: row.videoFile,
    thumbnail_file: row.thumbnailFile,
    channel_name: row.channelName ?? '',
    channel_icon: row.channelIcon ?? '',
    views: row.views ?? 0,
    watch_seconds: row.watchSeconds ?? 0,
    file_verified: row.fileVerified ?? 0,
    youtube_id: row.youtubeId ?? undefined,
    status: (row.status as any) ?? 'pending_download',
    created_at: row.createdAt,
  };
}

export function mapCategoryRowToCategory(row: typeof schema.categories.$inferSelect): Category {
  return {
    id: row.id,
    name: row.name,
    icon: row.icon ?? 'category',
    display_order: row.displayOrder ?? 0,
  };
}

export class CatalogRepository {
  static async getAllVideos(db: DrizzleDb): Promise<Video[]> {
    const rows = await db
      .select()
      .from(schema.videos)
      .orderBy(desc(schema.videos.createdAt));
    return rows.map(mapVideoRowToVideo);
  }

  static async getAllCategories(db: DrizzleDb): Promise<Category[]> {
    const rows = await db
      .select()
      .from(schema.categories)
      .orderBy(asc(schema.categories.displayOrder));
    return rows.map(mapCategoryRowToCategory);
  }

  static async getVideoById(db: DrizzleDb, id: string): Promise<Video | null> {
    const row = await db
      .select()
      .from(schema.videos)
      .where(eq(schema.videos.id, id))
      .get();
    return row ? mapVideoRowToVideo(row) : null;
  }

  static async getVideosByIds(db: DrizzleDb, ids: string[]): Promise<Video[]> {
    if (ids.length === 0) return [];
    const rows = await db
      .select()
      .from(schema.videos)
      .where(inArray(schema.videos.id, ids));
    return rows.map(mapVideoRowToVideo);
  }

  static async deleteVideosByIds(db: DrizzleDb, ids: string[]): Promise<number> {
    if (ids.length === 0) return 0;

    // Remove foreign references first if present
    await db
      .delete(schema.profileVideoAssignments)
      .where(inArray(schema.profileVideoAssignments.videoId, ids))
      .catch(() => null);

    await db
      .delete(schema.watchEvents)
      .where(inArray(schema.watchEvents.videoId, ids))
      .catch(() => null);

    const res = await db
      .delete(schema.videos)
      .where(inArray(schema.videos.id, ids));

    return (res as any)?.rowsAffected ?? ids.length;
  }

  static async getStudioStorageStats(db: DrizzleDb) {
    const countRes = await db
      .select({
        total: sql<number>`count(*)`,
        ready: sql<number>`sum(case when ${schema.videos.status} = 'ready' then 1 else 0 end)`,
        pending: sql<number>`sum(case when ${schema.videos.status} != 'ready' then 1 else 0 end)`,
        totalBytes: sql<number>`sum(${schema.videos.fileSizeBytes})`,
      })
      .from(schema.videos)
      .get();

    return {
      totalVideos: countRes?.total ?? 0,
      readyVideos: countRes?.ready ?? 0,
      pendingVideos: countRes?.pending ?? 0,
      storageUsedBytes: countRes?.totalBytes ?? 0,
    };
  }

  static async upsertVideo(db: DrizzleDb, params: UpsertVideoParams): Promise<void> {
    const now = new Date().toISOString();
    const videoId = params.id;
    const isShort = params.categoryId === 'shorts' || params.sourceUrl?.includes('/shorts/');
    const duration = params.duration !== undefined ? params.duration : 0;
    const durationFormatted =
      params.durationFormatted ||
      (duration > 0
        ? `${Math.floor(duration / 60)}:${(duration % 60).toString().padStart(2, '0')}`
        : '--:--');
    const categoryId = params.categoryId || (isShort ? 'shorts' : 'cartoons');
    const sourceUrl =
      params.sourceUrl ||
      (isShort
        ? `https://www.youtube.com/shorts/${videoId}`
        : `https://www.youtube.com/watch?v=${videoId}`);
    const videoFile = `${videoId}.mp4`;
    const thumbFile = `${videoId}.webp`;
    const channelIcon = params.channelIcon || params.thumbnailUrl || '';
    const channelName = params.channelName || 'YouTube Kids';
    const quality = params.quality || '720p';
    const status = params.status || 'pending_download';
    const fileVerified = params.fileVerified ?? 0;

    await db
      .insert(schema.videos)
      .values({
        id: videoId,
        title: params.title,
        duration,
        durationFormatted,
        categoryId,
        sourceUrl,
        videoFile,
        thumbnailFile: thumbFile,
        fileSizeBytes: 0,
        quality,
        createdAt: now,
        channelName,
        channelIcon,
        status,
        youtubeId: videoId,
        fileVerified,
        views: 0,
        watchSeconds: 0,
      })
      .onConflictDoUpdate({
        target: schema.videos.id,
        set: {
          title: params.title,
          categoryId,
          channelName,
          channelIcon,
          sourceUrl,
          youtubeId: videoId,
          status,
        },
      });

    const profileIds =
      params.allowedProfileIds && params.allowedProfileIds.length > 0
        ? params.allowedProfileIds
        : ['kids_all'];

    for (const pId of profileIds) {
      await db
        .insert(schema.profileVideoAssignments)
        .values({
          profileId: pId,
          videoId,
          categoryId,
          createdAt: now,
        })
        .onConflictDoNothing()
        .catch(() => null);
    }
  }
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

