import 'package:book_store_app/app/components/custom_refresh_wrapper.dart';
import 'package:book_store_app/app/components/shimmer/shimmer_profile_details.dart';
import 'package:book_store_app/app/components/shimmer/shimmer_user_greeting.dart';
import 'package:book_store_app/app/modules/profile/controllers/profile_controller.dart';
import 'package:book_store_app/app/modules/profile/widgets/profile_hero.dart';
import 'package:book_store_app/app/modules/profile/widgets/profile_stats_strip.dart';
import 'package:book_store_app/app/modules/settings/widgets/settings_section_widget.dart';
import 'package:book_store_app/config/resources/app_colors.dart';
import 'package:book_store_app/core/base/base_view.dart';
import 'package:book_store_app/core/theme/base_spacing.dart';
import 'package:book_store_app/core/widgets/wave_bottom_nav_bar.dart';
import 'package:book_store_app/utils/dimens.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProfileView extends BaseView<ProfileController> {
  const ProfileView({super.key});

  // `ProfileView` is embedded directly as a bottom-nav tab, not only
  // reached via `Routes.profileView`'s `ProfileBinding` — self-registering
  // keeps it working either way, matching the original
  // `Get.put(ProfileController())` field-initializer behaviour.
  @override
  ProfileController get controller {
    if (!Get.isRegistered<ProfileController>()) {
      Get.put(ProfileController(), permanent: true);
    }
    return Get.find<ProfileController>();
  }

  @override
  Color? get backgroundColor => AppColors.background;

  // `BaseView`'s default `SafeArea` reserves bottom padding matching the
  // floating bottom-nav bar's full height, leaving an empty painted strip
  // behind the bar instead of real scrolled content. Bottom safe area is
  // handled manually below instead, same as HomeView.
  @override
  bool get useSafeArea => false;

  @override
  Widget buildBody(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Obx(() {
        if (controller.isLoading.value) return const _LoadingBody();

        return CustomRefreshWrapper(
          onRefresh: controller.refreshProfile,
          child: SingleChildScrollView(
            child: Column(
              children: [
                ProfileHero(controller: controller),
                Transform.translate(
                  offset: const Offset(0, -24),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(BaseRadius.xxl),
                      ),
                    ),
                    child: Column(
                      children: [
                        SizedBox(height: BaseSpacing.xl),
                        if (controller.isLoggedIn) ...[
                          ProfileStatsStrip(controller: controller),
                          SizedBox(height: BaseSpacing.xl + BaseSpacing.xxs),
                        ],
                        ...controller.sections.map(
                          (s) => Padding(
                            padding: EdgeInsets.only(
                              bottom: BaseSpacing.xl + BaseSpacing.xxs,
                            ),
                            child: SettingsSectionWidget(section: s),
                          ),
                        ),
                        SizedBox(height: WaveBottomNavBar.totalHeight),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

class _LoadingBody extends StatelessWidget {
  const _LoadingBody();

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        children: [
          Container(
            height: topPad + 200,
            decoration: BoxDecoration(gradient: AppColors.appbarGradient),
          ),
          Padding(
            padding: const EdgeInsets.all(AppDimen.allPadding),
            child: Column(
              children: [
                SizedBox(height: BaseSpacing.xs),
                ShimmerUserGreeting(),
                SizedBox(height: BaseSpacing.md),
                ShimmerProfileDetails(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
