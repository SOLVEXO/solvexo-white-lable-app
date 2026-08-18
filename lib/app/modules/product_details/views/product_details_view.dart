import 'package:book_store_app/app/components/custom_text.dart';
import 'package:book_store_app/app/components/recommended_product_list.dart';
import 'package:book_store_app/app/modules/product_details/controller/product_detail_controller.dart';
import 'package:book_store_app/app/modules/product_details/widgets/product_details_bottom_bar.dart';
import 'package:book_store_app/app/modules/product_details/widgets/product_detail_shimmer.dart';
import 'package:book_store_app/app/modules/product_details/widgets/product_hero_gallery.dart';
import 'package:book_store_app/app/modules/product_details/widgets/product_price_stock_row.dart';
import 'package:book_store_app/app/modules/product_details/widgets/product_rating_sold_row.dart';
import 'package:book_store_app/app/modules/product_details/widgets/product_reviews_section.dart';
import 'package:book_store_app/app/modules/product_details/widgets/product_section_title.dart';
import 'package:book_store_app/app/modules/product_details/widgets/product_variant_selector.dart';
import 'package:book_store_app/app/modules/product_details/widgets/seller_store_card.dart';
import 'package:book_store_app/app/modules/profile/controllers/profile_controller.dart';
import 'package:book_store_app/app/routes/app_pages.dart';
import 'package:book_store_app/config/resources/app_colors.dart';
import 'package:book_store_app/core/theme/base_spacing.dart';
import 'package:book_store_app/core/widgets/buttons/base_buttons.dart';
import 'package:book_store_app/utils/app_font_size.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProductDetailsView extends StatelessWidget {
  ProductDetailsView({super.key});

  final controller = Get.put(ProductDetailController());

  ProfileController get profileController {
    if (!Get.isRegistered<ProfileController>()) Get.put(ProfileController(), permanent: true);
    return Get.find<ProfileController>();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.background,
      // Bottom bar only shown once product is loaded and user is logged in
      bottomNavigationBar: Obx(
        () => controller.isLoading.value
            ? const SizedBox.shrink()
            : ProductDetailsBottomBar(
                controller: controller,
                profileController: profileController,
                size: size,
              ),
      ),
      body: SafeArea(
        bottom: profileController.user.isNull,
        child: Obx(() {
          // ── Loading state ───────────────────────────────────────────────
          if (controller.isLoading.value) {
            return ProductDetailShimmer();
          }

          final product = controller.product.value;

          // ── Error / not found state ─────────────────────────────────────
          if (product == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 40,
                    color: AppColors.gray600,
                  ),
                  SizedBox(height: BaseSpacing.sm),
                  CustomText(
                    text: 'Product not found',
                    color: AppColors.gray600,
                    fontSize: AppFontSize.small,
                    fontWeight: FontWeight.w400,
                  ),
                ],
              ),
            );
          }

          // ── Product loaded ──────────────────────────────────────────────
          return SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(
              parent: ClampingScrollPhysics(),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Hero image carousel + floating back/share/heart ───────
                ProductHeroGallery(controller: controller, product: product),

                Container(
                  color: AppColors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: BaseSpacing.xl,
                    vertical: BaseSpacing.sm,
                  ),
                  width: double.infinity,
                  child: Column(
                    spacing: BaseSpacing.xs,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Seller / store row ──────────────────────────────
                      if (product.sellerId.isNotEmpty)
                        SellerStoreCard(product: product),

                      // ── Name ─────────────────────────────────────────────
                      CustomText(
                        text: product.name,
                        color: AppColors.black,
                        fontSize: AppFontSize.regular,
                        fontWeight: FontWeight.w600,
                      ),

                      // ── Price + Stock pill ──────────────────────────────
                      ProductPriceStockRow(controller: controller),

                      // ── Preview before you buy (digital products only) ──
                      if (product.isDigital && product.previewAvailable)
                        Padding(
                          padding: EdgeInsets.only(top: BaseSpacing.xs),
                          child: GhostButton(
                            label: 'Preview before you buy',
                            icon: Icon(
                              Icons.visibility_outlined,
                              size: 18,
                              color: AppColors.primaryColor,
                            ),
                            onPressed: () => Get.toNamed(
                              Routes.productPreviewView,
                              arguments: {'productId': product.id},
                            ),
                          ),
                        ),

                      const Divider(),

                      // ── Variants ────────────────────────────────────────
                      ProductVariantSelector(
                        controller: controller,
                        product: product,
                      ),

                      const Divider(),

                      const ProductSectionTitle('Description'),
                      CustomText(
                        text: product.description,
                        color: AppColors.black,
                        fontSize: AppFontSize.tiny,
                      ),

                      // ── Rating + sold row ───────────────────────────────
                      ProductRatingSoldRow(
                        controller: controller,
                        product: product,
                      ),

                      const Divider(),

                      // ── Reviews expansion tile ──────────────────────────
                      ProductReviewsSection(
                        controller: controller,
                        profileController: profileController,
                      ),

                      const Divider(),

                      const ProductSectionTitle('Related Products'),
                      RecommendedProductList(),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
