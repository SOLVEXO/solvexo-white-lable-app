import 'package:flutter/material.dart';
import 'base_colors.dart';
import 'base_spacing.dart';
import 'base_typography.dart';

/// Material 3 `ThemeData` for both brightness modes — the single source of
/// truth `AppTheme.lightTheme`/`AppTheme.darkTheme` delegate to, so existing
/// screens (which reference `AppTheme.lightTheme` via `main.dart`) keep
/// working unchanged while gaining the new token system underneath.
class BaseTheme {
  BaseTheme._();

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final surface = isDark ? BaseColors.surfaceDark : BaseColors.surfaceLight;
    final background = isDark ? BaseColors.backgroundDark : BaseColors.backgroundLight;
    final onSurface = isDark ? BaseColors.onSurfaceDark : BaseColors.onSurfaceLight;
    final border = isDark ? BaseColors.borderDark : BaseColors.borderLight;

    final colorScheme = ColorScheme.fromSeed(
      seedColor: BaseColors.primary,
      brightness: brightness,
      primary: BaseColors.primary,
      secondary: BaseColors.accent,
      surface: surface,
      error: BaseColors.danger,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      fontFamily: BaseTypography.fontFamily,
      textTheme: BaseTypography.textTheme(brightness),
      dividerColor: isDark ? BaseColors.dividerDark : BaseColors.dividerLight,
      splashFactory: InkSparkle.splashFactory,
      iconTheme: IconThemeData(color: onSurface, size: 22),
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: onSurface,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: BaseTypography.headlineSmall(color: onSurface),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(BaseRadius.lg)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: BaseColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(BaseRadius.md)),
          textStyle: BaseTypography.labelLarge(color: Colors.white),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: BaseColors.primary,
          minimumSize: const Size(double.infinity, 52),
          side: BorderSide(color: border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(BaseRadius.md)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? BaseColors.surfaceVariantDark : BaseColors.surfaceVariantLight,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: BaseTypography.bodyMedium(color: isDark ? BaseColors.onSurfaceMutedDark : BaseColors.onSurfaceMutedLight),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(BaseRadius.md), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(BaseRadius.md), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(BaseRadius.md),
          borderSide: BorderSide(color: BaseColors.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(BaseRadius.md),
          borderSide: const BorderSide(color: BaseColors.danger, width: 1.2),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(BaseRadius.xl)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: onSurface,
        contentTextStyle: BaseTypography.bodyMedium(color: surface),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(BaseRadius.sm)),
      ),
    );
  }
}
