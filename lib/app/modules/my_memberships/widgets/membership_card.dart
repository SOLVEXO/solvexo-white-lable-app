import 'package:book_store_app/app/components/custom_text.dart';
import 'package:book_store_app/app/data/models/subscriptions/buyer_subscription_model.dart';
import 'package:book_store_app/app/modules/my_memberships/widgets/membership_status_chip.dart';
import 'package:book_store_app/config/resources/app_colors.dart';
import 'package:book_store_app/core/theme/base_shadows.dart';
import 'package:book_store_app/core/theme/base_spacing.dart';
import 'package:book_store_app/utils/app_font_size.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Full-width card for one store membership: store name, plan name,
/// price/interval, status chip, and the next renewal (or end) date.
class MembershipCard extends StatelessWidget {
  final BuyerSubscriptionModel membership;
  final VoidCallback onTap;

  const MembershipCard({super.key, required this.membership, required this.onTap});

  String get _priceLabel =>
      '\$${membership.amountUSD.toStringAsFixed(2)} / ${membership.billingInterval == 'yearly' ? 'yr' : 'mo'}';

  String? get _dateLine {
    final d = membership.pendingCancellation || membership.isCanceled
        ? membership.currentPeriodEnd
        : membership.nextBillingDate;
    if (d == null) return null;
    final formatted = DateFormat('MMM d, yyyy').format(d);
    if (membership.isCanceled) return 'Ended $formatted';
    if (membership.pendingCancellation) return 'Ends $formatted';
    if (membership.isPaused) return 'Paused — was renewing $formatted';
    if (membership.isPastDue) return 'Payment due $formatted';
    return 'Renews $formatted';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(BaseSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(BaseRadius.lg),
          boxShadow: BaseShadows.forLevel(BaseElevation.level1),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(BaseRadius.md),
              ),
              alignment: Alignment.center,
              child: Icon(Icons.card_membership_rounded, color: AppColors.primaryColor, size: 22),
            ),
            SizedBox(width: BaseSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: CustomText(
                          text: membership.store?.name ?? 'Store',
                          color: AppColors.black2,
                          fontSize: AppFontSize.extraSmall,
                          fontWeight: FontWeight.w700,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: BaseSpacing.xs),
                      MembershipStatusChip(
                        status: membership.status,
                        pendingCancellation: membership.pendingCancellation,
                      ),
                    ],
                  ),
                  SizedBox(height: BaseSpacing.xxs),
                  CustomText(
                    text: '${membership.plan?.name ?? 'Membership'} · $_priceLabel',
                    color: AppColors.gray600,
                    fontSize: AppFontSize.tiny,
                    fontWeight: FontWeight.w600,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (_dateLine != null) ...[
                    SizedBox(height: BaseSpacing.xxs),
                    CustomText(
                      text: _dateLine!,
                      color: membership.isPastDue ? AppColors.red : AppColors.gray600,
                      fontSize: AppFontSize.tiny,
                      fontWeight: FontWeight.w500,
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(width: BaseSpacing.xs),
            const Icon(Icons.chevron_right_rounded, color: AppColors.lightGrey, size: 20),
          ],
        ),
      ),
    );
  }
}
