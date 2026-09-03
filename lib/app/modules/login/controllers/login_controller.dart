import 'package:book_store_app/app/modules/auth/controller/auth_controller.dart';
import 'package:book_store_app/app/routes/app_pages.dart';
import 'package:book_store_app/utils/field_validation_util.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Local form state for the merged Login/Sign-up screen — the actual auth
/// calls and post-success navigation live on [AuthController], shared with
/// Google Sign-In and every other auth-adjacent screen.
class LoginController extends GetxController {
  final formKey = GlobalKey<FormState>();

  final RxBool isSignUpMode = false.obs;
  final RxBool obscurePassword = true.obs;
  final RxBool obscureConfirmPassword = true.obs;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  AuthController get auth => Get.find<AuthController>();

  void toggleMode() {
    isSignUpMode.toggle();
    formKey.currentState?.reset();
  }

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }

  String? validateName(String? value) {
    if (!isSignUpMode.value) return null;
    return FieldValidationUtil.validateValue(value ?? '', 'Name');
  }

  String? validateEmail(String? value) => FieldValidationUtil.emailValidate(value ?? '');

  String? validatePassword(String? value) {
    if (!isSignUpMode.value) {
      return (value == null || value.isEmpty) ? 'Password is required' : null;
    }
    return FieldValidationUtil.passwordValidateStrong(value ?? '');
  }

  String? validateConfirmPassword(String? value) {
    if (!isSignUpMode.value) return null;
    return FieldValidationUtil.confirmPasswordValidate(value ?? '', passwordController.text);
  }

  Future<void> submit() async {
    if (formKey.currentState?.validate() != true) return;

    if (isSignUpMode.value) {
      await auth.registerWithEmail(
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        password: passwordController.text,
      );
    } else {
      await auth.loginWithEmail(
        email: emailController.text.trim(),
        password: passwordController.text,
      );
    }
  }

  void goToForgotPassword() => Get.toNamed(Routes.forgotPassword);
}
