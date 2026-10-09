import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safe_tube/widgets/kid_stat_card.dart';

void main() {
  group('KidStatCard Widget Tests', () {
    testWidgets('renders title, value, and subtitle in standard mode', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: KidStatCard(
              title: 'Catalog Total',
              value: '124 Videos',
              subtitle: '6 Categories',
              icon: Icons.video_library_rounded,
              color: Colors.red,
            ),
          ),
        ),
      );

      expect(find.text('Catalog Total'), findsOneWidget);
      expect(find.text('124 Videos'), findsOneWidget);
      expect(find.text('6 Categories'), findsOneWidget);
      expect(find.byIcon(Icons.video_library_rounded), findsOneWidget);
    });

    testWidgets('renders in compact mode and triggers onTap callback', (WidgetTester tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: KidStatCard(
              title: 'Offline',
              value: '15 MB',
              icon: Icons.storage_rounded,
              isCompact: true,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Offline'), findsOneWidget);
      expect(find.text('15 MB'), findsOneWidget);

      await tester.tap(find.byType(KidStatCard));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });
  });
}
