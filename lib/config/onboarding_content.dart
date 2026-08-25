import 'package:flutter/material.dart';

/// This app's first-launch onboarding slides — hardcoded per store build,
/// no backend call and no network image (replaces the old admin-managed
/// `GET /api/onboarding-slides`). Every store's app shows the same
/// onboarding flow structure with its own copy.
///
/// To customize for a new store: edit the [onboardingSlides] list below —
/// each slide is a short title/subtitle plus either a Material [icon] (the
/// default; needs no artwork, just tints with the store's own primary
/// color) or a bundled [OnboardingSlideContent.imageAsset] path if the
/// store wants its own illustration instead (drop the file under
/// `assets/images/onboarding/` and list it in `pubspec.yaml`'s `assets:`).
/// See `STORE_ONBOARDING.md` for the full new-store checklist.
class OnboardingSlideContent {
  final String title;
  final String subtitle;
  final IconData icon;

  /// Optional — a bundled asset path (e.g.
  /// `'assets/images/onboarding/slide1.png'`). When set, this renders
  /// instead of [icon].
  final String? imageAsset;

  const OnboardingSlideContent({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.imageAsset,
  });
}

const List<OnboardingSlideContent> onboardingSlides = [
  OnboardingSlideContent(
    title: 'Discover What You Love',
    subtitle: 'Browse a catalog picked just for you, updated all the time.',
    icon: Icons.storefront_rounded,
  ),
  OnboardingSlideContent(
    title: 'Fast, Reliable Delivery',
    subtitle: 'Track every order from checkout to your doorstep.',
    icon: Icons.local_shipping_rounded,
  ),
  OnboardingSlideContent(
    title: 'Save Your Favorites',
    subtitle: 'Add items to your wishlist and come back to them anytime.',
    icon: Icons.favorite_rounded,
  ),
];
