import 'package:book_store_app/app/components/custom_text.dart';
import 'package:book_store_app/app/modules/ordertracker/models/tracker_model.dart';
import 'package:book_store_app/config/resources/app_colors.dart';
import 'package:flutter/material.dart';

class TrackingTile extends StatelessWidget {
  final TrackingEvent event;
  final bool isLast;

  const TrackingTile({super.key, required this.event, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 10,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(text: _formatTime(event.time), color: AppColors.gray600),

        /// Timeline
        Column(
          children: [
            Container(
              width: 25,
              height: 25,
              decoration: BoxDecoration(
                color: AppColors.primaryColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, size: 14, color: AppColors.white),
            ),
            if (!isLast)
              Container(width: 2, height: 60, color: AppColors.primaryColor),
          ],
        ),

        /// Content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                text: event.title,
                fontWeight: FontWeight.w600,
              ),
              const SizedBox(height: 4),
              CustomText(
                text: event.description,
                color: AppColors.greySwatch600,
                fontSize: 12,
              ),
              const SizedBox(height: 6),
            ],
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime time) {
    return "${time.hour}:${time.minute.toString().padLeft(2, '0')} PM";
  }
}
