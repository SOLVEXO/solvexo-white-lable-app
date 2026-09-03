import 'package:book_store_app/app/data/services/branding_service.dart';
import 'package:book_store_app/utils/toast_util.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:get/get.dart';

/// Base for controllers backing a static-content screen (About, Privacy
/// Policy, Terms, ...) whose body is a bundled HTML asset — loads the asset
/// string into [htmlContent] behind [isLoading], substituting `{{APP_NAME}}`
/// with this build's actual store name (see `BrandingService`) so these
/// static pages never need a hardcoded brand name baked into the HTML file
/// itself.
abstract class HtmlAssetController extends GetxController {
  /// Path to the bundled HTML asset, e.g. `assets/html/about.html`.
  String get assetPath;

  final RxBool isLoading = true.obs;
  final RxString htmlContent = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadContent();
  }

  Future<void> loadContent() async {
    try {
      isLoading.value = true;
      final raw = await rootBundle.loadString(assetPath);
      final appName = Get.find<BrandingService>().config.value.appName;
      htmlContent.value = raw.replaceAll('{{APP_NAME}}', appName);
    } catch (e) {
      debugPrint('❌ Error loading $assetPath: $e');
      ToastUtil.showToast('Failed to load content');
    } finally {
      isLoading.value = false;
    }
  }
}
