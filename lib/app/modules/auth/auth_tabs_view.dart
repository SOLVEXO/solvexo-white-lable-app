import 'package:book_store_app/app/components/common_image_view.dart';
import 'package:book_store_app/app/components/custom_text.dart';
import 'package:book_store_app/app/data/services/auth_gate_service.dart';
import 'package:book_store_app/app/data/services/branding_service.dart';
import 'package:book_store_app/app/modules/login/controller/auth_tabs_controller.dart';
import 'package:book_store_app/app/modules/login/login_view.dart';
import 'package:book_store_app/app/modules/signup/sign_up_view.dart';
import 'package:book_store_app/config/resources/app_colors.dart';
import 'package:book_store_app/config/resources/app_images.dart';
import 'package:book_store_app/config/resources/app_text_styles.dart';
import 'package:book_store_app/core/theme/base_animations.dart';
import 'package:book_store_app/core/theme/base_spacing.dart';
import 'package:book_store_app/core/widgets/base_view_screen.dart';
import 'package:book_store_app/utils/app_font_size.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AuthTabsView extends StatelessWidget {
  const AuthTabsView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AuthTabsController>();
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        // Backing out of a login/signup that was opened to resume a
        // protected guest action (wishlist, message seller, ...) counts as
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
              _TabToggle(controller: controller),
              SizedBox(height: BaseSpacing.xs),
              Obx(
                () => AnimatedSwitcher(
                  duration: BaseMotion.normal,
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.04, 0),
                        end: Offset.zero,
                      ).animate(anim),
                      child: child,
                    ),
                  ),
                  child: controller.tabIndex.value == 0
                      ? const LoginView(key: ValueKey(0))
                      : const SignUpView(key: ValueKey(1)),
                ),
              ),
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

// ── Pill tab toggle ──────────────────────────────────────────────────────────

class _TabToggle extends StatelessWidget {
  const _TabToggle({required this.controller});
  final AuthTabsController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(BaseSpacing.xxs),
      decoration: BoxDecoration(
        color: AppColors.lightGrey10,
        borderRadius: BorderRadius.circular(BaseRadius.pill),
      ),
      child: Row(
        children: [
          _TabButton(label: 'Log in', index: 0, controller: controller),
          _TabButton(label: 'Sign up', index: 1, controller: controller),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.index,
    required this.controller,
  });
  final String label;
  final int index;
  final AuthTabsController controller;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        button: true,
        selected: controller.tabIndex.value == index,
        label: label,
        child: GestureDetector(
          onTap: () => controller.switchTab(index),
          child: Obx(() {
            final active = controller.tabIndex.value == index;
            return AnimatedContainer(
              duration: BaseMotion.normal,
              curve: BaseMotion.standard,
              constraints: const BoxConstraints(minHeight: 44),
              decoration: BoxDecoration(
                color: active ? AppColors.white : AppColors.transparent,
                borderRadius: BorderRadius.circular(BaseRadius.pill),
              ),
              alignment: Alignment.center,
              child: CustomText(
                text: label,
                color: active ? AppColors.black2 : AppColors.gray600,
                fontSize: AppFontSize.small,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              ),
            );
          }),
        ),
      ),
    );
  }
}
