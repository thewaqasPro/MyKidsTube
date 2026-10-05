import 'package:flutter_test/flutter_test.dart';
import 'package:safe_tube/main.dart';

void main() {
  testWidgets('App renders KidsTube', (WidgetTester tester) async {
    await tester.pumpWidget(const KidsTubeApp());
    expect(find.text('KidsTube'), findsOneWidget);
  });
}
