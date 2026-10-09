import 'package:dio/dio.dart';
import '../models/child_profile.dart';

class VpsApiService {
  final Dio _dio;

  VpsApiService({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 15),
            ));

  String? _authToken;

  void setAuthToken(String? token) {
    _authToken = token;
  }

  String? get authToken => _authToken;

  Options _authOptions([Options? base]) {
    final headers = Map<String, dynamic>.from(base?.headers ?? {});
    if (_authToken != null && _authToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return (base ?? Options()).copyWith(headers: headers);
  }

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
      final res = await _dio.get(
        '$cleanUrl/api/v1/devices/status/$pairingCode',
        options: _authOptions(),
      );
      if (res.statusCode == 200 && res.data is Map<String, dynamic>) {
        return res.data as Map<String, dynamic>;
      }
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return {'status': 'expired', 'message': 'Pairing code expired or invalid'};
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
      final res = await _dio.get(
        '$cleanUrl/api/v1/profiles',
        options: _authOptions(),
      );
      if (res.statusCode == 200 && res.data is List) {
        return (res.data as List)
            .map((p) => ChildProfile.fromMap(p as Map<String, dynamic>))
            .whereType<ChildProfile>()
            .toList();
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
      final res = await _dio.get(
        endpoint,
        options: _authOptions(),
      );
      if (res.statusCode == 200 && res.data is Map<String, dynamic>) {
        return res.data as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      // ignore: avoid_print
      print('fetchCatalog error: $e');
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
        options: _authOptions(),
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteVideos(String baseUrl, List<String> videoIds) async {
    if (videoIds.isEmpty) return true;
    try {
      final cleanUrl = _normalizeUrl(baseUrl);
      final idsParam = videoIds.join(',');
      final res = await _dio.delete(
        '$cleanUrl/api/studio/videos?ids=$idsParam',
        options: _authOptions(),
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> syncWatchEvents(String baseUrl, List<Map<String, dynamic>> events) async {
    if (events.isEmpty) return {'success': true, 'synced_count': 0};
    try {
      final cleanUrl = _normalizeUrl(baseUrl);
      final res = await _dio.post(
        '$cleanUrl/api/metrics/watch',
        data: {'events': events},
        options: _authOptions(),
      );
      if (res.statusCode == 200 && res.data is Map<String, dynamic>) {
        return res.data as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      // ignore: avoid_print
      print('syncWatchEvents error: $e');
      return null;
    }
  }

  Future<int?> pingHealth(String baseUrl) async {
    final cleanUrl = _normalizeUrl(baseUrl);
    final stopwatch = Stopwatch()..start();
    try {
      final res = await _dio.get('$cleanUrl/api/v1/health');
      stopwatch.stop();
      if (res.statusCode == 200) {
        return stopwatch.elapsedMilliseconds;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  String _normalizeUrl(String url) {
    var trimmed = url.trim();
    if (trimmed.endsWith('/')) {
      trimmed = trimmed.substring(0, trimmed.length - 1);
    }
    if (trimmed.startsWith('http://')) {
      // Warn on explicit http://
      // ignore: avoid_print
      print('⚠️ Warning: Using explicit cleartext HTTP connection for $trimmed');
      return trimmed;
    }
    if (!trimmed.startsWith('https://')) {
      trimmed = 'https://$trimmed';
    }
    return trimmed;
  }
}
