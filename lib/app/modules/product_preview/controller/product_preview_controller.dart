import 'package:audioplayers/audioplayers.dart';
import 'package:book_store_app/app/data/repositories/product_repository.dart';
import 'package:book_store_app/app/data/services/current_store_service.dart';
import 'package:book_store_app/app/modules/product_preview/models/product_preview_model.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';

class ProductPreviewController extends GetxController {
  final ProductRepository _productRepository = ProductRepository();

  late final String productId;

  final Rx<ProductPreviewModel?> preview = Rx<ProductPreviewModel?>(null);
  final RxBool isLoading = true.obs;
  final RxBool hasError = false.obs;

  // ─── Video (owned here, not in the widget, per this app's controller-owns-
  // lifecycle convention — disposed in onClose like other PageControllers) ──
  VideoPlayerController? _videoPlayerController;
  final Rx<ChewieController?> chewieController = Rx<ChewieController?>(null);
  final RxBool isVideoReady = false.obs;

  // ─── Audio ──────────────────────────────────────────────────────────────
  final AudioPlayer _audioPlayer = AudioPlayer();
  final RxBool isAudioPlaying = false.obs;
  final Rx<Duration> audioPosition = Duration.zero.obs;
  final Rx<Duration> audioDuration = Duration.zero.obs;

  // ─── PDF pager ──────────────────────────────────────────────────────────
  final PageController pdfPageController = PageController();
  final RxInt pdfPage = 0.obs;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    productId = (args is Map ? args['productId'] as String? : null) ?? '';
    _audioPlayer.onPositionChanged.listen((d) => audioPosition.value = d);
    _audioPlayer.onDurationChanged.listen((d) => audioDuration.value = d);
    _audioPlayer.onPlayerStateChanged.listen(
      (s) => isAudioPlaying.value = s == PlayerState.playing,
    );
    fetchPreview();
  }

  Future<void> fetchPreview() async {
    if (productId.isEmpty) {
      hasError.value = true;
      isLoading.value = false;
      return;
    }
    isLoading.value = true;
    hasError.value = false;
    _disposeVideo();

    final result = await _productRepository.getProductPreview(
      productId,
      storeId: Get.find<CurrentStoreService>().storeId,
    );
    if (result == null) {
      hasError.value = true;
      isLoading.value = false;
      return;
    }

    preview.value = result;
    isLoading.value = false;

    if (result.type == 'video' && result.url != null) {
      await _initVideo(result.url!);
    }
  }

  Future<void> _initVideo(String url) async {
    isVideoReady.value = false;
    final controller = VideoPlayerController.networkUrl(Uri.parse(url));
    _videoPlayerController = controller;
    await controller.initialize();
    chewieController.value = ChewieController(
      videoPlayerController: controller,
      autoPlay: false,
      looping: false,
      allowFullScreen: true,
      allowMuting: true,
    );
    isVideoReady.value = true;
  }

  Future<void> toggleAudio(String url) async {
    if (isAudioPlaying.value) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play(UrlSource(url));
    }
  }

  void _disposeVideo() {
    chewieController.value?.dispose();
    chewieController.value = null;
    _videoPlayerController?.dispose();
    _videoPlayerController = null;
    isVideoReady.value = false;
  }

  @override
  void onClose() {
    _disposeVideo();
    _audioPlayer.dispose();
    pdfPageController.dispose();
    super.onClose();
  }
}
