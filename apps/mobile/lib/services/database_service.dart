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
        download_status INTEGER DEFAULT 0
      );
    ''');

    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      );
    ''');

    // Default settings
    await db.insert('settings', {'key': 'vps_url', 'value': 'https://kids.waqas.pro'});
    await db.insert('settings', {'key': 'parent_pin', 'value': '1234'});
  }

  // --- Category CRUD ---
  Future<void> upsertCategory(CategoryItem category) async {
    final db = await database;
    await db.insert('categories', category.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<CategoryItem>> getAllCategories() async {
    final db = await database;
    final maps = await db.query('categories', orderBy: 'display_order ASC');
    return maps.map((m) => CategoryItem.fromMap(m)).toList();
  }

  // --- Video CRUD ---
  Future<void> upsertVideo(VideoItem video) async {
    final db = await database;
    // Check if video already exists with local file path to preserve offline status
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
  }

  Future<List<VideoItem>> getAllVideos() async {
    final db = await database;
    final maps = await db.query('videos');
    return maps.map((m) => VideoItem.fromMap(m)).toList();
  }

  Future<List<VideoItem>> getDownloadedVideos() async {
    final db = await database;
    final maps = await db.query(
      'videos',
      where: 'download_status = ? AND local_file_path IS NOT NULL',
      whereArgs: [DownloadStatus.downloaded.index],
    );
    return maps.map((m) => VideoItem.fromMap(m)).toList();
  }

  Future<List<VideoItem>> getVideosByCategory(String categoryId) async {
    final db = await database;
    final maps = await db.query(
      'videos',
      where: 'category_id = ?',
      whereArgs: [categoryId],
    );
    return maps.map((m) => VideoItem.fromMap(m)).toList();
  }

  Future<void> updateDownloadStatus(String videoId, DownloadStatus status, {String? localPath, String? localThumb}) async {
    final db = await database;
    final updateData = <String, dynamic>{
      'download_status': status.index,
    };
    if (localPath != null) updateData['local_file_path'] = localPath;
    if (localThumb != null) updateData['local_thumbnail_path'] = localThumb;

    await db.update('videos', updateData, where: 'id = ?', whereArgs: [videoId]);
  }

  Future<void> clearDownloadedStatus(String videoId) async {
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
  }

  Future<void> deleteVideo(String videoId) async {
    final db = await database;
    await db.delete('videos', where: 'id = ?', whereArgs: [videoId]);
  }

  // --- Settings ---
  Future<String?> getSetting(String key) async {
    final db = await database;
    final maps = await db.query('settings', where: 'key = ?', whereArgs: [key]);
    if (maps.isNotEmpty) {
      return maps.first['value'] as String;
    }
    return null;
  }

  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert('settings', {'key': key, 'value': value}, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // --- Favorites ---
  Future<void> toggleFavorite(String videoId) async {
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
  }

  Future<bool> isFavorite(String videoId) async {
    final db = await database;
    final res = await db.query('favorites', where: 'video_id = ?', whereArgs: [videoId]);
    return res.isNotEmpty;
  }

  Future<Set<String>> getFavoriteIds() async {
    final db = await database;
    final res = await db.query('favorites');
    return res.map((r) => r['video_id'] as String).toSet();
  }
}

