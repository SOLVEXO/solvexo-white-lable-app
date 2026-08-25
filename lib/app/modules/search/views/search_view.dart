import 'package:book_store_app/app/components/app_search_field.dart';
import 'package:book_store_app/app/components/common_image_view.dart';
import 'package:book_store_app/app/components/custom_text.dart';
import 'package:book_store_app/app/components/recommended_product_list.dart';
import 'package:book_store_app/app/components/svg_icon.dart';
import 'package:book_store_app/app/modules/category/controllers/category_controller.dart';
import 'package:book_store_app/app/modules/category/controllers/product_controller.dart';
import 'package:book_store_app/app/modules/home/widgets/horizontal_product_card.dart';
import 'package:book_store_app/app/modules/search/controllers/search_controller.dart';
import 'package:book_store_app/config/resources/app_colors.dart';
import 'package:book_store_app/config/resources/app_icons.dart';
import 'package:book_store_app/core/theme/base_shadows.dart';
import 'package:book_store_app/core/theme/base_spacing.dart';
import 'package:book_store_app/core/widgets/buttons/base_buttons.dart';
import 'package:book_store_app/core/widgets/wave_bottom_nav_bar.dart';
import 'package:book_store_app/utils/app_font_size.dart';
import 'package:book_store_app/utils/dimens.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SearchView extends StatelessWidget {
  SearchView({super.key});

  // Was bare `Get.put(...)` field initializers — those only run once, when
  // this widget instance is first constructed (as one of
  // `BottomNavController.screens`), so if GetX's route-based dependency
  // tracking ever disposes these controllers (e.g. across an
  // `Get.offAllNamed` elsewhere in the app), this widget kept holding a
  // reference to the now-disposed instance with nothing to recreate it —
  // the next tap into a `TextField` bound to its (disposed)
  // `TextEditingController` threw "used after being disposed" and crashed
  // the app. Guarded getters (checked fresh on every `build()`, same as
  // `_categoryController` below) recreate them instead.
  SearchBarController get c {
    if (!Get.isRegistered<SearchBarController>())
      Get.put(SearchBarController());
    return Get.find<SearchBarController>();
  }

  ProductController get productController {
    if (!Get.isRegistered<ProductController>()) Get.put(ProductController());
    return Get.find<ProductController>();
  }

  CategoryController get _categoryController {
    if (!Get.isRegistered<CategoryController>()) {
      Get.put(CategoryController(), permanent: true);
    }
    return Get.find<CategoryController>();
  }

  @override
  Widget build(BuildContext context) {
    double w = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimen.allPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Obx(
                () => AppSearchField(
                  controller: c.textController,
                  onChanged: c.onSearchChanged,
                  onFieldSubmitted: (value) {
                    c.performSearch(value);
                  },
                  suffixIcon: c.searchText.isNotEmpty
                      ? SvgIcon(
                          assetName: AppIcons.cross,
                          color: AppColors.black,
                          onTap: c.clearSearch,
                        )
                      : null,
                  staticHint: 'Search',
                  rotatingHints: _categoryController.categoryTrees
                      .map((cat) => cat.name)
                      .toList(),
                ),
              ),
              // No Results Message
              Obx(() {
                final isEmpty = !c.hasResults;
                if (!(c.showResults.value && !c.loading.value && isEmpty)) {
                  return const SizedBox();
                }
                return Container(
                  padding: EdgeInsets.symmetric(
                    vertical: BaseSpacing.xxl - 2,
                    horizontal: BaseSpacing.xxl - 2,
                  ),
                  child: Center(
                    child: Column(
                      spacing: BaseSpacing.xs,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 80,
                          color: AppColors.shimmerBase,
                        ),
                        CustomText(
                          text: "No Products Found",
                          textAlign: TextAlign.center,
                          color: AppColors.black,
                          fontSize: AppFontSize.small2,
                          fontWeight: FontWeight.w600,
                        ),
                        CustomText(
                          text:
                              "Try different keywords or check our recommendations",
                          textAlign: TextAlign.center,
                          color: AppColors.gray600,
                          fontSize: AppFontSize.tiny,
                        ),
                      ],
                    ),
                  ),
                );
              }),

              // Recent Searches Header
              Obx(
                () => c.searchText.value.isEmpty && !c.showResults.value
                    ? _recentHeader()
                    : const SizedBox(),
              ),

              // Recent Searches List OR Suggestions
              Obx(() {
                if (c.searchText.value.isEmpty && !c.showResults.value) {
                  return _recentSearchList();
                }
                if (c.showSuggestions.value && c.suggestions.isNotEmpty) {
                  return suggestionList();
                }
                return const SizedBox();
              }),

              SizedBox(height: BaseSpacing.xxs + 1),

              // See More/Less Button for Recent Searches
              Obx(
                () => c.searchText.value.isEmpty && !c.showResults.value
                    ? _seeMoreButton()
                    : const SizedBox(),
              ),

              SizedBox(height: BaseSpacing.xl),

              // Section Header (Products/Last Seen/Recommended)
              Obx(() {
                if (c.showResults.value && c.hasResults) {
                  return _sectionHeader("Products (${c.resultsCount})");
                } else if (c.searchText.value.isEmpty &&
                    c.lastSeenProducts.isNotEmpty) {
                  return _sectionHeader("Recently Viewed");
                } else if (c.showSuggestions.value && !c.hasResults) {
                  return _sectionHeader("Recommended Products");
                }
                return const SizedBox();
              }),

              SizedBox(height: BaseSpacing.xs),

              // Main Content Area
              Obx(() {
                if (c.showResults.value) {
                  return Expanded(child: _resultsBody());
                } else if (c.searchText.value.isEmpty) {
                  return _lastSeenList(w);
                } else if (c.showSuggestions.value) {
                  return RecommendedProductList();
                }
                return const SizedBox();
              }),
            ],
          ),
        ),
      ),
    );
  }

  /// Results body — product search results.
  Widget _resultsBody() {
    return Obx(() {
      return c.loading.value
          ? Center(
              child: Padding(
                padding: EdgeInsets.all(BaseSpacing.xxl + BaseSpacing.xl),
                child: const CircularProgressIndicator(),
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.only(bottom: WaveBottomNavBar.totalHeight),
              itemCount: c.filteredProducts.length,
              itemBuilder: (_, i) {
                final prod = c.filteredProducts[i];
                return Padding(
                  padding: EdgeInsets.only(bottom: BaseSpacing.sm),
                  child: HorizontalProductCard(
                    prod: prod,
                    onTap: () {
                      productController.openProductDetails(
                        c.filteredProducts[i],
                      );
                      // Add to recently viewed
                      c.addToRecentlyViewed(prod.id);
                    },
                  ),
                );
              },
            );
    });
  }

  /// Recent searches header
  Widget _recentHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        CustomText(
          text: "Recent Searches",
          color: AppColors.black,
          fontSize: AppFontSize.small2,
          fontWeight: FontWeight.bold,
        ),
        if (c.recentSearches.isNotEmpty)
          GhostButton(label: 'Clear All', onPressed: c.clearRecentSearches),
      ],
    );
  }

  /// Recent searches list
  Widget _recentSearchList() {
    if (c.recentSearches.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: BaseSpacing.xl),
        child: Center(
          child: CustomText(
            text: "No recent searches",
            color: AppColors.gray600,
            fontSize: AppFontSize.extraSmall,
          ),
        ),
      );
    }

    return Column(
      children: c.shownRecentSearches.map((item) {
        return InkWell(
          onTap: () {
            c.textController.text = item;
            c.performSearch(item);
          },
          child: Padding(
            padding: EdgeInsets.only(bottom: BaseSpacing.lg - 5),
            child: Row(
              children: [
                Icon(Icons.access_time, size: 20, color: AppColors.gray600),
                SizedBox(width: BaseSpacing.xs + 2),
                Expanded(
                  child: CustomText(
                    text: item,
                    color: AppColors.black,
                    fontSize: AppFontSize.extraSmall,
                  ),
                ),
                Semantics(
                  button: true,
                  label: 'Remove "$item" from recent searches',
                  child: GestureDetector(
                    onTap: () => c.deleteRecent(item),
                    child: Container(
                      constraints: const BoxConstraints(
                        minHeight: 40,
                        minWidth: 40,
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.close,
                        size: 22,
                        color: AppColors.greyDefault,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  /// See more/less button
  Widget _seeMoreButton() {
    return Obx(
      () => c.recentSearches.length > 4
          ? OutlineButton(
              label: c.showAll.value ? "See less" : "See more",
              onPressed: () => c.toggleSeeMore(),
            )
          : const SizedBox(),
    );
  }

  /// Section header
  Widget _sectionHeader(String text) {
    return CustomText(
      text: text,
      color: AppColors.black,
      fontSize: AppFontSize.small2,
      fontWeight: FontWeight.bold,
    );
  }

  /// Last seen/recently viewed list — hidden entirely until there is real
  /// history (no placeholder thumbnails).
  Widget _lastSeenList(double w) {
    if (c.lastSeenProducts.isEmpty) return const SizedBox();

    // Real backend products
    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: c.lastSeenProducts.length,
        separatorBuilder: (_, __) => SizedBox(width: BaseSpacing.sm),
        itemBuilder: (_, index) {
          final product = c.lastSeenProducts[index];
          return Semantics(
            button: true,
            label: product.name,
            child: GestureDetector(
              // Was a no-op (only a commented-out navigation line) —
              // tapping a recently-viewed thumbnail did nothing at all.
              onTap: () => productController.openProductDetails(product),
              child: Container(
                width: w / 5,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(BaseRadius.md),
                  color: AppColors.shimmerHighlight,
                ),
                child: CommonImageView(
                  url: product.images.isNotEmpty ? product.images.first : null,
                  fit: BoxFit.cover,
                  radius: BorderRadius.circular(BaseRadius.md),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Suggestions list
  Widget suggestionList() {
    return Container(
      margin: EdgeInsets.only(top: BaseSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(BaseRadius.md),
        boxShadow: BaseShadows.forLevel(BaseElevation.level2),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: c.suggestions.length,
        separatorBuilder: (_, __) =>
            const Divider(height: 1, color: AppColors.background, thickness: 1),
        itemBuilder: (_, i) {
          final item = c.suggestions[i];
          return InkWell(
            onTap: () => c.selectSuggestion(item),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: BaseSpacing.xs + 2,
                vertical: BaseSpacing.sm,
              ),
              child: Row(
                children: [
                  SvgIcon(assetName: AppIcons.searchIcon, size: 20),
                  SizedBox(width: BaseSpacing.xs + 2),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomText(
                          text: item.name,
                          color: AppColors.black,
                          fontSize: AppFontSize.extraSmall,
                          fontWeight: FontWeight.w500,
                        ),
                        if (item.category != null) ...[
                          SizedBox(height: BaseSpacing.xxs / 2),
                          CustomText(
                            text: item.category!.name,
                            color: AppColors.gray600,
                            fontSize: AppFontSize.tiny,
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    Icons.north_west,
                    size: 20,
                    color: AppColors.greySwatch400,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
