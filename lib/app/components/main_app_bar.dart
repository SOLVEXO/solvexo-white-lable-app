import 'package:book_store_app/app/components/cart_icon_with_count.dart';
import 'package:book_store_app/app/components/common_image_view.dart';
import 'package:book_store_app/app/components/custom_text.dart';
import 'package:book_store_app/app/components/svg_icon.dart';
import 'package:book_store_app/app/components/unread_count_badge.dart';
import 'package:book_store_app/app/data/services/branding_service.dart';
import 'package:book_store_app/app/data/services/store_chat_launcher.dart';
import 'package:book_store_app/app/modules/messaging/controllers/messaging_badge_controller.dart';
import 'package:book_store_app/app/modules/notifications/controllers/notifications_badge_controller.dart';
import 'package:book_store_app/app/routes/app_pages.dart';
import 'package:book_store_app/config/resources/app_colors.dart';
import 'package:book_store_app/config/resources/app_icons.dart';
import 'package:book_store_app/config/resources/app_images.dart';
import 'package:book_store_app/core/theme/base_shadows.dart';
import 'package:book_store_app/core/theme/base_spacing.dart';
import 'package:book_store_app/utils/app_font_size.dart';
import 'package:book_store_app/utils/dimens.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MainAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String actionIcon;
  final double size;
  final Function()? onPressed;
  final bool issearch;
  final double height;

  static const double _rowHeight = 44;
  static const double _searchRowHeight = 52;

  const MainAppBar({
    super.key,
    this.size = 22,
    this.actionIcon = AppIcons.heartIcon,
    this.onPressed,
    this.height = 80,
    this.issearch = false,
  });

  /// Exact height this bar needs on the current device — top status-bar
  /// inset + its own fixed content — so callers never have to guess a
  /// number that drifts out of sync with the real layout (the old
  /// `Get.height / 15` top-padding hack didn't match its own declared
  /// `preferredSize`, so the bar silently overflowed on most devices).
  static double preferredHeight(BuildContext context, {bool issearch = false}) {
    final topInset = MediaQuery.of(context).padding.top;
    final content =
        _rowHeight + (issearch ? BaseSpacing.sm + _searchRowHeight : 0);
    return topInset + BaseSpacing.sm * 2 + content;
  }

  @override
  Widget build(BuildContext context) {
    final messagingBadge = Get.put(MessagingBadgeController());
    final notificationsBadge = Get.put(NotificationsBadgeController());
    final topInset = MediaQuery.of(context).padding.top;

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppDimen.allPadding,
        topInset + BaseSpacing.sm,
        AppDimen.allPadding,
        BaseSpacing.sm,
      ),
      decoration: BoxDecoration(
        gradient: AppColors.appbarGradient,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(BaseRadius.xl),
          bottomRight: Radius.circular(BaseRadius.xl),
        ),
        boxShadow: BaseShadows.forLevel(BaseElevation.level2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: _rowHeight,
            child: Row(
              children: [
                _logoPill(),
                const Spacer(),
                GestureDetector(
                  onTap: () => StoreChatLauncher.open(),
                  child: _iconButton(
                    child: Obx(
                      () => UnreadCountBadge(
                        count: messagingBadge.unreadCount.value,
                        child: SvgIcon(assetName: AppIcons.messageIcon),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: BaseSpacing.xs),
                GestureDetector(
                  onTap: () => Get.toNamed(Routes.notifications),
                  child: _iconButton(
                    child: Obx(
                      () => UnreadCountBadge(
                        count: notificationsBadge.unreadCount.value,
                        child: SvgIcon(assetName: AppIcons.notificationIcon),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: BaseSpacing.xs),
                _iconButton(child: CartIconWithCount()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _logoPill() {
    return Container(
      height: _rowHeight,
      padding: EdgeInsets.symmetric(horizontal: BaseSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.22),
        borderRadius: BorderRadius.circular(AppDimen.borderRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CommonImageView(imagePath: AppImages.logoImage, width: 26),
          SizedBox(width: BaseSpacing.xxs + 2),
          Obx(
            () => CustomText(
              text: Get.find<BrandingService>().config.value.appName,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
              color: AppColors.acceptedBg,
              fontSize: AppFontSize.medium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconButton({Widget? child}) {
    return Container(
      width: _rowHeight,
      height: _rowHeight,
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.22),
        borderRadius: BorderRadius.circular(AppDimen.borderRadius),
      ),
      alignment: Alignment.center,
      child: child,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(height);
}
