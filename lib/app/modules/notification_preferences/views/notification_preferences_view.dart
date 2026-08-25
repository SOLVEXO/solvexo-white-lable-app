import 'package:book_store_app/app/components/custom_app_bar_two.dart';
import 'package:book_store_app/app/components/custom_text.dart';
import 'package:book_store_app/app/components/svg_icon.dart';
import 'package:book_store_app/app/modules/notification_preferences/controllers/notification_preferences_controller.dart';
import 'package:book_store_app/config/resources/app_colors.dart';
import 'package:book_store_app/config/resources/app_icons.dart';
import 'package:book_store_app/utils/app_font_size.dart';
import 'package:book_store_app/utils/dimens.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NotificationPreferencesView extends StatelessWidget {
  NotificationPreferencesView({super.key});
  final NotificationPreferencesController c = Get.put(
    NotificationPreferencesController(),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBarTwo(title: 'Notification Preferences'),
      body: Obx(
        () => c.isLoading.value
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(AppDimen.allPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Obx(
                      () => c.isOsPermissionDenied
                          ? Padding(
                              padding: const EdgeInsets.only(bottom: 20),
                              child: _PermissionBanner(
                                onTap: c.openSystemSettings,
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                    _NotifSection(
                      header: 'DELIVERY',
                      tiles: [
                        _NotifItem(
                          emoji: AppIcons.notificationIcon,
                          title: 'Push Notifications',
                          subtitle: 'Alerts on this device',
                          obs: c.pushEnabled,
                          onChanged: () => c.toggle(c.pushEnabled, 'pushEnabled'),
                        ),
                        _NotifItem(
                          emoji: AppIcons.emailIcon,
                          title: 'Email Notifications',
                          subtitle: 'Alerts sent to your email',
                          obs: c.emailEnabled,
                          onChanged: () => c.toggle(c.emailEnabled, 'emailEnabled'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _NotifSection(
                      header: 'ORDERS',
                      tiles: [
                        _NotifItem(
                          emoji: AppIcons.ordersIcon,
                          title: 'Orders & Payments',
                          subtitle: 'Order status updates and payment confirmations',
                          obs: c.orders,
                          onChanged: () => c.toggle(c.orders, 'orders'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _NotifSection(
                      header: 'MESSAGES',
                      tiles: [
                        _NotifItem(
                          emoji: AppIcons.messageIcon,
                          title: 'Store Messages',
                          subtitle: 'New messages from the store',
                          obs: c.messages,
                          onChanged: () => c.toggle(c.messages, 'messages'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _NotifSection(
                      header: 'REWARDS & OFFERS',
                      tiles: [
                        _NotifItem(
                          emoji: AppIcons.coinIcon,
                          title: 'Loyalty & Rewards',
                          subtitle: 'Points earned and tier upgrades',
                          obs: c.loyalty,
                          onChanged: () => c.toggle(c.loyalty, 'loyalty'),
                        ),
                        _NotifItem(
                          emoji: AppIcons.saleIcon,
                          title: 'Promotions & Offers',
                          subtitle: 'Deals and marketing updates',
                          obs: c.promotions,
                          onChanged: () => c.toggle(c.promotions, 'promotions'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _NotifSection(
                      header: 'MEMBERSHIPS',
                      tiles: [
                        _NotifItem(
                          emoji: AppIcons.cardIcon,
                          title: 'Store Memberships',
                          subtitle: 'Renewal reminders and billing updates',
                          obs: c.subscriptions,
                          onChanged: () => c.toggle(c.subscriptions, 'subscriptions'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

// ─── Warns when the OS permission is actually off — the toggles above only
// control a backend flag and have no bearing on whether push can reach this
// device at all, so this is the one place that reflects reality. ───────────

class _PermissionBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _PermissionBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.red.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppDimen.borderRadius),
        border: Border.all(color: AppColors.red.withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.notifications_off_outlined, color: AppColors.red, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  text: 'Notifications are off for this app',
                  fontSize: AppFontSize.extraSmall,
                  fontWeight: FontWeight.w600,
                  color: AppColors.black,
                ),
                const SizedBox(height: 2),
                CustomText(
                  text:
                      'Push alerts won’t arrive until you allow notifications in your device settings.',
                  fontSize: AppFontSize.tiny,
                  color: AppColors.gray600,
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: onTap,
                  child: CustomText(
                    text: 'Open Settings',
                    fontSize: AppFontSize.tiny,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NotifSection extends StatelessWidget {
  final String header;
  final List<_NotifItem> tiles;
  const _NotifSection({required this.header, required this.tiles});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: CustomText(
            text: header,
            fontSize: AppFontSize.tiny,
            fontWeight: FontWeight.w700,
            color: AppColors.grey,
            letterSpacing: 0.8,
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(
              AppDimen.serviceCountTileRadius,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: tiles.length,
            separatorBuilder: (_, __) => const Divider(
              height: 1,
              indent: 54,
              color: AppColors.lightGrey2,
            ),
            itemBuilder: (_, i) => tiles[i],
          ),
        ),
      ],
    );
  }
}

class _NotifItem extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final RxBool obs;
  final VoidCallback onChanged;
  const _NotifItem({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.obs,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimen.allPadding,
        vertical: 12,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(AppDimen.borderRadius),
            ),
            alignment: Alignment.center,
            child: SvgIcon(assetName: emoji),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  text: title,
                  fontSize: AppFontSize.extraSmall,
                  fontWeight: FontWeight.w500,
                  color: AppColors.black,
                ),
                const SizedBox(height: 2),
                CustomText(
                  text: subtitle,
                  fontSize: AppFontSize.tiny,
                  color: AppColors.grey,
                ),
              ],
            ),
          ),
          Obx(
            () => Switch(
              value: obs.value,
              onChanged: (_) => onChanged(),
              activeColor: AppColors.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
