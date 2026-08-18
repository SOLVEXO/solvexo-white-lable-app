import 'dart:async';

import 'package:book_store_app/shared_prefrences/app_prefrences.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:book_store_app/app/data/repositories/auth_repository.dart';
import 'package:book_store_app/app/data/repositories/cart_repository.dart';
import 'package:book_store_app/app/data/services/auth_gate_service.dart';
import 'package:book_store_app/app/modules/auth/controller/auth_controller.dart';
import 'package:book_store_app/app/modules/cart/controllers/cart_controller.dart';
import 'package:book_store_app/app/routes/app_pages.dart';
import 'package:book_store_app/core/base/base_controller.dart';
import 'package:book_store_app/utils/toast_util.dart';

class OtpController extends BaseController {
  OtpController({
    AuthRepository? authRepository,
    CartRepository? cartRepository,
    String? otpType,
    String? email,
  }) : _authRepository = authRepository ?? AuthRepository(),
       _cartRepository = cartRepository ?? CartRepository(),
       otpType = otpType ?? _readArg('type'),
       email = email ?? _readArg('email');

  static String _readArg(String key) {
    final args = Get.arguments;
    if (args is Map) return args[key] ?? '';
    return '';
  }

  final AuthRepository _authRepository;
  final CartRepository _cartRepository;

  AuthController get _authController {
    if (!Get.isRegistered<AuthController>()) Get.put(AuthController());
    return Get.find<AuthController>();
  }

  final int otpLength = 6;

  // Single controller — `PinCodeTextField` manages the individual boxes
  // itself (and, critically, correctly splits a pasted 6-digit code across
  // all of them; the old per-box `TextField` row truncated pasted text to
  // 1 character via `maxLength: 1` before `onChanged` ever saw it).
  final TextEditingController otpTextController = TextEditingController();

  // Drives the package's built-in shake + error-border animation — replaces
  // the hand-rolled `AnimationController`/`Transform.translate` that used
  // to live in the view.
  final StreamController<ErrorAnimationType> errorController =
      StreamController<ErrorAnimationType>.broadcast();

  RxBool resendAvailable = false.obs;
  RxInt timerSec = 60.obs;
  RxBool isResending = false.obs;
  RxString errorText = ''.obs;
  @override
  RxBool isLoading = false.obs;

  final String otpType;
  final String email;

  @override
  void onInit() {
    super.onInit();
    startTimer();
  }

  // ================= TIMER =================

  void startTimer() async {
    resendAvailable.value = false;
    timerSec.value = 60;

    for (int i = 60; i > 0; i--) {
      await Future.delayed(const Duration(seconds: 1));
      timerSec.value = i - 1;
    }

    resendAvailable.value = true;
  }

  // ================= OTP HELPERS =================

  String get otpCode => otpTextController.text;

  void clearOtp() => otpTextController.clear();

  /// Clears the inline error the moment the user starts correcting the code.
  void onOtpChanged(String value) {
    if (errorText.value.isNotEmpty) errorText.value = '';
  }

  /// Only offer pin_code_fields' built-in "paste this code?" dialog for a
  /// clipboard value that actually looks like an OTP.
  bool canPasteText(String? text) {
    if (text == null) return false;
    final trimmed = text.trim();
    return trimmed.length == otpLength && int.tryParse(trimmed) != null;
  }

  // ================= VERIFY OTP =================

  /// [completedCode] is passed by `PinCodeTextField.onCompleted` — using it
  /// directly avoids a race where `otpTextController.text` hasn't caught up
  /// yet when the last digit lands.
  Future<void> submitOtp([String? completedCode]) async {
    final code = completedCode ?? otpCode;
    if (code.length != otpLength) {
      ToastUtil.showToast("Please enter all 6 digits");
      return;
    }

    isLoading.value = true;

    if (otpType == "verify_email") {
      final intentRole = await AppPreferences.getIntentRole();

      final auth = await _authRepository.verifyEmailOtp(
        email: email,
        otp: code,
        role: intentRole ?? 'user',
      );

      isLoading.value = false;

      if (auth == null) {
        errorText.value = 'Incorrect code. Please try again.';
        errorController.add(ErrorAnimationType.shake);
        clearOtp();
        return;
      }

      await AppPreferences.clearIntentRole();

      // Attach any profile photo picked during signup now that real tokens
      // exist. Never blocks navigation below if it fails.
      await _authController.finishProfileSetupAfterVerification(auth);

      // Buyer signup only — a seller account has no guest cart to merge.
      if (intentRole != 'seller') {
        await _cartRepository.mergeGuestCartIntoAccount();
        if (Get.isRegistered<CartController>()) {
          await Get.find<CartController>().refreshCart();
        }
      }

      if (AuthGateService.instance.isAwaitingResume) {
        // This signup was opened to resume a protected guest action — pop
        // back to where the guard fired instead of navigating away.
        AuthGateService.instance.resolveSuccess();
      } else if (intentRole == 'seller') {
        // Seller onboarding now lives only in the standalone POS app
        // (Phase 3) — this buyer app has nowhere to send a fresh seller
        // signup, so fall back to the buyer guest home.
        Get.offAllNamed(Routes.mainHome);
      } else {
        Get.offAllNamed(Routes.mainHome);
      }
    } else if (otpType == "password_reset") {
      // OTP is verified at the reset-password step by the backend
      isLoading.value = false;
      Get.toNamed(
        Routes.newPasswordView,
        arguments: {"email": email, "otp": code},
      );
    }
  }

  // ================= RESEND =================

  Future<void> resendCode() async {
    if (!resendAvailable.value || isResending.value) return;

    isResending.value = true;
    final intentRole = await AppPreferences.getIntentRole();
    final ok = await _authRepository.resendVerificationOtp(
      email,
      role: intentRole ?? 'user',
    );
    isResending.value = false;

    if (ok) {
      ToastUtil.showToast("OTP sent again");
      errorText.value = '';
      clearOtp();
      startTimer();
    } else {
      ToastUtil.showToast("Failed to resend OTP");
    }
  }

  @override
  void onClose() {
    otpTextController.dispose();
    errorController.close();
    super.onClose();
  }
}
