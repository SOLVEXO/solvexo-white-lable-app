import 'package:book_store_app/app/components/custom_text.dart';
import 'package:book_store_app/app/modules/seller_storefront/controllers/seller_storefront_controller.dart';
import 'package:book_store_app/config/resources/app_colors.dart';
import 'package:book_store_app/utils/app_font_size.dart';
import 'package:book_store_app/utils/dimens.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Type chips (All / Physical / Digital) + a tag row (when the store has
/// tagged products) + a sort picker, styled as a floating elevated card
/// so it reads as a distinct control surface over the product grid below.
class StorefrontFilterBar extends StatelessWidget {
  final SellerStorefrontController c;
  const StorefrontFilterBar({super.key, required this.c});

  static const _types = ['all', 'physical', 'digital'];
  static const _typeLabels = {'all': 'All', 'physical': 'Physical', 'digital': 'Digital'};
  static const _typeIcons = {
    'all': Icons.apps_rounded,
    'physical': Icons.inventory_2_rounded,
    'digital': Icons.cloud_download_rounded,
  };
  static const _sortShortLabels = {
    'newest': 'Newest',
    'price_asc': 'Price ↑',
    'price_desc': 'Price ↓',
    'best_rated': 'Top Rated',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppDimen.allPadding),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: Obx(() {
                    final selectedType = c.selectedType.value;
                    return ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _types.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final type = _types[i];
                        final selected = selectedType == type;
                        return GestureDetector(
                          onTap: () => c.setType(type),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 160),
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              gradient: selected
                                  ? LinearGradient(
                                      colors: [AppColors.primaryColor, AppColors.accentColor],
                                    )
                                  : null,
                              color: selected ? null : AppColors.background,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: selected ? Colors.transparent : AppColors.lightGrey2,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _typeIcons[type],
                                  size: 14,
                                  color: selected ? AppColors.white : AppColors.grey,
                                ),
                                const SizedBox(width: 6),
                                CustomText(
                                  text: _typeLabels[type]!,
                                  fontSize: AppFontSize.tiny,
                                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                                  color: selected ? AppColors.white : AppColors.grey,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  }),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _showSortSheet(context),
                child: Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.lightGrey2),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.swap_vert_rounded, size: 16, color: AppColors.black2),
                      const SizedBox(width: 4),
                      Obx(
                        () => CustomText(
                          text: _sortShortLabels[c.sort.value] ?? 'Sort',
                          fontSize: AppFontSize.tiny,
                          fontWeight: FontWeight.w600,
                          color: AppColors.black2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Obx(() {
            if (c.filterTags.isEmpty) return const SizedBox.shrink();
            final tags = c.filterTags.toList();
            final selectedTag = c.selectedTag.value;
            return Padding(
              padding: const EdgeInsets.only(top: 10),
              child: SizedBox(
                height: 30,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: tags.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final tag = i == 0 ? 'all' : tags[i - 1];
                    final selected = selectedTag == tag;
                    return GestureDetector(
                      onTap: () => c.setTag(tag),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: selected ? AppColors.primaryColor.withOpacity(0.1) : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: selected ? AppColors.primaryColor : AppColors.lightGrey2,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: CustomText(
                          text: i == 0 ? 'All tags' : '#$tag',
                          fontSize: AppFontSize.tiny,
                          fontWeight: FontWeight.w600,
                          color: selected ? AppColors.primaryColor : AppColors.grey,
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  void _showSortSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(color: AppColors.lightGrey2, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 18),
            CustomText(
              text: 'Sort products by',
              fontSize: AppFontSize.small,
              fontWeight: FontWeight.bold,
              color: AppColors.black2,
            ),
            const SizedBox(height: 8),
            ...SellerStorefrontController.sortLabels.entries.map(
              (e) => Obx(() {
                final selected = c.sort.value == e.key;
                return GestureDetector(
                  onTap: () {
                    c.setSort(e.key);
                    Navigator.pop(context);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primaryColor.withOpacity(0.08) : AppColors.background,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: selected ? AppColors.primaryColor : Colors.transparent,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: CustomText(
                            text: e.value,
                            fontSize: AppFontSize.verySmall,
                            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                            color: selected ? AppColors.primaryColor : AppColors.black2,
                          ),
                        ),
                        Icon(
                          selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                          size: 20,
                          color: selected ? AppColors.primaryColor : AppColors.lightGrey2,
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
