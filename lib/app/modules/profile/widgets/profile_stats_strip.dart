import 'package:book_store_app/app/components/custom_text.dart';
import 'package:book_store_app/app/modules/address/controllers/address_controller.dart';
import 'package:book_store_app/app/modules/myorders/controllers/my_orders_controller.dart';
import 'package:book_store_app/app/modules/profile/controllers/profile_controller.dart';
import 'package:book_store_app/app/modules/wishlist/controllers/wishlist_controller.dart';
import 'package:book_store_app/config/resources/app_colors.dart';
import 'package:book_store_app/core/theme/base_shadows.dart';
import 'package:book_store_app/core/theme/base_spacing.dart';
import 'package:book_store_app/utils/app_font_size.dart';
import 'package:book_store_app/utils/dimens.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProfileStatsStrip extends StatelessWidget {
  final ProfileController controller;
  const ProfileStatsStrip({super.key, required this.controller});

  // Was `Get.put(AddressController())` *inside* the Obx builder below —
  // that re-ran (and replaced the shared, live `AddressController`) on
  // every single reactive rebuild triggered by `controller.user`, not just
  // once per widget build. Guarding + hoisting it out of the builder fixes
  // both the repeated replacement and the unnecessary work.
  AddressController get _addressController {
    if (!Get.isRegistered<AddressController>()) Get.put(AddressController());
    return Get.find<AddressController>();
  }

  @override
  Widget build(BuildContext context) {
    final addressController = _addressController;
    return Obx(() {
      final user = controller.user.value;
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: AppDimen.allPadding),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: BaseSpacing.md + 2),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(
              AppDimen.serviceCountTileRadius,
            ),
            boxShadow: BaseShadows.forLevel(BaseElevation.level1),
          ),
          child: Obx(() {
            return Row(
              children: [
                _StatCell(
                  value: user != null
                      ? "${Get.put(MyOrdersController()).orders.length}"
                      : '0',
                  label: 'Orders',
                ),
                _vDivider(),
                _StatCell(
                  value: "${Get.put(WishlistController()).count}",
                  label: 'Wishlist',
                ),
                _vDivider(),
                _StatCell(
                  value: "${addressController.addresses.length}",
                  label: 'Addresses',
                ),
              ],
            );
          }),
        ),
      );
    });
  }

  Widget _vDivider() =>
      Container(width: 1, height: 36, color: AppColors.lightGrey2);
}

class _StatCell extends StatelessWidget {
  final String value;
  final String label;
  const _StatCell({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomText(
            text: value,
            color: AppColors.primaryColor,
            fontSize: AppFontSize.extraSmall,
            fontWeight: FontWeight.bold,
          ),
          SizedBox(height: BaseSpacing.xxs / 2),
          CustomText(
            text: label,
            color: AppColors.greyDefault,
            fontSize: AppFontSize.tiny,
            fontWeight: FontWeight.w400,
          ),
        ],
      ),
    );
  }
}
