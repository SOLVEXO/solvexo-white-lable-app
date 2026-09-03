import 'package:book_store_app/app/data/models/storefront/storefront_model.dart';
import 'package:book_store_app/app/data/models/store_banner/store_banner_model.dart';
import 'package:book_store_app/app/data/models/store_faq/store_faq_model.dart';
import 'package:book_store_app/app/data/services/current_store_service.dart';
import 'package:book_store_app/app/data/services/store_chat_launcher.dart';
import 'package:book_store_app/app/data/repositories/promotions_repository.dart';
import 'package:book_store_app/app/data/repositories/store_banner_repository.dart';
import 'package:book_store_app/app/data/repositories/store_faq_repository.dart';
import 'package:book_store_app/app/data/repositories/storefront_repository.dart';
import 'package:book_store_app/app/modules/category/models/product_model.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';

/// This app's single "About this Store" page — the storefront screen only
/// ever describes the one store this build serves.
class SellerStorefrontController extends GetxController {
  final _repo = StorefrontRepository();
  final _storeBannerRepo = StoreBannerRepository();
  final _storeFaqRepo = StoreFaqRepository();
  final RxBool isStartingChat = false.obs;

  final ScrollController scrollController = ScrollController();

  late final String storeSlug;

  // ── Store profile ───────────────────────────────────────────────────────
  final Rx<StorefrontModel?> store = Rx(null);
  final RxBool isLoading = true.obs;

  // ── Products ─────────────────────────────────────────────────────────────
  final RxList<ProductModel> products = <ProductModel>[].obs;
  final RxBool isLoadingProducts = true.obs;
  final RxBool isLoadingMore = false.obs;
  final RxList<String> filterTags = <String>[].obs;
  final RxInt totalProducts = 0.obs;

  final RxString selectedType = 'all'.obs; // all | physical | digital
  final RxString selectedTag = 'all'.obs;
  final RxString sort = 'newest'.obs; // newest | price_asc | price_desc | best_rated

  int _page = 1;
  bool _hasMore = false;
  bool get hasMore => _hasMore;

  // ── Store banners (seller's free hero carousel) ──────────────────────────
  final RxList<StoreBannerModel> storeBanners = <StoreBannerModel>[].obs;

  // ── Store FAQs (seller-authored, this store only) ────────────────────────
  final RxList<StoreFaqModel> faqs = <StoreFaqModel>[].obs;

  // ── Merchandising sections (pinned / new arrivals / best sellers / trending) ─
  // Fetched in parallel alongside products once `storeId` is known. Every
  // repository call silently returns [] on failure — no error toast, the
  // corresponding section just renders nothing (no-fake-data rule).
  final RxList<ProductModel> pinnedProducts = <ProductModel>[].obs;
  final RxList<ProductModel> newArrivals = <ProductModel>[].obs;
  final RxList<ProductModel> bestSellers = <ProductModel>[].obs;
  final RxList<ProductModel> trending = <ProductModel>[].obs;

  // ── Announcement bar ─────────────────────────────────────────────────────
  // Local-only, not persisted — dismissing just hides it for the rest of
  // this screen's lifetime (same pattern as HomeController.announcementDismissed).
  final RxBool announcementBarDismissed = false.obs;

  // ── Store banner impressions ─────────────────────────────────────────────
  final Set<String> _impressedStoreBannerIds = {};

  static const sortLabels = {
    'newest': 'Newest',
    'price_asc': 'Price: Low to High',
    'price_desc': 'Price: High to Low',
    'best_rated': 'Top Rated',
  };

  // ── Lifecycle ────────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    _readArgs();
    _loadStore();
    scrollController.addListener(() {
      if (scrollController.position.pixels >= scrollController.position.maxScrollExtent - 300) {
        loadMoreProducts();
      }
    });
  }

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }

  void _readArgs() {
    final args = Get.arguments;
    if (args is Map) {
      storeSlug = args['slug'] as String? ?? '';
    } else if (args is String) {
      storeSlug = args;
    } else {
      storeSlug = '';
    }
  }

  // ── Store profile ────────────────────────────────────────────────────────

  Future<void> _loadStore() async {
    // Reuse the app-wide resolved store instead of hitting the same
    // `getStoreBySlug` endpoint a second time — Home's controller already
    // triggers that resolve at startup. Only fall back to our own
    // slug-based lookup if `CurrentStoreService` hasn't resolved yet (or
    // failed to), so this screen still works if opened before that
    // background resolve finishes.
    final currentStore = Get.find<CurrentStoreService>();
    StorefrontModel? result = currentStore.store.value;

    if (result == null) {
      if (storeSlug.isEmpty) {
        isLoading.value = false;
        return;
      }
      isLoading.value = true;
      result = await _repo.getStoreBySlug(storeSlug);
    }

    store.value = result;
    isLoading.value = false;

    if (result != null) {
      await Future.wait([
        loadProducts(reset: true),
        _loadFilterTags(),
        _loadStoreBanners(),
        _loadFaqs(),
        _loadMerchandisingSections(),
      ]);
    }
  }

  Future<void> _loadStoreBanners() async {
    final storeId = store.value?.storeId;
    if (storeId == null || storeId.isEmpty) return;
    storeBanners.assignAll(await _storeBannerRepo.getPublicBanners(storeId));
  }

  Future<void> _loadFaqs() async {
    final storeId = store.value?.storeId;
    if (storeId == null || storeId.isEmpty) return;
    faqs.assignAll(await _storeFaqRepo.getPublicFaqs(storeId));
  }

  Future<void> _loadMerchandisingSections() async {
    final storeId = store.value?.storeId;
    if (storeId == null || storeId.isEmpty) return;
    final results = await Future.wait([
      _repo.getPinnedProducts(storeId),
      _repo.getNewArrivals(storeId),
      _repo.getBestSellers(storeId),
      _repo.getTrending(storeId),
    ]);
    pinnedProducts.assignAll(results[0]);
    newArrivals.assignAll(results[1]);
    bestSellers.assignAll(results[2]);
    trending.assignAll(results[3]);
  }

  Future<void> refreshData() => _loadStore();

  Future<void> _loadFilterTags() async {
    final storeId = store.value?.storeId;
    if (storeId == null || storeId.isEmpty) return;
    filterTags.assignAll(await _repo.getStoreFilterTags(storeId));
  }

  // ── Products ─────────────────────────────────────────────────────────────

  Future<void> loadProducts({bool reset = false}) async {
    final storeId = store.value?.storeId;
    if (storeId == null || storeId.isEmpty) return;

    if (reset) {
      _page = 1;
      isLoadingProducts.value = true;
    }

    final result = await _repo.getStoreProducts(
      storeId: storeId,
      page: _page,
      type: selectedType.value,
      tag: selectedTag.value,
      sort: sort.value,
    );

    if (reset) {
      products.assignAll(result.products);
    } else {
      products.addAll(result.products);
    }
    totalProducts.value = result.total;
    _hasMore = result.hasMore;
    isLoadingProducts.value = false;
    isLoadingMore.value = false;
  }

  Future<void> loadMoreProducts() async {
    if (!_hasMore || isLoadingMore.value) return;
    isLoadingMore.value = true;
    _page++;
    await loadProducts();
  }

  void setType(String type) {
    if (selectedType.value == type) return;
    selectedType.value = type;
    loadProducts(reset: true);
  }

  void setTag(String tag) {
    if (selectedTag.value == tag) return;
    selectedTag.value = tag;
    loadProducts(reset: true);
  }

  void setSort(String value) {
    if (sort.value == value) return;
    sort.value = value;
    loadProducts(reset: true);
  }

  // ── Message us ───────────────────────────────────────────────────────────

  Future<void> messageStore() async {
    if (isStartingChat.value) return;
    isStartingChat.value = true;
    try {
      await StoreChatLauncher.open();
    } finally {
      isStartingChat.value = false;
    }
  }

  // ── Store banner impressions ─────────────────────────────────────────────

  /// Fires the store-banner impression beacon at most once per banner id
  /// per storefront view session — call from `StoreBannerCarousel` for
  /// whichever page is currently visible.
  void maybeTrackStoreBannerImpression(String bannerId) {
    if (bannerId.isEmpty) return;
    if (_impressedStoreBannerIds.add(bannerId)) {
      PromotionsRepository().trackImpression(
        entityType: 'store_banner',
        entityId: bannerId,
        storeId: store.value?.storeId,
      );
    }
  }

  // ── Announcement bar ─────────────────────────────────────────────────────

  void dismissAnnouncementBar() => announcementBarDismissed.value = true;

  // ── Share ────────────────────────────────────────────────────────────────

  void shareStore() {
    final s = store.value;
    if (s == null) return;
    final desc = (s.description ?? '').trim();
    final text = desc.isNotEmpty ? '${s.name} — $desc' : 'Check out ${s.name}\'s store!';
    SharePlus.instance.share(ShareParams(text: text, subject: s.name));
  }
}
