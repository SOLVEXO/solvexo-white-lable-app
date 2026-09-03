import 'package:book_store_app/app/modules/auth/controller/auth_controller.dart';
import 'package:book_store_app/utils/field_validation_util.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ForgotPasswordController extends GetxController {
  final formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();

  AuthController get _auth => Get.find<AuthController>();
  RxBool get isLoading => _auth.isForgotPasswordLoading;

  @override
  void onClose() {
    emailController.dispose();
    super.onClose();
  }

  String? validateEmail(String? value) => FieldValidationUtil.emailValidate(value ?? '');

  Future<void> submit() async {
    if (formKey.currentState?.validate() != true) return;
    await _auth.sendForgotPasswordOtp(email: emailController.text.trim());
  }
}
