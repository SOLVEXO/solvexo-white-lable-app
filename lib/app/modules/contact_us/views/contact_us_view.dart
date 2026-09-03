import 'package:book_store_app/app/components/custom_app_bar_two.dart';
import 'package:book_store_app/app/components/custom_text.dart';
import 'package:book_store_app/app/components/custom_text_field.dart';
import 'package:book_store_app/app/components/svg_icon.dart';
import 'package:book_store_app/app/modules/contact_us/controllers/contact_us_controller.dart';
import 'package:book_store_app/config/resources/app_colors.dart';
import 'package:book_store_app/config/resources/app_icons.dart';
import 'package:book_store_app/config/resources/app_text_styles.dart';
import 'package:book_store_app/core/theme/base_shadows.dart';
import 'package:book_store_app/core/theme/base_spacing.dart';
import 'package:book_store_app/core/widgets/buttons/base_buttons.dart';
import 'package:book_store_app/utils/app_font_size.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ContactUsView extends StatelessWidget {
  ContactUsView({super.key});

  final controller = Get.put(ContactUsController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBarTwo(title: 'Contact Us'),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(BaseSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ContactHeader(),
            SizedBox(height: BaseSpacing.lg),
            _ContactFormCard(controller: controller),
            SizedBox(height: BaseSpacing.xl),
            Obx(
              () => PrimaryButton(
                label: 'Send Message',
                icon: const SvgIcon(assetName: AppIcons.messageSendIcon, size: 18, color: AppColors.white),
                isLoading: controller.isSubmitting.value,
                onPressed: controller.isSubmitting.value ? null : controller.submit,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(BaseSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(BaseSpacing.md),
        border: Border.all(color: AppColors.primaryColor.withOpacity(0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: SvgIcon(assetName: AppIcons.messageIcon, size: 20, color: AppColors.primaryColor),
          ),
          SizedBox(width: BaseSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  text: "We're here to help",
                  color: AppColors.black,
                  fontFamily: AppTextStyles.headingFontFamily,
                  fontSize: AppFontSize.small,
                  fontWeight: FontWeight.w700,
                ),
                SizedBox(height: BaseSpacing.xxs),
                CustomText(
                  text: "Send us a message and our support team will get back "
                      "to you, usually within 24 hours.",
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

class _ContactFormCard extends StatelessWidget {
  final ContactUsController controller;
  const _ContactFormCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(BaseSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(BaseSpacing.md),
        boxShadow: BaseShadows.forLevel(BaseElevation.level1),
      ),
      child: Form(
        key: controller.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _fieldLabel('Your Name', required: true),
            SizedBox(height: BaseSpacing.xxs + 2),
            CustomTextField(
              hintText: 'e.g. Alex Morgan',
              controller: controller.nameController,
              validator: (v) => controller.validateRequired(v, 'your name'),
              isborder: true,
              fillColor: AppColors.textfldFillColor,
              prefixIcon: const SvgIcon(assetName: AppIcons.profileIcon, color: AppColors.greyDefault),
            ),
            SizedBox(height: BaseSpacing.md),
            _fieldLabel('Email Address', required: true),
            SizedBox(height: BaseSpacing.xxs + 2),
            CustomTextField(
              hintText: 'you@example.com',
              controller: controller.emailController,
              validator: controller.validateEmail,
              keyboardType: TextInputType.emailAddress,
              isborder: true,
              fillColor: AppColors.textfldFillColor,
              prefixIcon: const SvgIcon(assetName: AppIcons.emailIcon, color: AppColors.greyDefault),
            ),
            SizedBox(height: BaseSpacing.md),
            _fieldLabel('Topic', required: true),
            SizedBox(height: BaseSpacing.xxs + 2),
            CustomTextField(
              hintText: 'e.g. Order or delivery',
              controller: controller.topicController,
              validator: (v) => controller.validateRequired(v, 'a topic'),
              isborder: true,
              fillColor: AppColors.textfldFillColor,
              prefixIcon: const SvgIcon(assetName: AppIcons.messageIcon, color: AppColors.greyDefault),
            ),
            SizedBox(height: BaseSpacing.md),
            _fieldLabel('Message', required: true),
            SizedBox(height: BaseSpacing.xxs + 2),
            CustomTextField(
              hintText: "Tell us a bit about what's going on…",
              controller: controller.messageController,
              validator: (v) => controller.validateRequired(v, 'a message'),
              maxLines: 4,
              isborder: true,
              fillColor: AppColors.textfldFillColor,
              prefixIcon: const SvgIcon(assetName: AppIcons.messageIcon, color: AppColors.greyDefault),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _fieldLabel(String text, {bool required = false}) {
  return Row(
    children: [
      CustomText(
        text: text,
        fontSize: AppFontSize.verySmall,
        fontWeight: FontWeight.w600,
        color: AppColors.black2,
      ),
      if (required)
        const CustomText(
          text: ' *',
          fontSize: AppFontSize.verySmall,
          fontWeight: FontWeight.w600,
          color: AppColors.red,
        ),
    ],
  );
}
