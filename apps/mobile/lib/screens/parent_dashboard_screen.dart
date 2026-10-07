import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/constants.dart';

class ParentDashboardScreen extends StatefulWidget {
  const ParentDashboardScreen({super.key});

  @override
  State<ParentDashboardScreen> createState() => _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends State<ParentDashboardScreen> {
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _vpsController = TextEditingController();
  final TextEditingController _currentPinController = TextEditingController();
  final TextEditingController _newPinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();

  String _selectedCategory = 'cartoons';
  String _selectedQuality = '720p';
  bool _isSubmitting = false;
  bool _isChangingPin = false;
  bool _isUsingDefaultPin = false;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<AppProvider>(context, listen: false);
    _vpsController.text = provider.vpsUrl;
    if (provider.categories.isNotEmpty) {
      _selectedCategory = provider.categories.first.id;
    }
    provider.isUsingDefaultPin().then((val) {
      if (mounted) setState(() => _isUsingDefaultPin = val);
    });
  }

  @override
  void dispose() {
    _urlController.dispose();
    _vpsController.dispose();
    _currentPinController.dispose();
    _newPinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  Future<void> _submitUrl() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;

    setState(() => _isSubmitting = true);
    final provider = Provider.of<AppProvider>(context, listen: false);

    final success = await provider.submitUrlForIngestion(
      url,
      _selectedCategory,
      quality: _selectedQuality,
    );

    setState(() => _isSubmitting = false);

    if (mounted) {
      if (success) {
        _urlController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Video submitted! VPS is downloading & transcoding.'),
            backgroundColor: KidColors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to submit. Check VPS connection.'),
            backgroundColor: KidColors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleChangePin() async {
    final current = _currentPinController.text.trim();
    final newPin = _newPinController.text.trim();
    final confirm = _confirmPinController.text.trim();

    if (current.isEmpty || newPin.isEmpty || confirm.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter current PIN, new PIN, and confirmation.'),
          backgroundColor: KidColors.red,
        ),
      );
      return;
    }

    if (newPin.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('New PIN must be at least 4 digits.'),
          backgroundColor: KidColors.red,
        ),
      );
      return;
    }

    if (newPin != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('New PIN and confirmation do not match.'),
          backgroundColor: KidColors.red,
        ),
      );
      return;
    }

    setState(() => _isChangingPin = true);
    final provider = Provider.of<AppProvider>(context, listen: false);
    final success = await provider.changeParentPin(currentPin: current, newPin: newPin);
    setState(() => _isChangingPin = false);

    if (mounted) {
      if (success) {
        _currentPinController.clear();
        _newPinController.clear();
        _confirmPinController.clear();
        setState(() => _isUsingDefaultPin = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Parent PIN successfully updated!'),
            backgroundColor: KidColors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Incorrect current PIN. Please try again.'),
            backgroundColor: KidColors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        final cachedMb = (provider.cachedBytes / (1024 * 1024)).toStringAsFixed(1);

        return Scaffold(
          backgroundColor: KidColors.bgDark,
          appBar: AppBar(
            title: const Text('Parent Dashboard'),
            backgroundColor: KidColors.bgDark,
            elevation: 0,
            scrolledUnderElevation: 0,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Security Alert Banner if using default PIN
                if (_isUsingDefaultPin) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: KidColors.yellow.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: KidColors.yellow.withValues(alpha: 0.5)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: KidColors.yellow, size: 24),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Security Notice: Default PIN (1234) is in use. Please set a custom PIN below.',
                            style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // 1. Ingest Link Section
                _buildCard(
                  title: 'Add Video by Link',
                  icon: Icons.add_link_rounded,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Paste a link from YouTube. The server will queue and download it.',
                        style: TextStyle(color: KidColors.textMuted, fontSize: 13),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _urlController,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'https://youtube.com/watch?v=...',
                          hintStyle: const TextStyle(color: KidColors.textMuted),
                          filled: true,
                          fillColor: KidColors.bgDark,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: KidColors.borderDark),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              isExpanded: true,
                              initialValue: provider.categories.any((c) => c.id == _selectedCategory)
                                   ? _selectedCategory
                                  : (provider.categories.isNotEmpty ? provider.categories.first.id : 'cartoons'),
                              dropdownColor: KidColors.cardDark,
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                              decoration: InputDecoration(
                                labelText: 'Category',
                                labelStyle: const TextStyle(color: KidColors.textMuted),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                filled: true,
                                fillColor: KidColors.bgDark,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: KidColors.borderDark),
                                ),
                              ),
                              items: provider.categories.map((c) {
                                return DropdownMenuItem(value: c.id, child: Text(c.name, overflow: TextOverflow.ellipsis));
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedCategory = val);
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              isExpanded: true,
                              initialValue: _selectedQuality,
                              dropdownColor: KidColors.cardDark,
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                              decoration: InputDecoration(
                                labelText: 'Quality',
                                labelStyle: const TextStyle(color: KidColors.textMuted),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                filled: true,
                                fillColor: KidColors.bgDark,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: KidColors.borderDark),
                                ),
                              ),
                              items: const [
                                DropdownMenuItem(value: '720p', child: Text('720p', overflow: TextOverflow.ellipsis)),
                                DropdownMenuItem(value: '480p', child: Text('480p', overflow: TextOverflow.ellipsis)),
                              ],
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedQuality = val);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: KidColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: _isSubmitting ? null : _submitUrl,
                          icon: _isSubmitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.cloud_download_rounded, color: Colors.white),
                          label: Text(
                            _isSubmitting ? 'Sending to VPS...' : 'Download to Media Server',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 2. Change Parent PIN Section
                _buildCard(
                  title: 'Parent PIN Security',
                  icon: Icons.pin_rounded,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Set a 4+ digit numeric PIN to protect grown-up controls and settings.',
                        style: TextStyle(color: KidColors.textMuted, fontSize: 13),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _currentPinController,
                        obscureText: true,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          labelText: 'Current PIN',
                          labelStyle: const TextStyle(color: KidColors.textMuted),
                          filled: true,
                          fillColor: KidColors.bgDark,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: KidColors.borderDark),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _newPinController,
                              obscureText: true,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                              decoration: InputDecoration(
                                labelText: 'New PIN (min 4 digits)',
                                labelStyle: const TextStyle(color: KidColors.textMuted),
                                filled: true,
                                fillColor: KidColors.bgDark,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: KidColors.borderDark),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _confirmPinController,
                              obscureText: true,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                              decoration: InputDecoration(
                                labelText: 'Confirm New PIN',
                                labelStyle: const TextStyle(color: KidColors.textMuted),
                                filled: true,
                                fillColor: KidColors.bgDark,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: KidColors.borderDark),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: KidColors.primary),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: _isChangingPin ? null : _handleChangePin,
                          icon: _isChangingPin
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.check_rounded, color: KidColors.primary),
                          label: Text(
                            _isChangingPin ? 'Updating PIN...' : 'Change Parent PIN',
                            style: const TextStyle(color: KidColors.primary, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 3. VPS Server Settings
                _buildCard(
                  title: 'VPS Server Connection',
                  icon: Icons.dns_rounded,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            provider.isServerOnline ? Icons.check_circle : Icons.error_outline,
                            color: provider.isServerOnline ? KidColors.green : KidColors.red,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            provider.isServerOnline ? 'Connected to VPS' : 'Disconnected / Unreachable',
                            style: TextStyle(
                              color: provider.isServerOnline ? KidColors.green : KidColors.red,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _vpsController,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          labelText: 'Server Base URL',
                          labelStyle: const TextStyle(color: KidColors.textMuted),
                          filled: true,
                          fillColor: KidColors.bgDark,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: KidColors.borderDark),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: KidColors.borderDark),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: () {
                                provider.setVpsUrl(_vpsController.text.trim());
                              },
                              child: const Text('Save & Test', style: TextStyle(color: KidColors.primary)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: KidColors.surfaceDark,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: provider.isSyncing ? null : () => provider.syncCatalog(),
                              icon: provider.isSyncing
                                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                                  : const Icon(Icons.sync, size: 16),
                              label: const Text('Sync Catalog'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 4. Storage & Offline Manager
                _buildCard(
                  title: 'Device Storage & Offline Media',
                  icon: Icons.storage_rounded,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Offline Storage Used:', style: TextStyle(color: KidColors.textMuted, fontSize: 13)),
                          Text(
                            '$cachedMb MB (${provider.downloadedVideos.length} videos)',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: KidColors.accent,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: () async {
                                for (final v in provider.allVideos) {
                                  if (!v.isOfflineReady) {
                                    provider.startDownload(v);
                                  }
                                }
                              },
                              icon: const Icon(Icons.download_for_offline, size: 18),
                              label: const Text('Download All'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: KidColors.red),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: () => provider.clearAllDownloadedVideos(),
                              icon: const Icon(Icons.delete_outline, color: KidColors.red, size: 18),
                              label: const Text('Clear Storage', style: TextStyle(color: KidColors.red)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: KidColors.borderDark),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Clearing cache and re-syncing fresh catalog...'),
                                backgroundColor: KidColors.primary,
                              ),
                            );
                            provider.clearMobileCache();
                          },
                          icon: const Icon(Icons.cleaning_services_rounded, color: KidColors.yellow, size: 18),
                          label: const Text('Clear Mobile Cache & Fresh Reload', style: TextStyle(color: Colors.white)),
                        ),
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

  Widget _buildCard({required String title, required IconData icon, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: KidColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: KidColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: KidColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const Divider(height: 24, color: KidColors.borderDark),
          child,
        ],
      ),
    );
  }
}
