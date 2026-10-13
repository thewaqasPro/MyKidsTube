import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider.dart';
import 'screens/kid_home_screen.dart';
import 'utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Enforce system UI overlay style matching YouTube Dark
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: KidColors.bgDark,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()),
      ],
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
          return const KidHomeScreen();
        },
      ),
    );
  }
}

/// Authentic YouTube-Style Clean Minimal Splash Screen
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
            // Clean YouTube-Style Red Play Badge
            Container(
              width: 72,
              height: 52,
              decoration: BoxDecoration(
                color: KidColors.primary,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: KidColors.primary.withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 38,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'KidsTube',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w900,
                fontSize: 28,
                letterSpacing: -0.5,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Safe & Fun Video Space',
              style: TextStyle(
                fontFamily: 'Roboto',
                color: KidColors.textMuted,
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 36),
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color: KidColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
