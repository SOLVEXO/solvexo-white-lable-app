import 'package:book_store_app/app/components/custom_rating_bar.dart';
import 'package:book_store_app/app/components/custom_text.dart';
import 'package:book_store_app/app/data/models/rating/review_model.dart';
import 'package:book_store_app/app/modules/product_details/controller/product_detail_controller.dart';
import 'package:book_store_app/app/modules/product_details/widgets/product_section_title.dart';
import 'package:book_store_app/app/modules/profile/controllers/profile_controller.dart';
import 'package:book_store_app/app/routes/app_pages.dart';
import 'package:book_store_app/config/resources/app_colors.dart';
import 'package:book_store_app/core/theme/base_spacing.dart';
import 'package:book_store_app/utils/app_font_size.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// "Reviews" expansion tile: sort chips + review list, with loading/empty
/// states for both the initial fetch and re-sorting.
class ProductReviewsSection extends StatelessWidget {
  final ProductDetailController controller;
  final ProfileController profileController;
  final RxBool expanded = false.obs;

  ProductReviewsSection({
    super.key,
    required this.controller,
    required this.profileController,
  });

  static const _sortLabels = <String, String>{
    'newest': 'Newest',
    'most_helpful': 'Most Helpful',
    'highest_rating': 'Highest Rated',
    'lowest_rating': 'Lowest Rated',
    'oldest': 'Oldest',
  };

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => ExpansionTile(
        collapsedShape: const Border(top: BorderSide.none),
        shape: const Border(top: BorderSide.none),
        title: const ProductSectionTitle('Reviews'),
        initiallyExpanded: expanded.value,
        onExpansionChanged: (v) => expanded.value = v,
        children: [
          Padding(
            padding: EdgeInsets.all(BaseSpacing.sm),
            child: _content(),
          ),
        ],
      ),
    );
  }

  Widget _content() {
    return Obx(() {
      if (controller.isLoadingReviews.value && controller.reviews.isEmpty) {
        return const _CenteredSpinner();
      }

      if (controller.reviews.isEmpty && controller.reviewSort.value == 'newest') {
        return Padding(
          padding: EdgeInsets.symmetric(vertical: BaseSpacing.md),
          child: CustomText(
            text: 'No reviews yet. Be the first to review this product!',
            textAlign: TextAlign.center,
            color: AppColors.gray600,
            fontSize: AppFontSize.tiny,
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sortChips(),
          SizedBox(height: BaseSpacing.sm),
          if (controller.isLoadingReviews.value)
            const _CenteredSpinner()
          else
            ...controller.reviews.map((r) => _ReviewTile(review: r, controller: controller, profileController: profileController)),
        ],
      );
    });
  }

  Widget _sortChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: ProductDetailController.reviewSortOptions.map((sort) {
          final selected = controller.reviewSort.value == sort;
          return Padding(
            padding: EdgeInsets.only(right: BaseSpacing.xs),
            child: GestureDetector(
              onTap: () => controller.changeReviewSort(sort),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: BaseSpacing.sm,
                  vertical: BaseSpacing.xxs,
                ),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primaryColor : AppColors.white,
                  borderRadius: BorderRadius.circular(BaseRadius.lg),
                  border: Border.all(
                    color: selected ? AppColors.primaryColor : AppColors.greySwatch400,
                  ),
                ),
                child: CustomText(
                  text: _sortLabels[sort] ?? sort,
                  color: selected ? AppColors.white : AppColors.gray600,
                  fontSize: AppFontSize.tiny,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _CenteredSpinner extends StatelessWidget {
  const _CenteredSpinner();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: BaseSpacing.xl),
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryColor),
        ),
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  final ReviewModel review;
  final ProductDetailController controller;
  final ProfileController profileController;

  const _ReviewTile({
    required this.review,
    required this.controller,
    required this.profileController,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: BaseSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Row(
              children: [
                Expanded(
                  child: CustomText(
                    text: review.customerName.isEmpty ? 'Anonymous' : review.customerName,
                    color: AppColors.black,
                    fontSize: AppFontSize.tiny,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (review.isVerifiedPurchase)
                  CustomText(
                    text: 'Verified Purchase',
                    color: AppColors.green2,
                    fontSize: AppFontSize.tiny,
                    fontWeight: FontWeight.w600,
                  ),
              ],
            ),
            subtitle: review.rating != null
                ? Padding(
                    padding: EdgeInsets.only(top: BaseSpacing.xxs),
                    child: CustomRatingBar(rating: review.rating!, itemSize: 15, ignoreGestures: true),
                  )
                : null,
          ),
          if (review.commentText.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(left: BaseSpacing.md, right: BaseSpacing.md, bottom: BaseSpacing.xxs),
              child: CustomText(
                text: review.commentText,
                color: AppColors.gray600,
                fontSize: AppFontSize.tiny,
              ),
            ),
          Padding(
            padding: EdgeInsets.only(left: BaseSpacing.md, bottom: BaseSpacing.xxs),
            child: GestureDetector(
              onTap: () {
                if (profileController.user.value.isNull) {
                  Get.toNamed(Routes.authTabView);
                  return;
                }
                controller.toggleReviewHelpful(review);
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    review.helpfulByMe ? Icons.thumb_up_alt : Icons.thumb_up_alt_outlined,
                    size: 16,
                    color: review.helpfulByMe ? AppColors.primaryColor : AppColors.gray600,
                  ),
                  SizedBox(width: BaseSpacing.xxs),
                  CustomText(
                    text: review.helpfulCount > 0 ? 'Helpful (${review.helpfulCount})' : 'Helpful',
                    color: review.helpfulByMe ? AppColors.primaryColor : AppColors.gray600,
                    fontSize: AppFontSize.tiny,
                    fontWeight: FontWeight.w600,
                  ),
                ],
              ),
            ),
          ),
          if (review.sellerReply != null)
            Container(
              margin: EdgeInsets.only(left: BaseSpacing.xxl, right: BaseSpacing.md, bottom: BaseSpacing.sm),
              padding: EdgeInsets.all(BaseSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(BaseRadius.sm),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    text: 'Store response',
                    color: AppColors.primaryColor,
                    fontSize: AppFontSize.tiny,
                    fontWeight: FontWeight.w700,
                  ),
                  SizedBox(height: BaseSpacing.xxs / 2),
                  CustomText(
                    text: review.sellerReply!.text,
                    color: AppColors.black2,
                    fontSize: AppFontSize.tiny,
                    fontWeight: FontWeight.w400,
                  ),
                ],
              ),
            ),
          const Divider(),
        ],
      ),
    );
  }
}
