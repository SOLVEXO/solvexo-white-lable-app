import 'package:book_store_app/app/data/models/storefront/storefront_model.dart';
import 'package:book_store_app/app/modules/category/models/product_model.dart';
import 'package:book_store_app/app/network/api_constaints.dart';
import 'package:book_store_app/app/network/base_client.dart';
import 'package:book_store_app/app/network/dio_exception_handler.dart';
import 'package:book_store_app/utils/toast_util.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

/// A seller's public-facing storefront — profile, product catalog, filters,
/// and follow/unfollow. Distinct from [SellerRepository], which is the
/// seller's own store *management* API.
class StorefrontRepository {
  final BaseClient _client = BaseClient();

  // ─── GET /api/store/public/:slug ───────────────────────────────────────────

  Future<StorefrontModel?> getStoreBySlug(String slug) async {
    try {
      final response = await _client.get(ApiConstants.publicStoreBySlug(slug));
      if (response.data['success'] == true) {
        return StorefrontModel.fromJson(response.data['data'] as Map<String, dynamic>);
      }
      return null;
    } on DioException catch (e) {
      DioExceptionHandler.handleDioException(e);
      return null;
    } catch (e) {
      debugPrint('❌ getStoreBySlug error: $e');
      return null;
    }
  }

  // ─── GET /api/store/public/:storeId/products ───────────────────────────────

  Future<({List<ProductModel> products, int total, int totalPages, bool hasMore})>
      getStoreProducts({
    required String storeId,
    int page = 1,
    int limit = 12,
    String? type,
    String? categoryId,
    String? tag,
    String sort = 'newest', // newest | price_asc | price_desc | best_rated
  }) async {
    try {
      final response = await _client.get(
        ApiConstants.publicStoreProducts(storeId),
        queryParameters: {
          'page': page,
          'limit': limit,
          'sort': sort,
          if (type != null && type != 'all') 'type': type,
          if (categoryId != null && categoryId != 'all') 'categoryId': categoryId,
          if (tag != null && tag != 'all') 'tag': tag,
        },
      );

      if (response.data['success'] == true) {
        final data = response.data['data'] as Map<String, dynamic>;
        final pagination = data['pagination'] as Map<String, dynamic>? ?? {};
        final products = (data['products'] as List? ?? [])
            .map((p) => ProductModel.fromJson(p as Map<String, dynamic>))
            .toList();
        final currentPage = pagination['page'] as int? ?? page;
        final totalPages = pagination['totalPages'] as int? ?? 1;
        return (
          products: products,
          total: pagination['total'] as int? ?? products.length,
          totalPages: totalPages,
          hasMore: currentPage < totalPages,
        );
      }
      return (products: <ProductModel>[], total: 0, totalPages: 0, hasMore: false);
    } on DioException catch (e) {
      DioExceptionHandler.handleDioException(e);
      return (products: <ProductModel>[], total: 0, totalPages: 0, hasMore: false);
    } catch (e) {
      debugPrint('❌ getStoreProducts error: $e');
      ToastUtil.showToast('Failed to load products.');
      return (products: <ProductModel>[], total: 0, totalPages: 0, hasMore: false);
    }
  }

  // ─── GET /api/store/public/:storeId/filters ────────────────────────────────

  Future<List<String>> getStoreFilterTags(String storeId) async {
    try {
      final response = await _client.get(ApiConstants.publicStoreFilters(storeId));
      if (response.data['success'] == true) {
        final data = response.data['data'] as Map<String, dynamic>;
        return (data['tags'] as List?)?.cast<String>() ?? const [];
      }
      return const [];
    } on DioException catch (e) {
      DioExceptionHandler.handleDioException(e);
      return const [];
    } catch (e) {
      debugPrint('❌ getStoreFilterTags error: $e');
      return const [];
    }
  }

  // ─── GET /api/products/store/:storeId/{pinned,new-arrivals,best-sellers,trending} ──
  // Storefront promotion sections (`ProductsController`, public/optional-auth).
  // All 4 share the same `{success, data: {products}}` shape.

  Future<List<ProductModel>> getPinnedProducts(String storeId) => _getProductSection(ApiConstants.productsPinned(storeId));
  Future<List<ProductModel>> getNewArrivals(String storeId) => _getProductSection(ApiConstants.productsNewArrivals(storeId));
  Future<List<ProductModel>> getBestSellers(String storeId) => _getProductSection(ApiConstants.productsBestSellers(storeId));
  Future<List<ProductModel>> getTrending(String storeId) => _getProductSection(ApiConstants.productsTrending(storeId));

  Future<List<ProductModel>> _getProductSection(String url) async {
    try {
      final response = await _client.get(url);
      if (response.data['success'] == true) {
        final data = response.data['data'] as Map<String, dynamic>;
        final products = data['products'] as List? ?? [];
        return products.map((p) => ProductModel.fromJson(p as Map<String, dynamic>)).toList();
      }
      return const [];
    } catch (e) {
      // Every merchandising section is additive/optional — silently render
      // nothing rather than surface an error toast on a buyer's storefront view.
      debugPrint('❌ storefront product section error ($url): $e');
      return const [];
    }
  }

}
