import 'package:book_store_app/app/components/buttons/app_button.dart';
import 'package:book_store_app/app/components/custom_app_bar_two.dart';
import 'package:book_store_app/app/components/custom_text.dart';
import 'package:book_store_app/app/components/custom_text_field.dart';
import 'package:book_store_app/app/modules/reset_password/controllers/reset_password_controller.dart';
import 'package:book_store_app/config/resources/app_colors.dart';
import 'package:book_store_app/core/theme/base_spacing.dart';
import 'package:book_store_app/core/widgets/base_view_screen.dart';
import 'package:book_store_app/utils/app_font_size.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ResetPasswordView extends StatelessWidget {
  const ResetPasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ResetPasswordController>();

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
              CustomText(
                text: 'Reset password',
                color: AppColors.black2,
                fontSize: AppFontSize.veryLarge,
                fontWeight: FontWeight.bold,
              ),
              SizedBox(height: BaseSpacing.xxs),
              CustomText(
                text: 'Enter the code sent to ${controller.email} and choose a new password.',
                color: AppColors.gray600,
                fontSize: AppFontSize.small2,
                height: 1.4,
              ),
              SizedBox(height: BaseSpacing.xxl),
              CustomTextField(
                controller: controller.otpController,
                hintText: '6-digit code',
                keyboardType: TextInputType.number,
                fillColor: AppColors.background,
                prefixIcon: Icon(Icons.pin_outlined, color: AppColors.gray600, size: 20),
                validator: controller.validateOtp,
              ),
              SizedBox(height: BaseSpacing.sm),
              Obx(
                () => CustomTextField(
                  controller: controller.passwordController,
                  hintText: 'New password',
                  obscureText: controller.obscurePassword.value,
                  fillColor: AppColors.background,
                  prefixIcon: Icon(Icons.lock_outline, color: AppColors.gray600, size: 20),
                  suffixIcon: GestureDetector(
                    onTap: () => controller.obscurePassword.toggle(),
                    child: Icon(
                      controller.obscurePassword.value ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: AppColors.gray600,
                      size: 20,
                    ),
                  ),
                  validator: controller.validatePassword,
                ),
              ),
              SizedBox(height: BaseSpacing.sm),
              Obx(
                () => CustomTextField(
                  controller: controller.confirmPasswordController,
                  hintText: 'Confirm new password',
                  obscureText: controller.obscureConfirmPassword.value,
                  fillColor: AppColors.background,
                  prefixIcon: Icon(Icons.lock_outline, color: AppColors.gray600, size: 20),
                  suffixIcon: GestureDetector(
                    onTap: () => controller.obscureConfirmPassword.toggle(),
                    child: Icon(
                      controller.obscureConfirmPassword.value
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppColors.gray600,
                      size: 20,
                    ),
                  ),
                  validator: controller.validateConfirmPassword,
                ),
              ),
              SizedBox(height: BaseSpacing.xl),
              Obx(
                () => AppButton(
                  label: controller.isLoading.value ? 'Resetting...' : 'Reset Password',
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
