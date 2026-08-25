class AppImages {
  static const String _baseImagePath = "assets/images/";
  static const String userImage = '${_baseImagePath}account.jpeg';

  /// This app's logo — always this bundled asset, never a network URL. A new
  /// store sets its own logo by replacing this file directly (see
  /// STORE_ONBOARDING.md), not through runtime config — every screen that
  /// shows the logo (splash, app bar, login, toasts) reads this one constant.
  static const String logoImage = '${_baseImagePath}logo.png';

  static const String transparentLogo = '${_baseImagePath}Logo-transparent.png';
  static const String placeHolderImage =
      '${_baseImagePath}default_image_placeholder.png';
  static const String sampleProduct = '${_baseImagePath}sample-product.png';
  static const String fullLogo = '${_baseImagePath}Edudeen-Logo.webp';
}
