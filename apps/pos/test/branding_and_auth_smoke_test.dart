// Smoke test for this app's core architectural bet (Phase 3): POS carries no
// duplicated business logic, it depends on the buyer app (book_store_app) as
// a path dependency and imports shared code straight from there. This just
// confirms that wiring actually resolves and behaves as expected from POS's
// own package — pure Dart, no platform channels needed. Replaces the default
// `flutter create` counter-app test, which tested nothing relevant here.

import 'package:book_store_app/app/data/models/branding/branding_config_model.dart';
import 'package:book_store_app/app/data/repositories/auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('POS can construct and use book_store_app\'s BrandingConfigModel unmodified', () {
    final defaults = BrandingConfigModel.defaults();
    expect(defaults.appName, 'Solvexo');
    expect(defaults.primaryColor, const Color(0xFFd97757));

    // A tenant config as POS would receive it from BrandingService.
    final tenant = BrandingConfigModel.fromJson({
      'appName': 'Acme',
      'primaryColor': '#112233',
      'featureFlags': {'posAuditLog': false},
    });
    expect(tenant.appName, 'Acme');
    expect(tenant.isFeatureEnabled('posAuditLog'), false);
  });

  test('POS can construct book_store_app\'s AuthRepository (same seller login the buyer app uses)', () {
    // Just verifies the shared class is reachable/constructible from POS's
    // own package — POS's pos_login screen deliberately reuses this instead
    // of duplicating a second login implementation.
    expect(() => AuthRepository(), returnsNormally);
  });
}
