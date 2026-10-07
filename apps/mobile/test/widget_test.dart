import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safe_tube/main.dart';

void main() {
  testWidgets('SplashScreen renders KidsTube title', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: KidsTubeSplashScreen(),
      ),
    );
    expect(find.text('KidsTube'), findsOneWidget);
    expect(find.text('Safe & Fun Video Space'), findsOneWidget);
  });
}
