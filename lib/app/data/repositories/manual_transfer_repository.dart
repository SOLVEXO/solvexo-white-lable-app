import 'dart:io';
import 'package:book_store_app/app/data/models/payment/manual_payment_model.dart';
import 'package:book_store_app/app/network/api_constaints.dart';
import 'package:book_store_app/app/network/base_client.dart';
import 'package:book_store_app/app/network/dio_exception_handler.dart';
import 'package:book_store_app/utils/toast_util.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

/// The Pakistan "pay into the platform's own bank account, upload proof"
/// track — `api/payment/manual-transfer/*`. Same `{success, message, data}`
/// envelope as `CheckoutRepository`'s COD/Stripe methods (its sibling routes
/// under `api/payment/*`).
class ManualTransferRepository {
  final BaseClient _client = BaseClient();

  /// GET /api/payment/manual-transfer/bank-details
  Future<ManualPaymentBankDetails?> getBankDetails() async {
    try {
      final response = await _client.get(ApiConstants.manualTransferBankDetails, requiresAuth: true);
      if (response.data['success'] == true) {
        return ManualPaymentBankDetails.fromJson(response.data['data'] as Map<String, dynamic>);
      }
      ToastUtil.showToast(response.data['message'] as String? ?? 'Bank transfer is not available right now.');
      return null;
    } on DioException catch (e) {
      DioExceptionHandler.handleDioException(e);
      return null;
    } catch (e) {
      debugPrint('❌ getBankDetails error: $e');
      return null;
    }
  }

  /// POST /api/payment/manual-transfer/submit (multipart) — places the
  /// order(s) and attaches the buyer's uploaded receipt in one step.
  Future<({bool success, ManualPaymentProof? proof, String? message})> submitPayment({
    required String checkoutId,
    required File proofImage,
    String? transactionReference,
    String? senderName,
  }) async {
    try {
      final filename = proofImage.path.split('/').last;
      final formData = FormData.fromMap({
        'checkoutId': checkoutId,
        if (transactionReference != null && transactionReference.isNotEmpty) 'transactionReference': transactionReference,
        if (senderName != null && senderName.isNotEmpty) 'senderName': senderName,
        'file': await MultipartFile.fromFile(proofImage.path, filename: filename),
      });

      final response = await _client.post(
        ApiConstants.manualTransferSubmit,
        data: formData,
        requiresAuth: true,
      );

      if (response.data['success'] == true) {
        final data = response.data['data'] as Map<String, dynamic>;
        return (
          success: true,
          proof: ManualPaymentProof.fromJson(data['proof'] as Map<String, dynamic>),
          message: response.data['message'] as String?,
        );
      }
      return (success: false, proof: null, message: response.data['message'] as String?);
    } on DioException catch (e) {
      final data = e.response?.data;
      final message = data is Map ? data['message'] as String? : null;
      DioExceptionHandler.handleDioException(e, showToast: false);
      return (success: false, proof: null, message: message ?? 'Failed to submit payment proof');
    } catch (e) {
      debugPrint('❌ submitPayment error: $e');
      return (success: false, proof: null, message: 'Failed to submit payment proof');
    }
  }

  /// POST /api/payment/manual-transfer/:proofId/reupload (multipart) — after
  /// a rejection, try again with a fresh screenshot/reference.
  Future<({bool success, ManualPaymentProof? proof, String? message})> reuploadPayment({
    required String proofId,
    required File proofImage,
    String? transactionReference,
    String? senderName,
  }) async {
    try {
      final filename = proofImage.path.split('/').last;
      final formData = FormData.fromMap({
        if (transactionReference != null && transactionReference.isNotEmpty) 'transactionReference': transactionReference,
        if (senderName != null && senderName.isNotEmpty) 'senderName': senderName,
        'file': await MultipartFile.fromFile(proofImage.path, filename: filename),
      });

      final response = await _client.post(
        ApiConstants.manualTransferReupload(proofId),
        data: formData,
        requiresAuth: true,
      );

      if (response.data['success'] == true) {
        return (
          success: true,
          proof: ManualPaymentProof.fromJson(response.data['data'] as Map<String, dynamic>),
          message: response.data['message'] as String?,
        );
      }
      return (success: false, proof: null, message: response.data['message'] as String?);
    } on DioException catch (e) {
      final data = e.response?.data;
      final message = data is Map ? data['message'] as String? : null;
      DioExceptionHandler.handleDioException(e, showToast: false);
      return (success: false, proof: null, message: message ?? 'Failed to re-upload payment proof');
    } catch (e) {
      debugPrint('❌ reuploadPayment error: $e');
      return (success: false, proof: null, message: 'Failed to re-upload payment proof');
    }
  }

  /// GET /api/payment/manual-transfer/:proofId — poll this to refresh status.
  Future<ManualPaymentProof?> getProofStatus(String proofId, {String? storeId}) async {
    try {
      final response = await _client.get(
        ApiConstants.manualTransferProofById(proofId),
        requiresAuth: true,
        queryParameters: {
          if (storeId != null && storeId.isNotEmpty) 'storeId': storeId,
        },
      );
      if (response.data['success'] == true) {
        return ManualPaymentProof.fromJson(response.data['data'] as Map<String, dynamic>);
      }
      return null;
    } on DioException catch (e) {
      DioExceptionHandler.handleDioException(e, showToast: false);
      return null;
    } catch (e) {
      debugPrint('❌ getProofStatus error: $e');
      return null;
    }
  }

  /// GET /api/payment/manual-transfer — every proof the buyer has ever submitted.
  Future<List<ManualPaymentProof>> getMyProofs({String? storeId}) async {
    try {
      final response = await _client.get(
        ApiConstants.manualTransferMyProofs,
        requiresAuth: true,
        queryParameters: {
          if (storeId != null && storeId.isNotEmpty) 'storeId': storeId,
        },
      );
      if (response.data['success'] == true) {
        return (response.data['data'] as List).cast<Map<String, dynamic>>().map(ManualPaymentProof.fromJson).toList();
      }
      return [];
    } on DioException catch (e) {
      DioExceptionHandler.handleDioException(e);
      return [];
    } catch (e) {
      debugPrint('❌ getMyProofs error: $e');
      return [];
    }
  }
}
