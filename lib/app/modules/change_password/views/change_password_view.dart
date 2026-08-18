import 'package:book_store_app/app/components/custom_app_bar_two.dart';
import 'package:book_store_app/app/components/custom_text.dart';
import 'package:book_store_app/app/components/custom_text_field.dart';
import 'package:book_store_app/app/components/svg_icon.dart';
import 'package:book_store_app/app/modules/profile/controllers/profile_controller.dart';
import 'package:book_store_app/config/resources/app_colors.dart';
import 'package:book_store_app/config/resources/app_icons.dart';
import 'package:book_store_app/core/theme/base_animations.dart';
import 'package:book_store_app/core/theme/base_shadows.dart';
import 'package:book_store_app/core/theme/base_spacing.dart';
import 'package:book_store_app/core/widgets/base_view_screen.dart';
import 'package:book_store_app/core/widgets/buttons/base_buttons.dart';
import 'package:book_store_app/utils/app_font_size.dart';
import 'package:flutter/material.dart';

import 'package:get/get.dart';

// NOTE (architecture): this screen's own `ChangePasswordController` is dead
// code (an empty GetxController) — all real logic lives on the shared
// `ProfileController`, found here rather than owned by this module. Left
// as-is for this pass since consolidating it needs a full trace of every
// place `ProfileController.changePassword` is called; flagging for a
// dedicated cleanup rather than risking an untested rewire.
class ChangePasswordView extends StatelessWidget {
  const ChangePasswordView({super.key});
  @override
  Widget build(BuildContext context) {
    // Was `Get.put(ProfileController())` — since ProfileController is a
    // shared/permanent controller already created by the Profile screen,
    // `Get.put` here would replace that live instance every time this
    // screen builds. `Get.find` reuses it instead.
    final profileController = Get.find<ProfileController>();
    return BaseViewScreen(
      backgroundColor: AppColors.background,
      appBar: CustomAppBarTwo(title: "Change Password"),
      padding: EdgeInsets.all(BaseSpacing.md),
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Form(
          key: profileController.passwordFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SecurityHero(),
              SizedBox(height: BaseSpacing.lg),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(BaseSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(BaseRadius.lg),
                  boxShadow: BaseShadows.forLevel(BaseElevation.level1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fieldLabel('Current Password'),
                    SizedBox(height: BaseSpacing.xs),
                    Obx(
                      () => CustomTextField(
                        controller: profileController.currentPasswordController,
                        obscureText: !profileController.showCurrentPassword.value,
                        hintText: 'Enter your current password',
                        prefixIcon: const SvgIcon(assetName: AppIcons.lockPassword, color: AppColors.grey),
                        suffixIcon: SvgIcon(
                          assetName: profileController.showCurrentPassword.value
                              ? AppIcons.showPassword
                              : AppIcons.hidePassword,
                          onTap: () => profileController.showCurrentPassword.toggle(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter current password';
                          }
                          return null;
                        },
                        isborder: true,
                        fillColor: AppColors.textfldFillColor,
                      ),
                    ),
                    SizedBox(height: BaseSpacing.md),
                    Divider(height: 1, thickness: 1, color: AppColors.lightGrey2),
                    SizedBox(height: BaseSpacing.md),
                    _fieldLabel('New Password'),
                    SizedBox(height: BaseSpacing.xs),
                    Obx(
                      () => CustomTextField(
                        controller: profileController.newPasswordController,
                        obscureText: !profileController.showNewPassword.value,
                        hintText: 'Set a new password',
                        prefixIcon: const SvgIcon(assetName: AppIcons.lockPassword, color: AppColors.grey),
                        suffixIcon: SvgIcon(
                          assetName: profileController.showNewPassword.value
                              ? AppIcons.showPassword
                              : AppIcons.hidePassword,
                          onTap: () => profileController.showNewPassword.toggle(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter new password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                        isborder: true,
                        fillColor: AppColors.textfldFillColor,
                      ),
                    ),
                    SizedBox(height: BaseSpacing.sm),
                    _PasswordStrengthMeter(controller: profileController.newPasswordController),
                    SizedBox(height: BaseSpacing.md),
                    _fieldLabel('Confirm New Password'),
                    SizedBox(height: BaseSpacing.xs),
                    Obx(
                      () => CustomTextField(
                        controller: profileController.confirmPasswordController,
                        obscureText: !profileController.showConfirmPassword.value,
                        hintText: 'Re-enter the new password',
                        prefixIcon: const SvgIcon(assetName: AppIcons.lockPassword, color: AppColors.grey),
                        suffixIcon: SvgIcon(
                          assetName: profileController.showConfirmPassword.value
                              ? AppIcons.showPassword
                              : AppIcons.hidePassword,
                          onTap: () => profileController.showConfirmPassword.toggle(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please confirm password';
                          }
                          if (value != profileController.newPasswordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                        isborder: true,
                        fillColor: AppColors.textfldFillColor,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: BaseSpacing.lg),
              Obx(
                () => PrimaryButton(
                  label: profileController.isUpdating.value ? "Updating..." : "Update Password",
                  isLoading: profileController.isUpdating.value,
                  onPressed: profileController.isUpdating.value ? null : profileController.changePassword,
                ),
              ),
              SizedBox(height: BaseSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shield_outlined, size: 14, color: AppColors.lightGrey),
                  SizedBox(width: BaseSpacing.xxs),
                  Flexible(
                    child: CustomText(
                      text: "Choose a strong password you don't use anywhere else.",
                      color: AppColors.lightGrey,
                      fontSize: AppFontSize.tiny,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _fieldLabel(String text) {
  return CustomText(
    text: text,
    fontSize: AppFontSize.verySmall,
    fontWeight: FontWeight.w600,
    color: AppColors.black2,
  );
}

class _SecurityHero extends StatelessWidget {
  const _SecurityHero();

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
            child: SvgIcon(assetName: AppIcons.changePassword, size: 20, color: AppColors.primaryColor),
          ),
          SizedBox(width: BaseSpacing.sm + 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  text: "Keep your account secure",
                  color: AppColors.black,
                  fontSize: AppFontSize.small,
                  fontWeight: FontWeight.w700,
                ),
                SizedBox(height: BaseSpacing.xxs),
                CustomText(
                  text: "Enter your current password, then set a new one.",
                  color: AppColors.grey,
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

enum _PasswordStrength { empty, weak, fair, strong }

_PasswordStrength _strengthOf(String value) {
  if (value.isEmpty) return _PasswordStrength.empty;
  var score = 0;
  if (value.length >= 6) score++;
  if (value.length >= 10) score++;
  if (RegExp(r'[A-Z]').hasMatch(value) && RegExp(r'[a-z]').hasMatch(value)) score++;
  if (RegExp(r'[0-9]').hasMatch(value)) score++;
  if (RegExp(r'[^A-Za-z0-9]').hasMatch(value)) score++;
  if (score <= 1) return _PasswordStrength.weak;
  if (score <= 3) return _PasswordStrength.fair;
  return _PasswordStrength.strong;
}

/// Live strength feedback computed from the actual text already typed into
/// [controller] — no network round-trip, so it updates as the user types.
class _PasswordStrengthMeter extends StatelessWidget {
  final TextEditingController controller;
  const _PasswordStrengthMeter({required this.controller});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final strength = _strengthOf(value.text);
        if (strength == _PasswordStrength.empty) return const SizedBox.shrink();

        final (label, color, filledBars) = switch (strength) {
          _PasswordStrength.weak => ('Weak', AppColors.error, 1),
          _PasswordStrength.fair => ('Fair', AppColors.orange, 2),
          _PasswordStrength.strong => ('Strong', AppColors.greenSuccess, 3),
          _PasswordStrength.empty => ('', AppColors.lightGrey2, 0),
        };

        return Row(
          children: [
            for (var i = 0; i < 3; i++) ...[
              Expanded(
                child: AnimatedContainer(
                  duration: BaseMotion.fast,
                  height: 4,
                  decoration: BoxDecoration(
                    color: i < filledBars ? color : AppColors.lightGrey2,
                    borderRadius: BorderRadius.circular(BaseRadius.pill),
                  ),
                ),
              ),
              if (i < 2) SizedBox(width: BaseSpacing.xxs),
            ],
            SizedBox(width: BaseSpacing.sm),
            CustomText(text: label, color: color, fontSize: AppFontSize.tiny, fontWeight: FontWeight.w600),
          ],
        );
      },
    );
  }
}
