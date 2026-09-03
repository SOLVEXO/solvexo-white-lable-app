import 'package:book_store_app/app/data/models/bookings/bookable_service_model.dart';
import 'package:book_store_app/app/data/models/bookings/booking_model.dart';
import 'package:book_store_app/app/data/models/bookings/bookings_dashboard_model.dart';
import 'package:book_store_app/app/data/models/bookings/package_purchase_model.dart';
import 'package:book_store_app/app/data/models/bookings/service_availability_model.dart';
import 'package:book_store_app/app/data/models/bookings/service_package_model.dart';
import 'package:book_store_app/app/network/api_constaints.dart';
import 'package:book_store_app/app/network/base_client.dart';
import 'package:book_store_app/app/network/dio_exception_handler.dart';
import 'package:book_store_app/utils/toast_util.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

/// Covers both the seller (`api/bookings/:storeId/*`) and buyer
/// (`api/bookings/public/*`, `api/bookings/my/*`) sides of Services &
/// Bookings — sellers selling appointments/packages directly to buyers,
/// parallel to (not built on) the product/checkout pipeline.
class BookingsRepository {
  final BaseClient _client = BaseClient();
  static const _uuid = Uuid();

  /// `book`/`purchasePackage` move money — an Idempotency-Key means a retry
  /// or double-tap can never double-charge (backend caches the response 24h).
  Map<String, dynamic> get _idempotencyHeader => {'Idempotency-Key': _uuid.v4()};

  // ─── Seller — Services ──────────────────────────────────────────────────

  Future<List<BookableServiceModel>> listSellerServices(String storeId) async {
    try {
      final response = await _client.get(ApiConstants.sellerServices(storeId), requiresAuth: true);
      if (response.data['success'] == true) {
        return (response.data['data'] as List? ?? []).cast<Map<String, dynamic>>().map(BookableServiceModel.fromJson).toList();
      }
      return [];
    } on DioException catch (e) {
      DioExceptionHandler.handleDioException(e);
      return [];
    } catch (e) {
      debugPrint('❌ listSellerServices error: $e');
      ToastUtil.showToast('Failed to load services.');
      return [];
    }
  }

  Future<BookableServiceModel?> createService(String storeId, Map<String, dynamic> body) async {
    try {
      final response = await _client.post(ApiConstants.sellerServices(storeId), data: body, requiresAuth: true);
      if (response.data['success'] == true) {
        ToastUtil.showToast('Service created');
        return BookableServiceModel.fromJson(response.data['data'] as Map<String, dynamic>);
      }
      return null;
    } on DioException catch (e) {
      DioExceptionHandler.handleDioException(e);
      return null;
    } catch (e) {
      debugPrint('❌ createService error: $e');
      ToastUtil.showToast('Failed to create service.');
      return null;
    }
  }

  Future<BookableServiceModel?> updateService(String storeId, String serviceId, Map<String, dynamic> body) async {
    try {
      final response = await _client.patch(ApiConstants.sellerServiceById(storeId, serviceId), data: body, requiresAuth: true);
      if (response.data['success'] == true) {
        ToastUtil.showToast('Service updated');
        return BookableServiceModel.fromJson(response.data['data'] as Map<String, dynamic>);
      }
      return null;
    } on DioException catch (e) {
      DioExceptionHandler.handleDioException(e);
      return null;
    } catch (e) {
      debugPrint('❌ updateService error: $e');
      ToastUtil.showToast('Failed to update service.');
      return null;
    }
  }

  Future<bool> archiveService(String storeId, String serviceId) async {
    try {
      final response = await _client.delete(ApiConstants.sellerServiceById(storeId, serviceId), requiresAuth: true);
      if (response.data['success'] == true) {
        ToastUtil.showToast(response.data['message'] ?? 'Service archived');
        return true;
      }
      return false;
    } on DioException catch (e) {
      DioExceptionHandler.handleDioException(e);
      return false;
    } catch (e) {
      debugPrint('❌ archiveService error: $e');
      ToastUtil.showToast('Failed to archive service.');
      return false;
    }
  }

  // ─── Seller — Availability ──────────────────────────────────────────────

  Future<ServiceAvailabilityModel> getAvailability(String storeId, String serviceId) async {
    try {
      final response = await _client.get(ApiConstants.sellerServiceAvailability(storeId, serviceId), requiresAuth: true);
      if (response.data['success'] == true) {
        return ServiceAvailabilityModel.fromJson(response.data['data'] as Map<String, dynamic>);
      }
      return ServiceAvailabilityModel.empty;
    } on DioException catch (e) {
      DioExceptionHandler.handleDioException(e);
      return ServiceAvailabilityModel.empty;
    } catch (e) {
      debugPrint('❌ getAvailability error: $e');
      ToastUtil.showToast('Failed to load availability.');
      return ServiceAvailabilityModel.empty;
    }
  }

  Future<bool> setAvailability(String storeId, String serviceId, Map<String, dynamic> body) async {
    try {
      final response = await _client.put(ApiConstants.sellerServiceAvailability(storeId, serviceId), data: body, requiresAuth: true);
      if (response.data['success'] == true) {
        ToastUtil.showToast('Availability updated');
        return true;
      }
      return false;
    } on DioException catch (e) {
      DioExceptionHandler.handleDioException(e);
      return false;
    } catch (e) {
      debugPrint('❌ setAvailability error: $e');
      ToastUtil.showToast('Failed to update availability.');
      return false;
    }
  }

  // ─── Seller — Packages ──────────────────────────────────────────────────

  Future<List<ServicePackageModel>> listPackages(String storeId, String serviceId) async {
    try {
      final response = await _client.get(ApiConstants.sellerServicePackages(storeId, serviceId), requiresAuth: true);
      if (response.data['success'] == true) {
        return (response.data['data'] as List? ?? []).cast<Map<String, dynamic>>().map(ServicePackageModel.fromJson).toList();
      }
      return [];
    } on DioException catch (e) {
      DioExceptionHandler.handleDioException(e);
      return [];
    } catch (e) {
      debugPrint('❌ listPackages error: $e');
      ToastUtil.showToast('Failed to load packages.');
      return [];
    }
  }

  Future<ServicePackageModel?> createPackage(String storeId, String serviceId, Map<String, dynamic> body) async {
    try {
      final response = await _client.post(ApiConstants.sellerServicePackages(storeId, serviceId), data: body, requiresAuth: true);
      if (response.data['success'] == true) {
        ToastUtil.showToast('Package created');
        return ServicePackageModel.fromJson(response.data['data'] as Map<String, dynamic>);
      }
      return null;
    } on DioException catch (e) {
      DioExceptionHandler.handleDioException(e);
      return null;
    } catch (e) {
      debugPrint('❌ createPackage error: $e');
      ToastUtil.showToast('Failed to create package.');
      return null;
    }
  }

  Future<ServicePackageModel?> updatePackage(String storeId, String serviceId, String packageId, Map<String, dynamic> body) async {
    try {
      final response = await _client.patch(ApiConstants.sellerServicePackageById(storeId, serviceId, packageId), data: body, requiresAuth: true);
      if (response.data['success'] == true) {
        ToastUtil.showToast('Package updated');
        return ServicePackageModel.fromJson(response.data['data'] as Map<String, dynamic>);
      }
      return null;
    } on DioException catch (e) {
      DioExceptionHandler.handleDioException(e);
      return null;
    } catch (e) {
      debugPrint('❌ updatePackage error: $e');
      ToastUtil.showToast('Failed to update package.');
      return null;
    }
  }

  Future<bool> archivePackage(String storeId, String serviceId, String packageId) async {
    try {
      final response = await _client.delete(ApiConstants.sellerServicePackageById(storeId, serviceId, packageId), requiresAuth: true);
      if (response.data['success'] == true) {
        ToastUtil.showToast(response.data['message'] ?? 'Package archived');
        return true;
      }
      return false;
    } on DioException catch (e) {
      DioExceptionHandler.handleDioException(e);
      return false;
    } catch (e) {
      debugPrint('❌ archivePackage error: $e');
      ToastUtil.showToast('Failed to archive package.');
      return false;
    }
  }

  // ─── Seller — Bookings management ───────────────────────────────────────

  Future<BookingsDashboardModel> getSellerDashboard(String storeId) async {
    try {
      final response = await _client.get(ApiConstants.sellerBookingsDashboard(storeId), requiresAuth: true);
      if (response.data['success'] == true) {
        return BookingsDashboardModel.fromJson(response.data['data'] as Map<String, dynamic>);
      }
      return BookingsDashboardModel.empty;
    } on DioException catch (e) {
      DioExceptionHandler.handleDioException(e);
      return BookingsDashboardModel.empty;
    } catch (e) {
      debugPrint('❌ getSellerDashboard error: $e');
      ToastUtil.showToast('Failed to load bookings dashboard.');
      return BookingsDashboardModel.empty;
    }
  }

  Future<({List<BookingModel> bookings, int total, int pages})> listSellerBookings(
    String storeId, {
    int page = 1,
    int limit = 20,
    String? status,
    String? serviceId,
    String? date,
  }) async {
    try {
      final response = await _client.get(
        ApiConstants.sellerBookings(storeId),
        queryParameters: {
          'page': page,
          'limit': limit,
          if (status != null) 'status': status,
          if (serviceId != null) 'serviceId': serviceId,
          if (date != null) 'date': date,
        },
        requiresAuth: true,
      );
      if (response.data['success'] == true) {
        final data = response.data['data'] as Map<String, dynamic>;
        final pagination = data['pagination'] as Map<String, dynamic>;
        final bookings = (data['bookings'] as List).cast<Map<String, dynamic>>().map(BookingModel.fromJson).toList();
        return (bookings: bookings, total: pagination['total'] as int? ?? 0, pages: pagination['pages'] as int? ?? 1);
      }
      return (bookings: <BookingModel>[], total: 0, pages: 1);
    } on DioException catch (e) {
      DioExceptionHandler.handleDioException(e);
      return (bookings: <BookingModel>[], total: 0, pages: 1);
    } catch (e) {
      debugPrint('❌ listSellerBookings error: $e');
      ToastUtil.showToast('Failed to load bookings.');
      return (bookings: <BookingModel>[], total: 0, pages: 1);
    }
  }

  Future<BookingModel?> getSellerBookingById(String storeId, String id) async {
    try {
      final response = await _client.get(ApiConstants.sellerBookingById(storeId, id), requiresAuth: true);
      if (response.data['success'] == true) {
        return BookingModel.fromJson(response.data['data'] as Map<String, dynamic>);
      }
      return null;
    } on DioException catch (e) {
      DioExceptionHandler.handleDioException(e);
      return null;
    } catch (e) {
      debugPrint('❌ getSellerBookingById error: $e');
      ToastUtil.showToast('Failed to load booking details.');
      return null;
    }
  }

  Future<bool> confirmBooking(String storeId, String id) => _sellerBookingPatch(ApiConstants.sellerBookingConfirm(storeId, id));
  Future<bool> completeBooking(String storeId, String id) => _sellerBookingPatch(ApiConstants.sellerBookingComplete(storeId, id));

  Future<bool> sellerCancelBooking(String storeId, String id, {String? reason}) =>
      _sellerBookingPatch(ApiConstants.sellerBookingCancel(storeId, id), data: {if (reason != null) 'reason': reason});

  Future<bool> sellerRescheduleBooking(String storeId, String id, {required String date, required String startTime}) =>
      _sellerBookingPatch(ApiConstants.sellerBookingReschedule(storeId, id), data: {'date': date, 'startTime': startTime});

  Future<bool> setMeetingLink(String storeId, String id, String meetingLink) =>
      _sellerBookingPatch(ApiConstants.sellerBookingMeetingLink(storeId, id), data: {'meetingLink': meetingLink});

  Future<bool> _sellerBookingPatch(String url, {Map<String, dynamic>? data}) async {
    try {
      final response = await _client.patch(url, data: data, requiresAuth: true);
      if (response.data['success'] == true) {
        ToastUtil.showToast(response.data['message'] ?? 'Updated');
        return true;
      }
      return false;
    } on DioException catch (e) {
      DioExceptionHandler.handleDioException(e);
      return false;
    } catch (e) {
      debugPrint('❌ booking status update error: $e');
      ToastUtil.showToast('Failed to update booking.');
      return false;
    }
  }

  // ─── Buyer — Browse ─────────────────────────────────────────────────────

  Future<List<BookableServiceModel>> browseStoreServices(String storeId) async {
    try {
      final response = await _client.get(ApiConstants.buyerStoreServices(storeId), requiresAuth: false);
      if (response.data['success'] == true) {
        return (response.data['data'] as List? ?? []).cast<Map<String, dynamic>>().map(BookableServiceModel.fromJson).toList();
      }
      return [];
    } on DioException catch (e) {
      DioExceptionHandler.handleDioException(e);
      return [];
    } catch (e) {
      debugPrint('❌ browseStoreServices error: $e');
      return [];
    }
  }

  Future<BookableServiceModel?> getServiceDetail(String storeId, String serviceId) async {
    try {
      final response = await _client.get(ApiConstants.buyerServiceById(storeId, serviceId), requiresAuth: false);
      if (response.data['success'] == true) {
        return BookableServiceModel.fromJson(response.data['data'] as Map<String, dynamic>);
      }
      return null;
    } on DioException catch (e) {
      DioExceptionHandler.handleDioException(e);
      return null;
    } catch (e) {
      debugPrint('❌ getServiceDetail error: $e');
      return null;
    }
  }

  Future<List<ServiceSlotModel>> getSlots(String storeId, String serviceId, DateTime date) async {
    try {
      final dateStr = date.toIso8601String().split('T').first;
      final response = await _client.get(ApiConstants.buyerServiceSlots(storeId, serviceId, dateStr), requiresAuth: false);
      if (response.data['success'] == true) {
        return (response.data['data'] as List? ?? []).cast<Map<String, dynamic>>().map(ServiceSlotModel.fromJson).toList();
      }
      return [];
    } on DioException catch (e) {
      DioExceptionHandler.handleDioException(e);
      return [];
    } catch (e) {
      debugPrint('❌ getSlots error: $e');
      return [];
    }
  }

  // ─── Buyer — Book / Purchase ────────────────────────────────────────────

  Future<BookingModel?> bookAppointment({
    required String serviceId,
    required String date,
    required String startTime,
    String? locationType,
    String? packagePurchaseId,
    Map<String, dynamic>? serviceAddress,
    String? buyerNote,
    String? storeId,
  }) async {
    try {
      final response = await _client.post(
        ApiConstants.bookAppointment,
        data: {
          'serviceId': serviceId,
          'date': date,
          'startTime': startTime,
          if (locationType != null) 'locationType': locationType,
          if (packagePurchaseId != null) 'packagePurchaseId': packagePurchaseId,
          if (serviceAddress != null) 'serviceAddress': serviceAddress,
          if (buyerNote != null) 'buyerNote': buyerNote,
          if (storeId != null && storeId.isNotEmpty) 'storeId': storeId,
        },
        headers: _idempotencyHeader,
        requiresAuth: true,
      );
      if (response.data['success'] == true) {
        ToastUtil.showToast('Booking confirmed');
        return BookingModel.fromJson(response.data['data']['booking'] as Map<String, dynamic>);
      }
      return null;
    } on DioException catch (e) {
      DioExceptionHandler.handleDioException(e);
      return null;
    } catch (e) {
      debugPrint('❌ bookAppointment error: $e');
      ToastUtil.showToast('Failed to book this appointment.');
      return null;
    }
  }

  Future<PackagePurchaseModel?> purchasePackage(String packageId, {String? storeId}) async {
    try {
      final response = await _client.post(
        ApiConstants.purchasePackage(packageId),
        data: {
          if (storeId != null && storeId.isNotEmpty) 'storeId': storeId,
        },
        headers: _idempotencyHeader,
        requiresAuth: true,
      );
      if (response.data['success'] == true) {
        ToastUtil.showToast('Package purchased');
        return PackagePurchaseModel.fromJson(response.data['data']['purchase'] as Map<String, dynamic>);
      }
      return null;
    } on DioException catch (e) {
      DioExceptionHandler.handleDioException(e);
      return null;
    } catch (e) {
      debugPrint('❌ purchasePackage error: $e');
      ToastUtil.showToast('Failed to purchase this package.');
      return null;
    }
  }

  // ─── Buyer — My Packages ──────────────────────────────────────────────────
  // (The "My Bookings" list/detail/cancel/reschedule management screen was
  // removed — this app has no bookings-management surface any more, only
  // the book-a-service/buy-a-package flow on the service detail page, which
  // still needs to know which packages this buyer already owns.)

  Future<List<PackagePurchaseModel>> listMyPackages({String? storeId}) async {
    try {
      final response = await _client.get(
        ApiConstants.myPackages,
        queryParameters: {
          if (storeId != null && storeId.isNotEmpty) 'storeId': storeId,
        },
        requiresAuth: true,
      );
      if (response.data['success'] == true) {
        return (response.data['data'] as List? ?? []).cast<Map<String, dynamic>>().map(PackagePurchaseModel.fromJson).toList();
      }
      return [];
    } on DioException catch (e) {
      DioExceptionHandler.handleDioException(e);
      return [];
    } catch (e) {
      debugPrint('❌ listMyPackages error: $e');
      ToastUtil.showToast('Failed to load your packages.');
      return [];
    }
  }
}
