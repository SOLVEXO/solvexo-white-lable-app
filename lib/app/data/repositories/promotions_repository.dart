import 'package:book_store_app/app/network/api_constaints.dart';
import 'package:book_store_app/app/network/base_client.dart';

/// Public tracking beacons for seller-paid ad placements — `solvexo-api`'s
/// `src/promotions` `PublicPromotionsController`. The seller-facing request
/// flow (preview/create/pay/cancel/timeline) was seller-management and has
/// been removed from this app; these beacons stay because the buyer home
/// carousel and public storefront banners still fire them.
class PromotionsRepository {
  final BaseClient _client = BaseClient();

  // ─── Public tracking beacons — fire-and-forget, never surfaced to the user ──

  Future<void> trackImpression({required String entityType, required String entityId, String? device}) async {
    try {
      await _client.post(
        ApiConstants.promotionTrackImpression,
        data: {'entityType': entityType, 'entityId': entityId, if (device != null) 'device': device},
        // `OptionalJwtAuthGuard` on the backend — attaching the token when a
        // buyer happens to be logged in costs nothing and never forces a
        // logout (that only fires on a genuine 401 with `requiresAuth`), but
        // still works for guests since the header is simply omitted then.
        requiresAuth: true,
      );
    } catch (_) {
      // Best-effort — impressions are never worth surfacing an error for.
    }
  }

  Future<void> trackClick({required String entityType, required String entityId, String? device}) async {
    try {
      await _client.post(
        ApiConstants.promotionTrackClick,
        data: {'entityType': entityType, 'entityId': entityId, if (device != null) 'device': device},
        requiresAuth: true,
      );
    } catch (_) {
      // Best-effort — a failed click beacon must never block navigation.
    }
  }
}
