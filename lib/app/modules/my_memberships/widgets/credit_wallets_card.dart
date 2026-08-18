import 'package:book_store_app/app/components/custom_text.dart';
import 'package:book_store_app/app/data/models/subscriptions/buyer_credit_wallet_model.dart';
import 'package:book_store_app/config/resources/app_colors.dart';
import 'package:book_store_app/core/theme/base_shadows.dart';
import 'package:book_store_app/core/theme/base_spacing.dart';
import 'package:book_store_app/utils/app_font_size.dart';
import 'package:flutter/material.dart';

/// Summary card of every membership credit wallet the buyer holds —
/// one row per store + credit type. Only rendered when wallets exist.
class CreditWalletsCard extends StatelessWidget {
  final List<BuyerCreditWalletModel> credits;

  const CreditWalletsCard({super.key, required this.credits});

  String _balanceLabel(double value) =>
      value == value.roundToDouble() ? value.toStringAsFixed(0) : value.toString();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(BaseSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(BaseRadius.lg),
        boxShadow: BaseShadows.forLevel(BaseElevation.level1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_balance_wallet_outlined, color: AppColors.accentColor, size: 18),
              SizedBox(width: BaseSpacing.xs),
              CustomText(
                text: 'My Credits',
                color: AppColors.black2,
                fontSize: AppFontSize.extraSmall,
                fontWeight: FontWeight.w700,
              ),
            ],
          ),
          SizedBox(height: BaseSpacing.sm),
          ...credits.map(
            (wallet) => Padding(
              padding: EdgeInsets.only(bottom: BaseSpacing.xs),
              child: Row(
                children: [
                  Expanded(
                    child: CustomText(
                      text: '${wallet.store?.name ?? 'Store'} · ${wallet.creditType == 'service' ? 'Service' : 'Download'} credits',
                      color: AppColors.gray600,
                      fontSize: AppFontSize.tiny,
                      fontWeight: FontWeight.w600,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: BaseSpacing.xs),
                  CustomText(
                    text: _balanceLabel(wallet.balance),
                    color: AppColors.primaryColor,
                    fontSize: AppFontSize.extraSmall,
                    fontWeight: FontWeight.w700,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
