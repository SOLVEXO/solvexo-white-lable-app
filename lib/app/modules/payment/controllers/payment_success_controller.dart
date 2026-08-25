import 'package:book_store_app/app/modules/myorders/controllers/my_orders_controller.dart';
import 'package:book_store_app/app/modules/myorders/views/order_tracking_view.dart';
import 'package:book_store_app/app/modules/payment/models/payment_success_args.dart';
import 'package:book_store_app/app/routes/app_pages.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

class PaymentSuccessController extends GetxController {
  late final ConfettiController confettiController;

  List<String> orderIds = const [];
  double? codAmountDue;
  String currency = 'PKR';

  bool get hasOrders => orderIds.isNotEmpty;
  bool get isSingleOrder => orderIds.length == 1;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is PaymentSuccessArgs) {
      orderIds = args.orderIds;
      codAmountDue = args.codAmountDue;
      currency = args.currency;
    }
    confettiController = ConfettiController(duration: const Duration(seconds: 2));
    confettiController.play();
  }

  @override
  void onClose() {
    confettiController.dispose();
    super.onClose();
  }

  void continueShopping() => Get.offAllNamed(Routes.mainHome);

  /// Deep-links straight into the order just placed when there's exactly
  /// one (single-seller checkout); otherwise drops the buyer on the My
  /// Orders list — there's no single order to jump to, and no "combined
  /// order" screen for a multi-seller cart.
  Future<void> viewOrderDetails() async {
    if (!Get.isRegistered<MyOrdersController>()) Get.put(MyOrdersController());
    final myOrdersController = Get.find<MyOrdersController>();

    await myOrdersController.fetchOrders();
    myOrdersController.selectedTab.value = 0;
    myOrdersController.searchQuery.value = '';
    myOrdersController.searchController.clear();

    final index = isSingleOrder
        ? myOrdersController.filteredOrders.indexWhere((o) => o.orderId == orderIds.first)
        : -1;

    // Home sits underneath so the back arrow from order tracking / my-orders
    // lands somewhere sensible — but it must actually finish mounting (which
    // is what registers HomeController via HomeBinding's guard) before we
    // stack another route on top of it, otherwise Home's own tab widgets
    // (ProductCard etc., still built on HomeController) crash with a
    // "controller not found" the first time the user navigates back into it.
    Get.offAllNamed(Routes.mainHome);
    await WidgetsBinding.instance.endOfFrame;
    if (index != -1) {
      Get.to(() => OrderTrackingView(index: index));
    } else {
      Get.toNamed(Routes.myOrdersView);
    }
  }
}
