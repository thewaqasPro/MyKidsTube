import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider.dart';
import 'screens/kid_home_screen.dart';
import 'screens/device_pairing_screen.dart';
import 'utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: KidColors.bgDark,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  final appProvider = AppProvider();
  await appProvider.init();

  runApp(
    ChangeNotifierProvider.value(
      value: appProvider,
      child: const KidsTubeApp(),
    ),
  );
}

class KidsTubeApp extends StatelessWidget {
  const KidsTubeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KidsTube',
      debugShowCheckedModeBanner: false,
      theme: KidTheme.darkTheme,
      home: Consumer<AppProvider>(
        builder: (context, provider, _) {
          if (!provider.isDevicePaired) {
            return const DevicePairingScreen();
          }
          return const KidHomeScreen();
        },
      ),
    );
  }
}
