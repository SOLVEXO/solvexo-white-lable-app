import 'package:book_store_app/app/components/common_image_view.dart';
import 'package:book_store_app/app/components/custom_text.dart';
import 'package:book_store_app/app/data/services/auth_gate_service.dart';
import 'package:book_store_app/app/data/services/branding_service.dart';
import 'package:book_store_app/app/modules/login/login_view.dart';
import 'package:book_store_app/config/resources/app_colors.dart';
import 'package:book_store_app/config/resources/app_images.dart';
import 'package:book_store_app/config/resources/app_text_styles.dart';
import 'package:book_store_app/core/theme/base_spacing.dart';
import 'package:book_store_app/core/widgets/base_view_screen.dart';
import 'package:book_store_app/utils/app_font_size.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// The single "continue with Google" entry point — Google Sign-In is
/// simultaneously login-or-signup, so there is no separate tab/step to
/// switch between. The route name (`Routes.authTabView`) and class name
/// stay put since many other screens already navigate here.
class AuthTabsView extends StatelessWidget {
  const AuthTabsView({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        // Backing out of a login that was opened to resume a protected
        // guest action (wishlist, message seller, ...) counts as
        // "declined" — unblock the guard instead of leaving it hanging.
        if (didPop && AuthGateService.instance.isAwaitingResume) {
          AuthGateService.instance.resolveCancelled();
        }
      },
      child: BaseViewScreen(
        backgroundColor: AppColors.white,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            BaseSpacing.xl,
            BaseSpacing.xl,
            BaseSpacing.xl,
            BaseSpacing.md,
          ),
          child: Column(
            children: [
              const _TopBrand(),
              SizedBox(height: BaseSpacing.xl),
              const LoginView(),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Brand mark ─────────────────────────────────────────────────────────────

class _TopBrand extends StatelessWidget {
  const _TopBrand();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 70,
          width: 70,
          decoration: BoxDecoration(),
          child: CommonImageView(imagePath: AppImages.logoImage),
        ),
        SizedBox(height: BaseSpacing.sm),
        CustomText(
          text: Get.find<BrandingService>().config.value.appName,
          color: AppColors.black2,
          fontFamily: AppTextStyles.headingFontFamily,
          fontSize: AppFontSize.large,
          fontWeight: FontWeight.bold,
        ),
        SizedBox(height: BaseSpacing.xxs / 2),
        CustomText(
          text: 'Buy and sell, made simple',
          color: AppColors.gray600,
          fontSize: AppFontSize.small2,
        ),
      ],
    );
  }
}
