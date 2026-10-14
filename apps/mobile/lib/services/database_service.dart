import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/video_item.dart';
import '../models/category_item.dart';
import '../models/child_profile.dart';

class DatabaseService {
  static Database? _database;
  static final DatabaseService instance = DatabaseService._init();
  final Database? _customDb;

  DatabaseService._init() : _customDb = null;
  DatabaseService({Database? db}) : _customDb = db;
  DatabaseService.withDatabase(Database db) : _customDb = db;

  static Future<DatabaseService> createTestInstance(Database db) async {
    await instance._createDB(db, 1);
    try {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS local_child_profiles (\n          id TEXT PRIMARY KEY,
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
      await db.execute('''
        CREATE TABLE IF NOT EXISTS deleted_videos (
          video_id TEXT PRIMARY KEY,
          deleted_at INTEGER NOT NULL
        );
      ''');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_deleted_videos_id ON deleted_videos (video_id);');
    } catch (_) {}
    return DatabaseService.withDatabase(db);
  }

  Future<Database> get database async {
    if (_customDb != null) return _customDb;
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
        final wal = File('$path-wal');
        if (await wal.exists()) await wal.delete();
        final shm = File('$path-shm');
        if (await shm.exists()) await shm.delete();
      } catch (_) {}
      return await _openAndConfigure(path);
    }
  }

  /// Closes any open connection, renames corrupted database file as backup,
  /// and initializes a fresh replacement database.
  Future<void> recoverCorruptedDatabase() async {
    try {
      if (_database != null) {
        try {
          await _database!.close();
        } catch (_) {}
        _database = null;
      }
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'kidstube_v2.db');
      final corruptFile = File(path);
      if (await corruptFile.exists()) {
        final backupPath = '$path.corrupt.${DateTime.now().millisecondsSinceEpoch}';
        try {
          await corruptFile.rename(backupPath);
        } catch (_) {}
      }
      final walFile = File('$path-wal');
      if (await walFile.exists()) {
        try { await walFile.delete(); } catch (_) {}
      }
      final shmFile = File('$path-shm');
      if (await shmFile.exists()) {
        try { await shmFile.delete(); } catch (_) {}
      }
      _database = await _initDB('kidstube_v2.db');
    } catch (_) {
      _database = null;
    }
  }

  Future<Database> _openAndConfigure(String path) async {
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
      onOpen: (db) async {
        // Favorites table migration: support per-profile favorites with composite key (profile_id, video_id)
        await db.execute('''
          CREATE TABLE IF NOT EXISTS favorites_v2 (
            profile_id TEXT NOT NULL DEFAULT 'kids_all',
            video_id TEXT NOT NULL,
            created_at INTEGER,
            PRIMARY KEY (profile_id, video_id)
          );
        ''');
        try {
          final oldFavExists = await db.rawQuery(
            "SELECT name FROM sqlite_master WHERE type='table' AND name='favorites'"
          );
          if (oldFavExists.isNotEmpty) {
            final tableInfo = await db.rawQuery("PRAGMA table_info(favorites)");
            final hasProfileId = tableInfo.any((col) => col['name'] == 'profile_id');
            if (hasProfileId) {
              await db.execute('''
                INSERT OR IGNORE INTO favorites_v2 (profile_id, video_id, created_at)
                SELECT COALESCE(profile_id, 'kids_all'), video_id, created_at FROM favorites;
              ''');
            } else {
              await db.execute('''
                INSERT OR IGNORE INTO favorites_v2 (profile_id, video_id, created_at)
                SELECT 'kids_all', video_id, created_at FROM favorites;
              ''');
            }
            await db.execute('DROP TABLE favorites;');
            await db.execute('ALTER TABLE favorites_v2 RENAME TO favorites;');
          } else {
            await db.execute('ALTER TABLE favorites_v2 RENAME TO favorites;');
          }
        } catch (_) {}
        try {
          await db.execute('CREATE INDEX IF NOT EXISTS idx_favorites_profile ON favorites (profile_id, video_id);');
        } catch (_) {}

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
          await db.execute("UPDATE local_watch_events SET profile_id = 'no-profile' WHERE profile_id IS NULL OR profile_id = '' OR profile_id = 'all';");
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
        try {
          await db.execute('ALTER TABLE videos ADD COLUMN profile_id TEXT DEFAULT "kids_all";');
        } catch (_) {}
        try {
          await db.execute('UPDATE videos SET profile_id = "kids_all" WHERE profile_id IS NULL;');
        } catch (_) {}
        try {
          await db.execute('CREATE INDEX IF NOT EXISTS idx_videos_profile ON videos (profile_id);');
        } catch (_) {}

        // Deleted video tombstones table: ensures deleted videos stay permanently deleted
        await db.execute('''
          CREATE TABLE IF NOT EXISTS deleted_videos (
            video_id TEXT PRIMARY KEY,
            deleted_at INTEGER NOT NULL
          );
        ''');
        try {
          await db.execute('CREATE INDEX IF NOT EXISTS idx_deleted_videos_id ON deleted_videos (video_id);');
        } catch (_) {}
      },
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categories (\n        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        icon TEXT DEFAULT 'category',
        display_order INTEGER DEFAULT 0
      );\n    ''');

    await db.execute('''
      CREATE TABLE videos (
        id TEXT PRIMARY KEY,
        profile_id TEXT DEFAULT 'kids_all',
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
    await db.execute('CREATE INDEX IF NOT EXISTS idx_videos_profile ON videos (profile_id);');

    await db.execute('''
      CREATE TABLE favorites (
        profile_id TEXT NOT NULL DEFAULT 'kids_all',
        video_id TEXT NOT NULL,
        created_at INTEGER,
        PRIMARY KEY (profile_id, video_id)
      );
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_favorites_profile ON favorites (profile_id, video_id);');

    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE deleted_videos (
        video_id TEXT PRIMARY KEY,
        deleted_at INTEGER NOT NULL
      );
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_deleted_videos_id ON deleted_videos (video_id);');

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

  // --- Deleted Videos (Tombstone Persistence) ---
  Future<void> recordDeletedVideos(List<String> videoIds) async {
    if (videoIds.isEmpty) return;
    try {
      final db = await database;
      final now = DateTime.now().millisecondsSinceEpoch;
      final batch = db.batch();
      for (final id in videoIds) {
        batch.insert(
          'deleted_videos',
          {'video_id': id, 'deleted_at': now},
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    } catch (_) {}
  }

  Future<Set<String>> getDeletedVideoIds() async {
    try {
      final db = await database;
      final rows = await db.query('deleted_videos', columns: ['video_id']);
      return rows.map((r) => r['video_id'] as String).toSet();
    } catch (_) {
      return {};
    }
  }

  Future<bool> isVideoDeleted(String videoId) async {
    try {
      final db = await database;
      final rows = await db.query('deleted_videos', where: 'video_id = ?', whereArgs: [videoId], limit: 1);
      return rows.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<void> unmarkDeletedVideo(String videoId) async {
    try {
      final db = await database;
      await db.delete('deleted_videos', where: 'video_id = ?', whereArgs: [videoId]);
    } catch (_) {}
  }

  Future<void> unmarkDeletedVideos(List<String> videoIds) async {
    if (videoIds.isEmpty) return;
    try {
      final db = await database;
      final placeholders = List.filled(videoIds.length, '?').join(',');
      await db.delete('deleted_videos', where: 'video_id IN ($placeholders)', whereArgs: videoIds);
    } catch (_) {}
  }

  Future<void> clearDeletedVideosHistory() async {
    try {
      final db = await database;
      await db.delete('deleted_videos');
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
  static bool isAssignedToProfile(String? videoProfileId, String activeProfileId) {
    if (videoProfileId == null || videoProfileId.isEmpty) return true;
    if (videoProfileId == 'kids_all') return true;
    if (videoProfileId == activeProfileId) return true;
    final ids = videoProfileId.split(',').map((s) => s.trim()).toSet();
    return ids.contains(activeProfileId) || ids.contains('kids_all');
  }

  Future<void> batchUpsertCatalog(
    List<CategoryItem> categories,
    List<VideoItem> videos, {
    String? profileId,
  }) async {
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
      try {
        await db.execute('ALTER TABLE videos ADD COLUMN profile_id TEXT DEFAULT "kids_all";');
      } catch (_) {}

      final deletedIds = await getDeletedVideoIds();

      await db.transaction((txn) async {
        // Query existing downloaded items and profile assignments
        final existingVideos = await txn.query(
          'videos',
          columns: ['id', 'profile_id', 'local_file_path', 'local_thumbnail_path', 'download_status'],
        );
        final existingMap = {for (final r in existingVideos) r['id'] as String: r};

        final batch = txn.batch();
        for (final cat in categories) {
          batch.insert('categories', cat.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
        }

        for (final vid in videos) {
          // Permanently ignore videos that have been deleted by the user
          if (deletedIds.contains(vid.id)) continue;

          final data = vid.toMap();
          var pId = vid.profileId;
          if (pId.isEmpty || pId == 'kids_all') {
            if (profileId != null && profileId.isNotEmpty && profileId != 'all') {
              pId = profileId;
            }
          }

          if (existingMap.containsKey(vid.id)) {
            final prev = existingMap[vid.id]!;
            data['local_file_path'] = prev['local_file_path'];
            data['local_thumbnail_path'] = prev['local_thumbnail_path'];
            data['download_status'] = prev['download_status'];

            final prevPid = prev['profile_id'] as String?;
            if (prevPid != null && prevPid.isNotEmpty && prevPid != pId) {
              if (prevPid == 'kids_all' || pId == 'kids_all') {
                data['profile_id'] = 'kids_all';
              } else {
                final set = prevPid.split(',').map((s) => s.trim()).toSet();
                set.addAll(pId.split(',').map((s) => s.trim()));
                data['profile_id'] = set.join(',');
              }
            } else {
              data['profile_id'] = pId;
            }
          } else {
            data['profile_id'] = pId;
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
  /// Gated by allowEmpty guard and maxPruneRatio safety cap to protect offline libraries.
  /// When profileId is specified, only evaluates videos belonging to that profile (or kids_all),
  /// ensuring other profiles' downloaded offline content is NEVER pruned.
  Future<List<String>> pruneRemovedVideos(
    List<String> validServerVideoIds, {
    String? profileId,
    bool allowEmpty = false,
    double maxPruneRatio = 0.50,
    bool force = false,
  }) async {
    try {
      final db = await database;
      final Set<String> validIds = validServerVideoIds.toSet();

      // Find all videos currently in SQLite
      final allLocalVideos = await db.query(
        'videos',
        columns: ['id', 'profile_id', 'local_file_path', 'local_thumbnail_path', 'status'],
      );

      if (allLocalVideos.isEmpty) {
        return [];
      }

      // If a specific profileId is being synced, only consider videos that belong to this profile
      // (or kids_all), so that videos belonging to other profiles are never pruned!
      final relevantLocalVideos = (profileId != null && profileId.isNotEmpty && profileId != 'all')
          ? allLocalVideos.where((row) {
              final pId = (row['profile_id'] as String?) ?? 'kids_all';
              return isAssignedToProfile(pId, profileId);
            }).toList()
          : allLocalVideos;

      if (relevantLocalVideos.isEmpty) {
        return [];
      }

      // 1. Guard: Never wipe on an empty list without an explicit allowEmpty flag
      if (validIds.isEmpty && !allowEmpty) {
        // ignore: avoid_print
        print('DatabaseService: pruneRemovedVideos called with empty validServerVideoIds and allowEmpty=false. Skipping destructive prune to protect local library.');
        return [];
      }

      final toDelete = relevantLocalVideos.where((row) => !validIds.contains(row['id'] as String)).toList();
      if (toDelete.isEmpty) {
        return [];
      }

      // 2. Safety Cap: Never delete more than maxPruneRatio (default 50%) in one sync without explicit force confirmation
      final pruneRatio = toDelete.length / relevantLocalVideos.length;
      if (!force && relevantLocalVideos.length > 2 && pruneRatio > maxPruneRatio) {
        // ignore: avoid_print
        print('DatabaseService: pruneRemovedVideos safety cap blocked deletion of ${toDelete.length}/${relevantLocalVideos.length} videos (${(pruneRatio * 100).toStringAsFixed(1)}% > ${(maxPruneRatio * 100).toStringAsFixed(1)}%). Explicit confirmation required.');
        return [];
      }

      final deletedIds = <String>[];
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
        await db.delete('favorites', where: 'video_id = ?', whereArgs: [id]);
        deletedIds.add(id);
      }
      return deletedIds;
    } catch (e) {
      // ignore: avoid_print
      print('Database pruneRemovedVideos error: $e');
      return [];
    }
  }

  Future<void> upsertVideo(VideoItem video, {String? profileId}) async {
    try {
      // If a video is being explicitly added/upserted, unmark it from deleted tombstones
      await unmarkDeletedVideo(video.id);

      final db = await database;
      final existing = await db.query('videos', where: 'id = ?', whereArgs: [video.id]);

      Map<String, dynamic> data = video.toMap();
      var pId = video.profileId;
      if (pId.isEmpty || pId == 'kids_all') {
        if (profileId != null && profileId.isNotEmpty && profileId != 'all') {
          pId = profileId;
        }
      }

      if (existing.isNotEmpty) {
        final existingLocal = existing.first['local_file_path'] as String?;
        final existingStatus = existing.first['download_status'] as int? ?? 0;
        if (existingLocal != null && existingLocal.isNotEmpty && existingStatus == DownloadStatus.downloaded.index) {
          data['local_file_path'] = existingLocal;
          data['local_thumbnail_path'] = existing.first['local_thumbnail_path'];
          data['download_status'] = existingStatus;
        }

        final prevPid = existing.first['profile_id'] as String?;
        if (prevPid != null && prevPid.isNotEmpty && prevPid != pId) {
          if (prevPid == 'kids_all' || pId == 'kids_all') {
            data['profile_id'] = 'kids_all';
          } else {
            final set = prevPid.split(',').map((s) => s.trim()).toSet();
            set.addAll(pId.split(',').map((s) => s.trim()));
            data['profile_id'] = set.join(',');
          }
        } else {
          data['profile_id'] = pId;
        }
      } else {
        data['profile_id'] = pId;
      }

      await db.insert('videos', data, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (_) {}
  }

  Future<List<VideoItem>> getAllVideos({String? profileId}) async {
    try {
      final db = await database;
      final deletedIds = await getDeletedVideoIds();
      List<Map<String, dynamic>> maps;
      if (profileId != null && profileId.isNotEmpty && profileId != 'all' && profileId != 'kids_all') {
        maps = await db.query(
          'videos',
          where: "profile_id = 'kids_all' OR profile_id = ? OR profile_id LIKE ?",
          whereArgs: [profileId, '%$profileId%'],
        );
      } else {
        maps = await db.query('videos');
      }
      final list = <VideoItem>[];
      for (final m in maps) {
        try {
          final v = VideoItem.fromMap(m);
          if (v != null && !deletedIds.contains(v.id)) {
            if (profileId != null && profileId.isNotEmpty && profileId != 'all' && profileId != 'kids_all') {
              if (isAssignedToProfile(v.profileId, profileId)) {
                list.add(v);
              }
            } else {
              list.add(v);
            }
          }
        } catch (_) {}
      }
      return list;
    } catch (_) {
      return [];
    }
  }

  Future<List<VideoItem>> getDownloadedVideos({String? profileId}) async {
    try {
      final db = await database;
      final deletedIds = await getDeletedVideoIds();
      final maps = await db.query(
        'videos',
        where: 'download_status = ? AND local_file_path IS NOT NULL',
        whereArgs: [DownloadStatus.downloaded.index],
      );
      final list = <VideoItem>[];
      for (final m in maps) {
        try {
          final v = VideoItem.fromMap(m);
          if (v != null && !deletedIds.contains(v.id)) {
            if (profileId != null && profileId.isNotEmpty && profileId != 'all' && profileId != 'kids_all') {
              if (isAssignedToProfile(v.profileId, profileId)) {
                list.add(v);
              }
            } else {
              list.add(v);
            }
          }
        } catch (_) {}
      }
      return list;
    } catch (_) {
      return [];
    }
  }

  Future<List<VideoItem>> getVideosByCategory(String categoryId, {String? profileId}) async {
    try {
      final db = await database;
      final deletedIds = await getDeletedVideoIds();
      final maps = await db.query(
        'videos',
        where: 'category_id = ?',
        whereArgs: [categoryId],
      );
      final list = <VideoItem>[];
      for (final m in maps) {
        try {
          final v = VideoItem.fromMap(m);
          if (v != null && !deletedIds.contains(v.id)) {
            if (profileId != null && profileId.isNotEmpty && profileId != 'all' && profileId != 'kids_all') {
              if (isAssignedToProfile(v.profileId, profileId)) {
                list.add(v);
              }
            } else {
              list.add(v);
            }
          }
        } catch (_) {}
      }
      return list;
    } catch (_) {
      return [];
    }
  }

  Future<List<VideoItem>> searchVideos(String query, {String? profileId}) async {
    try {
      final db = await database;
      final q = query.trim().toLowerCase();
      if (q.isEmpty) return await getAllVideos(profileId: profileId);

      final deletedIds = await getDeletedVideoIds();
      final maps = await db.query(
        'videos',
        where: 'LOWER(title) LIKE ? OR LOWER(channel_name) LIKE ?',
        whereArgs: ['%$q%', '%$q%'],
      );
      final list = <VideoItem>[];
      for (final m in maps) {
        try {
          final v = VideoItem.fromMap(m);
          if (v != null && !deletedIds.contains(v.id)) {
            if (profileId != null && profileId.isNotEmpty && profileId != 'all' && profileId != 'kids_all') {
              if (isAssignedToProfile(v.profileId, profileId)) {
                list.add(v);
              }
            } else {
              list.add(v);
            }
          }
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
    await deleteVideos([videoId]);
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

  Future<bool> getAutoplayEnabled() async {
    final val = await getSetting('autoplay_enabled');
    if (val == null) return true; // Default enabled
    return val == 'true';
  }

  Future<void> setAutoplayEnabled(bool enabled) async {
    await setSetting('autoplay_enabled', enabled ? 'true' : 'false');
  }

  Future<int> getAutoplaySessionLimitMinutes() async {
    final val = await getSetting('autoplay_session_limit_minutes');
    if (val == null) return 60; // Default 60 minutes
    return int.tryParse(val) ?? 60;
  }

  Future<void> setAutoplaySessionLimitMinutes(int minutes) async {
    await setSetting('autoplay_session_limit_minutes', minutes.toString());
  }

  // --- Favorites (Per-Profile) ---
  Future<void> toggleFavorite(String videoId, {String? profileId}) async {
    try {
      final db = await database;
      final pId = (profileId != null && profileId.isNotEmpty) ? profileId : 'kids_all';
      final exists = await db.query(
        'favorites',
        where: 'profile_id = ? AND video_id = ?',
        whereArgs: [pId, videoId],
      );
      if (exists.isNotEmpty) {
        await db.delete(
          'favorites',
          where: 'profile_id = ? AND video_id = ?',
          whereArgs: [pId, videoId],
        );
      } else {
        await db.insert('favorites', {
          'profile_id': pId,
          'video_id': videoId,
          'created_at': DateTime.now().millisecondsSinceEpoch,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    } catch (_) {}
  }

  Future<bool> isFavorite(String videoId, {String? profileId}) async {
    try {
      final db = await database;
      final pId = (profileId != null && profileId.isNotEmpty) ? profileId : 'kids_all';
      final res = await db.query(
        'favorites',
        where: 'profile_id = ? AND video_id = ?',
        whereArgs: [pId, videoId],
      );
      return res.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<Set<String>> getFavoriteIds({String? profileId}) async {
    try {
      final db = await database;
      final pId = (profileId != null && profileId.isNotEmpty) ? profileId : 'kids_all';
      final res = await db.query(
        'favorites',
        where: 'profile_id = ?',
        whereArgs: [pId],
      );
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

      final effectiveProfileId = (profileId != null && profileId.isNotEmpty && profileId != 'all')
          ? profileId
          : 'no-profile';
      final effectiveProfileName = (profileName != null && profileName.isNotEmpty)
          ? profileName
          : (effectiveProfileId == 'no-profile' ? 'No Profile' : 'Kid');

      await db.insert('local_watch_events', {
        'id': eventId,
        'video_id': videoId,
        'video_title': videoTitle ?? '',
        'category_id': categoryId ?? '',
        'device_id': deviceId ?? 'kids_tablet',
        'profile_id': effectiveProfileId,
        'profile_name': effectiveProfileName,
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
      } else {
        whereClause = " WHERE profile_id != 'no-profile'";
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

      final partialCount = (totalSessions - completedCount - skippedCount).clamp(0, totalSessions);
      final completionRate = totalSessions > 0 ? ((completedCount / totalSessions) * 100).round() : 0;
      final skipRate = totalSessions > 0 ? ((skippedCount / totalSessions) * 100).round() : 0;
      final partialRate = totalSessions > 0 ? ((partialCount / totalSessions) * 100).round() : 0;

      // Retention Funnel: 4 stages matching web studio
      final funnelRes = await db.rawQuery('''
        SELECT
          COALESCE(SUM(CASE WHEN seconds_watched < 10 THEN 1 ELSE 0 END), 0) as bounce_count,
          COALESCE(SUM(CASE WHEN seconds_watched >= 10 AND seconds_watched < 60 THEN 1 ELSE 0 END), 0) as short_count,
          COALESCE(SUM(CASE WHEN seconds_watched >= 60 AND seconds_watched < 300 THEN 1 ELSE 0 END), 0) as medium_count,
          COALESCE(SUM(CASE WHEN seconds_watched >= 300 THEN 1 ELSE 0 END), 0) as deep_count
        FROM local_watch_events$whereClause
      ''', whereArgs);

      final bounceCount = (funnelRes.first['bounce_count'] as num?)?.toInt() ?? 0;
      final shortCount = (funnelRes.first['short_count'] as num?)?.toInt() ?? 0;
      final mediumCount = (funnelRes.first['medium_count'] as num?)?.toInt() ?? 0;
      final deepCount = (funnelRes.first['deep_count'] as num?)?.toInt() ?? 0;

      final retentionFunnel = [
        {
          'label': 'Immediate Bounce (< 10s)',
          'count': bounceCount,
          'percentage': totalSessions > 0 ? ((bounceCount / totalSessions) * 100).round() : 0,
          'color_hex': 0xFFFF5E62, // Coral
        },
        {
          'label': 'Short Focus (10s – 60s)',
          'count': shortCount,
          'percentage': totalSessions > 0 ? ((shortCount / totalSessions) * 100).round() : 0,
          'color_hex': 0xFFFFB300, // Sun
        },
        {
          'label': 'High Interest (1m – 5m)',
          'count': mediumCount,
          'percentage': totalSessions > 0 ? ((mediumCount / totalSessions) * 100).round() : 0,
          'color_hex': 0xFF38BDF8, // Sky
        },
        {
          'label': 'Deep Engagement (5m+)',
          'count': deepCount,
          'percentage': totalSessions > 0 ? ((deepCount / totalSessions) * 100).round() : 0,
          'color_hex': 0xFF10B981, // Mint
        },
      ];

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

      // "Kids Loved Most": ranked by views, completion, and total time, joined with videos
      final lovedWhere = whereClause.replaceAll('profile_id', 'e.profile_id');
      final lovedVideosRes = await db.rawQuery('''
        SELECT 
          e.video_id, 
          COALESCE(v.title, e.video_title, e.video_id) as title, 
          COALESCE(v.thumbnail_url, '') as thumbnail_url,
          COALESCE(v.channel_name, 'WonderKids') as channel_name,
          SUM(e.seconds_watched) as total_seconds, 
          COUNT(*) as views,
          SUM(e.is_completed) as completed_count,
          ROUND((SUM(e.is_completed) * 100.0) / COUNT(*)) as completion_pct
        FROM local_watch_events e
        LEFT JOIN videos v ON e.video_id = v.id
        $lovedWhere
        GROUP BY e.video_id
        ORDER BY views DESC, completed_count DESC, total_seconds DESC
        LIMIT 5
      ''', whereArgs);

      // "Passed Quickly": videos skipped in < 10 seconds, joined with videos
      final skipWhere = whereClause.isEmpty
          ? ' WHERE e.is_skipped = 1'
          : '${whereClause.replaceAll('profile_id', 'e.profile_id')} AND e.is_skipped = 1';
      final skippedVideosRes = await db.rawQuery('''
        SELECT 
          e.video_id, 
          COALESCE(v.title, e.video_title, e.video_id) as title, 
          COALESCE(v.thumbnail_url, '') as thumbnail_url,
          COALESCE(v.channel_name, 'WonderKids') as channel_name,
          COUNT(*) as skip_count,
          ROUND(AVG(e.seconds_watched), 1) as avg_seconds
        FROM local_watch_events e
        LEFT JOIN videos v ON e.video_id = v.id
        $skipWhere
        GROUP BY e.video_id
        ORDER BY skip_count DESC
        LIMIT 5
      ''', whereArgs);

      // Category breakdown with joined category names
      final catWhere = whereClause.isEmpty
          ? " WHERE e.category_id != ''"
          : "${whereClause.replaceAll('profile_id', 'e.profile_id')} AND e.category_id != ''";
      final categoryRes = await db.rawQuery('''
        SELECT 
          e.category_id, 
          COALESCE(c.name, e.category_id) as category_name, 
          SUM(e.seconds_watched) as total_seconds,
          ROUND((SUM(e.seconds_watched) * 100.0) / CASE WHEN $totalSeconds > 0 THEN $totalSeconds ELSE 1 END) as percentage
        FROM local_watch_events e
        LEFT JOIN categories c ON e.category_id = c.id
        $catWhere
        GROUP BY e.category_id
        ORDER BY total_seconds DESC
      ''', whereArgs);

      return {
        'total_seconds': totalSeconds,
        'today_seconds': todaySeconds,
        'total_sessions': totalSessions,
        'completed_count': completedCount,
        'skipped_count': skippedCount,
        'partial_count': partialCount,
        'completion_rate': completionRate,
        'skip_rate': skipRate,
        'partial_rate': partialRate,
        'retention_funnel': retentionFunnel,
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

  /// Fast aggregation query for the recommendation engine
  Future<Map<String, Map<String, dynamic>>> getVideoWatchSummaries({String? profileId}) async {
    // Prompt F8: Require a concrete profile context; never merge when profile is null, 'all', or 'no-profile'
    if (profileId == null || profileId.isEmpty || profileId == 'all' || profileId == 'no-profile') {
      return {};
    }

    try {
      final db = await database;
      final whereClause = ' WHERE profile_id = ?';
      final whereArgs = [profileId];

      final rows = await db.rawQuery('''
        SELECT 
          video_id,
          category_id,
          MAX(watched_at) as last_watched_at,
          COUNT(*) as watch_count,
          COALESCE(SUM(is_completed), 0) as completed_count,
          COALESCE(SUM(is_skipped), 0) as skipped_count,
          COALESCE(SUM(seconds_watched), 0) as total_seconds
        FROM local_watch_events$whereClause
        GROUP BY video_id
      ''', whereArgs);

      final Map<String, Map<String, dynamic>> result = {};
      for (final r in rows) {
        final videoId = r['video_id'] as String?;
        if (videoId != null && videoId.isNotEmpty) {
          result[videoId] = {
            'last_watched_at': (r['last_watched_at'] as num?)?.toInt() ?? 0,
            'watch_count': (r['watch_count'] as num?)?.toInt() ?? 0,
            'completed_count': (r['completed_count'] as num?)?.toInt() ?? 0,
            'skipped_count': (r['skipped_count'] as num?)?.toInt() ?? 0,
            'total_seconds': (r['total_seconds'] as num?)?.toInt() ?? 0,
            'category_id': r['category_id'] as String? ?? '',
          };
        }
      }
      return result;
    } catch (e) {
      return {};
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
      // 1. Permanently record tombstone so sync never restores these
      await recordDeletedVideos(videoIds);

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
