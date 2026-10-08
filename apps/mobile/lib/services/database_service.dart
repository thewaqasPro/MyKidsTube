import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/video_item.dart';
import '../models/category_item.dart';
import '../models/child_profile.dart';

class DatabaseService {
  static Database? _database;
  static final DatabaseService instance = DatabaseService._init();

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('kidstube_v2.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    try {
      return await _openAndConfigure(path);
    } catch (e) {
      // Corrupt DB recovery path (backup + recreate)
      try {
        final corruptFile = File(path);
        if (await corruptFile.exists()) {
          final backupPath = '$path.corrupt.${DateTime.now().millisecondsSinceEpoch}';
          await corruptFile.rename(backupPath);
        }
      } catch (_) {}
      return await _openAndConfigure(path);
    }
  }

  Future<Database> _openAndConfigure(String path) async {
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
      onOpen: (db) async {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS favorites (
            video_id TEXT PRIMARY KEY,
            created_at INTEGER
          );
        ''');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS local_child_profiles (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            avatar_icon TEXT DEFAULT 'bear',
            age_bracket TEXT DEFAULT 'all',
            created_at INTEGER
          );
        ''');
        await db.execute('''
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
        ''');
        try {
          await db.execute('ALTER TABLE local_watch_events ADD COLUMN device_id TEXT DEFAULT "kids_tablet";');
        } catch (_) {}
        try {
          await db.execute('ALTER TABLE local_watch_events ADD COLUMN profile_name TEXT;');
        } catch (_) {}
        try {
          await db.execute('ALTER TABLE local_watch_events ADD COLUMN video_duration INTEGER DEFAULT 0;');
        } catch (_) {}
        try {
          await db.execute('ALTER TABLE local_watch_events ADD COLUMN completion_rate REAL DEFAULT 0.0;');
        } catch (_) {}
        try {
          await db.execute('ALTER TABLE local_watch_events ADD COLUMN is_completed INTEGER DEFAULT 0;');
        } catch (_) {}
        try {
          await db.execute('ALTER TABLE local_watch_events ADD COLUMN is_skipped INTEGER DEFAULT 0;');
        } catch (_) {}
        try {
          await db.execute('CREATE INDEX IF NOT EXISTS idx_watch_events_watched_at ON local_watch_events (watched_at);');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_watch_events_synced ON local_watch_events (is_synced);');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_watch_events_profile ON local_watch_events (profile_id, watched_at);');
        } catch (_) {}
        try {
          await db.execute('ALTER TABLE videos ADD COLUMN status TEXT DEFAULT "pending_download";');
        } catch (_) {}
        try {
          await db.execute('ALTER TABLE videos ADD COLUMN youtube_id TEXT;');
        } catch (_) {}
        try {
          await db.execute('ALTER TABLE videos ADD COLUMN channel_name TEXT;');
        } catch (_) {}
        try {
          await db.execute('ALTER TABLE videos ADD COLUMN channel_icon_url TEXT;');
        } catch (_) {}
      },
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        icon TEXT DEFAULT 'category',
        display_order INTEGER DEFAULT 0
      );
    ''');

    await db.execute('''
      CREATE TABLE videos (
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
    ''');

    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      );
    ''');

    // Default settings (Note: parent PIN is salted & hashed in secure storage, NOT plaintext in settings)
    await db.insert('settings', {'key': 'vps_url', 'value': 'https://mykidstube.kidstube.workers.dev'},
        conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  /// Clears cached video and category records while preserving downloaded offline content
  Future<void> clearStaleCatalogCache() async {
    try {
      final db = await database;
      await db.delete(
        'videos',
        where: 'download_status != ? OR local_file_path IS NULL',
        whereArgs: [DownloadStatus.downloaded.index],
      );
      await db.delete('categories');
    } catch (_) {}
  }

  /// Completely wipes all cached videos and categories for a 100% fresh start
  Future<void> clearAllCache() async {
    try {
      final db = await database;
      await db.delete('videos');
      await db.delete('categories');
    } catch (_) {}
  }

  // --- Category CRUD ---
  Future<void> upsertCategory(CategoryItem category) async {
    try {
      final db = await database;
      await db.insert('categories', category.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (_) {}
  }

  Future<List<CategoryItem>> getAllCategories() async {
    try {
      final db = await database;
      final maps = await db.query('categories', orderBy: 'display_order ASC');
      final list = <CategoryItem>[];
      for (final m in maps) {
        try {
          list.add(CategoryItem.fromMap(m));
        } catch (_) {}
      }
      return list;
    } catch (_) {
      return [];
    }
  }

  // --- Video CRUD & Batch Operations ---
  Future<void> batchUpsertCatalog(List<CategoryItem> categories, List<VideoItem> videos) async {
    try {
      final db = await database;

      // Ensure any missing columns exist on existing databases
      try {
        await db.execute('ALTER TABLE videos ADD COLUMN channel_name TEXT;');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE videos ADD COLUMN channel_icon_url TEXT;');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE videos ADD COLUMN status TEXT DEFAULT "pending_download";');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE videos ADD COLUMN youtube_id TEXT;');
      } catch (_) {}

      await db.transaction((txn) async {
        // Query existing downloaded items to preserve local file paths
        final existingDownloaded = await txn.query(
          'videos',
          columns: ['id', 'local_file_path', 'local_thumbnail_path', 'download_status'],
          where: 'download_status = ? AND local_file_path IS NOT NULL',
          whereArgs: [DownloadStatus.downloaded.index],
        );
        final downloadedMap = {for (final r in existingDownloaded) r['id'] as String: r};

        final batch = txn.batch();
        for (final cat in categories) {
          batch.insert('categories', cat.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
        }

        for (final vid in videos) {
          final data = vid.toMap();
          if (downloadedMap.containsKey(vid.id)) {
            final prev = downloadedMap[vid.id]!;
            data['local_file_path'] = prev['local_file_path'];
            data['local_thumbnail_path'] = prev['local_thumbnail_path'];
            data['download_status'] = prev['download_status'];
          }
          batch.insert('videos', data, conflictAlgorithm: ConflictAlgorithm.replace);
        }

        await batch.commit(noResult: true);
      });
    } catch (e) {
      // ignore: avoid_print
      print('Database batchUpsertCatalog error: $e');
    }
  }

  /// Prunes any videos from SQLite that no longer exist on the server,
  /// and deletes their cached/downloaded local video and thumbnail files from device disk.
  Future<void> pruneRemovedVideos(List<String> validServerVideoIds) async {
    try {
      final db = await database;
      final Set<String> validIds = validServerVideoIds.toSet();

      // Find all videos currently in SQLite
      final allLocalVideos = await db.query(
        'videos',
        columns: ['id', 'local_file_path', 'local_thumbnail_path'],
      );

      final toDelete = allLocalVideos.where((row) => !validIds.contains(row['id'] as String)).toList();

      for (final row in toDelete) {
        final id = row['id'] as String;
        final localFilePath = row['local_file_path'] as String?;
        final localThumbPath = row['local_thumbnail_path'] as String?;

        // 1. Delete physical video file if downloaded
        if (localFilePath != null && localFilePath.isNotEmpty) {
          try {
            final f = File(localFilePath);
            if (await f.exists()) {
              await f.delete();
            }
          } catch (e) {
            // ignore: avoid_print
            print('Error deleting local video file $localFilePath: $e');
          }
        }

        // 2. Delete physical thumbnail file if cached
        if (localThumbPath != null && localThumbPath.isNotEmpty) {
          try {
            final f = File(localThumbPath);
            if (await f.exists()) {
              await f.delete();
            }
          } catch (e) {
            // ignore: avoid_print
            print('Error deleting local thumbnail file $localThumbPath: $e');
          }
        }

        // 3. Delete from SQLite
        await db.delete('videos', where: 'id = ?', whereArgs: [id]);
      }
    } catch (e) {
      // ignore: avoid_print
      print('Database pruneRemovedVideos error: $e');
    }
  }

  Future<void> upsertVideo(VideoItem video) async {
    try {
      final db = await database;
      final existing = await db.query('videos', where: 'id = ?', whereArgs: [video.id]);

      Map<String, dynamic> data = video.toMap();
      if (existing.isNotEmpty) {
        final existingLocal = existing.first['local_file_path'] as String?;
        final existingStatus = existing.first['download_status'] as int? ?? 0;
        if (existingLocal != null && existingLocal.isNotEmpty && existingStatus == DownloadStatus.downloaded.index) {
          data['local_file_path'] = existingLocal;
          data['local_thumbnail_path'] = existing.first['local_thumbnail_path'];
          data['download_status'] = existingStatus;
        }
      }

      await db.insert('videos', data, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (_) {}
  }

  Future<List<VideoItem>> getAllVideos() async {
    try {
      final db = await database;
      final maps = await db.query('videos');
      final list = <VideoItem>[];
      for (final m in maps) {
        try {
          final v = VideoItem.fromMap(m);
          if (v != null) list.add(v);
        } catch (_) {}
      }
      return list;
    } catch (_) {
      return [];
    }
  }

  Future<List<VideoItem>> getDownloadedVideos() async {
    try {
      final db = await database;
      final maps = await db.query(
        'videos',
        where: 'download_status = ? AND local_file_path IS NOT NULL',
        whereArgs: [DownloadStatus.downloaded.index],
      );
      final list = <VideoItem>[];
      for (final m in maps) {
        try {
          final v = VideoItem.fromMap(m);
          if (v != null) list.add(v);
        } catch (_) {}
      }
      return list;
    } catch (_) {
      return [];
    }
  }

  Future<List<VideoItem>> getVideosByCategory(String categoryId) async {
    try {
      final db = await database;
      final maps = await db.query(
        'videos',
        where: 'category_id = ?',
        whereArgs: [categoryId],
      );
      final list = <VideoItem>[];
      for (final m in maps) {
        try {
          final v = VideoItem.fromMap(m);
          if (v != null) list.add(v);
        } catch (_) {}
      }
      return list;
    } catch (_) {
      return [];
    }
  }

  Future<void> updateDownloadStatus(String videoId, DownloadStatus status, {String? localPath, String? localThumb}) async {
    try {
      final db = await database;
      final updateData = <String, dynamic>{
        'download_status': status.index,
      };
      if (localPath != null) updateData['local_file_path'] = localPath;
      if (localThumb != null) updateData['local_thumbnail_path'] = localThumb;

      await db.update('videos', updateData, where: 'id = ?', whereArgs: [videoId]);
    } catch (_) {}
  }

  Future<void> clearDownloadedStatus(String videoId) async {
    try {
      final db = await database;
      await db.update(
        'videos',
        {
          'download_status': DownloadStatus.notDownloaded.index,
          'local_file_path': null,
          'local_thumbnail_path': null,
        },
        where: 'id = ?',
        whereArgs: [videoId],
      );
    } catch (_) {}
  }

  Future<void> deleteVideo(String videoId) async {
    try {
      final db = await database;
      await db.delete('videos', where: 'id = ?', whereArgs: [videoId]);
    } catch (_) {}
  }

  // --- Settings ---
  Future<String?> getSetting(String key) async {
    try {
      final db = await database;
      final maps = await db.query('settings', where: 'key = ?', whereArgs: [key]);
      if (maps.isNotEmpty) {
        return maps.first['value'] as String?;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> setSetting(String key, String value) async {
    try {
      final db = await database;
      await db.insert('settings', {'key': key, 'value': value}, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (_) {}
  }

  // --- Favorites ---
  Future<void> toggleFavorite(String videoId) async {
    try {
      final db = await database;
      final exists = await db.query('favorites', where: 'video_id = ?', whereArgs: [videoId]);
      if (exists.isNotEmpty) {
        await db.delete('favorites', where: 'video_id = ?', whereArgs: [videoId]);
      } else {
        await db.insert('favorites', {
          'video_id': videoId,
          'created_at': DateTime.now().millisecondsSinceEpoch,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    } catch (_) {}
  }

  Future<bool> isFavorite(String videoId) async {
    try {
      final db = await database;
      final res = await db.query('favorites', where: 'video_id = ?', whereArgs: [videoId]);
      return res.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<Set<String>> getFavoriteIds() async {
    try {
      final db = await database;
      final res = await db.query('favorites');
      return res.map((r) => r['video_id'] as String).toSet();
    } catch (_) {
      return {};
    }
  }

  // --- Local Watch Time Analytics (Cloudflare Quota Preserving) ---
  Future<void> recordWatchSession({
    required String videoId,
    String? videoTitle,
    String? categoryId,
    String? profileId,
    String? profileName,
    String? deviceId,
    required int secondsWatched,
    int videoDuration = 0,
    bool isCompleted = false,
    bool isSkipped = false,
  }) async {
    if (secondsWatched <= 0) return;
    try {
      final db = await database;
      final eventId = 'ev_${DateTime.now().millisecondsSinceEpoch}_${videoId.hashCode.abs()}';
      final completionRate = videoDuration > 0
          ? (secondsWatched / videoDuration).clamp(0.0, 1.0)
          : 0.0;

      await db.insert('local_watch_events', {
        'id': eventId,
        'video_id': videoId,
        'video_title': videoTitle ?? '',
        'category_id': categoryId ?? '',
        'device_id': deviceId ?? 'kids_tablet',
        'profile_id': profileId ?? 'kids_all',
        'profile_name': profileName ?? 'Kid',
        'seconds_watched': secondsWatched,
        'video_duration': videoDuration,
        'completion_rate': completionRate,
        'is_completed': isCompleted ? 1 : (videoDuration > 0 && secondsWatched >= 0.75 * videoDuration ? 1 : 0),
        'is_skipped': isSkipped ? 1 : (secondsWatched < 10 ? 1 : 0),
        'watched_at': DateTime.now().millisecondsSinceEpoch,
        'is_synced': 0,
      });
    } catch (e) {
      // ignore: avoid_print
      print('recordWatchSession error: $e');
    }
  }

  Future<Map<String, dynamic>> getWatchAnalytics({String? profileId}) async {
    try {
      final db = await database;
      final now = DateTime.now();
      final startOfToday = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;

      String whereClause = '';
      List<dynamic> whereArgs = [];
      if (profileId != null && profileId.isNotEmpty && profileId != 'all') {
        whereClause = ' WHERE profile_id = ?';
        whereArgs.add(profileId);
      }

      // Total seconds & total sessions & retention counts
      final totalRes = await db.rawQuery('''
        SELECT 
          COALESCE(SUM(seconds_watched), 0) as total_seconds,
          COUNT(*) as total_sessions,
          COALESCE(SUM(is_completed), 0) as completed_count,
          COALESCE(SUM(is_skipped), 0) as skipped_count
        FROM local_watch_events$whereClause
      ''', whereArgs);

      final totalSeconds = (totalRes.first['total_seconds'] as num?)?.toInt() ?? 0;
      final totalSessions = (totalRes.first['total_sessions'] as num?)?.toInt() ?? 0;
      final completedCount = (totalRes.first['completed_count'] as num?)?.toInt() ?? 0;
      final skippedCount = (totalRes.first['skipped_count'] as num?)?.toInt() ?? 0;

      final completionRate = totalSessions > 0 ? ((completedCount / totalSessions) * 100).round() : 0;
      final skipRate = totalSessions > 0 ? ((skippedCount / totalSessions) * 100).round() : 0;

      // Today seconds
      final todayWhere = whereClause.isEmpty ? ' WHERE watched_at >= ?' : '$whereClause AND watched_at >= ?';
      final todayArgs = [...whereArgs, startOfToday];
      final todayRes = await db.rawQuery(
        'SELECT COALESCE(SUM(seconds_watched), 0) as today_seconds FROM local_watch_events$todayWhere',
        todayArgs,
      );
      final todaySeconds = (todayRes.first['today_seconds'] as num?)?.toInt() ?? 0;

      // Unsynced count
      final unsyncedRes = await db.rawQuery(
        'SELECT COUNT(*) as unsynced_count FROM local_watch_events WHERE is_synced = 0',
      );
      final unsyncedCount = (unsyncedRes.first['unsynced_count'] as num?)?.toInt() ?? 0;

      // Daily breakdown (last 7 days)
      final dailyBreakdown = <Map<String, dynamic>>[];
      final weekdayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      for (int i = 6; i >= 0; i--) {
        final dayStart = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
        final dayEnd = dayStart.add(const Duration(days: 1));
        final dayWhere = whereClause.isEmpty
            ? ' WHERE watched_at >= ? AND watched_at < ?'
            : '$whereClause AND watched_at >= ? AND watched_at < ?';
        final dayRes = await db.rawQuery(
          'SELECT COALESCE(SUM(seconds_watched), 0) as secs FROM local_watch_events$dayWhere',
          [...whereArgs, dayStart.millisecondsSinceEpoch, dayEnd.millisecondsSinceEpoch],
        );
        final secs = (dayRes.first['secs'] as num?)?.toInt() ?? 0;
        dailyBreakdown.add({
          'day_label': weekdayNames[dayStart.weekday - 1],
          'date': '${dayStart.month}/${dayStart.day}',
          'seconds': secs,
        });
      }

      // "Kids Loved Most": ranked by views, completion, and total time
      final lovedVideosRes = await db.rawQuery('''
        SELECT 
          video_id, 
          COALESCE(video_title, video_id) as title, 
          SUM(seconds_watched) as total_seconds, 
          COUNT(*) as views,
          SUM(is_completed) as completed_count
        FROM local_watch_events$whereClause
        GROUP BY video_id
        ORDER BY views DESC, completed_count DESC, total_seconds DESC
        LIMIT 5
      ''', whereArgs);

      // "Passed Quickly": videos skipped in < 10 seconds
      final skipWhere = whereClause.isEmpty ? ' WHERE is_skipped = 1' : '$whereClause AND is_skipped = 1';
      final skippedVideosRes = await db.rawQuery('''
        SELECT 
          video_id, 
          COALESCE(video_title, video_id) as title, 
          COUNT(*) as skip_count,
          AVG(seconds_watched) as avg_seconds
        FROM local_watch_events$skipWhere
        GROUP BY video_id
        ORDER BY skip_count DESC
        LIMIT 5
      ''', whereArgs);

      // Category breakdown
      final catWhere = whereClause.isEmpty ? " WHERE category_id != ''" : "$whereClause AND category_id != ''";
      final categoryRes = await db.rawQuery('''
        SELECT category_id, SUM(seconds_watched) as total_seconds
        FROM local_watch_events$catWhere
        GROUP BY category_id
        ORDER BY total_seconds DESC
      ''', whereArgs);

      return {
        'total_seconds': totalSeconds,
        'today_seconds': todaySeconds,
        'total_sessions': totalSessions,
        'completed_count': completedCount,
        'skipped_count': skippedCount,
        'completion_rate': completionRate,
        'skip_rate': skipRate,
        'unsynced_count': unsyncedCount,
        'daily_breakdown': dailyBreakdown,
        'loved_videos': lovedVideosRes,
        'skipped_videos': skippedVideosRes,
        'category_breakdown': categoryRes,
      };
    } catch (e) {
      // ignore: avoid_print
      print('getWatchAnalytics error: $e');
      return {
        'total_seconds': 0,
        'today_seconds': 0,
        'total_sessions': 0,
        'completed_count': 0,
        'skipped_count': 0,
        'completion_rate': 0,
        'skip_rate': 0,
        'unsynced_count': 0,
        'daily_breakdown': <Map<String, dynamic>>[],
        'loved_videos': <Map<String, dynamic>>[],
        'skipped_videos': <Map<String, dynamic>>[],
        'category_breakdown': <Map<String, dynamic>>[],
      };
    }
  }

  // --- Local Child Profiles CRUD ---
  Future<List<ChildProfile>> getAllLocalProfiles() async {
    try {
      final db = await database;
      final maps = await db.query('local_child_profiles', orderBy: 'name ASC');
      if (maps.isEmpty) {
        final seeds = [
          ChildProfile(id: 'kid_1', name: 'Kid 1 (Ali)', avatarIcon: 'bear', ageBracket: 'preschool'),
          ChildProfile(id: 'kid_2', name: 'Kid 2 (Fatima)', avatarIcon: 'unicorn', ageBracket: 'elementary'),
          ChildProfile(id: 'kid_3', name: 'Kid 3 (Omar)', avatarIcon: 'lion', ageBracket: 'all'),
        ];
        for (final p in seeds) {
          await db.insert('local_child_profiles', {
            'id': p.id,
            'name': p.name,
            'avatar_icon': p.avatarIcon,
            'age_bracket': p.ageBracket,
            'created_at': DateTime.now().millisecondsSinceEpoch,
          }, conflictAlgorithm: ConflictAlgorithm.ignore);
        }
        return seeds;
      }
      return maps.map((m) => ChildProfile.fromMap(m)).whereType<ChildProfile>().toList();
    } catch (_) {
      return [
        ChildProfile(id: 'kid_1', name: 'Kid 1', avatarIcon: 'bear', ageBracket: 'all'),
      ];
    }
  }

  Future<void> upsertLocalProfile(ChildProfile profile) async {
    try {
      final db = await database;
      await db.insert('local_child_profiles', {
        'id': profile.id,
        'name': profile.name,
        'avatar_icon': profile.avatarIcon,
        'age_bracket': profile.ageBracket,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (_) {}
  }

  Future<void> deleteLocalProfile(String profileId) async {
    try {
      final db = await database;
      await db.delete('local_child_profiles', where: 'id = ?', whereArgs: [profileId]);
    } catch (_) {}
  }

  Future<List<Map<String, dynamic>>> getUnsyncedWatchEvents({int limit = 100}) async {
    try {
      final db = await database;
      return await db.query(
        'local_watch_events',
        where: 'is_synced = 0',
        orderBy: 'watched_at ASC',
        limit: limit,
      );
    } catch (_) {
      return [];
    }
  }

  Future<void> markWatchEventsSynced(List<String> eventIds) async {
    if (eventIds.isEmpty) return;
    try {
      final db = await database;
      final placeholders = List.filled(eventIds.length, '?').join(',');
      await db.rawUpdate(
        'UPDATE local_watch_events SET is_synced = 1 WHERE id IN ($placeholders)',
        eventIds,
      );
    } catch (_) {}
  }

  Future<void> clearWatchHistory() async {
    try {
      final db = await database;
      await db.delete('local_watch_events');
    } catch (_) {}
  }

  Future<void> deleteVideos(List<String> videoIds) async {
    if (videoIds.isEmpty) return;
    try {
      final db = await database;
      for (final id in videoIds) {
        final existing = await db.query('videos', where: 'id = ?', whereArgs: [id]);
        if (existing.isNotEmpty) {
          final localPath = existing.first['local_file_path'] as String?;
          final thumbPath = existing.first['local_thumbnail_path'] as String?;
          if (localPath != null && localPath.isNotEmpty) {
            try {
              final f = File(localPath);
              if (await f.exists()) await f.delete();
            } catch (_) {}
          }
          if (thumbPath != null && thumbPath.isNotEmpty) {
            try {
              final f = File(thumbPath);
              if (await f.exists()) await f.delete();
            } catch (_) {}
          }
        }
        await db.delete('videos', where: 'id = ?', whereArgs: [id]);
        await db.delete('favorites', where: 'video_id = ?', whereArgs: [id]);
      }
    } catch (_) {}
  }
}
