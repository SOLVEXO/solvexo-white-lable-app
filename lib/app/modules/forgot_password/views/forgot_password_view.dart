import 'package:book_store_app/app/components/buttons/app_button.dart';
import 'package:book_store_app/app/components/custom_app_bar_two.dart';
import 'package:book_store_app/app/components/custom_text.dart';
import 'package:book_store_app/app/components/custom_text_field.dart';
import 'package:book_store_app/app/modules/forgot_password/controllers/forgot_password_controller.dart';
import 'package:book_store_app/config/resources/app_colors.dart';
import 'package:book_store_app/core/theme/base_spacing.dart';
import 'package:book_store_app/core/widgets/base_view_screen.dart';
import 'package:book_store_app/utils/app_font_size.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ForgotPasswordView extends StatelessWidget {
  const ForgotPasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ForgotPasswordController>();

    return BaseViewScreen(
      backgroundColor: AppColors.white,
      appBar: CustomAppBarTwo(backgroundColor: AppColors.white, iconColor: AppColors.black2),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(BaseSpacing.xl, BaseSpacing.md, BaseSpacing.xl, BaseSpacing.xl),
        child: Form(
          key: controller.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 64,
                width: 64,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(Icons.lock_reset_outlined, color: AppColors.primaryColor, size: 32),
              ),
              SizedBox(height: BaseSpacing.lg),
              CustomText(
                text: 'Forgot password?',
                color: AppColors.black2,
                fontSize: AppFontSize.veryLarge,
                fontWeight: FontWeight.bold,
              ),
              SizedBox(height: BaseSpacing.xxs),
              CustomText(
                text: "No worries — enter your email and we'll send you a reset code.",
                color: AppColors.gray600,
                fontSize: AppFontSize.small2,
                height: 1.4,
              ),
              SizedBox(height: BaseSpacing.xxl),
              CustomTextField(
                controller: controller.emailController,
                hintText: 'Email address',
                keyboardType: TextInputType.emailAddress,
                fillColor: AppColors.background,
                prefixIcon: Icon(Icons.mail_outline, color: AppColors.gray600, size: 20),
                validator: controller.validateEmail,
                onFieldSubmitted: (_) => controller.submit(),
              ),
              SizedBox(height: BaseSpacing.xl),
              Obx(
                () => AppButton(
                  label: controller.isLoading.value ? 'Sending...' : 'Send Reset Code',
                  onPressed: controller.isLoading.value ? null : controller.submit,
                  height: 52,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
