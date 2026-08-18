import 'package:book_store_app/app/data/models/refund_request_model.dart';
import 'package:book_store_app/app/network/api_constaints.dart';
import 'package:book_store_app/app/network/base_client.dart';
import 'package:book_store_app/app/network/dio_exception_handler.dart';
import 'package:book_store_app/utils/toast_util.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

/// Item-level refund request flow — `api/refund-request` — supersedes the old
/// free-text `orders/return-request`/`orders/returns`/`orders/return-action`
/// endpoints (left in place, unused, pending later removal).
class RefundRequestRepository {
  final BaseClient _client = BaseClient();
  static const _uuid = Uuid();

  /// Mutating POST is idempotent server-side — send a fresh key per attempt
  /// so a double-tap/retry can't create two refund requests.
  Map<String, dynamic> get _idempotencyHeader => {'Idempotency-Key': _uuid.v4()};

  /// POST /api/refund-request
  Future<bool> create({
    required String orderId,
    required String sellerOrderId,
    required List<String> itemIds,
    required String reason,
  }) async {
    try {
      final response = await _client.post(
        ApiConstants.createRefundRequest,
        data: {
          'orderId': orderId,
          'sellerOrderId': sellerOrderId,
          'itemIds': itemIds,
          'reason': reason,
        },
        headers: _idempotencyHeader,
        requiresAuth: true,
      );

      if (response.data['success'] == true) return true;

      ToastUtil.showToast(
        response.data['message'] as String? ?? 'Failed to submit refund request.',
      );
      return false;
    } on DioException catch (e) {
      debugPrint('❌ RefundRequestRepository.create DioException: ${e.response?.statusCode}');
      debugPrint('   Response: ${e.response?.data}');
      DioExceptionHandler.handleDioException(e);
      return false;
    } catch (e) {
      debugPrint('❌ RefundRequestRepository.create error: $e');
      ToastUtil.showToast('Failed to submit refund request.');
      return false;
    }
  }

  /// GET /api/refund-request/order/:orderId
  Future<List<RefundRequestModel>> listForOrder(String orderId) async {
    try {
      final response = await _client.get(
        ApiConstants.refundRequestsForOrder(orderId),
        requiresAuth: true,
      );

      if (response.data['success'] == true) {
        return (response.data['data'] as List? ?? [])
            .map((e) => RefundRequestModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      return [];
    } on DioException catch (e) {
      debugPrint('❌ RefundRequestRepository.listForOrder DioException: ${e.response?.statusCode}');
      debugPrint('   Response: ${e.response?.data}');
      DioExceptionHandler.handleDioException(e);
      return [];
    } catch (e) {
      debugPrint('❌ RefundRequestRepository.listForOrder error: $e');
      ToastUtil.showToast('Failed to load refund requests.');
      return [];
    }
  }

}
