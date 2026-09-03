import 'package:book_store_app/app/modules/auth/controller/auth_controller.dart';
import 'package:book_store_app/app/modules/otp_verification/controllers/otp_verification_controller.dart';
import 'package:get/get.dart';

class OtpVerificationBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AuthController>(() => AuthController());
    Get.lazyPut<OtpVerificationController>(() => OtpVerificationController());
  }
}
