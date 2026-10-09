import 'dart:async';
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
  final DatabaseService _db;
  final VpsApiService _api;
  final DownloadService _downloader;
  final FlutterSecureStorage _secureStorage;

  AppProvider({
    DatabaseService? db,
    VpsApiService? api,
    DownloadService? downloader,
    FlutterSecureStorage? secureStorage,
  })  : _db = db ?? DatabaseService.instance,
        _api = api ?? VpsApiService(),
        _downloader = downloader ?? DownloadService.instance,
        _secureStorage = secureStorage ?? const FlutterSecureStorage();

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

  // R5 Safeguard & Safety Cap State
  bool _hasRefreshFailedNotice = false;
  String? _refreshNoticeMessage;
  int _pendingPruneCount = 0;
  List<String> _pendingPruneVideoIds = [];
  Timer? _retryTimer;

  static const double maxPrunePercentage = 0.50; // Safety cap: max 50% in one sync without confirmation

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

  bool get hasRefreshFailedNotice => _hasRefreshFailedNotice;
  String? get refreshNoticeMessage => _refreshNoticeMessage;
  int get pendingPruneCount => _pendingPruneCount;
  bool get hasPendingMassPrune => _pendingPruneCount > 0;
  List<String> get pendingPruneVideoIds => List.unmodifiable(_pendingPruneVideoIds);

  void dismissRefreshNotice() {
    _hasRefreshFailedNotice = false;
    _refreshNoticeMessage = null;
    notifyListeners();
  }

  Future<void> confirmPendingPrune() async {
    if (_pendingPruneVideoIds.isEmpty) return;
    final idsToDelete = List<String>.from(_pendingPruneVideoIds);
    _pendingPruneVideoIds = [];
    _pendingPruneCount = 0;
    _hasRefreshFailedNotice = false;
    _refreshNoticeMessage = null;
    await _db.deleteVideos(idsToDelete);
    await _loadFromLocalDb();
    notifyListeners();
  }

  void dismissPendingPrune() {
    _pendingPruneVideoIds = [];
    _pendingPruneCount = 0;
    _hasRefreshFailedNotice = false;
    _refreshNoticeMessage = null;
    notifyListeners();
  }

  void _scheduleCatalogRetry() {
    _retryTimer?.cancel();
    _retryTimer = Timer(const Duration(seconds: 30), () {
      if (!_isSyncing) {
        syncCatalog();
      }
    });
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    super.dispose();
  }

  Future<void> setOrientationMode(AppOrientationMode mode) async {
    _orientationMode = mode;
    notifyListeners();
    await _applyOrientationMode(mode);
    await _db.setSetting('orientation_mode', mode.name);
  }

  Future<void> applyCurrentOrientationMode() async {
    await _applyOrientationMode(_orientationMode);
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

    try {
      // 1. Read vps_url from settings first; only write default when none exists (survives restart)
      try {
        final savedUrl = await _db.getSetting('vps_url');
        if (savedUrl != null && savedUrl.isNotEmpty) {
          _vpsUrl = savedUrl;
        } else {
          _vpsUrl = 'https://mykidstube.kidstube.workers.dev';
          await _db.setSetting('vps_url', _vpsUrl);
        }
      } catch (_) {
        await _db.recoverCorruptedDatabase();
        _vpsUrl = 'https://mykidstube.kidstube.workers.dev';
        try { await _db.setSetting('vps_url', _vpsUrl); } catch (_) {}
      }

      // 2. Initialize PIN security in secure storage
      await _initPinSecurity();

      // 3. Load device auth token from secure storage
      final savedToken = await _secureStorage.read(key: 'device_auth_token');
      if (savedToken != null && savedToken.isNotEmpty) {
        _api.setAuthToken(savedToken);
      }

      try {
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
      } catch (_) {}

      // 4. Load initial database state
      await _loadFromLocalDb();

      // 4b. Restore saved orientation mode
      try {
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
      } catch (_) {}
    } catch (_) {
      // Graceful error recovery: avoid black screen
    } finally {
      _isLoading = false;
      notifyListeners();
    }

    // 5. Background sync with Edge API
    try {
      await syncCatalog();
    } catch (_) {}
  }

  Future<void> clearMobileCache() async {
    _isLoading = true;
    notifyListeners();
    await _db.clearAllCache();
    await syncCatalog();
  }

  Future<void> _loadFromLocalDb() async {
    try {
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
    } catch (e) {
      // Corrupt DB file recovery: backup corrupt DB file and recreate fresh DB
      try {
        await _db.recoverCorruptedDatabase();
      } catch (_) {}
      _categories = [];
      _allVideos = [];
      _downloadedVideos = [];
      _favoriteVideoIds = {};
      _cachedBytes = 0;
      _availableProfiles = [];
      _activeProfile = null;
      _todayWatchSeconds = 0;
    }
    notifyListeners();
  }

  Future<void> syncCatalog({bool allowMassPrune = false, bool autoRetry = true}) async {
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

        final bool isCatalogClearedExplicitly =
            catalogData['catalog_cleared'] == true ||
            catalogData['allow_empty_catalog'] == true;

        if (videosToSync.isEmpty && !isCatalogClearedExplicitly) {
          // Ambiguous empty response: sections or videos was empty without an explicit server signal.
          // Keep local library intact. Do NOT prune or wipe!
          _hasRefreshFailedNotice = true;
          _refreshNoticeMessage = "Couldn't refresh video catalog. Using offline library.";
          if (autoRetry) _scheduleCatalogRetry();
          // ignore: avoid_print
          print('syncCatalog: Ambiguous empty catalog response detected. Keeping local library intact.');
        } else if (videosToSync.isEmpty && isCatalogClearedExplicitly) {
          // Explicit server signal that catalog was intentionally cleared
          final localVideos = await _db.getAllVideos();
          if (localVideos.isNotEmpty && !allowMassPrune) {
            // Safety cap: require explicit parent confirmation in dashboard
            _pendingPruneVideoIds = localVideos.map((v) => v.id).toList();
            _pendingPruneCount = localVideos.length;
            _hasRefreshFailedNotice = true;
            _refreshNoticeMessage = "Server signaled cleared catalog. Parent confirmation required in dashboard to delete offline library.";
          } else {
            _allVideos = [];
            _categories = [];
            await _db.pruneRemovedVideos([], allowEmpty: true, force: true);
            _pendingPruneVideoIds = [];
            _pendingPruneCount = 0;
            _hasRefreshFailedNotice = false;
            _refreshNoticeMessage = null;
          }
        } else {
          // Valid non-empty catalog: sync and prune appropriately
          _retryTimer?.cancel();
          _allVideos = List.from(videosToSync);
          if (categoriesToSync.isNotEmpty) {
            _categories = List.from(categoriesToSync);
          }

          // Atomic transaction batch upsert to persist to local SQLite
          await _db.batchUpsertCatalog(categoriesToSync, videosToSync);

          // Check removals against local SQLite videos
          final localVideos = await _db.getAllVideos();
          final validIds = videosToSync.map((v) => v.id).toSet();
          final toDelete = localVideos.where((v) => !validIds.contains(v.id)).toList();

          if (toDelete.isNotEmpty) {
            final pruneRatio = toDelete.length / localVideos.length;
            if (!allowMassPrune && localVideos.length > 2 && pruneRatio > maxPrunePercentage) {
              // Safety cap: never delete more than 50% without explicit parent confirmation
              _pendingPruneVideoIds = toDelete.map((v) => v.id).toList();
              _pendingPruneCount = toDelete.length;
              _hasRefreshFailedNotice = true;
              _refreshNoticeMessage = "Catalog refreshed, but ${toDelete.length} video removal(s) (${(pruneRatio * 100).toStringAsFixed(0)}%) held for parent confirmation.";
              // ignore: avoid_print
              print('syncCatalog: Safety cap held ${toDelete.length}/${localVideos.length} video deletions.');
            } else {
              // Genuine removal (<= 50% or allowMassPrune confirmed)
              await _db.pruneRemovedVideos(validIds.toList(), force: allowMassPrune);
              _pendingPruneVideoIds = [];
              _pendingPruneCount = 0;
              _hasRefreshFailedNotice = false;
              _refreshNoticeMessage = null;
            }
          } else {
            _pendingPruneVideoIds = [];
            _pendingPruneCount = 0;
            _hasRefreshFailedNotice = false;
            _refreshNoticeMessage = null;
          }
        }

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
        _hasRefreshFailedNotice = true;
        _refreshNoticeMessage = "Couldn't refresh video catalog. Using offline library.";
        if (autoRetry) _scheduleCatalogRetry();
      }
    } catch (e) {
      // ignore: avoid_print
      print('syncCatalog error: $e');
      _isServerOnline = false;
      _hasRefreshFailedNotice = true;
      _refreshNoticeMessage = "Couldn't refresh video catalog. Using offline library.";
      if (autoRetry) _scheduleCatalogRetry();
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

  String? _lastStorageError;
  String? get lastStorageError => _lastStorageError;

  Future<int?> getFreeDiskSpace() => _downloader.getFreeDiskSpace();
  String formatBytes(int bytes) => DownloadService.formatBytes(bytes);

  Future<String?> startDownload(VideoItem video) async {
    // Pre-flight free storage check
    final freeBytes = await _downloader.getFreeDiskSpace();
    final requiredBytes = video.fileSizeBytes > 0 ? video.fileSizeBytes : 25 * 1024 * 1024;
    if (freeBytes != null && freeBytes < requiredBytes) {
      final shortfall = requiredBytes - freeBytes;
      final msg = "Not enough storage space for '${video.title}'. Short by ${DownloadService.formatBytes(shortfall)}.";
      _lastStorageError = msg;
      notifyListeners();
      return msg;
    }

    _downloadProgress[video.id] = 0.01;
    notifyListeners();

    final success = await _downloader.downloadVideo(
      video,
      onProgress: (id, progress) {
        _downloadProgress[id] = progress;
        notifyListeners();
      },
    );

    _downloadProgress.remove(video.id);
    await _loadFromLocalDb();

    if (!success && _downloader.lastErrorMessage != null) {
      _lastStorageError = _downloader.lastErrorMessage;
      notifyListeners();
      return _downloader.lastErrorMessage;
    }
    return null;
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
