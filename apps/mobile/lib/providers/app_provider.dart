import 'package:flutter/material.dart';
import '../models/video_item.dart';
import '../models/category_item.dart';
import '../models/child_profile.dart';
import '../services/database_service.dart';
import '../services/vps_api_service.dart';
import '../services/download_service.dart';

class AppProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;
  final VpsApiService _api = VpsApiService();
  final DownloadService _downloader = DownloadService.instance;

  String _vpsUrl = 'https://kids.waqas.pro';
  String _parentPin = '1234';
  String _deviceName = 'Kids Tablet';

  // Multi-User state
  ChildProfile? _activeProfile;
  List<ChildProfile> _availableProfiles = [];
  String? _pairingCode;
  bool _isDevicePaired = false;

  List<CategoryItem> _categories = [];
  List<VideoItem> _allVideos = [];
  List<VideoItem> _downloadedVideos = [];
  final Map<String, double> _downloadProgress = {};

  bool _isLoading = false;
  bool _isSyncing = false;
  bool _isServerOnline = false;
  bool _isOfflineOnly = false;
  int _cachedBytes = 0;

  // Getters
  String get vpsUrl => _vpsUrl;
  String get parentPin => _parentPin;
  String get deviceName => _deviceName;
  ChildProfile? get activeProfile => _activeProfile;
  List<ChildProfile> get availableProfiles => _availableProfiles;
  String? get pairingCode => _pairingCode;
  bool get isDevicePaired => _isDevicePaired;

  List<CategoryItem> get categories => _categories;
  List<VideoItem> get allVideos => _isOfflineOnly ? _downloadedVideos : _allVideos;
  List<VideoItem> get downloadedVideos => _downloadedVideos;
  Map<String, double> get downloadProgress => _downloadProgress;
  bool get isLoading => _isLoading;
  bool get isSyncing => _isSyncing;
  bool get isServerOnline => _isServerOnline;
  bool get isOfflineOnly => _isOfflineOnly;
  int get cachedBytes => _cachedBytes;

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    // 1. Load settings
    final savedUrl = await _db.getSetting('vps_url');
    if (savedUrl != null && savedUrl.isNotEmpty) _vpsUrl = savedUrl;

    final savedPin = await _db.getSetting('parent_pin');
    if (savedPin != null && savedPin.isNotEmpty) _parentPin = savedPin;

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

    // 2. Load cached local database
    await _loadFromLocalDb();

    _isLoading = false;
    notifyListeners();

    // 3. Background sync with VPS
    await syncCatalog();
  }

  Future<void> _loadFromLocalDb() async {
    _categories = await _db.getAllCategories();
    _allVideos = await _db.getAllVideos();
    _downloadedVideos = await _db.getDownloadedVideos();
    _cachedBytes = await _downloader.getTotalCachedBytes();
    notifyListeners();
  }

  Future<void> syncCatalog() async {
    _isSyncing = true;
    notifyListeners();

    _isServerOnline = await _api.checkHealth(_vpsUrl);
    if (_isServerOnline) {
      // Sync profiles
      _availableProfiles = await _api.fetchProfiles(_vpsUrl);

      // Fetch curated catalog for active profile
      final catalogData = await _api.fetchCatalog(_vpsUrl, profileId: _activeProfile?.id);
      if (catalogData != null && catalogData['sections'] is List) {
        final sections = catalogData['sections'] as List;

        for (final sec in sections) {
          final catJson = sec['category'];
          final category = CategoryItem(
            id: catJson['id'],
            name: catJson['name'],
            icon: catJson['icon'] ?? 'category',
            displayOrder: catJson['display_order'] ?? 0,
          );
          await _db.upsertCategory(category);

          final videosJson = sec['videos'] as List? ?? [];
          for (final vJson in videosJson) {
            final video = VideoItem.fromApi(vJson);
            await _db.upsertVideo(video);
          }
        }
      }
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
      _pairingCode = res['pairing_code'];
      notifyListeners();
      return _pairingCode;
    }
    return null;
  }

  Future<bool> checkPairingStatus() async {
    if (_pairingCode == null) return false;
    final res = await _api.checkDeviceStatus(_vpsUrl, _pairingCode!);
    if (res != null && res['status'] == 'paired') {
      _isDevicePaired = true;
      await _db.setSetting('is_device_paired', 'true');

      if (res['profile'] != null) {
        final profJson = res['profile'];
        _activeProfile = ChildProfile.fromMap(profJson);
        await _db.setSetting('current_profile_id', _activeProfile!.id);
        await _db.setSetting('current_profile_name', _activeProfile!.name);
        await _db.setSetting('current_profile_avatar', _activeProfile!.avatarIcon);
      }

      notifyListeners();
      await syncCatalog();
      return true;
    }
    return false;
  }

  void skipPairingForDev() {
    _isDevicePaired = true;
    notifyListeners();
  }

  Future<void> switchProfile(ChildProfile profile) async {
    _activeProfile = profile;
    await _db.setSetting('current_profile_id', profile.id);
    await _db.setSetting('current_profile_name', profile.name);
    await _db.setSetting('current_profile_avatar', profile.avatarIcon);
    notifyListeners();
    await syncCatalog();
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

  Future<void> setParentPin(String newPin) async {
    _parentPin = newPin;
    await _db.setSetting('parent_pin', newPin);
    notifyListeners();
  }

  void toggleOfflineOnly() {
    _isOfflineOnly = !_isOfflineOnly;
    notifyListeners();
  }
}
