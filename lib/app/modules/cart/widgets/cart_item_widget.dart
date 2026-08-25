import 'package:book_store_app/app/components/common_image_view.dart';
import 'package:book_store_app/app/components/custom_icon_button.dart';
import 'package:book_store_app/app/components/custom_text.dart';
import 'package:book_store_app/app/components/icon_with_text.dart';
import 'package:book_store_app/app/data/services/currency_controller.dart';
import 'package:book_store_app/app/modules/cart/controllers/cart_controller.dart';
import 'package:book_store_app/app/modules/cart/models/cart_response_model.dart';
import 'package:book_store_app/app/modules/cart/widgets/inc_dicr_quantity_widget.dart';
import 'package:book_store_app/config/resources/app_colors.dart';
import 'package:book_store_app/config/resources/app_icons.dart';
import 'package:book_store_app/config/resources/app_text_styles.dart';
import 'package:book_store_app/core/theme/base_spacing.dart';
import 'package:book_store_app/utils/app_font_size.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CartItemWidget extends StatelessWidget {
  final CartItem item;
  CartItemWidget({super.key, required this.item});

  final controller = Get.find<CartController>();

  CurrencyController get currencyController {
    if (!Get.isRegistered<CurrencyController>()) {
      Get.put(CurrencyController(), permanent: true);
    }
    return Get.find<CurrencyController>();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: BaseSpacing.sm, vertical: BaseSpacing.xs),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                activeColor: AppColors.primaryColor,
                materialTapTargetSize: MaterialTapTargetSize.padded,
                value: item.isSelected,
                onChanged: (v) => controller.toggleItemSelection(item, v!),
              ),

              /// Product Image
              CommonImageView(
                url: item.displayImage,
                width: 70,
                height: 70,
                fit: BoxFit.cover,
                radius: BorderRadius.circular(BaseRadius.sm),
              ),

              SizedBox(width: BaseSpacing.xs + 2),

              /// Product Info
              Expanded(
                child: Column(
                  spacing: BaseSpacing.xxs + 1,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      text: item.name,
                      color: AppColors.black,
                      fontSize: AppFontSize.tiny,
                      fontWeight: FontWeight.bold,
                    ),
                    if (item.options.isNotEmpty)
                      CustomText(
                        text: item.options.map((o) => '${o.name}: ${o.value}').join('  ·  '),
                        color: AppColors.gray600,
                        fontSize: AppFontSize.tiny,
                      ),
                    CustomText(text: "${item.quantity} Item", color: AppColors.gray600, fontSize: AppFontSize.tiny),
                    Obx(
                      () => CustomText(
                        text: currencyController.format(item.actualPrice, item.currency),
                        color: AppColors.black,
                        fontSize: AppFontSize.small,
                        fontWeight: FontWeight.bold,
                        fontFamily: AppTextStyles.monoFontFamily,
                      ),
                    ),
                  ],
                ),
              ),

              /// Delete — productId is now non-nullable
              CustomIconButton(
                assetName: AppIcons.deleteIcon,
                size: 30,
                isPadding: true,
                onPressed: () {
                  controller.showDeleteConfirmation(
                    onLeftButtonTap: () => controller.showWishListConformation(
                      onRightButtonTap: () => controller.moveToWishlist(item),
                    ),
                    onRightButtonTap: () => controller.removeFromCart(item.productId, item.productVariantId),
                  );
                },
              ),
            ],
          ),
          Row(
            spacing: BaseSpacing.xl,
            children: [
              IconWithText(
                iconName: AppIcons.heartIcon,
                text: "WishList",
                onTap: () => controller.showWishListConformation(
                  onRightButtonTap: () => controller.moveToWishlist(item),
                ),
              ),
              IconWithText(
                iconName: AppIcons.deleteIcon,
                text: "Delete",
                onTap: () => controller.showDeleteConfirmation(
                  onLeftButtonTap: () => controller.showWishListConformation(
                    onRightButtonTap: () => controller.moveToWishlist(item),
                  ),
                  onRightButtonTap: () => controller.removeFromCart(item.productId, item.productVariantId),
                ),
              ),
              Expanded(child: IncDicrQuantityWidget(item: item)),
            ],
          ),
        ],
      ),
    );
  }
}
