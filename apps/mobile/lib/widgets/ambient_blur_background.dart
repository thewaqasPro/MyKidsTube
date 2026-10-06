import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../utils/constants.dart';

class AmbientBlurBackground extends StatelessWidget {
  final VideoPlayerController? controller;
  final String? fallbackThumbnailUrl;

  const AmbientBlurBackground({
    super.key,
    this.controller,
    this.fallbackThumbnailUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Scaled and cropped video or dark backdrop
        if (controller != null && controller!.value.isInitialized)
          FittedBox(
            fit: BoxFit.cover,
            clipBehavior: Clip.hardEdge,
            child: SizedBox(
              width: controller!.value.size.width,
              height: controller!.value.size.height,
              child: VideoPlayer(controller!),
            ),
          )
        else
          Container(color: KidColors.bgDark),

        // 2. Heavy Gaussian Blur
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            color: Colors.black.withOpacity(0.45),
          ),
        ),

        // 3. Subtle top and bottom vignette gradients for high contrast controls
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black54,
                Colors.transparent,
                Colors.transparent,
                Colors.black87,
              ],
              stops: [0.0, 0.2, 0.7, 1.0],
            ),
          ),
        ),
      ],
    );
  }
}
