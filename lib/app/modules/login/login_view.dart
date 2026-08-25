import 'package:book_store_app/app/components/custom_text.dart';
import 'package:book_store_app/app/components/svg_icon.dart';
import 'package:book_store_app/app/modules/auth/controller/auth_controller.dart';
import 'package:book_store_app/config/resources/app_colors.dart';
import 'package:book_store_app/config/resources/app_icons.dart';
import 'package:book_store_app/core/theme/base_spacing.dart';
import 'package:book_store_app/utils/app_font_size.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Google Sign-In is the only way to log in or sign up — there is no
/// separate signup step, since a first-time Google sign-in creates the
/// account and a returning one logs in.
class LoginView extends StatelessWidget {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    return Padding(
      padding: EdgeInsets.symmetric(vertical: BaseSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: BaseSpacing.md),
          Obx(
            () => _GoogleButton(
              onTap: authController.signInWithGoogle,
              isLoading: authController.isSocialLoading.value,
            ),
          ),
        ],
      ),
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
