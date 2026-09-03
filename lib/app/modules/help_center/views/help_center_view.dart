import 'package:book_store_app/app/components/custom_app_bar_two.dart';
import 'package:book_store_app/app/components/custom_text.dart';
import 'package:book_store_app/app/components/svg_icon.dart';
import 'package:book_store_app/app/modules/help_center/controllers/help_center_controller.dart';
import 'package:book_store_app/app/modules/help_center/widgets/search_bar.dart';
import 'package:book_store_app/app/routes/app_pages.dart';
import 'package:book_store_app/config/resources/app_colors.dart';
import 'package:book_store_app/config/resources/app_icons.dart';
import 'package:book_store_app/core/theme/base_spacing.dart';
import 'package:book_store_app/core/widgets/buttons/base_buttons.dart';
import 'package:book_store_app/utils/app_font_size.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../widgets/faq_status_list.dart';

class HelpCenterView extends StatelessWidget {
  HelpCenterView({super.key});
  final controller = Get.put(FaqController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBarTwo(title: "Help Centre"),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(BaseSpacing.md, BaseSpacing.md, BaseSpacing.md, 0),
              child: _HelpHero(),
            ),
            SizedBox(height: BaseSpacing.lg),
            HelpSearchBar(),
            SizedBox(height: BaseSpacing.md),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: BaseSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CustomText(
                    text: "Related FAQs",
                    color: AppColors.black,
                    fontSize: AppFontSize.extraSmall,
                    fontWeight: FontWeight.w700,
                  ),
                  GhostButton(label: "View all topics", onPressed: () => Get.toNamed(Routes.faqListView)),
                ],
              ),
            ),
            Expanded(
              child: FaqStatusList(
                onTapFaq: (faq) => Get.toNamed(Routes.faqDetailView, arguments: faq),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HelpHero extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(BaseSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryColor.withOpacity(0.10), AppColors.primaryColor.withOpacity(0.03)],
        ),
        borderRadius: BorderRadius.circular(BaseRadius.lg),
        border: Border.all(color: AppColors.primaryColor.withOpacity(0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: SvgIcon(assetName: AppIcons.faqIcon, size: 22, color: AppColors.primaryColor),
          ),
          SizedBox(width: BaseSpacing.sm + 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  text: "How can we help?",
                  color: AppColors.black,
                  fontSize: AppFontSize.small,
                  fontWeight: FontWeight.w700,
                ),
                SizedBox(height: BaseSpacing.xxs),
                CustomText(
                  text: "Search common questions or browse everything we've written down for you.",
                  color: AppColors.greyDefault,
                  fontSize: AppFontSize.tiny,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
