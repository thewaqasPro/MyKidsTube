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

    // 2. R2 asset cleanup (best effort)
    const r2 = await getR2Bucket(context).catch(() => null);
    if (r2) {
      for (const v of foundVideos) {
        const toDelete: string[] = [];
        if (v.thumbnail_file) {
          toDelete.push(`thumbnails/${v.thumbnail_file}`, v.thumbnail_file);
        }
        if (v.video_file) {
          toDelete.push(`videos/${v.video_file}`, v.video_file);
        }
        await Promise.allSettled(toDelete.map((k) => r2.delete(k)));
      }
    }

    // 3. VPS disk cleanup (best effort)
    const filesToClean = foundVideos
      .flatMap((v) => [v.video_file, v.thumbnail_file])
      .filter(Boolean) as string[];

    let vpsResult = { requested: false as boolean, success: false, deletedFiles: [] as string[] };
    if (filesToClean.length > 0) {
      try {
        const vpsRes = await cleanupVpsMedia(filesToClean, context);
        vpsResult = {
          requested: true,
          success: vpsRes.success,
          deletedFiles: vpsRes.deleted_files || vpsRes.deleted_ids || [],
        };
      } catch (e) {
        console.warn('VPS cleanup trigger failed:', e);
      }
    }

    // 4. Delete records from database
    const deletedCount = await CatalogRepository.deleteVideosByIds(db, ids);

    return {
      deletedCount,
      deletedIds: ids,
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
