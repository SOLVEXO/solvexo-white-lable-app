import 'package:book_store_app/app/base_view/base_view_screen.dart';
import 'package:book_store_app/app/components/custom_refresh_wrapper.dart';
import 'package:book_store_app/app/components/custom_text.dart';
import 'package:book_store_app/app/components/custom_text_field.dart';
import 'package:book_store_app/app/data/models/payment/manual_payment_model.dart';
import 'package:book_store_app/app/modules/manual_transfer/controllers/manual_transfer_status_controller.dart';
import 'package:book_store_app/app/modules/manual_transfer/widgets/manual_payment_status_banner.dart';
import 'package:book_store_app/app/modules/manual_transfer/widgets/proof_upload_tile.dart';
import 'package:book_store_app/app/routes/app_pages.dart';
import 'package:book_store_app/config/resources/app_colors.dart';
import 'package:book_store_app/config/resources/app_text_styles.dart';
import 'package:book_store_app/core/theme/base_spacing.dart';
import 'package:book_store_app/core/widgets/buttons/base_buttons.dart';
import 'package:book_store_app/utils/app_font_size.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Shows a submitted bank-transfer proof's review status — pending
/// ("we're verifying"), approved (order confirmed), or rejected (reason +
/// re-upload form right here). Reached either immediately after submission
/// or later by re-opening a pending order.
class ManualTransferStatusView extends StatelessWidget {
  ManualTransferStatusView({super.key});

  final controller = Get.put(ManualTransferStatusController());

  @override
  Widget build(BuildContext context) {
    return BaseViewScreen(
      backgroundColor: AppColors.white,
      screenName: "Payment Status",
      showCustomAppBar: true,
      hasBackButton: false,
      child: Obx(() {
        final proof = controller.proof.value;
        if (proof == null) {
          return controller.isRefreshing.value
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 80),
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryColor)),
                )
              : Padding(
                  padding: EdgeInsets.symmetric(vertical: BaseSpacing.xxl),
                  child: Center(
                    child: CustomText(text: 'Payment proof not found', color: AppColors.gray600, fontSize: AppFontSize.small),
                  ),
                );
        }

        return CustomRefreshWrapper(
          onRefresh: controller.refresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(BaseSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: BaseSpacing.lg,
              children: [
                ManualPaymentStatusBanner(proof: proof),
                _summaryCard(proof),
                if (proof.isRejected) _ReuploadSection(controller: controller),
                if (!proof.isRejected)
                  PrimaryButton(
                    label: 'Continue Shopping',
                    onPressed: () => Get.offAllNamed(Routes.mainHome),
                  ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _summaryCard(ManualPaymentProof proof) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(BaseSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(BaseRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: BaseSpacing.xs,
        children: [
          CustomText(text: 'Order Summary', color: AppColors.black, fontSize: AppFontSize.small2, fontWeight: FontWeight.bold),
          _row('Amount transferred', 'PKR ${proof.amountPKR.toStringAsFixed(0)}'),
          _row('USD equivalent', '\$${proof.amountUSD.toStringAsFixed(2)}'),
          if (proof.transactionReference != null && proof.transactionReference!.isNotEmpty)
            _row('Reference', proof.transactionReference!),
          _row('Orders', '${proof.orderIds.length}'),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        CustomText(text: label, color: AppColors.gray600, fontSize: AppFontSize.extraSmall),
        CustomText(text: value, color: AppColors.black2, fontSize: AppFontSize.extraSmall, fontWeight: FontWeight.w600),
      ],
    );
  }
}

class _ReuploadSection extends StatelessWidget {
  final ManualTransferStatusController controller;
  const _ReuploadSection({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: BaseSpacing.sm,
      children: [
        CustomText(text: 'Re-upload Proof', color: AppColors.black, fontFamily: AppTextStyles.headingFontFamily, fontSize: AppFontSize.small2, fontWeight: FontWeight.bold),
        Obx(
          () => ProofUploadTile(
            file: controller.newProofImage.value,
            onTap: controller.pickNewProofImage,
            onRemove: () => controller.newProofImage.value = null,
          ),
        ),
        CustomTextField(
          controller: controller.referenceController,
          hintText: 'Transaction reference (optional)',
          isborder: true,
        ),
        CustomTextField(
          controller: controller.senderNameController,
          hintText: 'Sender name (optional)',
          isborder: true,
        ),
        Obx(
          () => PrimaryButton(
            label: controller.isReuploading.value ? 'Submitting...' : 'Re-upload Proof',
            isLoading: controller.isReuploading.value,
            onPressed: controller.isReuploading.value ? null : controller.reupload,
          ),
        ),
        OutlineButton(
          label: 'Continue Shopping',
          onPressed: () => Get.offAllNamed(Routes.mainHome),
        ),
      ],
    );
  }
}
