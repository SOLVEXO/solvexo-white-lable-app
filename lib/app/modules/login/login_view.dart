import 'package:book_store_app/app/components/buttons/app_button.dart';
import 'package:book_store_app/app/components/custom_text.dart';
import 'package:book_store_app/app/components/custom_text_field.dart';
import 'package:book_store_app/app/components/svg_icon.dart';
import 'package:book_store_app/app/modules/auth/controller/auth_controller.dart';
import 'package:book_store_app/app/modules/login/controllers/login_controller.dart';
import 'package:book_store_app/config/resources/app_colors.dart';
import 'package:book_store_app/config/resources/app_icons.dart';
import 'package:book_store_app/core/theme/base_spacing.dart';
import 'package:book_store_app/utils/app_font_size.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// The merged Login / Sign-up screen — a segmented toggle switches between
/// email+password login and signup, with "Continue with Google" underneath
/// as the one-tap alternative to both.
class LoginView extends StatelessWidget {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<LoginController>();
    final authController = Get.find<AuthController>();

    return Form(
      key: controller.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _ModeToggle(),
          SizedBox(height: BaseSpacing.xl),
          Obx(
            () => AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              child: controller.isSignUpMode.value
                  ? Column(
                      key: const ValueKey('signup-fields'),
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _FieldLabel('Full name'),
                        CustomTextField(
                          controller: controller.nameController,
                          hintText: 'Jamie Doe',
                          fillColor: AppColors.background,
                          prefixIcon: Icon(Icons.person_outline, color: AppColors.gray600, size: 20),
                          validator: controller.validateName,
                        ),
                        SizedBox(height: BaseSpacing.sm),
                      ],
                    )
                  : const SizedBox.shrink(key: ValueKey('no-signup-fields')),
            ),
          ),
          _FieldLabel('Email'),
          CustomTextField(
            controller: controller.emailController,
            hintText: 'you@example.com',
            keyboardType: TextInputType.emailAddress,
            fillColor: AppColors.background,
            prefixIcon: Icon(Icons.mail_outline, color: AppColors.gray600, size: 20),
            validator: controller.validateEmail,
          ),
          SizedBox(height: BaseSpacing.sm),
          _FieldLabel('Password'),
          Obx(
            () => CustomTextField(
              controller: controller.passwordController,
              hintText: 'At least 8 characters',
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
          Obx(
            () => AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              child: controller.isSignUpMode.value
                  ? Column(
                      key: const ValueKey('confirm-password-field'),
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(height: BaseSpacing.sm),
                        _FieldLabel('Confirm password'),
                        Obx(
                          () => CustomTextField(
                            controller: controller.confirmPasswordController,
                            hintText: 'Re-enter your password',
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
                      ],
                    )
                  : Align(
                      key: const ValueKey('forgot-password-align'),
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: EdgeInsets.only(top: BaseSpacing.xxs),
                        child: GestureDetector(
                          key: const Key('forgot-password-link'),
                          onTap: controller.goToForgotPassword,
                          child: CustomText(
                            text: 'Forgot password?',
                            color: AppColors.primaryColor,
                            fontSize: AppFontSize.verySmall,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
            ),
          ),
          SizedBox(height: BaseSpacing.lg),
          Obx(
            () => AppButton(
              key: const Key('auth-submit-button'),
              label: authController.isEmailLoading.value
                  ? (controller.isSignUpMode.value ? 'Creating account...' : 'Logging in...')
                  : (controller.isSignUpMode.value ? 'Create Account' : 'Log In'),
              onPressed: authController.isEmailLoading.value ? null : controller.submit,
              height: 52,
            ),
          ),
          SizedBox(height: BaseSpacing.lg),
          const _OrDivider(),
          SizedBox(height: BaseSpacing.lg),
          Obx(
            () => _GoogleButton(
              onTap: authController.signInWithGoogle,
              isLoading: authController.isSocialLoading.value,
            ),
          ),
          SizedBox(height: BaseSpacing.xl),
          Center(
            child: Obx(
              () => GestureDetector(
                onTap: controller.toggleMode,
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: AppFontSize.small2,
                      fontFamily: 'Inter',
                      color: AppColors.gray600,
                    ),
                    children: [
                      TextSpan(
                        text: controller.isSignUpMode.value
                            ? 'Already have an account? '
                            : "Don't have an account? ",
                      ),
                      TextSpan(
                        text: controller.isSignUpMode.value ? 'Log In' : 'Sign Up',
                        style: TextStyle(color: AppColors.primaryColor, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Segmented Login / Sign Up toggle ────────────────────────────────────────

class _ModeToggle extends StatelessWidget {
  const _ModeToggle();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<LoginController>();

    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(BaseRadius.lg),
      ),
      child: Obx(
        () => Stack(
          children: [
            AnimatedAlign(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              alignment: controller.isSignUpMode.value ? Alignment.centerRight : Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: 0.5,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(BaseRadius.md),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.black.withOpacity(0.08),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: _ModeTab(
                    key: const Key('login-tab'),
                    label: 'Log In',
                    isActive: !controller.isSignUpMode.value,
                    onTap: () {
                      if (controller.isSignUpMode.value) controller.toggleMode();
                    },
                  ),
                ),
                Expanded(
                  child: _ModeTab(
                    key: const Key('signup-tab'),
                    label: 'Sign Up',
                    isActive: controller.isSignUpMode.value,
                    onTap: () {
                      if (!controller.isSignUpMode.value) controller.toggleMode();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeTab extends StatelessWidget {
  const _ModeTab({super.key, required this.label, required this.isActive, required this.onTap});
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: CustomText(
          text: label,
          color: isActive ? AppColors.black2 : AppColors.gray600,
          fontSize: AppFontSize.small,
          fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: BaseSpacing.xxs, left: BaseSpacing.xxs),
      child: CustomText(
        text: text,
        color: AppColors.black2,
        fontSize: AppFontSize.verySmall,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: AppColors.lightGrey2)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: BaseSpacing.sm),
          child: CustomText(
            text: 'or continue with',
            color: AppColors.gray600,
            fontSize: AppFontSize.tiny,
          ),
        ),
        Expanded(child: Divider(color: AppColors.lightGrey2)),
      ],
    );
  }
}

// ── Single "Continue with Google" button ─────────────────────────────────

class _GoogleButton extends StatelessWidget {
  const _GoogleButton({required this.onTap, required this.isLoading});
  final VoidCallback onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Opacity(
        opacity: isLoading ? 0.7 : 1,
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.lightGrey2),
            borderRadius: BorderRadius.circular(BaseRadius.md),
            color: AppColors.white,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: isLoading
                ? [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(
                          AppColors.primaryColor,
                        ),
                      ),
                    ),
                  ]
                : [
                    SvgIcon(assetName: AppIcons.googleIcon, size: 20),
                    SizedBox(width: BaseSpacing.xs),
                    CustomText(
                      text: 'Continue with Google',
                      color: AppColors.black2,
                      fontSize: AppFontSize.small,
                      fontWeight: FontWeight.w600,
                    ),
                  ],
          ),
        ),
      ),
    );
  }
}
