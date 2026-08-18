import 'package:book_store_app/app/components/custom_text.dart';
import 'package:book_store_app/app/data/models/announcement_model.dart';
import 'package:book_store_app/config/resources/app_colors.dart';
import 'package:book_store_app/core/theme/base_spacing.dart';
import 'package:book_store_app/utils/app_font_size.dart';
import 'package:flutter/material.dart';

/// Small dismissible strip for a single active platform announcement —
/// shared by the buyer home (audience='buyers') and seller home
/// (audience='sellers'). Purely presentational: the owning screen's
/// controller holds the fetched list + dismissed flag and passes the first
/// item in here, so this stays a StatelessWidget per the app's convention.
class AnnouncementBanner extends StatelessWidget {
  final AnnouncementModel? announcement;
  final VoidCallback onDismiss;

  const AnnouncementBanner({
    super.key,
    required this.announcement,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final item = announcement;
    if (item == null) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.fromLTRB(
        BaseSpacing.md,
        BaseSpacing.sm,
        BaseSpacing.md,
        0,
      ),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: BaseSpacing.sm + 2,
          vertical: BaseSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.primaryColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(BaseRadius.lg),
          border: Border.all(color: AppColors.primaryColor.withOpacity(0.25)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.campaign_rounded,
                size: 18,
                color: AppColors.primaryColor,
              ),
            ),
            SizedBox(width: BaseSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    text: item.title,
                    color: AppColors.black2,
                    fontSize: AppFontSize.verySmall,
                    fontWeight: FontWeight.w700,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: BaseSpacing.xxs / 2),
                  CustomText(
                    text: item.message,
                    color: AppColors.gray600,
                    fontSize: AppFontSize.tiny,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            SizedBox(width: BaseSpacing.xs),
            GestureDetector(
              onTap: onDismiss,
              behavior: HitTestBehavior.opaque,
              child: const SizedBox(
                width: 32,
                height: 32,
                child: Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: AppColors.gray600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
