import 'dart:async';

import 'package:book_store_app/app/components/custom_app_snack_bar.dart';
import 'package:book_store_app/app/data/models/rating/review_model.dart';
import 'package:book_store_app/app/data/repositories/cart_repository.dart';
import 'package:book_store_app/app/data/repositories/product_repository.dart';
import 'package:book_store_app/app/data/repositories/rating_repository.dart';
import 'package:book_store_app/app/data/repositories/search_repository.dart';
import 'package:book_store_app/app/data/services/current_store_service.dart';
import 'package:book_store_app/app/modules/category/models/product_model.dart';
import 'package:book_store_app/app/modules/cart/controllers/cart_controller.dart';
import 'package:book_store_app/app/modules/cart/models/cart_response_model.dart';
import 'package:book_store_app/config/resources/app_sounds.dart';
import 'package:book_store_app/shared_prefrences/app_prefrences.dart';
import 'package:book_store_app/utils/toast_util.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProductDetailController extends GetxController {
  final ProductRepository _productRepository = ProductRepository();
  final CartRepository _cartRepository = CartRepository();
  final RatingRepository _ratingRepository = RatingRepository();

  // ─── Arguments ────────────────────────────────────────────────────────────
  late final String productId;

  // ─── State ────────────────────────────────────────────────────────────────
  final Rx<ProductModel?> product = Rx<ProductModel?>(null);
  final RxList<ProductVariant> variants = <ProductVariant>[].obs;
  final Rx<ProductVariant?> selectedVariant = Rx<ProductVariant?>(null);
  final Rx<ProductVariant?> defaultVariant = Rx<ProductVariant?>(null);
  // Attribute name → currently selected value (e.g. {'Color': 'Red'}).
  final RxMap<String, String> selectedOptions = <String, String>{}.obs;

  final RxBool isLoading = false.obs;
  final RxBool isAddtoCartLoading = false.obs;
  final RxBool isLoadingVariant = false.obs;

  // ─── Reviews ──────────────────────────────────────────────────────────────
  final RxList<ReviewModel> reviews = <ReviewModel>[].obs;
  final Rx<ReviewStats> reviewStats = const ReviewStats().obs;
  final RxBool isLoadingReviews = true.obs;

  /// Backend sort keys — labels resolved in the view.
  static const reviewSortOptions = <String>[
    'newest',
    'most_helpful',
    'highest_rating',
    'lowest_rating',
    'oldest',
  ];
  final RxString reviewSort = 'newest'.obs;

  // ─── Quantity ─────────────────────────────────────────────────────────────
  final RxInt productQty = 1.obs;

  // ─── Hero image gallery ───────────────────────────────────────────────────
  // Owned here (not in the view) so `ProductDetailsView` and its widgets can
  // all stay `StatelessWidget` — the controller already outlives rebuilds
  // and is disposed via `onClose` below.
  final PageController imagePageController = PageController();
  final RxInt imagePage = 0.obs;

  // ─── Lifecycle ────────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    _readArguments();
    fetchProductDetails();
    fetchReviews();
  }

  @override
  void onClose() {
    imagePageController.dispose();
    super.onClose();
  }

  void _readArguments() {
    final args = Get.arguments;
    if (args is Map<String, dynamic>) {
      productId = args['productId'] as String? ?? '';
    } else if (args is String) {
      productId = args;
    } else {
      productId = '';
    }
    debugPrint('🛍️ ProductDetailController — productId: $productId');
  }

  // ─── 1. Fetch product + all variants ─────────────────────────────────────

  Future<void> fetchProductDetails() async {
    if (productId.isEmpty) {
      ToastUtil.showToast('Invalid product');
      return;
    }

    isLoading.value = true;

    try {
      final response = await _productRepository.getProductDetailById(
        productId,
        storeId: Get.find<CurrentStoreService>().storeId,
      );

      if (response != null) {
        product.value = response.product;
        variants.assignAll(response.variants);

        // Select default variant; fall back to first variant if none
        final def =
            response.defaultVariant ??
            (response.variants.isNotEmpty ? response.variants.first : null);
        selectedVariant.value = def;
        defaultVariant.value = def;
        selectedOptions.assignAll({
          for (final o in def?.options ?? <VariantOption>[]) o.name: o.value,
        });

        // Reset quantity + gallery position for the newly loaded product
        productQty.value = 1;
        _resetImageGallery();

        debugPrint(
          '✅ Loaded product: ${response.product.name} '
          'with ${response.variants.length} variants',
        );

        // Feed the "Recently Viewed" strip (local prefs + backend when
        // logged in) — fire-and-forget, never blocks the screen.
        unawaited(SearchRepository().recordProductView(
          productId,
          storeId: Get.find<CurrentStoreService>().storeId,
        ));
      } else {
        ToastUtil.showToast('Product not found');
        Get.back();
      }
    } catch (e) {
      debugPrint('❌ Error loading product details: $e');
      ToastUtil.showToast('Failed to load product details');
    } finally {
      isLoading.value = false;
    }
  }

  // ─── 1b. Fetch this product's review feed ────────────────────────────────

  Future<void> fetchReviews() async {
    if (productId.isEmpty) return;
    isLoadingReviews.value = true;
    final result = await _ratingRepository.getProductReviews(
      productId,
      sort: reviewSort.value,
    );
    reviewStats.value = result.stats;
    reviews.assignAll(result.reviews);
    isLoadingReviews.value = false;
  }

  void changeReviewSort(String sort) {
    if (reviewSort.value == sort) return;
    reviewSort.value = sort;
    fetchReviews();
  }

  /// Optimistically flips the vote, then reconciles with the backend's
  /// authoritative count (reverts on failure).
  Future<void> toggleReviewHelpful(ReviewModel review) async {
    final index = reviews.indexWhere((r) => r.reviewId == review.reviewId);
    if (index == -1) return;

    final optimistic = review.copyWith(
      helpfulByMe: !review.helpfulByMe,
      helpfulCount: review.helpfulCount + (review.helpfulByMe ? -1 : 1),
    );
    reviews[index] = optimistic;

    final result = await _ratingRepository.toggleHelpful(review.reviewId);
    final currentIndex = reviews.indexWhere((r) => r.reviewId == review.reviewId);
    if (currentIndex == -1) return;
    if (result == null) {
      reviews[currentIndex] = review;
    } else {
      reviews[currentIndex] = review.copyWith(
        helpfulCount: result.helpfulCount,
        helpfulByMe: result.helpfulByMe,
      );
    }
  }

  // ─── 2. Fetch variant by ID (when user taps a specific variant) ───────────

  Future<void> fetchVariantById(String variantId) async {
    isLoadingVariant.value = true;
    try {
      final response = await _productRepository.getVariantById(
        variantId,
        storeId: Get.find<CurrentStoreService>().storeId,
      );
      if (response != null) {
        selectedVariant.value = response.variant;
        // Reset qty so it doesn't exceed new variant stock
        if (productQty.value > response.variant.resolvedStock) {
          productQty.value = 1;
        }
        debugPrint('✅ Loaded variant: ${response.variant.sku}');
      }
    } catch (e) {
      debugPrint('❌ Error loading variant: $e');
      ToastUtil.showToast('Failed to load variant');
    } finally {
      isLoadingVariant.value = false;
    }
  }

  // ─── 3. Select variant from the chip list ────────────────────────────────
  // Immediately updates selectedVariant from the already-loaded list.
  // Also triggers fetchVariantById to get the most up-to-date stock/price.

  void selectVariant(ProductVariant variant) {
    selectedVariant.value = variant;
    productQty.value = 1;
    _resetImageGallery();
    fetchVariantById(variant.id); // refresh from API
  }

  /// Tapping an attribute chip (e.g. Color=Red) — updates the current
  /// selection map and resolves the matching variant, if one exists.
  void selectOption(String name, String value) {
    selectedOptions[name] = value;
    final match = product.value?.findVariant(Map.of(selectedOptions));
    if (match != null) {
      selectVariant(match);
    }
  }

  /// Whether picking [value] for attribute [name] (on top of the other
  /// currently selected attributes) resolves to a real variant — used to
  /// gray out combinations the seller never created.
  bool isOptionValueAvailable(String name, String value) {
    final trial = Map<String, String>.of(selectedOptions)..[name] = value;
    return product.value?.variants.any(
          (v) => trial.entries.every((e) => v.optionValue(e.key) == e.value),
        ) ??
        false;
  }

  void _resetImageGallery() {
    imagePage.value = 0;
    if (imagePageController.hasClients) imagePageController.jumpToPage(0);
  }

  // ─── 4. Quantity controls ─────────────────────────────────────────────────

  void increaseQty() {
    if (product.value?.isDigital ?? false) {
      productQty.value++;
      return;
    }
    final maxStock =
        selectedVariant.value?.resolvedStock ?? product.value?.stock ?? 0;
    if (productQty.value < maxStock) {
      productQty.value++;
    } else {
      ToastUtil.showToast('Maximum stock reached');
    }
  }

  void decreaseQty() {
    if (productQty.value > 1) productQty.value--;
  }

  // ─── 5. Add to cart ───────────────────────────────────────────────────────

  Future<void> addToCart() async {
    final p = product.value;
    if (p == null) {
      ToastUtil.showToast('Product not available');
      return;
    }

    final variant = selectedVariant.value;

    if (!p.isDigital) {
      final stockAvailable = variant?.resolvedStock ?? p.stock;

      if (stockAvailable == 0) {
        ToastUtil.showToast('Product is out of stock');
        return;
      }

      if (productQty.value > stockAvailable) {
        ToastUtil.showToast('Not enough stock available');
        return;
      }
    }
    if (variant == null || variant.id.isEmpty) {
      ToastUtil.showToast('Please select a variant first');
      return;
    }

    final cartController = Get.find<CartController>();

    if (!await AppPreferences.isLoggedIn()) {
      await cartController.addLocalItem(
        CartItem(
          productId: p.id,
          productVariantId: variant.id,
          name: p.name,
          sellerName: p.sellerName,
          sellerVerified: p.sellerVerified,
          price: variant.price,
          quantity: productQty.value,
          images: variant.images.isNotEmpty ? variant.images : p.images,
          productType: p.type,
          options: variant.options,
          currency: variant.currency,
        ),
      );
      CustomAppSnackbar.show(
        soundPath: AppSounds.successSound,
        title: 'Added to Cart',
        message: '${p.name} (x${productQty.value})',
      );
      ToastUtil.showToast('${p.name} added to cart');
      return;
    }

    try {
      isAddtoCartLoading.value = true;
      final cart = await _cartRepository.addToCart(
        productId: p.id,
        productVariantId: variant.id,
        quantity: productQty.value,
      );
      cartController.addToCartBackend(cart: cart);

      CustomAppSnackbar.show(
        soundPath: AppSounds.successSound,
        title: 'Added to Cart',
        message: '${p.name} (x$productQty.value)',
      );
      ToastUtil.showToast('${p.name} added to cart');
      debugPrint(
        '🛒 Added to cart: ${p.name} x${productQty.value} '
        '(variant: ${variant.sku})',
      );
      isAddtoCartLoading.value = false;
    } catch (e) {
      ToastUtil.showToast('Failed to add to cart');
    } finally {
      isAddtoCartLoading.value = false;
    }
  }

  // ─── Computed helpers ─────────────────────────────────────────────────────

  /// Price from selected variant, fallback to product computed price
  double get displayPrice =>
      selectedVariant.value?.price ?? product.value?.price ?? 0.0;

  /// Compare-at (original/crossed-out) price, if the active variant has one
  double? get displayCompareAtPrice =>
      selectedVariant.value?.compareAtPrice ?? product.value?.compareAtPrice;

  bool get hasDiscount =>
      displayCompareAtPrice != null && displayCompareAtPrice! > displayPrice;

  /// Currency for [displayPrice]/[displayCompareAtPrice] — server-stamped
  /// on the variant from the owning store's baseCurrency.
  String? get displayCurrency => selectedVariant.value?.currency;

  /// Stock from selected variant, fallback to product total stock
  int get displayStock =>
      selectedVariant.value?.resolvedStock ?? product.value?.stock ?? 0;

  bool get inStock =>
      (product.value?.isDigital ?? false) || displayStock > 0;

  /// Images: selected variant images first, then product images
  List<String> get displayImages {
    final variantImgs = selectedVariant.value?.images ?? [];
    if (variantImgs.isNotEmpty) return variantImgs;
    return product.value?.images ?? [];
  }

  /// Refresh
  @override
  Future<void> refresh() => fetchProductDetails();
}
