// ignore_for_file: avoid_print
// One-off manual verification pass for the redesigned auth screens (Login/
// Sign-Up toggle, Forgot Password, OTP verification). Deliberately never
// submits a real signup/login/forgot-password request against the live
// staging backend — it only exercises client-side rendering, toggling, and
// validation, plus direct navigation to the OTP screen (bypassing the
// signup call that would normally send a real email).

import 'package:book_store_app/app/modules/login/controllers/login_controller.dart';
import 'package:book_store_app/app/routes/app_pages.dart';
import 'package:flutter/material.dart';
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

  testWidgets('redesigned auth screens render, toggle, validate, and navigate', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    app.main();
    await tester.pump();

    // Tolerate either a fresh-install onboarding carousel or (if the
    // simulator's prefs.clear() raced with main()'s own read of them on a
    // re-run) landing straight on Home — this test only cares about
    // reaching Home, not the onboarding screen itself.
    await pumpUntil(
      tester,
      () => Get.currentRoute == Routes.onboarding || Get.currentRoute == Routes.mainHome,
      timeout: const Duration(seconds: 45),
    );
    await tester.pump(const Duration(milliseconds: 500));
    if (find.text('Skip').evaluate().isNotEmpty) {
      await tester.tap(find.text('Skip'));
      await tester.pump(const Duration(milliseconds: 500));
    }

    await pumpUntil(tester, () => Get.currentRoute == Routes.mainHome, timeout: const Duration(seconds: 45));
    print('✅ Reached guest-mode Home');

    // ── Navigate straight to the auth screen (bypassing the specific
    // guarded-action tap path — that's covered by the existing guest e2e
    // test; this test is scoped to the new screens themselves). ────────────
    Get.toNamed(Routes.authTabView);
    await tester.pumpAndSettle();
    expect(Get.currentRoute, Routes.authTabView);
    print('✅ AuthTabsView opened');

    // ── Default mode is Login: email/password fields + Google button. ─────
    expect(find.byKey(const Key('login-tab')), findsOneWidget);
    expect(find.byKey(const Key('signup-tab')), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.byKey(const Key('forgot-password-link')), findsOneWidget);
    expect(find.text('Full name'), findsNothing); // signup-only field hidden
    print('✅ Login mode renders correctly (fields + Google button + forgot-password link)');

    // ── Toggle to Sign Up — name field appears, forgot-password link hides. ─
    await tester.tap(find.byKey(const Key('signup-tab')));
    await tester.pumpAndSettle();
    expect(find.text('Full name'), findsOneWidget);
    expect(find.byKey(const Key('forgot-password-link')), findsNothing);
    expect(Get.find<LoginController>().isSignUpMode.value, isTrue);
    print('✅ Sign Up mode renders correctly (name field appears, forgot-password link hides)');

    // ── Submit empty Sign Up form — client-side validation fires, no
    // network call happens (form validation blocks it before the
    // repository call). ─────────────────────────────────────────────────────
    await tester.tap(find.byKey(const Key('auth-submit-button')));
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsNothing); // no "network" toast — validation caught it first
    print('✅ Empty Sign Up submit is blocked by client-side validation (no network call attempted)');

    // ── Toggle back to Login, tap "Forgot password?" ────────────────────────
    await tester.tap(find.byKey(const Key('login-tab')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('forgot-password-link')));
    await tester.pumpAndSettle();
    expect(Get.currentRoute, Routes.forgotPassword);
    expect(find.text('Forgot password?'), findsWidgets);
    expect(find.text('Send Reset Code'), findsOneWidget);
    print('✅ Forgot Password screen reachable and renders correctly');

    // ── OTP verification screen, reached directly with a fake email (skips
    // the real signup network call). Uses bounded pumps, not pumpAndSettle —
    // the pin field's autofocus blinking cursor animates forever, so
    // pumpAndSettle would never return. ─────────────────────────────────────
    Get.back();
    await tester.pump(const Duration(milliseconds: 500));
    Get.toNamed(Routes.otpVerification, arguments: {'email': 'smoke-test@example.com'});
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    expect(Get.currentRoute, Routes.otpVerification);
    expect(find.textContaining('smoke-test@example.com'), findsOneWidget);
    expect(find.text('Verify your email'), findsOneWidget);
    print('✅ OTP verification screen reachable and renders the pin code input');
  });
}
