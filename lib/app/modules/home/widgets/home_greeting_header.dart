import 'package:book_store_app/app/components/custom_text.dart';
import 'package:book_store_app/app/components/svg_icon.dart';
import 'package:book_store_app/app/data/services/store_chat_launcher.dart';
import 'package:book_store_app/app/modules/home/widgets/currency_selector.dart';
import 'package:book_store_app/app/modules/home/widgets/icon_badge.dart';
import 'package:book_store_app/app/modules/messaging/controllers/messaging_badge_controller.dart';
import 'package:book_store_app/app/modules/notifications/controllers/notifications_badge_controller.dart';
import 'package:book_store_app/app/modules/profile/controllers/profile_controller.dart';
import 'package:book_store_app/app/routes/app_pages.dart';
import 'package:book_store_app/config/resources/app_colors.dart';
import 'package:book_store_app/config/resources/app_icons.dart';
import 'package:book_store_app/config/resources/app_text_styles.dart';
import 'package:book_store_app/core/theme/base_spacing.dart';
import 'package:book_store_app/utils/app_font_size.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Home's flat greeting header — replaces the gradient `MainAppBar` on this
/// screen only (that component still backs other buyer screens, so it's
/// left untouched). Cart has its own bottom-nav tab already, so it isn't
/// duplicated here; messaging has no other entry point, so its icon stays.
class HomeGreetingHeader extends StatelessWidget {
  const HomeGreetingHeader({super.key});

  String get _timeGreeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final profileController = Get.isRegistered<ProfileController>()
        ? Get.find<ProfileController>()
        : Get.put(ProfileController(), permanent: true);
    final messagingBadge = Get.put(MessagingBadgeController());
    final notificationsBadge = Get.put(NotificationsBadgeController());

    return Padding(
      padding: EdgeInsets.fromLTRB(
        BaseSpacing.md,
        BaseSpacing.sm,
        BaseSpacing.md,
        BaseSpacing.xs,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Obx(() {
              final user = profileController.user.value;
              final name = (user?.name.trim().isNotEmpty ?? false)
                  ? user!.name.trim()
                  : 'Guest';
              final address = user?.address?.trim();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    text: _timeGreeting,
                    color: AppColors.gray600,
                    fontSize: AppFontSize.tiny,
                    fontWeight: FontWeight.w600,
                  ),
                  CustomText(
                    text: name,
                    color: AppColors.black2,
                    fontFamily: AppTextStyles.headingFontFamily,
                    fontSize: AppFontSize.regular,
                    fontWeight: FontWeight.bold,
                  ),
                  if (address != null && address.isNotEmpty) ...[
                    SizedBox(height: BaseSpacing.xxs / 2),
                    Row(
                      children: [
                        SvgIcon(
                          assetName: AppIcons.locationIcon,
                          size: 14,
                          color: AppColors.gray600,
                        ),
                        SizedBox(width: BaseSpacing.xxs / 2),
                        Expanded(
                          child: CustomText(
                            text: address,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            color: AppColors.gray600,
                            fontSize: AppFontSize.tiny,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              );
            }),
          ),
          SizedBox(width: BaseSpacing.sm),
          const CurrencySelector(),
          SizedBox(width: BaseSpacing.xs),
          GestureDetector(
            onTap: () => StoreChatLauncher.open(),
            child: Obx(
              () => IconBadge(
                icon: AppIcons.messageIcon,
                count: messagingBadge.unreadCount.value,
              ),
            ),
          ),
          SizedBox(width: BaseSpacing.xs),
          GestureDetector(
            onTap: () => Get.toNamed(Routes.notifications),
            child: Obx(
              () => IconBadge(
                icon: AppIcons.notificationIcon,
                count: notificationsBadge.unreadCount.value,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
