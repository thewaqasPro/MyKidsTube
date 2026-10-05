import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/constants.dart';
import 'kid_home_screen.dart';

class DevicePairingScreen extends StatefulWidget {
  const DevicePairingScreen({super.key});

  @override
  State<DevicePairingScreen> createState() => _DevicePairingScreenState();
}

class _DevicePairingScreenState extends State<DevicePairingScreen> {
  Timer? _pollTimer;
  bool _isRequesting = false;

  @override
  void initState() {
    super.initState();
    _initPairing();
  }

  Future<void> _initPairing() async {
    final provider = Provider.of<AppProvider>(context, listen: false);
    setState(() => _isRequesting = true);

    await provider.requestDevicePairing(name: 'Kids Tablet');
    setState(() => _isRequesting = false);

    // Poll status every 2.5 seconds
    _pollTimer = Timer.periodic(const Duration(milliseconds: 2500), (timer) async {
      final isPaired = await provider.checkPairingStatus();
      if (isPaired && mounted) {
        timer.cancel();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const KidHomeScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        final code = provider.pairingCode ?? '---';

        return Scaffold(
          backgroundColor: KidColors.bgDark,
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App Icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [KidColors.primary, KidColors.accent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: KidColors.primary.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.tv_rounded, color: Colors.white, size: 44),
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    'Welcome to KidsTube!',
                    style: TextStyle(
                      color: KidColors.textLight,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    'To pair this device with your family library,\nopen your Parent Dashboard and enter this code:',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: KidColors.textMuted,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // 6-Digit Pairing Code Box
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                    decoration: BoxDecoration(
                      color: KidColors.cardDark,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: KidColors.primary, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: KidColors.primary.withOpacity(0.15),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: _isRequesting
                        ? const SizedBox(
                            width: 32,
                            height: 32,
                            child: CircularProgressIndicator(color: KidColors.primary),
                          )
                        : Text(
                            code,
                            style: const TextStyle(
                              color: KidColors.textLight,
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'monospace',
                              letterSpacing: 4,
                            ),
                          ),
                  ),

                  const SizedBox(height: 24),

                  // Animated Polling Pill
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: KidColors.accent,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Waiting for parent authorization...',
                        style: TextStyle(
                          color: KidColors.textMuted.withOpacity(0.8),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 48),

                  // Development Skip Button
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: KidColors.textMuted,
                    ),
                    onPressed: () {
                      provider.skipPairingForDev();
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (context) => const KidHomeScreen()),
                      );
                    },
                    icon: const Icon(Icons.developer_mode, size: 16),
                    label: const Text('Developer / Skip Pairing for Now'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
