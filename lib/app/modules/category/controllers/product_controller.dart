import 'package:book_store_app/app/components/buttons/app_button.dart';
import 'package:book_store_app/app/components/common_image_view.dart';
import 'package:book_store_app/app/components/custom_app_snack_bar.dart';
import 'package:book_store_app/app/components/custom_bottom_sheet.dart';
import 'package:book_store_app/app/components/custom_text.dart';
import 'package:book_store_app/app/components/recommended_product_list.dart';
import 'package:book_store_app/app/components/svg_icon.dart';
import 'package:book_store_app/app/data/repositories/product_repository.dart';
import 'package:book_store_app/app/data/services/current_store_service.dart';
import 'package:book_store_app/app/modules/category/models/category_model.dart'
    as BackendModel;
import 'package:book_store_app/app/modules/category/models/product_model.dart'
    as BackendModel;
import 'package:book_store_app/app/modules/category/models/product_model.dart';
import 'package:book_store_app/app/modules/product_details/controller/product_detail_controller.dart';
import 'package:book_store_app/app/routes/app_pages.dart';
import 'package:book_store_app/config/resources/app_sounds.dart';
import 'package:book_store_app/config/store_config.dart';
import 'package:book_store_app/utils/app_font_size.dart';
import 'package:book_store_app/utils/toast_util.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProductController extends GetxController {
  final ProductRepository _productRepository = ProductRepository();

  RxInt selectedCategoryIndex = 0.obs;
  RxBool isLoading = false.obs;
  RxBool isFetchingProducts = false.obs;

  // ─── Pagination ───────────────────────────────────────────────────────────
  RxInt currentPage = 1.obs;
  RxInt totalPages = 1.obs;
  RxBool hasMoreProducts = true.obs;

  // ─── Categories ───────────────────────────────────────────────────────────
  final RxList<BackendModel.CategoryModel> categories =
      <BackendModel.CategoryModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    initializeData();
  }

  Future<void> initializeData() async {
    isLoading.value = true;
    try {
      await fetchCategories();
      await fetchProducts(); // fetch all products (no category filter)
    } catch (e) {
      debugPrint('Error initializing data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchCategories() async {
    try {
      final fetchedCategories = await _productRepository.getCategories();
      if (fetchedCategories != null) {
        categories.assignAll(fetchedCategories);
        debugPrint('Fetched ${fetchedCategories.length} categories');
      }
    } catch (e) {
      debugPrint('Error fetching categories: $e');
      ToastUtil.showToast('Failed to load categories');
    }
  }

  // ─── Products ─────────────────────────────────────────────────────────────
  RxList<BackendModel.ProductModel> products =
      <BackendModel.ProductModel>[].obs;

  /// Returns the selected category ID, or null when "All" is selected (index 0)
  String? get _selectedCategoryId {
    if (selectedCategoryIndex.value == 0) return null;
    return categories[selectedCategoryIndex.value - 1].id;
  }

  /// Fetch products using the products-by-category endpoint.
  /// When no categoryId is provided the backend returns ALL products.
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
      final response = await _productRepository.getProductsByCategory(
        categoryId: _selectedCategoryId, // null → all products
        page: currentPage.value,
        limit: 20,
      );

      if (response != null) {
        // Stopgap store scoping — see _scopeToCurrentStore below.
        final scoped = _scopeToCurrentStore(response.products);
        if (loadMore) {
          products.addAll(scoped);
        } else {
          products.assignAll(scoped);
        }

        totalPages.value = response.pages;
        hasMoreProducts.value = currentPage.value < totalPages.value;

        debugPrint(
          'Fetched ${response.products.length} products '
          '(Page ${currentPage.value}/${totalPages.value})',
        );
      }
    } catch (e) {
      debugPrint('Error fetching products: $e');
      ToastUtil.showToast('Failed to load products');
      if (loadMore) currentPage.value--;
    } finally {
      isFetchingProducts.value = false;
    }
  }

  Future<void> loadMoreProducts() async {
    await fetchProducts(loadMore: true);
  }

  // ─── Category selection ───────────────────────────────────────────────────
  void selectCategory(int index) {
    selectedCategoryIndex.value = index;
    fetchProducts(); // re-fetches with new (or null) categoryId
  }

  // ─── Product Details ──────────────────────────────────────────────────────
  final Rx<BackendModel.ProductModel?> selectedProduct =
      Rx<BackendModel.ProductModel?>(null);

  RxInt productQty = 1.obs;
  RxInt selectedVariantIndex = 0.obs;

  Future<void> loadProductDetails(String productId) async {
    try {
      isLoading.value = true;
      final product = await _productRepository.getProductById(productId);
      if (product != null) {
        selectedProduct.value = product;
        productQty.value = 1;
        selectedVariantIndex.value = 0;
        debugPrint('Loaded product details: ${product.name}');
      } else {
        ToastUtil.showToast('Product not found');
      }
    } catch (e) {
      debugPrint('Error loading product details: $e');
      ToastUtil.showToast('Failed to load product details');
    } finally {
      isLoading.value = false;
    }
  }

  void openProductDetails(dynamic product) {
    if (product is BackendModel.ProductModel) {
      selectedProduct.value = product;
      productQty.value = 1;
      selectedVariantIndex.value = 0;
      Get.toNamed(
        Routes.productDetailsView,
        arguments: {"productId": product.id},
      );
    } else if (product is ProductModel) {
      ToastUtil.showToast('Please refresh and try again');
    }
  }

  void increaseQty() {
    if (selectedProduct.value == null) return;
    if (productQty.value < selectedProduct.value!.stock) {
      productQty.value++;
    } else {
      ToastUtil.showToast('Maximum stock reached');
    }
  }

  void decreaseQty() {
    if (productQty.value > 1) productQty.value--;
  }

  void selectVariant(int index) {
    selectedVariantIndex.value = index;
  }

  List<BackendModel.ProductModel> get relatedProducts {
    if (selectedProduct.value == null) return [];
    return products
        .where(
          (p) =>
              p.category?.id == selectedProduct.value!.category?.id &&
              p.id != selectedProduct.value!.id,
        )
        .take(6)
        .toList();
  }

  void addToCart(context, prodImg) {
    if (selectedProduct.value == null) {
      ToastUtil.showToast('Please select a product');
      return;
    }
    if (!selectedProduct.value!.inStock) {
      ToastUtil.showToast('Product is out of stock');
      return;
    }
    if (productQty.value > selectedProduct.value!.stock) {
      ToastUtil.showToast('Not enough stock available');
      return;
    }

    final size = MediaQuery.of(context).size;
    final productDetailController = Get.put(ProductDetailController());

    productDetailController.addToCart();

    Get.bottomSheet(
      CustomBottomSheet(
        title: 'You might like',
        height: size.height / 1.5,
        widget: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RecommendedProductList(),
            const SizedBox(height: 20),
            Row(
              spacing: 20,
              children: [
                selectedProduct.value!.images.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CommonImageView(
                          url: selectedProduct.value!.images.first,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        ),
                      )
                    : SvgIcon(assetName: prodImg, size: 50),
                CustomText(
                  text: 'Added to cart',
                  fontSize: AppFontSize.regular,
                  fontWeight: FontWeight.w600,
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: AppButton(
                    label: 'Go to Cart',
                    onPressed: () => Get.toNamed(Routes.cartView),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    CustomAppSnackbar.show(
      soundPath: AppSounds.successSound,
      title: 'Added to Cart',
      message: '${selectedProduct.value!.name} (x$productQty)',
    );
  }

  // ─── Search ───────────────────────────────────────────────────────────────
  RxString searchQuery = ''.obs;

  Future<void> searchProducts(String query) async {
    searchQuery.value = query;
    if (query.isEmpty) {
      await fetchProducts();
      return;
    }

    isFetchingProducts.value = true;
    try {
      final response = await _productRepository.getProducts(
        search: query,
        page: 1,
        limit: 50,
      );
      if (response != null) {
        // Stopgap store scoping — see _scopeToCurrentStore below.
        final scoped = _scopeToCurrentStore(response.products);
        products.assignAll(scoped);
        debugPrint('Search found ${scoped.length} products');
      }
    } catch (e) {
      debugPrint('Error searching products: $e');
      ToastUtil.showToast('Search failed');
    } finally {
      isFetchingProducts.value = false;
    }
  }

  void clearSearch() {
    searchQuery.value = '';
    fetchProducts();
  }

  Future<void> refreshData() async {
    await initializeData();
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────
  // Both `getProductsByCategory` (category browsing) and `getProducts`
  // (search) are marketplace-wide endpoints — neither has a storeId param,
  // so on a single-store build they can hand back other stores' products
  // too. Until the backend adds a storeId filter to both, scope results
  // down to this build's one store client-side. This only narrows whatever
  // page the server already returned — it does not fix that page's
  // reported totals/hasMore, which still reflect the unfiltered
  // marketplace result set (same stopgap-limitation pattern as
  // HomeController's _applyLocalFilters comment for getStoreProducts).
  List<BackendModel.ProductModel> _scopeToCurrentStore(
    List<BackendModel.ProductModel> list,
  ) {
    if (!StoreConfig.isConfigured) return list;
    final storeId = Get.find<CurrentStoreService>().storeId;
    if (storeId == null) return list;
    return list.where((p) => p.storeId == storeId).toList();
  }
}
