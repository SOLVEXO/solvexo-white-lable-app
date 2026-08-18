import 'package:book_store_app/app/data/models/store_banner/store_banner_model.dart';
import 'package:book_store_app/app/network/api_constaints.dart';
import 'package:book_store_app/app/network/base_client.dart';
import 'package:flutter/foundation.dart';

/// A seller's free, self-managed storefront hero carousel — `solvexo-api`'s
/// `src/store-banner`. The seller-management side (`StoreBannerController`:
/// list/create/update/pause/resume/delete/timeline) has been removed from
/// this app; only the public read used by the buyer-facing storefront stays.
class StoreBannerRepository {
  final BaseClient _client = BaseClient();

  // ─── GET /api/public/store-banners/:storeId — buyer, active only ───────────

  Future<List<StoreBannerModel>> getPublicBanners(String storeId) async {
    try {
      final response = await _client.get(ApiConstants.publicStoreBanners(storeId));
      if (response.data['success'] == true) {
        final list = response.data['data'] as List? ?? [];
        return list.map((e) => StoreBannerModel.fromJson(e as Map<String, dynamic>)).toList();
      }
      return const [];
    } catch (e) {
      debugPrint('❌ public store banners error: $e');
      return const [];
    }
  }
}
