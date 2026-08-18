import 'package:book_store_app/app/data/models/branding/branding_config_model.dart';
import 'package:book_store_app/app/network/api_constaints.dart';
import 'package:book_store_app/app/network/base_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Fetches this app build's white-label branding. `ApiConstants.brandingConfig`
/// doesn't exist on the backend yet (see that constant's doc comment) — every
/// failure (404 included) is swallowed here and treated as "no override
/// available", never surfaced to the user, so `BrandingService` can always
/// fall back to `BrandingConfigModel.defaults()` or the last cached config.
class BrandingRepository {
  final BaseClient _client = BaseClient();

  Future<BrandingConfigModel?> getBrandingConfig() async {
    try {
      final response = await _client.get(
        ApiConstants.brandingConfig,
        requiresAuth: false,
      );
      if (response.data['success'] == true) {
        return BrandingConfigModel.fromJson(response.data['data'] as Map<String, dynamic>);
      }
      return null;
    } on DioException catch (e) {
      debugPrint('ℹ️ Branding config not available (${e.response?.statusCode}) — using defaults/cache.');
      return null;
    } catch (e) {
      debugPrint('ℹ️ Branding config fetch error: $e — using defaults/cache.');
      return null;
    }
  }
}
