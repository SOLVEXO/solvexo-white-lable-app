import 'package:book_store_app/app/components/buttons/app_button.dart';
import 'package:book_store_app/app/components/custom_bottom_sheet.dart';
import 'package:book_store_app/app/components/custom_text.dart';
import 'package:book_store_app/app/components/custom_text_field.dart';
import 'package:book_store_app/app/components/shimmer/trip_shimmer.dart';
import 'package:book_store_app/app/data/repositories/checkout_repository.dart';
import 'package:book_store_app/app/data/repositories/shipping_repository.dart';
import 'package:book_store_app/app/modules/address/controllers/address_controller.dart';
import 'package:book_store_app/app/modules/cart/controllers/cart_controller.dart';
import 'package:book_store_app/app/modules/checkout/models/create_checkout_response.dart';
import 'package:book_store_app/app/modules/checkout/models/shipping_options_model.dart';
import 'package:book_store_app/app/modules/payment/controllers/payment_controller.dart';
import 'package:book_store_app/app/modules/payment/models/payment_success_args.dart';
import 'package:book_store_app/app/network/dio_exception_handler.dart';
import 'package:book_store_app/app/routes/app_pages.dart';
import 'package:book_store_app/config/resources/app_colors.dart';
import 'package:book_store_app/utils/app_font_size.dart';
import 'package:book_store_app/utils/currency_formatter.dart';
import 'package:book_store_app/utils/toast_util.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/checkout_item_model.dart';

class CheckoutController extends GetxController {
  CheckoutController({
    ShippingRepository? shippingRepository,
    CheckoutRepository? checkoutRepository,
    AddressController? addressController,
    CreateCheckoutResponse? initialCheckoutResponse,
  }) : _shippingRepository = shippingRepository ?? ShippingRepository(),
       _checkoutRepository = checkoutRepository ?? CheckoutRepository(),
       _initialCheckoutResponse = initialCheckoutResponse,
       addressController =
           addressController ??
           (Get.isRegistered<AddressController>()
               ? Get.find<AddressController>()
               : Get.put(AddressController()));

  final ShippingRepository _shippingRepository;
  final CheckoutRepository _checkoutRepository;
  // Testing seam: `Get.arguments` has no public setter, so a plain unit test
  // can't otherwise populate `_checkoutId`/`orderItems` — every coupon/
  // shipping/COD method early-returns while `_checkoutId` is empty.
  final CreateCheckoutResponse? _initialCheckoutResponse;

  String _checkoutId = '';

  /// Order Items (coming from Cart)
  RxList<CheckoutItem> orderItems = <CheckoutItem>[].obs;
  final rewardController = TextEditingController();
  final voucherController = TextEditingController();
  final RxString rewardPointCode = "123".obs;

  /// Address
  RxString address = "".obs;

  /// Reward points — still a local placeholder (not backed by any API yet;
  /// unrelated to the coupon feature below).
  RxBool rewardPointsUsed = false.obs;
  static const double rewardPointDiscount = 0.0; // optional for future

  /// Coupon — validated server-side against the seller's real coupon
  /// records (POST /api/checkout/apply-coupon), scoped to whichever store
  /// in the cart the code belongs to.
  final RxString appliedCouponCode = ''.obs;
  final RxDouble couponDiscountUSD = 0.0.obs;
  final RxBool isApplyingCoupon = false.obs;
  bool get hasCouponApplied => appliedCouponCode.value.isNotEmpty;

  RxDouble shippingCost = 0.0.obs;
  final RxList<ShippingOption> shippingOptions = <ShippingOption>[].obs;
  final Rx<ShippingOption?> selectedShipping = Rx<ShippingOption?>(null);
  final RxBool isLoadingShipping = false.obs;
  final RxBool isLoading = true.obs;
  final AddressController addressController;

  /// The checkout's resolved currency ('PKR'|'USD') — set once from the
  /// create-checkout response.
  final RxString currency = 'PKR'.obs;

  // Allowed payment methods from the create-checkout API response
  final RxList<String> _allowedPaymentMethods = <String>[].obs;

  /// The current store's own connected payment gateways (Safepay et al,
  /// Stripe-via-Connect) — separate from [_allowedPaymentMethods] above,
  /// which only ever covers the existing COD/Stripe/split/manual-transfer
  /// rails. Empty for a multi-store cart or a store with none connected.
  final RxList<GatewayPaymentMethod> gatewayPaymentMethods = <GatewayPaymentMethod>[].obs;

  /// This checkout's store's own bound currency ('PKR'/'USD') — null until
  /// resolved, or for a multi-store cart. Used to region-gate [canPayOnline]
  /// (Stripe shows for non-Pakistan stores only) independently of whatever
  /// gateways are actually connected — see [_loadGatewayPaymentMethods].
  final Rx<String?> storeCurrency = Rx<String?>(null);

  /// Buyer's chosen payment method for this checkout — a key from
  /// `'cod'`/`'stripe'`/`'split'`/`'manual_bank_transfer'`, or a
  /// [GatewayPaymentMethod.provider] value (e.g. `'safepay'`). Null until
  /// the buyer picks one; the single bottom "Confirm Order" button stays
  /// disabled until then and dispatches based on this value.
  final Rx<String?> selectedPaymentMethod = Rx<String?>(null);

  void selectPaymentMethod(String key) => selectedPaymentMethod.value = key;

  // Digital/physical split of the subtotal — only meaningful (non-zero) for
  // a mixed cart, where `canSplitPay` is true. Refreshed after coupon
  // apply/remove since coupon discounts are baked into `item.totalPrice`
  // server-side.
  final RxDouble digitalSubtotal = 0.0.obs;
  final RxDouble physicalSubtotal = 0.0.obs;

  // ── Subscriber (membership) benefits — all server-computed ────────────────
  // Total member savings already baked into item prices (display-only).
  final RxDouble subscriberSavings = 0.0.obs;

  // Upsell hints for stores in this cart the buyer isn't subscribed to.
  final RxList<SubscriptionSavingsHint> savingsHints =
      <SubscriptionSavingsHint>[].obs;

  void openStoreFromHint(SubscriptionSavingsHint hint) {
    if (hint.storeSlug.isEmpty) return;
    Get.toNamed(Routes.sellerStorefront, arguments: hint.storeSlug);
  }

  /// Read by [PaymentController] to initiate a Stripe payment for this
  /// checkout — set once `_loadInitialData()` resolves.
  String get checkoutId => _checkoutId;

  bool get canPayCOD =>
      _allowedPaymentMethods.isEmpty ||
      _allowedPaymentMethods.contains('cash_on_delivery');

  /// Stripe ("Pay Online") only for a non-Pakistan store — Safepay (in
  /// [gatewayPaymentMethods]) covers Pakistan. `storeCurrency == null`
  /// (not yet resolved, or a multi-store cart) defaults to allowed, so this
  /// never regresses a cart the region check can't actually evaluate.
  bool get canPayOnline =>
      (_allowedPaymentMethods.isEmpty || _allowedPaymentMethods.contains('stripe')) &&
      storeCurrency.value != 'PKR';

  /// True for a mixed (digital + physical) cart — the backend only ever
  /// returns `['split']` in that case, never alongside `'stripe'`/
  /// `'cash_on_delivery'`, so this and the other two `canPay*` getters are
  /// mutually exclusive.
  bool get canSplitPay => _allowedPaymentMethods.contains('split');

  /// The Pakistan "pay into the platform's own bank account, upload proof"
  /// alternative — a Stripe-equivalent (works for any digital/physical mix),
  /// not a COD substitute, so it's independent of the other three getters
  /// and only appears when an admin has enabled it platform-wide.
  bool get canPayManualBankTransfer => _allowedPaymentMethods.contains('manual_bank_transfer');

  /// The amount collected in cash by the courier on delivery — the physical
  /// portion of a split-pay order plus shipping (digital items are always
  /// prepaid online, never COD).
  double get codAmountDue => physicalSubtotal.value + shippingCost.value;

  /// True when every item is digital — drives hiding the address/shipping
  /// sections (backend already excludes shipping for digital-only checkouts).
  bool get isAllDigital =>
      orderItems.isNotEmpty &&
      orderItems.every((item) => item.productType == 'digital');

  @override
  void onInit() {
    super.onInit();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    isLoading.value = true;

    final response =
        _initialCheckoutResponse ?? Get.arguments as CreateCheckoutResponse?;
    if (response != null) {
      _checkoutId = response.checkout.id;
      currency.value = response.checkout.currency;
      orderItems.assignAll(
        response.checkout.items.map((e) => e.toCheckoutItem()).toList(),
      );
      shippingCost.value = response.checkout.shippingFee;
      _allowedPaymentMethods.assignAll(response.allowedPaymentMethods);
      subscriberSavings.value = response.summary.subscriberSavingsUSD;
      digitalSubtotal.value = response.summary.digitalSubtotal;
      physicalSubtotal.value = response.summary.physicalSubtotal;
      savingsHints.assignAll(response.subscriptionSavingsHints);
      // Fire-and-forget — an optional, additive set of buttons; never worth
      // delaying the checkout screen's first paint for.
      _loadGatewayPaymentMethods();
    }

    // Digital-only carts never ship — skip the zone fetch entirely so
    // `shippingCost` stays at the backend's `0` rather than being
    // auto-overridden by the first available physical shipping option.
    if (!isAllDigital) await fetchShippingZones();
    isLoading.value = false;
  }

  @override
  Future<void> refresh() async {
    isLoading.value = true;
    if (!isAllDigital) await fetchShippingZones();
    isLoading.value = false;
  }

  Future<void> fetchShippingZones() async {
    try {
      isLoadingShipping.value = true;

      final zones = await _shippingRepository.getShippingZones();

      // Filter only active zones and map to ShippingOption
      final options = zones
          .where((z) => z.status == 'active' && !z.isDelete)
          .map((z) => z.toShippingOption())
          .toList();

      shippingOptions.assignAll(options);

      // Auto-select first option and apply its price
      if (options.isNotEmpty) {
        selectedShipping.value = options.first;
        shippingCost.value = options.first.amount;
      }
    } on DioException catch (e) {
      DioExceptionHandler.handleDioException(e);
    } catch (e) {
      ToastUtil.showToast('Failed to load shipping options');
    } finally {
      isLoadingShipping.value = false;
    }
  }

  RxBool isPlacingOrder = false.obs;

  /// Physical-goods checkouts need a delivery address before placing an
  /// order — digital-only carts skip the address section entirely.
  bool validateAddressSelected() {
    if (isAllDigital || addressController.defaultAddress.value != null) {
      return true;
    }
    ToastUtil.showToast('Please add a delivery address to continue');
    return false;
  }

  /// Shows a confirmation dialog then calls POST /api/payment/cod-payment.
  Future<void> placeCodOrder() async {
    if (!validateAddressSelected()) return;

    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        title: const CustomText(
          text: 'Confirm Order',
          fontSize: AppFontSize.small,
          fontWeight: FontWeight.w700,
          color: AppColors.black2,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.local_shipping_outlined,
                color: AppColors.primaryColor,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            const CustomText(
              text: 'Cash on Delivery',
              fontSize: AppFontSize.small2,
              fontWeight: FontWeight.w700,
              color: AppColors.black2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const CustomText(
              text:
                  'Your order will be placed immediately on your one tap. The delivery agent will collect payment on arrival.',
              fontSize: AppFontSize.verySmall,
              color: AppColors.greyDefault,
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Cancel',
                  isOutlined: true,
                  onPressed: () => Get.back(result: false),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppButton(
                  label: 'Place Order',
                  onPressed: () => Get.back(result: true),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    isPlacingOrder.value = true;
    try {
      final result = await _checkoutRepository.placeCodOrder(_checkoutId);
      if (result.success) onPaymentSuccess(orderIds: result.orderIds);
    } finally {
      isPlacingOrder.value = false;
    }
  }

  /// Hands off to the full-screen bank-transfer flow (bank details + proof
  /// upload) — unlike COD/split there's a whole form to fill in first, so
  /// this navigates instead of showing an inline confirmation dialog.
  void goToManualBankTransfer() {
    if (!validateAddressSelected()) return;
    Get.toNamed(
      Routes.manualTransferView,
      arguments: {'checkoutId': _checkoutId, 'totalAmountUSD': total},
    );
  }

  Future<void> _loadGatewayPaymentMethods() async {
    if (_checkoutId.isEmpty) return;
    final result = await _checkoutRepository.getGatewayPaymentMethods(_checkoutId);
    storeCurrency.value = result.currency;
    gatewayPaymentMethods.assignAll(result.methods);
  }

  void goToGatewayPayment(GatewayPaymentMethod method) {
    if (!validateAddressSelected()) return;
    Get.toNamed(
      Routes.gatewayPaymentView,
      arguments: {'checkoutId': _checkoutId, 'method': method},
    );
  }

  /// Single dispatcher the bottom "Confirm Order" button calls — routes to
  /// whichever handler the buyer's [selectedPaymentMethod] maps to. Every
  /// individual handler below already does its own address/loading-state
  /// guarding, so this only has to route, not re-validate.
  void confirmOrder(PaymentController paymentController) {
    final key = selectedPaymentMethod.value;
    if (key == null) return;
    switch (key) {
      case 'cod':
        placeCodOrder();
        return;
      case 'stripe':
        paymentController.payWithStripe();
        return;
      case 'split':
        placeSplitOrder(paymentController);
        return;
      case 'manual_bank_transfer':
        goToManualBankTransfer();
        return;
      default:
        for (final method in gatewayPaymentMethods) {
          if (method.provider == key) {
            goToGatewayPayment(method);
            return;
          }
        }
    }
  }

  /// A mixed (digital + physical) cart's single "Place Order" action —
  /// digital items are charged online right away, physical items become a
  /// COD order automatically once that payment succeeds (the backend
  /// resolves this from the checkout's item types; the actual online
  /// payment is the exact same Stripe flow as [PaymentController.payWithStripe],
  /// just charging the digital subtotal instead of the full total).
  Future<void> placeSplitOrder(PaymentController paymentController) async {
    if (!validateAddressSelected()) return;

    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        title: const CustomText(
          text: 'Confirm Your Order',
          fontSize: AppFontSize.small,
          fontWeight: FontWeight.w700,
          color: AppColors.black2,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.receipt_long_outlined,
                color: AppColors.primaryColor,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            const CustomText(
              text: 'Your cart has both digital and physical items',
              fontSize: AppFontSize.small2,
              fontWeight: FontWeight.w700,
              color: AppColors.black2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            CustomText(
              text:
                  "You'll pay ${CurrencyFormatter.amount(digitalSubtotal.value, currency.value)} now online for the digital items. "
                  "${CurrencyFormatter.amount(codAmountDue, currency.value)} will be collected in cash when your physical order is delivered.",
              fontSize: AppFontSize.verySmall,
              color: AppColors.greyDefault,
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Cancel',
                  isOutlined: true,
                  onPressed: () => Get.back(result: false),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppButton(
                  label: 'Place Order',
                  onPressed: () => Get.back(result: true),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await paymentController.payWithStripe(paymentMode: 'split');
  }

  /// Shared by COD and Stripe checkout: re-sync the cart from the server
  /// (only the checked-out lines were removed server-side, so unselected
  /// lines must stay) and hand off to the success screen.
  void onPaymentSuccess({List<String> orderIds = const []}) {
    Get.find<CartController>().fetchCart();
    Get.offAllNamed(
      Routes.paymentSuccessView,
      arguments: PaymentSuccessArgs(
        orderIds: orderIds,
        codAmountDue: canSplitPay ? codAmountDue : null,
        currency: currency.value,
      ),
    );
  }

  Future<void> selectShippingOption(ShippingOption option) async {
    // Optimistic update — close sheet and reflect selection immediately
    selectedShipping.value = option;
    shippingCost.value = option.amount;
    Get.back();

    if (_checkoutId.isEmpty) return;

    isLoadingShipping.value = true;
    try {
      final result = await _checkoutRepository.addShippingToCheckout(
        checkoutId: _checkoutId,
        shippingZoneId: option.id,
      );
      if (result != null) {
        shippingCost.value = result.shippingFee;
      }
    } finally {
      isLoadingShipping.value = false;
    }
  }

  void useRewardPoints(Size size) {
    useCouponBottomSheet(size, rewardController, "Reward Points", true, () {
      applyRewardPoints(size);
    });
  }

  /// Tapping the voucher tile either opens the code-entry sheet (nothing
  /// applied yet) or removes the currently-applied coupon (tap again to undo).
  void useVoucher(Size size) {
    if (hasCouponApplied) {
      removeCouponCode();
      return;
    }
    useCouponBottomSheet(
      size,
      voucherController,
      "Enter Coupon code",
      false,
      applyCouponCode,
    );
  }

  void applyRewardPoints(Size size) {
    if (rewardController.text == rewardPointCode.value) {
      rewardPointsUsed.value = true;
      rewardController.clear();
      Get.back();
    } else {
      rewardPointsUsed.value = false;
      Get.back();
    }
  }

  /// Validates the typed code against the seller's real coupon records.
  /// Keeps the sheet open on failure (backend's message is shown via toast)
  /// so the buyer can correct a typo without reopening it.
  Future<void> applyCouponCode() async {
    final code = voucherController.text.trim();
    if (code.isEmpty || _checkoutId.isEmpty || isApplyingCoupon.value) return;

    isApplyingCoupon.value = true;
    try {
      final response = await _checkoutRepository.applyCoupon(
        checkoutId: _checkoutId,
        code: code,
      );
      if (response.success && response.result != null) {
        appliedCouponCode.value = response.result!.couponCode;
        couponDiscountUSD.value = response.result!.couponDiscountUSD;
        shippingCost.value = response.result!.shippingFee;
        digitalSubtotal.value = response.result!.digitalSubtotal;
        physicalSubtotal.value = response.result!.physicalSubtotal;
        voucherController.clear();
        Get.back();
        ToastUtil.showToast('Coupon "${response.result!.couponCode}" applied');
      } else {
        ToastUtil.showToast(response.message ?? 'Invalid coupon code');
      }
    } finally {
      isApplyingCoupon.value = false;
    }
  }

  Future<void> removeCouponCode() async {
    if (_checkoutId.isEmpty || isApplyingCoupon.value) return;
    isApplyingCoupon.value = true;
    try {
      final result = await _checkoutRepository.removeCoupon(_checkoutId);
      if (result != null) {
        appliedCouponCode.value = '';
        couponDiscountUSD.value = 0.0;
        shippingCost.value = result.shippingFee;
        digitalSubtotal.value = result.digitalSubtotal;
        physicalSubtotal.value = result.physicalSubtotal;
      }
    } finally {
      isApplyingCoupon.value = false;
    }
  }

  void shippingOptionsBottomSheet(Size size) {
    Get.bottomSheet(
      CustomBottomSheet(
        height: size.height / 2.5,
        title: "Shipping Options",
        widget: Padding(
          padding: const EdgeInsets.only(top: 10.0),
          // ✅ Single top-level Obx wraps everything — rebuilds when
          //    shippingOptions or isLoadingShipping changes
          child: Obx(() {
            if (isLoadingShipping.value) {
              return TripShimmer(itemCount: 3); // ✅ return added
            }

            if (shippingOptions.isEmpty) {
              return const Center(
                child: CustomText(
                  text: "No shipping options available",
                  fontSize: AppFontSize.small,
                ),
              );
            }

            return Column(
              spacing: 15,
              children: List.generate(shippingOptions.length, (i) {
                final item = shippingOptions[i];
                final isSelected = selectedShipping.value?.type == item.type;

                return GestureDetector(
                  onTap: () => selectShippingOption(item),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        width: isSelected ? 1.2 : 0.3,
                        color: isSelected
                            ? AppColors.primaryColor
                            : AppColors.greyDefault,
                      ),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: ListTile(
                      title: CustomText(
                        text: item.type,
                        fontSize: AppFontSize.small,
                        fontWeight: FontWeight.w800,
                      ),
                      subtitle: CustomText(
                        text: item.time,
                        color: AppColors.gray600,
                        fontSize: AppFontSize.small,
                      ),
                      trailing: CustomText(
                        text: item.charges,
                        fontSize: AppFontSize.small,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ),
                );
              }),
            );
          }),
        ),
      ),
    );
  }

  void useCouponBottomSheet(
    Size size,
    TextEditingController? controller,
    String title,
    bool isRewardPoint,
    Function() onPressed,
  ) {
    Get.bottomSheet(
      CustomBottomSheet(
        height: size.height / 3.1,
        title: title,
        widget: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 5,
            children: [
              CustomText(
                text: isRewardPoint ? "Reward Points" : "Coupon Code",
                fontSize: AppFontSize.small2,
              ),
              CustomTextField(
                controller: controller,
                isborder: true,
                borderRadius: BorderRadius.circular(15),
                filled: true,
                fillColor: AppColors.background,
                hintText: isRewardPoint
                    ? "Enter your reward code"
                    : "Enter your coupon code",
              ),
              isRewardPoint
                  ? Row(
                      spacing: 5,
                      children: [
                        Icon(Icons.local_offer_outlined),
                        CustomText(
                          text: "Your point is 1500. 1 point = \$0.2",
                          fontSize: AppFontSize.small2,
                        ),
                      ],
                    )
                  : SizedBox(),
              SizedBox(height: isRewardPoint ? 15 : 30),
              Obx(
                () => AppButton(
                  label: isApplyingCoupon.value ? "Applying..." : "Apply",
                  onPressed: isApplyingCoupon.value ? null : onPressed,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double get discount {
    double totalDiscount = couponDiscountUSD.value;

    // Future extension
    if (rewardPointsUsed.value) {
      totalDiscount += rewardPointDiscount;
    }

    return totalDiscount;
  }

  double get subtotal =>
      orderItems.fold(0, (sum, e) => sum + e.price * e.quantity);

  double get total {
    final calculatedTotal = subtotal + shippingCost.value - discount;

    return calculatedTotal < 0 ? 0 : calculatedTotal;
  }

  int get totalItems => orderItems.fold(0, (sum, e) => sum + e.quantity);

  void addAddress(String value) {
    address.value = value;
  }
}
