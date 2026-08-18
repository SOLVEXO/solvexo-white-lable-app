import 'package:book_store_app/app/data/services/branding_service.dart';
import 'package:get/get.dart';

class AppImages {
  static const String _baseImagePath = "assets/images/";
  static const String userImage = '${_baseImagePath}account.jpeg';

  /// Tenant-swappable — returns the configured logo URL if one's been set
  /// via `BrandingService` (fed into `CommonImageView`, which loads http(s)
  /// paths as a network image), else the bundled Solvexo asset.
  static String get logoImage {
    if (Get.isRegistered<BrandingService>()) {
      final url = Get.find<BrandingService>().config.value.logoUrl;
      if (url.isNotEmpty) return url;
    }
    return '${_baseImagePath}logo.png';
  }

  static const String transparentLogo = '${_baseImagePath}Logo-transparent.png';
  static const String placeHolderImage =
      '${_baseImagePath}default_image_placeholder.png';
  static const String sampleProduct = '${_baseImagePath}sample-product.png';
  static const String fullLogo = '${_baseImagePath}Edudeen-Logo.webp';
}
