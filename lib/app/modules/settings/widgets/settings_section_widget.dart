import 'package:book_store_app/app/components/custom_text.dart';
import 'package:book_store_app/app/modules/settings/models/settings_section_model.dart';
import 'package:book_store_app/app/modules/settings/widgets/settings_tile_widget.dart';
import 'package:book_store_app/config/resources/app_colors.dart';
import 'package:book_store_app/utils/app_font_size.dart';
import 'package:book_store_app/utils/dimens.dart';
import 'package:flutter/material.dart';

class SettingsSectionWidget extends StatelessWidget {
  final SettingsSection section;
  const SettingsSectionWidget({super.key, required this.section});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimen.allPadding),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: CustomText(
            text: section.header,
            fontSize: AppFontSize.tiny,
            fontWeight: FontWeight.w700,
            color: AppColors.greyDefault,
            letterSpacing: 0.8,
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppDimen.serviceCountTileRadius),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: section.tiles.length,
            separatorBuilder: (_, __) => const Divider(
              height: 1,
              indent: 54,
              color: AppColors.lightGrey2,
            ),
            itemBuilder: (_, i) => SettingsTileWidget(tile: section.tiles[i]),
          ),
        ),
      ]),
    );
  }
}
