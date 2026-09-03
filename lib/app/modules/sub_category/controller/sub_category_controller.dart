import 'package:book_store_app/app/components/product_filter_bottom_sheet.dart';
import 'package:book_store_app/app/data/repositories/product_repository.dart';
import 'package:book_store_app/app/data/services/current_store_service.dart';
import 'package:book_store_app/app/modules/category/controllers/category_controller.dart';
import 'package:book_store_app/app/modules/category/models/category_model.dart';
import 'package:book_store_app/app/modules/category/models/product_model.dart';
import 'package:book_store_app/config/store_config.dart';
import 'package:book_store_app/utils/toast_util.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SubCategoryController extends GetxController {
  SubCategoryController({
    ProductRepository? productRepository,
    String? categoryId,
    String? categoryName,
  }) : _productRepository = productRepository ?? ProductRepository(),
       _initialCategoryId = categoryId,
       _initialCategoryName = categoryName;

  final ProductRepository _productRepository;
  final String? _initialCategoryId;
  final String? _initialCategoryName;

  // ─── Arguments ────────────────────────────────────────────────────────────
  late final String categoryId;
  late final String categoryName;

  // ─── State ────────────────────────────────────────────────────────────────
  final RxList<CategoryModel> subCategories = <CategoryModel>[].obs;
  final RxList<ProductModel> products = <ProductModel>[].obs;
  final RxInt selectedSubCategoryIndex = 0.obs; // 0 = All

  final RxBool isLoadingProducts = false.obs;
  final RxBool isLoadingSubCategories = false.obs;

  // ─── Pagination ───────────────────────────────────────────────────────────
  final RxInt currentPage = 1.obs;
  final RxInt totalPages = 1.obs;
  final RxBool hasMoreProducts = true.obs;

  // ─── Filters ──────────────────────────────────────────────────────────────
  static const double priceBoundMin = 0.0;
  static const double priceBoundMax = 1000.0;
  final RxDouble currentMinFilter = priceBoundMin.obs;
  final RxDouble currentMaxFilter = priceBoundMax.obs;
  final RxDouble selectedRating = 0.0.obs;
  final RxString selectedSort = 'newest'.obs;

  // Education-level facets (Tier-1 + Tier-2 "other" drill-down). Facet counts
  // are global (not scoped to this category), but the filter section itself
  // is only shown once any educational products actually appear here — see
  // [hasEducationalProducts].
  final Rx<EducationFacetsResult> educationFacets = Rx(
    const EducationFacetsResult(levels: [], otherLevels: []),
  );
  final Rxn<String> selectedEducationLevel = Rxn<String>();
  final Rxn<String> selectedNormalizedCustomLevel = Rxn<String>();

  bool get hasEducationalProducts =>
      products.any((p) => p.isEducational) ||
      selectedEducationLevel.value != null;

  // ─── Currently selected sub-category ID ──────────────────────────────────
  String? get _activeSubCategoryId {
    if (selectedSubCategoryIndex.value == 0) return null; // All
    final idx = selectedSubCategoryIndex.value - 1;
    if (idx < subCategories.length) return subCategories[idx].id;
    return null;
  }

  // ─── Lifecycle ────────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    _readArguments();
    // Run in parallel — sub-categories chip strip + initial products + facets
    Future.wait([
      fetchSubCategories(),
      fetchProducts(),
      fetchEducationFacets(),
    ]);
  }

  Future<void> fetchEducationFacets() async {
    educationFacets.value = await _productRepository.getEducationFacets();
  }

  void _readArguments() {
    final args = Get.arguments as Map<String, dynamic>?;
    categoryId = _initialCategoryId ?? args?['categoryId'] as String? ?? '';
    categoryName =
        _initialCategoryName ?? args?['categoryName'] as String? ?? 'Products';
    debugPrint(
      '📦 SubCategoryController init — '
      'id: $categoryId, name: $categoryName',
    );
  }

  // ─── 1. Fetch sub-categories ──────────────────────────────────────────────
  // Reads children of the current category from CategoryController.
  // CategoryController already has the full tree loaded — no extra API call.

  Future<void> fetchSubCategories() async {
    try {
      isLoadingSubCategories.value = true;

      // Try to find this category in the already-loaded tree
      final categoryController = Get.find<CategoryController>();

      // Search flat list for this category
      CategoryModel? match;
      try {
        match = categoryController.allCategoriesFlat.firstWhere(
          (c) => c.id == categoryId,
        );
      } catch (_) {
        match = null;
      }

      if (match != null && match.children.isNotEmpty) {
        // Use locally-cached children — no extra network call
        subCategories.assignAll(match.children);
        debugPrint(
          '✅ SubCategories loaded from cache: ${match.children.length}',
        );
        return;
      }

      // Fallback: fetch category details from API if not in cache
      await categoryController.fetchCategoryDetails(categoryId);

      final fetched = categoryController.categoryWithChildren.value;
      if (fetched != null && fetched.children.isNotEmpty) {
        subCategories.assignAll(fetched.children);
        debugPrint(
          '✅ SubCategories loaded from API: ${fetched.children.length}',
        );
      } else {
        subCategories.clear();
        debugPrint('ℹ️ No sub-categories for $categoryId');
      }
    } catch (e) {
      debugPrint('❌ fetchSubCategories error: $e');
    } finally {
      isLoadingSubCategories.value = false;
    }
  }

  // ─── 2. Fetch products ────────────────────────────────────────────────────

  Future<void> fetchProducts({bool loadMore = false}) async {
    if (isLoadingProducts.value) return;

    if (loadMore) {
      if (!hasMoreProducts.value) return;
      currentPage.value++;
    } else {
      currentPage.value = 1;
    }

    isLoadingProducts.value = true;

    try {
      if (!StoreConfig.isConfigured) {
        products.clear();
        hasMoreProducts.value = false;
        return;
      }
      await Get.find<CurrentStoreService>().ensureResolved();
      final storeId = Get.find<CurrentStoreService>().storeId;
      if (storeId == null || storeId.isEmpty) {
        products.clear();
        hasMoreProducts.value = false;
        return;
      }

      final effectiveCategoryId = _activeSubCategoryId ?? categoryId;

      final response = await _productRepository.getProductsByCategory(
        categoryId: effectiveCategoryId.isNotEmpty ? effectiveCategoryId : null,
        page: currentPage.value,
        limit: 20,
        educationLevel: selectedEducationLevel.value,
        normalizedCustomLevel: selectedNormalizedCustomLevel.value,
        minPrice: currentMinFilter.value > priceBoundMin ? currentMinFilter.value : null,
        maxPrice: currentMaxFilter.value < priceBoundMax ? currentMaxFilter.value : null,
        minRating: selectedRating.value > 0 ? selectedRating.value : null,
        sortBy: selectedSort.value == 'newest' ? null : selectedSort.value,
        storeId: storeId,
      );

      if (response != null) {
        if (loadMore) {
          products.addAll(response.products);
        } else {
          products.assignAll(response.products);
        }
        totalPages.value = response.pages;
        hasMoreProducts.value = currentPage.value < totalPages.value;

        debugPrint(
          '✅ Fetched ${response.products.length} products '
          '(Page ${currentPage.value}/${totalPages.value})',
        );
      }
    } catch (e) {
      debugPrint('❌ Error fetching products: $e');
      ToastUtil.showToast('Failed to load products');
      if (loadMore) currentPage.value--;
    } finally {
      isLoadingProducts.value = false;
    }
  }

  // ─── 3. Load more ─────────────────────────────────────────────────────────

  Future<void> loadMoreProducts() => fetchProducts(loadMore: true);

  // ─── 4. Select sub-category chip ─────────────────────────────────────────

  void selectSubCategory(int index) {
    if (selectedSubCategoryIndex.value == index) return;
    selectedSubCategoryIndex.value = index;
    fetchProducts();
  }

  // ─── 5. Filters ───────────────────────────────────────────────────────────

  void applyFilters(ProductFilterResult filters) {
    currentMinFilter.value = filters.minPrice;
    currentMaxFilter.value = filters.maxPrice;
    selectedRating.value = filters.rating;
    selectedSort.value = filters.sort;
    selectedEducationLevel.value = filters.educationLevel;
    selectedNormalizedCustomLevel.value = filters.normalizedCustomLevel;
    fetchProducts();
  }

  void resetFilters() {
    currentMinFilter.value = priceBoundMin;
    currentMaxFilter.value = priceBoundMax;
    selectedRating.value = 0;
    selectedSort.value = 'newest';
    selectedEducationLevel.value = null;
    selectedNormalizedCustomLevel.value = null;
    fetchProducts();
  }

  void openFilterBottomSheet() {
    Get.bottomSheet(
      ProductFilterBottomSheet(
        minBound: priceBoundMin,
        maxBound: priceBoundMax,
        initialMinPrice: currentMinFilter.value,
        initialMaxPrice: currentMaxFilter.value,
        initialRating: selectedRating.value,
        initialSort: selectedSort.value,
        educationFacets: hasEducationalProducts ? educationFacets.value : null,
        initialEducationLevel: selectedEducationLevel.value,
        initialNormalizedCustomLevel: selectedNormalizedCustomLevel.value,
        onApply: applyFilters,
        onReset: resetFilters,
      ),
    );
  }

  // ─── 6. Refresh ───────────────────────────────────────────────────────────

  @override
  Future<void> refresh() async {
    selectedSubCategoryIndex.value = 0;
    await Future.wait([fetchSubCategories(), fetchProducts()]);
  }
}
