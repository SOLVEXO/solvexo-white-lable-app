import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppPreferences {
  static const String _accessTokenKey = 'token';
  static const String _refreshTokenKey = 'refreshToken';
  static const String _userIdKey = 'user_id';
  static const String _userNameKey = 'user_name';
  static const String _userRoleKey = 'user_role';
  static const String _userEmailKey = 'user_email';
  static const String _intentRoleKey = 'intent_role';
  static const String _hasSeenOnboardingKey = 'has_seen_onboarding';
  static const String _guestCartKey = 'guest_cart_items';
  static const String _recentSearchesKey = 'recent_searches';
  static const String _recentlyViewedKey = 'recently_viewed_products';
  static const String _displayCurrencyKey = 'display_currency';
  static const String _brandingConfigKey = 'branding_config_json';

  // ── POS employee / session context ────────────────────────────────────────────
  static const String _posEmployeeIdKey   = 'pos_employee_id';
  static const String _posEmployeeNameKey = 'pos_employee_name';
  static const String _posEmployeeRoleKey = 'pos_employee_role';
  static const String _posSessionIdKey    = 'pos_session_id';
  static const String _posRegisterIdKey   = 'pos_register_id';
  static const String _posShiftIdKey      = 'pos_shift_id';

  // ── POS device-local preferences (not backend-tracked) ─────────────────────
  static const String _posSoundEffectsKey = 'pos_sound_effects';
  static const String _posAutoLockMinutesKey = 'pos_auto_lock_minutes';

  // Save access token
  static Future<void> setAccessToken(
    String accessToken,
    String refreshToken,
  ) async {
    await setTokens(accessToken: accessToken, refreshToken: refreshToken);
  }

  // Get access token
  static Future<String?> getAccessTokenAsync() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessTokenKey);
  }

  // Save refresh token
  static Future<void> setRefreshToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_refreshTokenKey, token);
  }

  // Get refresh token
  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  // ✅ Save both tokens at once
  static Future<void> setTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      debugPrint('💾 Saving tokens...');
      final accessSaved = await prefs.setString(_accessTokenKey, accessToken);
      final refreshSaved = await prefs.setString(
        _refreshTokenKey,
        refreshToken,
      );

      debugPrint('✅ Access token saved: $accessSaved');
      debugPrint('✅ Refresh token saved: $refreshSaved');

      // Verify
      final savedAccess = prefs.getString(_accessTokenKey);
      final savedRefresh = prefs.getString(_refreshTokenKey);
      debugPrint('✅ Verified access: ${savedAccess?.substring(0, 20)}...');
      debugPrint('✅ Verified refresh: ${savedRefresh?.substring(0, 20)}...');
    } catch (e) {
      debugPrint('❌ Error saving tokens: $e');
      rethrow;
    }
  }

  // Clear access token
  static Future<void> clearAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
  }

  // Clear refresh token
  /// Full local session wipe (tokens, user identity, cached search/store
  /// data — everything a logout clears) except the device-level
  /// onboarding-seen flag, which must survive. Route guards (AuthMiddleware
  /// et al.) that find no token present use this so stale
  /// user_id/name/role/email don't linger for whichever account logs in next
  /// (e.g. FcmService.subscribeToUserId reads user_id straight from prefs).
  static Future<void> clearSessionPreservingOnboarding() async {
    final hasSeenOnboarding = await getHasSeenOnboarding();
    await clearPreference();
    await setHasSeenOnboarding(hasSeenOnboarding);
  }

  // Save user data
  static Future<void> saveUserData({
    required String userId,
    required String name,
    required String email,
    required String role,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userIdKey, userId);
    await prefs.setString(_userNameKey, name);
    await prefs.setString(_userEmailKey, email);
    await prefs.setString(_userRoleKey, role);
  }

  // Get user ID
  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  // Get user name
  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userNameKey);
  }

  // Get user email
  static Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userEmailKey);
  }

  // Get user role
  static Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userRoleKey);
  }

  // ── Intent role (selected on Welcome screen before auth) ─────────────────────
  static Future<void> saveIntentRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_intentRoleKey, role);
  }

  static Future<String?> getIntentRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_intentRoleKey);
  }

  static Future<void> clearIntentRole() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_intentRoleKey);
  }

  // ── First-launch onboarding carousel flag ─────────────────────────────────
  static Future<void> setHasSeenOnboarding(bool seen) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasSeenOnboardingKey, seen);
  }

  static Future<bool> getHasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hasSeenOnboardingKey) ?? false;
  }

  // ── Guest cart (local-only until login merges it into the account cart) ────
  static Future<void> saveGuestCartItems(List<Map<String, dynamic>> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_guestCartKey, jsonEncode(items));
  }

  static Future<List<Map<String, dynamic>>> getGuestCartItems() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_guestCartKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('❌ Error decoding guest cart: $e');
      return [];
    }
  }

  static Future<void> clearGuestCart() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_guestCartKey);
  }

  // Clear all user data
  static Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userIdKey);
    await prefs.remove(_userNameKey);
    await prefs.remove(_userEmailKey);
  }

  // Clear all preferences
  static Future<void> clearPreference() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final token = await getAccessTokenAsync();
    return token != null && token.isNotEmpty;
  }

  // Recent Searches
  static Future<void> saveRecentSearches(List<String> searches) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_recentSearchesKey, searches);
  }

  static Future<List<String>?> getRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_recentSearchesKey);
  }

  /// Recent-searches and recently-viewed are keyed generically, not per
  /// user_id — call this before a different account's tokens/user data get
  /// written (see `AuthRepository.socialLogin`) so one account never inherits
  /// another's local search history on a shared device.
  static Future<void> clearLocalSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_recentSearchesKey);
    await prefs.remove(_recentlyViewedKey);
  }

  // ── POS employee context ──────────────────────────────────────────────────────
  static Future<void> savePosEmployee({
    required String id,
    required String name,
    required String role,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_posEmployeeIdKey, id);
    await prefs.setString(_posEmployeeNameKey, name);
    await prefs.setString(_posEmployeeRoleKey, role);
  }

  static Future<String?> getPosEmployeeId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_posEmployeeIdKey);
  }

  static Future<String?> getPosEmployeeName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_posEmployeeNameKey);
  }

  static Future<String?> getPosEmployeeRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_posEmployeeRoleKey);
  }

  static Future<void> clearPosEmployee() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_posEmployeeIdKey);
    await prefs.remove(_posEmployeeNameKey);
    await prefs.remove(_posEmployeeRoleKey);
  }

  // ── POS active session context ────────────────────────────────────────────────
  static Future<void> savePosSession({
    required String sessionId,
    required String registerId,
    required String shiftId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_posSessionIdKey, sessionId);
    await prefs.setString(_posRegisterIdKey, registerId);
    await prefs.setString(_posShiftIdKey, shiftId);
  }

  static Future<String?> getPosSessionId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_posSessionIdKey);
  }

  static Future<String?> getPosRegisterId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_posRegisterIdKey);
  }

  static Future<String?> getPosShiftId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_posShiftIdKey);
  }

  static Future<void> clearPosSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_posSessionIdKey);
    await prefs.remove(_posRegisterIdKey);
    await prefs.remove(_posShiftIdKey);
  }

  static Future<bool> hasPosSession() async {
    final id = await getPosSessionId();
    return id != null && id.isNotEmpty;
  }

  // ── POS device-local preferences ──────────────────────────────────────────
  static Future<void> setPosSoundEffects(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_posSoundEffectsKey, enabled);
  }

  static Future<bool> getPosSoundEffects() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_posSoundEffectsKey) ?? true;
  }

  static Future<void> setPosAutoLockMinutes(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_posAutoLockMinutesKey, minutes);
  }

  static Future<int> getPosAutoLockMinutes() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_posAutoLockMinutesKey) ?? 5;
  }

  // ── Buyer display currency (device-local; source of truth is the backend
  // `currencyPreference` for logged-in users once loaded — see
  // CurrencyController) ────────────────────────────────────────────────────
  static Future<void> saveDisplayCurrency(String currency) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_displayCurrencyKey, currency);
  }

  static Future<String?> getDisplayCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_displayCurrencyKey);
  }

  // ── White-label branding cache (last successfully fetched config, so a
  // cold start can paint the right brand instantly instead of flashing
  // defaults first — see BrandingService) ──────────────────────────────────
  static Future<void> saveBrandingConfigJson(String json) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_brandingConfigKey, json);
  }

  static Future<String?> getBrandingConfigJson() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_brandingConfigKey);
  }

  // Recently Viewed Products
  static Future<void> saveRecentlyViewedProductIds(List<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_recentlyViewedKey, ids);
  }

  static Future<List<String>?> getRecentlyViewedProductIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_recentlyViewedKey);
  }
}
