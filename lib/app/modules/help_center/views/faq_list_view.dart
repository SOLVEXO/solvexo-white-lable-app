import 'package:book_store_app/app/components/custom_app_bar_two.dart';
import 'package:book_store_app/app/components/custom_text.dart';
import 'package:book_store_app/app/routes/app_pages.dart';
import 'package:book_store_app/config/resources/app_colors.dart';
import 'package:book_store_app/core/theme/base_spacing.dart';
import 'package:book_store_app/core/widgets/buttons/base_buttons.dart';
import 'package:book_store_app/utils/app_font_size.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/help_center_controller.dart';
import '../widgets/faq_category_chips.dart';
import '../widgets/faq_status_list.dart';
import '../widgets/search_bar.dart';

class FAQListView extends StatelessWidget {
  const FAQListView({super.key});

  @override
  Widget build(BuildContext context) {
    Get.find<FaqController>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBarTwo(title: "FAQ"),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: BaseSpacing.sm),
            HelpSearchBar(),
            SizedBox(height: BaseSpacing.md),
            FaqCategoryChips(),
            SizedBox(height: BaseSpacing.sm),
            Expanded(
              child: FaqStatusList(
                onTapFaq: (faq) => Get.toNamed(Routes.faqDetailView, arguments: faq),
                footer: const _ContactFooterCard(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactFooterCard extends StatelessWidget {
  const _ContactFooterCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: BaseSpacing.xs),
      width: double.infinity,
      padding: EdgeInsets.all(BaseSpacing.md),
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
            color: AppColors.grey,
            fontSize: AppFontSize.tiny,
          ),
          SizedBox(height: BaseSpacing.md),
          OutlineButton(
            label: "Contact Support",
            icon: Icon(Icons.chat_bubble_outline_rounded, color: AppColors.primaryColor, size: 18),
            onPressed: () => Get.toNamed(Routes.contactUsView),
          ),
        ],
      ),
    );
  }
}
