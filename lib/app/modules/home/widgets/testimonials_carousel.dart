import 'package:book_store_app/app/components/custom_text.dart';
import 'package:book_store_app/app/data/models/store/testimonial_model.dart';
import 'package:book_store_app/app/modules/home/controllers/home_controller.dart';
import 'package:book_store_app/config/resources/app_colors.dart';
import 'package:book_store_app/core/theme/base_shadows.dart';
import 'package:book_store_app/core/theme/base_spacing.dart';
import 'package:book_store_app/utils/app_font_size.dart';
import 'package:book_store_app/utils/dimens.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// "What buyers say" — a horizontally-scrolling row of real, backend-sourced
/// testimonials. Renders nothing while unloaded/empty (never fabricated
/// reviews, never a broken section).
class TestimonialsCarousel extends StatelessWidget {
  TestimonialsCarousel({super.key});

  final HomeController controller = Get.find<HomeController>();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final testimonials = controller.testimonials;
      if (testimonials.isEmpty) return const SizedBox.shrink();

      return SizedBox(
        height: 172,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: AppDimen.allPadding),
          itemCount: testimonials.length,
          separatorBuilder: (_, __) => SizedBox(width: BaseSpacing.sm),
          itemBuilder: (_, i) => _TestimonialCard(testimonial: testimonials[i]),
        ),
      );
    });
  }
}

class _TestimonialCard extends StatelessWidget {
  final TestimonialModel testimonial;
  const _TestimonialCard({required this.testimonial});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      padding: EdgeInsets.all(BaseSpacing.sm + 2),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(BaseRadius.lg),
        boxShadow: BaseShadows.forLevel(BaseElevation.level1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(
              5,
              (i) => Icon(
                i < testimonial.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                size: 14,
                color: AppColors.primaryColor,
              ),
            ),
          ),
          SizedBox(height: BaseSpacing.xs),
          Expanded(
            child: CustomText(
              text: testimonial.text,
              color: AppColors.black2,
              fontSize: AppFontSize.tiny,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              height: 1.35,
            ),
          ),
          SizedBox(height: BaseSpacing.xs),
          Row(
            children: [
              Expanded(
                child: CustomText(
                  text: testimonial.storeName != null
                      ? '${testimonial.name} · ${testimonial.storeName}'
                      : testimonial.name,
                  color: AppColors.gray600,
                  fontSize: AppFontSize.tiny,
                  fontWeight: FontWeight.w600,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (testimonial.isVerifiedPurchase) ...[
                SizedBox(width: 4),
                Icon(
                  Icons.verified_rounded,
                  size: 13,
                  color: AppColors.secondryColor,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
