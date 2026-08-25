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

        debugPrint('✅ Social login successful');
        return auth;
      }

      return null;
    } catch (e) {
      debugPrint('❌ Social login error: $e');
      rethrow;
    }
  }

  // ================= LOGOUT =================
  Future<void> logout() async {
    // Must run before `clearPreference()` below wipes the user id it reads.
    try {
      await FcmService().signOut();
    } catch (e) {
      debugPrint('FCM sign-out error (ignored): $e');
    }

    try {
      // final token = await AppPreferences.getAccessTokenAsync();

      await _baseClient.post(ApiConstants.logout);
      await AppPreferences.clearAccessToken();
    } catch (e) {
      // Ignore API errors (401 is OK here)
      debugPrint('Logout API error (ignored): $e');
    } finally {
      // ALWAYS clear local data — but the first-launch onboarding carousel
      // is a device-level flag, not session state, so it must survive a
      // logout (`clearPreference()` wipes every SharedPreferences key).
      final hasSeenOnboarding = await AppPreferences.getHasSeenOnboarding();
      await AppPreferences.clearPreference();
      await AppPreferences.setHasSeenOnboarding(hasSeenOnboarding);
      // Tear down the realtime messaging socket so the next login doesn't
      // reuse this user's authenticated connection.
      if (Get.isRegistered<MessagingSocketService>()) {
        Get.find<MessagingSocketService>().disconnect();
      }
      if (Get.isRegistered<NotificationsSocketService>()) {
        Get.find<NotificationsSocketService>().disconnect();
      }
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
