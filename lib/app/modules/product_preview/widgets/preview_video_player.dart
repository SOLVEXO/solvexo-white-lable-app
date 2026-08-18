import 'package:book_store_app/app/modules/product_preview/controller/product_preview_controller.dart';
import 'package:book_store_app/config/resources/app_colors.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Plays a short, trimmed video-preview clip via a short-lived signed URL —
/// the master file is never sent to the device, only this trimmed derivative.
class PreviewVideoPlayer extends StatelessWidget {
  final ProductPreviewController controller;

  const PreviewVideoPlayer({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final chewie = controller.chewieController.value;
      if (!controller.isVideoReady.value || chewie == null) {
        return Center(
          child: CircularProgressIndicator(color: AppColors.primaryColor),
        );
      }
      return Center(
        child: AspectRatio(
          aspectRatio: chewie.videoPlayerController.value.aspectRatio,
          child: Chewie(controller: chewie),
        ),
      );
    });
  }
}
