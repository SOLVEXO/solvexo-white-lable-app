import 'package:book_store_app/app/base_view/base_view_screen.dart';
import 'package:book_store_app/app/components/custom_text.dart';
import 'package:book_store_app/app/modules/gateway_payment/controllers/gateway_payment_controller.dart';
import 'package:book_store_app/config/resources/app_colors.dart';
import 'package:book_store_app/core/theme/base_spacing.dart';
import 'package:book_store_app/core/widgets/buttons/base_buttons.dart';
import 'package:book_store_app/utils/app_font_size.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Hosts a redirect-based gateway's (Safepay et al) hosted checkout page.
/// Stays open until the WebView either reaches the return URL (success,
/// confirmed server-side) or the cancel URL (buyer backed out) — both
/// intercepted before they'd ever actually load, see
/// [GatewayPaymentController].
class GatewayPaymentView extends StatelessWidget {
  GatewayPaymentView({super.key});

  final controller = Get.put(GatewayPaymentController());

  @override
  Widget build(BuildContext context) {
    return BaseViewScreen(
      screenName: 'Pay with ${controller.method.displayName}',
      horizontalPadding: false,
      verticalPadding: false,
      backgroundColor: AppColors.white,
      child: Obx(() {
        switch (controller.uiState.value) {
          case GatewayPaymentUiState.loading:
            return const _CenteredMessage(child: CircularProgressIndicator());
          case GatewayPaymentUiState.webview:
            return WebViewWidget(controller: controller.webViewController!);
          case GatewayPaymentUiState.confirming:
            return const _CenteredMessage(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                spacing: BaseSpacing.md,
                children: [
                  CircularProgressIndicator(),
                  CustomText(text: 'Confirming your payment...', fontSize: AppFontSize.small),
                ],
              ),
            );
          case GatewayPaymentUiState.error:
            return _CenteredMessage(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: BaseSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  spacing: BaseSpacing.lg,
                  children: [
                    const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
                    CustomText(
                      text: controller.errorMessage.value,
                      fontSize: AppFontSize.small,
                      textAlign: TextAlign.center,
                    ),
                    PrimaryButton(label: 'Try Again', onPressed: controller.retry),
                  ],
                ),
              ),
            );
        }
      }),
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(child: child);
  }
}
