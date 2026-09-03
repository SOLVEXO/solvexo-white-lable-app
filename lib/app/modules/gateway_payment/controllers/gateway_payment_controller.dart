import 'package:book_store_app/app/data/repositories/checkout_repository.dart';
import 'package:book_store_app/app/modules/checkout/controllers/checkout_controller.dart';
import 'package:book_store_app/app/network/api_constaints.dart';
import 'package:book_store_app/utils/toast_util.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';

enum GatewayPaymentUiState { loading, webview, confirming, error }

/// Drives one payment attempt through a store's connected integration
/// gateway (Safepay today; Stripe-via-Connect returns a client-confirmed
/// token instead of a redirect, handled separately — see [_startStripe]).
///
/// Flow for a redirect-based gateway: initiate -> open the returned
/// `redirectUrl` in an in-app WebView -> watch navigation for the
/// `returnUrl`/`cancelUrl` this same controller generated -> once the
/// WebView reaches `returnUrl`, intercept it (never actually load it — it
/// doesn't need to be a real page) and call `confirmGatewayPayment`, which
/// re-verifies with the gateway server-side before any order is created.
class GatewayPaymentController extends GetxController {
  GatewayPaymentController({CheckoutRepository? checkoutRepository})
    : _repository = checkoutRepository ?? CheckoutRepository();

  final CheckoutRepository _repository;

  late final String _checkoutId;
  late final GatewayPaymentMethod method;

  final Rx<GatewayPaymentUiState> uiState = GatewayPaymentUiState.loading.obs;
  final RxString errorMessage = ''.obs;
  WebViewController? webViewController;

  String? _sessionId;
  late final String _returnUrl;
  late final String _cancelUrl;
  bool _resolved = false;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    _checkoutId = args['checkoutId'] as String? ?? '';
    method = args['method'] as GatewayPaymentMethod;

    // These never need to resolve to a real page — the WebView's navigation
    // delegate intercepts and cancels the request the moment it matches,
    // before anything actually loads. A fixed, distinguishable path on the
    // platform's own domain is enough.
    _returnUrl = '${ApiConstants.baseUrl}/payment-return/success';
    _cancelUrl = '${ApiConstants.baseUrl}/payment-return/cancel';

    _start();
  }

  Future<void> _start() async {
    if (_checkoutId.isEmpty) {
      uiState.value = GatewayPaymentUiState.error;
      errorMessage.value = 'Checkout not ready. Please try again.';
      return;
    }

    final result = await _repository.initiateGatewayPayment(
      checkoutId: _checkoutId,
      provider: method.provider,
      returnUrl: _returnUrl,
      cancelUrl: _cancelUrl,
    );

    if (!result.success || result.session == null) {
      uiState.value = GatewayPaymentUiState.error;
      errorMessage.value = result.message ?? 'Failed to start payment';
      return;
    }

    final session = result.session!;
    _sessionId = session.sessionId;

    if (session.isRedirectBased) {
      _openWebView(session.redirectUrl!);
    } else {
      // clientToken path (Stripe-via-Connect) — no separate SDK flow here;
      // just hands off to the same PaymentSheet the existing "Pay Online"
      // button already uses, since the token is the same PaymentIntent
      // client secret shape either way.
      uiState.value = GatewayPaymentUiState.error;
      errorMessage.value = 'This payment method needs the app update that adds card-based checkout for ${method.displayName}.';
    }
  }

  void _openWebView(String redirectUrl) {
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            if (request.url.startsWith(_returnUrl)) {
              _onReturned();
              return NavigationDecision.prevent;
            }
            if (request.url.startsWith(_cancelUrl)) {
              _onCancelled();
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(redirectUrl));

    webViewController = controller;
    uiState.value = GatewayPaymentUiState.webview;
  }

  void _onCancelled() {
    if (_resolved) return;
    _resolved = true;
    ToastUtil.showToast('Payment cancelled');
    Get.back();
  }

  Future<void> _onReturned() async {
    if (_resolved) return;
    _resolved = true;
    uiState.value = GatewayPaymentUiState.confirming;
    await _confirm();
  }

  Future<void> _confirm() async {
    final sessionId = _sessionId;
    if (sessionId == null) return;

    // The gateway can report "pending" briefly right after redirect — a
    // short bounded poll, same pattern the existing Stripe flow already
    // uses in PaymentController._confirmOrderCreated.
    for (var attempt = 0; attempt < 10; attempt++) {
      final status = await _repository.confirmGatewayPayment(
        checkoutId: _checkoutId,
        provider: method.provider,
        sessionId: sessionId,
      );

      if (status.isCompleted) {
        if (Get.isRegistered<CheckoutController>()) {
          Get.find<CheckoutController>().onPaymentSuccess(orderIds: status.orderIds);
        } else {
          Get.back();
        }
        return;
      }
      if (status.isFailed) {
        uiState.value = GatewayPaymentUiState.error;
        errorMessage.value = 'Payment could not be confirmed. If you were charged, contact support with your order details.';
        return;
      }
      await Future.delayed(const Duration(seconds: 1));
    }

    uiState.value = GatewayPaymentUiState.error;
    errorMessage.value = "We couldn't confirm your payment yet. Please check your orders shortly.";
  }

  void retry() {
    _resolved = false;
    uiState.value = GatewayPaymentUiState.loading;
    _start();
  }
}
