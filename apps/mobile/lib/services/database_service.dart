import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/video_item.dart';
import '../models/category_item.dart';

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
        try {
          await db.execute('ALTER TABLE videos ADD COLUMN status TEXT DEFAULT "pending_download";');
        } catch (_) {}
        try {
          await db.execute('ALTER TABLE videos ADD COLUMN youtube_id TEXT;');
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
}
