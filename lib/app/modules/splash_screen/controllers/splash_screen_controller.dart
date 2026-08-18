import 'dart:async';
import 'package:book_store_app/app/notification/fcm_service.dart';
import 'package:book_store_app/shared_prefrences/app_prefrences.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:book_store_app/app/routes/app_pages.dart';

const _kSlogans = [
  'Discover · Buy · Sell',
  'Your Marketplace, Redefined',
  'Shop Smart. Sell More.',
];

class SplashScreenController extends GetxController
    with GetTickerProviderStateMixin {
  // ── Animation controllers ─────────────────────────────────────────────────
  late AnimationController logoController;   // logo entrance + brand fade
  late AnimationController glowController;   // repeating logo pulse
  late AnimationController sloganController; // per-slogan fade in/out

  // ── Animations ────────────────────────────────────────────────────────────
  late Animation<double> scaleAnim;
  late Animation<Offset> slideAnim;
  late Animation<double> brandFade;
  late Animation<double> glowAnim;
  late Animation<double> sloganFade;

  // ── Reactive state ────────────────────────────────────────────────────────
  final RxInt sloganIndex = 0.obs;

  Timer? _sloganTimer;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    _setupLogoController();
    _setupGlowController();
    _setupSloganController();

    logoController.forward().then((_) => _startSloganCycle());
    _navigate();
  }

  void _setupLogoController() {
    logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.6),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: logoController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
    ));

    scaleAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: logoController,
        curve: const Interval(0.0, 0.65, curve: Curves.elasticOut),
      ),
    );

    brandFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: logoController,
        curve: const Interval(0.55, 1.0, curve: Curves.easeIn),
      ),
    );
  }

  void _setupGlowController() {
    glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    glowAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: glowController, curve: Curves.easeInOut),
    );
  }

  void _setupSloganController() {
    sloganController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    sloganFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: sloganController, curve: Curves.easeInOut),
    );
  }

  void _startSloganCycle() {
    sloganController.forward();
    _sloganTimer = Timer.periodic(const Duration(milliseconds: 1600), (_) async {
      await sloganController.reverse();
      sloganIndex.value = (sloganIndex.value + 1) % _kSlogans.length;
      sloganController.forward();
    });
  }

  String get currentSlogan => _kSlogans[sloganIndex.value];

  // ── Navigation ────────────────────────────────────────────────────────────

  void _navigate() async {
    await Future.delayed(const Duration(milliseconds: 5200));
    final token = await AppPreferences.getAccessTokenAsync();

    if (token == null || token.isEmpty) {
      // No session — first launch on this device shows the onboarding
      // carousel once, then it's guest-mode Home from here on. Never a login wall.
      final hasSeenOnboarding = await AppPreferences.getHasSeenOnboarding();
      Get.offAllNamed(hasSeenOnboarding ? Routes.mainHome : Routes.onboarding);
      return;
    }

    // Covers the returning-user case the login/verify call sites can't:
    // a device that already has a valid session but never ran FCM init on
    // this install (e.g. reinstalled, or logged in before this was wired
    // up). Never blocks navigation below.
    unawaited(FcmService().init());

    // Seller/POS accounts now live in the standalone POS app (Phase 3) —
    // this buyer app has no seller dashboard or POS terminal to send them
    // to, so any non-buyer role falls back to the buyer guest home too.
    Get.offAllNamed(Routes.mainHome);
  }

  @override
  void onClose() {
    _sloganTimer?.cancel();
    logoController.dispose();
    glowController.dispose();
    sloganController.dispose();
    super.onClose();
  }
}
