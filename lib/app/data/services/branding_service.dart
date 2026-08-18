import 'dart:async';
import 'dart:convert';

import 'package:book_store_app/app/data/models/branding/branding_config_model.dart';
import 'package:book_store_app/app/data/repositories/branding_repository.dart';
import 'package:book_store_app/shared_prefrences/app_prefrences.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

/// Single source of truth for this app build's white-label branding —
/// `AppColors`'s tenant-swappable colors and the marketplace-name/logo call
/// sites all read through here instead of hardcoded values.
///
/// `Get.put(BrandingService(), permanent: true)` before `runApp` in
/// `main.dart` (mirrors this codebase's other early/global services); read
/// anywhere via `Get.find<BrandingService>()`.
class BrandingService extends GetxController {
  final BrandingRepository _repository = BrandingRepository();

  final Rx<BrandingConfigModel> config = Rx<BrandingConfigModel>(BrandingConfigModel.defaults());

  /// Loads the last cached config (if any) for an instant, correct-brand
  /// first paint, then refreshes from the backend in the background —
  /// silently keeping the cache/defaults on any failure (see
  /// `BrandingRepository`, the endpoint doesn't exist yet).
  Future<void> init() async {
    final cachedJson = await AppPreferences.getBrandingConfigJson();
    if (cachedJson != null && cachedJson.isNotEmpty) {
      try {
        config.value = BrandingConfigModel.fromJson(jsonDecode(cachedJson) as Map<String, dynamic>);
      } catch (e) {
        debugPrint('ℹ️ Cached branding config unreadable, using defaults: $e');
      }
    }
    unawaited(refreshFromBackend());
  }

  Future<void> refreshFromBackend() async {
    final fetched = await _repository.getBrandingConfig();
    if (fetched == null) return;
    config.value = fetched;
    await AppPreferences.saveBrandingConfigJson(jsonEncode(fetched.toJson()));
  }

  bool isFeatureEnabled(String key) => config.value.isFeatureEnabled(key);
}
