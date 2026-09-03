import 'package:book_store_app/app/data/models/branding/branding_config_model.dart';

/// This repo's one store — hardcoded here directly, not a build-time flag.
///
/// White-label model: each store gets its **own copy of this whole repo**
/// (duplicated on GitHub, not built as a flavor of one shared repo — see
/// STORE_ONBOARDING.md), so there is never more than one store's config to
/// choose between at build time. Setting up a new store's repo means editing
/// the values below directly, the same way `lib/config/onboarding_content.dart`
/// and `AppImages.logoImage` are edited per store.
///
/// [storeSlug] is the one store this app serves — the same slug
/// `StorefrontRepository.getStoreBySlug` resolves to a `storeId` for every
/// subsequent per-store call, so it's the only identifier needed up front.
/// Leaving it blank means this repo has no store bound — see [isConfigured]
/// — which now shows an empty "no store configured" state everywhere
/// content would otherwise load, never a marketplace-wide fallback.
class StoreConfig {
  const StoreConfig._();

  static const String storeSlug = 'jewelery-store';

  // Compile-time fallback only — shown for the brief window before
  // CurrentStoreService resolves this store's real, live name from the
  // backend (see main.dart, which pushes that resolved name into
  // BrandingService once available). Keep this in sync with the store's
  // actual registered name so the fallback never looks wrong either.
  static const String appName = 'Jewelery store';
  static const String storeDisplayName = 'Jewelery store';
  static const String primaryColorHex = '#57D9D5';
  static const String secondaryColorHex = '#6FBF4A';
  static const String accentColorHex = '#57D9D5';

  /// True once a real store has been bound to this repo. False for the
  /// unconfigured template — callers that require a store (Home content,
  /// follow/reviews, etc.) should treat that as "nothing to load" rather
  /// than guessing one.
  static bool get isConfigured => storeSlug.isNotEmpty;

  static BrandingConfigModel toBrandingConfig() => BrandingConfigModel.fromStoreConfig(
    appName: appName,
    storeDisplayName: storeDisplayName,
    primaryColorHex: primaryColorHex,
    secondaryColorHex: secondaryColorHex,
    accentColorHex: accentColorHex,
  );
}
