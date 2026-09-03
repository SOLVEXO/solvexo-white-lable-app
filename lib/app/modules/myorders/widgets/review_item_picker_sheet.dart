import 'package:book_store_app/app/components/common_image_view.dart';
import 'package:book_store_app/app/components/custom_text.dart';
import 'package:book_store_app/app/modules/myorders/models/my_order_model.dart';
import 'package:book_store_app/app/routes/app_pages.dart';
import 'package:book_store_app/config/resources/app_colors.dart';
import 'package:book_store_app/core/theme/base_spacing.dart';
import 'package:book_store_app/utils/app_font_size.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Lets the buyer pick which line item to review when an order has more
/// than one — a single-item order skips this and goes straight to
/// [Routes.reviewsView].
class ReviewItemPickerSheet {
  ReviewItemPickerSheet._();

  static void show(BuildContext context, OrderModel order) {
    final items = order.unreviewedItems;
    if (items.isEmpty) return;

    if (items.length == 1) {
      Get.toNamed(Routes.reviewsView, arguments: {'orderId': order.orderId, 'item': items.first});
      return;
    }

    Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(BaseRadius.xxl)),
        ),
        padding: EdgeInsets.fromLTRB(0, BaseSpacing.sm, 0, MediaQuery.of(context).padding.bottom + BaseSpacing.xs),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: EdgeInsets.only(bottom: BaseSpacing.sm),
              decoration: BoxDecoration(color: AppColors.lightGrey2, borderRadius: BorderRadius.circular(BaseRadius.xs / 2)),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(BaseSpacing.xl, 0, BaseSpacing.xl, BaseSpacing.sm),
              child: Align(
                alignment: Alignment.centerLeft,
                child: CustomText(
                  text: 'Which item would you like to review?',
                  color: AppColors.black2,
                  fontSize: AppFontSize.extraSmall,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ...items.map(
              (item) => ListTile(
                onTap: () {
                  Get.back();
                  Get.toNamed(Routes.reviewsView, arguments: {'orderId': order.orderId, 'item': item});
                },
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(BaseRadius.sm),
                  child: CommonImageView(url: item.image ?? '', width: 44, height: 44, fit: BoxFit.cover),
                ),
                title: CustomText(
                  text: item.name,
                  color: AppColors.black,
                  fontSize: AppFontSize.tiny,
                  fontWeight: FontWeight.w600,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
      backgroundColor: AppColors.transparent,
      isScrollControlled: true,
    );
  }
}
