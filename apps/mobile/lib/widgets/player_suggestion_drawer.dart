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
    final isShortsList = videos.any((v) => v.isShort);
    final drawerWidth = isShortsList
        ? (mediaQuery.size.width * 0.45).clamp(165.0, 195.0)
        : (mediaQuery.size.width * 0.75).clamp(240.0, 320.0);

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
                color: Colors.black.withValues(alpha: 0.6),
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
                decoration: const BoxDecoration(
                  color: KidColors.cardDark,
                  border: Border(
                    left: BorderSide(color: KidColors.borderDark, width: 1.0),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black54,
                      blurRadius: 20,
                      offset: Offset(-6, 0),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Column(
                    children: [
                      // Header
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isShortsList ? 10 : 14,
                          vertical: isShortsList ? 10 : 12,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.playlist_play_rounded,
                              color: KidColors.primary,
                              size: isShortsList ? 20 : 24,
                            ),
                            SizedBox(width: isShortsList ? 6 : 8),
                            Expanded(
                              child: Text(
                                'Up Next',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'Roboto',
                                  color: Colors.white,
                                  fontSize: isShortsList ? 14 : 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            // Shuffle Button
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: isShortsList
                                  ? const BoxConstraints(minWidth: 30, minHeight: 30)
                                  : null,
                              icon: Icon(
                                Icons.shuffle_rounded,
                                color: KidColors.primary,
                                size: isShortsList ? 18 : 20,
                              ),
                              tooltip: 'Shuffle Upcoming',
                              onPressed: onShuffle,
                            ),
                            // Close Button
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: isShortsList
                                  ? const BoxConstraints(minWidth: 30, minHeight: 30)
                                  : null,
                              icon: Icon(
                                Icons.close_rounded,
                                color: Colors.white70,
                                size: isShortsList ? 20 : 22,
                              ),
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
                                padding: EdgeInsets.symmetric(
                                  horizontal: isShortsList ? 8 : 12,
                                  vertical: 10,
                                ),
                                itemCount: videos.length,
                                separatorBuilder: (_, __) => SizedBox(height: isShortsList ? 8 : 12),
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
    if (item.isShort) {
      // 1. YouTube Shorts: Compact, sleek vertical 9:14 card with rounded corners and badge
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 160,
            maxHeight: 200,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                onClose();
                onSelectVideo(index);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isCurrent ? KidColors.primary.withValues(alpha: 0.15) : KidColors.surfaceDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isCurrent ? KidColors.primary : KidColors.borderDark,
                    width: isCurrent ? 2.0 : 0.8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: AspectRatio(
                  aspectRatio: 9 / 14,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(
                          imageUrl: item.thumbnailUrl,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => Container(color: Colors.black38),
                        ),
                        // Small Short Badge at Top-Left
                        Positioned(
                          top: 6,
                          left: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: KidColors.durationBadgeBg,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.bolt_rounded, color: Colors.white, size: 11),
                                SizedBox(width: 2.5),
                                Text(
                                  'Short',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (isCurrent)
                          Positioned(
                            bottom: 6,
                            right: 6,
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: const BoxDecoration(
                                color: KidColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    // 2. Standard Videos: 16:9 Thumbnail with title moved to the BOTTOM
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
              color: isCurrent ? KidColors.primary : KidColors.borderDark,
              width: isCurrent ? 1.5 : 0.8,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 16:9 Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: item.thumbnailUrl,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(color: Colors.black38),
                      ),
                      if (item.durationFormatted.isNotEmpty && item.durationFormatted != '00:00')
                        Positioned(
                          bottom: 4,
                          right: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: KidColors.durationBadgeBg,
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

              const SizedBox(height: 6),

              // Title positioned at the BOTTOM of the card
              Row(
                children: [
                  Expanded(
                    child: Text(
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
                  ),
                  if (isCurrent) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.play_arrow_rounded, color: KidColors.primary, size: 18),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
