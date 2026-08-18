import 'package:book_store_app/app/components/custom_app_bar_two.dart';
import 'package:book_store_app/app/components/custom_refresh_wrapper.dart';
import 'package:book_store_app/app/components/custom_text.dart';
import 'package:book_store_app/app/data/models/bookings/bookable_service_model.dart';
import 'package:book_store_app/app/modules/store_services/controllers/store_services_controller.dart';
import 'package:book_store_app/app/routes/app_pages.dart';
import 'package:book_store_app/config/resources/app_colors.dart';
import 'package:book_store_app/core/theme/base_shadows.dart';
import 'package:book_store_app/core/theme/base_spacing.dart';
import 'package:book_store_app/utils/app_font_size.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class StoreServicesView extends StatelessWidget {
  StoreServicesView({super.key});

  final StoreServicesController controller = Get.put(StoreServicesController());

  void _openService(BookableServiceModel service) {
    Get.toNamed(
      Routes.storeServiceDetail,
      arguments: {'storeId': controller.storeId, 'storeName': controller.storeName, 'serviceId': service.id},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBarTwo(title: controller.storeName),
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

        if (controller.services.isEmpty) {
          return _EmptyState(onRefresh: controller.refresh);
        }

        return CustomRefreshWrapper(
          onRefresh: controller.refresh,
          child: ListView.separated(
            padding: EdgeInsets.all(BaseSpacing.md),
            itemCount: controller.services.length,
            separatorBuilder: (_, __) => SizedBox(height: BaseSpacing.sm),
            itemBuilder: (_, i) {
              final service = controller.services[i];
              return _ServiceListCard(service: service, onTap: () => _openService(service));
            },
          ),
        );
      }),
    );
  }
}

class _ServiceListCard extends StatelessWidget {
  final BookableServiceModel service;
  final VoidCallback onTap;

  const _ServiceListCard({required this.service, required this.onTap});

  String _locationTypeLabel(String type) => switch (type) {
        'in_person' => 'In Person',
        'virtual' => 'Virtual',
        'customer_address' => "Your Address",
        _ => type,
      };

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(BaseRadius.md),
                  ),
                  alignment: Alignment.center,
                  child: Icon(Icons.event_available_rounded, color: AppColors.primaryColor, size: 22),
                ),
                SizedBox(width: BaseSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        text: service.name,
                        color: AppColors.black2,
                        fontSize: AppFontSize.extraSmall,
                        fontWeight: FontWeight.w700,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: BaseSpacing.xxs),
                      Row(
                        children: [
                          CustomText(
                            text: '\$${service.price.toStringAsFixed(2)} ${service.currency}',
                            color: AppColors.primaryColor,
                            fontSize: AppFontSize.tiny,
                            fontWeight: FontWeight.w700,
                          ),
                          SizedBox(width: BaseSpacing.sm),
                          Icon(Icons.schedule_rounded, size: 13, color: AppColors.gray600),
                          SizedBox(width: BaseSpacing.xxs / 2),
                          CustomText(
                            text: '${service.durationMinutes} min',
                            color: AppColors.gray600,
                            fontSize: AppFontSize.tiny,
                            fontWeight: FontWeight.w600,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.lightGrey, size: 20),
              ],
            ),
            if (service.description != null && service.description!.isNotEmpty) ...[
              SizedBox(height: BaseSpacing.xs),
              CustomText(
                text: service.description!,
                color: AppColors.gray600,
                fontSize: AppFontSize.tiny,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (service.locationTypes.isNotEmpty) ...[
              SizedBox(height: BaseSpacing.xs),
              Wrap(
                spacing: BaseSpacing.xxs,
                runSpacing: BaseSpacing.xxs,
                children: service.locationTypes
                    .map(
                      (t) => Container(
                        padding: EdgeInsets.symmetric(horizontal: BaseSpacing.xs, vertical: 2),
                        decoration: BoxDecoration(color: AppColors.lightGrey10, borderRadius: BorderRadius.circular(BaseRadius.pill)),
                        child: CustomText(text: _locationTypeLabel(t), color: AppColors.gray600, fontSize: 10.5, fontWeight: FontWeight.w600),
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final Future<void> Function() onRefresh;

  const _EmptyState({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return CustomRefreshWrapper(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: BaseSpacing.xl),
        children: [
          SizedBox(height: BaseSpacing.xxxl * 2),
          Center(
            child: Column(
              children: [
                Icon(Icons.event_busy_outlined, size: 44, color: AppColors.lightGrey),
                SizedBox(height: BaseSpacing.sm),
                CustomText(
                  text: 'No services yet',
                  color: AppColors.black2,
                  fontSize: AppFontSize.extraSmall,
                  fontWeight: FontWeight.w700,
                ),
                SizedBox(height: BaseSpacing.xxs),
                CustomText(
                  text: 'This store hasn\'t listed any bookable services.',
                  color: AppColors.gray600,
                  fontSize: AppFontSize.tiny,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
