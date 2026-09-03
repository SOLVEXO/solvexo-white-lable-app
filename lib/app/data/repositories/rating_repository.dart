import 'package:book_store_app/app/data/models/rating/review_model.dart';
import 'package:book_store_app/app/network/api_constaints.dart';
import 'package:book_store_app/app/network/base_client.dart';
import 'package:book_store_app/app/network/dio_exception_handler.dart';
import 'package:book_store_app/shared_prefrences/app_prefrences.dart';
import 'package:book_store_app/utils/toast_util.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

/// Product reviews — `solvexo-api`'s `/api/rating/*` (`RatingController`).
class RatingRepository {
  final BaseClient _client = BaseClient();

  /// Writes a new review, or — if the buyer already reviewed this product —
  /// appends an extra comment to it (mirrors the backend's `addReview`
  /// upsert-like behaviour).
  Future<bool> addReview({
    required String productId,
    String? productVariantId,
    String? orderId,
    double? rating,
    String? comment,
    bool? isAnonymous,
    String? storeId,
  }) async {
    try {
      final response = await _client.post(
        ApiConstants.addReview,
        data: {
          'productId': productId,
          if (productVariantId != null) 'productVariantId': productVariantId,
          if (orderId != null) 'orderId': orderId,
          if (rating != null) 'rating': rating,
          if (comment != null && comment.isNotEmpty) 'comment': comment,
          if (isAnonymous != null) 'isAnonymous': isAnonymous,
          if (storeId != null && storeId.isNotEmpty) 'storeId': storeId,
        },
      );
      return response.data['success'] == true;
    } on DioException catch (e) {
      DioExceptionHandler.handleDioException(e);
      return false;
    } catch (e) {
      debugPrint('❌ addReview error: $e');
      ToastUtil.showToast('Could not submit your review.');
      return false;
    }
  }

  Future<bool> editReview(String reviewId, {double? rating, String? comment, String? storeId}) async {
    try {
      final response = await _client.patch(
        ApiConstants.editReview(reviewId),
        data: {
          if (rating != null) 'rating': rating,
          if (comment != null) 'comment': comment,
          if (storeId != null && storeId.isNotEmpty) 'storeId': storeId,
        },
      );
      return response.data['success'] == true;
    } on DioException catch (e) {
      DioExceptionHandler.handleDioException(e);
      return false;
    } catch (e) {
      debugPrint('❌ editReview error: $e');
      return false;
    }
  }

  Future<bool> deleteReview(String reviewId, {String? storeId}) async {
    try {
      final response = await _client.delete(
        ApiConstants.deleteReview(reviewId),
        queryParameters: {
          if (storeId != null && storeId.isNotEmpty) 'storeId': storeId,
        },
      );
      return response.data['success'] == true;
    } on DioException catch (e) {
      DioExceptionHandler.handleDioException(e);
      return false;
    } catch (e) {
      debugPrint('❌ deleteReview error: $e');
      return false;
    }
  }

  Future<({List<ReviewModel> reviews, int total, int totalPages})> getMyReviews({int page = 1, String? storeId}) async {
    try {
      final response = await _client.get(
        ApiConstants.myReviews,
        requiresAuth: true,
        queryParameters: {
          'page': page,
          if (storeId != null && storeId.isNotEmpty) 'storeId': storeId,
        },
      );
      final data = response.data['data'] as Map<String, dynamic>;
      final pagination = data['pagination'] as Map<String, dynamic>? ?? {};
      final reviews = (data['reviews'] as List? ?? [])
          .map((r) => ReviewModel.fromJson(r as Map<String, dynamic>))
          .toList();
      return (
        reviews: reviews,
        total: pagination['total'] as int? ?? reviews.length,
        totalPages: pagination['totalPages'] as int? ?? 1,
      );
    } on DioException catch (e) {
      DioExceptionHandler.handleDioException(e);
      return (reviews: <ReviewModel>[], total: 0, totalPages: 0);
    } catch (e) {
      debugPrint('❌ getMyReviews error: $e');
      return (reviews: <ReviewModel>[], total: 0, totalPages: 0);
    }
  }

  /// [sort]: newest | oldest | highest_rating | lowest_rating | most_helpful.
  /// Sends auth when logged in so the backend can fill `helpfulByMe`
  /// (the route uses an optional-JWT guard, so guests still work).
  Future<({ReviewStats stats, List<ReviewModel> reviews, bool hasMore})> getProductReviews(
    String productId, {
    int page = 1,
    int limit = 10,
    String? sort,
    bool? hasMedia,
    bool? verifiedOnly,
  }) async {
    try {
      final response = await _client.get(
        ApiConstants.productReviews(productId),
        requiresAuth: await AppPreferences.isLoggedIn(),
        queryParameters: {
          'page': page,
          'limit': limit,
          if (sort != null) 'sort': sort,
          if (hasMedia == true) 'hasMedia': 'true',
          if (verifiedOnly == true) 'verifiedOnly': 'true',
        },
      );
      final data = response.data['data'] as Map<String, dynamic>;
      final pagination = data['pagination'] as Map<String, dynamic>? ?? {};
      final reviews = (data['reviews'] as List? ?? [])
          .map((r) => ReviewModel.fromJson(r as Map<String, dynamic>))
          .toList();
      final currentPage = pagination['page'] as int? ?? page;
      final totalPages = pagination['totalPages'] as int? ?? 1;
      return (
        stats: ReviewStats.fromJson(data['stats'] as Map<String, dynamic>? ?? {}),
        reviews: reviews,
        hasMore: currentPage < totalPages,
      );
    } on DioException catch (e) {
      DioExceptionHandler.handleDioException(e);
      return (stats: const ReviewStats(), reviews: <ReviewModel>[], hasMore: false);
    } catch (e) {
      debugPrint('❌ getProductReviews error: $e');
      return (stats: const ReviewStats(), reviews: <ReviewModel>[], hasMore: false);
    }
  }

  /// Toggles the caller's "helpful" vote on a review. Returns the new
  /// `(helpfulCount, helpfulByMe)` from the backend, or null on failure.
  Future<({int helpfulCount, bool helpfulByMe})?> toggleHelpful(String reviewId) async {
    try {
      final response = await _client.post(ApiConstants.reviewHelpful(reviewId));
      if (response.data['success'] == true) {
        final data = response.data['data'] as Map<String, dynamic>? ?? {};
        return (
          helpfulCount: data['helpfulCount'] as int? ?? 0,
          helpfulByMe: data['helpfulByMe'] as bool? ?? false,
        );
      }
      return null;
    } on DioException catch (e) {
      DioExceptionHandler.handleDioException(e);
      return null;
    } catch (e) {
      debugPrint('❌ toggleHelpful error: $e');
      return null;
    }
  }
}
