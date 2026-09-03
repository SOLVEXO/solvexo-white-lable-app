import 'package:book_store_app/app/components/custom_text.dart';
import 'package:book_store_app/app/components/svg_icon.dart';
import 'package:book_store_app/app/data/models/common_models/notification_model.dart';
import 'package:book_store_app/app/modules/notifications/controllers/notifications_controller.dart';
import 'package:book_store_app/config/resources/app_colors.dart';
import 'package:book_store_app/config/resources/app_icons.dart';
import 'package:book_store_app/utils/app_font_size.dart';
import 'package:flutter/material.dart';

class NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final NotificationsController controller;

  const NotificationTile({
    super.key,
    required this.notification,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => controller.openNotification(notification),
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: notification.isRead
            ? AppColors.white
            : AppColors.primaryColor.withOpacity(0.03),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon container
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: _bgColor(notification.type),
                borderRadius: BorderRadius.circular(13),
              ),
              alignment: Alignment.center,
              child: SvgIcon(
                assetName: _icon(notification.type),
                size: 20,
                color: _iconColor(notification.type),
              ),
            ),
            const SizedBox(width: 12),
            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: CustomText(
                          text: notification.title,
                          fontSize: AppFontSize.extraSmall,
                          fontWeight: notification.isRead
                              ? FontWeight.w500
                              : FontWeight.w700,
                          color: AppColors.black2,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      CustomText(
                        text: _timeAgo(notification.createdAt),
                        fontSize: AppFontSize.tiny,
                        color: AppColors.lightGrey7,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  CustomText(
                    text: notification.body,
                    fontSize: AppFontSize.tiny,
                    color: AppColors.greyDefault,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  _TypeBadge(type: notification.type),
                ],
              ),
            ),
            if (!notification.isRead)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 6, left: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _bgColor(NotificationType type) {
    switch (type) {
      case NotificationType.order:
        return AppColors.languageBg;
      case NotificationType.message:
        return AppColors.messageNotificationBg;
      case NotificationType.promo:
        return AppColors.yellowBg;
      case NotificationType.system:
        return AppColors.lightPurple.withOpacity(0.35);
    }
  }

  Color _iconColor(NotificationType type) {
    switch (type) {
      case NotificationType.order:
        return AppColors.primaryColor;
      case NotificationType.message:
        return AppColors.iosBlue;
      case NotificationType.promo:
        return AppColors.amberDark;
      case NotificationType.system:
        return AppColors.categoryPurple;
    }
  }

  String _icon(NotificationType type) {
    switch (type) {
      case NotificationType.order:
        return AppIcons.ordersIcon;
      case NotificationType.message:
        return AppIcons.messageIcon;
      case NotificationType.promo:
        return AppIcons.appLogoSvg;
      case NotificationType.system:
        return AppIcons.alertIcon;
    }
  }

  static String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

// ── Small type label badge ────────────────────────────────────────────────────

class _TypeBadge extends StatelessWidget {
  final NotificationType type;
  const _TypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: _bg(type),
        borderRadius: BorderRadius.circular(6),
      ),
      child: CustomText(
        text: _label(type),
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: _fg(type),
      ),
    );
  }

  String _label(NotificationType t) {
    switch (t) {
      case NotificationType.order:
        return 'ORDER';
      case NotificationType.message:
        return 'MESSAGE';
      case NotificationType.promo:
        return 'PROMO';
      case NotificationType.system:
        return 'SYSTEM';
    }
  }

  Color _bg(NotificationType t) {
    switch (t) {
      case NotificationType.order:
        return AppColors.primaryColor.withOpacity(0.1);
      case NotificationType.message:
        return AppColors.messageNotificationBg;
      case NotificationType.promo:
        return AppColors.yellowBg;
      case NotificationType.system:
        return AppColors.lightPurple.withOpacity(0.35);
    }
  }

  Color _fg(NotificationType t) {
    switch (t) {
      case NotificationType.order:
        return AppColors.primaryColor;
      case NotificationType.message:
        return AppColors.iosBlue;
      case NotificationType.promo:
        return AppColors.amberDark;
      case NotificationType.system:
        return AppColors.categoryPurple;
    }
  }
}
