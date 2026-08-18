import 'package:book_store_app/app/components/animated_background_circles.dart';
import 'package:book_store_app/app/components/common_image_view.dart';
import 'package:book_store_app/app/components/custom_text.dart';
import 'package:book_store_app/app/components/svg_icon.dart';
import 'package:book_store_app/app/data/services/branding_service.dart';
import 'package:book_store_app/app/modules/welcome/controllers/welcome_controller.dart';
import 'package:book_store_app/config/resources/app_colors.dart';
import 'package:book_store_app/config/resources/app_icons.dart';
import 'package:book_store_app/config/resources/app_images.dart';
import 'package:book_store_app/config/resources/app_text_styles.dart';
import 'package:book_store_app/core/theme/base_animations.dart';
import 'package:book_store_app/core/theme/base_shadows.dart';
import 'package:book_store_app/core/theme/base_spacing.dart';
import 'package:book_store_app/core/widgets/base_view_screen.dart';
import 'package:book_store_app/core/widgets/buttons/base_buttons.dart';
import 'package:book_store_app/utils/app_font_size.dart';
import 'package:book_store_app/utils/dimens.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

// Seller-only landing screen. Reached exclusively via the "Sell on Solvexo"
// entry point (Account tab, or a Home banner) — never shown at first launch.
// Buyers never see a role picker; guest browsing is the default.
class WelcomeView extends StatelessWidget {
  const WelcomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<WelcomeController>();
    return BaseViewScreen(
      useSafeArea: false,
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(gradient: AppColors.appbarGradient),
          ),
          const AnimatedBackgroundCircles(),
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                const _LogoSection(),
                _BottomSection(onGetStarted: controller.startSelling),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.all(BaseSpacing.md),
              child: _CloseButton(onTap: () => Get.back()),
            ),
          ),
        ],
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  final VoidCallback onTap;
  const _CloseButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Close',
      child: PressableScale(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(AppDimen.borderRadius),
          ),
          alignment: Alignment.center,
          child: SvgIcon(assetName: AppIcons.cross, color: AppColors.white),
        ),
      ),
    );
  }
}

// ── Logo + branding ───────────────────────────────────────────────────────────

class _LogoSection extends StatelessWidget {
  const _LogoSection();

  @override
  Widget build(BuildContext context) {
    final marketplaceName = Get.find<BrandingService>().config.value.marketplaceName;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 100,
          width: 100,
          padding: EdgeInsets.all(BaseSpacing.xxs + 1),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(BaseRadius.xxl),
            boxShadow: BaseShadows.forLevel(BaseElevation.level4),
          ),
          child: CommonImageView(
            imagePath: AppImages.logoImage,
            fit: BoxFit.cover,
            radius: BorderRadius.circular(BaseRadius.xxl),
          ),
        ),
        SizedBox(height: BaseSpacing.lg),
        CustomText(
          text: 'Sell on $marketplaceName',
          color: AppColors.white,
          fontFamily: AppTextStyles.headingFontFamily,
          fontSize: AppFontSize.large,
          fontWeight: FontWeight.w800,
        ),
        SizedBox(height: BaseSpacing.xxs),
        CustomText(
          text: 'Turn your products into a storefront',
          color: AppColors.white.withOpacity(0.8),
          fontSize: AppFontSize.extraSmall,
        ),
        SizedBox(height: BaseSpacing.xxs - 2),
        CustomText(
          text: 'Reach thousands of buyers already shopping on $marketplaceName.',
          textAlign: TextAlign.center,
          color: AppColors.white.withOpacity(0.65),
          fontSize: AppFontSize.tiny,
        ),
      ],
    );
  }
}

// ── Seller pitch + CTA ─────────────────────────────────────────────────────────

class _BottomSection extends StatelessWidget {
  final Future<void> Function() onGetStarted;

  const _BottomSection({required this.onGetStarted});

  @override
  Widget build(BuildContext context) {
    final marketplaceName = Get.find<BrandingService>().config.value.marketplaceName;
    return Container(
      margin: EdgeInsets.symmetric(horizontal: AppDimen.allPadding),
      padding: EdgeInsets.fromLTRB(
        AppDimen.allPadding,
        BaseSpacing.xl,
        AppDimen.allPadding,
        BaseSpacing.xxl,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(BaseRadius.xxxl),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            text: 'Why sell on $marketplaceName?',
            color: AppColors.black,
            fontFamily: AppTextStyles.headingFontFamily,
            fontSize: AppFontSize.small2,
            fontWeight: FontWeight.w600,
          ),
          SizedBox(height: BaseSpacing.xl),
          const _SellerPerk(
            icon: AppIcons.cashIcon,
            title: 'Create a store in minutes',
            subtitle: 'Set up your storefront and list products fast',
          ),
          SizedBox(height: BaseSpacing.sm),
          const _SellerPerk(
            icon: AppIcons.cartIcon,
            title: 'Manage everything in one place',
            subtitle: 'Orders, inventory, and analytics on one dashboard',
          ),
          SizedBox(height: BaseSpacing.xl),
          PrimaryButton(label: 'Get Started', onPressed: onGetStarted),
          SizedBox(height: BaseSpacing.md),
          Center(
            child: CustomText(
              text: 'By continuing you agree to our Terms & Privacy Policy',
              textAlign: TextAlign.center,
              color: AppColors.lightGrey5,
              fontSize: AppFontSize.tiny,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _SellerPerk extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;

  const _SellerPerk({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(BaseRadius.sm),
          ),
          alignment: Alignment.center,
          child: SvgIcon(
            assetName: icon,
            size: 24,
            color: AppColors.primaryColor,
          ),
        ),
        SizedBox(width: BaseSpacing.md - 2),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                text: title,
                color: AppColors.black,
                fontSize: AppFontSize.verySmall,
                fontWeight: FontWeight.bold,
              ),
              SizedBox(height: BaseSpacing.xxs / 2),
              CustomText(
                text: subtitle,
                color: AppColors.grey,
                fontSize: AppFontSize.tiny,
                fontWeight: FontWeight.w400,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
