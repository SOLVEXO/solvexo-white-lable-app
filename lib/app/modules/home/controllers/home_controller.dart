import 'package:book_store_app/core/base/base_controller.dart';
import 'package:book_store_app/app/components/product_filter_bottom_sheet.dart';
import 'package:book_store_app/app/data/repositories/announcements_repository.dart';
import 'package:book_store_app/app/data/repositories/cart_repository.dart';
import 'package:book_store_app/app/data/repositories/category_repository.dart';
import 'package:book_store_app/app/data/repositories/product_repository.dart';
import 'package:book_store_app/app/data/repositories/promotions_repository.dart';
import 'package:book_store_app/app/data/repositories/storefront_repository.dart';
import 'package:book_store_app/app/data/repositories/store_banner_repository.dart';
import 'package:book_store_app/app/data/models/store_banner/store_banner_model.dart';
import 'package:book_store_app/app/data/services/auth_gate_service.dart';
import 'package:book_store_app/app/data/services/current_store_service.dart';
import 'package:book_store_app/app/data/models/announcement_model.dart';
import 'package:book_store_app/config/store_config.dart';
import 'package:book_store_app/app/modules/category/controllers/category_controller.dart';
import 'package:book_store_app/app/modules/category/models/category_model.dart';
import 'package:book_store_app/app/modules/category/models/product_model.dart';
import 'package:book_store_app/app/modules/cart/controllers/cart_controller.dart';
import 'package:book_store_app/app/modules/cart/models/cart_response_model.dart';
import 'package:book_store_app/app/modules/address/models/address_model.dart';
import 'package:book_store_app/app/modules/wishlist/controllers/wishlist_controller.dart';
import 'package:book_store_app/shared_prefrences/app_prefrences.dart';
import 'package:book_store_app/utils/toast_util.dart';
import 'package:book_store_app/config/resources/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HomeController extends BaseController {
  HomeController({
    ProductRepository? productRepository,
    CategoryRepository? categoryRepository,
    StoreBannerRepository? storeBannerRepository,
    CartRepository? cartRepository,
    StorefrontRepository? storefrontRepository,
    AnnouncementsRepository? announcementsRepository,
    WishlistController? wishlistController,
    CategoryController? categoryController,
  }) : _productRepository = productRepository ?? ProductRepository(),
       _categoryRepository = categoryRepository ?? CategoryRepository(),
       _storeBannerRepository = storeBannerRepository ?? StoreBannerRepository(),
       _cartRepository = cartRepository ?? CartRepository(),
       _storefrontRepository = storefrontRepository ?? StorefrontRepository(),
       _announcementsRepository =
           announcementsRepository ?? AnnouncementsRepository(),
       wishlistController =
           wishlistController ??
           (Get.isRegistered<WishlistController>()
               ? Get.find<WishlistController>()
               : Get.put(WishlistController())),
       categoryController =
           categoryController ??
           (Get.isRegistered<CategoryController>()
               ? Get.find<CategoryController>()
               : Get.put(CategoryController(), permanent: true));

  final ProductRepository _productRepository;
  final CategoryRepository _categoryRepository;
  final StoreBannerRepository _storeBannerRepository;
  final CartRepository _cartRepository;
  final StorefrontRepository _storefrontRepository;
  final AnnouncementsRepository _announcementsRepository;

  // This build's one store — resolved once, shared app-wide. See
  // `CurrentStoreService`'s doc comment.
  CurrentStoreService get _currentStore => Get.find<CurrentStoreService>();

  // ─── UI State ─────────────────────────────────────────────────────────────
  final RxList<StoreBannerModel> banners = <StoreBannerModel>[].obs;
  final RxInt bannerIndex = 0.obs;
  final RxBool isLoadingBanners = false.obs;
  // Impression beacons are per-banner-id, once per session — a page that
  // scrolls back and forth (or a rebuild replaying index 0) must never
  // double-fire.
  final Set<String> _impressedBannerIds = {};
  @override
  final RxBool isLoading = true.obs;
  final RxBool isFetchingProducts = false.obs;
  final RxInt selectedCategoryIndex = 0.obs;
  final RxInt tabIndex = 0.obs;

  // ─── Pagination ───────────────────────────────────────────────────────────
  @override
  final RxInt currentPage = 1.obs;
  final RxInt totalPages = 1.obs;
  final RxBool hasMoreProducts = true.obs;
  final RxInt totalProductsCount = 0.obs;

  // ─── Data ─────────────────────────────────────────────────────────────────
  // New ProductModel — variants-based, no top-level price/stock/ratings
  final RxList<ProductModel> products = <ProductModel>[].obs;
  final RxList<ProductModel> featuredProducts = <ProductModel>[].obs;
  final RxList<ProductModel> filteredProducts = <ProductModel>[].obs;

  // CategoryModel from getAllCategoryTrees — may have nested children
  final RxList<CategoryModel> categories = <CategoryModel>[].obs;

  final RxList<AnnouncementModel> announcements = <AnnouncementModel>[].obs;
  // Local-only UI state — dismissal isn't persisted, it just hides the
  // banner until the next time this screen is built.
  final RxBool announcementDismissed = false.obs;

  // ─── Favourite map ────────────────────────────────────────────────────────
  final RxMap<String, bool> favouriteMap = <String, bool>{}.obs;

  // ─── Search & Filter ──────────────────────────────────────────────────────
  final RxString searchQuery = ''.obs;
  final RxString selectedSort = 'newest'.obs;
  final TextEditingController searchTextCtrl = TextEditingController();
  static const double priceBoundMin = 0.0;
  static const double priceBoundMax = 1000.0;
  final RxDouble currentMinFilter = priceBoundMin.obs;
  final RxDouble currentMaxFilter = priceBoundMax.obs;
  final RxDouble selectedRating = 0.0.obs;

  // ─── Static address (placeholder) ────────────────────────────────────────
  AddressModel get address => AddressModel(
    label: 'home',
    recipientName: 'Jami Raza',
    phoneNumber: '028866372',
    addressLine1: 'flat 1, fb area',
    state: 'sindh',
    city: 'Karachi',
    zipCode: '21092',
  );

  // ─── Tabs ─────────────────────────────────────────────────────────────────
  // "All Products" + one tab per root category name
  List<String> get tabs {
    return ['All Products', ...categories.map((cat) => cat.name)];
  }

  // ─── Lifecycle ────────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    initializeHome();
    fetchBanners();
    fetchHomeExtras();
    // Wishlist can change from screens other than this one (the Wishlist
    // tab's per-item remove, Clear Wishlist, cart's "move to wishlist") —
    // re-sync heart icons here whenever that happens, not just on fetch.
    ever(wishlistController.wishlistItems, (_) => _updateFavouriteMap(products));
  }

  @override
  void onClose() {
    searchTextCtrl.dispose();
    super.onClose();
  }

  // ─── 1. Banners ───────────────────────────────────────────────────────────

  /// This store's own hero carousel — was `BannersRepository.fetchBanners()`
  /// (the admin-managed, platform-wide `/api/banners`, with no storeId
  /// concept at all), which meant a single-store build's homepage could show
  /// another tenant's promoted banner. `StoreBannerRepository` is the same
  /// per-store carousel already used on the seller storefront page.
  Future<void> fetchBanners() async {
    try {
      isLoadingBanners.value = true;
      await _currentStore.ensureResolved();
      final storeId = _currentStore.storeId;
      if (storeId == null || storeId.isEmpty) {
        banners.clear();
        return;
      }
      final result = await _storeBannerRepository.getPublicBanners(storeId);
      banners.assignAll(result);
      debugPrint('✅ Banners loaded: ${banners.length}');
    } catch (e) {
      debugPrint('❌ Error loading banners: $e');
      banners.clear();
    } finally {
      isLoadingBanners.value = false;
    }
  }

  /// Fires the store-banner impression beacon at most once per banner id
  /// per session — call from the carousel for whichever page is currently
  /// visible (index 0 on load, then again on every `onPageChanged`).
  void maybeTrackBannerImpression(String bannerId) {
    if (bannerId.isEmpty) return;
    if (_impressedBannerIds.add(bannerId)) {
      PromotionsRepository().trackImpression(
        entityType: 'store_banner',
        entityId: bannerId,
        storeId: _currentStore.storeId,
      );
    }
  }

  // ─── 1c. Public marketing/homepage content (unauthenticated, additive) ────
  // Swallows its own errors (repository-level) and simply leaves the list
  // empty on failure — the corresponding widget renders nothing in that
  // case, never a broken section or an error toast.

  Future<void> fetchAnnouncements() async {
    final result = await _announcementsRepository.getActive('buyers');
    announcements.assignAll(result);
  }

  void dismissAnnouncement() => announcementDismissed.value = true;

  /// Runs the non-critical homepage fetches in parallel — called from
  /// [onInit] and again on pull-to-refresh, alongside (not blocking) the
  /// core [initializeHome]/banners fetches.
  Future<void> fetchHomeExtras() => Future.wait([fetchAnnouncements()]);

  // ─── 2. Initialize ────────────────────────────────────────────────────────

  Future<void> initializeHome() async {
    isLoading.value = true;
    try {
      await _currentStore.ensureResolved();
      await fetchCategories();
      await fetchFeaturedProducts();
      await fetchProducts();
    } catch (e) {
      debugPrint('❌ Error initializing home: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ─── 3. Categories ────────────────────────────────────────────────────────
  // Uses getAllCategoryTrees() — same source as CategoryController — so the
  // tab list and CategoryView always show the same categories.

  Future<void> fetchCategories() async {
    try {
      await _currentStore.ensureResolved();
      final trees = await _categoryRepository.getAllCategoryTrees(
        storeId: _currentStore.storeId,
      );
      categories.assignAll(trees);
      debugPrint('✅ Fetched ${trees.length} category trees for home');
    } catch (e) {
      debugPrint('❌ Error fetching categories: $e');
      ToastUtil.showToast('Failed to load categories');
    }
  }

  // ─── 4. Featured Products ─────────────────────────────────────────────────

  Future<void> fetchFeaturedProducts() async {
    // try {
    //   // final fetched = await _productRepository.getFeaturedProducts();
    //   // if (fetched != null) {
    //   //   featuredProducts.assignAll(fetched);
    //   //   _updateFavouriteMap(fetched);
    //   //   debugPrint('✅ Featured products: ${fetched.length}');
    //   // }
    // } catch (e) {
    //   debugPrint('❌ Error fetching featured products: $e');
    // }
  }

  // ─── 5. Products ──────────────────────────────────────────────────────────
  // A configured build (`StoreConfig.isConfigured`) shows only this app's
  // one store's catalog, via the same per-store endpoint `seller_storefront`
  // uses (`StorefrontRepository.getStoreProducts`). If no store is bound
  // (`StoreConfig.isConfigured == false`) this shows an empty state —
  // never the old marketplace-wide `getProductsByCategory` fallback, so a
  // misconfigured build can't silently show other stores' products.
  // When tab is "All Products" no categoryId is sent and the backend returns
  // everything. When a tab is selected the root category ID is passed.

  Future<void> fetchProducts({bool loadMore = false}) async {
    if (isFetchingProducts.value) return;

    if (loadMore) {
      if (!hasMoreProducts.value) return;
      currentPage.value++;
    } else {
      currentPage.value = 1;
    }

    isFetchingProducts.value = true;

    try {
      if (!StoreConfig.isConfigured) {
        if (!loadMore) products.clear();
        totalProductsCount.value = 0;
        hasMoreProducts.value = false;
        _applyLocalFilters();
        return;
      }

      await _currentStore.ensureResolved();
      final storeId = _currentStore.storeId;
      if (storeId == null || storeId.isEmpty) {
        if (!loadMore) products.clear();
        totalProductsCount.value = 0;
        hasMoreProducts.value = false;
        _applyLocalFilters();
        return;
      }

      final result = await _storefrontRepository.getStoreProducts(
        storeId: storeId,
        page: currentPage.value,
        limit: 10,
        categoryId: _categoryIdForCurrentTab(),
        sort: selectedSort.value,
      );

      if (loadMore) {
        products.addAll(result.products);
      } else {
        products.assignAll(result.products);
      }

      totalPages.value = result.totalPages;
      totalProductsCount.value = result.total;
      hasMoreProducts.value = result.hasMore;

      _updateFavouriteMap(result.products);
      // getStoreProducts has no price/rating params — applied client-side
      // over whatever page(s) are already loaded (see _applyLocalFilters).
      _applyLocalFilters();

      debugPrint(
        '✅ Fetched ${result.products.length} store products '
        '(page ${currentPage.value})',
      );
    } catch (e) {
      debugPrint('❌ Error fetching products: $e');
      ToastUtil.showToast('Failed to load products');
      if (loadMore) currentPage.value--;
    } finally {
      isFetchingProducts.value = false;
    }
  }

  /// Returns the category ID for the active tab, or null for "All Products".
  String? _categoryIdForCurrentTab() {
    final index = tabIndex.value;
    if (index == 0) return null; // "All Products"

    // Tab index maps to categories list with offset of 1
    final catIndex = index - 1;
    if (catIndex < categories.length) {
      return categories[catIndex].id;
    }
    return null;
  }

  // ─── 6. Local filtering ───────────────────────────────────────────────────
  // Applied after every fetch so the displayed list is always up to date.
  // Search is always client-side. `getStoreProducts` has no price/rating
  // params, so this is the only place they're enforced — meaning they only
  // narrow whatever page(s) are already loaded, not the store's full
  // catalog, until the backend adds support.
  void _applyLocalFilters() {
    final query = searchQuery.value.trim().toLowerCase();

    Iterable<ProductModel> result = products;
    if (query.isNotEmpty) {
      result = result.where(
        (p) => p.name.toLowerCase().contains(query) || p.description.toLowerCase().contains(query),
      );
    }
    if (currentMinFilter.value > priceBoundMin) {
      result = result.where((p) => p.price >= currentMinFilter.value);
    }
    if (currentMaxFilter.value < priceBoundMax) {
      result = result.where((p) => p.price <= currentMaxFilter.value);
    }
    if (selectedRating.value > 0) {
      result = result.where((p) => p.averageRating >= selectedRating.value);
    }

    filteredProducts.assignAll(result);
    debugPrint('🔍 Filtered to ${filteredProducts.length} products');
  }

  // ─── 7. Public actions ────────────────────────────────────────────────────

  /// Change tab — re-fetches products for the selected category
  void onTabChanged(int index) {
    tabIndex.value = index;
    fetchProducts();
  }

  final WishlistController wishlistController;

  // Guards against a rapid second tap firing a second add/remove request
  // before the first one's response comes back (was producing duplicate
  // wishlist entries and contradictory toasts).
  final Set<String> _wishlistTogglesInFlight = {};

  bool isFavourite(String productId) => favouriteMap[productId] ?? false;

  Future<void> addorRemoveWishList(
    String productId,
    String productVariantId,
  ) async {
    if (_wishlistTogglesInFlight.contains(productId)) return;
    final allowed = await AuthGateService.instance.requireAuth(
      message: 'Login to save items to your wishlist.',
    );
    if (!allowed) return;
    _wishlistTogglesInFlight.add(productId);
    try {
      if (isFavourite(productId)) {
        await wishlistController.removeFromWishlist(
          productVariantId: productVariantId,
        );
        favouriteMap[productId] = false;
      } else {
        await wishlistController.addToWishlist(
          productId: productId,
          productVariantId: productVariantId,
        );
        favouriteMap[productId] = true;
      }
    } catch (e) {
      ToastUtil.showToast("$e");
    } finally {
      _wishlistTogglesInFlight.remove(productId);
    }
  }

  /// Quick add-to-cart from a product card (no variant picker available
  /// there) — always uses the first variant and quantity 1, same fallback
  /// the wishlist heart already relies on.
  Future<void> quickAddToCart(ProductModel product) async {
    if (product.variants.isEmpty) {
      ToastUtil.showToast('Product is not available');
      return;
    }
    if (!product.inStock) {
      ToastUtil.showToast('Product is out of stock');
      return;
    }
    final variant = product.variants.first;
    if (!Get.isRegistered<CartController>()) Get.put(CartController());
    final cartController = Get.find<CartController>();

    if (!await AppPreferences.isLoggedIn()) {
      await cartController.addLocalItem(
        CartItem(
          productId: product.id,
          productVariantId: variant.id,
          name: product.name,
          sellerName: product.sellerName,
          sellerVerified: product.sellerVerified,
          price: variant.price,
          quantity: 1,
          images: variant.images.isNotEmpty ? variant.images : product.images,
          productType: product.type,
          options: variant.options,
          currency: variant.currency,
        ),
      );
      ToastUtil.showToast('${product.name} added to cart');
      return;
    }

    try {
      final cart = await _cartRepository.addToCart(
        productId: product.id,
        productVariantId: variant.id,
        quantity: 1,
      );
      cartController.addToCartBackend(cart: cart);
      ToastUtil.showToast('${product.name} added to cart');
    } catch (e) {
      ToastUtil.showToast('Failed to add to cart');
    }
  }

  /// Search — filters the already-loaded list instantly;
  /// fetches fresh results from the server after a tab reset
  void searchProducts(String query) {
    searchQuery.value = query;
    if (query.isEmpty) {
      fetchProducts();
    } else {
      _applyLocalFilters();
    }
  }

  void clearSearch() {
    searchQuery.value = '';
    searchTextCtrl.clear();
    fetchProducts();
  }

  /// Applies price/rating/sort from the shared filter sheet and re-fetches
  /// page 1 from the server (see `fetchProducts`, which forwards them).
  void applyFilters(ProductFilterResult filters) {
    currentMinFilter.value = filters.minPrice;
    currentMaxFilter.value = filters.maxPrice;
    selectedRating.value = filters.rating;
    selectedSort.value = filters.sort;
    fetchProducts();
  }

  void resetFilters() {
    currentMinFilter.value = priceBoundMin;
    currentMaxFilter.value = priceBoundMax;
    selectedRating.value = 0;
    selectedSort.value = 'newest';
    fetchProducts();
  }

  /// Load more (pagination)
  Future<void> loadMoreProducts() => fetchProducts(loadMore: true);

  /// Full refresh
  final CategoryController categoryController;

  // ─── Replace refreshHome in HomeController ────────────────────────────────
  // Both home data and category data reset at the same time so
  // isLoading fires once for both, showing shimmer for all sections together.

  Future<void> refreshHome() async {
    // Set both loading states true simultaneously before any await
    isLoading.value = true;
    categoryController.isLoading.value = true;

    try {
      // Run both refreshes in parallel.
      await Future.wait([
        initializeHome(),
        categoryController.refresh(),
        fetchHomeExtras(),
      ]);
    } finally {
      // Both will set their own loading to false inside their methods,
      // but guard here just in case
      isLoading.value = false;
      categoryController.isLoading.value = false;
    }
  }

  /// Fetch single product by ID
  Future<ProductModel?> getProductById(String productId) async {
    try {
      final product = await _productRepository.getProductById(productId, storeId: _currentStore.storeId);
      if (product != null) {
        debugPrint('✅ Fetched product: ${product.name}');
      }
      return product;
    } catch (e) {
      debugPrint('❌ Error fetching product: $e');
      ToastUtil.showToast('Failed to load product details');
      return null;
    }
  }

  /// Product count per category tab (uses filteredProducts)
  int getProductCount(String categoryName) {
    if (categoryName == 'All Products') return filteredProducts.length;
    // category?.name may be null on the new model when not populated,
    // so fall back to matching categoryId via the categories list
    final cat = categories.firstWhereOrNull((c) => c.name == categoryName);
    if (cat == null) return 0;
    return filteredProducts.where((p) => p.categoryId == cat.id).length;
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  void _updateFavouriteMap(List<ProductModel> list) {
    for (final p in list) {
      final variantId = p.variants.isNotEmpty ? p.variants.first.id : '';
      favouriteMap[p.id] = variantId.isNotEmpty && wishlistController.isWishlisted(variantId);
    }
  }

  // ─── Static items (home quick-links) ─────────────────────────────────────

  final items = [
    {
      'title': 'Sheet Sets',
      'price': '\$3.99',
      'image': 'https://www.pngall.com/wp-content/uploads/2/Pillow.png',
      'color': AppColors.categoryBg1,
    },
    {
      'title': 'Laundry Bags',
      'price': '\$4.99',
      'image':
          'https://www.pngall.com/wp-content/uploads/4/Leather-Bag-PNG.png',
      'color': AppColors.categoryBg2,
    },
    {
      'title': 'Towel Sets',
      'price': '\$14.99',
      'image': 'https://pngimg.com/uploads/towel/towel_PNG20.png',
      'color': AppColors.categoryBg3,
    },
    {
      'title': 'Floor Lamps',
      'price': '\$7.99',
      'image':
          'https://static.vecteezy.com/system/resources/previews/052/648/828/non_2x/gold-floor-lamp-with-pleated-shade-png.png',
      'color': AppColors.categoryBg4,
    },
  ];
}
