import 'package:book_store_app/core/base/base_controller.dart';
import 'package:book_store_app/app/components/buttons/app_button.dart';
import 'package:book_store_app/app/components/custom_app_snack_bar.dart';
import 'package:book_store_app/app/components/custom_text.dart';
import 'package:book_store_app/app/data/repositories/cart_repository.dart';
import 'package:book_store_app/app/data/repositories/checkout_repository.dart';
import 'package:book_store_app/app/data/services/auth_gate_service.dart';
import 'package:book_store_app/app/modules/address/controllers/address_controller.dart';
import 'package:book_store_app/app/modules/cart/models/cart_response_model.dart';
import 'package:book_store_app/app/modules/wishlist/controllers/wishlist_controller.dart';
import 'package:book_store_app/app/routes/app_pages.dart';
import 'package:book_store_app/app/services/promotion_attribution_service.dart';
import 'package:book_store_app/config/resources/app_colors.dart';
import 'package:book_store_app/config/resources/app_sounds.dart';
import 'package:book_store_app/shared_prefrences/app_prefrences.dart';
import 'package:book_store_app/utils/app_font_size.dart';
import 'package:book_store_app/utils/custom_alert_dialog_util.dart';
import 'package:book_store_app/utils/toast_util.dart';
import 'package:flutter/material.dart';

import 'package:get/get.dart';

class CartController extends BaseController {
  CartController({
    CartRepository? cartRepository,
    CheckoutRepository? checkoutRepository,
    WishlistController? wishlistController,
  }) : _cartRepository = cartRepository ?? CartRepository(),
       _checkoutRepository = checkoutRepository ?? CheckoutRepository(),
       wishlistController =
           wishlistController ??
           (Get.isRegistered<WishlistController>()
               ? Get.find<WishlistController>()
               : Get.put(WishlistController()));

  final CartRepository _cartRepository;
  final CheckoutRepository _checkoutRepository;

  // ─── State ────────────────────────────────────────────────────────────────
  final RxList<CartItem> cartItems = <CartItem>[].obs;
  final RxBool selectAll = false.obs;
  @override
  final RxBool isLoading = false.obs;
  final RxBool isCheckingOut = false.obs;

  final Rx<double> subtotal = 0.0.obs;
  final Rx<double> shipping = 0.0.obs;
  final Rx<double> tax = 0.0.obs;
  final Rx<double> total = 0.0.obs;

  final Rx<CartResponseModel?> backendCart = Rx<CartResponseModel?>(null);

  // ─── Lifecycle ────────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    fetchCart();
  }

  Future<void> refreshCart() => fetchCart();

  // ─── 1. Fetch cart ────────────────────────────────────────────────────────

  Future<void> fetchCart() async {
    // Cart is a login-only endpoint backend-side — guests read/write a
    // local cart instead of hitting it (and 401ing) on every load.
    if (!await isUserLogin()) {
      await _loadLocalCart();
      return;
    }
    try {
      debugPrint("Fetching cart....");
      isLoading.value = true;

      final cart = await _cartRepository.getCart();
      debugPrint("cart: $cart");

      if (cart != null) {
        backendCart.value = cart;
        cartItems.assignAll(cart.items);
        selectAll.value = true;
        calculateTotal();
      } else {
        cartItems.clear();
        calculateTotal();
      }
    } catch (e) {
      ToastUtil.showToast('Failed to load cart');
    } finally {
      isLoading.value = false;
    }
  }

  // ─── Guest (local-only) cart ──────────────────────────────────────────────

  Future<void> _loadLocalCart() async {
    final raw = await AppPreferences.getGuestCartItems();
    cartItems.assignAll(raw.map(CartItem.fromLocalJson));
    selectAll.value = true;
    calculateTotal();
  }

  Future<void> _persistLocalCart() async {
    await AppPreferences.saveGuestCartItems(
      cartItems.map((i) => i.toLocalJson()).toList(),
    );
  }

  /// Adds a fully-formed `CartItem` (built by the caller from already-loaded
  /// product/variant data — no network round-trip needed) to the local guest
  /// cart, summing quantity on conflict just like the backend's `addToCart`.
  Future<void> addLocalItem(CartItem newItem) async {
    final index = cartItems.indexWhere(
      (i) =>
          i.productId == newItem.productId &&
          i.productVariantId == newItem.productVariantId,
    );
    if (index != -1) {
      cartItems[index] = cartItems[index].copyWith(
        quantity: cartItems[index].quantity + newItem.quantity,
      );
    } else {
      cartItems.add(newItem);
    }
    cartItems.refresh();
    selectAll.value = true;
    calculateTotal();
    await _persistLocalCart();
  }

  // ─── 2. Add to cart ───────────────────────────────────────────────────────

  Future<void> addToCartBackend({CartResponseModel? cart}) async {
    try {
      isLoading.value = true;

      if (cart != null) {
        backendCart.value = cart;
        cartItems.assignAll(cart.items);
        for (final item in cartItems) {
          item.isSelected = true;
        }
        selectAll.value = true;
        calculateTotal();
      } else {
        await fetchCart();
      }
    } catch (e) {
      ToastUtil.showToast('Failed to add to cart');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateQuantity(
    String productId,
    String productVariantId,
    String action,
  ) async {
    if (!await isUserLogin()) {
      final index = cartItems.indexWhere(
        (i) => i.productId == productId && i.productVariantId == productVariantId,
      );
      if (index == -1) return;
      final current = cartItems[index];
      final newQty = action == 'increase'
          ? current.quantity + 1
          : (current.quantity - 1).clamp(1, current.quantity);
      cartItems[index] = current.copyWith(quantity: newQty);
      cartItems.refresh();
      calculateTotal();
      await _persistLocalCart();
      return;
    }
    try {
      isLoading.value = true;

      final updatedItem = await _cartRepository.updateCartItem(
        productId: productId,
        productVariantId: productVariantId,
        action: action,
      );

      if (updatedItem != null) {
        final index = cartItems.indexWhere(
          (i) =>
              i.productId == updatedItem.productId &&
              i.productVariantId == updatedItem.productVariantId,
        );

        if (index != -1) {
          cartItems[index] = cartItems[index].copyWith(
            quantity: updatedItem.quantity,
            price: updatedItem.price, // ← price (not backendPrice)
            isSelected: cartItems[index].isSelected,
          );
          cartItems.refresh();
        }

        calculateTotal();
      }
    } catch (e) {
      ToastUtil.showToast('Failed to update quantity');
    } finally {
      isLoading.value = false;
    }
  }

  // ── Increase ───────────────────────────────────────────────────────────────
  Future<void> increaseQuantity(
    String productId,
    String productVariantId,
  ) async {
    await updateQuantity(productId, productVariantId, 'increase');
  }

  Future<void> decreaseQuantity(
    String productId,
    String productVariantId,
  ) async {
    await updateQuantity(productId, productVariantId, 'decrease');
  }

  Future<void> removeFromCart(String productId, String productVariantId) async {
    if (!await isUserLogin()) {
      cartItems.removeWhere(
        (i) => i.productId == productId && i.productVariantId == productVariantId,
      );
      updateSelectAll();
      calculateTotal();
      await _persistLocalCart();
      ToastUtil.showToast('Item removed');
      return;
    }
    try {
      isLoading.value = true;

      final remainingItems = await _cartRepository.removeFromCart(
        productId,
        productVariantId,
      );

      if (remainingItems != null) {
        // Replace cartItems with the remaining items from the response
        cartItems.assignAll(remainingItems);
        updateSelectAll();
        calculateTotal();
        ToastUtil.showToast('Item removed');
      }
    } catch (e) {
      ToastUtil.showToast('Failed to remove item');
    } finally {
      isLoading.value = false;
    }
  }

  // ─── 5. Clear cart ────────────────────────────────────────────────────────

  Future<void> clearCart() async {
    if (!await isUserLogin()) {
      cartItems.clear();
      calculateTotal();
      await AppPreferences.clearGuestCart();
      return;
    }
    try {
      isLoading.value = true;

      final success = await _cartRepository.clearCart();

      if (success) {
        backendCart.value = null;
        cartItems.clear();
        calculateTotal();
      }
    } catch (e) {
      ToastUtil.showToast('Failed to clear cart');
    } finally {
      isLoading.value = false;
    }
  }

  // ─── 6. Selection logic ───────────────────────────────────────────────────

  void toggleSelectAll(bool value) {
    selectAll.value = value;
    for (final item in cartItems) {
      item.isSelected = value;
    }
    cartItems.refresh();
    calculateTotal();
  }

  void toggleItemSelection(CartItem item, bool value) {
    item.isSelected = value;
    cartItems.refresh();
    updateSelectAll();
    calculateTotal();
  }

  void updateSelectAll() {
    selectAll.value =
        cartItems.isNotEmpty && cartItems.every((item) => item.isSelected);
  }

  void removeSelectedItems() {
    final selectedItems = cartItems.where((item) => item.isSelected).toList();
    for (final item in selectedItems) {
      removeFromCart(item.productId, item.productVariantId);
    }
  }

  // ─── 7. Total calculation ─────────────────────────────────────────────────

  /// Only labeled with a currency symbol when every selected item shares
  /// one — a mixed-currency selection renders the plain number instead.
  String? get selectedCurrency {
    final selected = cartItems.where((e) => e.isSelected).toList();
    if (selected.isEmpty) return null;
    final first = selected.first.currency;
    return selected.every((i) => i.currency == first) ? first : null;
  }

  void calculateTotal() {
    final selected = cartItems.where((e) => e.isSelected);

    subtotal.value = selected.fold(
      0.0,
      (sum, item) => sum + (item.actualPrice * item.quantity),
    );

    if (subtotal.value == 0) {
      shipping.value = 0;
      tax.value = 0;
      total.value = 0;
      return;
    }

    shipping.value = subtotal.value >= 50 ? 0 : 5;
    tax.value = subtotal.value * 0.1;
    total.value = subtotal.value + shipping.value + tax.value;
  }

  // ─── 8. Getters ───────────────────────────────────────────────────────────

  int get itemCount => cartItems.length;
  int get totalItems => backendCart.value?.totalItems ?? 0;
  bool get isEmpty => cartItems.isEmpty;
  bool get hasItems => cartItems.isNotEmpty;
  bool get hasSelectedItems => cartItems.any((item) => item.isSelected);

  // ─── 9. Checkout ──────────────────────────────────────────────────────────

  Future<void> proceedToCheckout() async {
    if (isCheckingOut.value) return;

    // Checkout is login-only. If this was a guest, a successful login here
    // also merges the local cart into the account cart and refreshes
    // `cartItems` (see AuthController.signInWithGoogle) before this resumes.
    final allowed = await AuthGateService.instance.requireAuth(
      message: 'Login to place your order.',
    );
    if (!allowed) return;

    // Only the ticked cart lines go to checkout — without this the backend
    // defaults to checking out the ENTIRE cart.
    final selected = cartItems
        .where((item) => item.isSelected)
        .map(
          (item) => {
            'productId': item.productId,
            'variantId': item.productVariantId,
          },
        )
        .toList();
    if (selected.isEmpty) {
      ToastUtil.showToast('Select at least one item to checkout');
      return;
    }

    isCheckingOut.value = true;
    try {
      // If the buyer arrived via a platform/store banner tap within the last
      // 30 minutes, attribute this checkout to it for promotion conversion
      // tracking (see PromotionAttributionService doc comment).
      final attribution = PromotionAttributionService.instance.consumeIfFresh();
      final result = await _checkoutRepository.createCheckout(
        items: selected,
        attributedBannerId: attribution.bannerId,
        attributedStoreBannerId: attribution.storeBannerId,
      );
      if (result.success && result.data != null) {
        Get.toNamed(Routes.checkoutView, arguments: result.data);
      } else if (result.addressRequired) {
        _promptAddDeliveryAddress();
      } else {
        ToastUtil.showToast(result.message ?? 'Failed to create checkout');
      }
    } finally {
      isCheckingOut.value = false;
    }
  }

  /// Shown when the buyer has no saved address at all (the backend resolves
  /// the delivery address itself and only rejects checkout in that case —
  /// see `CheckoutRepository.createCheckout`). Adding an address here pushes
  /// straight to the add-address form; saving it returns here to the cart.
  void _promptAddDeliveryAddress() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        title: const CustomText(
          text: 'Delivery Address Required',
          fontSize: AppFontSize.small,
          fontWeight: FontWeight.w700,
          color: AppColors.black2,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.add_location_alt_outlined,
                color: AppColors.primaryColor,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            const CustomText(
              text: 'You need a delivery address to check out',
              fontSize: AppFontSize.small2,
              fontWeight: FontWeight.w700,
              color: AppColors.black2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const CustomText(
              text: 'Add an address so we know where to ship your order.',
              fontSize: AppFontSize.verySmall,
              color: AppColors.grey,
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Not Now',
                  isOutlined: true,
                  onPressed: () => Get.back(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppButton(
                  label: 'Add Address',
                  onPressed: () {
                    Get.back();
                    if (!Get.isRegistered<AddressController>()) {
                      Get.put(AddressController());
                    }
                    Get.find<AddressController>().clearForm();
                    Get.toNamed(Routes.addAddressView);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> getOrderItems() {
    return cartItems
        .where((item) => item.isSelected)
        .map((item) => item.toBackendJson())
        .toList();
  }

  // ─── 10. UI helpers ───────────────────────────────────────────────────────
  final WishlistController wishlistController;
  Future<void> moveToWishlist(CartItem item) async {
    final allowed = await AuthGateService.instance.requireAuth(
      message: 'Login to save items to your wishlist.',
    );
    if (!allowed) return;
    await wishlistController.addToWishlist(
      productId: item.productId,
      productVariantId: item.productVariantId,
    );
    CustomAppSnackbar.show(
      soundPath: AppSounds.successSound,
      title: 'Wishlist',
      message: '${item.name} moved to wishlist',
    );
  }

  /// Bulk "Move to Wishlist" for every currently-selected cart item.
  Future<void> moveSelectedToWishlist() async {
    final selectedItems = cartItems.where((item) => item.isSelected).toList();
    for (final item in selectedItems) {
      await moveToWishlist(item);
    }
  }

  void showDeleteConfirmation({
    Function()? onLeftButtonTap,
    Function()? onRightButtonTap,
  }) {
    showCustomDialog(
      title: 'Are you sure?',
      content:
          'Try moving the item to your wishlist, just in case you need it someday.',
      onLeftButtonTap: onLeftButtonTap,
      leftButtonName: 'Move to Wishlist',
      onRightButtonTap: onRightButtonTap,
      rightButtonName: 'Delete',
    );
  }

  void showWishListConformation({Function()? onRightButtonTap}) {
    showCustomDialog(
      title: 'Move to Wishlist?',
      content: 'Are you sure you want to move the item to your wishlist?',
      leftButtonName: 'Cancel',
      onRightButtonTap: onRightButtonTap,
      rightButtonName: 'Yes',
      onLeftButtonTap: Get.back,
    );
  }
}
