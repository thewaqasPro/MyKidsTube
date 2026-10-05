import 'package:dio/dio.dart';
import '../models/video_item.dart';
import '../models/category_item.dart';

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

  Future<Map<String, dynamic>?> fetchCatalog(String baseUrl) async {
    try {
      final cleanUrl = _normalizeUrl(baseUrl);
      final res = await _dio.get('$cleanUrl/api/v1/catalog');
      if (res.statusCode == 200 && res.data is Map<String, dynamic>) {
        return res.data as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> ingestUrl(String baseUrl, String url, {String categoryId = 'cartoons', String quality = '720p'}) async {
    try {
      final cleanUrl = _normalizeUrl(baseUrl);
      final res = await _dio.post(
        '$cleanUrl/api/v1/ingest',
        data: {
          'url': url,
          'category_id': categoryId,
          'quality': quality,
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
