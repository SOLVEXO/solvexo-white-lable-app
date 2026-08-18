import 'package:book_store_app/app/components/custom_text.dart';
import 'package:book_store_app/app/components/custom_text_field.dart';
import 'package:book_store_app/app/data/services/branding_service.dart';
import 'package:book_store_app/config/resources/app_colors.dart';
import 'package:book_store_app/core/theme/base_spacing.dart';
import 'package:book_store_app/core/widgets/buttons/base_buttons.dart';
import 'package:book_store_app/utils/app_font_size.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:solvexo_pos/app/modules/pos_login/controllers/pos_login_controller.dart';

class PosLoginView extends StatelessWidget {
  const PosLoginView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PosLoginController>();

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: BaseSpacing.xl,
            vertical: BaseSpacing.xxl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: BaseSpacing.xxxl),
              CustomText(
                text: '${Get.find<BrandingService>().config.value.appName} POS',
                fontSize: AppFontSize.veryLarge3,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryColor,
              ),
              SizedBox(height: BaseSpacing.xs),
              CustomText(
                text: 'Sign in with your seller account',
                fontSize: AppFontSize.small2,
                color: AppColors.grey,
              ),
              SizedBox(height: BaseSpacing.xxl),
              CustomText(
                text: 'Email',
                fontSize: AppFontSize.extraSmall,
                fontWeight: FontWeight.w600,
              ),
              SizedBox(height: BaseSpacing.xs),
              CustomTextField(
                controller: controller.emailController,
                hintText: 'you@example.com',
                fillColor: AppColors.lightGrey3,
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: BaseSpacing.md),
              CustomText(
                text: 'Password',
                fontSize: AppFontSize.extraSmall,
                fontWeight: FontWeight.w600,
              ),
              SizedBox(height: BaseSpacing.xs),
              Obx(
                () => CustomTextField(
                  controller: controller.passwordController,
                  hintText: 'Password',
                  fillColor: AppColors.lightGrey3,
                  obscureText: controller.obscurePassword.value,
                  onFieldSubmitted: (_) => controller.login(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      controller.obscurePassword.value
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppColors.grey,
                    ),
                    onPressed: controller.toggleObscurePassword,
                  ),
                ),
              ),
              SizedBox(height: BaseSpacing.xxl),
              Obx(
                () => PrimaryButton(
                  label: controller.isLoading.value ? 'Logging in...' : 'Log in',
                  isLoading: controller.isLoading.value,
                  onPressed: controller.isLoading.value ? null : controller.login,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
