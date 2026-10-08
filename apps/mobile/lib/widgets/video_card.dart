import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/video_item.dart';
import '../utils/constants.dart';

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

  String get _channelName {
    if (video.channelName != null && video.channelName!.isNotEmpty) {
      return video.channelName!;
    }
    if (video.title.contains('•')) {
      return video.title.split('•').first.trim();
    }
    return 'KidsTube';
  }

  String get _cleanTitle {
    if (video.title.contains('•')) {
      return video.title.split('•').last.trim();
    }
    return video.title;
  }

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

          // 2. Metadata row with 36x36 Channel Avatar
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 14, left: 4, right: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 36x36 Circular Channel Avatar
                CircleAvatar(
                  radius: 18,
                  backgroundColor: _avatarColor,
                  backgroundImage: (video.channelIconUrl != null && video.channelIconUrl!.isNotEmpty)
                      ? CachedNetworkImageProvider(video.channelIconUrl!)
                      : null,
                  child: (video.channelIconUrl != null && video.channelIconUrl!.isNotEmpty)
                      ? null
                      : Text(
                          _channelName.isNotEmpty ? _channelName[0].toUpperCase() : 'K',
                          style: const TextStyle(
                            fontFamily: 'Roboto',
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
                const SizedBox(width: 12),

                // Title + Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Video Title (max 2 lines, FontWeight 500)
                      Text(
                        _cleanTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          color: KidColors.textLight,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w500,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 3),

                      // Metadata (Channel • Quality • Size)
                      Text(
                        '$_channelName • ${video.quality}${video.fileSizeBytes > 0 ? " • ${(video.fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB" : ""}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          color: KidColors.textMuted,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),

                // Download Action Button
                if (onDownloadTap != null) _buildDownloadAction(),
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
              _buildThumbnail(context, borderRadius: 14, aspectRatio: 9 / 16),
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 4, left: 2, right: 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _cleanTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        color: KidColors.textLight,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.bolt_rounded, color: Colors.red, size: 14),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            '$_channelName • Shorts',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Roboto',
                              color: KidColors.textMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                            ),
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
        width: 220,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 16:9 Thumbnail
            _buildThumbnail(context, borderRadius: 10, aspectRatio: 16 / 9),

            // Metadata Row
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 2, right: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: _avatarColor,
                    backgroundImage: (video.channelIconUrl != null && video.channelIconUrl!.isNotEmpty)
                        ? CachedNetworkImageProvider(video.channelIconUrl!)
                        : null,
                    child: (video.channelIconUrl != null && video.channelIconUrl!.isNotEmpty)
                        ? null
                        : Text(
                            _channelName.isNotEmpty ? _channelName[0].toUpperCase() : 'K',
                            style: const TextStyle(
                              fontFamily: 'Roboto',
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _cleanTitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Roboto',
                            color: KidColors.textLight,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _channelName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Roboto',
                            color: KidColors.textMuted,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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
                      color: Colors.red.withValues(alpha: 0.9),
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

                // 6. Overlaid Title and Channel (Bottom)
                Positioned(
                  bottom: 10,
                  left: 10,
                  right: 10,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _cleanTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          color: Colors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          height: 1.25,
                          shadows: [
                            Shadow(color: Colors.black87, blurRadius: 4),
                          ],
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _channelName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          shadows: [
                            Shadow(color: Colors.black87, blurRadius: 4),
                          ],
                        ),
                      ),
                    ],
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

            // Duration Pill or Shorts Badge
            Positioned(
              bottom: 6,
              right: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: video.isShort ? Colors.red.withValues(alpha: 0.9) : KidColors.durationBadgeBg,
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

  Widget _buildDownloadAction() {
    if (downloadProgress != null && downloadProgress! > 0 && downloadProgress! < 1.0) {
      return const Padding(
        padding: EdgeInsets.only(left: 6, top: 2),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: KidColors.primary),
        ),
      );
    }

    if (video.downloadStatus == DownloadStatus.downloaded) {
      return const SizedBox.shrink();
    }

    return IconButton(
      visualDensity: VisualDensity.compact,
      icon: const Icon(Icons.arrow_downward_rounded, color: KidColors.textMuted, size: 20),
      tooltip: 'Save Offline',
      onPressed: onDownloadTap,
    );
  }
}
