import 'package:book_store_app/app/components/custom_text.dart';
import 'package:book_store_app/app/data/services/branding_service.dart';
import 'package:book_store_app/app/routes/app_pages.dart';
import 'package:book_store_app/config/resources/app_colors.dart';
import 'package:book_store_app/config/resources/app_icons.dart';
import 'package:book_store_app/app/components/svg_icon.dart';
import 'package:book_store_app/core/theme/base_animations.dart';
import 'package:book_store_app/core/theme/base_spacing.dart';
import 'package:book_store_app/utils/app_font_size.dart';
import 'package:book_store_app/utils/dimens.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Small, non-intrusive "become a seller" nudge for guests — deliberately
/// low-key (outlined, not the primary gradient treatment) so it never
/// competes with the buyer login banner for attention.
class SellOnSolvexoCard extends StatelessWidget {
  const SellOnSolvexoCard({super.key});

  @override
  Widget build(BuildContext context) {
    final marketplaceName = Get.find<BrandingService>().config.value.marketplaceName;
    return Semantics(
      button: true,
      label: 'Sell on $marketplaceName',
      child: PressableScale(
        onTap: () => Get.toNamed(Routes.welcome),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: BaseSpacing.md,
            vertical: BaseSpacing.sm + 2,
          ),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(AppDimen.serviceCountTileRadius),
            border: Border.all(color: AppColors.lightGrey2),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(BaseRadius.sm),
                ),
                alignment: Alignment.center,
                child: SvgIcon(
                  assetName: AppIcons.cashIcon,
                  size: 20,
                  color: AppColors.primaryColor,
                ),
              ),
              SizedBox(width: BaseSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      text: 'Have something to sell?',
                      color: AppColors.black,
                      fontSize: AppFontSize.verySmall,
                      fontWeight: FontWeight.w600,
                    ),
                    CustomText(
                      text: 'Open your store on $marketplaceName',
                      color: AppColors.grey,
                      fontSize: AppFontSize.tiny,
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: AppColors.lightGrey5,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
