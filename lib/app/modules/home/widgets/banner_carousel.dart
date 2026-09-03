import 'dart:async';
import 'package:book_store_app/app/components/custom_catagory_header.dart';
import 'package:book_store_app/app/data/models/store_banner/store_banner_model.dart';
import 'package:book_store_app/app/data/repositories/promotions_repository.dart';
import 'package:book_store_app/app/modules/home/controllers/home_controller.dart';
import 'package:book_store_app/app/routes/app_pages.dart';
import 'package:book_store_app/app/services/promotion_attribution_service.dart';
import 'package:book_store_app/config/resources/app_colors.dart';
import 'package:book_store_app/core/theme/base_spacing.dart';
import 'package:book_store_app/utils/toast_util.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:url_launcher/url_launcher.dart';

class BannerCarousel extends StatefulWidget {
  const BannerCarousel({super.key});

  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel> {
  final c = Get.find<HomeController>();
  final PageController controllerPage = PageController();
  Timer? _autoScrollTimer;

  @override
  void initState() {
    super.initState();
    // Was called unconditionally from `build()` with a plain
    // `Timer.periodic` and no handle kept — every rebuild (e.g. whenever
    // any parent `Obx` fired) started a *new* timer stacked on top of
    // whatever was already running, so the carousel accelerated over time
    // and timers leaked for the lifetime of the app. Starting once here in
    // `initState` and cancelling in `dispose` fixes both.
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted) return;
      if (controllerPage.hasClients && c.banners.isNotEmpty) {
        final nextPage = (c.bannerIndex.value + 1) % c.banners.length;
        controllerPage.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.ease,
        );
      }
    });
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    controllerPage.dispose();
    super.dispose();
  }

  Future<void> _openBannerLink(StoreBannerModel item) async {
    // Capture attribution + fire the click beacon regardless of whether the
    // banner actually has a link — a tap is a tap for tracking purposes.
    PromotionAttributionService.instance.capture('store_banner', item.id);
    PromotionsRepository().trackClick(entityType: 'store_banner', entityId: item.id, storeId: item.storeId);

    final target = item.linkTarget;
    switch (item.linkType) {
      case 'product':
        if (target != null && target.isNotEmpty) {
          Get.toNamed(Routes.productDetailsView, arguments: {'productId': target});
        }
        break;
      case 'category':
        if (target != null && target.isNotEmpty) {
          Get.toNamed(Routes.subCategoryView, arguments: {'categoryId': target});
        }
        break;
      case 'external':
      case 'collection':
      // No dedicated collection screen exists yet — fall back to treating
      // the target as an external link, same as 'external'.
      default:
        await _openExternalLink(target);
        break;
    }
  }

  Future<void> _openExternalLink(String? target) async {
    if (target == null || target.trim().isEmpty) return;
    final uri = Uri.tryParse(target.trim());
    if (uri == null) return;
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched) ToastUtil.showToast('Could not open this link.');
  }

  @override
  Widget build(BuildContext context) {
    // A store that hasn't set up any hero banners yet is common (unlike the
    // old always-populated admin/platform banners) — once loading is done,
    // render nothing instead of a shimmer skeleton stuck on-screen forever.
    if (c.banners.isEmpty && !c.isLoadingBanners.value) {
      return const SizedBox.shrink();
    }
    if (c.banners.isEmpty) {
      return Shimmer.fromColors(
        baseColor: AppColors.gray600,
        highlightColor: AppColors.acceptedBg,
        child: SizedBox(height: Get.height / 5, width: double.infinity),
      );
    }

    // Fire the impression beacon for whichever page is currently visible.
    // `maybeTrackBannerImpression` dedupes per banner id per session, so
    // calling it here on every build (including the initially-visible
    // index 0, before any `onPageChanged` fires) is safe.
    final visibleIndex = c.bannerIndex.value.clamp(0, c.banners.length - 1);
    c.maybeTrackBannerImpression(c.banners[visibleIndex].id);

    return Column(
      children: [
        SizedBox(
          height: Get.height / 5,
          child: PageView.builder(
            controller: controllerPage,
            onPageChanged: (i) {
              c.bannerIndex.value = i;
              c.maybeTrackBannerImpression(c.banners[i].id);
            },
            itemCount: c.banners.length,
            itemBuilder: (_, i) {
              final item = c.banners[i];
              final image = item.mobileImageUrl?.isNotEmpty == true ? item.mobileImageUrl! : item.imageUrl;
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: BaseSpacing.md),
                child: GestureDetector(
                  onTap: () => _openBannerLink(item),
                  child: CustomCatagoryHeader(productImage: image),
                ),
              );
            },
          ),
        ),

        SizedBox(height: BaseSpacing.xs + 2),

        Obx(
          () => SmoothIndicator(
            offset: c.bannerIndex.toDouble(),
            count: c.banners.length,
            effect: ExpandingDotsEffect(
              dotHeight: 6,
              dotWidth: 6,
              spacing: 6,
              activeDotColor: AppColors.primaryColor,
              dotColor: AppColors.shimmerBase,
            ),
            size: Size(Get.width * 0.18, 20),
          ),
        ),
      ],
    );
  }
}
