import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../models/video_item.dart';
import '../utils/constants.dart';

/// Right-side collapsible drawer containing upcoming videos and recommendation shuffle.
class PlayerSuggestionDrawer extends StatelessWidget {
  final bool isOpen;
  final VoidCallback onClose;
  final List<VideoItem> videos;
  final int currentIndex;
  final ValueChanged<int> onSelectVideo;
  final VoidCallback onShuffle;

  const PlayerSuggestionDrawer({
    super.key,
    required this.isOpen,
    required this.onClose,
    required this.videos,
    required this.currentIndex,
    required this.onSelectVideo,
    required this.onShuffle,
  });

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final drawerWidth = (mediaQuery.size.width * 0.78).clamp(260.0, 340.0);

    return IgnorePointer(
      ignoring: !isOpen,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 240),
        opacity: isOpen ? 1.0 : 0.0,
        child: Stack(
          children: [
            // Dark dismiss barrier
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onClose,
              child: Container(
                color: Colors.black.withValues(alpha: 0.55),
              ),
            ),

            // Right drawer panel
            AnimatedPositioned(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              right: isOpen ? 0 : -drawerWidth,
              top: 0,
              bottom: 0,
              width: drawerWidth,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xF5111726),
                  border: const Border(
                    left: BorderSide(color: KidColors.borderDark, width: 1.2),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.6),
                      blurRadius: 24,
                      offset: const Offset(-8, 0),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Column(
                    children: [
                      // Header
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Row(
                          children: [
                            const Icon(Icons.playlist_play_rounded, color: KidColors.primary, size: 24),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Up Next',
                                style: TextStyle(
                                  fontFamily: 'Roboto',
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            // Shuffle Button
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(Icons.shuffle_rounded, color: KidColors.primary, size: 20),
                              tooltip: 'Shuffle Upcoming',
                              onPressed: onShuffle,
                            ),
                            // Close Button
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 22),
                              tooltip: 'Close',
                              onPressed: onClose,
                            ),
                          ],
                        ),
                      ),
                      const Divider(color: KidColors.borderDark, height: 1),

                      // Upcoming List
                      Expanded(
                        child: videos.isEmpty
                            ? const Center(
                                child: Text(
                                  'No more videos',
                                  style: TextStyle(
                                    fontFamily: 'Roboto',
                                    color: KidColors.textMuted,
                                    fontSize: 13,
                                  ),
                                ),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                itemCount: videos.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 8),
                                itemBuilder: (context, index) {
                                  final item = videos[index];
                                  final isCurrent = index == currentIndex;

                                  return _buildDrawerVideoCard(item, index, isCurrent);
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerVideoCard(VideoItem item, int index, bool isCurrent) {
    final title = item.title.contains('•') ? item.title.split('•').last.trim() : item.title;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          onClose();
          onSelectVideo(index);
        },
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isCurrent ? KidColors.primary.withValues(alpha: 0.15) : KidColors.surfaceDark,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isCurrent ? KidColors.primary.withValues(alpha: 0.7) : KidColors.borderDark,
              width: isCurrent ? 1.4 : 0.8,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 16:9 Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  width: 90,
                  height: 54,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: item.thumbnailUrl,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(color: Colors.black38),
                      ),
                      if (item.durationFormatted.isNotEmpty)
                        Positioned(
                          bottom: 3,
                          right: 3,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.75),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              item.durationFormatted,
                              style: const TextStyle(
                                fontFamily: 'Roboto',
                                color: Colors.white,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Title and details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        color: isCurrent ? KidColors.primary : Colors.white,
                        fontSize: 12,
                        fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (isCurrent)
                      const Text(
                        'Now Playing',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          color: KidColors.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
