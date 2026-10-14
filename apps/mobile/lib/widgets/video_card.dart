import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/video_item.dart';
import '../utils/constants.dart';
import '../utils/format_utils.dart';

/// Authentic YouTube / YouTube Kids Video Card
class VideoCard extends StatelessWidget {
  final VideoItem video;
  final VoidCallback onTap;
  final VoidCallback? onDownloadTap;
  final double? downloadProgress;
  final bool isHorizontalCompact;

  const VideoCard({
    super.key,
    required this.video,
    required this.onTap,
    this.onDownloadTap,
    this.downloadProgress,
    this.isHorizontalCompact = false,
  });

  String get _channelName => FormatUtils.extractChannelName(video.channelName, video.title);

  String get _cleanTitle => FormatUtils.cleanVideoTitle(video.title);

  Color get _avatarColor {
    final colors = [
      const Color(0xFFE53935),
      const Color(0xFF1E88E5),
      const Color(0xFF43A047),
      const Color(0xFFFB8C00),
      const Color(0xFF8E24AA),
      const Color(0xFF00ACC1),
    ];
    final hash = _channelName.codeUnits.fold(0, (prev, c) => prev + c);
    return colors[hash % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    if (isHorizontalCompact) {
      return _buildCompactCard(context);
    }
    return _buildFullFeedCard(context);
  }

  /// Full-width feed card (YouTube standard mobile/tablet view)
  Widget _buildFullFeedCard(BuildContext context) {
    if (video.isShort) {
      return _buildFullFeedShortCard(context);
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. 16:9 Thumbnail with Duration Pill
          _buildThumbnail(context, borderRadius: 12),

          // 2. Clean Video Title
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 10, left: 2, right: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    _cleanTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      color: KidColors.textLight,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      height: 1.25,
                    ),
                  ),
                ),

              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Single-column feed view for a Short (Centered vertical 9:16 card)
  Widget _buildFullFeedShortCard(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Center(
        child: Container(
          width: 220,
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildThumbnail(context, borderRadius: 12, aspectRatio: 9 / 16),
              Padding(
                padding: const EdgeInsets.only(top: 6, bottom: 4, left: 2, right: 2),
                child: Text(
                  _cleanTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    color: KidColors.textLight,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.25,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Compact horizontal shelf card (for horizontal Shorts & Reels shelf)
  Widget _buildCompactCard(BuildContext context) {
    if (video.isShort) {
      return _buildCompactShortCard(context);
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 190,
        margin: const EdgeInsets.only(right: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 16:9 Thumbnail
            _buildThumbnail(context, borderRadius: 10, aspectRatio: 16 / 9),

            // Video Title
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 2, right: 2),
              child: Text(
                _cleanTitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  color: KidColors.textLight,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Compact vertical 9:16 card (Authentic YouTube Shorts & Reels shelf card)
  Widget _buildCompactShortCard(BuildContext context) {
    final hasLocalThumb = video.localThumbnailPath != null &&
        File(video.localThumbnailPath!).existsSync();

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 145,
        margin: const EdgeInsets.only(right: 12),
        child: AspectRatio(
          aspectRatio: 9 / 16,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // 1. Full 9:16 Thumbnail Background
                Container(
                  color: KidColors.surfaceDark,
                  child: hasLocalThumb
                      ? Image.file(File(video.localThumbnailPath!), fit: BoxFit.cover)
                      : (video.thumbnailUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: video.thumbnailUrl,
                              fit: BoxFit.cover,
                              fadeInDuration: const Duration(milliseconds: 200),
                              placeholder: (context, url) => Container(
                                color: KidColors.surfaceDark,
                                child: const Center(
                                  child: SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: KidColors.primary,
                                    ),
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, err) => _buildFallbackThumbnail(),
                            )
                          : _buildFallbackThumbnail()),
                ),

                // 2. Bottom Gradient Scrim for readable title overlay
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.4),
                          Colors.black.withValues(alpha: 0.9),
                        ],
                        stops: const [0.0, 0.45, 0.7, 1.0],
                      ),
                    ),
                  ),
                ),

                // 3. Shorts Badge Pill (Top-Left)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: KidColors.coral.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.bolt_rounded, color: Colors.white, size: 12),
                        SizedBox(width: 2),
                        Text(
                          'Shorts',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 4. Downloaded checkmark (Top-Right)
                if (video.downloadStatus == DownloadStatus.downloaded)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_circle_rounded, color: KidColors.green, size: 15),
                    ),
                  ),

                // 5. In-progress download bar
                if (downloadProgress != null && downloadProgress! > 0 && downloadProgress! < 1.0)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: LinearProgressIndicator(
                      value: downloadProgress,
                      minHeight: 3,
                      color: KidColors.primary,
                      backgroundColor: Colors.white24,
                    ),
                  ),

                // 6. Overlaid Title (Bottom)
                Positioned(
                  bottom: 10,
                  left: 10,
                  right: 10,
                  child: Text(
                    _cleanTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                      shadows: [
                        Shadow(color: Colors.black87, blurRadius: 4),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Core AspectRatio Thumbnail (16:9 for regular videos, 9:16 for Shorts)
  Widget _buildThumbnail(BuildContext context, {required double borderRadius, double? aspectRatio}) {
    final hasLocalThumb = video.localThumbnailPath != null &&
        File(video.localThumbnailPath!).existsSync();
    final double targetAspect = aspectRatio ?? (video.isShort ? (9 / 16) : (16 / 9));

    return AspectRatio(
      aspectRatio: targetAspect,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image
            Container(
              color: KidColors.surfaceDark,
              child: hasLocalThumb
                  ? Image.file(File(video.localThumbnailPath!), fit: BoxFit.cover)
                  : (video.thumbnailUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: video.thumbnailUrl,
                          fit: BoxFit.cover,
                          fadeInDuration: const Duration(milliseconds: 200),
                          placeholder: (context, url) => Container(
                            color: KidColors.surfaceDark,
                            child: const Center(
                              child: SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: KidColors.primary,
                                ),
                              ),
                            ),
                          ),
                          errorWidget: (context, url, err) => _buildFallbackThumbnail(),
                        )
                      : _buildFallbackThumbnail()),
            ),

            // Duration Pill or Shorts Badge (hidden for embeds where duration is unavailable)
            if (video.isShort || (!video.needsEmbed && video.duration > 0 && video.durationFormatted.isNotEmpty && video.durationFormatted != '0:00'))
              Positioned(
                bottom: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: video.isShort ? KidColors.coral.withValues(alpha: 0.9) : KidColors.durationBadgeBg,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (video.isShort) ...[
                        const Icon(Icons.bolt_rounded, color: Colors.white, size: 12),
                        const SizedBox(width: 2),
                        const Text(
                          'Shorts',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ] else
                        Text(
                          video.durationFormatted,
                          style: const TextStyle(
                            fontFamily: 'Roboto',
                            color: Colors.white,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.2,
                          ),
                        ),
                    ],
                  ),
                ),
              ),

            // Downloaded indicator checkmark (Top-Right)
            if (video.downloadStatus == DownloadStatus.downloaded)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: KidColors.durationBadgeBg,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle_rounded, color: KidColors.green, size: 18),
                ),
              ),

            // In-progress download bar
            if (downloadProgress != null && downloadProgress! > 0 && downloadProgress! < 1.0)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(
                  value: downloadProgress,
                  minHeight: 3,
                  color: KidColors.primary,
                  backgroundColor: Colors.white24,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackThumbnail() {
    return Container(
      decoration: BoxDecoration(
        color: KidColors.surfaceDark,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            KidColors.cardDark,
            _avatarColor.withValues(alpha: 0.35),
            KidColors.surfaceDark,
          ],
        ),
      ),
      child: Center(
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.55),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white24, width: 1.5),
          ),
          child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
        ),
      ),
    );
  }


}
