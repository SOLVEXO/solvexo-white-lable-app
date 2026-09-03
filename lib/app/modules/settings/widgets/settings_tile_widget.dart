import 'package:book_store_app/app/components/custom_text.dart';
import 'package:book_store_app/app/components/svg_icon.dart';
import 'package:book_store_app/app/modules/settings/models/settings_section_model.dart';
import 'package:book_store_app/config/resources/app_colors.dart';
import 'package:book_store_app/config/resources/app_icons.dart';
import 'package:book_store_app/utils/app_font_size.dart';
import 'package:book_store_app/utils/dimens.dart';
import 'package:flutter/material.dart';

class SettingsTileWidget extends StatelessWidget {
  final SettingsTile tile;
  const SettingsTileWidget({super.key, required this.tile});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: tile.onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimen.allPadding,
          vertical: 14,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: tile.isDanger
                    ? AppColors.lightRed
                    : AppColors.background,
                borderRadius: BorderRadius.circular(AppDimen.borderRadius),
              ),
              alignment: Alignment.center,
              child: SvgIcon(
                assetName: tile.icon,
                size: 20,
                color: tile.isDanger ? AppColors.red : AppColors.primaryColor,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: CustomText(
                text: tile.title,
                fontSize: AppFontSize.extraSmall,
                fontWeight: FontWeight.w500,
                color: tile.isDanger ? AppColors.red : AppColors.black,
              ),
            ),
            if (tile.trailing != null) ...[
              const SizedBox(width: 8),
              CustomText(
                text: tile.trailing!,
                fontSize: AppFontSize.verySmall,
                color: tile.isDanger ? AppColors.red : AppColors.lightGrey5,
              ),
            ],
            const SizedBox(width: 6),
            SvgIcon(
              assetName: AppIcons.chevronRight,
              size: 18,
              color: tile.isDanger ? AppColors.red : AppColors.lightGrey5,
            ),
          ],
        ),
      ),
    );
  }
}
