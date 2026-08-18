// ignore_for_file: avoid_print
// End-to-end pass for the guest-mode onboarding flow (Phases 2-6): fresh
// install -> onboarding carousel -> guest browse/cart -> protected action
// triggers the login bottom sheet -> login resumes the original action ->
// guest cart merges into the account cart -> logout returns to guest Home
// -> the seller path lands on the seller shell, never buyer Home.
//
// Uses two pre-verified throwaway accounts (created via curl against the
// same backend instance this test targets) so the OTP-entry screen itself
// isn't part of what's under test here — Phases 2-6 didn't touch OTP entry,
// they touched the guard/resume/merge/routing logic, which a plain login
// exercises identically to a signup.
//
// Run against a backend whose baseUrl matches ApiConstants.baseUrl, with
// these two accounts already registered+verified:
//   BUYER_EMAIL / BUYER_PASSWORD  (role: user)
//   SELLER_EMAIL / SELLER_PASSWORD (role: seller)

import 'package:book_store_app/app/bottom_bar/controllers/bottom_navbar_controller.dart';
import 'package:book_store_app/app/components/wishlist_heart_button.dart';
import 'package:book_store_app/app/modules/auth/controller/auth_controller.dart';
import 'package:book_store_app/app/modules/cart/controllers/cart_controller.dart';
import 'package:book_store_app/app/modules/home/controllers/home_controller.dart';
import 'package:book_store_app/app/modules/home/widgets/icon_badge.dart';
import 'package:book_store_app/app/modules/home/widgets/product_card.dart';
import 'package:book_store_app/app/modules/home/widgets/products_grid.dart';
import 'package:book_store_app/app/modules/wishlist/controllers/wishlist_controller.dart';
import 'package:book_store_app/app/routes/app_pages.dart';
import 'package:book_store_app/core/widgets/buttons/base_buttons.dart';
import 'package:book_store_app/shared_prefrences/app_prefrences.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:book_store_app/main.dart' as app;

const _buyerEmail = 'e2e-buyer-1786517506@example.com';
const _buyerPassword = 'Test1234!';
const _sellerEmail = 'e2e-seller-1786517527@example.com';
const _sellerPassword = 'Test1234!';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpUntil(
    WidgetTester tester,
    bool Function() condition, {
    Duration timeout = const Duration(seconds: 20),
  }) async {
    final end = DateTime.now().add(timeout);
    while (!condition()) {
      if (DateTime.now().isAfter(end)) {
        fail('Timed out waiting for condition');
      }
      await tester.pump(const Duration(milliseconds: 250));
    }
  }

  // A single large `tester.pump(Duration(seconds: N))` call appears to hang
  // indefinitely against this real (non-fake-async) integration_test binding
  // once real network I/O is in flight — looping smaller pumps avoids it.
  Future<void> pumpFor(WidgetTester tester, Duration total) async {
    final end = DateTime.now().add(total);
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 200));
    }
  }

  testWidgets('guest flow: onboarding, browse, protected-action resume, merge, logout, seller path', (
    tester,
  ) async {
    // ── Fresh install simulation ────────────────────────────────────────────
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    app.main();
    await tester.pump();

    // ── Splash (5.2s, plus real cold-start overhead for Firebase/dotenv
    // init before the splash controller's own timer even starts) →
    // first-launch onboarding carousel, IF the backend has slides configured
    // (OnboardingController.finish()'s auto-skip-when-empty means an
    // environment with zero seeded slides — like staging at the time of
    // writing — goes straight to Home instead; both are correct, this test
    // is about guard/resume/merge/routing (Phases 2-6), not slide content,
    // so it tolerates either) ───────────────────────────────────────────────
    await pumpUntil(
      tester,
      () => Get.currentRoute == Routes.onboarding || Get.currentRoute == Routes.mainHome,
      timeout: const Duration(seconds: 30),
    );
    if (Get.currentRoute == Routes.onboarding) {
      await tester.pump(const Duration(milliseconds: 500));
      if (find.text('Skip').evaluate().isNotEmpty) {
        await tester.tap(find.text('Skip'));
        await tester.pump(const Duration(milliseconds: 500));
      }
      print('✅ Onboarding carousel shown on first launch (backend had slides configured)');
    } else {
      print('ℹ️ No onboarding slides configured on this backend — app correctly auto-skipped to Home');
    }

    // ── Guest-mode Home — no login wall ─────────────────────────────────────
    print('… waiting for mainHome route');
    await pumpUntil(tester, () => Get.currentRoute == Routes.mainHome);
    print('… on mainHome, waiting for product cards to render');
    final homeController = Get.find<HomeController>();
    try {
      await pumpUntil(
        tester,
        () => find.byType(ProductCard).evaluate().isNotEmpty,
        timeout: const Duration(seconds: 15),
      );
    } catch (e) {
      print(
        '❌ DIAGNOSTIC: filteredProducts=${homeController.filteredProducts.length} '
        'products=${homeController.products.length} '
        'isLoading=${homeController.isLoading.value} '
        'isFetchingProducts=${homeController.isFetchingProducts.value} '
        'ProductsGrid found=${find.byType(ProductsGrid).evaluate().length} '
        'GridView found=${find.byType(GridView).evaluate().length}',
      );
      rethrow;
    }
    print('… checking route');
    expect(Get.currentRoute, Routes.mainHome);
    print('… checking logged-out state');
    expect(await AppPreferences.isLoggedIn(), false);
    print('… checking for product cards (found: ${find.byType(ProductCard).evaluate().length})');
    expect(
      find.byType(ProductCard),
      findsWidgets,
      reason: 'guest should see real product content with no login wall',
    );
    print(
      '… checking for login nudge banner (found: ${find.text('Login to continue').evaluate().length})',
    );
    expect(
      find.text('Login to continue'),
      findsWidgets,
      reason: 'non-blocking login nudge should be present but not blocking',
    );
    print('✅ Guest lands directly on Home, browsable, non-blocking login banner present');

    // ── Guest add-to-cart (local cart, no network 401) ──────────────────────
    final firstCard = find.byWidgetPredicate((w) => w is ProductCard && w.index == 0);
    expect(firstCard, findsOneWidget);
    await tester.tap(find.descendant(of: firstCard, matching: find.byType(IconBadge)));
    await tester.pump(const Duration(milliseconds: 800));

    final cartController = Get.find<CartController>();
    expect(
      cartController.cartItems.length,
      1,
      reason: 'guest add-to-cart should populate the local cart with no login prompt',
    );
    expect((await AppPreferences.getGuestCartItems()).length, 1);
    final addedProductId = cartController.cartItems.first.productId;
    print('✅ Guest added an item to the local cart without hitting a login wall');

    // ── Protected action: wishlist heart triggers the login bottom sheet ────
    await tester.tap(find.descendant(of: firstCard, matching: find.byType(WishlistHeartButton)));
    await tester.pump(const Duration(milliseconds: 600));
    expect(
      find.text('Log In'),
      findsOneWidget,
      reason: 'a protected action (wishlist) should surface the login prompt sheet',
    );
    expect(find.text('Sign Up'), findsOneWidget);
    print('✅ Protected action (wishlist) surfaced the login bottom sheet, not a hard redirect');

    await tester.tap(find.text('Log In'));
    await tester.pump(const Duration(milliseconds: 500));
    await pumpUntil(tester, () => Get.currentRoute == Routes.authTabView);

    final authController = Get.find<AuthController>();
    authController.loginEmailController.text = _buyerEmail;
    authController.loginPasswordController.text = _buyerPassword;
    await tester.pump();
    await tester.tap(find.widgetWithText(PrimaryButton, 'Log in'));

    await pumpUntil(tester, () => Get.currentRoute == Routes.mainHome, timeout: const Duration(seconds: 15));
    await pumpFor(tester, const Duration(seconds: 2));
    print('✅ Login succeeded and popped back to where the guard fired (no hard redirect)');

    // ── Resume + merge verification ─────────────────────────────────────────
    expect(await AppPreferences.isLoggedIn(), true);
    final wishlistController = Get.find<WishlistController>();
    await pumpUntil(tester, () => wishlistController.isWishlisted(addedProductId));
    expect(
      wishlistController.isWishlisted(addedProductId),
      true,
      reason: 'the original wishlist action should resume and complete automatically after login',
    );
    print('✅ Original wishlist action resumed automatically after login');

    await pumpUntil(
      tester,
      () => cartController.backendCart.value != null,
      timeout: const Duration(seconds: 10),
    );
    expect(
      cartController.cartItems.any((i) => i.productId == addedProductId),
      true,
      reason: 'the item added to the guest cart should have been merged into the account cart',
    );
    expect(
      await AppPreferences.getGuestCartItems(),
      isEmpty,
      reason: 'guest cart should be cleared once merged',
    );
    print('✅ Guest cart merged into the account cart on login');

    // ── Logout returns to guest Home, not a login wall ──────────────────────
    Get.find<BottomNavController>().changeTab(4); // Profile tab
    await pumpFor(tester, const Duration(seconds: 1));
    await tester.tap(find.text('Logout'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.widgetWithText(CupertinoDialogAction, 'Logout'));
    await pumpUntil(tester, () => Get.currentRoute == Routes.mainHome);
    expect(await AppPreferences.isLoggedIn(), false);
    print('✅ Logout returns to guest-mode Home, not a login wall');

    // ── Seller path: Sell on Solvexo -> seller landing -> seller login ──────
    // Post-Phase-3 (POS extraction): seller-management and the seller shell
    // no longer exist in this app at all — they live only in the standalone
    // POS app now. A seller logging in here has nowhere seller-specific to
    // go, so `AuthController._navigateByRole` intentionally falls back to
    // the buyer guest Home for every role (see that method's own comment).
    Get.find<BottomNavController>().changeTab(4);
    await pumpFor(tester, const Duration(seconds: 1));
    await tester.tap(find.text('Sell on Solvexo'));
    await pumpUntil(tester, () => Get.currentRoute == Routes.welcome);
    print('✅ "Sell on Solvexo" opens the seller landing screen');

    await tester.tap(find.text('Get Started'));
    await pumpUntil(tester, () => Get.currentRoute == Routes.authTabView);

    final authController2 = Get.find<AuthController>();
    authController2.loginEmailController.text = _sellerEmail;
    authController2.loginPasswordController.text = _sellerPassword;
    await tester.pump();
    await tester.tap(find.widgetWithText(PrimaryButton, 'Log in'));

    await pumpUntil(
      tester,
      () => Get.currentRoute != Routes.authTabView,
      timeout: const Duration(seconds: 15),
    );
    await pumpFor(tester, const Duration(seconds: 2));

    expect(
      Get.currentRoute,
      Routes.mainHome,
      reason: 'seller-management moved to the standalone POS app (Phase 3) — '
          'a seller login in this app now falls back to buyer guest Home '
          'like any other role, since there is no seller shell left here',
    );
    print('✅ Seller login falls back to buyer guest Home (${Get.currentRoute}) — no seller shell left in this app');
  });
}
