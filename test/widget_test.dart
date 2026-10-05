import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:safe_tube/main.dart';
import 'package:safe_tube/providers/app_provider.dart';

void main() {
  testWidgets('App renders KidsTube title', (WidgetTester tester) async {
    final appProvider = AppProvider();
    appProvider.skipPairingForDev();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: appProvider,
        child: const KidsTubeApp(),
      ),
    );
    expect(find.textContaining('KidsTube'), findsWidgets);
  });
}
