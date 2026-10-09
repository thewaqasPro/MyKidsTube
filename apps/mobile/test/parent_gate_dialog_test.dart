import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:safe_tube/providers/app_provider.dart';
import 'package:safe_tube/screens/parent_gate_dialog.dart';

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });
  group('ParentGateDialog Widget Tests', () {
    testWidgets('renders Grown-Ups Only title and math problem', (WidgetTester tester) async {
      final provider = AppProvider();

      await tester.pumpWidget(
        ChangeNotifierProvider<AppProvider>.value(
          value: provider,
          child: const MaterialApp(
            home: Scaffold(
              body: ParentGateDialog(),
            ),
          ),
        ),
      );

      expect(find.text('Grown-Ups Only'), findsOneWidget);
      expect(find.text('Please solve this problem or enter PIN to continue:'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Enter'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('shows error message when incorrect answer is entered', (WidgetTester tester) async {
      final provider = AppProvider();

      await tester.pumpWidget(
        ChangeNotifierProvider<AppProvider>.value(
          value: provider,
          child: const MaterialApp(
            home: Scaffold(
              body: ParentGateDialog(),
            ),
          ),
        ),
      );

      // Enter a clearly wrong answer (-99999)
      await tester.enterText(find.byType(TextField), '-99999');
      await tester.tap(find.text('Enter'));
      await tester.pumpAndSettle();

      expect(find.text('Incorrect answer. Try again!'), findsOneWidget);
    });
  });
}
