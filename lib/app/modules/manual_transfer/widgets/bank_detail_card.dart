import 'package:book_store_app/app/components/custom_text.dart';
import 'package:book_store_app/app/data/models/payment/manual_payment_model.dart';
import 'package:book_store_app/config/resources/app_colors.dart';
import 'package:book_store_app/core/theme/base_spacing.dart';
import 'package:book_store_app/utils/app_font_size.dart';
import 'package:book_store_app/utils/toast_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Reusable "here's where to send the money" card — every account field the
/// admin has configured, each row copyable with one tap. Used on the
/// bank-transfer submission screen; kept as its own widget since it's a
/// self-contained, reusable piece of UI (matches the seller-finance module's
/// `widgets/` convention).
class BankDetailCard extends StatelessWidget {
  final ManualPaymentBankDetails details;
  final String? instructions;

  const BankDetailCard({super.key, required this.details, this.instructions});

  void _copy(BuildContext context, String value) {
    Clipboard.setData(ClipboardData(text: value));
    ToastUtil.showToast('Copied to clipboard');
  }

  @override
  Widget build(BuildContext context) {
    final fields = details.filledFields;
    return Container(
      padding: EdgeInsets.all(BaseSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(BaseRadius.lg),
        border: Border.all(color: AppColors.primaryColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_balance_rounded, size: 18, color: AppColors.primaryColor),
              SizedBox(width: BaseSpacing.xs),
              CustomText(
                text: 'Transfer to this account',
                color: AppColors.black2,
                fontSize: AppFontSize.verySmall,
                fontWeight: FontWeight.w700,
              ),
            ],
          ),
          SizedBox(height: BaseSpacing.sm),
          if (fields.isEmpty)
            CustomText(
              text: 'Bank details are being set up — please check back shortly.',
              color: AppColors.gray600,
              fontSize: AppFontSize.tiny,
            )
          else
            ...fields.map(
              (entry) => Padding(
                padding: EdgeInsets.symmetric(vertical: BaseSpacing.xxs),
                child: Row(
                  children: [
                    SizedBox(
                      width: 100,
                      child: CustomText(text: entry.key, color: AppColors.gray600, fontSize: AppFontSize.tiny),
                    ),
                    Expanded(
                      child: CustomText(
                        text: entry.value,
                        color: AppColors.black2,
                        fontSize: AppFontSize.extraSmall,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _copy(context, entry.value),
                      child: Icon(Icons.copy_rounded, size: 15, color: AppColors.primaryColor),
                    ),
                  ],
                ),
              ),
            ),
          if (instructions != null && instructions!.isNotEmpty) ...[
            SizedBox(height: BaseSpacing.xs),
            const Divider(),
            SizedBox(height: BaseSpacing.xxs),
            CustomText(text: instructions!, color: AppColors.gray600, fontSize: AppFontSize.tiny),
          ],
        ],
      ),
    );
  }
}
