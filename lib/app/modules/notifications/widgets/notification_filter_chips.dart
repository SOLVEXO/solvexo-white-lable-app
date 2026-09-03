import 'package:book_store_app/app/components/custom_text.dart';
import 'package:book_store_app/app/modules/notifications/controllers/notifications_controller.dart';
import 'package:book_store_app/config/resources/app_colors.dart';
import 'package:book_store_app/config/resources/app_text_styles.dart';
import 'package:book_store_app/utils/app_font_size.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

const _kFilters = [
  ('all', 'All'),
  ('order', 'Orders'),
  ('message', 'Messages'),
  ('promo', 'Promos'),
  ('system', 'System'),
];

class NotificationFilterChips extends StatelessWidget {
  final NotificationsController controller;
  const NotificationFilterChips({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final current = controller.selectedFilter.value;
      return SizedBox(
        height: 36,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _kFilters.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final (key, label) = _kFilters[i];
            final selected = current == key;
            return GestureDetector(
              onTap: () => controller.setFilter(key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primaryColor : AppColors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected
                        ? AppColors.primaryColor
                        : AppColors.lightGrey2,
                  ),
                ),
                child: CustomText(
                  text: label,
                  fontSize: AppFontSize.tiny,
                  fontWeight:
                      selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? AppColors.white : AppColors.greyDefault,
                  fontFamily: AppTextStyles.monoFontFamily,
                ),
              ),
            );
          },
        ),
      );
    });
  }
}
