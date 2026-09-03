import 'package:book_store_app/app/components/custom_app_snack_bar.dart';
import 'package:book_store_app/app/data/models/common_models/user_model.dart';
import 'package:book_store_app/app/data/repositories/auth_repository.dart';
import 'package:book_store_app/app/data/repositories/cart_repository.dart';
import 'package:book_store_app/app/data/services/auth_gate_service.dart';
import 'package:book_store_app/app/data/services/current_store_service.dart';
import 'package:book_store_app/app/data/services/social_auth_service.dart';
import 'package:book_store_app/app/modules/cart/controllers/cart_controller.dart';
import 'package:book_store_app/app/modules/profile/controllers/profile_controller.dart';
import 'package:book_store_app/app/routes/app_pages.dart';
import 'package:book_store_app/core/base/base_controller.dart';
import 'package:book_store_app/shared_prefrences/app_prefrences.dart';
import 'package:book_store_app/utils/toast_util.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Google Sign-In and email/password are the two ways to log in or sign up.
/// A first-time Google sign-in creates the account server-side; a returning
/// one logs in. Email/password signup requires an OTP verification step
/// (see [verifyOtpCode]) before the account can log in.
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
  final RxBool isEmailLoading = false.obs;
  final RxBool isOtpLoading = false.obs;
  final RxBool isForgotPasswordLoading = false.obs;
  final RxBool isResetPasswordLoading = false.obs;

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

      // 0. Resolve this build's own store first — the account created/found
      // by socialLogin must be scoped to it (see SocialLoginModel.storeId),
      // never the legacy apex-wide account. ensureResolved() is idempotent,
      // so this is a no-op if Home/main.dart already resolved it.
      final currentStore = Get.find<CurrentStoreService>();
      await currentStore.ensureResolved();

      // 1. Get Google credentials
      final dto = await _socialAuth.signInWithGoogle(storeId: currentStore.storeId);
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

  // ─────────────────────────────────────────
  // EMAIL / PASSWORD
  // ─────────────────────────────────────────

  Future<void> registerWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    if (isEmailLoading.value) return;
    try {
      isEmailLoading.value = true;
      final currentStore = Get.find<CurrentStoreService>();
      await currentStore.ensureResolved();

      final sent = await _authRepository.signup(
        name: name,
        email: email,
        password: password,
        storeId: currentStore.storeId,
      );
      if (!sent) return;

      _showSuccess('We sent a verification code to $email');
      Get.toNamed(Routes.otpVerification, arguments: {'email': email});
    } finally {
      isEmailLoading.value = false;
    }
  }

  Future<void> loginWithEmail({
    required String email,
    required String password,
  }) async {
    if (isEmailLoading.value) return;
    try {
      isEmailLoading.value = true;
      final currentStore = Get.find<CurrentStoreService>();
      await currentStore.ensureResolved();

      final auth = await _authRepository.login(
        email: email,
        password: password,
        storeId: currentStore.storeId,
      );
      if (auth == null) return; // error already surfaced by the repository

      currentUser.value = auth.user;
      await _navigateByRole(auth.user.role);
      _showSuccess('Welcome back, ${auth.user.name}!');
    } on AccountNotVerifiedException catch (e) {
      CustomAppSnackbar.warning('Please verify your email first — we sent you a new code.');
      await resendOtpCode(email: e.email);
      Get.toNamed(Routes.otpVerification, arguments: {'email': e.email});
    } finally {
      isEmailLoading.value = false;
    }
  }

  /// Verifies a signup OTP. The backend logs the account in as part of this
  /// call, so success here goes straight into the app like any other login.
  Future<void> verifyOtpCode({required String email, required String otp}) async {
    if (isOtpLoading.value) return;
    try {
      isOtpLoading.value = true;
      final currentStore = Get.find<CurrentStoreService>();
      await currentStore.ensureResolved();

      final auth = await _authRepository.verifyOtp(
        email: email,
        otp: otp,
        storeId: currentStore.storeId,
      );
      if (auth == null) return;

      currentUser.value = auth.user;
      await _navigateByRole(auth.user.role);
      _showSuccess('Account verified — welcome, ${auth.user.name}!');
    } finally {
      isOtpLoading.value = false;
    }
  }

  /// Returns true on success so callers (e.g. a resend-countdown button) can
  /// restart their own cooldown only when a new code actually went out.
  Future<bool> resendOtpCode({required String email}) async {
    final currentStore = Get.find<CurrentStoreService>();
    await currentStore.ensureResolved();
    return _authRepository.resendOtp(email: email, storeId: currentStore.storeId);
  }

  Future<void> sendForgotPasswordOtp({required String email}) async {
    if (isForgotPasswordLoading.value) return;
    try {
      isForgotPasswordLoading.value = true;
      final currentStore = Get.find<CurrentStoreService>();
      await currentStore.ensureResolved();

      final sent = await _authRepository.forgotPassword(
        email: email,
        storeId: currentStore.storeId,
      );
      if (!sent) return;

      _showSuccess('If an account exists for $email, a reset code is on its way.');
      Get.toNamed(Routes.resetPassword, arguments: {'email': email});
    } finally {
      isForgotPasswordLoading.value = false;
    }
  }

  Future<void> resetPasswordWithOtp({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    if (isResetPasswordLoading.value) return;
    try {
      isResetPasswordLoading.value = true;
      final currentStore = Get.find<CurrentStoreService>();
      await currentStore.ensureResolved();

      final success = await _authRepository.resetPassword(
        email: email,
        otp: otp,
        newPassword: newPassword,
        storeId: currentStore.storeId,
      );
      if (!success) return;

      _showSuccess('Password reset — please log in with your new password.');
      // Clears the whole Forgot-/Reset-Password stack, not just this screen,
      // so back navigation can't land on a stale reset-password form.
      Get.offAllNamed(Routes.authTabView);
    } finally {
      isResetPasswordLoading.value = false;
    }
  }

  /// Logout user
  Future<void> logout() async {
    // Clear user data
    currentUser.value = null;
    // Same permanent-singleton issue as the login path (see _navigateByRole)
    // — ProfileController survives this navigation, so without clearing it
    // directly here the previous user's name/avatar would keep showing on
    // Home/Profile for whoever uses this device next, until an app restart.
    if (Get.isRegistered<ProfileController>()) {
      Get.find<ProfileController>().user.value = null;
    }

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

    // ProfileController is a permanent singleton, usually already alive from
    // when Home first built its guest-mode greeting header — it loaded once
    // with no token and never re-checks, so without this it keeps showing
    // "Guest" (and stale profile data) until the app process restarts.
    if (Get.isRegistered<ProfileController>()) {
      await Get.find<ProfileController>().refreshProfile();
    }

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
