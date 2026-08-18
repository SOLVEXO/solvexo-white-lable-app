import 'package:book_store_app/app/components/custom_text.dart';
import 'package:book_store_app/app/data/models/bookings/package_purchase_model.dart';
import 'package:book_store_app/config/resources/app_colors.dart';
import 'package:book_store_app/core/theme/base_spacing.dart';
import 'package:book_store_app/utils/app_font_size.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Summary card of every multi-session package the buyer has purchased —
/// one progress row per package, showing remaining/total sessions and
/// expiry. Only rendered by the caller when purchases exist.
class PackageCreditsCard extends StatelessWidget {
  final List<PackagePurchaseModel> packages;

  const PackageCreditsCard({super.key, required this.packages});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(BaseSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryColor.withOpacity(0.08), AppColors.accentColor.withOpacity(0.03)],
        ),
        borderRadius: BorderRadius.circular(BaseRadius.xl),
        border: Border.all(color: AppColors.primaryColor.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(BaseRadius.sm),
                ),
                alignment: Alignment.center,
                child: Icon(Icons.card_giftcard_rounded, color: AppColors.primaryColor, size: 16),
              ),
              SizedBox(width: BaseSpacing.xs),
              CustomText(
                text: 'My Packages',
                color: AppColors.black2,
                fontSize: AppFontSize.extraSmall,
                fontWeight: FontWeight.w700,
              ),
            ],
          ),
          SizedBox(height: BaseSpacing.md),
          ...packages.map(
            (pkg) => Padding(
              padding: EdgeInsets.only(bottom: BaseSpacing.sm),
              child: _PackageRow(package: pkg),
            ),
          ),
        ],
      ),
    );
  }
}

class _PackageRow extends StatelessWidget {
  final PackagePurchaseModel package;

  const _PackageRow({required this.package});

  Color get _progressColor {
    if (!package.isUsable) return AppColors.lightGrey;
    final ratio = package.sessionsTotal == 0 ? 0.0 : package.sessionsRemaining / package.sessionsTotal;
    if (ratio <= 0.2) return AppColors.orange;
    return AppColors.greenSuccess;
  }

  String get _subtitle {
    if (package.status == 'expired') return 'Expired';
    if (package.status == 'fully_used') return 'Fully used';
    if (package.status == 'cancelled') return 'Cancelled';
    return 'Expires ${DateFormat('MMM d, yyyy').format(package.expiresAt)}';
  }

  @override
  Widget build(BuildContext context) {
    final ratio = package.sessionsTotal == 0 ? 0.0 : package.sessionsRemaining / package.sessionsTotal;

    return Container(
      padding: EdgeInsets.all(BaseSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(BaseRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: CustomText(
                  text: package.service?.name ?? 'Service package',
                  color: AppColors.black2,
                  fontSize: AppFontSize.tiny,
                  fontWeight: FontWeight.w700,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: BaseSpacing.xs),
              CustomText(
                text: '${package.sessionsRemaining}/${package.sessionsTotal} left',
                color: _progressColor,
                fontSize: AppFontSize.tiny,
                fontWeight: FontWeight.w800,
              ),
            ],
          ),
          SizedBox(height: BaseSpacing.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(BaseRadius.pill),
            child: LinearProgressIndicator(
              value: ratio.clamp(0, 1),
              minHeight: 6,
              backgroundColor: AppColors.lightGrey2,
              valueColor: AlwaysStoppedAnimation<Color>(_progressColor),
            ),
          ),
          SizedBox(height: BaseSpacing.xxs),
          CustomText(
            text: _subtitle,
            color: package.isUsable ? AppColors.gray600 : AppColors.red,
            fontSize: AppFontSize.tiny,
            fontWeight: FontWeight.w500,
          ),
        ],
      ),
    );
  }
}
