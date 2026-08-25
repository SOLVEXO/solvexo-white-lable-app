import 'package:book_store_app/app/components/custom_app_snack_bar.dart';
import 'package:book_store_app/app/data/models/common_models/user_model.dart';
import 'package:book_store_app/app/data/repositories/auth_repository.dart';
import 'package:book_store_app/app/data/repositories/cart_repository.dart';
import 'package:book_store_app/app/data/services/auth_gate_service.dart';
import 'package:book_store_app/app/data/services/social_auth_service.dart';
import 'package:book_store_app/app/modules/cart/controllers/cart_controller.dart';
import 'package:book_store_app/app/routes/app_pages.dart';
import 'package:book_store_app/core/base/base_controller.dart';
import 'package:book_store_app/shared_prefrences/app_prefrences.dart';
import 'package:book_store_app/utils/toast_util.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Google Sign-In is the only way to log in or sign up — see Phase 10 of
/// the white-label conversion. A first-time Google sign-in creates the
/// account server-side; a returning one logs in. There is no separate
/// email/password, Facebook, or Apple path any more.
class AuthController extends BaseController {
  AuthController({
    AuthRepository? authRepository,
    SocialAuthService? socialAuthService,
  }) : _authRepository = authRepository ?? AuthRepository(),
       _socialAuth = socialAuthService ?? SocialAuthService();

  final AuthRepository _authRepository;
  final SocialAuthService _socialAuth;
  // Observables
  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);
  final RxBool isSocialLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    checkAuthStatus();
  }

  /// Check if user is already logged in
  Future<void> checkAuthStatus() async {
    try {
      final token = await AppPreferences.getAccessTokenAsync();
      if (token == null || token.isEmpty) return;

      final user = await _authRepository.getMe(token: token);
      if (user != null) {
        currentUser.value = user;
      }
    } catch (e) {
      debugPrint('Auth status check error: $e');
    }
  }

  Future<void> signInWithGoogle() async {
    if (isSocialLoading.value) return;
    try {
      isSocialLoading.value = true;

      // 1. Get Google credentials
      final dto = await _socialAuth.signInWithGoogle();
      if (dto == null) {
        // User cancelled
        return;
      }

      // 2. Send to backend — AuthRepository.socialLogin persists tokens/user itself
      final auth = await _authRepository.socialLogin(dto);

      if (auth == null) {
        _showError('Google sign in failed. Please try again.');
        return;
      }

      currentUser.value = auth.user;
      await _navigateByRole(auth.user.role);
      _showSuccess('Welcome ${auth.user.name}!');
    } catch (e) {
      debugPrint('❌ Google sign in error: $e');
      _showError('Google sign in failed: ${e.toString()}');
    } finally {
      isSocialLoading.value = false;
    }
  }

  /// Logout user
  Future<void> logout() async {
    // Clear user data
    currentUser.value = null;

    _authRepository.logout();
    // Logout returns to guest-mode Home, not a login wall.
    Get.offAllNamed(Routes.mainHome);
    ToastUtil.showToast('Logged out successfully');
  }

  /// Get user profile
  Future<void> getUserProfile() async {
    final token = await AppPreferences.getAccessTokenAsync();
    if (token == null || token.isEmpty) return;

    final user = await _authRepository.getUserProfile(token: token);
    if (user != null) {
      currentUser.value = user;
    }
  }
  // ─────────────────────────────────────────
  // UI HELPERS
  // ─────────────────────────────────────────

  Future<void> _navigateByRole(String role) async {
    // Buyer login/signup only — a seller account has no guest cart to merge.
    if (role != 'seller') await _mergeGuestCartAndRefresh();

    // This login/social-login was opened to resume a protected guest action
    // (wishlist, message seller, ...) — pop back to where the guard was
    // triggered and let that awaiting call resume, instead of navigating.
    if (AuthGateService.instance.isAwaitingResume) {
      AuthGateService.instance.resolveSuccess();
      return;
    }
    // Seller stores/onboarding now live only in the standalone POS app
    // (Phase 3) — this buyer app has no seller flow to send a 'seller'
    // login into, so every role falls back to the buyer guest home.
    Get.offAllNamed(Routes.mainHome);
  }

  /// Folds any locally-held guest cart into the now-logged-in buyer's
  /// account cart (summing quantities on conflict — see
  /// `CartRepository.mergeGuestCartIntoAccount`), then refreshes the shared
  /// `CartController` so the badge/cart screen reflect it immediately.
  Future<void> _mergeGuestCartAndRefresh() async {
    await CartRepository().mergeGuestCartIntoAccount();
    if (Get.isRegistered<CartController>()) {
      await Get.find<CartController>().refreshCart();
    }
  }

  void _showSuccess(String message) {
    CustomAppSnackbar.success(message);
  }

  void _showError(String message) {
    CustomAppSnackbar.error(message);
  }

  /// Check if user is logged in
  bool get isLoggedIn => currentUser.value != null;

  /// Get user name
  String get userName => currentUser.value?.name ?? 'Guest';

  /// Get user email
  String get userEmail => currentUser.value?.email ?? '';
}
