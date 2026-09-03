import 'package:book_store_app/app/data/models/bookings/bookable_service_model.dart';
import 'package:book_store_app/app/data/models/bookings/package_purchase_model.dart';
import 'package:book_store_app/app/data/models/bookings/service_availability_model.dart';
import 'package:book_store_app/app/data/models/bookings/service_package_model.dart';
import 'package:book_store_app/app/components/custom_app_snack_bar.dart';
import 'package:book_store_app/app/data/repositories/bookings_repository.dart';
import 'package:book_store_app/app/data/services/auth_gate_service.dart';
import 'package:book_store_app/shared_prefrences/app_prefrences.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

/// Drives a single bookable service's detail + booking flow: service info,
/// date/slot selection, location type, active packages to buy, and any
/// package the buyer already owns for this service (usable as payment for
/// the appointment instead of charging directly).
class StoreServiceDetailController extends GetxController {
  final BookingsRepository _repo = BookingsRepository();

  late final String storeId;
  late final String storeName;
  late final String serviceId;

  final RxBool isLoading = true.obs;
  final Rx<BookableServiceModel?> service = Rx<BookableServiceModel?>(null);

  final RxBool isLoadingPackages = true.obs;
  final RxList<ServicePackageModel> packages = <ServicePackageModel>[].obs;

  final RxBool isLoadingMyPackages = true.obs;
  final RxList<PackagePurchaseModel> usablePackages = <PackagePurchaseModel>[].obs;

  final Rx<DateTime?> selectedDate = Rx<DateTime?>(null);
  final RxBool isLoadingSlots = false.obs;
  final RxList<ServiceSlotModel> slots = <ServiceSlotModel>[].obs;
  final Rx<ServiceSlotModel?> selectedSlot = Rx<ServiceSlotModel?>(null);

  final RxString selectedLocationType = ''.obs;

  /// Id of the owned package to redeem for this booking instead of paying —
  /// empty means "pay for this appointment directly".
  final RxString selectedPackagePurchaseId = ''.obs;

  final RxBool isBooking = false.obs;
  final RxString purchasingPackageId = ''.obs;

  // Plain (non-reactive) buyer input fields — read at submit time only, so
  // typing into them doesn't need to trigger rebuilds. Owned by the address
  // form widget in the view.
  String buyerAddressLine1 = '';
  String buyerCity = '';
  String buyerPhone = '';
  String buyerNote = '';

  @override
  void onInit() {
    super.onInit();
    _readArgs();
    _load();
  }

  void _readArgs() {
    final args = Get.arguments;
    if (args is Map) {
      storeId = args['storeId'] as String? ?? '';
      storeName = args['storeName'] as String? ?? 'Store';
      serviceId = args['serviceId'] as String? ?? '';
    } else {
      storeId = '';
      storeName = 'Store';
      serviceId = '';
    }
  }

  Future<void> _load() async {
    if (storeId.isEmpty || serviceId.isEmpty) {
      isLoading.value = false;
      isLoadingPackages.value = false;
      isLoadingMyPackages.value = false;
      return;
    }
    isLoading.value = true;
    final result = await _repo.getServiceDetail(storeId, serviceId);
    service.value = result;
    if (result != null && result.locationTypes.isNotEmpty) {
      selectedLocationType.value = result.locationTypes.first;
    }
    // `getServiceDetail` already embeds the service's active packages — no
    // separate (and previously seller-only, always-403-for-buyers) call needed.
    packages.assignAll(result?.packages ?? []);
    isLoadingPackages.value = false;
    isLoading.value = false;

    if (result != null) {
      await Future.wait([
        selectDate(DateTime.now()),
        _loadMyPackages(),
      ]);
    } else {
      isLoadingMyPackages.value = false;
    }
  }

  /// Only relevant to a logged-in buyer — guests have no packages to own, and
  /// calling this endpoint unauthenticated would 401 (and, since it's a
  /// `requiresAuth` request, trip the app's forced-logout interceptor) even
  /// though the guest never did anything wrong.
  Future<void> _loadMyPackages() async {
    if (!await AppPreferences.isLoggedIn()) {
      isLoadingMyPackages.value = false;
      return;
    }
    isLoadingMyPackages.value = true;
    final all = await _repo.listMyPackages(storeId: storeId);
    usablePackages.assignAll(all.where((p) => p.serviceId == serviceId && p.isUsable));
    isLoadingMyPackages.value = false;
  }

  void selectLocationType(String type) {
    if (selectedLocationType.value == type) return;
    selectedLocationType.value = type;
  }

  Future<void> selectDate(DateTime date) async {
    selectedDate.value = date;
    selectedSlot.value = null;
    isLoadingSlots.value = true;
    slots.assignAll(await _repo.getSlots(storeId, serviceId, date));
    isLoadingSlots.value = false;
  }

  void selectSlot(ServiceSlotModel slot) {
    if (!slot.isAvailable) return;
    selectedSlot.value = slot;
  }

  /// Toggles whether this booking should be redeemed against [package]
  /// (pass null to switch back to paying directly).
  void useOwnedPackage(PackagePurchaseModel? package) {
    selectedPackagePurchaseId.value = package?.id ?? '';
  }

  bool get canSubmitBooking =>
      service.value != null && selectedDate.value != null && selectedSlot.value != null && !isBooking.value;

  Future<bool> confirmBooking({Map<String, dynamic>? serviceAddress, String? buyerNote}) async {
    final svc = service.value;
    final date = selectedDate.value;
    final slot = selectedSlot.value;
    if (svc == null || date == null || slot == null || isBooking.value) return false;

    final allowed = await AuthGateService.instance.requireAuth(message: 'Login to book this appointment.');
    if (!allowed) return false;

    isBooking.value = true;
    final booking = await _repo.bookAppointment(
      serviceId: svc.id,
      date: DateFormat('yyyy-MM-dd').format(date),
      startTime: slot.startTime,
      locationType: svc.locationTypes.isNotEmpty ? selectedLocationType.value : null,
      packagePurchaseId: selectedPackagePurchaseId.value.isEmpty ? null : selectedPackagePurchaseId.value,
      serviceAddress: serviceAddress,
      buyerNote: buyerNote,
      storeId: storeId,
    );
    isBooking.value = false;

    if (booking != null) {
      final usedPackage = selectedPackagePurchaseId.value.isNotEmpty;
      selectedSlot.value = null;
      selectedPackagePurchaseId.value = '';
      if (usedPackage) await _loadMyPackages();
      // There's no "My Bookings" management screen any more — confirm
      // success here and return to the service page instead.
      CustomAppSnackbar.success('Appointment booked!');
      Get.back();
    }
    return booking != null;
  }

  Future<bool> buyPackage(ServicePackageModel package) async {
    if (purchasingPackageId.value.isNotEmpty) return false;

    final allowed = await AuthGateService.instance.requireAuth(message: 'Login to purchase this package.');
    if (!allowed) return false;

    purchasingPackageId.value = package.id;
    final purchase = await _repo.purchasePackage(package.id, storeId: storeId);
    purchasingPackageId.value = '';
    if (purchase != null) await _loadMyPackages();
    return purchase != null;
  }
}
