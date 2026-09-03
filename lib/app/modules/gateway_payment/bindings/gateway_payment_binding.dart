import 'package:book_store_app/app/modules/gateway_payment/controllers/gateway_payment_controller.dart';
import 'package:get/get.dart';

class GatewayPaymentBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<GatewayPaymentController>(() => GatewayPaymentController());
  }
}
