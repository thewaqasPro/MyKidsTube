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

    // Verify Advanced Section Tiles
    expect(find.text('VPS Server Connection'), findsOneWidget);
    expect(find.text('Device Storage & Media'), findsOneWidget);

    // Verify Return to Kids button
    expect(find.text('Return to Kids'), findsOneWidget);
  });
}
