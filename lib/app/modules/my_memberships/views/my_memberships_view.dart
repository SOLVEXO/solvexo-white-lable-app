import 'package:book_store_app/app/components/custom_app_bar_two.dart';
import 'package:book_store_app/app/components/custom_refresh_wrapper.dart';
import 'package:book_store_app/app/components/custom_text.dart';
import 'package:book_store_app/app/data/models/subscriptions/buyer_subscription_model.dart';
import 'package:book_store_app/app/modules/my_memberships/controllers/my_memberships_controller.dart';
import 'package:book_store_app/app/modules/my_memberships/widgets/credit_wallets_card.dart';
import 'package:book_store_app/app/modules/my_memberships/widgets/membership_card.dart';
import 'package:book_store_app/app/modules/my_memberships/widgets/membership_details_sheet.dart';
import 'package:book_store_app/config/resources/app_colors.dart';
import 'package:book_store_app/core/theme/base_spacing.dart';
import 'package:book_store_app/utils/app_font_size.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MyMembershipsView extends StatelessWidget {
  MyMembershipsView({super.key});

  final MyMembershipsController controller = Get.put(MyMembershipsController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBarTwo(title: 'My Memberships'),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryColor),
            ),
          );
        }

        return CustomRefreshWrapper(
          onRefresh: controller.refresh,
          child: controller.memberships.isEmpty && controller.credits.isEmpty
              ? _EmptyState()
              : ListView(
                  padding: EdgeInsets.all(BaseSpacing.md),
                  children: [
                    if (controller.credits.isNotEmpty) ...[
                      CreditWalletsCard(credits: controller.credits),
                      SizedBox(height: BaseSpacing.md),
                    ],
                    ...controller.memberships.map(
                      (membership) => Padding(
                        padding: EdgeInsets.only(bottom: BaseSpacing.sm),
                        child: MembershipCard(
                          membership: membership,
                          onTap: () => _openDetails(context, membership),
                        ),
                      ),
                    ),
                    SizedBox(height: BaseSpacing.xxl),
                  ],
                ),
        );
      }),
    );
  }

  void _openDetails(BuildContext context, BuyerSubscriptionModel membership) {
    controller.select(membership);
    MembershipDetailsSheet.show(context, controller);
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      // Keeps pull-to-refresh working on the empty state.
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: BaseSpacing.xl),
      children: [
        SizedBox(height: BaseSpacing.xxxl * 2),
        Center(
          child: Column(
            children: [
              Icon(Icons.card_membership_outlined, size: 44, color: AppColors.lightGrey),
              SizedBox(height: BaseSpacing.sm),
              CustomText(
                text: 'No memberships yet',
                color: AppColors.black2,
                fontSize: AppFontSize.extraSmall,
                fontWeight: FontWeight.w700,
              ),
              SizedBox(height: BaseSpacing.xxs),
              CustomText(
                text: 'Subscribe to a store\'s membership plan to unlock perks like discounts, free shipping, and credits.',
                color: AppColors.gray600,
                fontSize: AppFontSize.tiny,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
