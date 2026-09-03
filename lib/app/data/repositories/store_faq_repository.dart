import 'package:book_store_app/app/data/models/store_faq/store_faq_model.dart';
import 'package:book_store_app/app/network/api_constaints.dart';
import 'package:book_store_app/app/network/base_client.dart';
import 'package:flutter/foundation.dart';

/// This store's own FAQ list — `solvexo-api`'s `src/store-faq`. Seller
/// management happens on the web dashboard; this app only reads the public,
/// active-only list for the storefront ("About this Store") page.
class StoreFaqRepository {
  final BaseClient _client = BaseClient();

  // ─── GET /api/public/store-faqs/:storeId — buyer, active only ──────────────

  Future<List<StoreFaqModel>> getPublicFaqs(String storeId) async {
    try {
      final response = await _client.get(ApiConstants.publicStoreFaqs(storeId));
      if (response.data['success'] == true) {
        final list = response.data['data'] as List? ?? [];
        return list.map((e) => StoreFaqModel.fromJson(e as Map<String, dynamic>)).toList();
      }
      return const [];
    } catch (e) {
      debugPrint('❌ public store faqs error: $e');
      return const [];
    }
  }
}
