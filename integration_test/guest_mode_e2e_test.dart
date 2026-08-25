// ignore_for_file: avoid_print
// End-to-end pass for the guest-mode onboarding flow (Phases 2-6): fresh
// install -> onboarding carousel -> guest browse/cart -> protected action
// triggers the login bottom sheet -> login resumes the original action ->
// guest cart merges into the account cart -> logout returns to guest Home
// -> the seller path lands on the seller shell, never buyer Home.
//
// Phase 10 removed email/password (and Facebook/Apple) auth entirely —
// Google Sign-In is now the only way in, via a native account-chooser UI
// that this widget-test harness can't drive headlessly. This test is kept
// (and its UI lookups updated to the Google-only login screen) as living
// documentation of the guard/resume/merge/routing behavior it exercises,
// but it's marked `skip` below since it can no longer complete a real
// sign-in without a device-linked Google account.

import 'package:book_store_app/app/bottom_bar/controllers/bottom_navbar_controller.dart';
import 'package:book_store_app/app/components/wishlist_heart_button.dart';
import 'package:book_store_app/app/modules/cart/controllers/cart_controller.dart';
import 'package:book_store_app/app/modules/home/controllers/home_controller.dart';
import 'package:book_store_app/app/modules/home/widgets/icon_badge.dart';
import 'package:book_store_app/app/modules/home/widgets/product_card.dart';
import 'package:book_store_app/app/modules/wishlist/controllers/wishlist_controller.dart';
import 'package:book_store_app/app/routes/app_pages.dart';
import 'package:book_store_app/shared_prefrences/app_prefrences.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:book_store_app/main.dart' as app;

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

  testWidgets(
    'guest flow: onboarding, browse, protected-action resume, merge, logout, seller path',
    skip: true, // Google Sign-In's native account chooser can't be driven headlessly — see header comment.
    (tester) async {
    // ── Fresh install simulation ────────────────────────────────────────────
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    app.main();
    await tester.pump();

    // ── Splash (5.2s, plus real cold-start overhead for Firebase/dotenv
    // init before the splash controller's own timer even starts) →
    // first-launch onboarding carousel. Onboarding content is hardcoded
    // (`lib/config/onboarding_content.dart`, no backend call), so a fresh
    // install always shows it — no more "backend might have zero slides"
    // tolerance needed. ─────────────────────────────────────────────────────
    await pumpUntil(
      tester,
      () => Get.currentRoute == Routes.onboarding,
      timeout: const Duration(seconds: 30),
    );
    await tester.pump(const Duration(milliseconds: 500));
    if (find.text('Skip').evaluate().isNotEmpty) {
      await tester.tap(find.text('Skip'));
      await tester.pump(const Duration(milliseconds: 500));
    }
    print('✅ Onboarding carousel shown on first launch');

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
        '❌ DIAGNOSTIC: products=${homeController.products.length} '
        'isLoading=${homeController.isLoading.value} '
        'isFetchingProducts=${homeController.isFetchingProducts.value} '
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
      find.text('Continue with Google'),
      findsOneWidget,
      reason: 'a protected action (wishlist) should surface the login prompt sheet',
    );
    print('✅ Protected action (wishlist) surfaced the login bottom sheet, not a hard redirect');

    await tester.tap(find.text('Continue with Google'));
    await tester.pump(const Duration(milliseconds: 500));
    await pumpUntil(tester, () => Get.currentRoute == Routes.authTabView);

    // NOTE: from here on, completing sign-in requires the native Google
    // account chooser, which this harness can't drive — hence `skip: true`
    // on this whole test. Left in place as documentation of the flow.
    await tester.tap(find.text('Continue with Google'));

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

    // NOTE (Phase 9 — single-store conversion): this test previously ended
    // with a "Seller path" section that tapped a "Sell on Solvexo" button
    // (`SellOnSolvexoCard`, shown on Home for guests) to reach the seller
    // landing screen and confirm a seller login falls back to buyer Home.
    // `SellOnSolvexoCard` was deleted in Phase 9 (a single-store app has no
    // marketplace "become a seller" entry point), so that button no longer
    // exists anywhere in the app and the section was removed rather than
    // left tapping dead UI. The underlying routing behavior it exercised
    // (`AuthController._navigateByRole` falling back to buyer Home for every
    // role, since the seller shell moved to the standalone POS app in Phase
    // 3) is unrelated to this deletion and still holds — it just has no
    // reachable UI entry point left in this app to test from.
  });
}
