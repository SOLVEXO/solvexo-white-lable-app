import 'package:book_store_app/app/components/custom_refresh_wrapper.dart';
import 'package:book_store_app/app/components/custom_text.dart';
import 'package:book_store_app/app/modules/home/widgets/product_card.dart';
import 'package:book_store_app/app/modules/seller_storefront/controllers/seller_storefront_controller.dart';
import 'package:book_store_app/app/modules/seller_storefront/widgets/product_horizontal_section.dart';
import 'package:book_store_app/app/modules/seller_storefront/widgets/store_announcement_bar.dart';
import 'package:book_store_app/app/modules/seller_storefront/widgets/store_banner_carousel.dart';
import 'package:book_store_app/app/modules/seller_storefront/widgets/storefront_filter_bar.dart';
import 'package:book_store_app/app/modules/seller_storefront/widgets/storefront_header.dart';
import 'package:book_store_app/app/modules/seller_storefront/widgets/storefront_plans_teaser.dart';
import 'package:book_store_app/app/modules/seller_storefront/widgets/storefront_services_teaser.dart';
import 'package:book_store_app/app/modules/seller_storefront/widgets/storefront_shimmer.dart';
import 'package:book_store_app/config/resources/app_colors.dart';
import 'package:book_store_app/config/resources/app_text_styles.dart';
import 'package:book_store_app/utils/app_font_size.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SellerStorefrontView extends StatelessWidget {
  SellerStorefrontView({super.key});

  final SellerStorefrontController c = Get.put(SellerStorefrontController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Obx(() {
        if (c.isLoading.value) return const StorefrontShimmer();

        final store = c.store.value;
        if (store == null) return _NotFoundState();

        return CustomRefreshWrapper(
          onRefresh: c.refreshData,
          child: CustomScrollView(
            controller: c.scrollController,
            slivers: [
              SliverToBoxAdapter(
                child: StorefrontHeader(store: store, c: c),
              ),
              // Hidden entirely (renders nothing) when the bar isn't
              // currently active/in-window, or once dismissed for this
              // screen session.
              SliverToBoxAdapter(
                child: c.announcementBarDismissed.value
                    ? const SizedBox.shrink()
                    : StoreAnnouncementBar(
                        announcementBar: store.announcementBar,
                        onDismiss: c.dismissAnnouncementBar,
                      ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 18)),
              // Hidden entirely (renders nothing) when the store has no
              // active hero banners.
              SliverToBoxAdapter(
                child: StoreBannerCarousel(banners: c.storeBanners),
              ),
              // Hidden entirely (renders nothing) when the store has no
              // active membership plans.
              SliverToBoxAdapter(
                child: StorefrontPlansTeaser(storeId: store.storeId, storeName: store.name),
              ),
              // Hidden entirely (renders nothing) when the store has no
              // active bookable services.
              SliverToBoxAdapter(
                child: StorefrontServicesTeaser(storeId: store.storeId, storeName: store.name),
              ),
              // ── Merchandising rows — handpicked pinned products read as
              // "curated by the seller", so they lead; the rest follow in a
              // discovery-oriented order. Each hides itself when empty.
              SliverToBoxAdapter(
                child: ProductHorizontalSection(title: 'Handpicked by the Seller', products: c.pinnedProducts),
              ),
              SliverToBoxAdapter(
                child: ProductHorizontalSection(title: 'New Arrivals', products: c.newArrivals),
              ),
              SliverToBoxAdapter(
                child: ProductHorizontalSection(title: 'Best Sellers', products: c.bestSellers),
              ),
              SliverToBoxAdapter(
                child: ProductHorizontalSection(title: 'Trending Now', products: c.trending),
              ),
              SliverToBoxAdapter(child: StorefrontFilterBar(c: c)),
              const SliverToBoxAdapter(child: SizedBox(height: 18)),
              SliverToBoxAdapter(child: _SectionHeader(c: c)),
              _ProductsSliver(c: c),
              SliverToBoxAdapter(
                child: Obx(
                  () => c.isLoadingMore.value
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primaryColor,
                              ),
                            ),
                          ),
                        )
                      : const SizedBox(height: 24),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final SellerStorefrontController c;
  const _SectionHeader({required this.c});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (c.isLoadingProducts.value || c.products.isEmpty) {
        return const SizedBox.shrink();
      }
      return Padding(
        padding: const EdgeInsets.fromLTRB(15, 0, 15, 4),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 16,
              decoration: BoxDecoration(
                color: AppColors.primaryColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 8),
            CustomText(
              text: '${c.totalProducts.value} Products',
              fontFamily: AppTextStyles.headingFontFamily,
              fontSize: AppFontSize.small2,
              fontWeight: FontWeight.w700,
              color: AppColors.black2,
            ),
          ],
        ),
      );
    });
  }
}

class _ProductsSliver extends StatelessWidget {
  final SellerStorefrontController c;
  const _ProductsSliver({required this.c});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (c.isLoadingProducts.value) {
        return SliverPadding(
          padding: const EdgeInsets.all(15),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 0.60,
            ),
            delegate: SliverChildBuilderDelegate(
              (_, __) => Container(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              childCount: 6,
            ),
          ),
        );
      }

      if (c.products.isEmpty) {
        return SliverToBoxAdapter(child: _EmptyState());
      }

      return SliverPadding(
        padding: const EdgeInsets.all(15),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 0.60,
          ),
          delegate: SliverChildBuilderDelegate(
            (_, i) => ProductCard(product: c.products[i], index: i),
            childCount: c.products.length,
          ),
        ),
      );
    });
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 50),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryColor.withOpacity(0.12),
                    AppColors.accentColor.withOpacity(0.06),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.storefront_outlined,
                size: 34,
                color: AppColors.primaryColor,
              ),
            ),
            const SizedBox(height: 14),
            const CustomText(
              text: 'No products yet',
              fontSize: AppFontSize.small2,
              fontWeight: FontWeight.w600,
              color: AppColors.black2,
            ),
            const SizedBox(height: 4),
            const CustomText(
              text: 'This store hasn\'t listed anything for this filter.',
              fontSize: AppFontSize.tiny,
              color: AppColors.grey,
            ),
          ],
        ),
      ),
    );
  }
}

class _NotFoundState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: MediaQuery.of(context).padding.top + 10,
          left: 16,
          child: GestureDetector(
            onTap: () => Get.back(),
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: AppColors.lightGrey3,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 16,
                color: AppColors.black2,
              ),
            ),
          ),
        ),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: AppColors.lightGrey3,
                  borderRadius: BorderRadius.circular(24),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.storefront_outlined,
                  size: 40,
                  color: AppColors.lightGrey2,
                ),
              ),
              const SizedBox(height: 16),
              const CustomText(
                text: 'Store not found',
                fontSize: AppFontSize.medium,
                fontWeight: FontWeight.bold,
                color: AppColors.black2,
              ),
              const SizedBox(height: 4),
              const CustomText(
                text: 'This store may have been removed or is unavailable.',
                fontSize: AppFontSize.verySmall,
                color: AppColors.grey,
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () => Get.back(),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primaryColor, AppColors.accentColor],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const CustomText(
                    text: 'Go Back',
                    fontSize: AppFontSize.verySmall,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
