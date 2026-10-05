import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/video_item.dart';
import '../utils/constants.dart';

class VideoTile extends StatelessWidget {
  final VideoItem video;
  final VoidCallback onTap;
  final VoidCallback? onDownloadTap;
  final double? downloadProgress;

  const VideoTile({
    super.key,
    required this.video,
    required this.onTap,
    this.onDownloadTap,
    this.downloadProgress,
  });

  @override
  Widget build(BuildContext context) {
    final hasLocalThumb = video.localThumbnailPath != null &&
        File(video.localThumbnailPath!).existsSync();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 220,
        margin: const EdgeInsets.only(right: 14),
        decoration: BoxDecoration(
          color: KidColors.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: KidColors.borderDark, width: 1.2),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail container
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: hasLocalThumb
                      ? Image.file(
                          File(video.localThumbnailPath!),
                          fit: BoxFit.cover,
                        )
                      : (video.thumbnailUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: video.thumbnailUrl,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: KidColors.surfaceDark,
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: KidColors.primary,
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: KidColors.surfaceDark,
                                child: const Icon(Icons.movie, color: KidColors.textMuted, size: 36),
                              ),
                            )
                          : Container(
                              color: KidColors.surfaceDark,
                              child: const Icon(Icons.movie, color: KidColors.textMuted, size: 36),
                            )),
                ),

                // Duration badge
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      video.durationFormatted,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                // Download status badge / button
                Positioned(
                  top: 8,
                  right: 8,
                  child: _buildDownloadBadge(),
                ),
              ],
            ),

            // Video Title & Meta
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: KidColors.textLight,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        video.quality,
                        style: const TextStyle(
                          color: KidColors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (video.fileSizeBytes > 0)
                        Text(
                          '${(video.fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB',
                          style: const TextStyle(
                            color: KidColors.textMuted,
                            fontSize: 11,
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
  }

  Widget _buildDownloadBadge() {
    if (downloadProgress != null && downloadProgress! > 0) {
      return Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          shape: BoxShape.circle,
        ),
        padding: const EdgeInsets.all(4),
        child: CircularProgressIndicator(
          value: downloadProgress,
          strokeWidth: 3,
          color: KidColors.accent,
          backgroundColor: Colors.white24,
        ),
      );
    }

    if (video.isOfflineReady) {
      return Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: KidColors.green.withOpacity(0.9),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check, color: Colors.white, size: 14),
      );
    }

    return GestureDetector(
      onTap: onDownloadTap,
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.download_rounded, color: Colors.white, size: 16),
      ),
    );
  }
}
