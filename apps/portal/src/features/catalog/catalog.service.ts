import type { DrizzleDb } from '@/db';
import { CatalogRepository } from './catalog.repository';
import { getR2Bucket } from '@/lib/r2';
import { cleanupVpsMedia } from '@/lib/vpsCleanup';
import * as schema from '@/db/schema';
import { eq } from 'drizzle-orm';
import type { Video } from '@/types/video';

export interface DeleteVideosResult {
  deletedCount: number;
  deletedIds: string[];
  vpsCleanup: {
    requested: boolean;
    success?: boolean;
    deletedFiles?: string[];
  };
}

export class CatalogService {
  static async listVideos(db: DrizzleDb): Promise<Video[]> {
    return CatalogRepository.getAllVideos(db);
  }

  static async deleteVideo(
    db: DrizzleDb,
    id: string,
    context?: unknown
  ): Promise<{ success: boolean; notFound?: boolean; vpsCleanup?: boolean }> {
    const found = await CatalogRepository.getVideoById(db, id);
    if (!found) {
      return {
        success: false,
        notFound: true,
      };
    }

    // 1. Delete database record first to guarantee catalog consistency
    await CatalogRepository.deleteVideoById(db, id);

    // 2. R2 asset cleanup (best effort)
    if (found) {
      const r2 = await getR2Bucket(context).catch(() => null);
      if (r2) {
        const toDelete: string[] = [];
        if (found.thumbnail_file) {
          toDelete.push(`thumbnails/${found.thumbnail_file}`, found.thumbnail_file);
        }
        if (found.video_file) {
          toDelete.push(`videos/${found.video_file}`, found.video_file);
        }
        const uniqueKeys = Array.from(new Set(toDelete.filter(Boolean)));
        if (uniqueKeys.length > 0) {
          try {
            await r2.delete(uniqueKeys);
          } catch (r2Err) {
            console.warn('R2 delete error for video:', id, r2Err);
          }
        }
      }
    }

    // 3. VPS disk cleanup (best effort)
    let vpsSuccess = false;
    try {
      const vpsRes = await cleanupVpsMedia([id], context);
      vpsSuccess = Boolean(vpsRes.success);
    } catch (e) {
      console.warn('VPS cleanup trigger failed for video:', id, e);
    }

    return {
      success: true,
      vpsCleanup: vpsSuccess,
    };
  }

  static async deleteVideos(
    db: DrizzleDb,
    ids: string[],
    context?: unknown
  ): Promise<DeleteVideosResult> {
    if (ids.length === 0) {
      return {
        deletedCount: 0,
        deletedIds: [],
        vpsCleanup: { requested: false },
      };
    }

    // 1. Fetch matching videos to get file paths for disk & R2 cleanup
    const foundVideos = await CatalogRepository.getVideosByIds(db, ids);
    const existingIds = foundVideos.map((v) => v.id);

    if (existingIds.length === 0) {
      return {
        deletedCount: 0,
        deletedIds: [],
        vpsCleanup: { requested: false },
      };
    }

    // 2. Delete database records first to guarantee catalog consistency
    const deletedCount = await CatalogRepository.deleteVideosByIds(db, existingIds);

    // 3. Batch R2 asset cleanup in a single subrequest call (prevents Cloudflare subrequest limit)
    const r2 = await getR2Bucket(context).catch(() => null);
    if (r2 && foundVideos.length > 0) {
      try {
        const toDelete: string[] = [];
        for (const v of foundVideos) {
          if (v.thumbnail_file) {
            toDelete.push(`thumbnails/${v.thumbnail_file}`, v.thumbnail_file);
          }
          if (v.video_file) {
            toDelete.push(`videos/${v.video_file}`, v.video_file);
          }
        }
        const uniqueKeys = Array.from(new Set(toDelete.filter(Boolean)));
        if (uniqueKeys.length > 0) {
          // Cloudflare R2 bucket.delete accepts an array of keys in a single operation
          await r2.delete(uniqueKeys);
        }
      } catch (r2Err) {
        console.warn('R2 batch cleanup error:', r2Err);
      }
    }

    // 4. VPS disk cleanup (pass video IDs matching Python SAFE_ID_REGEX)
    let vpsResult = { requested: false as boolean, success: false, deletedFiles: [] as string[] };
    if (existingIds.length > 0) {
      try {
        const vpsRes = await cleanupVpsMedia(existingIds, context);
        vpsResult = {
          requested: true,
          success: vpsRes.success,
          deletedFiles: vpsRes.deleted_files || vpsRes.deleted_ids || [],
        };
      } catch (e) {
        console.warn('VPS cleanup trigger failed:', e);
      }
    }

    return {
      deletedCount: existingIds.length,
      deletedIds: existingIds,
      vpsCleanup: vpsResult,
    };
  }

  static async updateVideoStatus(
    db: DrizzleDb,
    id: string,
    status: 'pending_download' | 'ready' | 'error'
  ): Promise<boolean> {
    const res = await db
      .update(schema.videos)
      .set({ status })
      .where(eq(schema.videos.id, id));
    return Boolean(res);
  }
}
