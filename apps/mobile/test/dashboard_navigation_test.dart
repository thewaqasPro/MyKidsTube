import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:safe_tube/providers/app_provider.dart';
import 'package:safe_tube/screens/parent_dashboard_screen.dart';

void main() {
  testWidgets('ParentDashboardScreen renders streamlined executive stats and management sections', (WidgetTester tester) async {
    final provider = AppProvider();

    await tester.pumpWidget(
      ChangeNotifierProvider<AppProvider>.value(
        value: provider,
        child: const MaterialApp(
          home: ParentDashboardScreen(),
        ),
      ),
    );

    // Verify Title
    expect(find.text('Parent Command Center'), findsOneWidget);

    // Verify Streamlined Executive Stats
    expect(find.text('Catalog Size'), findsOneWidget);
    expect(find.text("Today's Watch"), findsOneWidget);

    // Verify Primary Action
    expect(find.text('Add YouTube Video'), findsOneWidget);

    // Verify Management Section Tiles
    expect(find.text('Media Library'), findsOneWidget);
    expect(find.text('Watch Time & Analytics'), findsOneWidget);
    expect(find.text('PIN & Security Settings'), findsOneWidget);
    expect(find.text('Curated Starter Pack'), findsOneWidget);

    // Verify Advanced Section Tiles
    expect(find.text('VPS Server Connection'), findsOneWidget);
    expect(find.text('Device Storage & Media'), findsOneWidget);

    // Verify Return to Kids button
    expect(find.text('Return to Kids'), findsOneWidget);
  });

  testWidgets('Back button navigates back to previous tab and only exits on Overview with empty history', (WidgetTester tester) async {
    final provider = AppProvider();
    bool didExit = false;

    await tester.pumpWidget(
      ChangeNotifierProvider<AppProvider>.value(
        value: provider,
        child: MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ParentDashboardScreen()),
                );
                didExit = true;
              },
              child: const Text('Open Dashboard'),
            ),
          ),
        ),
      ),
    );

    // Tap to open dashboard
    await tester.tap(find.text('Open Dashboard'));
    await tester.pumpAndSettle();

    expect(find.text('Parent Command Center'), findsOneWidget);

    // Switch to Tab 1 (Search YouTube) via Hero Action Card
    await tester.tap(find.text('Search YouTube & Channels'));
    await tester.pumpAndSettle();

    expect(find.text('Search & Add YouTube Videos'), findsOneWidget);

    // Switch to Tab 2 (Screen Time) via bottom navigation bar
    await tester.tap(find.text('Screen Time'));
    await tester.pumpAndSettle();

    expect(find.text('Screen Time & Limits'), findsOneWidget);

    // Switch to Tab 3 (Settings) via bottom navigation bar
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    expect(find.text('Parent Settings'), findsOneWidget);

    // Find back button in AppBar
    final backButton = find.byIcon(Icons.arrow_back_ios_new_rounded);

    // 1st Back: Should go from Settings (3) -> Screen Time (2)
    await tester.tap(backButton);
    await tester.pumpAndSettle();
    expect(find.text('Screen Time & Limits'), findsOneWidget);
    expect(didExit, isFalse);

    // 2nd Back: Should go from Screen Time (2) -> Search YouTube (1)
    await tester.tap(backButton);
    await tester.pumpAndSettle();
    expect(find.text('Search & Add YouTube Videos'), findsOneWidget);
    expect(didExit, isFalse);

    // 3rd Back: Should go from Search YouTube (1) -> Overview (0)
    await tester.tap(backButton);
    await tester.pumpAndSettle();
    expect(find.text('Parent Command Center'), findsOneWidget);
    expect(didExit, isFalse);

    // 4th Back: Now on Overview with empty history, should pop out to previous route (Home)
    await tester.tap(backButton);
    await tester.pumpAndSettle();
    expect(didExit, isTrue);
    expect(find.text('Open Dashboard'), findsOneWidget);
  });
}
