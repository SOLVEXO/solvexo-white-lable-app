# Onboarding a new store (white-label repo)

This repo is a **complete, single-store app** (iOS + Android) pushed to
GitHub as a template. There is no in-app store picker, no marketplace
browsing, and no build flag/flavor that switches which store an install
belongs to — every value that identifies "which store is this" is
hardcoded directly in source.

**To create a new store's app: duplicate this entire repository into a new
repo dedicated to that store, then edit the values below directly in that
new repo.** Each store gets its own independent repo, its own git history,
and is built/published completely independently of every other store's
repo — there is never more than one store's config in a given checkout.

This is a developer/release-engineering process, done once per new store —
not something an end user or store owner configures inside the app.

## What you need before starting

- The store's real `slug` from the backend (`GET /api/store/public` lists
  every store with its `slug`/`storeId` — see `StorefrontRepository`). The
  app resolves `slug` → `storeId` itself at startup via `getStoreBySlug`,
  so the slug is the only identifier you need up front.
- Brand colors, app name, and a logo image file for that store.
- A **separate Firebase project** for that store (Google Sign-In and FCM
  push notifications are tied to a package name/bundle id + OAuth client
  registered in one specific Firebase project — you cannot reuse another
  store's).
- The applicationId (Android) / bundle id (iOS) you want to publish under,
  e.g. `com.<store>.app`.
- App icon artwork (square, ≥1024×1024) for `flutter_launcher_icons`.

## 1. Store identity & branding — `lib/config/store_config.dart`

Edit the hardcoded values directly:

```dart
class StoreConfig {
  static const String storeSlug = '<real store slug from the backend>';
  static const String appName = 'Acme';
  static const String marketplaceName = 'Acme';
  static const String primaryColorHex = '#112233';
  static const String secondaryColorHex = '#445566';
  static const String accentColorHex = '#112233';
  // ...
}
```

No build flag, no `--dart-define`, no separate config file — this is a
plain Dart source file. `AppColors`/`BaseTheme`/`GetMaterialApp.title`
already read through `BrandingService`, which is seeded from this file
before anything else runs, so changing these values here is the whole job.

## 2. Logo — `assets/images/logo.png`

There is no logo URL/config — the logo is never fetched at runtime.
Replace `assets/images/logo.png` with the new store's logo file directly
(`lib/config/resources/app_images.dart`'s `AppImages.logoImage` constant
points at it) — every screen that shows a logo (splash, app bar, login,
toasts) reads that one bundled asset.

## 3. Android — applicationId, Firebase, icon

In `android/app/build.gradle.kts`'s `defaultConfig`, change:

```kotlin
applicationId = "com.acme.app"
```

Then:
- Replace `android/app/google-services.json` with the new store's own
  Firebase file.
- Update `android/app/src/main/res/values/strings.xml`'s `app_name` to the
  store's name (sets the launcher label).
- Regenerate the launcher icon via `flutter_launcher_icons` (its config is
  in `pubspec.yaml` — point `image_path` at the new store's icon artwork,
  then run `dart run flutter_launcher_icons`).

Build: `flutter build appbundle` (no flags needed — everything is already
baked into this repo).

## 4. iOS — bundle id, Firebase, icon

In Xcode (`ios/Runner.xcworkspace`), change the `Runner` target's
`PRODUCT_BUNDLE_IDENTIFIER` to the store's bundle id (e.g. `com.acme.app`)
across the Debug/Release/Profile configurations, and `CFBundleDisplayName`
in `ios/Runner/Info.plist` to the store's app name. Replace
`ios/Runner/GoogleService-Info.plist` with the new store's own Firebase
file. Regenerate the `AppIcon` asset set (same `flutter_launcher_icons` run
as step 3 covers both platforms).

Build: `flutter build ios` (no flags needed).

## 5. First-launch onboarding content — `lib/config/onboarding_content.dart`

The onboarding carousel a buyer sees on first launch is **hardcoded in this
one Dart file**, not fetched from any backend. Edit the `onboardingSlides`
list for the new store:

```dart
const List<OnboardingSlideContent> onboardingSlides = [
  OnboardingSlideContent(
    title: 'Discover What You Love',
    subtitle: 'Browse a catalog picked just for you, updated all the time.',
    icon: Icons.storefront_rounded,
  ),
  // ...
];
```

Each slide needs a `title`, `subtitle`, and either an `icon` (a Material
icon — the default, needs no artwork, and automatically tints with the
store's own `PRIMARY_COLOR`) or an `imageAsset` path if the store wants its
own illustration instead. To use a custom image: drop the file under
`assets/images/onboarding/`, add it to `pubspec.yaml`'s `assets:` list, and
set `imageAsset: 'assets/images/onboarding/<file>'` on that slide (leave
`icon` off or ignored — `imageAsset` takes priority when set).

## 6. Backend environment (only if this store points at a different API)

`lib/app/network/api_constaints.dart`'s `baseUrl` defaults to
`https://staging.solvexo.store` and can still be overridden per build via
`--dart-define=API_BASE_URL=...` if this store's repo needs to target a
different backend environment (dev/staging/prod) — this is unrelated to
store identity (every store still points at whichever backend it's told
to) and is the one place a build flag is still used, since it's just an
environment switch, not a per-store config choice.

## 7. Verify before publishing

- `flutter analyze` clean.
- Both `flutter build apk` and (on macOS with Xcode set up)
  `flutter build ios` succeed.
- Install the built app on a device/simulator, delete-and-reinstall (or
  clear app data) to see a true first launch, and confirm: onboarding shows
  this store's slides with the right colors, correct name/icon, Home loads
  this store's real banners/products, Google Sign-In succeeds and reaches
  Home.
- Confirm with the backend owner that this store's buyer accounts/orders/
  wishlist/cart are correctly isolated from other stores (each store's repo
  can point at its own backend deployment via step 6, or the shared backend
  must scope this data by store server-side) — this is a backend concern,
  not something this repo's config can fix on its own.
