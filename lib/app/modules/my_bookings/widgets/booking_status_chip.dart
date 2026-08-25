import 'package:book_store_app/app/components/custom_text.dart';
import 'package:book_store_app/config/resources/app_colors.dart';
import 'package:book_store_app/config/resources/app_text_styles.dart';
import 'package:book_store_app/core/theme/base_spacing.dart';
import 'package:book_store_app/utils/app_font_size.dart';
import 'package:flutter/material.dart';

/// Small tinted pill reflecting a booking's lifecycle status.
class BookingStatusChip extends StatelessWidget {
  final String status; // pending_payment | confirmed | completed | cancelled_by_buyer | cancelled_by_seller | no_show

  const BookingStatusChip({super.key, required this.status});

  Color get _color => switch (status) {
        'pending_payment' => AppColors.orange,
        'confirmed' => AppColors.blue,
        'completed' => AppColors.greenSuccess,
        'cancelled_by_buyer' || 'cancelled_by_seller' => AppColors.red,
        'no_show' => AppColors.gray600,
        _ => AppColors.gray600,
      };

  String get _label => switch (status) {
        'pending_payment' => 'Pending',
        'confirmed' => 'Confirmed',
        'completed' => 'Completed',
        'cancelled_by_buyer' => 'Cancelled',
        'cancelled_by_seller' => 'Cancelled by Store',
        'no_show' => 'No Show',
        _ => status,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: BaseSpacing.xs, vertical: BaseSpacing.xxs),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(BaseRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: _color, shape: BoxShape.circle),
          ),
          SizedBox(width: BaseSpacing.xxs),
          CustomText(
            text: _label,
            color: _color,
            fontSize: AppFontSize.tiny,
            fontWeight: FontWeight.w700,
            fontFamily: AppTextStyles.monoFontFamily,
          ),
        ],
      ),
    );
  }
}
