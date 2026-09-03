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

  Future<void>? _resolving;

  String? get storeId => store.value?.storeId;
  String? get storeName => store.value?.name;

  /// Idempotent — safe to call from multiple screens; concurrent callers
  /// await the same in-flight network call. Only caches a *successful*
  /// resolution — a transient failure (e.g. a network hiccup at cold start)
  /// must not permanently block every storeId-scoped call for the rest of
  /// the app session (login/register, search, categories, banners, ...); the
  /// next caller gets a fresh attempt instead of silently no-op-ing forever.
  Future<void> ensureResolved() {
    if (store.value != null) return Future.value();
    if (!StoreConfig.isConfigured) return Future.value();
    return _resolving ??= _resolve().whenComplete(() {
      if (store.value == null) _resolving = null;
    });
  }

  Future<void> _resolve() async {
    store.value = await _repo.getStoreBySlug(StoreConfig.storeSlug);
  }
}
