import 'dart:async';
import 'dart:math';
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
  bool _isExpired = false;
  bool _isTimedOut = false;
  int _pollIntervalMs = 2500;
  int _totalElapsedSeconds = 0;

  @override
  void initState() {
    super.initState();
    _initPairing();
  }

  Future<void> _initPairing() async {
    _pollTimer?.cancel();
    final provider = Provider.of<AppProvider>(context, listen: false);
    setState(() {
      _isRequesting = true;
      _isExpired = false;
      _isTimedOut = false;
      _pollIntervalMs = 2500;
      _totalElapsedSeconds = 0;
    });

    final code = await provider.requestDevicePairing(name: 'Kids Tablet');
    if (!mounted) return;

    setState(() => _isRequesting = false);

    if (code != null) {
      _scheduleNextPoll();
    } else {
      setState(() => _isExpired = true);
    }
  }

  void _scheduleNextPoll() {
    _pollTimer?.cancel();
    if (!mounted || _isExpired || _isTimedOut) return;

    _pollTimer = Timer(Duration(milliseconds: _pollIntervalMs), () async {
      if (!mounted) return;
      _totalElapsedSeconds += (_pollIntervalMs / 1000).ceil();

      // Cap polling at 5 minutes (300 seconds)
      if (_totalElapsedSeconds >= 300) {
        setState(() => _isTimedOut = true);
        return;
      }

      final provider = Provider.of<AppProvider>(context, listen: false);
      final status = await provider.checkPairingStatus();
      if (!mounted) return;

      if (status == 'paired') {
        _pollTimer?.cancel();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const KidHomeScreen()),
        );
        return;
      } else if (status == 'expired') {
        setState(() => _isExpired = true);
        return;
      }

      // Exponential backoff capped at 10 seconds
      _pollIntervalMs = min(10000, (_pollIntervalMs * 1.25).round());
      _scheduleNextPoll();
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
                          color: KidColors.primary.withValues(alpha: 0.3),
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
                      border: Border.all(
                        color: (_isExpired || _isTimedOut) ? KidColors.red : KidColors.primary,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: ((_isExpired || _isTimedOut) ? KidColors.red : KidColors.primary).withValues(alpha: 0.15),
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
                            (_isExpired || _isTimedOut) ? 'EXPIRED' : code,
                            style: TextStyle(
                              color: (_isExpired || _isTimedOut) ? KidColors.red : KidColors.textLight,
                              fontSize: (_isExpired || _isTimedOut) ? 28 : 36,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'monospace',
                              letterSpacing: (_isExpired || _isTimedOut) ? 2 : 4,
                            ),
                          ),
                  ),

                  const SizedBox(height: 24),

                  // Status / Polling Indicator or Expired State
                  if (_isExpired || _isTimedOut) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: KidColors.red.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: KidColors.red.withValues(alpha: 0.4)),
                      ),
                      child: Column(
                        children: [
                          Text(
                            _isTimedOut
                                ? 'Pairing session timed out (5 minutes).'
                                : 'Pairing code expired or invalid.',
                            style: const TextStyle(color: KidColors.red, fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: KidColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                            ),
                            onPressed: _initPairing,
                            icon: const Icon(Icons.refresh_rounded, size: 18),
                            label: const Text('Generate New Code'),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
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
                            color: KidColors.textMuted.withValues(alpha: 0.8),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
