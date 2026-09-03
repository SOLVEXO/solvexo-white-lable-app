import 'package:book_store_app/app/base_view/base_view_screen.dart';
import 'package:book_store_app/app/components/common_image_view.dart';
import 'package:book_store_app/app/components/custom_refresh_wrapper.dart';
import 'package:book_store_app/app/components/custom_text.dart';
import 'package:book_store_app/app/components/skeleton.dart';
import 'package:book_store_app/app/components/svg_icon.dart';
import 'package:book_store_app/app/modules/checkout/widgets/coupon_code_list_tile.dart';
import 'package:book_store_app/app/modules/map_picker/controllers/mappicker_controller.dart';
import 'package:book_store_app/app/modules/payment/controllers/payment_controller.dart';
import 'package:book_store_app/app/routes/app_pages.dart';
import 'package:book_store_app/config/resources/app_colors.dart';
import 'package:book_store_app/config/resources/app_icons.dart';
import 'package:book_store_app/config/resources/app_text_styles.dart';
import 'package:book_store_app/core/theme/base_spacing.dart';
import 'package:book_store_app/core/widgets/buttons/base_buttons.dart';
import 'package:book_store_app/utils/app_font_size.dart';
import 'package:book_store_app/utils/currency_formatter.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/checkout_controller.dart';

class CheckoutView extends StatelessWidget {
  CheckoutView({super.key});

  // Fresh per navigation is correct here — a new checkout needs its own
  // state (matches ProductDetailController's pattern).
  final controller = Get.put(CheckoutController());

  // These two are shared controllers used by other standalone screens
  // (MapPickerView, PaymentView) — was unconditional `Get.put(...)` here
  // too, which replaced their live singleton every time Checkout opened.
  MapPickerController get mapPickerController {
    if (!Get.isRegistered<MapPickerController>()) Get.put(MapPickerController());
    return Get.find<MapPickerController>();
  }

  PaymentController get paymentController {
    if (!Get.isRegistered<PaymentController>()) Get.put(PaymentController());
    return Get.find<PaymentController>();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return BaseViewScreen(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppColors.white,
      screenName: "Checkout",
      showCustomAppBar: true,
      customBottomBar: _BottomBar(
        controller: controller,
        paymentController: paymentController,
        size: size,
      ),
      horizontalPadding: false,
      child: Obx(() {
        if (controller.isLoading.value) {
          return const _CheckoutShimmer();
        }
        return CustomRefreshWrapper(
          onRefresh: controller.refresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            // `BaseViewScreen`'s Scaffold uses `extendBody: true`, so this
            // scroll view's content area extends behind `customBottomBar`
            // rather than being resized around it — without this, the last
            // couple of summary rows render underneath the fixed bottom bar.
            padding: EdgeInsets.only(bottom: _BottomBar.height + MediaQuery.of(context).padding.bottom),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!controller.isAllDigital) _deliveryAddress(),
                _voucherSection(size),
                _orderList(),
                _subscriptionUpsell(),
                if (!controller.isAllDigital) shippingSection(size),
                _paymentMethodSection(),
                _summary(),
                SizedBox(height: BaseSpacing.xl),
              ],
            ),
          ),
        );
      }),
    );
  }

  // ── Delivery Address ─────────────────────────────────────────────────────

  Widget _deliveryAddress() {
    return _section(
      title: "Delivery Address",
      child: Obx(() {
        final address = controller.addressController.defaultAddress.value;

        if (address == null) {
          return Container(
            padding: EdgeInsets.fromLTRB(BaseSpacing.sm, 0, BaseSpacing.sm, BaseSpacing.sm),
            decoration: BoxDecoration(
              border: Border.all(width: 0.3),
              borderRadius: BorderRadius.circular(BaseRadius.lg),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: CustomText(
                    text: "Please select the address",
                    color: AppColors.gray600,
                    fontSize: AppFontSize.extraSmall,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(left: BaseSpacing.xxl - 2),
                    child: OutlineButton(
                      onPressed: () {
                        controller.addressController.clearForm();
                        Get.toNamed(Routes.addAddressView);
                      },
                      label: "Add",
                      compact: true,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return Container(
          padding: EdgeInsets.fromLTRB(BaseSpacing.sm, 0, BaseSpacing.sm, BaseSpacing.sm),
          decoration: BoxDecoration(
            border: Border.all(width: 0.3),
            borderRadius: BorderRadius.circular(BaseRadius.lg),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: BaseSpacing.xxs + 2,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    spacing: BaseSpacing.xxs + 2,
                    children: [
                      SvgIcon(assetName: AppIcons.locationIcon, size: 16),
                      CustomText(
                        text: address.label,
                        color: AppColors.black,
                        fontSize: AppFontSize.extraSmall,
                        fontWeight: FontWeight.w700,
                      ),
                    ],
                  ),
                  GhostButton(
                    label: "Change",
                    onPressed: () => Get.toNamed(Routes.addressView),
                  ),
                ],
              ),
              CustomText(
                text: address.recipientName,
                color: AppColors.black,
                fontSize: AppFontSize.extraSmall,
                fontWeight: FontWeight.w600,
              ),
              CustomText(text: address.phoneNumber, color: AppColors.gray600, fontSize: AppFontSize.tiny),
              CustomText(
                text: [
                  address.addressLine1,
                  if (address.addressLine2 != null && address.addressLine2!.isNotEmpty) address.addressLine2!,
                  address.city,
                  address.state,
                  address.zipCode,
                ].join(', '),
                color: AppColors.gray600,
                fontSize: AppFontSize.tiny,
              ),
            ],
          ),
        );
      }),
    );
  }

  // ── Voucher ───────────────────────────────────────────────────────────────

  Widget _voucherSection(size) {
    return _section(
      title: "Voucher and reward points",
      child: Column(
        spacing: BaseSpacing.sm,
        children: [
          Obx(
            () => CouponCodeListTile(
              isSubtitle: controller.hasCouponApplied,
              subTitle: "You saved ${CurrencyFormatter.amount(controller.couponDiscountUSD.value, controller.currency.value)} — tap to remove",
              title: controller.hasCouponApplied ? controller.appliedCouponCode.value : "Use Voucher",
              onTap: () => controller.useVoucher(size),
            ),
          ),
          Obx(
            () => CouponCodeListTile(
              isSubtitle: controller.rewardPointsUsed.value,
              subTitle: "You have redeemed 150 points",
              title: "Reward Points",
              onTap: () => controller.useRewardPoints(size),
            ),
          ),
        ],
      ),
    );
  }

  // ── Order list ────────────────────────────────────────────────────────────

  Widget _orderList() {
    return _section(
      title: "Your Order",
      child: Obx(
        () => Column(
          spacing: BaseSpacing.xxs / 2,
          children: controller.orderItems
              .map(
                (item) => Container(
                  padding: EdgeInsets.symmetric(horizontal: BaseSpacing.sm, vertical: BaseSpacing.xxs + 3),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(BaseRadius.md),
                  ),
                  child: ListTile(
                    leading: CommonImageView(url: item.image, width: 60),
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CustomText(text: item.name, color: AppColors.black, fontSize: AppFontSize.extraSmall),
                      ],
                    ),
                    subtitle: Wrap(
                      spacing: BaseSpacing.xxs + 2,
                      runSpacing: BaseSpacing.xxs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        CustomText(
                          text: "${item.quantity} Item",
                          color: AppColors.black,
                          fontSize: AppFontSize.extraSmall,
                        ),
                        _ProductTypeBadge(type: item.productType),
                        if (item.hasMemberDiscount) const _MemberPriceBadge(),
                      ],
                    ),
                    trailing: item.hasMemberDiscount
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              CustomText(
                                text: CurrencyFormatter.amount(item.originalPrice! * item.quantity, controller.currency.value),
                                color: AppColors.gray600,
                                fontSize: AppFontSize.tiny,
                                textDecoration: TextDecoration.lineThrough,
                                fontFamily: AppTextStyles.monoFontFamily,
                              ),
                              CustomText(
                                text: CurrencyFormatter.amount(item.price * item.quantity, controller.currency.value),
                                color: AppColors.primaryColor,
                                fontSize: AppFontSize.extraSmall,
                                fontWeight: FontWeight.bold,
                                fontFamily: AppTextStyles.monoFontFamily,
                              ),
                            ],
                          )
                        : CustomText(
                            text: CurrencyFormatter.amount(item.price * item.quantity, controller.currency.value),
                            color: AppColors.black,
                            fontSize: AppFontSize.extraSmall,
                            fontWeight: FontWeight.bold,
                            fontFamily: AppTextStyles.monoFontFamily,
                          ),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  // ── Shipping ──────────────────────────────────────────────────────────────

  Widget shippingSection(Size size) {
    return Obx(() {
      final shipping = controller.selectedShipping.value;

      return _section(
        title: "Shipping Option",
        child: Container(
          padding: EdgeInsets.all(BaseSpacing.sm),
          decoration: BoxDecoration(
            border: Border.all(width: 0.3),
            borderRadius: BorderRadius.circular(BaseRadius.lg),
          ),
          child: shipping == null
              ? ListTile(
                  title: CustomText(
                    text: "Select Shipping Method",
                    color: AppColors.black,
                    fontSize: AppFontSize.extraSmall,
                    fontWeight: FontWeight.w600,
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => controller.shippingOptionsBottomSheet(size),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: BaseSpacing.xxs + 2,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CustomText(
                          text: shipping.type,
                          color: AppColors.black,
                          fontSize: AppFontSize.extraSmall,
                          fontWeight: FontWeight.w700,
                        ),
                        GhostButton(
                          label: "Change",
                          onPressed: () => controller.shippingOptionsBottomSheet(size),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        CustomText(text: shipping.time, color: AppColors.gray600, fontSize: AppFontSize.tiny),
                        CustomText(
                          text: shipping.charges,
                          color: AppColors.primaryColor,
                          fontSize: AppFontSize.extraSmall,
                          fontWeight: FontWeight.bold,
                          fontFamily: AppTextStyles.monoFontFamily,
                        ),
                      ],
                    ),
                  ],
                ),
        ),
      );
    });
  }

  // ── Subscription upsell ───────────────────────────────────────────────────
  // Server-computed: shown only for stores in this cart the buyer is NOT
  // subscribed to whose plan would have saved money on this exact order.

  Widget _subscriptionUpsell() {
    return Obx(() {
      if (controller.savingsHints.isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: BaseSpacing.md),
        child: Column(
          spacing: BaseSpacing.xs,
          children: controller.savingsHints
              .map(
                (hint) => GestureDetector(
                  onTap: () => controller.openStoreFromHint(hint),
                  child: Container(
                    padding: EdgeInsets.all(BaseSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(BaseRadius.md),
                      border: Border.all(color: AppColors.primaryColor.withOpacity(0.25)),
                    ),
                    child: Row(
                      spacing: BaseSpacing.xs + 2,
                      children: [
                        Icon(Icons.workspace_premium_outlined, color: AppColors.primaryColor, size: 22),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CustomText(
                                text:
                                    "Save ${CurrencyFormatter.amount(hint.potentialSavingsUSD, controller.currency.value)} on this order",
                                color: AppColors.black2,
                                fontSize: AppFontSize.verySmall,
                                fontWeight: FontWeight.w700,
                                fontFamily: AppTextStyles.monoFontFamily,
                              ),
                              CustomText(
                                text: "Join ${hint.storeName}'s ${hint.planName} plan for member pricing",
                                color: AppColors.gray600,
                                fontSize: AppFontSize.tiny,
                              ),
                            ],
                          ),
                        ),
                        if (hint.storeSlug.isNotEmpty)
                          Icon(Icons.chevron_right_rounded, color: AppColors.primaryColor, size: 20),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      );
    });
  }

  // ── Summary ───────────────────────────────────────────────────────────────

  // ── Payment Method ───────────────────────────────────────────────────────

  /// Selectable list (radio-style) rather than the old row of action
  /// buttons — picking one just sets `selectedPaymentMethod`; the single
  /// "Confirm Order" button in `_BottomBar` does the actual dispatch.
  /// `canPayOnline` (Stripe) is already store-region-gated (non-Pakistan
  /// only) in the controller; the new gateways in `gatewayPaymentMethods`
  /// (Safepay et al) are Pakistan-only by construction on the backend side.
  Widget _paymentMethodSection() {
    return _section(
      title: "Payment Method",
      child: Obx(() {
        final selected = controller.selectedPaymentMethod.value;
        return Column(
          children: [
            if (controller.canPayCOD)
              _PaymentOptionTile(
                label: "Cash on Delivery",
                icon: Icons.local_shipping_outlined,
                selected: selected == 'cod',
                onTap: () => controller.selectPaymentMethod('cod'),
              ),
            if (controller.canPayOnline)
              _PaymentOptionTile(
                label: "Pay Online",
                icon: Icons.lock_outline_rounded,
                selected: selected == 'stripe',
                onTap: () => controller.selectPaymentMethod('stripe'),
              ),
            if (controller.canSplitPay)
              _PaymentOptionTile(
                label: "Split Payment",
                icon: Icons.call_split_rounded,
                selected: selected == 'split',
                onTap: () => controller.selectPaymentMethod('split'),
              ),
            if (controller.canPayManualBankTransfer)
              _PaymentOptionTile(
                label: "Bank Transfer",
                icon: Icons.account_balance_outlined,
                selected: selected == 'manual_bank_transfer',
                onTap: () => controller.selectPaymentMethod('manual_bank_transfer'),
              ),
            for (final method in controller.gatewayPaymentMethods)
              _PaymentOptionTile(
                label: method.displayName,
                icon: Icons.payment_rounded,
                selected: selected == method.provider,
                onTap: () => controller.selectPaymentMethod(method.provider),
              ),
          ],
        );
      }),
    );
  }

  Widget _summary() {
    return _section(
      title: "Summary",
      child: Obx(
        () => Column(
          children: [
            _summaryRow("Subtotal (${controller.totalItems} items)", controller.subtotal.toStringAsFixed(2)),
            if (!controller.isAllDigital)
              _summaryRow("Shipping Cost", controller.shippingCost.value.toStringAsFixed(2)),
            if (controller.hasCouponApplied)
              _summaryRow(
                "Discount (${controller.appliedCouponCode.value})",
                "- ${controller.couponDiscountUSD.value.toStringAsFixed(2)}",
              ),
            const Divider(),
            _summaryRow("Total", controller.total.toStringAsFixed(2), bold: true, color: AppColors.primaryColor),
            // Mixed cart — "Split Payment" is one of two options below: it
            // charges only the digital items online now and collects the
            // physical items' cost in cash on delivery instead.
            if (controller.canSplitPay) ...[
              SizedBox(height: BaseSpacing.xxs),
              _summaryRow("If Split Payment — Online now", controller.digitalSubtotal.value.toStringAsFixed(2)),
              _summaryRow("If Split Payment — COD on delivery", controller.codAmountDue.toStringAsFixed(2)),
            ],
            // Member savings are already baked into the item prices above —
            // this is a "you saved" note, not another deduction.
            if (controller.subscriberSavings.value > 0)
              Padding(
                padding: EdgeInsets.only(top: BaseSpacing.xs),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: BaseSpacing.xxs,
                  children: [
                    const Icon(Icons.workspace_premium_outlined, size: 15, color: AppColors.greenSuccess),
                    CustomText(
                      // Despite the "...USD" field name, CheckoutSummary.
                      // subscriberSavingsUSD is actually computed from each
                      // item's own price (see subscription-benefits.service.ts
                      // resolveProductDiscount) — i.e. denominated the same as
                      // the rest of this checkout's line items, not real USD.
                      text:
                          "You saved ${CurrencyFormatter.amount(controller.subscriberSavings.value, controller.currency.value)} with your membership",
                      color: AppColors.greenSuccess,
                      fontSize: AppFontSize.tiny,
                      fontWeight: FontWeight.w700,
                      fontFamily: AppTextStyles.monoFontFamily,
                    ),
                  ],
                ),
              ),
            SizedBox(height: BaseSpacing.xs),
            CustomText(text: "Get reward points 10", color: AppColors.lightGrey, fontSize: AppFontSize.extraSmall),
          ],
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _section({required String title, required Widget child}) {
    return Padding(
      padding: EdgeInsets.all(BaseSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            text: title,
            color: AppColors.black,
            fontSize: AppFontSize.small2,
            fontWeight: FontWeight.bold,
          ),
          SizedBox(height: BaseSpacing.xs),
          child,
        ],
      ),
    );
  }

  Widget _summaryRow(String title, String value, {bool bold = false, Color? color}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: BaseSpacing.xxs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CustomText(text: title, color: AppColors.black, fontSize: AppFontSize.extraSmall),
          CustomText(
            text: "${CurrencyFormatter.symbol(controller.currency.value)}$value",
            color: color ?? AppColors.black,
            fontSize: AppFontSize.extraSmall,
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            fontFamily: AppTextStyles.monoFontFamily,
          ),
        ],
      ),
    );
  }
}

// ── Payment method option tile ──────────────────────────────────────────────

class _PaymentOptionTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _PaymentOptionTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: BaseSpacing.xs),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(BaseRadius.lg),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: BaseSpacing.sm, vertical: BaseSpacing.sm),
          decoration: BoxDecoration(
            border: Border.all(
              color: selected ? AppColors.primaryColor : AppColors.lightGrey11,
              width: selected ? 1.5 : 0.3,
            ),
            borderRadius: BorderRadius.circular(BaseRadius.lg),
            color: selected ? AppColors.primaryColor.withOpacity(0.06) : null,
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: selected ? AppColors.primaryColor : AppColors.greyDefault),
              SizedBox(width: BaseSpacing.xs),
              Expanded(
                child: CustomText(
                  text: label,
                  fontSize: AppFontSize.extraSmall,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? AppColors.primaryColor : AppColors.black,
                ),
              ),
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                size: 18,
                color: selected ? AppColors.primaryColor : AppColors.greyDefault,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Bottom bar ────────────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  final CheckoutController controller;
  final PaymentController paymentController;
  final Size size;

  const _BottomBar({
    required this.controller,
    required this.paymentController,
    required this.size,
  });

  // Vertical padding (top + bottom) below plus the buttons' fixed height —
  // kept in sync here so the scroll view above can reserve exactly this
  // much space instead of guessing.
  static const double height =
      (BaseSpacing.sm + 2) + 52 + (BaseSpacing.xxl - 8);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isPlacing = controller.isPlacingOrder.value;
      final isPaying = paymentController.isProcessing.value;
      final busy = isPlacing || isPaying;
      final hasSelection = controller.selectedPaymentMethod.value != null;

      return Container(
        padding: EdgeInsets.fromLTRB(BaseSpacing.xl, BaseSpacing.sm + 2, BaseSpacing.xl, BaseSpacing.xxl - 8),
        decoration: BoxDecoration(
          color: AppColors.white,
          boxShadow: [
            BoxShadow(color: AppColors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, -3)),
          ],
        ),
        // A single dispatcher button — pick a method above first, then this
        // routes to whichever handler that method needs (CheckoutController
        // .confirmOrder). Disabled until something's selected.
        child: PrimaryButton(
          label: busy ? "Processing..." : "Confirm Order",
          icon: busy ? null : const Icon(Icons.lock_outline_rounded),
          isLoading: busy,
          onPressed: (busy || !hasSelection) ? null : () => controller.confirmOrder(paymentController),
        ),
      );
    });
  }
}

// ── Member price badge ────────────────────────────────────────────────────────

class _MemberPriceBadge extends StatelessWidget {
  const _MemberPriceBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: BaseSpacing.xxs + 2, vertical: BaseSpacing.xxs / 2),
      decoration: BoxDecoration(
        color: AppColors.greenSuccess.withOpacity(0.1),
        borderRadius: BorderRadius.circular(BaseRadius.xs),
      ),
      child: const CustomText(
        text: 'Member price',
        color: AppColors.greenSuccess,
        fontSize: AppFontSize.tiny,
        fontWeight: FontWeight.w600,
        fontFamily: AppTextStyles.monoFontFamily,
      ),
    );
  }
}

// ── Product type badge ────────────────────────────────────────────────────────

class _ProductTypeBadge extends StatelessWidget {
  final String type;
  const _ProductTypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    final isDigital = type == 'digital';
    return Container(
      padding: EdgeInsets.symmetric(horizontal: BaseSpacing.xxs + 2, vertical: BaseSpacing.xxs / 2),
      decoration: BoxDecoration(
        color: isDigital ? AppColors.primaryColor.withOpacity(0.1) : AppColors.darkGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(BaseRadius.xs),
      ),
      child: CustomText(
        text: isDigital ? 'Digital' : 'Physical',
        color: isDigital ? AppColors.primaryColor : AppColors.darkGreen,
        fontSize: AppFontSize.tiny,
        fontWeight: FontWeight.w600,
        fontFamily: AppTextStyles.monoFontFamily,
      ),
    );
  }
}

// ── Full-page shimmer ─────────────────────────────────────────────────────────

class _CheckoutShimmer extends StatelessWidget {
  const _CheckoutShimmer();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: BaseSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ShimmerSection(
              child: Column(
                spacing: BaseSpacing.xs,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Skeleton(width: 120, height: 14),
                      Skeleton(width: 60, height: 14),
                    ],
                  ),
                  Skeleton(width: 160, height: 14),
                  Skeleton(width: double.infinity, height: 12),
                  Skeleton(width: double.infinity, height: 12),
                ],
              ),
            ),
            SizedBox(height: BaseSpacing.xxs),

            _ShimmerSection(
              child: Column(spacing: BaseSpacing.xxs + 2, children: [_shimmerTile(), _shimmerTile()]),
            ),
            SizedBox(height: BaseSpacing.xxs),

            _ShimmerSection(
              child: Column(spacing: BaseSpacing.xs, children: [_shimmerOrderItem(), _shimmerOrderItem()]),
            ),
            SizedBox(height: BaseSpacing.xxs),

            _ShimmerSection(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: BaseSpacing.xs,
                    children: [
                      Skeleton(width: 120, height: 14),
                      Skeleton(width: 80, height: 12),
                    ],
                  ),
                  Skeleton(width: 60, height: 14),
                ],
              ),
            ),
            SizedBox(height: BaseSpacing.xxs),

            _ShimmerSection(
              child: Column(
                spacing: BaseSpacing.xxs + 2,
                children: [
                  _shimmerSummaryRow(),
                  _shimmerSummaryRow(),
                  const Divider(),
                  _shimmerSummaryRow(bold: true),
                ],
              ),
            ),
            SizedBox(height: BaseSpacing.xl),
          ],
        ),
      ),
    );
  }

  static Widget _shimmerTile() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: BaseSpacing.sm, vertical: BaseSpacing.md - 2),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.lightGrey2, width: 0.5),
        borderRadius: BorderRadius.circular(BaseRadius.md),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Skeleton(width: 130, height: 13),
          Skeleton(width: 28, height: 28, cornerRadius: 8),
        ],
      ),
    );
  }

  static Widget _shimmerOrderItem() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: BaseSpacing.sm, vertical: BaseSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(BaseRadius.md),
      ),
      child: Row(
        spacing: BaseSpacing.sm,
        children: [
          Skeleton(width: 60, height: 60, cornerRadius: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: BaseSpacing.xs,
              children: [
                Skeleton(width: double.infinity, height: 13),
                Skeleton(width: 80, height: 11),
              ],
            ),
          ),
          Skeleton(width: 50, height: 13),
        ],
      ),
    );
  }

  static Widget _shimmerSummaryRow({bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Skeleton(width: bold ? 60 : 140, height: bold ? 15 : 12),
        Skeleton(width: 50, height: bold ? 15 : 12),
      ],
    );
  }
}

// ── Shimmer section wrapper ───────────────────────────────────────────────────

class _ShimmerSection extends StatelessWidget {
  final Widget child;
  const _ShimmerSection({required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: BaseSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: BaseSpacing.xs,
        children: [Skeleton(width: 140, height: 15, cornerRadius: 4), child],
      ),
    );
  }
}
