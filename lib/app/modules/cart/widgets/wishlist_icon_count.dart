import 'package:book_store_app/app/data/services/branding_service.dart';
import 'package:book_store_app/app/modules/cart/controllers/cart_controller.dart';
import 'package:book_store_app/app/modules/home/widgets/icon_badge.dart';
import 'package:book_store_app/app/routes/app_pages.dart';
import 'package:book_store_app/config/resources/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class WishlistIconCount extends StatelessWidget {
  const WishlistIconCount({super.key});

  @override
  Widget build(BuildContext context) {
    // UI-level only — hides the entry point for a tenant that's disabled
    // wishlist via white-label feature flags; the wishlist API/routes still
    // exist, actual enforcement (if ever needed) is the backend's job.
    if (!Get.find<BrandingService>().isFeatureEnabled('wishlist')) {
      return const SizedBox.shrink();
    }
    if (!Get.isRegistered<CartController>()) Get.put(CartController());
    final controller = Get.find<CartController>();
    return GestureDetector(
      onTap: () => Get.toNamed(Routes.WISHLIST),
      child: Obx(
        () => Padding(
          padding: const EdgeInsets.only(right: 10.0),
          child: IconBadge(
            icon: AppIcons.heartIcon,
            count: controller.wishlistController.count,
          ),
        ),
      ),
    );
  }
}
