import 'package:book_store_app/app/components/custom_text.dart';
import 'package:book_store_app/app/modules/category/models/product_model.dart';
import 'package:book_store_app/config/resources/app_colors.dart';
import 'package:book_store_app/config/resources/app_text_styles.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Product Grid Item Widget
class ProductGridItem extends StatelessWidget {
  final ProductModel product;
  final bool isFavourite;
  final VoidCallback onTap;
  final VoidCallback onFavouriteTap;

  const ProductGridItem({
    super.key,
    required this.product,
    required this.isFavourite,
    required this.onTap,
    required this.onFavouriteTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.greyDefault.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: product.images.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: product.images.first,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: AppColors.greySwatch200,
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: AppColors.greySwatch200,
                              child: const Icon(Icons.image_not_supported),
                            ),
                          )
                        : Container(
                            color: AppColors.greySwatch200,
                            child: const Icon(
                              Icons.image,
                              size: 50,
                              color: AppColors.greyDefault,
                            ),
                          ),
                  ),
                ),

                // Favourite Button
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: onFavouriteTap,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.black.withOpacity(0.1),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Icon(
                        isFavourite ? Icons.favorite : Icons.favorite_border,
                        color: isFavourite ? AppColors.red : AppColors.greyDefault,
                        size: 20,
                      ),
                    ),
                  ),
                ),

                // Discount Badge
                // if (product.hasDiscount)
                //   Positioned(
                //     top: 8,
                //     left: 8,
                //     child: Container(
                //       padding: const EdgeInsets.symmetric(
                //         horizontal: 8,
                //         vertical: 4,
                //       ),
                //       decoration: BoxDecoration(
                //         color: Colors.red,
                //         borderRadius: BorderRadius.circular(4),
                //       ),
                //       child: Text(
                //         '-${product.discountPercentage}%',
                //         style: const TextStyle(
                //           color: AppColors.white,
                //           fontSize: 12,
                //           fontWeight: FontWeight.bold,
                //         ),
                //       ),
                //     ),
                //   ),

                // Out of Stock Badge
                if (!product.inStock)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.black.withOpacity(0.5),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                      ),
                      child: const Center(
                        child: CustomText(
                          text: 'Out of Stock',
                          color: AppColors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // Product Details
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Name
                  CustomText(
                    text: product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),

                  const SizedBox(height: 4),

                  // Category
                  if (product.category != null)
                    CustomText(
                      text: product.category!.name,
                      fontSize: 12,
                      color: AppColors.greySwatch600,
                    ),

                  const SizedBox(height: 8),

                  // Rating
                  Row(
                    children: [
                      const Icon(Icons.star, color: AppColors.materialAmber, size: 16),
                      const SizedBox(width: 4),
                      CustomText(
                        text: '${product.totalRatings.toStringAsFixed(1)} (${product.averageRating})',
                        fontSize: 12,
                        color: AppColors.greySwatch600,
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Price
                  Row(
                    children: [
                      CustomText(
                        text: '\$${product.price.toStringAsFixed(2)}',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryColor,
                        fontFamily: AppTextStyles.monoFontFamily,
                      ),

                      // if (product.hasDiscount) ...[
                      //   const SizedBox(width: 8),
                      //   Text(
                      //     '\$${product.price.toStringAsFixed(2)}',
                      //     style: TextStyle(
                      //       fontSize: 14,
                      //       color: AppColors.greyDefault[600],
                      //       decoration: TextDecoration.lineThrough,
                      //     ),
                      //   ),
                      // ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Loading Shimmer Widget
class ProductLoadingShimmer extends StatelessWidget {
  const ProductLoadingShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.greySwatch200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image placeholder
          AspectRatio(
            aspectRatio: 1.2,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.shimmerBase,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 14,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.shimmerBase,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 12,
                  width: 100,
                  decoration: BoxDecoration(
                    color: AppColors.shimmerBase,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 16,
                  width: 80,
                  decoration: BoxDecoration(
                    color: AppColors.shimmerBase,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Empty Products Widget
class EmptyProductsWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const EmptyProductsWidget({
    super.key,
    this.message = 'No products found',
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_bag_outlined, size: 80, color: AppColors.greySwatch400),
          const SizedBox(height: 16),
          CustomText(text: message, fontSize: 16, color: AppColors.greySwatch600),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const CustomText(text: 'Retry')),
          ],
        ],
      ),
    );
  }
}
