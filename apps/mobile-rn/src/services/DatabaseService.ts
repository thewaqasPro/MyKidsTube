import * as SQLite from 'expo-sqlite';
import * as FileSystem from 'expo-file-system/legacy';
import { VideoItem, CategoryItem, DownloadStatus } from '../types/video';
import { ChildProfile, LocalWatchEvent, WatchAnalytics } from '../types/profile';
import { DEFAULT_VPS_URL } from '../utils/urlHelpers';

const DB_NAME = 'kidstube_v2.db';

class DatabaseService {
  private static instance: DatabaseService;
  private dbPromise: Promise<SQLite.SQLiteDatabase> | null = null;

  public static getInstance(): DatabaseService {
    if (!DatabaseService.instance) {
      DatabaseService.instance = new DatabaseService();
    }
    return DatabaseService.instance;
  }

  private constructor() {}

  public async getDatabase(): Promise<SQLite.SQLiteDatabase> {
    if (!this.dbPromise) {
      this.dbPromise = this.initDB();
    }
    return this.dbPromise;
  }

  private async initDB(): Promise<SQLite.SQLiteDatabase> {
    try {
      const db = await SQLite.openDatabaseAsync(DB_NAME);
      await this.configureAndMigrate(db);
      return db;
    } catch (e) {
      console.error('Failed to open database, attempting recovery:', e);
      return await this.recoverCorruptedDatabase();
    }
  }

  private async configureAndMigrate(db: SQLite.SQLiteDatabase): Promise<void> {
    await db.execAsync(`
      CREATE TABLE IF NOT EXISTS categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        icon TEXT DEFAULT 'category',
        display_order INTEGER DEFAULT 0
      );

      CREATE TABLE IF NOT EXISTS videos (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        duration INTEGER DEFAULT 0,
        duration_formatted TEXT DEFAULT '00:00',
        category_id TEXT NOT NULL,
        source_url TEXT DEFAULT '',
        stream_url TEXT NOT NULL,
        thumbnail_url TEXT NOT NULL,
        channel_name TEXT,
        channel_icon_url TEXT,
        local_file_path TEXT,
        local_thumbnail_path TEXT,
        file_size_bytes INTEGER DEFAULT 0,
        quality TEXT DEFAULT '720p',
        download_status INTEGER DEFAULT 0,
        status TEXT DEFAULT 'pending_download',
        youtube_id TEXT
      );

      CREATE TABLE IF NOT EXISTS settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      );

      CREATE TABLE IF NOT EXISTS favorites (
        video_id TEXT PRIMARY KEY,
        created_at INTEGER
      );

      CREATE TABLE IF NOT EXISTS local_child_profiles (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        avatar_icon TEXT DEFAULT 'bear',
        age_bracket TEXT DEFAULT 'all',
        created_at INTEGER
      );

      CREATE TABLE IF NOT EXISTS local_watch_events (
        id TEXT PRIMARY KEY,
        video_id TEXT NOT NULL,
        video_title TEXT,
        category_id TEXT,
        device_id TEXT DEFAULT 'kids_tablet',
        profile_id TEXT,
        profile_name TEXT,
        seconds_watched INTEGER NOT NULL,
        video_duration INTEGER DEFAULT 0,
        completion_rate REAL DEFAULT 0.0,
        is_completed INTEGER DEFAULT 0,
        is_skipped INTEGER DEFAULT 0,
        watched_at INTEGER NOT NULL,
        is_synced INTEGER DEFAULT 0
      );

      CREATE INDEX IF NOT EXISTS idx_watch_events_watched_at ON local_watch_events (watched_at);
      CREATE INDEX IF NOT EXISTS idx_watch_events_synced ON local_watch_events (is_synced);
      CREATE INDEX IF NOT EXISTS idx_watch_events_profile ON local_watch_events (profile_id, watched_at);
    `);

    // Ensure default settings (default vps url if none exists)
    const existingUrl = await db.getFirstAsync<{ value: string }>(
      'SELECT value FROM settings WHERE key = ?',
      ['vps_url']
    );
    if (!existingUrl) {
      await db.runAsync(
        'INSERT OR IGNORE INTO settings (key, value) VALUES (?, ?)',
        ['vps_url', DEFAULT_VPS_URL]
      );
    }
  }

  public async recoverCorruptedDatabase(): Promise<SQLite.SQLiteDatabase> {
    try {
      if (this.dbPromise) {
        try {
          const oldDb = await this.dbPromise;
          await oldDb.closeAsync();
        } catch (_) {}
      }
      await SQLite.deleteDatabaseAsync(DB_NAME);
    } catch (_) {}
    const newDb = await SQLite.openDatabaseAsync(DB_NAME);
    await this.configureAndMigrate(newDb);
    this.dbPromise = Promise.resolve(newDb);
    return newDb;
  }

  // --- Category CRUD ---
  public async upsertCategory(category: CategoryItem): Promise<void> {
    try {
      const db = await this.getDatabase();
      await db.runAsync(
        'INSERT OR REPLACE INTO categories (id, name, icon, display_order) VALUES (?, ?, ?, ?)',
        [category.id, category.name, category.icon, category.displayOrder]
      );
    } catch (e) {
      console.error('upsertCategory error:', e);
    }
  }

  public async getAllCategories(): Promise<CategoryItem[]> {
    try {
      const db = await this.getDatabase();
      const rows = await db.getAllAsync<{
        id: string;
        name: string;
        icon: string;
        display_order: number;
      }>('SELECT * FROM categories ORDER BY display_order ASC');
      return rows.map((r) => ({
        id: r.id,
        name: r.name,
        icon: r.icon || 'category',
        displayOrder: r.display_order ?? 0,
      }));
    } catch (_) {
      return [];
    }
  }

  // --- Video CRUD & Batch Operations ---
  public async batchUpsertCatalog(
    videos: VideoItem[],
    categories: CategoryItem[]
  ): Promise<void> {
    try {
      const db = await this.getDatabase();
      await db.withExclusiveTransactionAsync(async (txn) => {
        // Upsert categories
        for (const cat of categories) {
          await txn.runAsync(
            'INSERT OR REPLACE INTO categories (id, name, icon, display_order) VALUES (?, ?, ?, ?)',
            [cat.id, cat.name, cat.icon, cat.displayOrder]
          );
        }

        // Upsert videos, preserving existing local downloads
        for (const v of videos) {
          const existing = await txn.getFirstAsync<{
            local_file_path?: string;
            local_thumbnail_path?: string;
            download_status?: number;
          }>('SELECT local_file_path, local_thumbnail_path, download_status FROM videos WHERE id = ?', [v.id]);

          let localPath = v.localFilePath;
          let localThumb = v.localThumbnailPath;
          let dlStatus = v.downloadStatus;

          if (existing) {
            if (existing.local_file_path) {
              localPath = existing.local_file_path;
            }
            if (existing.local_thumbnail_path) {
              localThumb = existing.local_thumbnail_path;
            }
            if (
              existing.download_status !== undefined &&
              existing.download_status === DownloadStatus.downloaded
            ) {
              dlStatus = DownloadStatus.downloaded;
            }
          }

          await txn.runAsync(
            `INSERT OR REPLACE INTO videos (
              id, title, duration, duration_formatted, category_id,
              source_url, stream_url, thumbnail_url, channel_name,
              channel_icon_url, local_file_path, local_thumbnail_path,
              file_size_bytes, quality, download_status, status, youtube_id
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
            [
              v.id,
              v.title,
              v.duration,
              v.durationFormatted,
              v.categoryId,
              v.sourceUrl,
              v.streamUrl,
              v.thumbnailUrl,
              v.channelName || null,
              v.channelIconUrl || null,
              localPath || null,
              localThumb || null,
              v.fileSizeBytes,
              v.quality,
              dlStatus,
              v.status,
              v.youtubeId || null,
            ]
          );
        }
      });
    } catch (e) {
      console.error('Database batchUpsertCatalog error:', e);
    }
  }

  /**
   * Prunes videos from SQLite that no longer exist on the server, and deletes their
   * downloaded media files. Gated by allowEmpty guard and maxPruneRatio safety cap.
   */
  public async pruneRemovedVideos(
    validServerVideoIds: string[],
    options: {
      allowEmpty?: boolean;
      maxPruneRatio?: number;
      force?: boolean;
    } = {}
  ): Promise<string[]> {
    const { allowEmpty = false, maxPruneRatio = 0.5, force = false } = options;
    try {
      const db = await this.getDatabase();
      const validSet = new Set(validServerVideoIds);

      const allLocal = await db.getAllAsync<{
        id: string;
        local_file_path?: string;
        local_thumbnail_path?: string;
      }>('SELECT id, local_file_path, local_thumbnail_path FROM videos');

      if (allLocal.length === 0) return [];

      // 1. Guard: Never wipe on an empty list without explicit allowEmpty flag
      if (validSet.size === 0 && !allowEmpty) {
        console.warn(
          'DatabaseService: pruneRemovedVideos called with empty validServerVideoIds and allowEmpty=false. Skipping destructive prune to protect local library.'
        );
        return [];
      }

      const toDelete = allLocal.filter((row) => !validSet.has(row.id));
      if (toDelete.length === 0) return [];

      // 2. Safety Cap: Never delete > maxPruneRatio (default 50%) in one sync without explicit confirmation
      const pruneRatio = toDelete.length / allLocal.length;
      if (!force && allLocal.length > 2 && pruneRatio > maxPruneRatio) {
        console.warn(
          `DatabaseService: pruneRemovedVideos safety cap blocked deletion of ${toDelete.length}/${allLocal.length} videos (${(pruneRatio * 100).toFixed(1)}% > ${(maxPruneRatio * 100).toFixed(1)}%). Explicit confirmation required.`
        );
        return [];
      }

      const deletedIds: string[] = [];
      for (const row of toDelete) {
        // Delete local media files
        if (row.local_file_path) {
          try {
            await FileSystem.deleteAsync(row.local_file_path, { idempotent: true });
          } catch (_) {}
        }
        if (row.local_thumbnail_path) {
          try {
            await FileSystem.deleteAsync(row.local_thumbnail_path, { idempotent: true });
          } catch (_) {}
        }

        await db.runAsync('DELETE FROM videos WHERE id = ?', [row.id]);
        await db.runAsync('DELETE FROM favorites WHERE video_id = ?', [row.id]);
        deletedIds.push(row.id);
      }

      return deletedIds;
    } catch (e) {
      console.error('Database pruneRemovedVideos error:', e);
      return [];
    }
  }

  public async updateDownloadStatus(
    videoId: string,
    status: DownloadStatus,
    localPath?: string,
    localThumb?: string
  ): Promise<void> {
    try {
      const db = await this.getDatabase();
      if (localPath !== undefined && localThumb !== undefined) {
        await db.runAsync(
          'UPDATE videos SET download_status = ?, local_file_path = ?, local_thumbnail_path = ? WHERE id = ?',
          [status, localPath, localThumb, videoId]
        );
      } else if (localPath !== undefined) {
        await db.runAsync(
          'UPDATE videos SET download_status = ?, local_file_path = ? WHERE id = ?',
          [status, localPath, videoId]
        );
      } else {
        await db.runAsync(
          'UPDATE videos SET download_status = ? WHERE id = ?',
          [status, videoId]
        );
      }
    } catch (e) {
      console.error('updateDownloadStatus error:', e);
    }
  }

  public async clearDownloadedStatus(videoId: string): Promise<void> {
    try {
      const db = await this.getDatabase();
      await db.runAsync(
        'UPDATE videos SET download_status = ?, local_file_path = NULL, local_thumbnail_path = NULL WHERE id = ?',
        [DownloadStatus.notDownloaded, videoId]
      );
    } catch (_) {}
  }

  public async clearStaleCatalogCache(): Promise<void> {
    try {
      const db = await this.getDatabase();
      await db.runAsync(
        'DELETE FROM videos WHERE download_status != ? OR local_file_path IS NULL',
        [DownloadStatus.downloaded]
      );
      await db.runAsync('DELETE FROM categories');
    } catch (_) {}
  }

  public async clearAllCache(): Promise<void> {
    try {
      const db = await this.getDatabase();
      await db.runAsync('DELETE FROM videos');
      await db.runAsync('DELETE FROM categories');
    } catch (_) {}
  }

  public async getAllVideos(categoryId?: string): Promise<VideoItem[]> {
    try {
      const db = await this.getDatabase();
      let query = 'SELECT * FROM videos';
      const params: any[] = [];
      if (categoryId && categoryId !== 'all') {
        query += ' WHERE category_id = ?';
        params.push(categoryId);
      }
      query += ' ORDER BY rowid ASC';

      const rows = await db.getAllAsync<any>(query, params);
      return rows.map(this.mapRowToVideo);
    } catch (_) {
      return [];
    }
  }

  public async getVideoById(id: string): Promise<VideoItem | null> {
    try {
      const db = await this.getDatabase();
      const row = await db.getFirstAsync<any>('SELECT * FROM videos WHERE id = ?', [id]);
      if (!row) return null;
      return this.mapRowToVideo(row);
    } catch (_) {
      return null;
    }
  }

  public async getDownloadedVideos(): Promise<VideoItem[]> {
    try {
      const db = await this.getDatabase();
      const rows = await db.getAllAsync<any>(
        'SELECT * FROM videos WHERE download_status = ? AND local_file_path IS NOT NULL',
        [DownloadStatus.downloaded]
      );
      return rows.map(this.mapRowToVideo);
    } catch (_) {
      return [];
    }
  }

  private mapRowToVideo(row: any): VideoItem {
    return {
      id: row.id,
      title: row.title || 'Untitled Video',
      duration: row.duration || 0,
      durationFormatted: row.duration_formatted || '00:00',
      categoryId: row.category_id || 'cartoons',
      sourceUrl: row.source_url || '',
      streamUrl: row.stream_url || '',
      thumbnailUrl: row.thumbnail_url || '',
      channelName: row.channel_name || undefined,
      channelIconUrl: row.channel_icon_url || undefined,
      localFilePath: row.local_file_path || undefined,
      localThumbnailPath: row.local_thumbnail_path || undefined,
      fileSizeBytes: row.file_size_bytes || 0,
      quality: row.quality || '720p',
      downloadStatus: row.download_status ?? DownloadStatus.notDownloaded,
      downloadProgress: row.download_status === DownloadStatus.downloaded ? 1.0 : 0.0,
      status: row.status || 'pending_download',
      youtubeId: row.youtube_id || undefined,
    };
  }

  // --- Settings ---
  public async getSetting(key: string): Promise<string | null> {
    try {
      const db = await this.getDatabase();
      const row = await db.getFirstAsync<{ value: string }>(
        'SELECT value FROM settings WHERE key = ?',
        [key]
      );
      return row ? row.value : null;
    } catch (_) {
      return null;
    }
  }

  public async setSetting(key: string, value: string): Promise<void> {
    try {
      const db = await this.getDatabase();
      await db.runAsync(
        'INSERT OR REPLACE INTO settings (key, value) VALUES (?, ?)',
        [key, value]
      );
    } catch (e) {
      console.error('setSetting error:', e);
    }
  }

  // --- Favorites ---
  public async toggleFavorite(videoId: string): Promise<boolean> {
    try {
      const db = await this.getDatabase();
      const exists = await db.getFirstAsync(
        'SELECT video_id FROM favorites WHERE video_id = ?',
        [videoId]
      );
      if (exists) {
        await db.runAsync('DELETE FROM favorites WHERE video_id = ?', [videoId]);
        return false;
      } else {
        await db.runAsync(
          'INSERT INTO favorites (video_id, created_at) VALUES (?, ?)',
          [videoId, Date.now()]
        );
        return true;
      }
    } catch (_) {
      return false;
    }
  }

  public async isFavorite(videoId: string): Promise<boolean> {
    try {
      const db = await this.getDatabase();
      const row = await db.getFirstAsync(
        'SELECT video_id FROM favorites WHERE video_id = ?',
        [videoId]
      );
      return !!row;
    } catch (_) {
      return false;
    }
  }

  public async getFavoriteIds(): Promise<string[]> {
    try {
      const db = await this.getDatabase();
      const rows = await db.getAllAsync<{ video_id: string }>(
        'SELECT video_id FROM favorites ORDER BY created_at DESC'
      );
      return rows.map((r) => r.video_id);
    } catch (_) {
      return [];
    }
  }

  // --- Profiles ---
  public async getLocalProfiles(): Promise<ChildProfile[]> {
    try {
      const db = await this.getDatabase();
      const rows = await db.getAllAsync<{
        id: string;
        name: string;
        avatar_icon: string;
        age_bracket: string;
      }>('SELECT * FROM local_child_profiles ORDER BY name ASC');
      return rows.map((r) => ({
        id: r.id,
        name: r.name,
        avatarIcon: r.avatar_icon || 'bear',
        ageBracket: r.age_bracket || 'all',
      }));
    } catch (_) {
      return [];
    }
  }

  public async upsertLocalProfile(profile: ChildProfile): Promise<void> {
    try {
      const db = await this.getDatabase();
      await db.runAsync(
        'INSERT OR REPLACE INTO local_child_profiles (id, name, avatar_icon, age_bracket, created_at) VALUES (?, ?, ?, ?, ?)',
        [profile.id, profile.name, profile.avatarIcon, profile.ageBracket, Date.now()]
      );
    } catch (e) {
      console.error('upsertLocalProfile error:', e);
    }
  }

  // --- Watch Events & Analytics ---
  public async recordWatchEvent(event: Omit<LocalWatchEvent, 'id' | 'isSynced'>): Promise<void> {
    try {
      const db = await this.getDatabase();
      const id = `ev_${Date.now()}_${Math.random().toString(36).substring(2, 7)}`;
      await db.runAsync(
        `INSERT INTO local_watch_events (
          id, video_id, video_title, category_id, device_id,
          profile_id, profile_name, seconds_watched, video_duration,
          completion_rate, is_completed, is_skipped, watched_at, is_synced
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
        [
          id,
          event.videoId,
          event.videoTitle || null,
          event.categoryId || null,
          event.deviceId || 'kids_tablet',
          event.profileId || null,
          event.profileName || null,
          event.secondsWatched,
          event.videoDuration || 0,
          event.completionRate || 0.0,
          event.isCompleted ? 1 : 0,
          event.isSkipped ? 1 : 0,
          event.watchedAt,
          0,
        ]
      );
    } catch (e) {
      console.error('recordWatchEvent error:', e);
    }
  }

  public async getPendingWatchEvents(): Promise<LocalWatchEvent[]> {
    try {
      const db = await this.getDatabase();
      const rows = await db.getAllAsync<any>(
        'SELECT * FROM local_watch_events WHERE is_synced = 0 ORDER BY watched_at ASC LIMIT 50'
      );
      return rows.map((r) => ({
        id: r.id,
        videoId: r.video_id,
        videoTitle: r.video_title,
        categoryId: r.category_id,
        deviceId: r.device_id,
        profileId: r.profile_id,
        profileName: r.profile_name,
        secondsWatched: r.seconds_watched,
        videoDuration: r.video_duration,
        completionRate: r.completion_rate,
        isCompleted: r.is_completed === 1,
        isSkipped: r.is_skipped === 1,
        watchedAt: r.watched_at,
        isSynced: r.is_synced === 1,
      }));
    } catch (_) {
      return [];
    }
  }

  public async markWatchEventsSynced(ids: string[]): Promise<void> {
    if (ids.length === 0) return;
    try {
      const db = await this.getDatabase();
      const placeholders = ids.map(() => '?').join(',');
      await db.runAsync(
        `UPDATE local_watch_events SET is_synced = 1 WHERE id IN (${placeholders})`,
        ids
      );
    } catch (_) {}
  }

  public async getWatchAnalytics(profileId?: string): Promise<WatchAnalytics> {
    try {
      const db = await this.getDatabase();
      let whereClause = '';
      const params: any[] = [];
      if (profileId) {
        whereClause = ' WHERE profile_id = ?';
        params.push(profileId);
      }

      const totalRow = await db.getFirstAsync<{ total_seconds: number; count: number }>(
        `SELECT SUM(seconds_watched) as total_seconds, COUNT(*) as count FROM local_watch_events${whereClause}`,
        params
      );

      const completionRow = await db.getFirstAsync<{ avg_rate: number }>(
        `SELECT AVG(completion_rate) as avg_rate FROM local_watch_events${whereClause}`,
        params
      );

      const categoryRow = await db.getFirstAsync<{ category_id: string }>(
        `SELECT category_id, COUNT(*) as cat_count FROM local_watch_events${whereClause} GROUP BY category_id ORDER BY cat_count DESC LIMIT 1`,
        params
      );

      const recentRows = await db.getAllAsync<{ video_title: string }>(
        `SELECT DISTINCT video_title FROM local_watch_events${whereClause} WHERE video_title IS NOT NULL ORDER BY watched_at DESC LIMIT 5`,
        params
      );

      const totalSecs = totalRow?.total_seconds || 0;
      const hours = Math.floor(totalSecs / 3600);
      const mins = Math.floor((totalSecs % 3600) / 60);
      const formatted = hours > 0 ? `${hours}h ${mins}m` : `${mins} mins`;

      return {
        totalSeconds: totalSecs,
        totalWatchedFormatted: formatted,
        totalViews: totalRow?.count || 0,
        completionRate: completionRow?.avg_rate ? Math.round(completionRow.avg_rate * 100) : 0,
        mostWatchedCategory: categoryRow?.category_id || 'None yet',
        recentTitles: recentRows.map((r) => r.video_title).filter(Boolean),
      };
    } catch (_) {
      return {
        totalSeconds: 0,
        totalWatchedFormatted: '0 mins',
        totalViews: 0,
        completionRate: 0,
        mostWatchedCategory: 'None yet',
        recentTitles: [],
      };
    }
  }
}

export const databaseService = DatabaseService.getInstance();
