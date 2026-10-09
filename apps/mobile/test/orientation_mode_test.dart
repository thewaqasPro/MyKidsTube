import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:safe_tube/providers/app_provider.dart';
import 'package:safe_tube/widgets/orientation_mode_switch.dart';

import 'package:safe_tube/services/database_service.dart';

class FakeDatabaseService extends Fake implements DatabaseService {
  final Map<String, String> settings = {};
  @override
  Future<String?> getSetting(String key) async => settings[key];
  @override
  Future<void> setSetting(String key, String value) async {
    settings[key] = value;
  }
}

void main() {
  test('AppOrientationMode enum serialization', () {
    expect(AppOrientationMode.auto.name, 'auto');
    expect(AppOrientationMode.portrait.name, 'portrait');
    expect(AppOrientationMode.landscape.name, 'landscape');

    final parsedMode = AppOrientationMode.values.firstWhere(
      (m) => m.name == 'landscape',
      orElse: () => AppOrientationMode.auto,
    );
    expect(parsedMode, AppOrientationMode.landscape);
  });

  testWidgets('OrientationModeSwitch cycles directly between portrait, landscape, and auto on tap', (WidgetTester tester) async {
    final mockProvider = AppProvider(db: FakeDatabaseService());

    await tester.pumpWidget(
      ChangeNotifierProvider<AppProvider>.value(
        value: mockProvider,
        child: const MaterialApp(
          home: Scaffold(
            body: OrientationModeSwitch(),
          ),
        ),
      ),
    );

    // Initial default is auto rotation icon
    expect(find.byType(OrientationModeSwitch), findsOneWidget);
    expect(find.byIcon(Icons.screen_rotation_rounded), findsOneWidget);

    // Tap 1: Auto -> Portrait
    await tester.tap(find.byType(OrientationModeSwitch));
    await tester.pumpAndSettle();
    expect(mockProvider.orientationMode, AppOrientationMode.portrait);
    expect(find.byIcon(Icons.stay_current_portrait_rounded), findsOneWidget);

    // Tap 2: Portrait -> Landscape
    await tester.tap(find.byType(OrientationModeSwitch));
    await tester.pumpAndSettle();
    expect(mockProvider.orientationMode, AppOrientationMode.landscape);
    expect(find.byIcon(Icons.stay_current_landscape_rounded), findsOneWidget);

    // Tap 3: Landscape -> Auto
    await tester.tap(find.byType(OrientationModeSwitch));
    await tester.pumpAndSettle();
    expect(mockProvider.orientationMode, AppOrientationMode.auto);
    expect(find.byIcon(Icons.screen_rotation_rounded), findsOneWidget);
  });
}
