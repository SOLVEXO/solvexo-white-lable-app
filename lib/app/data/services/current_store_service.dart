import 'package:book_store_app/app/data/models/storefront/storefront_model.dart';
import 'package:book_store_app/app/data/repositories/storefront_repository.dart';
import 'package:book_store_app/config/store_config.dart';
import 'package:get/get.dart';

/// Resolves this app build's one store — `StoreConfig.storeSlug` (compile-
/// time) → a real `storeId`/name/logo (runtime, via `getStoreBySlug`) — once,
/// and shares the result app-wide. Every screen that needs "which store is
/// this app" (Home, Search, Category, the store info page, the direct-chat
/// shortcut) should read this instead of resolving its own copy, so there's
/// exactly one network call and one source of truth.
///
/// On an unconfigured/default build (`StoreConfig.isConfigured == false`,
/// e.g. a plain `flutter run` with no store dart-define) [store] stays null
/// forever — callers already treat that as "nothing to scope to" the same
/// way they did before this service existed.
class CurrentStoreService extends GetxController {
  final StorefrontRepository _repo = StorefrontRepository();

  final Rx<StorefrontModel?> store = Rx(null);

  bool _resolveAttempted = false;
  Future<void>? _resolving;

  String? get storeId => store.value?.storeId;
  String? get storeName => store.value?.name;

  /// Idempotent — safe to call from multiple screens; only the first call
  /// actually hits the network, every other call awaits the same result.
  Future<void> ensureResolved() {
    if (_resolveAttempted) return _resolving ?? Future.value();
    if (!StoreConfig.isConfigured) return Future.value();
    _resolveAttempted = true;
    return _resolving = _resolve();
  }

  Future<void> _resolve() async {
    store.value = await _repo.getStoreBySlug(StoreConfig.storeSlug);
  }
}
