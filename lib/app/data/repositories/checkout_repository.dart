import 'package:book_store_app/app/modules/checkout/models/create_checkout_response.dart';
import 'package:book_store_app/app/network/api_constaints.dart';
import 'package:book_store_app/app/network/base_client.dart';
import 'package:book_store_app/app/network/dio_exception_handler.dart';
import 'package:book_store_app/utils/toast_util.dart';
import 'package:dio/dio.dart';

class CheckoutRepository {
  final BaseClient _client = BaseClient();

  /// POST /api/checkout/create-checkout
  /// The server reads the cart from the auth token. [items] narrows the
  /// checkout to specific cart lines (`{productId, variantId}` pairs) —
  /// without it the backend checks out the ENTIRE cart, ignoring the
  /// selection checkboxes in the cart UI.
  ///
  /// The backend resolves the buyer's delivery address itself (falling back
  /// to — and promoting — any saved address if none is explicitly flagged
  /// default) and only rejects the request when the buyer has NO saved
  /// address at all. [addressRequired] surfaces that specific case so the
  /// caller can prompt the buyer to add one instead of showing a generic
  /// error toast.
  Future<({bool success, CreateCheckoutResponse? data, bool addressRequired, String? message})> createCheckout({
    List<Map<String, String>>? items,
    String? attributedBannerId,
    String? attributedStoreBannerId,
    String? currencyPreference,
  }) async {
    try {
      final response = await _client.post(
        ApiConstants.createCheckout,
        data: {
          if (items != null && items.isNotEmpty) 'items': items,
          if (attributedBannerId != null) 'attributedBannerId': attributedBannerId,
          if (attributedStoreBannerId != null) 'attributedStoreBannerId': attributedStoreBannerId,
          if (currencyPreference != null) 'currencyPreference': currencyPreference,
        },
        requiresAuth: true,
      );

      if (response.data['success'] == true) {
        return (
          success: true,
          data: CreateCheckoutResponse.fromJson(response.data['data'] as Map<String, dynamic>),
          addressRequired: false,
          message: null,
        );
      }

      final message = response.data['message'] as String?;
      return (success: false, data: null, addressRequired: _isAddressRequiredMessage(message), message: message ?? 'Failed to create checkout');
    } on DioException catch (e) {
      final data = e.response?.data;
      final message = data is Map ? data['message'] as String? : null;
      return (success: false, data: null, addressRequired: _isAddressRequiredMessage(message), message: message ?? 'Failed to create checkout');
    } catch (e) {
      return (success: false, data: null, addressRequired: false, message: 'Failed to create checkout');
    }
  }

  bool _isAddressRequiredMessage(String? message) =>
      message?.toLowerCase().contains('default address') ?? false;

  /// POST /api/checkout/addShippingInCheckout
  /// Called whenever the user selects a shipping zone on the checkout screen.
  Future<AddShippingResult?> addShippingToCheckout({
    required String checkoutId,
    required String shippingZoneId,
  }) async {
    try {
      final response = await _client.post(
        ApiConstants.addShippingInCheckout,
        data: {
          'checkoutId': checkoutId,
          'shippingZoneId': shippingZoneId,
        },
        requiresAuth: true,
      );

      if (response.data['success'] == true) {
        return AddShippingResult.fromJson(
          response.data['data'] as Map<String, dynamic>,
        );
      }

      ToastUtil.showToast(
        response.data['message'] as String? ?? 'Failed to update shipping',
      );
      return null;
    } on DioException catch (e) {
      DioExceptionHandler.handleDioException(e);
      return null;
    } catch (e) {
      ToastUtil.showToast('Failed to update shipping');
      return null;
    }
  }

  /// POST /api/checkout/apply-coupon
  /// Validates a seller coupon against this checkout and, if valid,
  /// discounts only the items belonging to that coupon's store. [message]
  /// carries the backend's validation error (e.g. "invalid code", "minimum
  /// order not met") so the caller can show it directly.
  Future<({bool success, CouponApplyResult? result, String? message})> applyCoupon({
    required String checkoutId,
    required String code,
  }) async {
    try {
      final response = await _client.post(
        ApiConstants.applyCoupon,
        data: {'checkoutId': checkoutId, 'code': code},
        requiresAuth: true,
      );

      if (response.data['success'] == true) {
        return (
          success: true,
          result: CouponApplyResult.fromJson(response.data['data'] as Map<String, dynamic>),
          message: null,
        );
      }
      return (success: false, result: null, message: response.data['message'] as String?);
    } on DioException catch (e) {
      final data = e.response?.data;
      final message = data is Map ? data['message'] as String? : null;
      return (success: false, result: null, message: message ?? 'Failed to apply coupon');
    } catch (e) {
      return (success: false, result: null, message: 'Failed to apply coupon');
    }
  }

  /// DELETE /api/checkout/remove-coupon/:checkoutId
  Future<AddShippingResult?> removeCoupon(String checkoutId) async {
    try {
      final response = await _client.delete(
        ApiConstants.removeCoupon(checkoutId),
        requiresAuth: true,
      );

      if (response.data['success'] == true) {
        return AddShippingResult.fromJson(response.data['data'] as Map<String, dynamic>);
      }
      ToastUtil.showToast(response.data['message'] as String? ?? 'Failed to remove coupon');
      return null;
    } on DioException catch (e) {
      DioExceptionHandler.handleDioException(e);
      return null;
    } catch (e) {
      ToastUtil.showToast('Failed to remove coupon');
      return null;
    }
  }

  /// POST /api/payment/cod-payment
  /// Places a Cash on Delivery order for physical products. [orderIds] lets
  /// the success screen deep-link into the order(s) just created — a
  /// multi-seller checkout produces one order per store.
  Future<({bool success, List<String> orderIds})> placeCodOrder(String checkoutId) async {
    try {
      final response = await _client.post(
        ApiConstants.codPayment,
        data: {'checkoutId': checkoutId},
        requiresAuth: true,
      );

      if (response.data['success'] == true) {
        return (success: true, orderIds: _extractOrderIds(response.data['data']));
      }

      ToastUtil.showToast(
        response.data['message'] as String? ?? 'Failed to place order',
      );
      return (success: false, orderIds: <String>[]);
    } on DioException catch (e) {
      DioExceptionHandler.handleDioException(e);
      return (success: false, orderIds: <String>[]);
    } catch (e) {
      ToastUtil.showToast('Failed to place order');
      return (success: false, orderIds: <String>[]);
    }
  }

  List<String> _extractOrderIds(dynamic data) {
    final orders = data is Map ? data['orders'] as List? : null;
    if (orders == null) return [];
    return orders
        .map((o) => (o as Map)['orderId']?.toString())
        .whereType<String>()
        .toList();
  }

  /// POST /api/payment/initiate-payment
  /// Creates (or reuses) a Stripe PaymentIntent for this checkout. [message]
  /// carries the backend's error text on failure (e.g. "not configured yet")
  /// so the caller can show it directly instead of a generic toast.
  /// [paymentMode] only matters for a mixed (digital + physical) checkout:
  /// `'full'` charges everything online, `'split'` charges only the digital
  /// subtotal and leaves the physical portion as COD. Ignored otherwise.
  Future<({bool success, PaymentIntentResult? intent, String? message})> initiatePayment(
    String checkoutId, {
    String paymentMode = 'full',
  }) async {
    try {
      final response = await _client.post(
        ApiConstants.initiatePayment,
        data: {'checkoutId': checkoutId, 'paymentMode': paymentMode},
        requiresAuth: true,
      );

      if (response.data['success'] == true) {
        return (
          success: true,
          intent: PaymentIntentResult.fromJson(response.data['data'] as Map<String, dynamic>),
          message: null,
        );
      }

      return (success: false, intent: null, message: response.data['message'] as String?);
    } on DioException catch (e) {
      final data = e.response?.data;
      final message = data is Map ? data['message'] as String? : null;
      return (success: false, intent: null, message: message ?? 'Failed to start payment');
    } catch (e) {
      return (success: false, intent: null, message: 'Failed to start payment');
    }
  }

  /// GET /api/payment/status — polled after `presentPaymentSheet()` succeeds
  /// client-side, since webhook delivery timing can't be relied on from a
  /// mobile client. Returns 'pending' on any error so the caller can just
  /// keep polling rather than treat a transient network hiccup as failure.
  Future<PaymentStatusResult> getPaymentStatus(String checkoutId) async {
    try {
      final response = await _client.get(
        ApiConstants.paymentStatus,
        queryParameters: {'checkoutId': checkoutId},
        requiresAuth: true,
      );

      if (response.data['success'] == true) {
        final data = response.data['data'] as Map<String, dynamic>;
        return PaymentStatusResult(
          status: data['status'] as String? ?? 'pending',
          orderIds: _extractOrderIds(data),
        );
      }
      return const PaymentStatusResult(status: 'pending');
    } catch (e) {
      return const PaymentStatusResult(status: 'pending');
    }
  }

  // ── Store integration gateways (Safepay, Stripe-via-Connect) ────────────
  // Storefront never needs to know/pass a storeId — the backend resolves it
  // server-side from this checkout's own line items. See
  // solvexo-api/docs/integrations-api-reference.md for the full contract.

  /// GET .../payment-methods — the store's own available gateways for this
  /// checkout, plus its resolved currency (returned even with zero gateways
  /// connected — used to region-gate the OTHER, older payment options too,
  /// e.g. showing "Pay Online"/Stripe only for a non-Pakistan store). Empty
  /// methods + null currency for a multi-store cart (existing COD/Stripe/
  /// manual-transfer buttons keep working for that case, ungated).
  Future<GatewayPaymentMethodsResult> getGatewayPaymentMethods(String checkoutId) async {
    try {
      final response = await _client.get(
        ApiConstants.checkoutPaymentMethods(checkoutId),
        requiresAuth: true,
      );
      if (response.data['success'] == true) {
        return GatewayPaymentMethodsResult.fromJson(response.data['data'] as Map<String, dynamic>);
      }
      return const GatewayPaymentMethodsResult(currency: null, methods: []);
    } catch (e) {
      return const GatewayPaymentMethodsResult(currency: null, methods: []);
    }
  }

  /// POST .../payment-methods/:provider/initiate
  Future<({bool success, GatewayPaymentSession? session, String? message})> initiateGatewayPayment({
    required String checkoutId,
    required String provider,
    required String returnUrl,
    required String cancelUrl,
  }) async {
    try {
      final response = await _client.post(
        ApiConstants.initiateCheckoutPaymentMethod(checkoutId, provider),
        data: {'returnUrl': returnUrl, 'cancelUrl': cancelUrl},
        requiresAuth: true,
      );

      if (response.data['success'] == true) {
        return (
          success: true,
          session: GatewayPaymentSession.fromJson(response.data['data'] as Map<String, dynamic>),
          message: null,
        );
      }
      return (success: false, session: null, message: response.data['message'] as String?);
    } on DioException catch (e) {
      final data = e.response?.data;
      final message = data is Map ? data['message'] as String? : null;
      return (success: false, session: null, message: message ?? 'Failed to start payment');
    } catch (e) {
      return (success: false, session: null, message: 'Failed to start payment');
    }
  }

  /// POST .../payment-methods/:provider/confirm — always re-verifies with the
  /// gateway itself server-side before creating an order; never trust
  /// `sessionId` reaching this point as proof of anything by itself.
  Future<PaymentStatusResult> confirmGatewayPayment({
    required String checkoutId,
    required String provider,
    required String sessionId,
  }) async {
    try {
      final response = await _client.post(
        ApiConstants.confirmCheckoutPaymentMethod(checkoutId, provider),
        data: {'sessionId': sessionId},
        requiresAuth: true,
      );
      if (response.data['success'] == true) {
        final data = response.data['data'] as Map<String, dynamic>;
        final orderIds = (data['orderIds'] as List<dynamic>? ?? []).map((e) => e.toString()).toList();
        return PaymentStatusResult(status: data['status'] as String? ?? 'pending', orderIds: orderIds);
      }
      return const PaymentStatusResult(status: 'pending');
    } on DioException catch (e) {
      final data = e.response?.data;
      final message = data is Map ? data['message'] as String? : null;
      // An amount-mismatch/validation rejection is a real failure, not a
      // transient hiccup — surface it as 'failed' rather than 'pending' so
      // the UI stops silently retrying against something that will never
      // succeed.
      return PaymentStatusResult(status: message != null ? 'failed' : 'pending');
    } catch (e) {
      return const PaymentStatusResult(status: 'pending');
    }
  }
}

// ── Response models ────────────────────────────────────────────────────────────

class AddShippingResult {
  final double shippingFee;
  final double subtotal;
  final double totalAmount;
  final double digitalSubtotal;
  final double physicalSubtotal;

  AddShippingResult({
    required this.shippingFee,
    required this.subtotal,
    required this.totalAmount,
    this.digitalSubtotal = 0,
    this.physicalSubtotal = 0,
  });

  factory AddShippingResult.fromJson(Map<String, dynamic> json) {
    return AddShippingResult(
      shippingFee: (json['shippingFee'] ?? 0).toDouble(),
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      digitalSubtotal: (json['digitalSubtotal'] ?? 0).toDouble(),
      physicalSubtotal: (json['physicalSubtotal'] ?? 0).toDouble(),
    );
  }
}

class CouponApplyResult {
  final String couponCode;
  final double couponDiscountUSD;
  final double subtotal;
  final double shippingFee;
  final double totalAmount;
  final double digitalSubtotal;
  final double physicalSubtotal;

  CouponApplyResult({
    required this.couponCode,
    required this.couponDiscountUSD,
    required this.subtotal,
    required this.shippingFee,
    required this.totalAmount,
    this.digitalSubtotal = 0,
    this.physicalSubtotal = 0,
  });

  factory CouponApplyResult.fromJson(Map<String, dynamic> json) {
    return CouponApplyResult(
      couponCode: json['couponCode'] as String? ?? '',
      couponDiscountUSD: (json['couponDiscountUSD'] ?? 0).toDouble(),
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      shippingFee: (json['shippingFee'] ?? 0).toDouble(),
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      digitalSubtotal: (json['digitalSubtotal'] ?? 0).toDouble(),
      physicalSubtotal: (json['physicalSubtotal'] ?? 0).toDouble(),
    );
  }
}

/// One entry from GET .../payment-methods — a store's own connected,
/// checkout-enabled gateway. Never carries any credential/secret data.
class GatewayPaymentMethod {
  final String provider;
  final String displayName;
  final String currency;

  GatewayPaymentMethod({required this.provider, required this.displayName, required this.currency});

  factory GatewayPaymentMethod.fromJson(Map<String, dynamic> json) {
    return GatewayPaymentMethod(
      provider: json['provider'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      currency: json['currency'] as String? ?? '',
    );
  }
}

/// GET .../payment-methods response — [currency] is the store's own bound
/// currency ('PKR'/'USD'), resolved and returned even when [methods] is
/// empty (nothing connected yet, or a multi-store cart — [currency] is null
/// in that second case, since there's no single store to resolve one for).
class GatewayPaymentMethodsResult {
  final String? currency;
  final List<GatewayPaymentMethod> methods;

  const GatewayPaymentMethodsResult({required this.currency, required this.methods});

  bool get isPakistanRegion => currency == 'PKR';

  factory GatewayPaymentMethodsResult.fromJson(Map<String, dynamic> json) {
    final methodsJson = json['methods'] as List<dynamic>? ?? [];
    return GatewayPaymentMethodsResult(
      currency: json['currency'] as String?,
      methods: methodsJson.map((e) => GatewayPaymentMethod.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

/// POST .../initiate response — exactly one of [redirectUrl] (Safepay-style
/// hosted checkout, open in a WebView) or [clientToken] (Stripe-style,
/// client-confirmed via the existing PaymentSheet flow) is set, discriminated
/// by [isRedirectBased]. [sessionId] must be sent back on confirm either way.
class GatewayPaymentSession {
  final String sessionId;
  final String? redirectUrl;
  final String? clientToken;

  GatewayPaymentSession({required this.sessionId, this.redirectUrl, this.clientToken});

  bool get isRedirectBased => redirectUrl != null && redirectUrl!.isNotEmpty;

  factory GatewayPaymentSession.fromJson(Map<String, dynamic> json) {
    return GatewayPaymentSession(
      sessionId: json['sessionId'] as String? ?? '',
      redirectUrl: json['redirectUrl'] as String?,
      clientToken: json['clientToken'] as String?,
    );
  }
}

/// A Stripe PaymentIntent's client secret, ready to hand to
/// `Stripe.instance.initPaymentSheet`.
class PaymentIntentResult {
  final String clientSecret;
  final String paymentIntentId;
  final double amount;
  final String currency;

  PaymentIntentResult({
    required this.clientSecret,
    required this.paymentIntentId,
    required this.amount,
    required this.currency,
  });

  factory PaymentIntentResult.fromJson(Map<String, dynamic> json) {
    return PaymentIntentResult(
      clientSecret: json['clientSecret'] as String? ?? '',
      paymentIntentId: json['paymentIntentId'] as String? ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      currency: json['currency'] as String? ?? 'USD',
    );
  }
}

/// 'pending' | 'completed' | 'failed'
class PaymentStatusResult {
  final String status;
  final List<String> orderIds;

  const PaymentStatusResult({required this.status, this.orderIds = const []});

  bool get isCompleted => status == 'completed';
  bool get isFailed => status == 'failed';
}
