import 'package:book_store_app/app/components/custom_text.dart';
import 'package:book_store_app/app/components/svg_icon.dart';
import 'package:book_store_app/config/resources/app_icons.dart';
import 'package:book_store_app/core/theme/base_colors.dart';
import 'package:book_store_app/core/theme/base_spacing.dart';
import 'package:book_store_app/utils/app_font_size.dart';
import 'package:flutter/material.dart';
import 'package:book_store_app/config/resources/app_colors.dart';

/// The one empty-state screen every redesigned list/screen should use —
/// icon, title, subtitle, and an optional call-to-action.
class BaseEmptyView extends StatelessWidget {
  final IconData icon;
  final String assetName;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool isIcon;

  const BaseEmptyView({
    super.key,
    this.assetName = AppIcons.calenderIcon,
    this.title = "Nothing here yet",
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.isIcon = true,
    this.icon = Icons.hourglass_empty,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark
        ? BaseColors.onSurfaceMutedDark
        : BaseColors.onSurfaceMutedLight;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(BaseSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    BaseColors.primary.withOpacity(0.12),
                    BaseColors.accent.withOpacity(0.06),
                  ],
                ),
                borderRadius: BorderRadius.circular(BaseRadius.xl),
              ),
              alignment: Alignment.center,
              child: isIcon
                  ? Icon(icon, size: 38, color: BaseColors.primary)
                  : SvgIcon(
                      assetName: assetName,
                      size: 38,
                      color: BaseColors.primary,
                    ),
            ),
            const SizedBox(height: BaseSpacing.lg),
            CustomText(
              text: title,
              fontSize: AppFontSize.regular,
              fontWeight: FontWeight.w600,
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: BaseSpacing.xs),
              CustomText(
                text: subtitle!,
                color: muted,
                fontSize: AppFontSize.extraSmall,
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: BaseSpacing.lg),
              FilledButton(
                onPressed: onAction,
                style: FilledButton.styleFrom(
                  backgroundColor: BaseColors.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: BaseSpacing.xl,
                    vertical: BaseSpacing.md,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(BaseRadius.md),
                  ),
                ),
                child: CustomText(
                  text: actionLabel!,
                  color: AppColors.white,
                  fontSize: AppFontSize.extraSmall,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
