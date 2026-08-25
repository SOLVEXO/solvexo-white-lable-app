import 'package:book_store_app/app/components/common_image_view.dart';
import 'package:book_store_app/app/components/custom_text.dart';
import 'package:book_store_app/config/resources/app_colors.dart';
import 'package:book_store_app/config/resources/app_images.dart';
import 'package:book_store_app/core/theme/base_spacing.dart';
import 'package:book_store_app/core/widgets/buttons/base_buttons.dart';
import 'package:book_store_app/utils/app_font_size.dart';
import 'package:book_store_app/utils/dimens.dart';
import 'package:flutter/material.dart';

/// Shown by `AuthGateService` whenever a guest taps a protected action
/// (add to wishlist, message a seller, checkout, ...). Not a full navigation
/// redirect — just a nudge with a way in and a way out. Google Sign-In is
/// simultaneously login-or-signup, so there is only one way in.
class LoginPromptSheet extends StatelessWidget {
  final String message;
  final VoidCallback onContinueWithGoogle;
  final VoidCallback onClose;

  const LoginPromptSheet({
    super.key,
    required this.message,
    required this.onContinueWithGoogle,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(
          AppDimen.allPadding,
          BaseSpacing.sm,
          AppDimen.allPadding,
          BaseSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  margin: EdgeInsets.only(left: BaseSpacing.lg),
                  height: 4,
                  width: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(BaseRadius.pill),
                    color: AppColors.lightGrey2,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: onClose,
                  child: const CircleAvatar(
                    radius: 14,
                    backgroundColor: AppColors.background,
                    child: Icon(Icons.close_rounded, size: 16, color: AppColors.black),
                  ),
                ),
              ],
            ),
            SizedBox(height: BaseSpacing.md),
            Container(
              width: 56,
              height: 56,
              padding: EdgeInsets.all(BaseSpacing.xxs + 2),
              decoration: BoxDecoration(
                color: AppColors.white,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.lightGrey2),
              ),
              child: CommonImageView(
                imagePath: AppImages.logoImage,
                fit: BoxFit.cover,
                radius: BorderRadius.circular(BaseRadius.pill),
              ),
            ),
            SizedBox(height: BaseSpacing.md),
            CustomText(
              text: 'Login to continue',
              color: AppColors.black,
              fontSize: AppFontSize.small2,
              fontWeight: FontWeight.w700,
            ),
            SizedBox(height: BaseSpacing.xxs),
            CustomText(
              text: message,
              textAlign: TextAlign.center,
              color: AppColors.grey,
              fontSize: AppFontSize.verySmall,
            ),
            SizedBox(height: BaseSpacing.xl),
            PrimaryButton(
              label: 'Continue with Google',
              onPressed: onContinueWithGoogle,
            ),
          ],
        ),
      ),
    );
  }
}
