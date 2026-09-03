import 'dart:async';

import 'package:book_store_app/app/data/repositories/product_repository.dart';
import 'package:book_store_app/app/data/repositories/search_repository.dart';
import 'package:book_store_app/app/data/services/current_store_service.dart';
import 'package:book_store_app/app/modules/category/models/product_model.dart';
import 'package:book_store_app/config/store_config.dart';
import 'package:book_store_app/utils/toast_util.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Backs the "Trending near you" See All screen — same source as Home's
/// default (categoryId: null) product feed, with a real server-side
/// paginated search box layered on top (switches to `SearchRepository`
/// while a query is active, same as `SearchBarController.performSearch`).
class TrendingProductsController extends GetxController {
  final ProductRepository _productRepository = ProductRepository();
  final SearchRepository _searchRepository = SearchRepository();

  final TextEditingController searchTextCtrl = TextEditingController();
  Timer? _debounce;

  final RxBool isLoading = true.obs;
  final RxBool isFetchingMore = false.obs;
  final RxList<ProductModel> products = <ProductModel>[].obs;

  final RxInt currentPage = 1.obs;
  final RxInt totalPages = 1.obs;
  final RxInt totalCount = 0.obs;
  final RxBool hasMore = true.obs;
  final RxString searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchProducts();
  }

  @override
  void onClose() {
    _debounce?.cancel();
    searchTextCtrl.dispose();
    super.onClose();
  }

  Future<void> fetchProducts({bool loadMore = false}) async {
    if (loadMore) {
      if (!hasMore.value || isFetchingMore.value) return;
      currentPage.value++;
      isFetchingMore.value = true;
    } else {
      currentPage.value = 1;
      isLoading.value = true;
    }

    try {
      if (!StoreConfig.isConfigured) {
        products.clear();
        hasMore.value = false;
        return;
      }
      await Get.find<CurrentStoreService>().ensureResolved();
      final storeId = Get.find<CurrentStoreService>().storeId;
      if (storeId == null || storeId.isEmpty) {
        products.clear();
        hasMore.value = false;
        return;
      }

      final query = searchQuery.value.trim();
      final response = query.isEmpty
          ? await _productRepository.getProductsByCategory(
              page: currentPage.value,
              limit: 20,
              storeId: storeId,
            )
          : await _searchRepository.searchProducts(
              query,
              page: currentPage.value,
              limit: 20,
              storeId: storeId,
            );

      if (response != null) {
        if (loadMore) {
          products.addAll(response.products);
        } else {
          products.assignAll(response.products);
        }
        totalPages.value = response.pages;
        totalCount.value = response.total;
        hasMore.value = currentPage.value < response.pages;
      } else if (!loadMore) {
        products.clear();
        totalPages.value = 1;
        totalCount.value = 0;
        hasMore.value = false;
      }
    } catch (e) {
      debugPrint('❌ Error fetching trending products: $e');
      ToastUtil.showToast('Failed to load products');
      if (loadMore) currentPage.value--;
    } finally {
      isLoading.value = false;
      isFetchingMore.value = false;
    }
  }

  Future<void> loadMoreProducts() => fetchProducts(loadMore: true);

  /// Debounced (400ms) — same feel as `SearchBarController.onSearchChanged`.
  void onSearchChanged(String value) {
    searchQuery.value = value;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), fetchProducts);
  }

  void clearSearch() {
    searchQuery.value = '';
    searchTextCtrl.clear();
    _debounce?.cancel();
    fetchProducts();
  }
}
