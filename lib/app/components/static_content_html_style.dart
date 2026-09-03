import 'package:book_store_app/config/resources/app_colors.dart';
import 'package:book_store_app/config/resources/app_text_styles.dart';
import 'package:book_store_app/core/theme/base_spacing.dart';
import 'package:book_store_app/utils/app_font_size.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

/// Shared styling for static-content screens (About, Privacy Policy, ...)
/// that render a bundled HTML asset — keeps it in the app's own type
/// scale/colors instead of browser defaults.
final Map<String, Style> staticContentHtmlStyle = {
  "body": Style(
    fontFamily: AppTextStyles.fontFamily,
    color: AppColors.black2,
    fontSize: FontSize(AppFontSize.extraSmall),
    margin: Margins.zero,
  ),
  "h1": Style(
    color: AppColors.black,
    fontSize: FontSize(AppFontSize.veryLarge),
    fontWeight: FontWeight.w700,
    margin: Margins.only(bottom: BaseSpacing.sm),
  ),
  "h2": Style(
    color: AppColors.black,
    fontSize: FontSize(AppFontSize.regular),
    fontWeight: FontWeight.w700,
    margin: Margins.only(top: BaseSpacing.lg, bottom: BaseSpacing.xs),
  ),
  "p": Style(margin: Margins.only(bottom: BaseSpacing.sm)),
  "ul": Style(margin: Margins.only(bottom: BaseSpacing.sm)),
  "li": Style(margin: Margins.only(bottom: BaseSpacing.xxs)),
  "a": Style(color: AppColors.primaryColor, textDecoration: TextDecoration.none),
  "strong": Style(fontWeight: FontWeight.w700),
  "em": Style(color: AppColors.greyDefault),
};
