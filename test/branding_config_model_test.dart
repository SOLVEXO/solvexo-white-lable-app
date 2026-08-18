// Basic unit coverage for the white-label branding model (Phase 4/5) — pure
// Dart, no platform channels needed, unlike the app's Firebase/shared_prefs
// bootstrap which only exercises reliably under `integration_test` on a
// real device/simulator (see integration_test/guest_mode_e2e_test.dart).
// Replaces the default `flutter create` counter-app test, which tested
// nothing relevant to this app.

import 'package:book_store_app/app/data/models/branding/branding_config_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BrandingConfigModel.defaults', () {
    test('matches the hardcoded Solvexo branding so nothing visually changes before a backend config exists', () {
      final defaults = BrandingConfigModel.defaults();
      expect(defaults.appName, 'Solvexo');
      expect(defaults.marketplaceName, 'Solvexo');
      expect(defaults.logoUrl, '');
      expect(defaults.primaryColor, const Color(0xFFd97757));
      expect(defaults.featureFlags, isEmpty);
    });

    test('isFeatureEnabled defaults to true for any unknown flag, so a missing backend flag never hides a feature', () {
      final defaults = BrandingConfigModel.defaults();
      expect(defaults.isFeatureEnabled('wishlist'), true);
      expect(defaults.isFeatureEnabled('posAuditLog'), true);
      expect(defaults.isFeatureEnabled('anything-not-configured'), true);
    });
  });

  group('BrandingConfigModel.fromJson', () {
    test('parses a full, well-formed response', () {
      final config = BrandingConfigModel.fromJson({
        'appName': 'Acme',
        'marketplaceName': 'Acme Market',
        'logoUrl': 'https://cdn.example.com/logo.png',
        'primaryColor': '#112233',
        'secondaryColor': '#AABBCC',
        'accentColor': '#FF00FF',
        'featureFlags': {'wishlist': false, 'posAuditLog': true},
      });

      expect(config.appName, 'Acme');
      expect(config.marketplaceName, 'Acme Market');
      expect(config.logoUrl, 'https://cdn.example.com/logo.png');
      expect(config.primaryColor, const Color(0xFF112233));
      expect(config.secondaryColor, const Color(0xFFAABBCC));
      expect(config.accentColor, const Color(0xFFFF00FF));
      expect(config.isFeatureEnabled('wishlist'), false);
      expect(config.isFeatureEnabled('posAuditLog'), true);
    });

    test('falls back to defaults field-by-field for missing/blank/malformed values', () {
      final config = BrandingConfigModel.fromJson({
        'appName': '',
        'primaryColor': 'not-a-color',
        // marketplaceName, logoUrl, secondaryColor, accentColor, featureFlags all omitted
      });
      final defaults = BrandingConfigModel.defaults();

      expect(config.appName, defaults.appName);
      expect(config.marketplaceName, defaults.marketplaceName);
      expect(config.primaryColor, defaults.primaryColor);
      expect(config.secondaryColor, defaults.secondaryColor);
      expect(config.accentColor, defaults.accentColor);
    });
  });

  test('toJson round-trips through fromJson without losing color/flag data', () {
    final original = BrandingConfigModel.fromJson({
      'appName': 'Acme',
      'marketplaceName': 'Acme Market',
      'logoUrl': 'https://cdn.example.com/logo.png',
      'primaryColor': '#112233',
      'secondaryColor': '#aabbcc',
      'accentColor': '#ff00ff',
      'featureFlags': {'wishlist': false},
    });

    final roundTripped = BrandingConfigModel.fromJson(original.toJson());

    expect(roundTripped.appName, original.appName);
    expect(roundTripped.marketplaceName, original.marketplaceName);
    expect(roundTripped.logoUrl, original.logoUrl);
    expect(roundTripped.primaryColor, original.primaryColor);
    expect(roundTripped.secondaryColor, original.secondaryColor);
    expect(roundTripped.accentColor, original.accentColor);
    expect(roundTripped.isFeatureEnabled('wishlist'), false);
  });
}
