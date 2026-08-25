import 'package:book_store_app/app/components/custom_app_bar_two.dart';
import 'package:book_store_app/app/components/custom_refresh_wrapper.dart';
import 'package:book_store_app/app/components/custom_text.dart';
import 'package:book_store_app/app/components/shimmer/shimmer_effect.dart';
import 'package:book_store_app/app/data/models/bookings/booking_model.dart';
import 'package:book_store_app/app/modules/my_bookings/controllers/my_bookings_controller.dart';
import 'package:book_store_app/app/modules/my_bookings/widgets/booking_card.dart';
import 'package:book_store_app/app/modules/my_bookings/widgets/booking_details_sheet.dart';
import 'package:book_store_app/app/modules/my_bookings/widgets/package_credits_card.dart';
import 'package:book_store_app/config/resources/app_colors.dart';
import 'package:book_store_app/config/resources/app_icons.dart';
import 'package:book_store_app/core/theme/base_animations.dart';
import 'package:book_store_app/core/theme/base_shadows.dart';
import 'package:book_store_app/core/theme/base_spacing.dart';
import 'package:book_store_app/core/widgets/base_empty_view.dart';
import 'package:book_store_app/core/widgets/buttons/base_buttons.dart';
import 'package:book_store_app/utils/app_font_size.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

const List<(String?, String)> _kStatusFilters = [
  (null, 'All'),
  ('pending_payment', 'Pending'),
  ('confirmed', 'Confirmed'),
  ('completed', 'Completed'),
  ('cancelled_by_buyer', 'Cancelled'),
  ('no_show', 'No Show'),
];

class MyBookingsView extends StatelessWidget {
  MyBookingsView({super.key});

  final MyBookingsController controller = Get.put(MyBookingsController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBarTwo(title: 'My Bookings'),
      body: Column(
        children: [
          // A single elevated block so the filters read as "sticky" above
          // the scrolling list beneath — same treatment as My Orders.
          Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              boxShadow: BaseShadows.forLevel(BaseElevation.level2),
            ),
            child: SizedBox(
              height: 50,
              child: ListView.separated(
                padding: EdgeInsets.symmetric(
                  horizontal: BaseSpacing.md,
                  vertical: BaseSpacing.sm,
                ),
                scrollDirection: Axis.horizontal,
                itemCount: _kStatusFilters.length,
                separatorBuilder: (_, __) => SizedBox(width: BaseSpacing.xs),
                itemBuilder: (_, i) {
                  final (status, label) = _kStatusFilters[i];
                  return Obx(() {
                    final selected = controller.statusFilter.value == status;
                    return GestureDetector(
                      onTap: () => controller.setStatusFilter(status),
                      child: AnimatedContainer(
                        duration: BaseMotion.normal,
                        curve: Curves.easeInOut,
                        padding: EdgeInsets.symmetric(
                          horizontal: BaseSpacing.sm + 2,
                          vertical: BaseSpacing.xs,
                        ),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.primaryColor
                              : AppColors.background,
                          borderRadius: BorderRadius.circular(BaseRadius.pill),
                          border: Border.all(
                            color: selected
                                ? AppColors.primaryColor
                                : AppColors.lightGrey2,
                          ),
                        ),
                        child: CustomText(
                          text: label,
                          color: selected ? AppColors.white : AppColors.gray600,
                          fontSize: AppFontSize.tiny,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    );
                  });
                },
              ),
            ),
          ),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const ShimmerEffect(itemCount: 4);
              }

              return CustomRefreshWrapper(
                onRefresh: controller.refresh,
                child:
                    controller.bookings.isEmpty && controller.packages.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(height: BaseSpacing.xxxl * 2),
                          BaseEmptyView(
                            isIcon: false,
                            assetName: AppIcons.calenderIcon,
                            title: 'No bookings yet',
                            subtitle:
                                'Book an appointment or a package with a store to see it here.',
                          ),
                        ],
                      )
                    : ListView(
                        padding: EdgeInsets.all(BaseSpacing.md),
                        children: [
                          if (controller.packages.isNotEmpty) ...[
                            PackageCreditsCard(packages: controller.packages),
                            SizedBox(height: BaseSpacing.md),
                          ],
                          ...controller.bookings.map(
                            (booking) => Padding(
                              padding: EdgeInsets.only(bottom: BaseSpacing.sm),
                              child: BookingCard(
                                booking: booking,
                                onTap: () => _openDetails(context, booking),
                              ),
                            ),
                          ),
                          if (controller.totalPages.value > 1)
                            Padding(
                              padding: EdgeInsets.only(top: BaseSpacing.sm),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  GhostButton(
                                    label: 'Previous',
                                    onPressed: controller.page.value > 1
                                        ? () => controller.loadPage(
                                            controller.page.value - 1,
                                          )
                                        : null,
                                  ),
                                  SizedBox(width: BaseSpacing.md),
                                  CustomText(
                                    text:
                                        '${controller.page.value} / ${controller.totalPages.value}',
                                    color: AppColors.gray600,
                                    fontSize: AppFontSize.tiny,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  SizedBox(width: BaseSpacing.md),
                                  GhostButton(
                                    label: 'Next',
                                    onPressed:
                                        controller.page.value <
                                            controller.totalPages.value
                                        ? () => controller.loadPage(
                                            controller.page.value + 1,
                                          )
                                        : null,
                                  ),
                                ],
                              ),
                            ),
                          SizedBox(height: BaseSpacing.xxl),
                        ],
                      ),
              );
            }),
          ),
        ],
      ),
    );
  }

  void _openDetails(BuildContext context, BookingModel booking) {
    controller.select(booking);
    BookingDetailsSheet.show(context, controller);
  }
}
