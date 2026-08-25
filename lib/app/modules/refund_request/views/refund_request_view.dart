import 'package:book_store_app/app/components/buttons/app_button.dart';
import 'package:book_store_app/app/components/common_image_view.dart';
import 'package:book_store_app/app/components/custom_app_bar_two.dart';
import 'package:book_store_app/app/components/custom_text.dart';
import 'package:book_store_app/app/components/custom_text_field.dart';
import 'package:book_store_app/app/components/recent_order.dart';
import 'package:book_store_app/app/components/svg_icon.dart';
import 'package:book_store_app/app/data/models/refund_request_model.dart';
import 'package:book_store_app/app/modules/myorders/models/order_item_model.dart';
import 'package:book_store_app/app/modules/refund_request/controllers/refund_request_controller.dart';
import 'package:book_store_app/config/resources/app_colors.dart';
import 'package:book_store_app/config/resources/app_icons.dart';
import 'package:book_store_app/utils/app_font_size.dart';
import 'package:book_store_app/utils/currency_formatter.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RefundRequestView extends StatelessWidget {
  RefundRequestView({super.key});
  final controller = Get.put(RefundRequestController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: CustomAppBarTwo(title: "Request Refund"),
      body: Obx(() {
        final store = controller.selectedStore.value;
        final showPicker = store == null || !controller.itemsConfirmed.value;

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Container(
            color: AppColors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Order Header
                RecentOrder(orders: controller.order),

                const SizedBox(height: 20),

                if (controller.eligibleStores.isEmpty)
                  const CustomText(
                    text:
                        "No items on this order are eligible for a refund request.",
                    fontSize: AppFontSize.small,
                    color: AppColors.grey,
                  )
                else if (store == null)
                  _storePicker()
                else if (!controller.itemsConfirmed.value)
                  _itemPicker(store)
                else if (controller.selectedIssue.value == null)
                  _issueList()
                else
                  _detailsSection(),

                if (showPicker) ...[
                  const SizedBox(height: 20),
                  _continueButton(store),
                ] else ...[
                  const SizedBox(height: 20),
                  Obx(
                    () => AppButton(
                      iconWidget: controller.isLoading.value
                          ? const CircularProgressIndicator(
                              color: AppColors.background,
                            )
                          : const SizedBox(),
                      label: controller.isLoading.value
                          ? "Submitting"
                          : "Submit Request",
                      onPressed: controller.canContinue
                          ? controller.submitRefund
                          : null,
                    ),
                  ),
                ],

                const SizedBox(height: 28),
                _statusSection(),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _continueButton(OrderStore? store) {
    if (store == null) return const SizedBox.shrink();
    return Obx(
      () => AppButton(
        iconWidget: const SizedBox(),
        label: "Continue",
        onPressed: controller.canConfirmItems ? controller.confirmItems : null,
      ),
    );
  }

  Widget _storePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          text: "Which store's items would you like to return?",
          fontWeight: FontWeight.w800,
          fontSize: AppFontSize.regular,
        ),
        const SizedBox(height: 12),
        ...controller.eligibleStores.map(
          (store) => GestureDetector(
            onTap: () => controller.selectStore(store),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: CustomText(
                      text: store.sellerName ?? 'Store',
                      fontWeight: FontWeight.w600,
                      fontSize: AppFontSize.small,
                    ),
                  ),
                  SvgIcon(assetName: AppIcons.chevronRight, size: 18),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _itemPicker(OrderStore store) {
    final items = controller.returnableItems;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: CustomText(
                text: "Which items would you like to return?",
                fontWeight: FontWeight.w800,
                fontSize: AppFontSize.regular,
              ),
            ),
            if (controller.eligibleStores.length > 1)
              GestureDetector(
                onTap: controller.changeStore,
                child: CustomText(
                  text: "Change store",
                  fontSize: AppFontSize.tiny,
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (items.isEmpty)
          const CustomText(
            text:
                "No items from this store are currently eligible for a refund.",
            fontSize: AppFontSize.small,
            color: AppColors.grey,
          )
        else
          ...items.map((item) => _itemTile(item)),
      ],
    );
  }

  Widget _itemTile(OrderItem item) {
    return Obx(() {
      final selected = controller.selectedItemIds.contains(item.itemId);
      return GestureDetector(
        onTap: () => controller.toggleItem(item.itemId),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primaryColor.withOpacity(0.06)
                : AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.primaryColor : AppColors.transparent,
            ),
          ),
          child: Row(
            children: [
              if (item.image != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CommonImageView(
                    url: item.image,
                    width: 44,
                    height: 44,
                  ),
                ),
              if (item.image != null) const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      text: item.name,
                      fontWeight: FontWeight.w600,
                      fontSize: AppFontSize.small2,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    CustomText(
                      text:
                          'Qty ${item.quantity} · \$${item.totalPrice.toStringAsFixed(2)}',
                      fontSize: AppFontSize.tiny,
                      color: AppColors.grey,
                    ),
                  ],
                ),
              ),
              Icon(
                selected ? Icons.check_box : Icons.check_box_outline_blank,
                color: selected ? AppColors.primaryColor : AppColors.grey,
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _issueList() {
    return Obx(
      () => Container(
        color: AppColors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomText(
              text: "What is the issue with your item?",
              fontWeight: FontWeight.w800,
              fontSize: AppFontSize.regular,
            ),
            ...controller.issues.entries.map((e) {
              final selected = controller.selectedIssue.value == e.key;
              return GestureDetector(
                onTap: () => controller.selectedIssue.value = e.key,
                child: Container(
                  padding: const EdgeInsets.only(top: 25.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: CustomText(
                          text: e.value,
                          fontWeight: FontWeight.w600,
                          fontSize: AppFontSize.small,
                          color: AppColors.gray600,
                        ),
                      ),
                      Icon(
                        selected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        size: 27,
                        color: selected
                            ? AppColors.primaryColor
                            : AppColors.grey,
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _detailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          text: "What is the issue with your item?",
          fontWeight: FontWeight.w800,
          fontSize: AppFontSize.regular,
        ),
        Obx(
          () => ListTile(
            contentPadding: EdgeInsets.zero,
            title: CustomText(
              text: controller.issues[controller.selectedIssue.value] ?? '',
              fontWeight: FontWeight.w500,
              fontSize: AppFontSize.small,
            ),
            trailing: SvgIcon(assetName: AppIcons.chevronRight, size: 20),
            onTap: () => controller.selectedIssue.value = null,
          ),
        ),
        const SizedBox(height: 8),

        /// Message
        const CustomText(
          text: "Additional details (optional)",
          fontWeight: FontWeight.w600,
          fontSize: AppFontSize.small,
        ),
        const SizedBox(height: 8),
        CustomTextField(
          controller: controller.messageController,
          hintText: "Tell us more about the issue",
          maxLines: 4,
          isborder: true,
          borderRadius: BorderRadius.circular(12),
        ),
      ],
    );
  }

  Widget _statusSection() {
    return Obx(() {
      if (controller.isLoadingStatuses.value) {
        return const Center(child: CircularProgressIndicator());
      }
      final requests = controller.existingRequests;
      if (requests.isEmpty) return const SizedBox.shrink();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1, color: AppColors.lightGrey2),
          const SizedBox(height: 16),
          CustomText(
            text: "Your refund requests",
            fontWeight: FontWeight.w800,
            fontSize: AppFontSize.regular,
          ),
          const SizedBox(height: 12),
          ...requests.map((r) => _statusTile(r)),
        ],
      );
    });
  }

  Widget _statusTile(RefundRequestModel r) {
    final _StatusStyle style = _resolveStatusStyle(r.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: CustomText(
                  text: r.reason,
                  fontWeight: FontWeight.w600,
                  fontSize: AppFontSize.small2,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: style.bg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: CustomText(
                  text: style.label,
                  fontSize: AppFontSize.tiny,
                  fontWeight: FontWeight.w600,
                  color: style.fg,
                ),
              ),
            ],
          ),
          if (r.isApproved && r.buyerRefundAmount != null) ...[
            const SizedBox(height: 6),
            CustomText(
              text:
                  'Refunded: ${CurrencyFormatter.amount(r.buyerRefundAmount!, r.buyerRefundCurrency)}',
              fontSize: AppFontSize.verySmall,
              color: AppColors.darkGreen,
              fontWeight: FontWeight.w600,
            ),
          ],
          if (r.isRejected &&
              r.resolutionNotes != null &&
              r.resolutionNotes!.isNotEmpty) ...[
            const SizedBox(height: 6),
            CustomText(
              text: 'Store note: ${r.resolutionNotes}',
              fontSize: AppFontSize.verySmall,
              color: AppColors.grey,
            ),
          ],
        ],
      ),
    );
  }

  _StatusStyle _resolveStatusStyle(String status) {
    switch (status) {
      case 'approved':
        return const _StatusStyle(
          'Approved',
          AppColors.darkGreen,
          AppColors.greenContainerInnerColor,
        );
      case 'rejected':
        return const _StatusStyle(
          'Rejected',
          AppColors.red,
          AppColors.lightRed,
        );
      default:
        return const _StatusStyle(
          'Pending',
          AppColors.amberDark,
          AppColors.yellowBg,
        );
    }
  }
}

class _StatusStyle {
  final String label;
  final Color fg;
  final Color bg;
  const _StatusStyle(this.label, this.fg, this.bg);
}
