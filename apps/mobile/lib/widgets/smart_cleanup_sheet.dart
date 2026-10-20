import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/video_item.dart';
import '../providers/app_provider.dart';
import '../utils/constants.dart';

/// Modal bottom sheet allowing parents to review and clean up
/// low-engagement, stale, or frequently skipped videos from the catalog.
class SmartCleanupSheet extends StatefulWidget {
  const SmartCleanupSheet({super.key});

  @override
  State<SmartCleanupSheet> createState() => _SmartCleanupSheetState();
}

class _SmartCleanupSheetState extends State<SmartCleanupSheet> {
  final Set<String> _selectedIds = {};
  bool _initialized = false;
  List<VideoItem> _suggestions = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final provider = Provider.of<AppProvider>(context, listen: false);
      _suggestions = provider.getPruningSuggestions(limit: 30);
      _selectedIds.addAll(_suggestions.map((v) => v.id));
      _initialized = true;
    }
  }

  void _toggleSelectAll() {
    setState(() {
      if (_selectedIds.length == _suggestions.length) {
        _selectedIds.clear();
      } else {
        _selectedIds.clear();
        _selectedIds.addAll(_suggestions.map((v) => v.id));
      }
    });
  }

  Future<void> _executeCleanup(BuildContext context) async {
    if (_selectedIds.isEmpty) return;

    final provider = Provider.of<AppProvider>(context, listen: false);
    final count = _selectedIds.length;

    await provider.pruneStaleVideos(_selectedIds.toList());

    if (context.mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 20),
              const SizedBox(width: 8),
              Text('Cleaned up $count stale videos from library.'),
            ],
          ),
          backgroundColor: const Color(0xFF1E1E1E),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final metrics = provider.watchMetrics;

    return Material(
      color: KidColors.cardDark,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: Container(
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(color: KidColors.borderDark, width: 1.0),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.auto_delete_rounded, color: Colors.amber, size: 20),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Smart Catalog Cleanup',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white54, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'These videos were frequently skipped or never watched. Clean them up to make room for fresh content.',
                  style: TextStyle(color: Colors.white60, fontSize: 13, height: 1.3),
                ),
                const SizedBox(height: 16),

                if (_suggestions.isEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Column(
                        children: [
                          const Icon(Icons.verified_rounded, size: 48, color: KidColors.mint),
                          const SizedBox(height: 12),
                          const Text(
                            'Your catalog is in great shape!',
                            style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'No cleanup needed. All videos are active or favorited.',
                            style: TextStyle(color: Colors.white54, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  // Selection count & toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_selectedIds.length} of ${_suggestions.length} selected for removal',
                        style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                      TextButton(
                        onPressed: _toggleSelectAll,
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          foregroundColor: KidColors.primary,
                        ),
                        child: Text(
                          _selectedIds.length == _suggestions.length ? 'Deselect All' : 'Select All',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Video list
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: _suggestions.length,
                      separatorBuilder: (_, __) => const Divider(color: KidColors.borderDark, height: 1),
                      itemBuilder: (context, idx) {
                        final video = _suggestions[idx];
                        final isSelected = _selectedIds.contains(video.id);
                        final metric = metrics[video.id];

                        String reasonText = 'Unwatched';
                        if (metric != null && metric.skippedCount > 0) {
                          reasonText = 'Skipped ${metric.skippedCount}x (watched ${metric.totalSeconds}s)';
                        }

                        return CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          value: isSelected,
                          activeColor: KidColors.red,
                          checkColor: Colors.white,
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                _selectedIds.add(video.id);
                              } else {
                                _selectedIds.remove(video.id);
                              }
                            });
                          },
                          title: Text(
                            video.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                          subtitle: Row(
                            children: [
                              Text(
                                video.channelName ?? 'YouTube',
                                style: const TextStyle(color: Colors.white54, fontSize: 12),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  reasonText,
                                  style: const TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                          secondary: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              width: 60,
                              height: 38,
                              color: Colors.black26,
                              child: (video.thumbnailUrl.startsWith('http://') || video.thumbnailUrl.startsWith('https://'))
                                  ? CachedNetworkImage(
                                      imageUrl: video.thumbnailUrl,
                                      fit: BoxFit.cover,
                                      errorWidget: (_, __, ___) => const Icon(Icons.broken_image, size: 16, color: Colors.white24),
                                    )
                                  : const Icon(Icons.movie_outlined, size: 20, color: Colors.white38),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white70,
                            side: const BorderSide(color: KidColors.borderDark),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: _selectedIds.isEmpty ? null : () => _executeCleanup(context),
                          icon: const Icon(Icons.delete_sweep_rounded, size: 18),
                          label: Text('Clean Up Selected (${_selectedIds.length})'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: KidColors.red,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.white12,
                            disabledForegroundColor: Colors.white30,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
