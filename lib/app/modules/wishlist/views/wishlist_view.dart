import 'package:book_store_app/app/components/common_image_view.dart';
import 'package:book_store_app/app/components/custom_app_bar_two.dart';
import 'package:book_store_app/app/components/custom_icon_button.dart';
import 'package:book_store_app/app/components/custom_refresh_wrapper.dart';
import 'package:book_store_app/app/components/custom_text.dart';
import 'package:book_store_app/app/components/shimmer/trip_shimmer.dart';
import 'package:book_store_app/app/data/services/currency_controller.dart';
import 'package:book_store_app/app/modules/wishlist/controllers/wishlist_controller.dart';
import 'package:book_store_app/app/modules/wishlist/model/wishlist_model.dart';
import 'package:book_store_app/app/routes/app_pages.dart';
import 'package:book_store_app/config/resources/app_colors.dart';
import 'package:book_store_app/config/resources/app_icons.dart';
import 'package:book_store_app/config/resources/app_text_styles.dart';
import 'package:book_store_app/core/base/base_view.dart';
import 'package:book_store_app/core/widgets/base_empty_view.dart';
import 'package:book_store_app/utils/app_font_size.dart';
import 'package:book_store_app/utils/dimens.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

/// First screen migrated to the new `core/` architecture — same
/// `WishlistController`/API/business logic as before, now composed via
/// [BaseView] instead of `BaseViewScreen`, with the shared [BaseEmptyView]
/// replacing a bespoke empty-state widget.
class WishlistView extends BaseView<WishlistController> {
  const WishlistView({super.key});

  @override
  Color? get backgroundColor => AppColors.background;

  @override
  PreferredSizeWidget buildAppBar(BuildContext context) {
    return CustomAppBarTwo(
      title: 'Wishlist',
      actions: [
        // Reactive fix: the original action icon was built once outside any
        // Obx, so it never updated after the list emptied/filled — wrapped
        // here so it now reflects live wishlist state.
        Obx(
          () => controller.wishlistItems.isNotEmpty
              ? CustomIconButton(
                  assetName: AppIcons.deleteIcon,
                  size: 24,
                  isPadding: true,
                  onPressed: () => controller.showDeleteConfirmation(),
                )
              : const SizedBox(),
        ),
      ],
    );
  }

  @override
  Future<void> Function()? get onRefresh => controller.refresh;

  @override
  Widget buildBody(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppDimen.horizontalPadding.w,
        vertical: AppDimen.verticalPadding.h,
      ),
      child: CustomRefreshWrapper(
        onRefresh: () => controller.refresh(),
        child: Obx(() {
          if (controller.isLoading.value) {
            return const TripShimmer(itemCount: 6);
          }

          if (controller.isEmpty) {
            return BaseEmptyView(
              icon: Icons.favorite_border_rounded,
              title: 'Your wishlist is empty',
              subtitle: 'Save items you love and come back to them anytime.',
              actionLabel: 'Explore Products',
              onAction: () => Get.back(),
            );
          }

          return Column(
            spacing: 10,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const CustomText(
                    text: 'My Wishlist',
                    fontSize: AppFontSize.regular,
                    fontWeight: FontWeight.w600,
                  ),
                  Obx(
                    () => CustomText(
                      text: '${controller.count} items',
                      fontSize: AppFontSize.small,
                      color: AppColors.gray600,
                    ),
                  ),
                ],
              ),
              Expanded(
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics()),
                  itemCount: controller.wishlistItems.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => _WishlistCard(item: controller.wishlistItems[i], controller: controller),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

// ─── Wishlist Card ─────────────────────────────────────────────────────────

class _WishlistCard extends StatelessWidget {
  final WishlistItem item;
  final WishlistController controller;

  const _WishlistCard({required this.item, required this.controller});

  CurrencyController get _currencyController {
    if (!Get.isRegistered<CurrencyController>()) {
      Get.put(CurrencyController(), permanent: true);
    }
    return Get.find<CurrencyController>();
  }

  @override
  Widget build(BuildContext context) {
    final product = item.product;
    final variant = item.selectedVariant ?? (item.variants.isNotEmpty ? item.variants.first : null);
    final inStock = product.isDigital || (variant?.isInStock ?? true);

    return GestureDetector(
      onTap: () => Get.toNamed(Routes.productDetailsView, arguments: {'productId': product.id}),
      child: Container(
        padding: EdgeInsets.all(AppDimen.allPadding),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(color: AppColors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -2)),
          ],
        ),
        child: Row(
          spacing: AppDimen.allPadding,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              child: CommonImageView(url: item.displayImage, width: 90, height: 90, fit: BoxFit.cover),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    text: product.name,
                    fontSize: AppFontSize.small,
                    fontWeight: FontWeight.w600,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  if (variant != null && variant.options.isNotEmpty)
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [for (final o in variant.options) _Badge(label: o.value)],
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Obx(
                        () => CustomText(
                          text: _currencyController.format(item.price, item.currency),
                          fontSize: AppFontSize.small,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryColor,
                          fontFamily: AppTextStyles.monoFontFamily,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: inStock ? AppColors.seaGreen.withOpacity(0.10) : AppColors.red.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: CustomText(
                          text: inStock ? 'In stock' : 'Out of stock',
                          fontSize: AppFontSize.small2,
                          fontWeight: FontWeight.w600,
                          color: inStock ? AppColors.darkGreen : AppColors.red,
                          fontFamily: AppTextStyles.monoFontFamily,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8, right: 8),
              child: GestureDetector(
                onTap: () {
                  final variantId =
                      item.wishlistEntry?.productVariantId ?? (item.variants.isNotEmpty ? item.variants.first.id : '');
                  controller.removeFromWishlist(productVariantId: variantId, wishlistId: item.wishlistId);
                },
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.red.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.favorite_rounded, size: 18, color: AppColors.red),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Variant Badge ─────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  final String label;
  const _Badge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: CustomText(
        text: label,
        fontSize: AppFontSize.verySmall,
        color: AppColors.primaryColor,
        fontFamily: AppTextStyles.monoFontFamily,
      ),
    );
  }
}
