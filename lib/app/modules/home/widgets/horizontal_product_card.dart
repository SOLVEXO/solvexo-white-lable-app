import 'package:book_store_app/app/components/common_image_view.dart';
import 'package:book_store_app/app/components/custom_text.dart';
import 'package:book_store_app/app/components/svg_icon.dart';
import 'package:book_store_app/app/data/services/currency_controller.dart';
import 'package:book_store_app/app/modules/category/models/product_model.dart';
import 'package:book_store_app/config/resources/app_colors.dart';
import 'package:book_store_app/config/resources/app_icons.dart';
import 'package:book_store_app/core/theme/base_shadows.dart';
import 'package:book_store_app/core/theme/base_spacing.dart';
import 'package:book_store_app/utils/app_font_size.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HorizontalProductCard extends StatelessWidget {
  final ProductModel prod;
  final Function()? onTap;
  HorizontalProductCard({super.key, this.onTap, required this.prod});

  CurrencyController get currencyController {
    if (!Get.isRegistered<CurrencyController>()) {
      Get.put(CurrencyController(), permanent: true);
    }
    return Get.find<CurrencyController>();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        margin: EdgeInsets.only(bottom: BaseSpacing.sm + 1),
        decoration: BoxDecoration(
          color: AppColors.white,
          boxShadow: BaseShadows.forLevel(BaseElevation.level1),
          borderRadius: BorderRadius.circular(BaseRadius.md),
        ),
        padding: EdgeInsets.all(BaseSpacing.sm),
        child: Row(
          children: [
            Container(
              width: 95,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(BaseRadius.md),
                boxShadow: BaseShadows.forLevel(BaseElevation.level1),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  prod.images.isNotEmpty
                      ? CommonImageView(url: prod.images.first, width: 50)
                      : const Icon(Icons.image_outlined, color: AppColors.lightGrey7, size: 30),
                  if (prod.isOnSale)
                    Positioned(
                      top: 4,
                      left: 4,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: BaseSpacing.xxs + 2, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.red,
                          borderRadius: BorderRadius.circular(BaseRadius.sm),
                        ),
                        child: CustomText(
                          text: prod.activeCampaign!.badgeLabel,
                          color: AppColors.white,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(width: BaseSpacing.xs + 2),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(text: prod.name, color: AppColors.black, fontSize: AppFontSize.extraSmall, fontWeight: FontWeight.w600),
                  CustomText(
                    text: prod.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    color: AppColors.black54,
                    fontSize: AppFontSize.tiny,
                    fontWeight: FontWeight.w400,
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: 5,
                            itemBuilder: (context, index) {
                              return SvgIcon(assetName: AppIcons.fillStar, size: 13);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  Obx(
                    () => CustomText(
                      text: currencyController.format(prod.price, prod.currency),
                      color: AppColors.black,
                      fontSize: AppFontSize.extraSmall,
                      fontWeight: FontWeight.w600,
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
