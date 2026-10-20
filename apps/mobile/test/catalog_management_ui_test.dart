import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:safe_tube/providers/app_provider.dart';
import 'package:safe_tube/services/database_service.dart';
import 'package:safe_tube/services/download_service.dart';
import 'package:safe_tube/services/vps_api_service.dart';
import 'package:safe_tube/widgets/smart_cleanup_sheet.dart';
import 'package:safe_tube/models/video_item.dart';

class FakeVpsApiService extends Fake implements VpsApiService {
  @override
  Future<bool> checkHealth(String baseUrl) async => true;
  @override
  Future<Map<String, dynamic>?> fetchCatalog(String baseUrl, {String? profileId}) async => null;
}

class FakeDownloadService extends Fake implements DownloadService {
  @override
  Future<int> getTotalCachedBytes() async => 0;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('Catalog Management UI Tests', () {
    late Database db;
    late DatabaseService dbService;
    late AppProvider provider;

    setUp(() async {
      db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
      dbService = await DatabaseService.createTestInstance(db);
      provider = AppProvider(
        db: dbService,
        downloader: FakeDownloadService(),
        api: FakeVpsApiService(),
      );
    });

    tearDown(() async {
      await db.close();
    });

    testWidgets('SmartCleanupSheet renders empty state when no stale videos exist', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<AppProvider>.value(
          value: provider,
          child: const MaterialApp(
            home: Scaffold(
              body: SmartCleanupSheet(),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Smart Catalog Cleanup'), findsOneWidget);
      expect(find.textContaining('No cleanup needed'), findsOneWidget);
    });

    testWidgets('SmartCleanupSheet lists stale videos and allows deletion', (tester) async {
      final staleVideo = VideoItem(
        id: 'stale_1',
        title: 'Boring Skipped Video',
        categoryId: 'cartoons',
        streamUrl: 'https://example.com/stale.mp4',
        thumbnailUrl: '',
      );

      await tester.runAsync(() async {
        await provider.addStandaloneVideo(staleVideo);
      });

      await tester.pumpWidget(
        ChangeNotifierProvider<AppProvider>.value(
          value: provider,
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (_) => const SmartCleanupSheet(),
                    );
                  },
                  child: const Text('Open Sheet'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Open sheet
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('Boring Skipped Video'), findsOneWidget);
      expect(find.textContaining('Clean Up Selected (1)'), findsOneWidget);

      // Tap cleanup button
      await tester.runAsync(() async {
        await tester.tap(find.textContaining('Clean Up Selected'));
        await Future.delayed(const Duration(milliseconds: 150));
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      // Video should be pruned from provider
      expect(provider.allVideos.isEmpty, isTrue);

      // Settle remaining timers (such as SnackBar)
      await tester.pump(const Duration(seconds: 4));
      await tester.pump(const Duration(milliseconds: 500));
    });
  });
}
