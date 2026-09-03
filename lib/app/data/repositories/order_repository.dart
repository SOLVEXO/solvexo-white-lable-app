import 'package:book_store_app/app/data/models/orders/digital_download_file_model.dart';
import 'package:book_store_app/app/modules/myorders/models/my_order_model.dart';
import 'package:book_store_app/app/network/api_constaints.dart';
import 'package:book_store_app/app/network/base_client.dart';
import 'package:book_store_app/app/network/dio_exception_handler.dart';
import 'package:book_store_app/utils/toast_util.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class OrderRepository {
  final BaseClient _baseClient = BaseClient();

  /// GET /api/orders/my-orders
  Future<List<OrderModel>> getMyOrders({int page = 1, int limit = 20, String? storeId}) async {
    try {
      debugPrint('🔄 Fetching my orders (page $page)...');

      final response = await _baseClient.get(
        ApiConstants.myOrders,
        queryParameters: {
          'page': page,
          'limit': limit,
          if (storeId != null && storeId.isNotEmpty) 'storeId': storeId,
        },
        requiresAuth: true,
      );

      debugPrint('✅ Get My Orders status: ${response.statusCode}');

      if (response.data['success'] == true) {
        final data = response.data['data'] as Map<String, dynamic>;
        final orderList = (data['orders'] as List? ?? [])
            .map((e) => OrderModel.fromJson(e as Map<String, dynamic>))
            .toList();
        debugPrint('✅ Parsed ${orderList.length} orders');
        return orderList;
      }

      debugPrint('⚠️ Response not successful: ${response.data}');
      return [];
    } catch (e) {
      debugPrint('❌ Get My Orders error: $e');
      rethrow;
    }
  }


  /// Get single order by ID
  Future<OrderModel?> getOrderById(String orderId, {String? storeId}) async {
    try {
      // final token = await AppPreferences.getAccessTokenAsync();

      debugPrint('🔄 Fetching order: $orderId');

      final response = await _baseClient.get(
        '${ApiConstants.orders}/$orderId',
        queryParameters: {
          if (storeId != null && storeId.isNotEmpty) 'storeId': storeId,
        },
        requiresAuth: true,
      );

      debugPrint('✅ Get Order Response: ${response.data}');

      if (response.data['success'] == true) {
        return OrderModel.fromJson(response.data['data']);
      }

      return null;
    } catch (e) {
      debugPrint('❌ Get Order error: $e');
      rethrow;
    }
  }

  /// Cancel order — POST /api/orders/cancel/:orderId, body: { reason }
  Future<bool> cancelOrder(String orderId, {required String reason, String? storeId}) async {
    try {
      debugPrint('🔄 Cancelling order: $orderId');

      final response = await _baseClient.post(
        ApiConstants.cancelOrder(orderId),
        data: {
          'reason': reason,
          if (storeId != null && storeId.isNotEmpty) 'storeId': storeId,
        },
      );

      debugPrint('✅ Cancel Order Response: ${response.data}');

      return response.data['success'] == true;
    } catch (e) {
      debugPrint('❌ Cancel Order error: $e');
      rethrow;
    }
  }

  /// Request a return/refund for a delivered order —
  /// POST /api/orders/return-request/:orderId, body: { reason, itemIds? }
  Future<bool> requestReturn({
    required String orderId,
    required String reason,
    List<String>? itemIds,
    String? storeId,
  }) async {
    try {
      debugPrint('🔄 Requesting return for order: $orderId');

      final response = await _baseClient.post(
        ApiConstants.returnRequest(orderId),
        data: {
          'reason': reason,
          if (itemIds != null && itemIds.isNotEmpty) 'itemIds': itemIds,
          if (storeId != null && storeId.isNotEmpty) 'storeId': storeId,
        },
      );

      debugPrint('✅ Return Request Response: ${response.data}');

      if (response.data['success'] == true) return true;

      ToastUtil.showToast(
        response.data['message'] as String? ?? 'Failed to submit refund request.',
      );
      return false;
    } on DioException catch (e) {
      debugPrint('❌ Return Request DioException: ${e.response?.statusCode}');
      debugPrint('   Response: ${e.response?.data}');
      DioExceptionHandler.handleDioException(e);
      return false;
    } catch (e) {
      debugPrint('❌ Return Request error: $e');
      ToastUtil.showToast('Failed to submit refund request.');
      return false;
    }
  }

  /// Update order to paid
  Future<bool> updateOrderToPaid({
    required String orderId,
    required String paymentId,
    required String paymentStatus,
    String? emailAddress,
  }) async {
    try {
      // final token = await AppPreferences.getAccessTokenAsync();

      debugPrint('🔄 Updating order to paid: $orderId');

      final response = await _baseClient.put(
        '${ApiConstants.orders}/$orderId/pay',

        data: {
          'id': paymentId,
          'status': paymentStatus,
          'update_time': DateTime.now().toIso8601String(),
          'email_address': emailAddress,
        },
      );

      debugPrint('✅ Update to Paid Response: ${response.data}');

      return response.data['success'] == true;
    } catch (e) {
      debugPrint('❌ Update to Paid error: $e');
      rethrow;
    }
  }

  // ─── Digital product delivery ──────────────────────────────────────────────

  /// GET /api/orders/download-url — signed, short-lived (10-min) tokens for
  /// every file in a purchased digital product. Requires the order to be paid.
  Future<List<DigitalDownloadFile>> getDigitalDownloadLinks({
    required String orderId,
    required String productId,
    String? storeId,
  }) async {
    try {
      final response = await _baseClient.get(
        ApiConstants.ordersDownloadUrl,
        queryParameters: {
          'orderId': orderId,
          'productId': productId,
          if (storeId != null && storeId.isNotEmpty) 'storeId': storeId,
        },
        requiresAuth: true,
      );

      if (response.data['success'] == true) {
        final data = response.data['data'] as Map<String, dynamic>;
        return (data['files'] as List? ?? [])
            .map((e) => DigitalDownloadFile.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      ToastUtil.showToast(response.data['message'] as String? ?? 'Failed to get download link.');
      return [];
    } on DioException catch (e) {
      debugPrint('❌ getDigitalDownloadLinks DioException: ${e.response?.statusCode}');
      debugPrint('   Response: ${e.response?.data}');
      DioExceptionHandler.handleDioException(e);
      return [];
    } catch (e) {
      debugPrint('❌ getDigitalDownloadLinks error: $e');
      ToastUtil.showToast('Failed to get download link.');
      return [];
    }
  }

  /// Fetches the raw bytes for one token'd file (the `download-file` /
  /// `stream-pdf-token` endpoints are token-authenticated, not JWT-header
  /// authenticated — the backend streams the file itself, not JSON).
  Future<List<int>?> fetchDigitalFileBytes(DigitalDownloadFile file) async {
    try {
      final response = await _baseClient.get(
        '${ApiConstants.baseUrl}${file.endpoint}',
        queryParameters: {'token': file.token},
        responseType: ResponseType.bytes,
      );
      return response.data as List<int>;
    } on DioException catch (e) {
      debugPrint('❌ fetchDigitalFileBytes DioException: ${e.response?.statusCode}');
      ToastUtil.showToast('Download link expired or invalid. Please try again.');
      return null;
    } catch (e) {
      debugPrint('❌ fetchDigitalFileBytes error: $e');
      ToastUtil.showToast('Failed to download file.');
      return null;
    }
  }
}
