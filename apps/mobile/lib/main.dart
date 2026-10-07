import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider.dart';
import 'screens/kid_home_screen.dart';
import 'screens/device_pairing_screen.dart';
import 'utils/constants.dart';

void main() {
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

  // runApp immediately without awaiting network initialization
  runApp(
    ChangeNotifierProvider.value(
      value: appProvider,
      child: const KidsTubeApp(),
    ),
  );
}

class KidsTubeApp extends StatefulWidget {
  const KidsTubeApp({super.key});

  @override
  State<KidsTubeApp> createState() => _KidsTubeAppState();
}

class _KidsTubeAppState extends State<KidsTubeApp> {
  bool _hasStartedInit = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasStartedInit) {
        _hasStartedInit = true;
        final provider = Provider.of<AppProvider>(context, listen: false);
        provider.init();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KidsTube',
      debugShowCheckedModeBanner: false,
      theme: KidTheme.darkTheme,
      home: Consumer<AppProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const KidsTubeSplashScreen();
          }
          if (!provider.isDevicePaired) {
            return const DevicePairingScreen();
          }
          return const KidHomeScreen();
        },
      ),
    );
  }
}

class KidsTubeSplashScreen extends StatelessWidget {
  const KidsTubeSplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KidColors.bgDark,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [KidColors.primary, KidColors.accent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: KidColors.primary.withValues(alpha: 0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(Icons.tv_rounded, color: Colors.white, size: 48),
            ),
            const SizedBox(height: 20),
            const Text(
              'KidsTube',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Safe & Fun Video Space',
              style: TextStyle(
                color: KidColors.textMuted,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 32),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: KidColors.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
