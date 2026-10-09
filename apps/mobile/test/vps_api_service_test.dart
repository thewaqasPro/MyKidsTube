import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safe_tube/services/vps_api_service.dart';

class MockDioAdapter implements HttpClientAdapter {
  final Map<String, ResponseBody Function(RequestOptions options)> handlers = {};

  void on(String pathSuffix, ResponseBody Function(RequestOptions options) handler) {
    handlers[pathSuffix] = handler;
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    for (final entry in handlers.entries) {
      if (options.path.endsWith(entry.key)) {
        return entry.value(options);
      }
    }
    return ResponseBody.fromString(
      jsonEncode({'error': 'Not found'}),
      404,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  group('VpsApiService Unit Tests with Mock Dio Adapter', () {
    late Dio dio;
    late MockDioAdapter mockAdapter;
    late VpsApiService apiService;
    const testBaseUrl = 'https://api.test.example';

    setUp(() {
      dio = Dio();
      mockAdapter = MockDioAdapter();
      dio.httpClientAdapter = mockAdapter;
      apiService = VpsApiService(dio: dio);
    });

    test('checkHealth returns true when status code is 200', () async {
      mockAdapter.on('/api/v1/health', (options) {
        return ResponseBody.fromString(
          jsonEncode({'status': 'healthy'}),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      final result = await apiService.checkHealth(testBaseUrl);
      expect(result, isTrue);
    });

    test('checkHealth returns false when server returns 500 or error', () async {
      mockAdapter.on('/api/v1/health', (options) {
        return ResponseBody.fromString(
          'Internal Server Error',
          500,
        );
      });

      final result = await apiService.checkHealth(testBaseUrl);
      expect(result, isFalse);
    });

    test('registerDevice sends device_name and parses pairing code payload', () async {
      mockAdapter.on('/api/v1/devices/register', (options) {
        final body = options.data as Map<String, dynamic>;
        expect(body['device_name'], 'Tablet Kids');
        return ResponseBody.fromString(
          jsonEncode({'pairing_code': '123456', 'device_id': 'dev_abc'}),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      final response = await apiService.registerDevice(testBaseUrl, 'Tablet Kids');
      expect(response, isNotNull);
      expect(response!['pairing_code'], '123456');
      expect(response['device_id'], 'dev_abc');
    });

    test('checkDeviceStatus attaches Bearer auth header when token is set', () async {
      apiService.setAuthToken('secret_token_123');
      expect(apiService.authToken, 'secret_token_123');

      mockAdapter.on('/api/v1/devices/status/123456', (options) {
        expect(options.headers['Authorization'], 'Bearer secret_token_123');
        return ResponseBody.fromString(
          jsonEncode({'status': 'paired'}),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      final res = await apiService.checkDeviceStatus(testBaseUrl, '123456');
      expect(res, isNotNull);
      expect(res!['status'], 'paired');
    });

    test('fetchCatalog parses categories and video payload safely', () async {
      mockAdapter.on('/api/v1/catalog', (options) {
        return ResponseBody.fromString(
          jsonEncode({
            'categories': [
              {'id': 'cartoons', 'name': 'Cartoons'},
            ],
            'videos': [
              {
                'id': 'v1',
                'title': 'Fun Video',
                'category_id': 'cartoons',
                'stream_url': 'https://stream.example/1',
                'thumbnail_url': 'https://thumb.example/1.jpg',
              }
            ],
          }),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      final catalog = await apiService.fetchCatalog(testBaseUrl);
      expect(catalog, isNotNull);
      final categories = catalog!['categories'] as List;
      final videos = catalog['videos'] as List;
      expect(categories.length, 1);
      expect(categories.first['id'], 'cartoons');
      expect(videos.length, 1);
      expect(videos.first['id'], 'v1');
    });
  });
}
