import 'package:book_store_app/app/components/custom_catagory_header.dart';
import 'package:book_store_app/app/data/models/store_banner/store_banner_model.dart';
import 'package:book_store_app/app/data/repositories/promotions_repository.dart';
import 'package:book_store_app/app/modules/seller_storefront/controllers/seller_storefront_controller.dart';
import 'package:book_store_app/app/routes/app_pages.dart';
import 'package:book_store_app/app/services/promotion_attribution_service.dart';
import 'package:book_store_app/config/resources/app_colors.dart';
import 'package:book_store_app/core/theme/base_spacing.dart';
import 'package:book_store_app/utils/toast_util.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:url_launcher/url_launcher.dart';

/// A seller's free, self-managed storefront hero carousel — the buyer-facing
/// counterpart of the home tab's `BannerCarousel`, but sourced from
/// `StoreBannerModel` (`StoreBannerRepository.getPublicBanners`) and shown on
/// a single seller's public storefront. This is a secondary section (not the
/// homepage hero), so it renders nothing while empty — no shimmer.
class StoreBannerCarousel extends StatefulWidget {
  final List<StoreBannerModel> banners;
  const StoreBannerCarousel({super.key, required this.banners});

  @override
  State<StoreBannerCarousel> createState() => _StoreBannerCarouselState();
}

class _StoreBannerCarouselState extends State<StoreBannerCarousel> {
  final PageController _controllerPage = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controllerPage.dispose();
    super.dispose();
  }

  void _maybeTrackImpression(String bannerId) {
    if (Get.isRegistered<SellerStorefrontController>()) {
      Get.find<SellerStorefrontController>().maybeTrackStoreBannerImpression(bannerId);
    }
  }

  void _onPageChanged(int i) {
    setState(() => _index = i);
    _maybeTrackImpression(widget.banners[i].id);
  }

  Future<void> _onBannerTap(StoreBannerModel banner) async {
    PromotionAttributionService.instance.capture('store_banner', banner.id);
    PromotionsRepository().trackClick(entityType: 'store_banner', entityId: banner.id, storeId: banner.storeId);

    final target = banner.linkTarget;
    switch (banner.linkType) {
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
    final banners = widget.banners;
    if (banners.isEmpty) return const SizedBox.shrink();

    // Fire the impression beacon for whichever page is currently visible —
    // deduped per banner id per session by the controller, so calling this
    // on every build (index 0 initially, then again on page change) is safe.
    final visibleIndex = _index.clamp(0, banners.length - 1);
    _maybeTrackImpression(banners[visibleIndex].id);

    return Column(
      children: [
        SizedBox(
          height: Get.height / 5,
          child: PageView.builder(
            controller: _controllerPage,
            onPageChanged: _onPageChanged,
            itemCount: banners.length,
            itemBuilder: (_, i) {
              final item = banners[i];
              final image = item.mobileImageUrl?.isNotEmpty == true ? item.mobileImageUrl! : item.imageUrl;
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: BaseSpacing.md),
                child: GestureDetector(
                  onTap: () => _onBannerTap(item),
                  child: CustomCatagoryHeader(productImage: image),
                ),
              );
            },
          ),
        ),
        SizedBox(height: BaseSpacing.xs + 2),
        if (banners.length > 1)
          SmoothIndicator(
            offset: visibleIndex.toDouble(),
            count: banners.length,
            effect: ExpandingDotsEffect(
              dotHeight: 6,
              dotWidth: 6,
              spacing: 6,
              activeDotColor: AppColors.primaryColor,
              dotColor: AppColors.shimmerBase,
            ),
            size: Size(Get.width * 0.18, 20),
          ),
        SizedBox(height: BaseSpacing.sm),
      ],
    );
  }
}
