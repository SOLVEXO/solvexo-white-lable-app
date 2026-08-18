import 'package:book_store_app/app/data/repositories/auth_repository.dart';
import 'package:book_store_app/utils/toast_util.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:solvexo_pos/app/routes/app_pages.dart';

/// Login for the standalone POS app. Sellers authenticate with their
/// existing store-owner email/password (same account used on the buyer
/// app's seller signup) — there's no separate "pos" account role, the
/// backend just expects `role: 'seller'`.
///
/// Deliberately does NOT reuse the buyer app's `auth`/`login`/`otp` modules
/// (guest cart merge, guest-action-resume guard, buyer signup flow) — none
/// of that applies here.
class PosLoginController extends GetxController {
  final AuthRepository _authRepository = AuthRepository();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final RxBool isLoading = false.obs;
  final RxBool obscurePassword = true.obs;

  void toggleObscurePassword() => obscurePassword.value = !obscurePassword.value;

  Future<void> login() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ToastUtil.showToast('Please enter your email and password');
      return;
    }

    isLoading.value = true;
    final authResponse = await _authRepository.login(
      email: email,
      password: password,
      role: 'seller',
    );
    isLoading.value = false;

    if (authResponse == null) {
      // AuthRepository already surfaced its own error toast.
      return;
    }

    if (authResponse.user.role != 'seller') {
      ToastUtil.showToast("This account isn't a seller account");
      return;
    }

    Get.offAllNamed(Routes.sellerStores);
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
