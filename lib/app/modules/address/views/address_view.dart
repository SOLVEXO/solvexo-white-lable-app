import 'package:book_store_app/app/base_view/base_view_screen.dart';
import 'package:book_store_app/app/components/custom_confirm_dialog.dart';
import 'package:book_store_app/app/components/custom_icon_button.dart';
import 'package:book_store_app/app/components/custom_refresh_wrapper.dart';
import 'package:book_store_app/app/components/custom_text.dart';
import 'package:book_store_app/app/components/shimmer/shimmer_effect.dart';
import 'package:book_store_app/app/components/svg_icon.dart';
import 'package:book_store_app/app/modules/address/controllers/address_controller.dart';
import 'package:book_store_app/app/modules/address/models/address_model.dart';
import 'package:book_store_app/app/routes/app_pages.dart';
import 'package:book_store_app/config/resources/app_colors.dart';
import 'package:book_store_app/config/resources/app_icons.dart';
import 'package:book_store_app/core/theme/base_spacing.dart';
import 'package:book_store_app/core/widgets/buttons/base_buttons.dart';
import 'package:book_store_app/utils/app_font_size.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AddressView extends StatelessWidget {
  AddressView({super.key});

  final controller = Get.put(AddressController());

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _screen(),
        // Brief overlay while re-fetching the latest copy of an address by
        // id before opening the edit form (see `AddressController.startEditing`).
        Obx(
          () => controller.isFetchingForEdit.value
              ? Container(
                  color: AppColors.black.withOpacity(0.15),
                  alignment: Alignment.center,
                  child: CircularProgressIndicator(color: AppColors.primaryColor),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _screen() {
    return BaseViewScreen(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppColors.background,
      screenName: 'Address',
      showCustomAppBar: true,
      horizontalPadding: false,
      verticalPadding: true,
      customBottomBar: Obx(
        () => controller.addresses.isEmpty
            ? const SizedBox.shrink()
            : Padding(
                padding: EdgeInsets.fromLTRB(BaseSpacing.xl, 0, BaseSpacing.xl, BaseSpacing.xxl - 2),
                child: PrimaryButton(
                  label: 'Add',
                  onPressed: () {
                    controller.clearForm();
                    Get.toNamed(Routes.addAddressView);
                  },
                ),
              ),
      ),
      child: CustomRefreshWrapper(
        onRefresh: () => controller.refreshaddress(),
        child: Obx(() {
          // ── Shimmer loading ──────────────────────────────────────────
          if (controller.loading.value) {
            return const ShimmerEffect(itemCount: 2);
          }

          // ── Empty state ──────────────────────────────────────────────
          if (controller.addresses.isEmpty) {
            return _emptyState();
          }

          // ── Address list ─────────────────────────────────────────────
          return ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics()),
            itemCount: controller.addresses.length,
            itemBuilder: (itemContext, i) {
              final a = controller.addresses[i];
              return _addressCard(itemContext, a, i);
            },
          );
        }),
      ),
    );
  }

  // ─── Empty state ──────────────────────────────────────────────────────────

  Widget _emptyState() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: BaseSpacing.xxl - 2),
      child: Column(
        spacing: BaseSpacing.lg,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgIcon(assetName: AppIcons.mapsIcon, size: 80),
          CustomText(
            text: "You don't have shipping address",
            textAlign: TextAlign.center,
            color: AppColors.black,
            fontSize: AppFontSize.medium,
            fontWeight: FontWeight.w600,
          ),
          PrimaryButton(
            label: 'Add Address',
            onPressed: () {
              controller.clearForm();
              Get.toNamed(Routes.addAddressView);
            },
          ),
        ],
      ),
    );
  }

  // ─── Address card ─────────────────────────────────────────────────────────

  Widget _addressCard(BuildContext context, AddressModel a, int index) {
    return Container(
      margin: EdgeInsets.only(top: BaseSpacing.xxs / 2),
      padding: EdgeInsets.symmetric(horizontal: BaseSpacing.xl, vertical: BaseSpacing.md - 1),
      decoration: const BoxDecoration(color: AppColors.white),
      child: Column(
        spacing: BaseSpacing.xs,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              customcontainer(
                Row(
                  children: [
                    SvgIcon(assetName: AppIcons.locationIcon, color: AppColors.primaryColor),
                    CustomText(
                      text: a.label,
                      color: AppColors.black,
                      fontSize: AppFontSize.extraSmall,
                      fontWeight: FontWeight.w500,
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                spacing: BaseSpacing.xs,
                children: [
                  Semantics(
                    button: true,
                    label: 'Edit address',
                    child: GestureDetector(
                      onTap: () async {
                        await controller.startEditing(a);
                        Get.toNamed(Routes.addAddressView);
                      },
                      child: customcontainer(
                        CustomText(
                          text: 'Edit',
                          color: AppColors.black,
                          fontSize: AppFontSize.extraSmall,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  Semantics(
                    button: true,
                    label: 'Delete address',
                    child: GestureDetector(
                      onTap: () => _confirmDelete(context, a),
                      child: customcontainer(
                        SvgIcon(assetName: AppIcons.deleteIcon, size: 18, color: AppColors.red),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  spacing: BaseSpacing.xxs / 2,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      text: a.recipientName,
                      color: AppColors.black,
                      fontSize: AppFontSize.extraSmall,
                      fontWeight: FontWeight.bold,
                    ),
                    CustomText(
                      text:
                          '${a.addressLine1.toUpperCase()}, ${a.city.toUpperCase()}, ${a.state.toUpperCase()}, ${a.zipCode}',
                      color: AppColors.black,
                      fontSize: AppFontSize.tiny,
                    ),
                    CustomText(
                      text: a.phoneNumber,
                      color: AppColors.black,
                      fontSize: AppFontSize.tiny,
                    ),
                  ],
                ),
              ),
              CustomIconButton(
                assetName: AppIcons.checkIcon,
                size: 30,
                color: a.isDefault ? AppColors.primaryColor : AppColors.gray600,
                onPressed: () {
                  if (a.id != null) controller.setDefault(a.id!);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, AddressModel a) {
    if (a.id == null) return;
    CustomConfirmDialog.show(
      context,
      title: 'Delete address?',
      message: 'This will permanently remove "${a.label}" from your saved addresses.',
      confirmLabel: 'Delete',
      confirmColor: AppColors.red,
      onConfirm: () => controller.deleteAddress(a.id!),
    );
  }

  Widget customcontainer(Widget child) {
    return Container(
      constraints: const BoxConstraints(minHeight: 40),
      padding: EdgeInsets.symmetric(horizontal: BaseSpacing.xs, vertical: BaseSpacing.xxs),
      decoration: BoxDecoration(
        border: Border.all(width: 0.2),
        borderRadius: BorderRadius.circular(BaseRadius.sm),
      ),
      alignment: Alignment.center,
      child: child,
    );
  }
}
