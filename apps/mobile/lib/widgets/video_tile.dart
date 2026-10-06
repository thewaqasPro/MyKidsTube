import 'package:flutter/material.dart';
import '../models/video_item.dart';
import 'video_card.dart';

/// Legacy alias for VideoCard to preserve any references
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
    return VideoCard(
      video: video,
      onTap: onTap,
      onDownloadTap: onDownloadTap,
      downloadProgress: downloadProgress,
    );
  }
}
