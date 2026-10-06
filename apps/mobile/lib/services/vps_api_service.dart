import 'package:dio/dio.dart';
import '../models/child_profile.dart';

class VpsApiService {
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
  ));

  Future<bool> checkHealth(String baseUrl) async {
    try {
      final cleanUrl = _normalizeUrl(baseUrl);
      final res = await _dio.get('$cleanUrl/api/v1/health');
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // --- Device Registration & Pairing (6-Digit Code) ---
  Future<Map<String, dynamic>?> registerDevice(String baseUrl, String deviceName) async {
    try {
      final cleanUrl = _normalizeUrl(baseUrl);
      final res = await _dio.post(
        '$cleanUrl/api/v1/devices/register',
        data: {'device_name': deviceName},
      );
      if (res.statusCode == 200 && res.data is Map<String, dynamic>) {
        return res.data as Map<String, dynamic>;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> checkDeviceStatus(String baseUrl, String pairingCode) async {
    try {
      final cleanUrl = _normalizeUrl(baseUrl);
      final res = await _dio.get('$cleanUrl/api/v1/devices/status/$pairingCode');
      if (res.statusCode == 200 && res.data is Map<String, dynamic>) {
        return res.data as Map<String, dynamic>;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // --- Profiles & Curated Catalog ---
  Future<List<ChildProfile>> fetchProfiles(String baseUrl) async {
    try {
      final cleanUrl = _normalizeUrl(baseUrl);
      final res = await _dio.get('$cleanUrl/api/v1/profiles');
      if (res.statusCode == 200 && res.data is List) {
        return (res.data as List).map((p) => ChildProfile.fromMap(p)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> fetchCatalog(String baseUrl, {String? profileId}) async {
    try {
      final cleanUrl = _normalizeUrl(baseUrl);
      var endpoint = '$cleanUrl/api/v1/catalog';
      if (profileId != null && profileId.isNotEmpty) {
        endpoint += '?profile_id=$profileId';
      }
      final res = await _dio.get(endpoint);
      if (res.statusCode == 200 && res.data is Map<String, dynamic>) {
        return res.data as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> ingestUrl(
    String baseUrl,
    String url, {
    String categoryId = 'cartoons',
    String quality = '720p',
    List<String>? allowedProfileIds,
  }) async {
    try {
      final cleanUrl = _normalizeUrl(baseUrl);
      final res = await _dio.post(
        '$cleanUrl/api/v1/ingest',
        data: {
          'url': url,
          'category_id': categoryId,
          'quality': quality,
          'allowed_profile_ids': allowedProfileIds,
        },
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<List<dynamic>> fetchTasks(String baseUrl) async {
    try {
      final cleanUrl = _normalizeUrl(baseUrl);
      final res = await _dio.get('$cleanUrl/api/v1/tasks');
      if (res.statusCode == 200 && res.data is List) {
        return res.data as List<dynamic>;
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  String _normalizeUrl(String url) {
    var trimmed = url.trim();
    if (trimmed.endsWith('/')) {
      trimmed = trimmed.substring(0, trimmed.length - 1);
    }
    if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
      trimmed = 'http://$trimmed';
    }
    return trimmed;
  }
}
