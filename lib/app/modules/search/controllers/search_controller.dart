import 'dart:async';
import 'package:book_store_app/app/data/repositories/search_repository.dart';
import 'package:book_store_app/app/data/services/current_store_service.dart';
import 'package:book_store_app/app/modules/category/models/product_model.dart';
import 'package:book_store_app/config/store_config.dart';
import 'package:book_store_app/shared_prefrences/app_prefrences.dart';
import 'package:book_store_app/utils/toast_util.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SearchBarController extends GetxController {
  final SearchRepository _searchRepository = SearchRepository();
  final TextEditingController textController = TextEditingController();

  /// Backend history is used when logged in; guests keep the old
  /// SharedPreferences behaviour.
  bool _isLoggedIn = false;

  String? get _storeId => Get.find<CurrentStoreService>().storeId;

  // ─── UI state ──────────────────────────────────────────────────────────────
  final RxString searchText = ''.obs;
  final RxBool showResults = false.obs;
  final RxBool loading = false.obs;
  final RxBool showSuggestions = false.obs;

  // ─── Products ─────────────────────────────────────────────────────────────
  // ProductModel is now variants-based — use product.price, product.stock,
  // product.averageRating computed getters; no alias import needed.
  final RxList<ProductModel> allProducts = <ProductModel>[].obs;
  final RxList<ProductModel> filteredProducts = <ProductModel>[].obs;
  final RxList<ProductModel> suggestions = <ProductModel>[].obs;

  // ─── Favourites ───────────────────────────────────────────────────────────
  final RxMap<String, bool> favouriteMap = <String, bool>{}.obs;

  Timer? _debounce;

  // ─── Lifecycle ────────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    _init();
  }

  Future<void> _init() async {
    _isLoggedIn = await AppPreferences.isLoggedIn();
    loadRecentSearches();
    loadRecentlyViewed();
    loadPopularSearches();
  }

  @override
  void onClose() {
    _debounce?.cancel();
    textController.dispose();
    super.onClose();
  }

  // ─── 1. Typing handler ────────────────────────────────────────────────────

  void onSearchChanged(String value) {
    searchText.value = value;

    if (value.trim().isEmpty) {
      _clearState();
      return;
    }

    showSuggestions.value = true;

    // Instant suggestions from already-loaded products
    if (allProducts.isNotEmpty) {
      suggestions.assignAll(
        allProducts
            .where(
              (p) =>
                  p.name.toLowerCase().startsWith(value.toLowerCase()) ||
                  p.description.toLowerCase().contains(value.toLowerCase()),
            )
            .take(6)
            .toList(),
      );
    }

    // Debounced API call — 400ms feels natural for search.
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      performSearch(value);
    });
  }

  // ─── 2. Main search ───────────────────────────────────────────────────────
  // Server-side keyword search (`api/search/products`). When logged in the
  // backend also records the term into the user's search history.

  Future<void> performSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    loading.value = true;
    showResults.value = true;

    try {
      if (!StoreConfig.isConfigured) {
        filteredProducts.clear();
        suggestions.clear();
        showResults.value = false;
        return;
      }
      await Get.find<CurrentStoreService>().ensureResolved();
      final storeId = Get.find<CurrentStoreService>().storeId;
      if (storeId == null || storeId.isEmpty) {
        filteredProducts.clear();
        suggestions.clear();
        showResults.value = false;
        return;
      }

      final response = await _searchRepository.searchProducts(
        trimmed,
        page: 1,
        limit: 50,
        storeId: storeId,
      );

      final matched = response?.products ?? <ProductModel>[];

      if (matched.isNotEmpty) {
        filteredProducts.assignAll(matched);
        allProducts.assignAll(matched); // cache for instant suggestions

        // Top suggestion is the closest name match
        suggestions.assignAll(
          matched
              .where(
                (p) => p.name.toLowerCase().startsWith(trimmed.toLowerCase()),
              )
              .take(5)
              .toList(),
        );

        _updateFavouriteMap(matched);
        addToRecentSearches(trimmed);

        debugPrint('🔍 Search "$trimmed" → ${matched.length} results');
      } else {
        // A no-hit search is still worth remembering — the backend recorded
        // it too, so keep local state consistent.
        addToRecentSearches(trimmed);
        filteredProducts.clear();
        suggestions.clear();
        showResults.value = false;
        ToastUtil.showToast('No products found for "$trimmed"');
      }
    } catch (e) {
      debugPrint('❌ Search error: $e');
      ToastUtil.showToast('Search failed. Please try again.');
      filteredProducts.clear();
      suggestions.clear();
      showResults.value = false;
    } finally {
      loading.value = false;
    }
  }

  // ─── 3. Select a suggestion ───────────────────────────────────────────────

  void selectSuggestion(ProductModel product) {
    textController.text = product.name;
    searchText.value = product.name;
    showSuggestions.value = false;
    performSearch(product.name);
  }

  // ─── 4. Clear ─────────────────────────────────────────────────────────────

  void clearSearch() {
    textController.clear();
    _clearState();
  }

  void _clearState() {
    searchText.value = '';
    filteredProducts.clear();
    suggestions.clear();
    showResults.value = false;
    showSuggestions.value = false;
  }

  // ─── 5. Filters ───────────────────────────────────────────────────────────
  // Applies price / sort on the already-loaded filteredProducts list so
  // there is no extra API round-trip for simple filter changes.

  final RxString activeQuickFilter = 'all'.obs;

  void applyFilters({
    double? minPrice,
    double? maxPrice,
    double? minRating,
    String? sortBy,
    String quickFilter = 'all',
  }) {
    if (allProducts.isEmpty) return;
    activeQuickFilter.value = quickFilter;

    var result = allProducts.toList();

    // Re-apply the current search text filter
    final query = searchText.value.trim().toLowerCase();
    if (query.isNotEmpty) {
      result = result
          .where(
            (p) =>
                p.name.toLowerCase().contains(query) ||
                p.description.toLowerCase().contains(query),
          )
          .toList();
    }

    // Price — uses product.price computed getter (min variant price)
    if (minPrice != null) {
      result = result.where((p) => p.price >= minPrice).toList();
    }
    if (maxPrice != null) {
      result = result.where((p) => p.price <= maxPrice).toList();
    }
    if (minRating != null) {
      result = result.where((p) => p.averageRating >= minRating).toList();
    }

    // Sort
    switch (sortBy ?? 'newest') {
      case 'price_asc':
        result.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'price_desc':
        result.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'rating':
        // averageRating is a direct field on the new ProductModel
        result.sort((a, b) => b.averageRating.compareTo(a.averageRating));
        break;
      case 'newest':
      default:
        result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }

    filteredProducts.assignAll(result);
    debugPrint('🎛️ Filtered to ${filteredProducts.length} products');
  }

  void sortResults(String sortBy) => applyFilters(sortBy: sortBy);

  // ─── 6. Recent searches ───────────────────────────────────────────────────
  // Logged in → backend history (`api/search/recent`, synced across devices);
  // guest → the old SharedPreferences list.

  final RxList<String> recentSearches = <String>[].obs;
  final RxBool showAll = false.obs;

  /// Backend id per (lowercased) query — needed for per-entry deletion.
  final Map<String, String> _searchIdByQuery = {};

  List<String> get shownRecentSearches =>
      showAll.value ? recentSearches : recentSearches.take(4).toList();

  Future<void> loadRecentSearches() async {
    try {
      if (_isLoggedIn) {
        final entries = await _searchRepository.getRecentSearches(storeId: _storeId);
        if (entries != null) {
          _searchIdByQuery
            ..clear()
            ..addEntries(entries.map((e) => MapEntry(e.query.toLowerCase(), e.searchId)));
          recentSearches.assignAll(entries.map((e) => e.query));
        }
        return;
      }
      final saved = await AppPreferences.getRecentSearches();
      if (saved != null) recentSearches.assignAll(saved);
    } catch (e) {
      debugPrint('❌ Error loading recent searches: $e');
    }
  }

  Future<void> _saveRecentSearches() async {
    if (_isLoggedIn) return; // backend is the source of truth when logged in
    try {
      await AppPreferences.saveRecentSearches(recentSearches);
    } catch (e) {
      debugPrint('❌ Error saving recent searches: $e');
    }
  }

  void addToRecentSearches(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;
    // Optimistic local update (dedup case-insensitively, same as backend).
    recentSearches.removeWhere((s) => s.toLowerCase() == trimmed.toLowerCase());
    recentSearches.insert(0, trimmed);
    if (recentSearches.length > 10) {
      recentSearches.removeRange(10, recentSearches.length);
    }
    _saveRecentSearches();
    // Backend recorded the term during the search itself — re-fetch quietly
    // so the new entry's id is known for deletion.
    if (_isLoggedIn) unawaited(loadRecentSearches());
  }

  void deleteRecent(String value) {
    recentSearches.remove(value);
    if (_isLoggedIn) {
      final id = _searchIdByQuery.remove(value.toLowerCase());
      if (id != null) unawaited(_searchRepository.deleteRecentSearch(id, storeId: _storeId));
      return;
    }
    _saveRecentSearches();
  }

  void toggleSeeMore() => showAll.value = !showAll.value;

  void clearRecentSearches() {
    recentSearches.clear();
    if (_isLoggedIn) {
      _searchIdByQuery.clear();
      unawaited(_searchRepository.clearRecentSearches(storeId: _storeId));
      return;
    }
    _saveRecentSearches();
  }

  // ─── 7. Recently viewed ───────────────────────────────────────────────────
  // Logged in → one backend call with fresh product data; guest → re-fetch
  // each locally-stored id like before.

  final RxList<ProductModel> lastSeenProducts = <ProductModel>[].obs;

  Future<void> loadRecentlyViewed() async {
    // Recently-viewed display is a login-only feature — guests still record
    // views locally (see `recordProductView`, in case they log in later and
    // want it), but never see the section itself.
    if (!_isLoggedIn) {
      lastSeenProducts.clear();
      return;
    }
    try {
      final products = await _searchRepository.getRecentlyViewed(limit: 10, storeId: _storeId);
      if (products != null) lastSeenProducts.assignAll(products);
    } catch (e) {
      debugPrint('❌ Error loading recently viewed: $e');
    }
  }

  /// Records locally + on the backend (via SearchRepository) and refreshes
  /// the strip so the tapped product surfaces immediately.
  Future<void> addToRecentlyViewed(String productId) async {
    await _searchRepository.recordProductView(productId, storeId: _storeId);
    unawaited(loadRecentlyViewed());
  }

  // ─── 8. Popular searches ──────────────────────────────────────────────────

  final RxList<String> popularSearches = <String>[].obs;

  Future<void> loadPopularSearches() async {
    // Uncomment when endpoint is ready:
    // try {
    //   final popular = await _productRepository.getPopularSearches();
    //   if (popular != null) popularSearches.assignAll(popular);
    // } catch (e) {
    //   debugPrint('Error loading popular searches: $e');
    // }
  }

  // ─── 9. Utilities ─────────────────────────────────────────────────────────

  bool isFavorite(String productId) => favouriteMap[productId] ?? false;

  void toggleFavorite(String productId) {
    favouriteMap[productId] = !(favouriteMap[productId] ?? false);
  }

  int get resultsCount => filteredProducts.length;
  bool get hasResults => filteredProducts.isNotEmpty;
  bool get isSearching => searchText.value.isNotEmpty;

  // ─── Helpers ──────────────────────────────────────────────────────────────

  void _updateFavouriteMap(List<ProductModel> list) {
    for (final p in list) {
      favouriteMap.putIfAbsent(p.id, () => false);
    }
  }
}
