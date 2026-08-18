import 'package:book_store_app/app/components/custom_text.dart';
import 'package:book_store_app/app/data/models/bookings/bookable_service_model.dart';
import 'package:book_store_app/app/data/repositories/bookings_repository.dart';
import 'package:book_store_app/app/routes/app_pages.dart';
import 'package:book_store_app/config/resources/app_colors.dart';
import 'package:book_store_app/core/theme/base_shadows.dart';
import 'package:book_store_app/core/theme/base_spacing.dart';
import 'package:book_store_app/utils/app_font_size.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// "Services" section shown on a store's storefront when it has at least one
/// bookable/active service (same hide-when-empty contract as
/// StorefrontPlansTeaser) — a horizontal scroll of compact cards (name,
/// price, duration), each tapping through to that service's booking screen.
/// Hidden entirely for stores without services.
class StorefrontServicesTeaser extends StatefulWidget {
  final String storeId;
  final String storeName;

  const StorefrontServicesTeaser({super.key, required this.storeId, required this.storeName});

  @override
  State<StorefrontServicesTeaser> createState() => _StorefrontServicesTeaserState();
}

class _StorefrontServicesTeaserState extends State<StorefrontServicesTeaser> {
  final _repo = BookingsRepository();
  List<BookableServiceModel> _services = [];

  @override
  void initState() {
    super.initState();
    if (widget.storeId.isNotEmpty) _load();
  }

  Future<void> _load() async {
    final services = await _repo.browseStoreServices(widget.storeId);
    if (!mounted) return;
    setState(() => _services = services);
  }

  void _openService(BookableServiceModel service) {
    Get.toNamed(
      Routes.storeServiceDetail,
      arguments: {'storeId': widget.storeId, 'storeName': widget.storeName, 'serviceId': service.id},
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_services.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 0, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Row(
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
                Expanded(
                  child: CustomText(
                    text: 'Book a service',
                    color: AppColors.black2,
                    fontSize: AppFontSize.small2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                GestureDetector(
                  onTap: () => Get.toNamed(
                    Routes.storeServices,
                    arguments: {'storeId': widget.storeId, 'storeName': widget.storeName},
                  ),
                  child: CustomText(
                    text: 'See all',
                    color: AppColors.primaryColor,
                    fontSize: AppFontSize.tiny,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: BaseSpacing.sm),
          SizedBox(
            height: 132,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(right: 20),
              itemCount: _services.length,
              separatorBuilder: (_, __) => SizedBox(width: BaseSpacing.sm),
              itemBuilder: (_, i) => _ServiceTeaserCard(
                service: _services[i],
                onTap: () => _openService(_services[i]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceTeaserCard extends StatelessWidget {
  final BookableServiceModel service;
  final VoidCallback onTap;

  const _ServiceTeaserCard({required this.service, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 168,
        padding: EdgeInsets.all(BaseSpacing.sm + 2),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(BaseRadius.lg),
          boxShadow: BaseShadows.forLevel(BaseElevation.level1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(BaseRadius.md),
              ),
              alignment: Alignment.center,
              child: Icon(Icons.event_available_rounded, color: AppColors.primaryColor, size: 18),
            ),
            SizedBox(height: BaseSpacing.xs),
            CustomText(
              text: service.name,
              color: AppColors.black2,
              fontSize: AppFontSize.tiny,
              fontWeight: FontWeight.w700,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            CustomText(
              text: '\$${service.price.toStringAsFixed(2)}',
              color: AppColors.primaryColor,
              fontSize: AppFontSize.tiny,
              fontWeight: FontWeight.w700,
            ),
            SizedBox(height: BaseSpacing.xxs / 2),
            Row(
              children: [
                Icon(Icons.schedule_rounded, size: 12, color: AppColors.gray600),
                SizedBox(width: BaseSpacing.xxs / 2),
                CustomText(
                  text: '${service.durationMinutes} min',
                  color: AppColors.gray600,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
