import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/video_item.dart';
import '../providers/app_provider.dart';
import '../utils/constants.dart';
import 'kid_player_screen.dart';

class ParentStorageScreen extends StatefulWidget {
  const ParentStorageScreen({super.key});

  @override
  State<ParentStorageScreen> createState() => _ParentStorageScreenState();
}

class _ParentStorageScreenState extends State<ParentStorageScreen> {
  bool _isDownloadingAll = false;
  bool _isClearing = false;

  Future<void> _handleDownloadAll(AppProvider provider) async {
    final toDownload = provider.allVideos.where((v) => !v.isOfflineReady).toList();
    if (toDownload.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All videos are already downloaded for offline play!'),
          backgroundColor: KidColors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isDownloadingAll = true);
    for (final v in toDownload) {
      await provider.startDownload(v);
    }
    if (mounted) {
      setState(() => _isDownloadingAll = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Completed offline download of ${toDownload.length} videos!'),
          backgroundColor: KidColors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleClearStorage(AppProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: KidColors.cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: KidColors.borderDark),
        ),
        title: const Row(
          children: [
            Icon(Icons.delete_sweep_rounded, color: KidColors.red, size: 24),
            SizedBox(width: 10),
            Text('Clear Offline Storage?', style: TextStyle(color: Colors.white, fontSize: 18)),
          ],
        ),
        content: const Text(
          'This will remove all downloaded video files from device disk to free up storage space. Catalog entries will remain intact.',
          style: TextStyle(color: KidColors.textMuted, fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: KidColors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Clear Storage'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isClearing = true);
      await provider.clearAllDownloadedVideos();
      if (mounted) {
        setState(() => _isClearing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Offline storage cleared!'),
            backgroundColor: KidColors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _handleResetCache(AppProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: KidColors.cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: KidColors.borderDark),
        ),
        title: const Row(
          children: [
            Icon(Icons.refresh_rounded, color: KidColors.yellow, size: 24),
            SizedBox(width: 10),
            Text('Reset Cache & Catalog?', style: TextStyle(color: Colors.white, fontSize: 18)),
          ],
        ),
        content: const Text(
          'This wipes metadata caches and performs a fresh resync from your server.',
          style: TextStyle(color: KidColors.textMuted, fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: KidColors.yellow,
              foregroundColor: Colors.black,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Fresh Reload', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await provider.clearMobileCache();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cache reset & fresh catalog synced!'),
            backgroundColor: KidColors.green,
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
        final downloaded = provider.downloadedVideos;
        final totalVideos = provider.allVideos.length;
        final cachedMb = (provider.cachedBytes / (1024 * 1024)).toStringAsFixed(1);
        final offlineRatio = totalVideos > 0 ? (downloaded.length / totalVideos) : 0.0;

        return Scaffold(
          backgroundColor: KidColors.bgDark,
          appBar: AppBar(
            title: const Text(
              'Device Storage & Media',
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
                // 1. Storage Stats Card
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
                              Icon(Icons.storage_rounded, color: KidColors.primary, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Local Disk Usage',
                                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: KidColors.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: KidColors.primary.withValues(alpha: 0.4)),
                            ),
                            child: Text(
                              '$cachedMb MB',
                              style: const TextStyle(
                                color: KidColors.primary,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Storage Metric Chips
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricMiniCard(
                              label: 'Downloaded',
                              value: '${downloaded.length} videos',
                              icon: Icons.check_circle_outline,
                              color: KidColors.green,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildMetricMiniCard(
                              label: 'Catalog Total',
                              value: '$totalVideos videos',
                              icon: Icons.video_library_outlined,
                              color: KidColors.accent,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildMetricMiniCard(
                              label: 'Offline Ready',
                              value: '${(offlineRatio * 100).toInt()}%',
                              icon: Icons.offline_bolt_outlined,
                              color: KidColors.yellow,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Linear Progress Bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: offlineRatio.clamp(0.0, 1.0),
                          minHeight: 8,
                          backgroundColor: KidColors.bgDark,
                          valueColor: const AlwaysStoppedAnimation<Color>(KidColors.primary),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // 2. Optimized Single-Row Button Toolbar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  decoration: BoxDecoration(
                    color: KidColors.cardDark,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: KidColors.borderDark),
                  ),
                  child: Row(
                    children: [
                      // Button 1: Download All
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: KidColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                          onPressed: _isDownloadingAll ? null : () => _handleDownloadAll(provider),
                          icon: _isDownloadingAll
                              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.download_rounded, size: 16),
                          label: Text(
                            _isDownloadingAll ? 'Saving...' : 'Download All',
                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Button 2: Clear Storage
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: KidColors.red),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: _isClearing ? null : () => _handleClearStorage(provider),
                          icon: const Icon(Icons.delete_outline_rounded, color: KidColors.red, size: 16),
                          label: const Text(
                            'Clear Files',
                            style: TextStyle(color: KidColors.red, fontSize: 12.5, fontWeight: FontWeight.w700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Button 3: Resync & Clean Cache
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: KidColors.borderDark),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () => _handleResetCache(provider),
                          icon: const Icon(Icons.cleaning_services_rounded, color: KidColors.yellow, size: 16),
                          label: const Text(
                            'Fresh Sync',
                            style: TextStyle(color: Colors.white70, fontSize: 12.5, fontWeight: FontWeight.w700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 3. Downloaded Videos List
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Offline Video Files',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      '${downloaded.length} items',
                      style: const TextStyle(color: KidColors.textMuted, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                if (downloaded.isEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                    decoration: BoxDecoration(
                      color: KidColors.cardDark,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: KidColors.borderDark),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.cloud_download_outlined, color: KidColors.textMuted, size: 48),
                        SizedBox(height: 12),
                        Text(
                          'No videos downloaded yet',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Tap "Download All" above or download individual videos in the Media Library to enable offline viewing.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: KidColors.textMuted, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: downloaded.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = downloaded[index];
                      return _buildDownloadedVideoTile(context, item, provider);
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetricMiniCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: KidColors.bgDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: KidColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(color: KidColors.textMuted, fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadedVideoTile(BuildContext context, VideoItem video, AppProvider provider) {
    String fileSizeStr = 'Local MP4';
    if (video.localFilePath != null) {
      try {
        final f = File(video.localFilePath!);
        if (f.existsSync()) {
          final bytes = f.lengthSync();
          fileSizeStr = '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
        }
      } catch (_) {}
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: KidColors.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: KidColors.borderDark),
      ),
      child: Row(
        children: [
          // Thumbnail Preview
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 70,
              height: 48,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    video.thumbnailUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(color: KidColors.bgDark),
                  ),
                  const Center(
                    child: Icon(Icons.play_circle_fill, color: Colors.white70, size: 24),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Title & Metadata
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  video.title,
                  style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: KidColors.green.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        fileSizeStr,
                        style: const TextStyle(color: KidColors.green, fontSize: 10.5, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      video.durationFormatted,
                      style: const TextStyle(color: KidColors.textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Action Buttons: Play & Delete
          IconButton(
            tooltip: 'Play Offline',
            icon: const Icon(Icons.play_arrow_rounded, color: Colors.white70),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => KidPlayerScreen(
                    video: video,
                    playlist: provider.downloadedVideos,
                  ),
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Remove from Disk',
            icon: const Icon(Icons.delete_outline_rounded, color: KidColors.red),
            onPressed: () async {
              await provider.deleteDownloaded(video);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Removed file from offline storage.'),
                    backgroundColor: KidColors.green,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
