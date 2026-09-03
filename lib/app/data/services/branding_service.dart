import 'dart:async';
import 'dart:convert';

import 'package:book_store_app/app/data/models/branding/branding_config_model.dart';
import 'package:book_store_app/app/data/repositories/branding_repository.dart';
import 'package:book_store_app/config/store_config.dart';
import 'package:book_store_app/shared_prefrences/app_prefrences.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

/// Single source of truth for this app build's white-label branding —
/// `AppColors`'s tenant-swappable colors and every store-name/logo call site
/// all read through here instead of hardcoded values.
///
/// `Get.put(BrandingService(), permanent: true)` before `runApp` in
/// `main.dart` (mirrors this codebase's other early/global services); read
/// anywhere via `Get.find<BrandingService>()`.
class BrandingService extends GetxController {
  final BrandingRepository _repository = BrandingRepository();

  final Rx<BrandingConfigModel> config = Rx<BrandingConfigModel>(
    StoreConfig.toBrandingConfig(),
  );

  /// Seeds from this build's compile-time [StoreConfig] first (so the very
  /// first frame already paints the right store's brand, synchronously, no
  /// network involved), then layers a previously-cached backend override on
  /// top if one exists, then refreshes from the backend in the background —
  /// silently keeping whatever's already showing on any failure (see
  /// `BrandingRepository`, the endpoint doesn't exist yet).
  Future<void> init() async {
    final cachedJson = await AppPreferences.getBrandingConfigJson();
    if (cachedJson != null && cachedJson.isNotEmpty) {
      try {
        config.value = BrandingConfigModel.fromJson(
          jsonDecode(cachedJson) as Map<String, dynamic>,
        );
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

  /// Overlays this store's real, live name (resolved from the backend by
  /// `CurrentStoreService`, see main.dart) onto whatever's already showing —
  /// so the app never keeps displaying `StoreConfig`'s compile-time name
  /// once the actual, current name is known (e.g. after the seller renames
  /// their store, without needing a new app build).
  void applyStoreName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    config.value = config.value.copyWith(
      appName: trimmed,
      storeDisplayName: trimmed,
    );
  }

  bool isFeatureEnabled(String key) => config.value.isFeatureEnabled(key);
}
