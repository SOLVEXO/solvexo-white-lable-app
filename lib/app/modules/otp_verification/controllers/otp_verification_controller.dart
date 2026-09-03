import 'dart:async';

import 'package:book_store_app/app/components/custom_app_snack_bar.dart';
import 'package:book_store_app/app/modules/auth/controller/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Backs the post-signup OTP screen. The email/password login flow
/// (`AuthController.loginWithEmail`) also lands here when the account
/// exists but hasn't verified yet.
class OtpVerificationController extends GetxController {
  late final String email;

  final TextEditingController otpController = TextEditingController();
  final RxString otp = ''.obs;
  final RxInt secondsUntilResend = 30.obs;
  Timer? _resendTimer;

  AuthController get _auth => Get.find<AuthController>();
  RxBool get isVerifying => _auth.isOtpLoading;
  bool get canResend => secondsUntilResend.value == 0;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>?;
    email = args?['email'] as String? ?? '';
    _startResendCooldown();
  }

  @override
  void onClose() {
    _resendTimer?.cancel();
    otpController.dispose();
    super.onClose();
  }

  void _startResendCooldown() {
    secondsUntilResend.value = 30;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (secondsUntilResend.value <= 1) {
        timer.cancel();
        secondsUntilResend.value = 0;
      } else {
        secondsUntilResend.value--;
      }
    });
  }

  Future<void> submit() async {
    if (otp.value.trim().length != 6) {
      CustomAppSnackbar.warning('Enter the 6-digit code sent to your email');
      return;
    }
    await _auth.verifyOtpCode(email: email, otp: otp.value.trim());
  }

  Future<void> resend() async {
    if (!canResend) return;
    final sent = await _auth.resendOtpCode(email: email);
    if (sent) _startResendCooldown();
  }
}
