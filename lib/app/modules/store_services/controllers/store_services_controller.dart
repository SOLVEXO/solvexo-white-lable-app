import 'package:book_store_app/app/data/models/bookings/bookable_service_model.dart';
import 'package:book_store_app/app/data/repositories/bookings_repository.dart';
import 'package:book_store_app/app/data/services/current_store_service.dart';
import 'package:get/get.dart';

/// Public, storeId-scoped list of a store's bookable services — the buyer
/// lands here from the storefront's services teaser or directly, and taps
/// through to a service's booking screen.
class StoreServicesController extends GetxController {
  final BookingsRepository _repo = BookingsRepository();

  late final String storeId;
  late final String storeName;

  final RxBool isLoading = true.obs;
  final RxList<BookableServiceModel> services = <BookableServiceModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    _readArgs();
    _load();
  }

  // Prefers whatever storeId/storeName the caller passed (e.g. the
  // storefront's services teaser, a push-notification deep link) — falling
  // back to this app's own resolved store (`CurrentStoreService`, already
  // resolved in the background since app launch by the time a buyer has
  // navigated this deep) so this screen also works as a standalone entry
  // point. Read synchronously (not awaited) so `storeId`/`storeName` are
  // always set before this returns — the view reads them unconditionally in
  // its AppBar, not behind an `isLoading` guard.
  void _readArgs() {
    final args = Get.arguments;
    var id = args is Map ? args['storeId'] as String? ?? '' : '';
    var name = args is Map ? args['storeName'] as String? ?? '' : '';

    if (id.isEmpty) {
      final currentStore = Get.find<CurrentStoreService>();
      id = currentStore.storeId ?? '';
      name = currentStore.storeName ?? '';
    }

    storeId = id;
    storeName = name.isNotEmpty ? name : 'Store';
  }

  Future<void> _load() async {
    if (storeId.isEmpty) {
      isLoading.value = false;
      return;
    }
    isLoading.value = true;
    services.assignAll(await _repo.browseStoreServices(storeId));
    isLoading.value = false;
  }

  @override
  Future<void> refresh() => _load();
}
