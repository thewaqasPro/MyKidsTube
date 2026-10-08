import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:safe_tube/providers/app_provider.dart';
import 'package:safe_tube/widgets/orientation_mode_switch.dart';

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

  testWidgets('OrientationModeSwitch renders current orientation icon and popup options', (WidgetTester tester) async {
    final mockProvider = AppProvider();

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

    // Tap to open popup menu
    await tester.tap(find.byType(OrientationModeSwitch));
    await tester.pumpAndSettle();

    // Verify popup menu options
    expect(find.text('Auto Rotate'), findsOneWidget);
    expect(find.text('Landscape'), findsOneWidget);
    expect(find.text('Portrait'), findsOneWidget);
  });
}
