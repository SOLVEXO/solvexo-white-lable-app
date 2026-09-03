import 'package:book_store_app/app/components/buttons/app_button.dart';
import 'package:book_store_app/app/components/custom_app_bar_two.dart';
import 'package:book_store_app/app/components/custom_text.dart';
import 'package:book_store_app/app/modules/otp_verification/controllers/otp_verification_controller.dart';
import 'package:book_store_app/config/resources/app_colors.dart';
import 'package:book_store_app/core/theme/base_spacing.dart';
import 'package:book_store_app/core/widgets/base_view_screen.dart';
import 'package:book_store_app/utils/app_font_size.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

class OtpVerificationView extends StatelessWidget {
  const OtpVerificationView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<OtpVerificationController>();

    return BaseViewScreen(
      backgroundColor: AppColors.white,
      appBar: CustomAppBarTwo(backgroundColor: AppColors.white, iconColor: AppColors.black2),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(BaseSpacing.xl, BaseSpacing.md, BaseSpacing.xl, BaseSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 64,
              width: 64,
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(Icons.mark_email_read_outlined, color: AppColors.primaryColor, size: 32),
            ),
            SizedBox(height: BaseSpacing.lg),
            CustomText(
              text: 'Verify your email',
              color: AppColors.black2,
              fontSize: AppFontSize.veryLarge,
              fontWeight: FontWeight.bold,
            ),
            SizedBox(height: BaseSpacing.xxs),
            CustomText(
              text: 'Enter the 6-digit code we sent to\n${controller.email}',
              color: AppColors.gray600,
              fontSize: AppFontSize.small2,
              height: 1.4,
            ),
            SizedBox(height: BaseSpacing.xxl),
            PinCodeTextField(
              appContext: context,
              length: 6,
              controller: controller.otpController,
              // The controller is owned (and disposed) by OtpVerificationController,
              // same as every other TextEditingController in this app — without
              // this, PinCodeTextField's own default auto-dispose double-frees
              // it, crashing with "used after being disposed" when the screen
              // closes.
              autoDisposeControllers: false,
              keyboardType: TextInputType.number,
              autoFocus: true,
              animationType: AnimationType.fade,
              onChanged: (value) => controller.otp.value = value,
              onCompleted: (_) => controller.submit(),
              pinTheme: PinTheme(
                shape: PinCodeFieldShape.box,
                borderRadius: BorderRadius.circular(BaseRadius.md),
                fieldHeight: 48,
                fieldWidth: 44,
                activeColor: AppColors.primaryColor,
                selectedColor: AppColors.primaryColor,
                inactiveColor: AppColors.lightGrey2,
                activeFillColor: AppColors.white,
                selectedFillColor: AppColors.white,
                inactiveFillColor: AppColors.background,
              ),
            ),
            SizedBox(height: BaseSpacing.xl),
            Obx(
              () => AppButton(
                key: const Key('otp-submit-button'),
                label: controller.isVerifying.value ? 'Verifying...' : 'Verify & Continue',
                onPressed: controller.isVerifying.value ? null : controller.submit,
                height: 52,
              ),
            ),
            SizedBox(height: BaseSpacing.lg),
            Center(
              child: Obx(
                () => GestureDetector(
                  onTap: controller.canResend ? controller.resend : null,
                  child: CustomText(
                    text: controller.canResend
                        ? "Didn't get a code? Resend"
                        : 'Resend code in 0:${controller.secondsUntilResend.value.toString().padLeft(2, '0')}',
                    color: controller.canResend ? AppColors.primaryColor : AppColors.gray600,
                    fontSize: AppFontSize.small2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
