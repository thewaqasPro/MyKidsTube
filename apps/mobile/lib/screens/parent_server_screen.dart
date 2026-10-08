import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/constants.dart';
import 'parent_security_screen.dart';

class ParentServerScreen extends StatefulWidget {
  const ParentServerScreen({super.key});

  @override
  State<ParentServerScreen> createState() => _ParentServerScreenState();
}

class _ParentServerScreenState extends State<ParentServerScreen> {
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _deviceNameController = TextEditingController();

  bool _isTesting = false;
  int? _latencyMs;
  String? _testStatusMessage;
  bool _isPairing = false;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<AppProvider>(context, listen: false);
    _urlController.text = provider.vpsUrl;
    _deviceNameController.text = provider.deviceName;
    _testPing();
  }

  @override
  void dispose() {
    _urlController.dispose();
    _deviceNameController.dispose();
    super.dispose();
  }

  Future<void> _testPing() async {
    setState(() {
      _isTesting = true;
      _testStatusMessage = null;
    });

    final provider = Provider.of<AppProvider>(context, listen: false);
    final latency = await provider.pingVpsServer();

    if (mounted) {
      setState(() {
        _isTesting = false;
        _latencyMs = latency;
        _testStatusMessage = latency != null
            ? 'Server reachable! Ping: ${latency}ms'
            : 'Server unreachable or offline.';
      });
    }
  }

  Future<void> _saveUrl() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;

    final provider = Provider.of<AppProvider>(context, listen: false);
    await provider.setVpsUrl(url);
    await _testPing();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('VPS URL updated and catalog synced!'),
          backgroundColor: KidColors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _requestPairing() async {
    setState(() => _isPairing = true);
    final provider = Provider.of<AppProvider>(context, listen: false);
    final name = _deviceNameController.text.trim().isNotEmpty
        ? _deviceNameController.text.trim()
        : 'Kids Tablet';
    final code = await provider.requestDevicePairing(name: name);
    setState(() => _isPairing = false);

    if (mounted) {
      if (code != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pairing code generated: $code'),
            backgroundColor: KidColors.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to generate code. Ensure server is online.'),
            backgroundColor: KidColors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _checkPairing() async {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final status = await provider.checkPairingStatus();
    if (mounted) {
      if (status == 'paired') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Device paired successfully!'),
            backgroundColor: KidColors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        final isDefault = await provider.isUsingDefaultPin();
        if (isDefault && mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const ParentSecurityScreen(isForceChange: true),
            ),
          );
        }
      } else if (status == 'pending') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Waiting for approval in Web Studio...'),
            backgroundColor: KidColors.yellow,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pairing code expired. Please request a new one.'),
            backgroundColor: KidColors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        final isOnline = provider.isServerOnline;

        return Scaffold(
          backgroundColor: KidColors.bgDark,
          appBar: AppBar(
            title: const Text(
              'VPS Server Connection',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
            ),
            backgroundColor: KidColors.bgDark,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Server Health Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: KidColors.cardDark,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isOnline
                          ? KidColors.green.withValues(alpha: 0.4)
                          : KidColors.red.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: (isOnline ? KidColors.green : KidColors.red).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isOnline ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                          color: isOnline ? KidColors.green : KidColors.red,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  isOnline ? 'Server Online' : 'Server Offline / Unreachable',
                                  style: TextStyle(
                                    color: isOnline ? KidColors.green : KidColors.red,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                                if (_latencyMs != null) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: KidColors.bgDark,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: KidColors.borderDark),
                                    ),
                                    child: Text(
                                      '${_latencyMs}ms',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _testStatusMessage ?? (isOnline ? 'Edge API is connected & ready' : 'Check URL or internet connection'),
                              style: const TextStyle(color: KidColors.textMuted, fontSize: 12.5),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Ping Now',
                        onPressed: _isTesting ? null : _testPing,
                        icon: _isTesting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.refresh_rounded, color: Colors.white70),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Server Configuration Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: KidColors.cardDark,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: KidColors.borderDark),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.dns_rounded, color: KidColors.primary, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Server Endpoint URL',
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Base URL of your Cloudflare Worker or custom VPS media server.',
                        style: TextStyle(color: KidColors.textMuted, fontSize: 13),
                      ),
                      const SizedBox(height: 18),
                      TextField(
                        controller: _urlController,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          labelText: 'Server Base URL',
                          labelStyle: const TextStyle(color: KidColors.textMuted),
                          hintText: 'https://mykidstube.kidstube.workers.dev',
                          hintStyle: const TextStyle(color: Colors.white24),
                          filled: true,
                          fillColor: KidColors.bgDark,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: KidColors.borderDark),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: KidColors.borderDark),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: KidColors.primary),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Single-row button layout for Save & Test
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: KidColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: _saveUrl,
                              icon: const Icon(Icons.save_rounded, size: 18),
                              label: const Text('Save & Test', style: TextStyle(fontWeight: FontWeight.w700)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: KidColors.borderDark),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: provider.isSyncing ? null : () => provider.syncCatalog(),
                              icon: provider.isSyncing
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Icon(Icons.sync_rounded, color: Colors.white70, size: 18),
                              label: Text(
                                provider.isSyncing ? 'Syncing...' : 'Sync Catalog',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Device Pairing Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: KidColors.cardDark,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: KidColors.borderDark),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.devices_other_rounded, color: KidColors.accent, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Device Pairing',
                                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: (provider.isDevicePaired ? KidColors.green : KidColors.yellow).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: (provider.isDevicePaired ? KidColors.green : KidColors.yellow).withValues(alpha: 0.4),
                              ),
                            ),
                            child: Text(
                              provider.isDevicePaired ? 'PAIRED' : 'UNPAIRED',
                              style: TextStyle(
                                color: provider.isDevicePaired ? KidColors.green : KidColors.yellow,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Pair this mobile app with your Web Studio to enforce child profiles and parental remote controls.',
                        style: TextStyle(color: KidColors.textMuted, fontSize: 13),
                      ),
                      const SizedBox(height: 16),

                      if (provider.pairingCode != null && !provider.isDevicePaired) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                          decoration: BoxDecoration(
                            color: KidColors.bgDark,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: KidColors.primary.withValues(alpha: 0.5)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('PAIRING CODE: ', style: TextStyle(color: KidColors.textMuted, fontSize: 13)),
                              Text(
                                provider.pairingCode!,
                                style: const TextStyle(
                                  color: KidColors.primary,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Single-row button layout for Pairing
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: KidColors.accent),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: _isPairing ? null : _requestPairing,
                              icon: _isPairing
                                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                  : const Icon(Icons.qr_code_rounded, color: KidColors.accent, size: 18),
                              label: Text(
                                provider.pairingCode == null ? 'Get Pairing Code' : 'New Code',
                                style: const TextStyle(color: KidColors.accent, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                          if (provider.pairingCode != null && !provider.isDevicePaired) ...[
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: KidColors.green,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: _checkPairing,
                                icon: const Icon(Icons.check_rounded, size: 18),
                                label: const Text('Check Status', style: TextStyle(fontWeight: FontWeight.w700)),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
