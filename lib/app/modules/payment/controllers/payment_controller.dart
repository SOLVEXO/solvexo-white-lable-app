import 'package:book_store_app/app/data/repositories/checkout_repository.dart';
import 'package:book_store_app/app/data/services/branding_service.dart';
import 'package:book_store_app/app/modules/checkout/controllers/checkout_controller.dart';
import 'package:book_store_app/config/stripe_config.dart';
import 'package:book_store_app/utils/toast_util.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:get/get.dart';

class PaymentController extends GetxController {
  PaymentController({
    CheckoutController? checkoutController,
    CheckoutRepository? checkoutRepository,
  }) : checkoutController =
           checkoutController ?? Get.find<CheckoutController>(),
       _checkoutRepository = checkoutRepository ?? CheckoutRepository();

  final CheckoutController checkoutController;
  final CheckoutRepository _checkoutRepository;

  final RxBool isProcessing = false.obs;

  /// Presents Stripe's own PaymentSheet (card entry + 3DS/SCA handling all
  /// built in) for the current checkout, then confirms the resulting order
  /// was actually created before navigating to the success screen.
  ///
  /// [paymentMode] only matters for a mixed (digital + physical) checkout —
  /// `'full'` (the default, used by the plain "Pay Online" button) charges
  /// everything; `'split'` (used by [CheckoutController.placeSplitOrder])
  /// charges only the digital subtotal and leaves the physical items COD.
  Future<void> payWithStripe({String paymentMode = 'full'}) async {
    if (isProcessing.value) return;

    if (!checkoutController.validateAddressSelected()) return;

    if (!StripeConfig.isConfigured) {
      ToastUtil.showToast(
        'Online payments are not available yet. Please use Cash on Delivery.',
      );
      return;
    }

    final checkoutId = checkoutController.checkoutId;
    if (checkoutId.isEmpty) {
      ToastUtil.showToast('Checkout not ready. Please try again.');
      return;
    }

    isProcessing.value = true;
    try {
      final result = await _checkoutRepository.initiatePayment(checkoutId, paymentMode: paymentMode);
      if (!result.success || result.intent == null) {
        ToastUtil.showToast(result.message ?? 'Failed to start payment');
        return;
      }

      final intent = result.intent!;

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: intent.clientSecret,
          merchantDisplayName: Get.find<BrandingService>().config.value.appName,
        ),
      );

      try {
        await Stripe.instance.presentPaymentSheet();
      } on StripeException catch (e) {
        // FailureCode.Canceled is the user backing out of the sheet — not
        // an error worth surfacing.
        if (e.error.code != FailureCode.Canceled) {
          ToastUtil.showToast(e.error.localizedMessage ?? 'Payment failed');
        }
        return;
      }

      await _confirmOrderCreated(checkoutId);
    } catch (e) {
      debugPrint('❌ payWithStripe error: $e');
      ToastUtil.showToast(
        'Something went wrong while processing your payment.',
      );
    } finally {
      isProcessing.value = false;
    }
  }

  /// Stripe confirms the charge instantly client-side, but our own order(s)
  /// are only created once the webhook (or this poll, as a fallback) tells
  /// the backend the PaymentIntent succeeded — so briefly poll rather than
  /// assume success is immediate.
  Future<void> _confirmOrderCreated(String checkoutId) async {
    for (var attempt = 0; attempt < 10; attempt++) {
      final status = await _checkoutRepository.getPaymentStatus(checkoutId);
      if (status.isCompleted) {
        checkoutController.onPaymentSuccess(orderIds: status.orderIds);
        return;
      }
      if (status.isFailed) {
        ToastUtil.showToast(
          'Payment could not be completed. Please try again.',
        );
        return;
      }
      await Future.delayed(const Duration(seconds: 1));
    }

    // Payment succeeded on Stripe's side but our confirmation is still
    // pending (webhook delayed) — still treat this as success from the
    // buyer's perspective; the order will finish appearing shortly.
    checkoutController.onPaymentSuccess();
  }
}
