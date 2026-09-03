import 'package:book_store_app/app/modules/category/models/category_model.dart';
import 'package:book_store_app/app/modules/category/models/product_model.dart';
import 'package:book_store_app/app/modules/product_details/models/product_detail_response.dart';
import 'package:book_store_app/app/modules/product_preview/models/product_preview_model.dart';
import 'package:book_store_app/app/network/api_constaints.dart';
import 'package:book_store_app/app/network/base_client.dart';
import 'package:book_store_app/app/network/dio_exception_handler.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class ProductRepository {
  final BaseClient _baseClient = BaseClient();
  Future<ProductListResponse?> getProductsByCategory({
    String? categoryId,
    int page = 1,
    int limit = 10,
    String? productType,
    String? educationLevel,
    String? normalizedCustomLevel,
    double? minPrice,
    double? maxPrice,
    double? minRating,
    String? sortBy,
    String? storeId,
  }) async {
    try {
      final url = ApiConstants.getProductsByCategory(
        categoryId: categoryId,
        page: page,
        limit: limit,
        productType: productType,
        educationLevel: educationLevel,
        normalizedCustomLevel: normalizedCustomLevel,
        minPrice: minPrice,
        maxPrice: maxPrice,
        minRating: minRating,
        sortBy: sortBy,
        storeId: storeId,
      );
      final response = await _baseClient.get(url);
      if (response.data['success'] == true) {
        return ProductListResponse.fromJson(response.data['data']);
      }
      return null;
    } on DioException catch (e) {
      DioExceptionHandler.handleDioException(e);
      return null;
    }
  }

  /// Buyer-facing, unauthenticated facet counts backing the education-level
  /// filter chips on category/sub-category browsing.
  Future<EducationFacetsResult> getEducationFacets() async {
    try {
      final response = await _baseClient.get(ApiConstants.educationFacets);
      if (response.data['success'] == true) {
        return EducationFacetsResult.fromJson(
          response.data['data'] as Map<String, dynamic>,
        );
      }
      return const EducationFacetsResult(levels: [], otherLevels: []);
    } catch (e) {
      debugPrint("Get Education Facets error --> $e");
      return const EducationFacetsResult(levels: [], otherLevels: []);
    }
  }

  /// Seller-only autocomplete while typing a custom education level.
  Future<List<String>> getCustomLevelSuggestions(String q) async {
    if (q.trim().isEmpty) return [];
    try {
      final response = await _baseClient.get(
        ApiConstants.educationCustomLevelSuggestions(q),
        requiresAuth: true,
      );
      if (response.data['success'] == true) {
        return (response.data['data'] as List? ?? []).cast<String>();
      }
      return [];
    } catch (e) {
      debugPrint("Get Custom Level Suggestions error --> $e");
      return [];
    }
  }

  /// Get single product by ID
  Future<ProductModel?> getProductById(String productId, {String? storeId}) async {
    try {
      final response = await _baseClient.get(
        ApiConstants.getProductById(productId, storeId: storeId),
      );

      debugPrint("Get Product By ID Response --> ${response.data}");

      if (response.statusCode == 200 && response.data['success'] == true) {
        return ProductModel.fromJson(response.data['data']);
      }

      return null;
    } on DioException catch (e) {
      DioExceptionHandler.handleDioException(e);
      return null;
    } catch (e) {
      debugPrint("Get Product By ID error --> $e");
      return null;
    }
  }

  Future<ProductDetailResponse?> getProductDetailById(String id, {String? storeId}) async {
    try {
      final response = await _baseClient.get(ApiConstants.getProductById(id, storeId: storeId));
      if (response.data['success'] == true) {
        return ProductDetailResponse.fromJson(response.data);
      }
      return null;
    } on DioException catch (e) {
      DioExceptionHandler.handleDioException(e);
      return null;
    }
  }

  Future<VariantDetailResponse?> getVariantById(String variantId, {String? storeId}) async {
    try {
      final response = await _baseClient.get(
        ApiConstants.getVariantById(variantId, storeId: storeId),
      );
      if (response.data['success'] == true) {
        return VariantDetailResponse.fromJson(response.data);
      }
      return null;
    } on DioException catch (e) {
      DioExceptionHandler.handleDioException(e);
      return null;
    }
  }

  /// Public, pre-purchase preview of a digital product — a watermarked/trimmed
  /// derivative only, never the original file.
  Future<ProductPreviewModel?> getProductPreview(String productId, {String? storeId}) async {
    try {
      final response = await _baseClient.get(
        ApiConstants.getProductPreview(productId, storeId: storeId),
      );
      if (response.data['success'] == true) {
        return ProductPreviewModel.fromJson(response.data['data']);
      }
      return null;
    } on DioException catch (e) {
      DioExceptionHandler.handleDioException(e);
      return null;
    }
  }

  /// Get all categories. Pass this build's [storeId] so the backend returns
  /// this store's own tree instead of the legacy global/admin roots it falls
  /// back to when storeId is omitted.
  Future<List<CategoryModel>?> getCategories({String? storeId}) async {
    try {
      final response = await _baseClient.get(
        storeId != null && storeId.isNotEmpty
            ? ApiConstants.storeCategories(storeId)
            : ApiConstants.categories,
      );

      debugPrint("Get Categories Response --> ${response.data}");

      if (response.statusCode == 200 && response.data['success'] == true) {
        return (response.data['data'] as List)
            .map((category) => CategoryModel.fromJson(category))
            .toList();
      }

      return null;
    } on DioException catch (e) {
      DioExceptionHandler.handleDioException(e);
      return null;
    } catch (e) {
      debugPrint("Get Categories error --> $e");
      return null;
    }
  }
}
