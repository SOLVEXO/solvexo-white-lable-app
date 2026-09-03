import 'package:book_store_app/app/base_view/base_view_screen.dart';
import 'package:book_store_app/app/components/custom_text.dart';
import 'package:book_store_app/app/components/custom_text_field.dart';
import 'package:book_store_app/app/modules/manual_transfer/controllers/manual_transfer_controller.dart';
import 'package:book_store_app/app/modules/manual_transfer/widgets/bank_detail_card.dart';
import 'package:book_store_app/app/modules/manual_transfer/widgets/proof_upload_tile.dart';
import 'package:book_store_app/config/resources/app_colors.dart';
import 'package:book_store_app/core/theme/base_spacing.dart';
import 'package:book_store_app/core/widgets/buttons/base_buttons.dart';
import 'package:book_store_app/utils/app_font_size.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Buyer-facing Pakistan "pay into the platform's own bank account" flow —
/// shows the company account details, the approximate PKR amount to
/// transfer, and collects the buyer's proof (screenshot/receipt) plus an
/// optional transaction reference/sender name. Submitting places the
/// order(s) as `pending_verification` and hands off to the status screen.
class ManualTransferView extends StatelessWidget {
  ManualTransferView({super.key});

  final controller = Get.put(ManualTransferController());

  @override
  Widget build(BuildContext context) {
    return BaseViewScreen(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppColors.white,
      screenName: "Bank Transfer",
      showCustomAppBar: true,
      customBottomBar: _BottomBar(controller: controller),
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: BaseSpacing.md, vertical: BaseSpacing.sm),
        child: Obx(() {
          if (controller.isLoadingBankDetails.value) {
            return const _LoadingState();
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: BaseSpacing.lg,
            children: [
              _AmountToTransferCard(controller: controller),
              BankDetailCard(
                details: controller.bankDetails.value,
                instructions: controller.bankDetails.value.instructions,
              ),
              _section(
                title: 'Payment Proof',
                child: Obx(
                  () => ProofUploadTile(
                    file: controller.proofImage.value,
                    onTap: controller.pickProofImage,
                    onRemove: () => controller.proofImage.value = null,
                  ),
                ),
              ),
              _section(
                title: 'Transaction Reference (optional)',
                child: CustomTextField(
                  controller: controller.referenceController,
                  hintText: 'e.g. TXN123456789',
                  isborder: true,
                ),
              ),
              _section(
                title: 'Sender Name (optional)',
                child: CustomTextField(
                  controller: controller.senderNameController,
                  hintText: 'If different from your account name',
                  isborder: true,
                ),
              ),
              SizedBox(height: BaseSpacing.xl),
            ],
          );
        }),
      ),
    );
  }

  Widget _section({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: BaseSpacing.xs,
      children: [
        CustomText(text: title, color: AppColors.black, fontSize: AppFontSize.small2, fontWeight: FontWeight.bold),
        child,
      ],
    );
  }
}

class _AmountToTransferCard extends StatelessWidget {
  final ManualTransferController controller;
  const _AmountToTransferCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Container(
        width: double.infinity,
        padding: EdgeInsets.all(BaseSpacing.md),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.transferCardGradientStart, AppColors.transferCardGradientEnd],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(BaseRadius.lg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomText(text: 'Amount to transfer', color: AppColors.lightGrey8, fontSize: AppFontSize.verySmall),
            SizedBox(height: BaseSpacing.xxs),
            CustomText(
              text: 'PKR ${controller.approximateAmountPKR.toStringAsFixed(0)}',
              color: AppColors.white,
              fontSize: AppFontSize.veryLarge,
              fontWeight: FontWeight.w800,
            ),
            SizedBox(height: BaseSpacing.xxs / 2),
            CustomText(
              text:
                  '≈ \$${controller.totalAmountUSD.toStringAsFixed(2)} USD at ${controller.bankDetails.value.usdToPkrRate.toStringAsFixed(0)} PKR/USD — the exact amount is confirmed when your order is verified.',
              color: AppColors.lightGrey8,
              fontSize: AppFontSize.tiny,
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final ManualTransferController controller;
  const _BottomBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Container(
        padding: EdgeInsets.fromLTRB(BaseSpacing.xl, BaseSpacing.sm + 2, BaseSpacing.xl, BaseSpacing.xxl - 8),
        decoration: BoxDecoration(
          color: AppColors.white,
          boxShadow: [BoxShadow(color: AppColors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, -3))],
        ),
        child: PrimaryButton(
          label: controller.isSubmitting.value ? 'Submitting...' : "I've Made the Transfer",
          isLoading: controller.isSubmitting.value,
          onPressed: controller.isSubmitting.value ? null : controller.submit,
        ),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 80),
      child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryColor)),
    );
  }
}
