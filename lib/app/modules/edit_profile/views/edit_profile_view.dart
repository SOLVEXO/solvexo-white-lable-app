import 'package:book_store_app/app/components/buttons/app_button.dart';
import 'package:book_store_app/app/components/custom_app_bar_two.dart';
import 'package:book_store_app/app/components/custom_icon_button.dart';
import 'package:book_store_app/app/components/custom_text.dart';
import 'package:book_store_app/app/components/custom_text_field.dart';
import 'package:book_store_app/app/modules/edit_profile/widgets/update_profile_image.dart';
import 'package:book_store_app/app/modules/map_picker/models/picked_address_model.dart';
import 'package:book_store_app/app/modules/profile/controllers/profile_controller.dart';
import 'package:book_store_app/app/routes/app_pages.dart';
import 'package:book_store_app/config/resources/app_colors.dart';
import 'package:book_store_app/config/resources/app_icons.dart';
import 'package:book_store_app/utils/app_font_size.dart';
import 'package:book_store_app/utils/dimens.dart';
import 'package:book_store_app/utils/field_validation_util.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class EditProfileView extends StatelessWidget {
  const EditProfileView({super.key});
  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<ProfileController>()) {
      Get.put(ProfileController(), permanent: true);
    }
    final controller = Get.find<ProfileController>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBarTwo(title: "Edit Profile"),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppDimen.allPadding),
        child: Column(
          spacing: AppDimen.allPadding,
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(AppDimen.allPadding),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppDimen.borderRadius),
                gradient: AppColors.appbarGradient,
              ),

              child: Column(
                spacing: AppDimen.bottomPadding,
                children: [
                  UpdateProfileImage(),
                  CustomText(
                    text: "Change Profile",
                    fontWeight: FontWeight.w500,
                    color: AppColors.white,
                    fontSize: AppFontSize.regular,
                  ),
                ],
              ),
            ),
            Form(
              key: controller.profileFormKey,
              child: Column(
                children: [
                  CustomTextField(
                    hintText: 'Full Name',
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(AppDimen.borderRadius),
                      topRight: Radius.circular(AppDimen.borderRadius),
                    ),
                    ispadding: true,
                    controller: controller.nameController,
                    validator: controller.validateName,
                  ),
                  CustomTextField(
                    hintText: "Email",
                    ispadding: true,
                    controller: controller.emailController,
                    validator: controller.validateEmail,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  CustomTextField(
                    hintText: "Phone Number",
                    ispadding: true,
                    controller: controller.phoneController,
                    validator: controller.validatePhone,
                    keyboardType: TextInputType.phone,
                  ),

                  CustomTextField(
                    hintText: 'Address',
                    controller: controller.addressController,
                    maxLines: 4,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(AppDimen.borderRadius),
                      bottomRight: Radius.circular(AppDimen.borderRadius),
                    ),
                    suffixIcon: CustomIconButton(
                      isPadding: true,
                      assetName: AppIcons.mapsIcon,
                      onPressed: () async {
                        final result = await Get.toNamed(
                          Routes.mapPickerView,
                        );
                        if (result is PickedAddress) {
                          controller.addressController.text =
                              result.formattedAddress;
                        }
                      },
                    ),

                    keyboardType: TextInputType.multiline,
                    validator: (val) =>
                        FieldValidationUtil.validateValue(val!, 'address'.tr),
                  ),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(AppDimen.allPadding),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(AppDimen.borderRadius),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    text: 'Preferred Currency',
                    fontWeight: FontWeight.w600,
                    fontSize: AppFontSize.verySmall,
                    color: AppColors.black,
                  ),
                  SizedBox(height: 8),
                  CustomText(
                    text: 'Used to price your checkouts.',
                    fontSize: AppFontSize.tiny,
                    color: AppColors.greyDefault,
                  ),
                  SizedBox(height: 12),
                  Obx(
                    () => Row(
                      children: [
                        Expanded(
                          child: _CurrencyChip(
                            label: 'PKR',
                            isSelected: controller.currencyPreference.value == 'PKR',
                            onTap: () => controller.pickCurrencyPreference('PKR'),
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: _CurrencyChip(
                            label: 'USD',
                            isSelected: controller.currencyPreference.value == 'USD',
                            onTap: () => controller.pickCurrencyPreference('USD'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Obx(
              () => AppButton(
                label: controller.isUpdating.value
                    ? 'Updating...'
                    : 'Update Profile',
                onPressed: controller.isUpdating.value
                    ? null
                    : controller.updateProfile,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CurrencyChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CurrencyChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryColor.withOpacity(0.1) : AppColors.textfldFillColor,
          borderRadius: BorderRadius.circular(AppDimen.borderRadius),
          border: Border.all(
            color: isSelected ? AppColors.primaryColor : AppColors.lightGrey,
            width: isSelected ? 1.2 : 0.3,
          ),
        ),
        child: CustomText(
          text: label,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          color: isSelected ? AppColors.primaryColor : AppColors.black,
        ),
      ),
    );
  }
}
