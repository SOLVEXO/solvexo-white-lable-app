import 'package:book_store_app/app/components/custom_confirm_dialog.dart';
import 'package:book_store_app/app/components/custom_text.dart';
import 'package:book_store_app/app/data/models/subscriptions/buyer_store_benefits_model.dart';
import 'package:book_store_app/app/data/models/subscriptions/buyer_store_plan_model.dart';
import 'package:book_store_app/app/data/repositories/buyer_memberships_repository.dart';
import 'package:book_store_app/config/resources/app_colors.dart';
import 'package:book_store_app/core/theme/base_shadows.dart';
import 'package:book_store_app/core/theme/base_spacing.dart';
import 'package:book_store_app/utils/app_font_size.dart';
import 'package:flutter/material.dart';

/// "Membership plans" section shown on a store's storefront when it has at
/// least one active plan (same hide-when-empty contract as
/// StorefrontLoyaltyTeaser) — each plan row shows name, price, and benefit
/// bullets, with a Subscribe button that confirms and POSTs the
/// subscription. Hidden entirely for stores without plans.
class StorefrontPlansTeaser extends StatefulWidget {
  final String storeId;
  final String storeName;

  const StorefrontPlansTeaser({super.key, required this.storeId, required this.storeName});

  @override
  State<StorefrontPlansTeaser> createState() => _StorefrontPlansTeaserState();
}

class _StorefrontPlansTeaserState extends State<StorefrontPlansTeaser> {
  final _repo = BuyerMembershipsRepository();
  List<BuyerStorePlanModel> _plans = [];
  BuyerStoreBenefitsModel _benefits = BuyerStoreBenefitsModel.empty;
  String _subscribingPlanId = '';

  @override
  void initState() {
    super.initState();
    if (widget.storeId.isNotEmpty) _load();
  }

  Future<void> _load() async {
    final plansFuture = _repo.getStorePlans(widget.storeId);
    final benefitsFuture = _repo.getStoreBenefits(widget.storeId);
    final plans = await plansFuture;
    final benefits = await benefitsFuture;
    if (!mounted) return;
    setState(() {
      _plans = plans;
      _benefits = benefits;
    });
  }

  void _confirmSubscribe(BuyerStorePlanModel plan) {
    CustomConfirmDialog.show(
      context,
      title: 'Subscribe to "${plan.name}"?',
      message:
          'You will be charged \$${plan.monthlyPriceUSD.toStringAsFixed(2)} per month for a ${widget.storeName} membership. You can pause or cancel anytime from My Memberships.',
      confirmLabel: 'Subscribe',
      onConfirm: () => _subscribe(plan),
    );
  }

  Future<void> _subscribe(BuyerStorePlanModel plan) async {
    if (_subscribingPlanId.isNotEmpty) return;
    setState(() => _subscribingPlanId = plan.id);
    final subscription = await _repo.subscribe(planId: plan.id, billingInterval: 'monthly', storeId: widget.storeId);
    if (!mounted) return;
    setState(() => _subscribingPlanId = '');
    if (subscription != null) await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_plans.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 16,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              SizedBox(width: BaseSpacing.xs),
              CustomText(
                text: 'Membership plans',
                color: AppColors.black2,
                fontSize: AppFontSize.small2,
                fontWeight: FontWeight.w700,
              ),
            ],
          ),
          if (_benefits.subscribed) ...[
            SizedBox(height: BaseSpacing.xs),
            Row(
              children: [
                const Icon(Icons.verified_rounded, size: 15, color: AppColors.greenSuccess),
                SizedBox(width: BaseSpacing.xxs),
                Expanded(
                  child: CustomText(
                    text: 'You\'re a member — ${_benefits.planName ?? 'membership active'}',
                    color: AppColors.greenSuccess,
                    fontSize: AppFontSize.tiny,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
          SizedBox(height: BaseSpacing.sm),
          ..._plans.map(
            (plan) => Padding(
              padding: EdgeInsets.only(bottom: BaseSpacing.sm),
              child: _PlanRow(
                plan: plan,
                isSubscribing: _subscribingPlanId == plan.id,
                showSubscribe: !_benefits.subscribed,
                onSubscribe: () => _confirmSubscribe(plan),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanRow extends StatelessWidget {
  final BuyerStorePlanModel plan;
  final bool isSubscribing;
  final bool showSubscribe;
  final VoidCallback onSubscribe;

  const _PlanRow({
    required this.plan,
    required this.isSubscribing,
    required this.showSubscribe,
    required this.onSubscribe,
  });

  @override
  Widget build(BuildContext context) {
    final bullets = plan.activeBenefits.map((b) => b.summary).toList();

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
              Expanded(
                child: CustomText(
                  text: plan.name,
                  color: AppColors.black2,
                  fontSize: AppFontSize.extraSmall,
                  fontWeight: FontWeight.w700,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: BaseSpacing.xs),
              CustomText(
                text: '\$${plan.monthlyPriceUSD.toStringAsFixed(2)} / mo',
                color: AppColors.primaryColor,
                fontSize: AppFontSize.extraSmall,
                fontWeight: FontWeight.w700,
              ),
            ],
          ),
          if (plan.description != null && plan.description!.isNotEmpty) ...[
            SizedBox(height: BaseSpacing.xxs),
            CustomText(
              text: plan.description!,
              color: AppColors.gray600,
              fontSize: AppFontSize.tiny,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (bullets.isNotEmpty) ...[
            SizedBox(height: BaseSpacing.xs),
            ...bullets.map(
              (bullet) => Padding(
                padding: EdgeInsets.only(bottom: BaseSpacing.xxs),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle_outline_rounded, size: 15, color: AppColors.greenSuccess),
                    SizedBox(width: BaseSpacing.xs),
                    Expanded(
                      child: CustomText(
                        text: bullet,
                        color: AppColors.gray600,
                        fontSize: AppFontSize.tiny,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (showSubscribe) ...[
            SizedBox(height: BaseSpacing.xs),
            GestureDetector(
              onTap: isSubscribing ? null : onSubscribe,
              child: Container(
                width: double.infinity,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSubscribing ? AppColors.lightGrey.withOpacity(0.5) : AppColors.primaryColor,
                  borderRadius: BorderRadius.circular(BaseRadius.md),
                ),
                child: isSubscribing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
                      )
                    : CustomText(
                        text: 'Subscribe',
                        color: AppColors.white,
                        fontSize: AppFontSize.tiny,
                        fontWeight: FontWeight.w700,
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
