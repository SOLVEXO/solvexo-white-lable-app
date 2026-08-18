import 'package:book_store_app/app/routes/app_pages.dart';
import 'package:book_store_app/shared_prefrences/app_prefrences.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Protects any route that requires authentication.
/// If token is missing or cleared → redirects to authTabView.
class AuthMiddleware extends GetMiddleware {
  @override
  int? get priority => 1;

  @override
  RouteSettings? redirect(String? route) {
    // This is called synchronously — we use a cached/sync check here.
    // The async token check happens in onPageCalled below.
    return null;
  }

  @override
  GetPage? onPageCalled(GetPage? page) {
    _checkAuth();
    return page;
  }

  Future<void> _checkAuth() async {
    final token = await AppPreferences.getAccessTokenAsync();
    if (token == null || token.isEmpty) {
      await AppPreferences.clearTokens();
      Get.offAllNamed(Routes.authTabView);
    }
  }
}

/// Extends AuthMiddleware to also verify the user's role matches
/// the expected role for this section (seller / pos / user).
class RoleMiddleware extends GetMiddleware {
  final String expectedRole;

  RoleMiddleware(this.expectedRole);

  @override
  int? get priority => 1;

  @override
  GetPage? onPageCalled(GetPage? page) {
    _checkRoleAuth();
    return page;
  }

  Future<void> _checkRoleAuth() async {
    final token = await AppPreferences.getAccessTokenAsync();

    // No token → kick to auth
    if (token == null || token.isEmpty) {
      await AppPreferences.clearTokens();
      Get.offAllNamed(Routes.authTabView);
      return;
    }

    // Wrong role → redirect to correct home
    final role = await AppPreferences.getUserRole();
    if (role != expectedRole) {
      _navigateByRole(role);
    }
  }

  void _navigateByRole(String? role) {
    // Seller/POS accounts now live in the standalone POS app (Phase 3) —
    // this buyer app has no seller dashboard or POS terminal to send them
    // to, so every role (including 'seller'/'pos') falls back to the buyer
    // guest home.
    Get.offAllNamed(Routes.mainHome);
  }
}

/// Guards the POS terminal screens. Every POS backend endpoint requires the
/// store owner's own `seller` JWT — there is no separate "pos" account role,
/// so (unlike [RoleMiddleware]) this checks for `role == 'seller'`.
///
/// [requireActiveSession] additionally requires a PIN-logged-in employee with
/// an open register session (tracked locally via [AppPreferences] POS keys).
/// Use this on the POS terminal shell and its tabs; leave it false for the
/// PIN-login and open-register screens themselves, which establish that
/// session in the first place.
class PosAccessMiddleware extends GetMiddleware {
  final bool requireActiveSession;

  PosAccessMiddleware({this.requireActiveSession = false});

  @override
  int? get priority => 1;

  @override
  GetPage? onPageCalled(GetPage? page) {
    _check();
    return page;
  }

  Future<void> _check() async {
    final token = await AppPreferences.getAccessTokenAsync();
    if (token == null || token.isEmpty) {
      await AppPreferences.clearTokens();
      Get.offAllNamed(Routes.authTabView);
      return;
    }

    final role = await AppPreferences.getUserRole();
    if (role != 'seller') {
      Get.offAllNamed(Routes.mainHome);
      return;
    }

    if (requireActiveSession && !await AppPreferences.hasPosSession()) {
      // The POS PIN-login screen lives only in the standalone POS app
      // (Phase 3) — this middleware is shared/generic (imported by that
      // app via the book_store_app path dependency) so it can't reference
      // a `Routes.posPinLogin` constant from this app's own route table.
      // Use the literal path instead; the POS app registers this same
      // route string itself.
      Get.offAllNamed('/pos/pin-login');
    }
  }
}
