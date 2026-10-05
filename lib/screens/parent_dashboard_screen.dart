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
  final TextEditingController _pinController = TextEditingController();

  String _selectedCategory = 'cartoons';
  String _selectedQuality = '720p';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<AppProvider>(context, listen: false);
    _vpsController.text = provider.vpsUrl;
    _pinController.text = provider.parentPin;
    if (provider.categories.isNotEmpty) {
      _selectedCategory = provider.categories.first.id;
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    _vpsController.dispose();
    _pinController.dispose();
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

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        final cachedMb = (provider.cachedBytes / (1024 * 1024)).toStringAsFixed(1);

        return Scaffold(
          backgroundColor: KidColors.bgDark,
          appBar: AppBar(
            title: const Text('Parent Dashboard'),
            backgroundColor: KidColors.cardDark,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Ingest Link Section
                _buildCard(
                  title: 'Add Video by Link',
                  icon: Icons.add_link_rounded,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Paste a link from YouTube, Vimeo, TikTok, or direct MP4. The server will download and transcode it in moderate quality.',
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
                              value: provider.categories.any((c) => c.id == _selectedCategory)
                                  ? _selectedCategory
                                  : (provider.categories.isNotEmpty ? provider.categories.first.id : 'cartoons'),
                              dropdownColor: KidColors.cardDark,
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                              decoration: InputDecoration(
                                labelText: 'Category',
                                labelStyle: const TextStyle(color: KidColors.textMuted),
                                filled: true,
                                fillColor: KidColors.bgDark,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: KidColors.borderDark),
                                ),
                              ),
                              items: provider.categories.map((c) {
                                return DropdownMenuItem(value: c.id, child: Text(c.name));
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedCategory = val);
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedQuality,
                              dropdownColor: KidColors.cardDark,
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                              decoration: InputDecoration(
                                labelText: 'Quality',
                                labelStyle: const TextStyle(color: KidColors.textMuted),
                                filled: true,
                                fillColor: KidColors.bgDark,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: KidColors.borderDark),
                                ),
                              ),
                              items: const [
                                DropdownMenuItem(value: '720p', child: Text('720p (Good)')),
                                DropdownMenuItem(value: '480p', child: Text('480p (Compact)')),
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

                // 2. VPS Server Settings
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

                // 3. Storage & Offline Manager
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
