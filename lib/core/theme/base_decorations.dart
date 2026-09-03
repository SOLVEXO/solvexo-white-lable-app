import 'dart:ui';

import 'package:flutter/material.dart';
import 'base_colors.dart';
import 'base_shadows.dart';
import 'base_spacing.dart';
import 'package:book_store_app/config/resources/app_colors.dart';

/// Ready-made [BoxDecoration]s for the premium component library —
/// `BaseDecorations.card(context)`, `.glass(context)`, `.gradient()` — so
/// widgets don't hand-roll `BoxDecoration(...)` with inconsistent radii/shadows.
class BaseDecorations {
  BaseDecorations._();

  static bool _isDark(BuildContext context) => Theme.of(context).brightness == Brightness.dark;

  static BoxDecoration card(BuildContext context, {double radius = BaseRadius.lg, bool elevated = true}) {
    return BoxDecoration(
      color: _isDark(context) ? BaseColors.surfaceDark : BaseColors.surfaceLight,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: elevated ? BaseShadows.sm : BaseShadows.none,
    );
  }

  static BoxDecoration outlinedCard(BuildContext context, {double radius = BaseRadius.lg}) {
    return BoxDecoration(
      color: _isDark(context) ? BaseColors.surfaceDark : BaseColors.surfaceLight,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: _isDark(context) ? BaseColors.borderDark : BaseColors.borderLight),
    );
  }

  static BoxDecoration gradient({Gradient? gradient, double radius = BaseRadius.lg}) {
    return BoxDecoration(
      gradient: gradient ?? BaseColors.primaryGradient,
      borderRadius: BorderRadius.circular(radius),
    );
  }

  static BoxDecoration pill(BuildContext context, {Color? color}) {
    return BoxDecoration(
      color: color ?? (_isDark(context) ? BaseColors.surfaceVariantDark : BaseColors.surfaceVariantLight),
      borderRadius: BorderRadius.circular(BaseRadius.pill),
    );
  }

  /// Frosted-glass surface — pair with a [BackdropFilter] wrapper
  /// ([glassBlur]) for the full effect.
  static BoxDecoration glass(BuildContext context, {double radius = BaseRadius.lg}) {
    return BoxDecoration(
      color: _isDark(context) ? BaseColors.glassDark : BaseColors.glassLight,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: AppColors.white.withOpacity(_isDark(context) ? 0.08 : 0.5)),
    );
  }

  static ImageFilter glassBlur({double sigma = 16}) => ImageFilter.blur(sigmaX: sigma, sigmaY: sigma);

  static const EdgeInsets screenPadding = EdgeInsets.symmetric(horizontal: BaseSpacing.md);
}
