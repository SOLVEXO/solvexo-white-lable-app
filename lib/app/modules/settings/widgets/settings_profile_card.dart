import 'package:book_store_app/app/components/custom_text.dart';
import 'package:book_store_app/app/modules/settings/controllers/settings_controller.dart';
import 'package:book_store_app/app/routes/app_pages.dart';
import 'package:book_store_app/config/resources/app_colors.dart';
import 'package:book_store_app/config/resources/app_text_styles.dart';
import 'package:book_store_app/utils/app_font_size.dart';
import 'package:book_store_app/utils/dimens.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SettingsProfileCard extends StatelessWidget {
  final SettingsController controller;
  const SettingsProfileCard({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(AppDimen.allPadding),
      padding: const EdgeInsets.all(AppDimen.allPadding),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimen.serviceCountTileRadius),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Obx(() => Row(children: [
        // Avatar
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: CustomText(
            text: controller.initials,
            fontSize: AppFontSize.medium,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryColor,
          ),
        ),
        const SizedBox(width: 14),
        // Name + email
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          CustomText(
            text: controller.name.value.isEmpty ? 'User' : controller.name.value,
            fontSize: AppFontSize.small,
            fontWeight: FontWeight.bold,
            color: AppColors.black,
          ),
          const SizedBox(height: 3),
          CustomText(
            text: controller.email.value.isEmpty ? '—' : controller.email.value,
            fontSize: AppFontSize.verySmall,
            color: AppColors.grey,
          ),
          const SizedBox(height: 6),
          // Buyer badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(AppDimen.draggableBorderRadius),
              border: Border.all(color: AppColors.primaryColor.withOpacity(0.25)),
            ),
            child: CustomText(
              text: 'Buyer Account',
              fontSize: AppFontSize.tiny,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryColor,
              fontFamily: AppTextStyles.monoFontFamily,
            ),
          ),
        ])),
        const SizedBox(width: 10),
        // Edit button
        GestureDetector(
          onTap: () => Get.toNamed(Routes.editProfileView),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(AppDimen.borderRadius),
              border: Border.all(color: AppColors.lightGrey2),
            ),
            child: const CustomText(
              text: 'Edit',
              fontSize: AppFontSize.verySmall,
              fontWeight: FontWeight.w600,
              color: AppColors.black2,
            ),
          ),
        ),
      ])),
    );
  }
}
