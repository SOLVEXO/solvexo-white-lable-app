import 'package:book_store_app/app/data/models/common_models/social_login_model.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// Google Sign-In is the only auth method the buyer app supports — see
/// Phase 10 of the white-label conversion (Facebook/Apple were removed).
class SocialAuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  // ─────────────────────────────────────────
  // GET FCM TOKEN
  // ─────────────────────────────────────────

  Future<String?> _getFcmToken() async {
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      debugPrint('🔔 FCM Token: ${fcmToken?.substring(0, 20)}...');
      return fcmToken;
    } catch (e) {
      debugPrint('⚠️ FCM token error: $e');
      return null;
    }
  }

  // ─────────────────────────────────────────
  // GOOGLE SIGN IN
  // ─────────────────────────────────────────

  Future<SocialLoginModel?> signInWithGoogle({String? storeId}) async {
    try {
      debugPrint('🔄 Starting Google Sign In...');

      await _googleSignIn.initialize();

      final GoogleSignInAccount account = await _googleSignIn.authenticate();

      final auth = account.authentication;
      final fcmToken = await _getFcmToken();

      return SocialLoginModel(
        authProvider: 'google',
        socialId: account.id,
        userName: account.displayName ?? 'User',
        email: account.email,
        image: account.photoUrl,
        fcmToken: fcmToken,
        token: auth.idToken,
        storeId: storeId,
      );
    } catch (e) {
      debugPrint('❌ Google Sign In error: $e');
      return null;
    }
  }

  // ─────────────────────────────────────────
  // SIGN OUT
  // ─────────────────────────────────────────

  Future<void> signOutGoogle() async {
    try {
      await _googleSignIn.signOut();
      debugPrint('✅ Google signed out');
    } catch (e) {
      debugPrint('⚠️ Google sign out error: $e');
    }
  }

  Future<void> signOutAll() async {
    await signOutGoogle();
  }
}
