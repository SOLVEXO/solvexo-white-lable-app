import 'package:book_store_app/app/components/common_image_view.dart';
import 'package:book_store_app/app/components/custom_text.dart';
import 'package:book_store_app/app/components/svg_icon.dart';
import 'package:book_store_app/app/components/wishlist_heart_button.dart';
import 'package:book_store_app/app/data/services/currency_controller.dart';
import 'package:book_store_app/app/modules/category/controllers/product_controller.dart';
import 'package:book_store_app/app/modules/category/models/product_model.dart';
import 'package:book_store_app/app/modules/home/controllers/home_controller.dart';
import 'package:book_store_app/app/modules/home/widgets/icon_badge.dart';
import 'package:book_store_app/app/modules/home/widgets/notched_image_box.dart';
import 'package:book_store_app/config/resources/app_colors.dart';
import 'package:book_store_app/config/resources/app_icons.dart';
import 'package:book_store_app/config/resources/app_text_styles.dart';
import 'package:book_store_app/core/theme/base_shadows.dart';
import 'package:book_store_app/core/theme/base_spacing.dart';
import 'package:book_store_app/utils/app_font_size.dart';
import 'package:book_store_app/utils/dimens.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProductCard extends StatelessWidget {
  final int index;
  final ProductModel product;

  ProductCard({super.key, required this.product, required this.index});

  final homeController = Get.find<HomeController>();

  ProductController get productController {
    if (!Get.isRegistered<ProductController>()) Get.put(ProductController());
    return Get.find<ProductController>();
  }

  CurrencyController get currencyController {
    if (!Get.isRegistered<CurrencyController>()) {
      Get.put(CurrencyController(), permanent: true);
    }
    return Get.find<CurrencyController>();
  }

  // Half the add-to-cart button sits below the image box, overlapping into
  // the text zone — this is how much bottom room the image box must give up.
  static const double _cartButtonSize = 30;
  static const double _cartButtonOverlap = _cartButtonSize / 2;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => productController.openProductDetails(product),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(BaseRadius.lg),
          boxShadow: BaseShadows.forLevel(BaseElevation.level1),
        ),
        padding: EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image box — peach background + terracotta notched border ──────
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: _cartButtonOverlap),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: NotchedImageBox(
                        heartGap: BaseSpacing.xs,
                        heartSize: 28,
                        radius: BaseRadius.lg,
                        // height/width: double.infinity forces CommonImageView
                        // to fill the box regardless of the image's own
                        // aspect ratio — without this it sizes to the image's
                        // natural dimensions and leaves blank space around it.
                        child: product.images.isNotEmpty
                            ? CommonImageView(
                                url: product.images.first,
                                fit: BoxFit.cover,
                                height: double.infinity,
                                width: double.infinity,
                              )
                            : const Icon(
                                Icons.image_outlined,
                                color: AppColors.lightGrey7,
                                size: 40,
                              ),
                      ),
                    ),

                    // Sale + education-level badges — top left, stacked,
                    // mirrors the heart's top-right placement inside the notch.
                    if (product.isOnSale ||
                        (product.isEducational &&
                            product.educationLevel != null))
                      Positioned(
                        top: BaseSpacing.xxs,
                        left: BaseSpacing.xxs,
                        right: BaseSpacing.xxs + 28, // clear the heart button
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (product.isOnSale)
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: BaseSpacing.xs,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.red,
                                  borderRadius: BorderRadius.circular(
                                    BaseRadius.sm,
                                  ),
                                ),
                                child: CustomText(
                                  text: product.activeCampaign!.badgeLabel,
                                  color: AppColors.white,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            if (product.isOnSale &&
                                product.isEducational &&
                                product.educationLevel != null)
                              SizedBox(height: BaseSpacing.xxs / 2),
                            if (product.isEducational &&
                                product.educationLevel != null)
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: BaseSpacing.xs,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryColor,
                                  borderRadius: BorderRadius.circular(
                                    BaseRadius.sm,
                                  ),
                                ),
                                child: CustomText(
                                  text: educationLevelLabel(
                                    product.educationLevel,
                                  ),
                                  color: AppColors.white,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                        ),
                      ),

                    // Wishlist heart — sitting inside the notch, top right
                    Positioned(
                      top: 0,
                      right: 0,
                      child: WishlistHeartButton(
                        productId: product.id,
                        variantId: product.variants.isNotEmpty
                            ? product.variants.first.id
                            : '',
                      ),
                    ),

                    // Add to cart — overlaps the bottom-right corner of the
                    // image box, same as the reference design's bag button.
                    Positioned(
                      bottom: -_cartButtonOverlap,
                      right: BaseSpacing.xs,
                      child: GestureDetector(
                        onTap: () => homeController.quickAddToCart(product),
                        child: Container(
                          width: _cartButtonSize,
                          height: _cartButtonSize,
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(
                              AppDimen.borderRadius,
                            ),
                            border: Border.all(
                              color: AppColors.primaryColor,
                              width: 0.1,
                            ),
                            boxShadow: BaseShadows.forLevel(
                              BaseElevation.level1,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: IconBadge(icon: AppIcons.addToCartIcon),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // ── Text — sized to content, no forced empty space ─────────
            Padding(
              padding: EdgeInsets.fromLTRB(
                BaseSpacing.xs,
                BaseSpacing.xs,
                BaseSpacing.xs,
                BaseSpacing.xxs,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomText(
                    text: product.name,
                    color: AppColors.black2,
                    fontSize: AppFontSize.tiny,
                    fontWeight: FontWeight.w700,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: BaseSpacing.xxs),
                  _SellerRatingRow(product: product),
                  SizedBox(height: BaseSpacing.xxs),
                  Obx(
                    () => product.hasDiscount
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              CustomText(
                                text: currencyController.format(
                                  product.compareAtPrice!,
                                  product.currency,
                                ),
                                color: AppColors.gray600,
                                fontSize: AppFontSize.tiny,
                                fontWeight: FontWeight.w500,
                                textDecoration: TextDecoration.lineThrough,
                                fontFamily: AppTextStyles.monoFontFamily,
                              ),
                              SizedBox(width: BaseSpacing.xxs),
                              CustomText(
                                text: currencyController.format(
                                  product.price,
                                  product.currency,
                                ),
                                color: AppColors.primaryColor,
                                fontSize: AppFontSize.verySmall,
                                fontWeight: FontWeight.w800,
                                fontFamily: AppTextStyles.monoFontFamily,
                              ),
                            ],
                          )
                        : CustomText(
                            text: product.hasPriceRange
                                ? '${currencyController.format(product.price, product.currency)} – ${currencyController.format(product.maxPrice, product.currency)}'
                                : currencyController.format(
                                    product.price,
                                    product.currency,
                                  ),
                            color: AppColors.primaryColor,
                            fontSize: AppFontSize.verySmall,
                            fontWeight: FontWeight.w800,
                            fontFamily: AppTextStyles.monoFontFamily,
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
}

// ─── "⭐ rating" subtitle ─────────────────────────────────────────────────────

class _SellerRatingRow extends StatelessWidget {
  const _SellerRatingRow({required this.product});
  final ProductModel product;

  @override
  Widget build(BuildContext context) {
    final rating = product.averageRating.toStringAsFixed(1);
    return Row(
      children: [
        SvgIcon(
          assetName: AppIcons.fillStar,
          size: 11,
          color: AppColors.ratingStar,
        ),
        SizedBox(width: BaseSpacing.xxs / 2),
        CustomText(
          text: rating,
          color: AppColors.gray600,
          fontSize: 10.5,
          fontWeight: FontWeight.w400,
        ),
      ],
    );
  }
}
