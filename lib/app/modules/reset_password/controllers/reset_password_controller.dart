import 'package:book_store_app/app/modules/auth/controller/auth_controller.dart';
import 'package:book_store_app/utils/field_validation_util.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ResetPasswordController extends GetxController {
  late final String email;

  final formKey = GlobalKey<FormState>();
  final TextEditingController otpController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  final RxBool obscurePassword = true.obs;
  final RxBool obscureConfirmPassword = true.obs;

  AuthController get _auth => Get.find<AuthController>();
  RxBool get isLoading => _auth.isResetPasswordLoading;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>?;
    email = args?['email'] as String? ?? '';
  }

  @override
  void onClose() {
    otpController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }

  String? validateOtp(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Enter the code we emailed you';
    if (v.length != 6) return 'The code is 6 digits';
    return null;
  }

  String? validatePassword(String? value) => FieldValidationUtil.passwordValidateStrong(value ?? '');

  String? validateConfirmPassword(String? value) =>
      FieldValidationUtil.confirmPasswordValidate(value ?? '', passwordController.text);

  Future<void> submit() async {
    if (formKey.currentState?.validate() != true) return;
    await _auth.resetPasswordWithOtp(
      email: email,
      otp: otpController.text.trim(),
      newPassword: passwordController.text,
    );
  }
}
