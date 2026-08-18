import 'package:book_store_app/app/components/common_image_view.dart';
import 'package:book_store_app/app/components/custom_app_bar_two.dart';
import 'package:book_store_app/app/components/custom_refresh_wrapper.dart';
import 'package:book_store_app/app/components/custom_text.dart';
import 'package:book_store_app/app/modules/category/controllers/category_controller.dart';
import 'package:book_store_app/app/modules/category/models/category_model.dart';
import 'package:book_store_app/app/modules/category/widgets/category_search_bar.dart';
import 'package:book_store_app/app/modules/category/widgets/category_search_list.dart';
import 'package:book_store_app/config/resources/app_colors.dart';
import 'package:book_store_app/core/theme/base_animations.dart';
import 'package:book_store_app/core/theme/base_spacing.dart';
import 'package:book_store_app/utils/app_font_size.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';

/// Split-pane category browser: a vertical rail of root categories on the
/// left ("All" + each root), and a 2-column grid on the right showing either
/// every root (All) or the selected root's subcategories. Tapping any grid
/// tile keeps the existing behavior — straight to SubCategoryView's product
/// grid for that category.
class CategoryView extends StatelessWidget {
  const CategoryView({super.key});

  // Guarded — was unconditional `Get.put`, which replaced the shared
  // `CategoryController` singleton (also used by Home's "Browse by
  // Category" section) every time this screen was opened.
  CategoryController get controller {
    if (!Get.isRegistered<CategoryController>()) {
      Get.put(CategoryController(), permanent: true);
    }
    return Get.find<CategoryController>();
  }

  @override
  Widget build(BuildContext context) {
    final controller = this.controller;
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: CustomAppBarTwo(title: "Categories"),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CategorySearchBar(controller: controller),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const _CategorySplitShimmer();
              }
              if (controller.searchQuery.value.isNotEmpty) {
                return CategorySearchList(controller: controller);
              }
              if (controller.rootCategories.isEmpty) {
                return const _EmptyState();
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _CategoryRail(controller: controller),
                  Expanded(child: _SubcategoryPane(controller: controller)),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ─── Left rail ───────────────────────────────────────────────────────────────

class _CategoryRail extends StatelessWidget {
  final CategoryController controller;
  const _CategoryRail({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      color: AppColors.background,
      child: Obx(() {
        final selected = controller.railSelection.value;
        return ListView(
          padding: EdgeInsets.only(bottom: BaseSpacing.xl),
          children: [
            _RailItem(
              label: 'All',
              image: null,
              fallbackIcon: Icons.grid_view_rounded,
              selected: selected == null,
              onTap: () => controller.selectRail(null),
            ),
            ...controller.rootCategories.map(
              (cat) => _RailItem(
                label: cat.name,
                image: cat.image,
                fallbackIcon: Icons.category_outlined,
                selected: selected?.id == cat.id,
                onTap: () => controller.selectRail(cat),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _RailItem extends StatelessWidget {
  final String label;
  final String? image;
  final IconData fallbackIcon;
  final bool selected;
  final VoidCallback onTap;

  const _RailItem({
    required this.label,
    required this.image,
    required this.fallbackIcon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: BaseMotion.normal,
        color: selected ? AppColors.white : AppColors.transparent,
        padding: EdgeInsets.symmetric(vertical: BaseSpacing.sm),
        child: Row(
          children: [
            // Selected indicator bar
            AnimatedContainer(
              duration: BaseMotion.normal,
              width: 3,
              height: 44,
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primaryColor
                    : AppColors.transparent,
                borderRadius: const BorderRadius.horizontal(
                  right: Radius.circular(2),
                ),
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primaryColor.withOpacity(0.12)
                          : AppColors.lightGrey10,
                      borderRadius: BorderRadius.circular(BaseRadius.md),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: image != null && image!.isNotEmpty
                        ? CommonImageView(url: image, fit: BoxFit.cover)
                        : Icon(
                            fallbackIcon,
                            size: 20,
                            color: selected
                                ? AppColors.primaryColor
                                : AppColors.gray600,
                          ),
                  ),
                  SizedBox(height: BaseSpacing.xxs + 1),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: BaseSpacing.xxs),
                    child: CustomText(
                      text: label,
                      color: selected ? AppColors.black2 : AppColors.gray600,
                      fontSize: AppFontSize.tiny,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 3),
          ],
        ),
      ),
    );
  }
}

// ─── Right pane ──────────────────────────────────────────────────────────────

class _SubcategoryPane extends StatelessWidget {
  final CategoryController controller;
  const _SubcategoryPane({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final parent = controller.railSelection.value;
      final items = parent == null
          ? controller.rootCategories
          : parent.children;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              BaseSpacing.md,
              BaseSpacing.sm,
              BaseSpacing.md,
              0,
            ),
            child: Row(
              children: [
                Expanded(
                  child: CustomText(
                    text: parent?.name ?? 'All Categories',
                    color: AppColors.black2,
                    fontSize: AppFontSize.small2,
                    fontWeight: FontWeight.bold,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (parent != null)
                  GestureDetector(
                    onTap: () => controller.selectCategory(parent),
                    child: Row(
                      children: [
                        CustomText(
                          text: 'View all',
                          color: AppColors.primaryColor,
                          fontSize: AppFontSize.tiny,
                          fontWeight: FontWeight.w700,
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 16,
                          color: AppColors.primaryColor,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? _NoSubcategories(parent: parent!, controller: controller)
                : CustomRefreshWrapper(
                    onRefresh: controller.refresh,
                    child: GridView.builder(
                      padding: EdgeInsets.fromLTRB(
                        BaseSpacing.md,
                        BaseSpacing.sm,
                        BaseSpacing.md,
                        BaseSpacing.xl,
                      ),
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: items.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.92,
                          ),
                      itemBuilder: (_, i) {
                        final item = items[i];
                        return _SubcategoryTile(
                          category: item,
                          onTap: () => controller.selectCategory(item),
                        );
                      },
                    ),
                  ),
          ),
        ],
      );
    });
  }
}

class _SubcategoryTile extends StatelessWidget {
  final CategoryModel category;
  final VoidCallback onTap;

  const _SubcategoryTile({required this.category, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.lightGrey10,
                borderRadius: BorderRadius.circular(BaseRadius.lg),
              ),
              clipBehavior: Clip.antiAlias,
              child: category.image != null && category.image!.isNotEmpty
                  ? CommonImageView(url: category.image, fit: BoxFit.cover)
                  : const Icon(
                      Icons.category_outlined,
                      size: 36,
                      color: AppColors.lightGrey7,
                    ),
            ),
          ),
          SizedBox(height: BaseSpacing.xs),
          CustomText(
            text: category.name,
            color: AppColors.black2,
            fontSize: AppFontSize.verySmall,
            fontWeight: FontWeight.w600,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          if (category.productCount != null) ...[
            const SizedBox(height: 2),
            CustomText(
              text:
                  '${category.productCount} product${category.productCount == 1 ? '' : 's'}',
              color: AppColors.gray600,
              fontSize: AppFontSize.tiny,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

// ─── No subcategories ────────────────────────────────────────────────────────

class _NoSubcategories extends StatelessWidget {
  final CategoryModel parent;
  final CategoryController controller;
  const _NoSubcategories({required this.parent, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.category_outlined,
            size: 40,
            color: AppColors.lightGrey7,
          ),
          SizedBox(height: BaseSpacing.sm),
          const CustomText(
            text: 'No subcategories',
            color: AppColors.gray600,
            fontSize: AppFontSize.verySmall,
            fontWeight: FontWeight.w600,
          ),
          SizedBox(height: BaseSpacing.sm),
          GestureDetector(
            onTap: () => controller.selectCategory(parent),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: BaseSpacing.md,
                vertical: BaseSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: AppColors.primaryColor,
                borderRadius: BorderRadius.circular(BaseRadius.pill),
              ),
              child: CustomText(
                text: 'Browse ${parent.name}',
                color: AppColors.white,
                fontSize: AppFontSize.tiny,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Empty state ─────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(BaseRadius.xxl),
            ),
            child: Icon(
              Icons.category_outlined,
              size: 40,
              color: AppColors.primaryColor,
            ),
          ),
          SizedBox(height: BaseSpacing.md),
          const CustomText(
            text: 'No categories found',
            color: AppColors.textPrimary,
            fontSize: AppFontSize.small,
            fontWeight: FontWeight.w600,
          ),
          SizedBox(height: BaseSpacing.xxs + 2),
          const CustomText(
            text: 'Check back later',
            color: AppColors.gray600,
            fontSize: AppFontSize.tiny,
            fontWeight: FontWeight.w600,
          ),
        ],
      ),
    );
  }
}

// ─── Shimmer ─────────────────────────────────────────────────────────────────

class _CategorySplitShimmer extends StatelessWidget {
  const _CategorySplitShimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.lightGrey.withOpacity(0.4),
      highlightColor: AppColors.lightGrey.withOpacity(0.7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Rail placeholders
          Container(
            width: 88,
            color: AppColors.background,
            child: Column(
              children: List.generate(
                6,
                (_) => Padding(
                  padding: EdgeInsets.symmetric(vertical: BaseSpacing.sm),
                  child: Column(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(BaseRadius.md),
                        ),
                      ),
                      SizedBox(height: BaseSpacing.xxs + 1),
                      Container(
                        width: 44,
                        height: 9,
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(BaseRadius.xs),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Grid placeholders
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.all(BaseSpacing.md),
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 6,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.92,
              ),
              itemBuilder: (_, __) => Column(
                children: [
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(BaseRadius.lg),
                      ),
                    ),
                  ),
                  SizedBox(height: BaseSpacing.xs),
                  Container(
                    width: 70,
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(BaseRadius.xs),
                    ),
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
