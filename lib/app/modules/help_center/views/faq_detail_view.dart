import 'package:book_store_app/app/components/custom_app_bar_two.dart';
import 'package:book_store_app/app/components/custom_text.dart';
import 'package:book_store_app/app/components/svg_icon.dart';
import 'package:book_store_app/app/routes/app_pages.dart';
import 'package:book_store_app/config/resources/app_colors.dart';
import 'package:book_store_app/config/resources/app_icons.dart';
import 'package:book_store_app/core/theme/base_shadows.dart';
import 'package:book_store_app/core/theme/base_spacing.dart';
import 'package:book_store_app/core/widgets/buttons/base_buttons.dart';
import 'package:book_store_app/utils/app_font_size.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import '../models/faq_model.dart';

class FAQDetailView extends StatelessWidget {
  const FAQDetailView({super.key});

  String _capitalize(String value) =>
      value.isEmpty ? value : '${value[0].toUpperCase()}${value.substring(1)}';

  @override
  Widget build(BuildContext context) {
    final FaqModel faq = Get.arguments;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBarTwo(
        title: "FAQ",
        actions: [
          Padding(
            padding: EdgeInsets.only(right: BaseSpacing.md),
            child: SvgIcon(
              assetName: AppIcons.shareIcon,
              size: 20,
              color: AppColors.black,
              onTap: () => SharePlus.instance.share(
                ShareParams(text: '${faq.question}\n\n${faq.answer}'),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(BaseSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (faq.category.isNotEmpty)
              Container(
                padding: EdgeInsets.symmetric(horizontal: BaseSpacing.sm, vertical: BaseSpacing.xxs),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(BaseRadius.pill),
                ),
                child: CustomText(
                  text: _capitalize(faq.category),
                  color: AppColors.primaryColor,
                  fontSize: AppFontSize.tiny,
                  fontWeight: FontWeight.w600,
                ),
              ),
            SizedBox(height: BaseSpacing.md),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(BaseSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(BaseRadius.lg),
                boxShadow: BaseShadows.level1,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: SvgIcon(assetName: AppIcons.faqIcon, size: 16, color: AppColors.primaryColor),
                      ),
                      SizedBox(width: BaseSpacing.sm),
                      Expanded(
                        child: CustomText(
                          text: faq.question,
                          color: AppColors.black,
                          fontSize: AppFontSize.regular,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: BaseSpacing.md),
                  Divider(height: 1, thickness: 1, color: AppColors.lightGrey2),
                  SizedBox(height: BaseSpacing.md),
                  CustomText(
                    text: faq.answer,
                    color: AppColors.black2,
                    fontSize: AppFontSize.extraSmall,
                    fontWeight: FontWeight.w400,
                  ),
                ],
              ),
            ),
            SizedBox(height: BaseSpacing.xl),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(BaseSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(0.06),
                borderRadius: BorderRadius.circular(BaseRadius.lg),
                border: Border.all(color: AppColors.primaryColor.withOpacity(0.15)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    text: "Still need help?",
                    color: AppColors.black,
                    fontSize: AppFontSize.small,
                    fontWeight: FontWeight.w600,
                  ),
                  SizedBox(height: BaseSpacing.xxs),
                  CustomText(
                    text: "Can't find what you're looking for? Our support team is happy to help.",
                    color: AppColors.greyDefault,
                    fontSize: AppFontSize.tiny,
                  ),
                  SizedBox(height: BaseSpacing.md),
                  OutlineButton(
                    label: "Contact Support",
                    icon: SvgIcon(assetName: AppIcons.messageIcon, size: 18, color: AppColors.primaryColor),
                    onPressed: () => Get.toNamed(Routes.contactUsView),
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
