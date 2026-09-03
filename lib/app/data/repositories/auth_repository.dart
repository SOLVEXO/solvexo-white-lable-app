import 'dart:async';

import 'package:book_store_app/app/data/models/common_models/auth_response_model.dart';
import 'package:book_store_app/app/data/models/common_models/social_login_model.dart';
import 'package:book_store_app/app/data/models/common_models/user_model.dart';
import 'package:book_store_app/app/notification/fcm_service.dart';
import 'package:book_store_app/app/network/api_constaints.dart';
import 'package:book_store_app/app/network/base_client.dart';
import 'package:book_store_app/app/network/dio_exception_handler.dart';
import 'package:book_store_app/app/network/messaging_socket_service.dart';
import 'package:book_store_app/app/network/notifications_socket_service.dart';
import 'package:book_store_app/shared_prefrences/app_prefrences.dart';
import 'package:book_store_app/utils/toast_util.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Response, FormData, MultipartFile;

/// Thrown by [AuthRepository.login] specifically when the account exists and
/// the password matched, but the account hasn't completed OTP verification
/// yet — the backend returns this as a distinct message so the client can
/// route to the OTP screen instead of showing a bare "login failed" error.
class AccountNotVerifiedException implements Exception {
  final String email;
  AccountNotVerifiedException(this.email);
}

class AuthRepository {
  final BaseClient _baseClient = BaseClient();

  // ─────────────────────────────────────────
  // SOCIAL LOGIN
  // ─────────────────────────────────────────

  Future<AuthResponseModel?> socialLogin(SocialLoginModel dto) async {
    try {
      debugPrint('🔄 Social login: ${dto.authProvider} - ${dto.email}');

      final response = await _baseClient.post(
        ApiConstants.socialLogin,
        data: dto.toJson(),
      );

      if (response.data['success'] == true) {
        final auth = AuthResponseModel.fromJson(response.data);
        await _persistAuthSession(auth);
        debugPrint('✅ Social login successful');
        return auth;
      }

      return null;
    } catch (e) {
      debugPrint('❌ Social login error: $e');
      rethrow;
    }
  }

  // ─────────────────────────────────────────
  // EMAIL / PASSWORD
  // ─────────────────────────────────────────

  /// Registers a new buyer account, scoped to this build's [storeId] (same
  /// per-store identity rule as [socialLogin]/`SocialLoginModel.storeId`).
  /// The account isn't usable until the OTP the backend emails is verified
  /// via [verifyOtp] — returns true only when that OTP was actually sent.
  Future<bool> signup({
    required String name,
    required String email,
    required String password,
    String? storeId,
  }) async {
    try {
      final response = await _baseClient.post(
        ApiConstants.register,
        requiresAuth: false,
        data: {
          'name': name,
          'email': email,
          'password': password,
          'role': 'user',
          if (storeId != null && storeId.isNotEmpty) 'storeId': storeId,
        },
      );
      return response.data['success'] == true;
    } on DioException catch (e) {
      DioExceptionHandler.handleDioException(e);
      return false;
    } catch (e) {
      debugPrint('❌ Signup error: $e');
      return false;
    }
  }

  /// Throws [AccountNotVerifiedException] (not a bare null) when the
  /// credentials are correct but the account is still pending OTP
  /// verification, so the caller can route to that screen instead of
  /// showing a generic error.
  Future<AuthResponseModel?> login({
    required String email,
    required String password,
    String? storeId,
  }) async {
    try {
      final response = await _baseClient.post(
        ApiConstants.login,
        requiresAuth: false,
        data: {
          'email': email,
          'password': password,
          'role': 'user',
          if (storeId != null && storeId.isNotEmpty) 'storeId': storeId,
        },
      );

      if (response.data['success'] == true) {
        final auth = AuthResponseModel.fromJson(response.data);
        await _persistAuthSession(auth);
        return auth;
      }
      return null;
    } on DioException catch (e) {
      final message = _extractMessage(e);
      if (message != null && message.toLowerCase().contains('not verified')) {
        throw AccountNotVerifiedException(email);
      }
      DioExceptionHandler.handleDioException(e);
      return null;
    } catch (e) {
      debugPrint('❌ Login error: $e');
      ToastUtil.showToast('Login failed. Please try again.');
      return null;
    }
  }

  /// Verifies a signup OTP and, on success, logs the now-verified account in
  /// (the backend returns real tokens for this call — no separate login step
  /// needed afterward).
  Future<AuthResponseModel?> verifyOtp({
    required String email,
    required String otp,
    String? storeId,
  }) async {
    try {
      final response = await _baseClient.post(
        ApiConstants.verifyOtp,
        requiresAuth: false,
        data: {
          'email': email,
          'otp': otp,
          'role': 'user',
          if (storeId != null && storeId.isNotEmpty) 'storeId': storeId,
        },
      );

      if (response.data['success'] == true) {
        final auth = AuthResponseModel.fromJson(response.data);
        await _persistAuthSession(auth);
        return auth;
      }
      return null;
    } on DioException catch (e) {
      DioExceptionHandler.handleDioException(e);
      return null;
    } catch (e) {
      debugPrint('❌ Verify OTP error: $e');
      ToastUtil.showToast('Verification failed. Please try again.');
      return null;
    }
  }

  Future<bool> resendOtp({required String email, String? storeId}) async {
    try {
      final response = await _baseClient.post(
        ApiConstants.resendOtp,
        requiresAuth: false,
        data: {
          'email': email,
          'role': 'user',
          if (storeId != null && storeId.isNotEmpty) 'storeId': storeId,
        },
      );
      return response.data['success'] == true;
    } on DioException catch (e) {
      DioExceptionHandler.handleDioException(e);
      return false;
    } catch (e) {
      debugPrint('❌ Resend OTP error: $e');
      return false;
    }
  }

  /// Always reports success (matching the backend's deliberate
  /// no-enumeration design — it never reveals whether the email exists) —
  /// the return value only reflects whether the request itself went through.
  Future<bool> forgotPassword({required String email, String? storeId}) async {
    try {
      final response = await _baseClient.post(
        ApiConstants.forgotPassword,
        requiresAuth: false,
        data: {
          'email': email,
          'role': 'user',
          if (storeId != null && storeId.isNotEmpty) 'storeId': storeId,
        },
      );
      return response.data['success'] == true;
    } on DioException catch (e) {
      DioExceptionHandler.handleDioException(e);
      return false;
    } catch (e) {
      debugPrint('❌ Forgot password error: $e');
      return false;
    }
  }

  Future<bool> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
    String? storeId,
  }) async {
    try {
      final response = await _baseClient.post(
        ApiConstants.resetPassword,
        requiresAuth: false,
        data: {
          'email': email,
          'otp': otp,
          'newPassword': newPassword,
          'role': 'user',
          if (storeId != null && storeId.isNotEmpty) 'storeId': storeId,
        },
      );
      return response.data['success'] == true;
    } on DioException catch (e) {
      DioExceptionHandler.handleDioException(e);
      return false;
    } catch (e) {
      debugPrint('❌ Reset password error: $e');
      return false;
    }
  }

  String? _extractMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['message'] != null) return data['message'].toString();
    return null;
  }

  /// Persists a successful auth response's session locally — tokens, user
  /// data, FCM — and defensively clears a previous account's leftovers.
  /// Shared by every login-shaped flow (social login, email/password login,
  /// OTP verification) so none of them can drift out of sync on what "being
  /// logged in" locally means.
  Future<void> _persistAuthSession(AuthResponseModel auth) async {
    // A `success: true` response whose `data.token` shape doesn't match what
    // TokenPair.fromJson expects (a renamed field, a missing `token` object
    // entirely, ...) parses to an EMPTY string rather than throwing — silently
    // "logging in" with a blank token that `AppPreferences.isLoggedIn()` then
    // reports as false, which looks exactly like "the token isn't saving."
    // Fail loudly here instead of writing garbage to prefs.
    if (auth.token.accessToken.trim().isEmpty) {
      throw Exception(
        'Auth response had no accessToken — check the backend response shape matches what this app version expects.',
      );
    }

    // Defensive clear: if a different account's session data is still
    // present locally (e.g. a middleware-triggered redirect left it behind
    // without a full logout — see AuthMiddleware), don't let this new
    // account inherit it. Guest cart is deliberately left alone — it's
    // meant to carry into whichever account logs in next.
    final previousUserId = await AppPreferences.getUserId();
    if (previousUserId != null &&
        previousUserId.isNotEmpty &&
        previousUserId != auth.user.id) {
      try {
        await FcmService().signOut();
      } catch (e) {
        debugPrint('FCM sign-out error (ignored): $e');
      }
      await AppPreferences.clearLocalSearchHistory();
    }

    await AppPreferences.setTokens(
      accessToken: auth.token.accessToken,
      refreshToken: auth.token.refreshToken,
    );
    await AppPreferences.saveUserData(
      userId: auth.user.id,
      name: auth.user.name,
      email: auth.user.email,
      role: auth.user.role,
    );
    // Never blocks navigation — push setup failing shouldn't fail login.
    unawaited(FcmService().init());
  }

  // ================= LOGOUT =================
  Future<void> logout() async {
    try {
      await _baseClient.post(ApiConstants.logout);
      await AppPreferences.clearAccessToken();
    } catch (e) {
      // Ignore API errors (401 is OK here)
      debugPrint('Logout API error (ignored): $e');
    } finally {
      await clearLocalSession();
    }
  }

  /// Clears all local session state — FCM topic subscription/device token,
  /// realtime sockets, cached tokens/user/search/cart data — while preserving
  /// the device-level onboarding-seen flag. Shared by explicit logout above
  /// and by a forced session-expiry logout (a 401 caught in `DioService`),
  /// so neither path leaves a stale FCM subscription or open socket behind
  /// for whichever account logs in next on this device.
  Future<void> clearLocalSession() async {
    // Must run before `clearPreference()` below wipes the user id it reads.
    try {
      await FcmService().signOut();
    } catch (e) {
      debugPrint('FCM sign-out error (ignored): $e');
    }

    // The first-launch onboarding carousel is a device-level flag, not
    // session state, so it must survive (`clearPreference()` wipes every
    // SharedPreferences key).
    final hasSeenOnboarding = await AppPreferences.getHasSeenOnboarding();
    await AppPreferences.clearPreference();
    await AppPreferences.setHasSeenOnboarding(hasSeenOnboarding);

    // Tear down the realtime sockets so the next login doesn't reuse this
    // user's authenticated connection.
    if (Get.isRegistered<MessagingSocketService>()) {
      Get.find<MessagingSocketService>().disconnect();
    }
    if (Get.isRegistered<NotificationsSocketService>()) {
      Get.find<NotificationsSocketService>().disconnect();
    }
  }

  /// Get current user profile
  Future<UserModel?> getMe({required String token}) async {
    try {
      final response = await _baseClient.get(
        ApiConstants.getMe,
        requiresAuth: true,
      );

      debugPrint("========== GET ME DEBUG ==========");
      debugPrint("Status: ${response.statusCode}");
      debugPrint("Headers sent: Bearer $token");
      debugPrint("Raw response: ${response.data}");
      debugPrint("Success field: ${response.data['success']}");
      debugPrint("Data field: ${response.data['data']}");
      debugPrint("==================================");

      if (response.statusCode == 200 && response.data['success'] == true) {
        return UserModel.fromJson(response.data['data']);
      }

      return null;
    } catch (e) {
      debugPrint("GetMe error: $e");
      return null;
    }
  }

  /// Get user profile
  Future<UserModel?> getUserProfile({required String token}) async {
    try {
      final response = await _baseClient.get(
        ApiConstants.getUserProfile,
        requiresAuth: true,
      );

      debugPrint("Get Profile Response --> ${response.data}");

      if (response.statusCode == 200 && response.data['success'] == true) {
        return UserModel.fromJson(response.data['data']);
      }

      return null;
    } on DioException catch (e) {
      DioExceptionHandler.handleDioException(e);
      return null;
    } catch (e) {
      debugPrint("Get Profile error --> $e");
      return null;
    }
  }

  /// Edit user profile (PATCH /auth/edit-profile) — works for both user and seller
  Future<UserModel?> editProfile({
    String? name,
    String? email,
    String? phone,
    String? profileImage,
  }) async {
    try {
      final Map<String, dynamic> data = {};
      if (name != null) data['name'] = name;
      if (email != null) data['email'] = email;
      if (phone != null) data['phone'] = phone;
      if (profileImage != null) data['profileImage'] = profileImage;

      final response = await _baseClient.patch(
        ApiConstants.editProfile,
        data: data,
      );

      debugPrint("Edit Profile Response --> ${response.data}");

      if (response.data['success'] == true) {
        return UserModel.fromJson(response.data['data']);
      }

      ToastUtil.showToast(response.data['message'] ?? 'Update failed');
      return null;
    } on DioException catch (e) {
      DioExceptionHandler.handleDioException(e);
      return null;
    } catch (e) {
      debugPrint("Edit Profile error: $e");
      return null;
    }
  }

  /// Update user profile
  Future<UserModel?> updateProfile({
    required String token,
    String? name,
    String? email,
    String? phone,
    String? profileImage,
    String? address,
    String? currencyPreference,
  }) async {
    try {
      final Map<String, dynamic> data = {};

      if (name != null) data['name'] = name;
      if (email != null) data['email'] = email;
      if (phone != null) data['phone'] = phone;
      if (profileImage != null) data['profileImage'] = profileImage;
      if (address != null) data['address'] = address;
      if (currencyPreference != null) data['currencyPreference'] = currencyPreference;

      final response = await _baseClient.put(
        ApiConstants.updateUserProfile,

        data: data,
      );

      debugPrint("Update Profile Response --> ${response.data}");

      if (response.statusCode == 200 && response.data['success'] == true) {
        return UserModel.fromJson(response.data['data']);
      }

      return null;
    } on DioException catch (e) {
      DioExceptionHandler.handleDioException(e);
      return null;
    } catch (e) {
      debugPrint("Update Profile error --> $e");
      return null;
    }
  }

  /// Delete user account
  Future<bool> deleteAccount({required String token}) async {
    try {
      final response = await _baseClient.delete(ApiConstants.deleteUserAccount);

      debugPrint("Delete Account Response --> ${response.data}");

      return response.statusCode == 200 && response.data['success'] == true;
    } on DioException catch (e) {
      DioExceptionHandler.handleDioException(e);
      return false;
    } catch (e) {
      debugPrint("Delete Account error --> $e");
      return false;
    }
  }
}
