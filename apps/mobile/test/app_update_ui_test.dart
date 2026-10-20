import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safe_tube/models/app_update_info.dart';
import 'package:safe_tube/widgets/app_update_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppUpdateDialog UI Tests', () {
    testWidgets('Renders update available details and action buttons', (tester) async {
      final info = AppUpdateInfo(
        hasUpdate: true,
        currentVersion: '1.3.0',
        latestVersion: '1.4.0',
        latestVersionCode: 4,
        releaseTitle: 'MyKidsTube v1.4.0 — Intro Skip & Updates',
        releaseNotes: '- Added skip intro controls\n- Added GitHub update system',
        apkDownloadUrl: 'https://github.com/.../app.apk',
        downloadPageUrl: 'https://github.com/.../release',
      );

      bool urlLaunched = false;
      String? launchedUrl;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  AppUpdateDialog.show(
                    context,
                    info: info,
                    onLaunchUrlOverride: (url) async {
                      urlLaunched = true;
                      launchedUrl = url;
                      return true;
                    },
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Update Available'), findsOneWidget);
      expect(find.textContaining('v1.4.0'), findsWidgets);
      expect(find.text('MyKidsTube v1.4.0 — Intro Skip & Updates'), findsOneWidget);
      expect(find.textContaining('Added skip intro controls'), findsOneWidget);
      expect(find.text('Download & Install Update'), findsOneWidget);
      expect(find.text('View on GitHub'), findsOneWidget);

      // Tap Download
      await tester.tap(find.text('Download & Install Update'));
      await tester.pumpAndSettle();

      expect(urlLaunched, isTrue);
      expect(launchedUrl, equals('https://github.com/.../app.apk'));
    });

    testWidgets('Renders up-to-date dialog when hasUpdate is false', (tester) async {
      final info = AppUpdateInfo.upToDate(currentVersion: '1.4.0');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  AppUpdateDialog.show(context, info: info);
                },
                child: const Text('Open UpToDate Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open UpToDate Dialog'));
      await tester.pumpAndSettle();

      expect(find.text("You're Up to Date!"), findsOneWidget);
      expect(find.textContaining('1.4.0'), findsOneWidget);
      expect(find.text('OK'), findsOneWidget);
    });
  });
}
