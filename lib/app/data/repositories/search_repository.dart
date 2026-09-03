import 'package:book_store_app/app/data/models/search/recent_search_model.dart';
import 'package:book_store_app/app/modules/category/models/product_model.dart';
import 'package:book_store_app/app/network/api_constaints.dart';
import 'package:book_store_app/app/network/base_client.dart';
import 'package:book_store_app/app/network/dio_exception_handler.dart';
import 'package:book_store_app/shared_prefrences/app_prefrences.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

/// Product search + per-user search history — `solvexo-api`'s `api/search/*`
/// (`SearchController`). Search itself is public; auth is attached when
/// available so the backend records history and applies subscriber pricing.
class SearchRepository {
  final BaseClient _client = BaseClient();

  /// Keyword search — same response shape as products-by-category, so it
  /// reuses [ProductListResponse].
  Future<ProductListResponse?> searchProducts(
    String query, {
    int page = 1,
    int limit = 20,
    String? storeId,
  }) async {
    try {
      final response = await _client.get(
        ApiConstants.searchProducts,
        requiresAuth: await AppPreferences.isLoggedIn(),
        queryParameters: {
          'q': query,
          'page': page,
          'limit': limit,
          if (storeId != null && storeId.isNotEmpty) 'storeId': storeId,
        },
      );
      if (response.data['success'] == true) {
        return ProductListResponse.fromJson(response.data['data']);
      }
      return null;
    } on DioException catch (e) {
      DioExceptionHandler.handleDioException(e);
      return null;
    } catch (e) {
      debugPrint('❌ searchProducts error: $e');
      return null;
    }
  }

  Future<List<RecentSearchModel>?> getRecentSearches({int limit = 15, String? storeId}) async {
    try {
      final response = await _client.get(
        ApiConstants.recentSearches,
        requiresAuth: true,
        queryParameters: {
          'limit': limit,
          if (storeId != null && storeId.isNotEmpty) 'storeId': storeId,
        },
      );
      if (response.data['success'] == true) {
        return (response.data['data'] as List? ?? [])
            .map((e) => RecentSearchModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return null;
    } on DioException catch (e) {
      DioExceptionHandler.handleDioException(e);
      return null;
    } catch (e) {
      debugPrint('❌ getRecentSearches error: $e');
      return null;
    }
  }

  Future<bool> deleteRecentSearch(String searchId, {String? storeId}) async {
    try {
      final response = await _client.delete(
        ApiConstants.deleteRecentSearch(searchId),
        queryParameters: {
          if (storeId != null && storeId.isNotEmpty) 'storeId': storeId,
        },
      );
      return response.data['success'] == true;
    } on DioException catch (e) {
      DioExceptionHandler.handleDioException(e);
      return false;
    } catch (e) {
      debugPrint('❌ deleteRecentSearch error: $e');
      return false;
    }
  }

  Future<bool> clearRecentSearches({String? storeId}) async {
    try {
      final response = await _client.delete(
        ApiConstants.recentSearches,
        queryParameters: {
          if (storeId != null && storeId.isNotEmpty) 'storeId': storeId,
        },
      );
      return response.data['success'] == true;
    } on DioException catch (e) {
      DioExceptionHandler.handleDioException(e);
      return false;
    } catch (e) {
      debugPrint('❌ clearRecentSearches error: $e');
      return false;
    }
  }

  Future<List<ProductModel>?> getRecentlyViewed({int limit = 10, String? storeId}) async {
    try {
      final response = await _client.get(
        ApiConstants.recentlyViewed,
        requiresAuth: true,
        queryParameters: {
          'limit': limit,
          if (storeId != null && storeId.isNotEmpty) 'storeId': storeId,
        },
      );
      if (response.data['success'] == true) {
        final data = response.data['data'] as Map<String, dynamic>? ?? const {};
        return (data['products'] as List? ?? [])
            .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return null;
    } on DioException catch (e) {
      DioExceptionHandler.handleDioException(e);
      return null;
    } catch (e) {
      debugPrint('❌ getRecentlyViewed error: $e');
      return null;
    }
  }

  /// Records a product view: always in local prefs (works for guests and is
  /// the offline fallback), plus the backend when logged in. Fire-and-forget
  /// — never surfaces errors to the user.
  Future<void> recordProductView(String productId, {String? storeId}) async {
    if (productId.isEmpty) return;
    try {
      final ids = await AppPreferences.getRecentlyViewedProductIds() ?? [];
      ids.remove(productId);
      ids.insert(0, productId);
      if (ids.length > 20) ids.removeRange(20, ids.length);
      await AppPreferences.saveRecentlyViewedProductIds(ids);

      if (await AppPreferences.isLoggedIn()) {
        await _client.post(
          ApiConstants.recentlyViewed,
          data: {
            'productId': productId,
            if (storeId != null && storeId.isNotEmpty) 'storeId': storeId,
          },
        );
      }
    } catch (e) {
      debugPrint('❌ recordProductView error: $e');
    }
  }
}
