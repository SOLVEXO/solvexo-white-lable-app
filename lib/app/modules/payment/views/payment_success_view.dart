import 'package:book_store_app/app/components/custom_text.dart';
import 'package:book_store_app/app/modules/payment/controllers/payment_success_controller.dart';
import 'package:book_store_app/config/resources/app_colors.dart';
import 'package:book_store_app/core/theme/base_animations.dart';
import 'package:book_store_app/core/theme/base_shadows.dart';
import 'package:book_store_app/core/theme/base_spacing.dart';
import 'package:book_store_app/core/widgets/buttons/base_buttons.dart';
import 'package:book_store_app/utils/app_font_size.dart';
import 'package:book_store_app/utils/currency_formatter.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Post-checkout celebration screen — shown identically after COD and
/// online (Stripe) orders since [CheckoutController.onPaymentSuccess] is
/// the single hand-off point for both. Styled as a centered popup card over
/// a confetti burst, with "View Order Details" (when we know which order(s)
/// were created) and "Continue Shopping" as the two ways out.
class PaymentSuccessView extends StatelessWidget {
  PaymentSuccessView({super.key});

  final controller = Get.put(PaymentSuccessController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: controller.confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              numberOfParticles: 24,
              maxBlastForce: 28,
              minBlastForce: 10,
              gravity: 0.25,
              shouldLoop: false,
              colors: [
                AppColors.primaryColor,
                AppColors.seaGreen,
                AppColors.yellow,
                AppColors.orange,
                AppColors.accentColor,
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: BaseSpacing.xl),
              child: Center(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: BaseSpacing.xl,
                    vertical: BaseSpacing.xxl,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(BaseRadius.lg),
                    boxShadow: BaseShadows.forLevel(BaseElevation.level3),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration: BaseMotion.slow,
                        curve: Curves.easeOutBack,
                        builder: (_, value, child) {
                          return Transform.scale(
                            scale: value,
                            child: const Icon(
                              Icons.check_circle,
                              color: AppColors.seaGreen,
                              size: 100,
                            ),
                          );
                        },
                      ),
                      SizedBox(height: BaseSpacing.lg),
                      CustomText(
                        text: "Order Placed Successfully!",
                        color: AppColors.black,
                        fontSize: AppFontSize.medium,
                        fontWeight: FontWeight.w700,
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: BaseSpacing.sm),
                      CustomText(
                        text: controller.orderIds.length > 1
                            ? "Your ${controller.orderIds.length} orders have been confirmed and are being prepared."
                            : "Your order has been confirmed and is being prepared.",
                        color: AppColors.gray600,
                        fontSize: AppFontSize.verySmall,
                        textAlign: TextAlign.center,
                      ),
                      if (controller.codAmountDue != null) ...[
                        SizedBox(height: BaseSpacing.sm),
                        CustomText(
                          text:
                              "Pay ${CurrencyFormatter.amount(controller.codAmountDue!, controller.currency)} in cash when your physical order is delivered.",
                          color: AppColors.gray600,
                          fontSize: AppFontSize.verySmall,
                          textAlign: TextAlign.center,
                        ),
                      ],
                      SizedBox(height: BaseSpacing.xl),
                      if (controller.hasOrders) ...[
                        PrimaryButton(
                          expand: true,
                          onPressed: controller.viewOrderDetails,
                          label: "View Order Details",
                        ),
                        SizedBox(height: BaseSpacing.sm),
                      ],
                      OutlineButton(
                        expand: true,
                        onPressed: controller.continueShopping,
                        label: "Continue Shopping",
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
