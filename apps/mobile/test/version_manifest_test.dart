import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Version Manifest (version.json) Validation', () {
    test('version.json exists at repository root and has valid schema', () {
      // Find repo root (mobile app is in apps/mobile)
      final manifestFile = File('../../version.json');
      expect(manifestFile.existsSync(), isTrue, reason: 'version.json must exist in repository root');

      final content = manifestFile.readAsStringSync();
      final data = jsonDecode(content);

      expect(data, isA<Map<String, dynamic>>());
      final map = data as Map<String, dynamic>;

      expect(map.containsKey('version'), isTrue);
      expect(map['version'], isA<String>());
      expect(map['version'].toString(), matches(r'^\d+\.\d+\.\d+$'));

      expect(map.containsKey('versionCode'), isTrue);
      expect(map['versionCode'], isA<int>());
      expect(map['versionCode'] as int, greaterThanOrEqualTo(1));

      expect(map.containsKey('releaseTitle'), isTrue);
      expect(map['releaseTitle'], isA<String>());
      expect((map['releaseTitle'] as String).isNotEmpty, isTrue);

      expect(map.containsKey('releaseNotes'), isTrue);
      expect(map['releaseNotes'], isA<String>());
      expect((map['releaseNotes'] as String).isNotEmpty, isTrue);

      expect(map.containsKey('apkDownloadUrl'), isTrue);
      expect(map['apkDownloadUrl'], isA<String>());
      expect((map['apkDownloadUrl'] as String).startsWith('https://'), isTrue);

      expect(map.containsKey('downloadPageUrl'), isTrue);
      expect(map['downloadPageUrl'], isA<String>());
      expect((map['downloadPageUrl'] as String).startsWith('https://'), isTrue);
    });
  });
}
