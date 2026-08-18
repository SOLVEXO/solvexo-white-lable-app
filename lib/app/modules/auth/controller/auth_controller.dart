import 'dart:io';

import 'package:book_store_app/app/components/custom_app_snack_bar.dart';
import 'package:book_store_app/app/data/models/common_models/auth_response_model.dart';
import 'package:book_store_app/app/data/models/common_models/user_model.dart';
import 'package:book_store_app/app/data/repositories/auth_repository.dart';
import 'package:book_store_app/app/data/repositories/cart_repository.dart';
import 'package:book_store_app/app/data/repositories/upload_repository.dart';
import 'package:book_store_app/app/data/services/auth_gate_service.dart';
import 'package:book_store_app/app/data/services/social_auth_service.dart';
import 'package:book_store_app/app/modules/cart/controllers/cart_controller.dart';
import 'package:book_store_app/app/routes/app_pages.dart';
import 'package:book_store_app/core/base/base_controller.dart';
import 'package:book_store_app/shared_prefrences/app_prefrences.dart';
import 'package:book_store_app/utils/toast_util.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class AuthController extends BaseController {
  AuthController({
    AuthRepository? authRepository,
    UploadRepository? uploadRepository,
    SocialAuthService? socialAuthService,
  }) : _authRepository = authRepository ?? AuthRepository(),
       _uploadRepository = uploadRepository ?? UploadRepository(),
       _socialAuth = socialAuthService ?? SocialAuthService();

  final AuthRepository _authRepository;
  final UploadRepository _uploadRepository;
  final SocialAuthService _socialAuth;
  // Observables
  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);
  @override
  final RxBool isLoading = false.obs;
  final RxBool isSocialLoading = false.obs;
  // Which provider's button should show its own spinner — the other two
  // stay disabled but plain, rather than all three animating identically.
  final RxString activeSocialProvider = ''.obs;
  final RxBool isPasswordVisible = false.obs;
  final RxBool isConfirmPasswordVisible = false.obs;
  // Text Controllers for Login
  final TextEditingController loginEmailController = TextEditingController();
  final TextEditingController loginPasswordController = TextEditingController();
  // Text Controllers for Register
  final TextEditingController registerEmailController = TextEditingController();
  final TextEditingController registerFirstNameController =
      TextEditingController();
  final TextEditingController registerLastNameController =
      TextEditingController();
  final TextEditingController registerPhoneController = TextEditingController();
  final TextEditingController registerAddressController =
      TextEditingController();
  final TextEditingController registerPasswordController =
      TextEditingController();
  final TextEditingController registerConfirmPasswordController =
      TextEditingController();

  // Profile photo picked at signup time — the upload endpoint requires a
  // bearer token the user doesn't have yet at this point (registration is
  // OTP-gated), so this is only uploaded once OTP verification hands back
  // real tokens (see `finishProfileSetupAfterVerification`).
  final Rx<File?> registerProfileImage = Rx<File?>(null);
  final RxBool isPickingRegisterImage = false.obs;

  // Form Keys
  final GlobalKey<FormState> loginFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> registerFormKey = GlobalKey<FormState>();

  @override
  void onInit() {
    super.onInit();
    checkAuthStatus();
  }

  @override
  void onClose() {
    loginEmailController.dispose();
    loginPasswordController.dispose();
    registerEmailController.dispose();
    registerFirstNameController.dispose();
    registerLastNameController.dispose();
    registerPhoneController.dispose();
    registerAddressController.dispose();
    registerPasswordController.dispose();
    registerConfirmPasswordController.dispose();
    super.onClose();
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

  /// Toggle password visibility
  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  /// Toggle confirm password visibility
  void toggleConfirmPasswordVisibility() {
    isConfirmPasswordVisible.value = !isConfirmPasswordVisible.value;
  }

  /// Validate email
  @override
  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email';
    }

    return null;
  }

  /// Validate password
  @override
  String? validatePassword(String? value, {int minLength = 6}) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }

    if (value.length < minLength) {
      return 'Password must be at least $minLength characters';
    }

    return null;
  }

  /// Validate confirm password
  String? validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }

    if (value != registerPasswordController.text) {
      return 'Passwords do not match';
    }

    return null;
  }

  /// Validate name
  String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your name';
    }

    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }

    return null;
  }

  /// Validate phone (optional but if filled must be valid)
  String? validatePhone(String? value) {
    if (value != null && value.isNotEmpty) {
      // Remove any spaces or dashes
      String cleanedValue = value.replaceAll(RegExp(r'[\s\-]'), '');
      if (cleanedValue.length < 10) {
        return 'Please enter a valid phone number';
      }
    }
    return null;
  }

  Future<void> signInWithGoogle() async {
    if (isSocialLoading.value) return;
    try {
      isSocialLoading.value = true;
      activeSocialProvider.value = 'google';

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

      await _navigateByRole(auth.user.role);
      _showSuccess('Welcome ${auth.user.name}!');
    } catch (e) {
      debugPrint('❌ Google sign in error: $e');
      _showError('Google sign in failed: ${e.toString()}');
    } finally {
      isSocialLoading.value = false;
      activeSocialProvider.value = '';
    }
  }

  Future<void> signInWithFacebook() async {
    if (isSocialLoading.value) return;
    try {
      isSocialLoading.value = true;
      activeSocialProvider.value = 'facebook';

      final dto = await _socialAuth.signInWithFacebook();
      if (dto == null) return;

      final auth = await _authRepository.socialLogin(dto);

      if (auth == null) {
        _showError('Facebook sign in failed. Please try again.');
        return;
      }

      await _navigateByRole(auth.user.role);
      _showSuccess('Welcome ${auth.user.name}!');
    } catch (e) {
      debugPrint('❌ Facebook sign in error: $e');
      _showError('Facebook sign in failed: ${e.toString()}');
    } finally {
      isSocialLoading.value = false;
      activeSocialProvider.value = '';
    }
  }

  Future<void> signInWithApple() async {
    if (isSocialLoading.value) return;
    try {
      isSocialLoading.value = true;
      activeSocialProvider.value = 'apple';

      final dto = await _socialAuth.signInWithApple();
      if (dto == null) return;

      final auth = await _authRepository.socialLogin(dto);

      if (auth == null) {
        _showError('Apple sign in failed. Please try again.');
        return;
      }

      await _navigateByRole(auth.user.role);
      _showSuccess('Welcome!');
    } catch (e) {
      debugPrint('❌ Apple sign in error: $e');
      _showError('Apple sign in failed: ${e.toString()}');
    } finally {
      isSocialLoading.value = false;
      activeSocialProvider.value = '';
    }
  }

  /// Register new user
  Future<void> register() async {
    if (!registerFormKey.currentState!.validate()) {
      return;
    }

    isLoading.value = true;

    try {
      // Combine first and last name
      final fullName =
          '${registerFirstNameController.text.trim()} ${registerLastNameController.text.trim()}';
      final role = await AppPreferences.getIntentRole();
      final success = await _authRepository.register(
        name: fullName,
        email: registerEmailController.text.trim().toLowerCase(),
        password: registerPasswordController.text,
        phone: registerPhoneController.text.trim().isNotEmpty
            ? registerPhoneController.text.trim()
            : null,
        address: registerAddressController.text.trim().isNotEmpty
            ? registerAddressController.text.trim()
            : null,
        role: role ?? "user",
      );
      if (success) {
        ToastUtil.showToast("OTP sent to your email");

        Get.toNamed(
          Routes.otpView,
          arguments: {
            'email': registerEmailController.text.trim(),
            'type': 'verify_email',
          },
        );
      }
    } catch (e) {
      debugPrint('Register error: $e');
      ToastUtil.showToast('Registration failed. Please try again.');
    } finally {
      isLoading.value = false;
    }
  }

  /// Login user
  Future<void> login() async {
    if (!loginFormKey.currentState!.validate()) {
      return;
    }

    isLoading.value = true;

    try {
      final role = await AppPreferences.getIntentRole();
      final authResponse = await _authRepository.login(
        email: loginEmailController.text.trim().toLowerCase(),
        password: loginPasswordController.text,
        role: role ?? "user",
      );
      debugPrint("auth response: $authResponse");

      if (authResponse != null) {
        currentUser.value = authResponse.user;
        await AppPreferences.setTokens(
          accessToken: authResponse.token.accessToken,
          refreshToken: authResponse.token.refreshToken,
        );
        await AppPreferences.saveUserData(
          userId: authResponse.user.id,
          name: authResponse.user.name,
          email: authResponse.user.email,
          role: authResponse.user.role,
        );
        ToastUtil.showToast('Login successful!');
        clearLoginForm();
        await _navigateByRole(authResponse.user.role);
        debugPrint('User logged in successfully: ${authResponse.user.email}');
      }
    } catch (e) {
      debugPrint('Login error: $e');
      ToastUtil.showToast('Login failed. Please check your credentials.');
    } finally {
      isLoading.value = false;
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

  /// Clear login form
  void clearLoginForm() {
    loginEmailController.clear();
    loginPasswordController.clear();
    isPasswordVisible.value = false;
  }

  /// Clear register form
  void clearRegisterForm() {
    registerEmailController.clear();
    registerFirstNameController.clear();
    registerLastNameController.clear();
    registerPhoneController.clear();
    registerAddressController.clear();
    registerPasswordController.clear();
    registerConfirmPasswordController.clear();
    registerProfileImage.value = null;
    isPasswordVisible.value = false;
    isConfirmPasswordVisible.value = false;
  }

  /// Pick a profile photo at signup time. Just held locally — see
  /// `registerProfileImage`'s doc comment for why it isn't uploaded yet.
  Future<void> pickRegisterProfileImage() async {
    isPickingRegisterImage.value = true;
    try {
      final file = await _uploadRepository.pickImage(
        source: ImageSource.gallery,
      );
      if (file != null) registerProfileImage.value = file;
    } finally {
      isPickingRegisterImage.value = false;
    }
  }

  /// Called right after OTP verification succeeds (i.e. the moment real
  /// tokens exist) to upload any profile photo picked during signup and
  /// attach it to the now-verified user. Failures here must never block
  /// navigation — signup itself already succeeded.
  Future<void> finishProfileSetupAfterVerification(
    AuthResponseModel auth,
  ) async {
    final file = registerProfileImage.value;
    if (file == null) return;

    try {
      final imageUrl = await _uploadRepository.uploadImage(file);
      if (imageUrl == null) return;

      final updatedUser = await _authRepository.updateProfile(
        token: auth.token.accessToken,
        profileImage: imageUrl,
      );
      if (updatedUser != null) currentUser.value = updatedUser;
    } catch (e) {
      debugPrint('❌ finishProfileSetupAfterVerification error: $e');
    } finally {
      registerProfileImage.value = null;
    }
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
