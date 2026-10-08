import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/video_item.dart';
import '../models/category_item.dart';
import '../models/child_profile.dart';
import '../services/database_service.dart';
import '../services/vps_api_service.dart';
import '../services/download_service.dart';

enum AppOrientationMode {
  auto,
  portrait,
  landscape,
}

class AppProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;
  final VpsApiService _api = VpsApiService();
  final DownloadService _downloader = DownloadService.instance;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  String _vpsUrl = 'https://mykidstube.kidstube.workers.dev';
  String _deviceName = 'Kids Tablet';

  // Multi-User state
  ChildProfile? _activeProfile;
  List<ChildProfile> _availableProfiles = [];
  String? _pairingCode;
  bool _isDevicePaired = false;

  List<CategoryItem> _categories = [];
  List<VideoItem> _allVideos = [];
  List<VideoItem> _downloadedVideos = [];
  Set<String> _favoriteVideoIds = {};
  final Map<String, double> _downloadProgress = {};

  bool _isLoading = false;
  bool _isSyncing = false;
  bool _isServerOnline = false;
  bool _isOfflineOnly = false;
  int _cachedBytes = 0;
  int _todayWatchSeconds = 0;
  AppOrientationMode _orientationMode = AppOrientationMode.auto;

  // Getters
  String get vpsUrl => _vpsUrl;
  String get deviceName => _deviceName;
  ChildProfile? get activeProfile => _activeProfile;
  List<ChildProfile> get availableProfiles => _availableProfiles;
  String? get pairingCode => _pairingCode;
  bool get isDevicePaired => _isDevicePaired;
  AppOrientationMode get orientationMode => _orientationMode;

  List<CategoryItem> get categories => _categories;
  List<VideoItem> get allVideos => _isOfflineOnly ? _downloadedVideos : _allVideos;
  List<VideoItem> get downloadedVideos => _downloadedVideos;
  Set<String> get favoriteVideoIds => _favoriteVideoIds;
  List<VideoItem> get favoriteVideos => allVideos.where((v) => _favoriteVideoIds.contains(v.id)).toList();
  bool isFavorite(String videoId) => _favoriteVideoIds.contains(videoId);
  Map<String, double> get downloadProgress => _downloadProgress;
  bool get isLoading => _isLoading;
  bool get isSyncing => _isSyncing;
  bool get isServerOnline => _isServerOnline;
  bool get isOfflineOnly => _isOfflineOnly;
  int get cachedBytes => _cachedBytes;
  int get todayWatchSeconds => _todayWatchSeconds;

  Future<void> setOrientationMode(AppOrientationMode mode) async {
    _orientationMode = mode;
    await _applyOrientationMode(mode);
    await _db.setSetting('orientation_mode', mode.name);
    notifyListeners();
  }

  Future<void> _applyOrientationMode(AppOrientationMode mode) async {
    switch (mode) {
      case AppOrientationMode.portrait:
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
        ]);
        break;
      case AppOrientationMode.landscape:
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
        break;
      case AppOrientationMode.auto:
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
        break;
    }
  }

  // --- PIN Security & Salted Hash Storage ---
  Future<String> _getOrCreateSalt() async {
    var salt = await _secureStorage.read(key: 'parent_pin_salt');
    if (salt == null || salt.isEmpty) {
      final random = Random.secure();
      final bytes = List<int>.generate(16, (_) => random.nextInt(256));
      salt = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
      await _secureStorage.write(key: 'parent_pin_salt', value: salt);
    }
    return salt;
  }

  String _hashPin(String pin, String salt) {
    return sha256.convert(utf8.encode('$salt:$pin')).toString();
  }

  Future<void> _initPinSecurity() async {
    final salt = await _getOrCreateSalt();
    final storedHash = await _secureStorage.read(key: 'parent_pin_hash');
    if (storedHash == null || storedHash.isEmpty) {
      // Check legacy setting from SQLite
      final legacyPin = await _db.getSetting('parent_pin');
      final pinToUse = (legacyPin != null && legacyPin.isNotEmpty) ? legacyPin : '1234';
      final newHash = _hashPin(pinToUse, salt);
      await _secureStorage.write(key: 'parent_pin_hash', value: newHash);
      // Wipe plaintext pin from SQLite settings
      await _db.setSetting('parent_pin', '');
    }
  }

  Future<bool> verifyParentPin(String enteredPin) async {
    final salt = await _getOrCreateSalt();
    final storedHash = await _secureStorage.read(key: 'parent_pin_hash');
    if (storedHash == null || storedHash.isEmpty) {
      return enteredPin == '1234';
    }
    final enteredHash = _hashPin(enteredPin, salt);
    return enteredHash == storedHash;
  }

  Future<bool> changeParentPin({required String currentPin, required String newPin}) async {
    if (!await verifyParentPin(currentPin)) {
      return false;
    }
    if (newPin.length < 4 || !RegExp(r'^\d+$').hasMatch(newPin)) {
      return false;
    }
    final salt = await _getOrCreateSalt();
    final newHash = _hashPin(newPin, salt);
    await _secureStorage.write(key: 'parent_pin_hash', value: newHash);
    notifyListeners();
    return true;
  }

  Future<bool> isUsingDefaultPin() async {
    final salt = await _getOrCreateSalt();
    final storedHash = await _secureStorage.read(key: 'parent_pin_hash');
    if (storedHash == null) return true;
    return storedHash == _hashPin('1234', salt);
  }

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    // 1. Read vps_url from settings first; only write default when none exists (survives restart)
    final savedUrl = await _db.getSetting('vps_url');
    if (savedUrl != null && savedUrl.isNotEmpty) {
      _vpsUrl = savedUrl;
    } else {
      _vpsUrl = 'https://mykidstube.kidstube.workers.dev';
      await _db.setSetting('vps_url', _vpsUrl);
    }

    // 2. Initialize PIN security in secure storage
    await _initPinSecurity();

    // 3. Load device auth token from secure storage
    final savedToken = await _secureStorage.read(key: 'device_auth_token');
    if (savedToken != null && savedToken.isNotEmpty) {
      _api.setAuthToken(savedToken);
    }

    final pairedSetting = await _db.getSetting('is_device_paired');
    _isDevicePaired = pairedSetting == 'true';

    final savedProfileId = await _db.getSetting('current_profile_id');
    final savedProfileName = await _db.getSetting('current_profile_name');
    final savedProfileAvatar = await _db.getSetting('current_profile_avatar');
    if (savedProfileId != null) {
      _activeProfile = ChildProfile(
        id: savedProfileId,
        name: savedProfileName ?? 'Kid',
        avatarIcon: savedProfileAvatar ?? 'bear',
      );
    }

    // 4. Load initial database state
    await _loadFromLocalDb();

    // 4b. Restore saved orientation mode
    final savedOrientation = await _db.getSetting('orientation_mode');
    if (savedOrientation != null && savedOrientation.isNotEmpty) {
      if (savedOrientation == 'portrait') {
        _orientationMode = AppOrientationMode.portrait;
      } else if (savedOrientation == 'landscape') {
        _orientationMode = AppOrientationMode.landscape;
      } else {
        _orientationMode = AppOrientationMode.auto;
      }
      await _applyOrientationMode(_orientationMode);
    }

    _isLoading = false;
    notifyListeners();

    // 5. Background sync with Edge API
    await syncCatalog();
  }

  Future<void> clearMobileCache() async {
    _isLoading = true;
    notifyListeners();
    await _db.clearAllCache();
    await syncCatalog();
  }

  Future<void> _loadFromLocalDb() async {
    _categories = await _db.getAllCategories();
    _allVideos = await _db.getAllVideos();
    _downloadedVideos = await _db.getDownloadedVideos();
    _favoriteVideoIds = await _db.getFavoriteIds();
    _cachedBytes = await _downloader.getTotalCachedBytes();
    _availableProfiles = await _db.getAllLocalProfiles();
    if (_activeProfile == null && _availableProfiles.isNotEmpty) {
      _activeProfile = _availableProfiles.first;
      await _db.setSetting('current_profile_id', _activeProfile!.id);
      await _db.setSetting('current_profile_name', _activeProfile!.name);
      await _db.setSetting('current_profile_avatar', _activeProfile!.avatarIcon);
    }
    try {
      final analytics = await _db.getWatchAnalytics(profileId: _activeProfile?.id);
      _todayWatchSeconds = (analytics['today_seconds'] as num?)?.toInt() ?? 0;
    } catch (_) {}
    notifyListeners();
  }

  Future<void> syncCatalog() async {
    _isSyncing = true;
    notifyListeners();

    try {
      final catalogData = await _api.fetchCatalog(_vpsUrl, profileId: _activeProfile?.id);
      if (catalogData != null && catalogData['sections'] is List) {
        _isServerOnline = true;
        final sections = catalogData['sections'] as List;

        final categoriesToSync = <CategoryItem>[];
        final videosToSync = <VideoItem>[];
        final seenVideoIds = <String>{};

        for (final sec in sections) {
          final catJson = sec['category'];
          if (catJson != null && catJson['id'] != null) {
            categoriesToSync.add(CategoryItem(
              id: catJson['id'].toString(),
              name: (catJson['name'] ?? 'Category').toString(),
              icon: (catJson['icon'] ?? 'category').toString(),
              displayOrder: (catJson['display_order'] as num?)?.toInt() ?? 0,
            ));
          }

          final videosJson = sec['videos'] as List? ?? [];
          for (final vJson in videosJson) {
            if (vJson is Map<String, dynamic>) {
              final video = VideoItem.fromApi(vJson);
              if (video != null && !seenVideoIds.contains(video.id)) {
                seenVideoIds.add(video.id);
                videosToSync.add(video);
              }
            }
          }
        }

        // Also add complete all_videos list
        if (catalogData['all_videos'] is List) {
          for (final vJson in (catalogData['all_videos'] as List)) {
            if (vJson is Map<String, dynamic>) {
              final video = VideoItem.fromApi(vJson);
              if (video != null && !seenVideoIds.contains(video.id)) {
                seenVideoIds.add(video.id);
                videosToSync.add(video);
              }
            }
          }
        }

        if (videosToSync.isNotEmpty) {
          _allVideos = List.from(videosToSync);
          _categories = List.from(categoriesToSync);
          notifyListeners();
        }

        // Atomic transaction batch upsert to persist to local SQLite
        await _db.batchUpsertCatalog(categoriesToSync, videosToSync);

        // Prune any videos deleted from the server (removes SQLite rows and cleans disk files)
        await _db.pruneRemovedVideos(videosToSync.map((v) => v.id).toList());

        // Sync profiles from server if available without wiping local
        final remoteProfiles = await _api.fetchProfiles(_vpsUrl);
        if (remoteProfiles.isNotEmpty) {
          for (final p in remoteProfiles) {
            await _db.upsertLocalProfile(p);
          }
        }
        _availableProfiles = await _db.getAllLocalProfiles();
      } else {
        _isServerOnline = await _api.checkHealth(_vpsUrl);
      }
    } catch (e) {
      // ignore: avoid_print
      print('syncCatalog error: $e');
      _isServerOnline = false;
    }

    await _loadFromLocalDb();
    _isSyncing = false;
    notifyListeners();
  }

  // --- Device Pairing Flow (6-Digit Code) ---
  Future<String?> requestDevicePairing({String name = 'Kids Tablet'}) async {
    _deviceName = name;
    final res = await _api.registerDevice(_vpsUrl, name);
    if (res != null && res['pairing_code'] != null) {
      _pairingCode = res['pairing_code'].toString();
      notifyListeners();
      return _pairingCode;
    }
    return null;
  }

  Future<String> checkPairingStatus() async {
    if (_pairingCode == null) return 'expired';
    final res = await _api.checkDeviceStatus(_vpsUrl, _pairingCode!);
    if (res != null) {
      if (res['status'] == 'paired') {
        _isDevicePaired = true;
        await _db.setSetting('is_device_paired', 'true');

        final token = res['auth_token'] as String?;
        if (token != null && token.isNotEmpty) {
          await _secureStorage.write(key: 'device_auth_token', value: token);
          _api.setAuthToken(token);
        }

        if (res['profile'] != null) {
          final prof = ChildProfile.fromMap(res['profile'] as Map<String, dynamic>);
          if (prof != null) {
            _activeProfile = prof;
            await _db.upsertLocalProfile(prof);
            await _db.setSetting('current_profile_id', _activeProfile!.id);
            await _db.setSetting('current_profile_name', _activeProfile!.name);
            await _db.setSetting('current_profile_avatar', _activeProfile!.avatarIcon);
          }
        }

        notifyListeners();
        await syncCatalog();
        return 'paired';
      } else if (res['status'] == 'expired') {
        return 'expired';
      }
      return 'pending';
    }
    return 'pending';
  }

  Future<void> switchProfile(ChildProfile profile) async {
    _activeProfile = profile;
    await _db.setSetting('current_profile_id', profile.id);
    await _db.setSetting('current_profile_name', profile.name);
    await _db.setSetting('current_profile_avatar', profile.avatarIcon);
    try {
      final analytics = await _db.getWatchAnalytics(profileId: profile.id);
      _todayWatchSeconds = (analytics['today_seconds'] as num?)?.toInt() ?? 0;
    } catch (_) {}
    notifyListeners();
    await syncCatalog();
  }

  Future<void> addLocalProfile(ChildProfile profile) async {
    await _db.upsertLocalProfile(profile);
    _availableProfiles = await _db.getAllLocalProfiles();
    notifyListeners();
  }

  Future<void> deleteLocalProfile(String profileId) async {
    await _db.deleteLocalProfile(profileId);
    _availableProfiles = await _db.getAllLocalProfiles();
    if (_activeProfile?.id == profileId) {
      _activeProfile = _availableProfiles.isNotEmpty ? _availableProfiles.first : null;
      if (_activeProfile != null) {
        await _db.setSetting('current_profile_id', _activeProfile!.id);
        await _db.setSetting('current_profile_name', _activeProfile!.name);
        await _db.setSetting('current_profile_avatar', _activeProfile!.avatarIcon);
      }
    }
    notifyListeners();
  }

  List<VideoItem> getVideosForCategory(String categoryId) {
    return allVideos.where((v) => v.categoryId == categoryId).toList();
  }

  Future<void> startDownload(VideoItem video) async {
    _downloadProgress[video.id] = 0.01;
    notifyListeners();

    await _downloader.downloadVideo(
      video,
      onProgress: (id, progress) {
        _downloadProgress[id] = progress;
        notifyListeners();
      },
    );

    _downloadProgress.remove(video.id);
    await _loadFromLocalDb();
  }

  void cancelDownload(String videoId) {
    _downloader.cancelDownload(videoId);
    _downloadProgress.remove(videoId);
    notifyListeners();
  }

  Future<void> deleteDownloaded(VideoItem video) async {
    await _downloader.deleteDownloadedFile(video.id, video.localFilePath);
    await _loadFromLocalDb();
  }

  Future<void> clearAllDownloadedVideos() async {
    await _downloader.deleteAllDownloadedMedia();
    await _loadFromLocalDb();
  }

  Future<bool> submitUrlForIngestion(
    String url,
    String categoryId, {
    String quality = '720p',
    List<String>? allowedProfileIds,
  }) async {
    final success = await _api.ingestUrl(
      _vpsUrl,
      url,
      categoryId: categoryId,
      quality: quality,
      allowedProfileIds: allowedProfileIds,
    );
    if (success) {
      Future.delayed(const Duration(seconds: 4), () => syncCatalog());
    }
    return success;
  }

  Future<void> setVpsUrl(String newUrl) async {
    _vpsUrl = newUrl;
    await _db.setSetting('vps_url', newUrl);
    notifyListeners();
    await syncCatalog();
  }

  Future<void> toggleFavorite(String videoId) async {
    if (_favoriteVideoIds.contains(videoId)) {
      _favoriteVideoIds.remove(videoId);
    } else {
      _favoriteVideoIds.add(videoId);
    }
    notifyListeners();
    await _db.toggleFavorite(videoId);
  }

  void toggleOfflineOnly() {
    _isOfflineOnly = !_isOfflineOnly;
    notifyListeners();
  }

  // --- Local Watch Time Analytics (Cloudflare Quota Preserving) ---
  Future<void> recordWatchSession({
    required String videoId,
    String? videoTitle,
    String? categoryId,
    required int secondsWatched,
    int videoDuration = 0,
    bool isCompleted = false,
    bool isSkipped = false,
  }) async {
    if (secondsWatched <= 0) return;
    _todayWatchSeconds += secondsWatched;
    notifyListeners();

    await _db.recordWatchSession(
      videoId: videoId,
      videoTitle: videoTitle,
      categoryId: categoryId,
      profileId: _activeProfile?.id ?? 'kid_1',
      profileName: _activeProfile?.name ?? 'Kid 1',
      deviceId: _deviceName,
      secondsWatched: secondsWatched,
      videoDuration: videoDuration,
      isCompleted: isCompleted,
      isSkipped: isSkipped,
    );
  }

  Future<Map<String, dynamic>> getWatchAnalytics({String? profileId}) async {
    return await _db.getWatchAnalytics(profileId: profileId ?? _activeProfile?.id);
  }

  Future<Map<String, dynamic>> syncWatchEventsToServer() async {
    final unsynced = await _db.getUnsyncedWatchEvents();
    if (unsynced.isEmpty) {
      return {'success': true, 'synced_count': 0};
    }

    try {
      final res = await _api.syncWatchEvents(_vpsUrl, unsynced);
      if (res != null && res['success'] == true) {
        final syncedIds = (res['synced_ids'] as List?)?.map((e) => e.toString()).toList() ??
            unsynced.map((e) => e['id'] as String).toList();
        await _db.markWatchEventsSynced(syncedIds);
        return {'success': true, 'synced_count': syncedIds.length};
      }
      return {'success': false, 'error': 'Sync request failed'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // --- Video Deletion (Backend + Local SQLite + Disk Storage) ---
  Future<bool> deleteVideosFromCatalog(List<String> videoIds) async {
    if (videoIds.isEmpty) return true;
    _isLoading = true;
    notifyListeners();

    bool remoteSuccess = false;
    try {
      remoteSuccess = await _api.deleteVideos(_vpsUrl, videoIds);
    } catch (_) {}

    // Always prune locally from SQLite and disk
    await _db.deleteVideos(videoIds);
    await _loadFromLocalDb();

    _isLoading = false;
    notifyListeners();
    return remoteSuccess;
  }

  Future<int?> pingVpsServer() async {
    final latency = await _api.pingHealth(_vpsUrl);
    _isServerOnline = latency != null;
    notifyListeners();
    return latency;
  }
}
