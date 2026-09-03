import 'package:flutter/material.dart';

/// App-wide white-label branding — distinct from a single seller's own store
/// branding (`StoreModel.logo`/name/colors), which is unrelated and stays as
/// it is. This describes who operates *this build of the app itself*.
///
/// No backend endpoint for this exists yet (see `BrandingRepository`) — the
/// shape below is what Phase 4 needs from the platform-config/tenant team;
/// [BrandingConfigModel.defaults] is a brand-neutral last resort, never any
/// specific tenant's name — a build should never fall back to rendering a
/// *different* store's (or the platform operator's own) brand.
class BrandingConfigModel {
  final String appName;

  /// This store's own display name (e.g. shown in "About {storeDisplayName}"
  /// and the AI shopping-assistant's persona) — was named `marketplaceName`
  /// before the single-store conversion; renamed since this app never spans
  /// multiple sellers.
  final String storeDisplayName;

  /// Empty string means "use the bundled default asset" — see `AppImages.logoImage`.
  final String logoUrl;

  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;

  /// App-wide UI feature toggles (UI-level only — this never replaces a real
  /// backend entitlement/permission check). Unknown keys default to enabled
  /// via [isFeatureEnabled] so a flag missing from the backend response never
  /// hides a feature by accident.
  final Map<String, bool> featureFlags;

  const BrandingConfigModel({
    required this.appName,
    required this.storeDisplayName,
    required this.logoUrl,
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
    required this.featureFlags,
  });

  bool isFeatureEnabled(String key) => featureFlags[key] ?? true;

  factory BrandingConfigModel.defaults() => const BrandingConfigModel(
    appName: 'Store',
    storeDisplayName: 'Store',
    logoUrl: '',
    primaryColor: Color.fromARGB(255, 217, 120, 87),
    secondaryColor: Color(0xFF6FBF4A),
    accentColor: Color(0xFFd97757),
    featureFlags: {},
  );

  BrandingConfigModel copyWith({
    String? appName,
    String? storeDisplayName,
    String? logoUrl,
    Color? primaryColor,
    Color? secondaryColor,
    Color? accentColor,
    Map<String, bool>? featureFlags,
  }) {
    return BrandingConfigModel(
      appName: appName ?? this.appName,
      storeDisplayName: storeDisplayName ?? this.storeDisplayName,
      logoUrl: logoUrl ?? this.logoUrl,
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      accentColor: accentColor ?? this.accentColor,
      featureFlags: featureFlags ?? this.featureFlags,
    );
  }

  /// Builds branding from this app build's compile-time [StoreConfig] values
  /// (Phase 8 of the white-label conversion — one app binary per store).
  /// Blank strings/unparseable colors fall back to [defaults] field-by-field,
  /// same rule as [fromJson], so an unconfigured build renders identically
  /// to today's app. No logo param — the app logo is always the bundled
  /// `AppImages.logoImage` asset now, never runtime config (see
  /// STORE_ONBOARDING.md); a new store's logo is set by replacing that file.
  factory BrandingConfigModel.fromStoreConfig({
    required String appName,
    required String storeDisplayName,
    required String? primaryColorHex,
    required String? secondaryColorHex,
    required String? accentColorHex,
  }) {
    final defaults = BrandingConfigModel.defaults();
    return BrandingConfigModel(
      appName: appName.trim().isNotEmpty ? appName : defaults.appName,
      storeDisplayName: storeDisplayName.trim().isNotEmpty
          ? storeDisplayName
          : defaults.storeDisplayName,
      logoUrl: defaults.logoUrl,
      primaryColor: _parseColor(primaryColorHex) ?? defaults.primaryColor,
      secondaryColor: _parseColor(secondaryColorHex) ?? defaults.secondaryColor,
      accentColor: _parseColor(accentColorHex) ?? defaults.accentColor,
      featureFlags: const {},
    );
  }

  factory BrandingConfigModel.fromJson(Map<String, dynamic> json) {
    final defaults = BrandingConfigModel.defaults();
    return BrandingConfigModel(
      appName: (json['appName'] as String?)?.trim().isNotEmpty == true
          ? json['appName'] as String
          : defaults.appName,
      storeDisplayName:
          (json['storeDisplayName'] as String?)?.trim().isNotEmpty == true
          ? json['storeDisplayName'] as String
          : defaults.storeDisplayName,
      logoUrl: (json['logoUrl'] as String?) ?? defaults.logoUrl,
      primaryColor: _parseColor(json['primaryColor']) ?? defaults.primaryColor,
      secondaryColor:
          _parseColor(json['secondaryColor']) ?? defaults.secondaryColor,
      accentColor: _parseColor(json['accentColor']) ?? defaults.accentColor,
      featureFlags:
          (json['featureFlags'] as Map?)?.map(
            (k, v) => MapEntry(k.toString(), v == true),
          ) ??
          defaults.featureFlags,
    );
  }

  Map<String, dynamic> toJson() => {
    'appName': appName,
    'storeDisplayName': storeDisplayName,
    'logoUrl': logoUrl,
    'primaryColor':
        '#${primaryColor.value.toRadixString(16).padLeft(8, '0').substring(2)}',
    'secondaryColor':
        '#${secondaryColor.value.toRadixString(16).padLeft(8, '0').substring(2)}',
    'accentColor':
        '#${accentColor.value.toRadixString(16).padLeft(8, '0').substring(2)}',
    'featureFlags': featureFlags,
  };

  /// Accepts `#RRGGBB`/`#AARRGGBB` (leading `#` optional).
  static Color? _parseColor(dynamic value) {
    if (value is! String || value.isEmpty) return null;
    final hex = value.startsWith('#') ? value.substring(1) : value;
    final normalized = hex.length == 6 ? 'FF$hex' : hex;
    final parsed = int.tryParse(normalized, radix: 16);
    return parsed == null ? null : Color(parsed);
  }
}
