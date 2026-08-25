import 'package:book_store_app/app/data/services/branding_service.dart';
import 'package:book_store_app/app/data/services/current_store_service.dart';
import 'package:book_store_app/app/network/dio_service.dart';
import 'package:book_store_app/app/notification/fcm_background_handler.dart';
import 'package:book_store_app/app/notification/local_notification_service.dart';
import 'package:book_store_app/app/routes/app_pages.dart';
import 'package:book_store_app/config/resources/app_theme.dart';
import 'package:book_store_app/config/stripe_config.dart';
import 'package:book_store_app/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:get/get.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  DioService.onForceLogout = () {
    if (Get.currentRoute != Routes.mainHome) {
      Get.offAllNamed(Routes.mainHome);
    }
  };
  await dotenv.load(fileName: ".env");
  // Initialize SharedPreferences
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Must be registered before runApp() — see the handler's own doc comment
  // for why it has to be a top-level function.
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  // Creates the Android notification channel + initializes the local-
  // notifications plugin so FcmService's foreground-message listener can
  // actually display something once it starts running.
  await LocalNotificationService().init();

  await SharedPreferences.getInstance();
  // Loads any cached branding instantly (so the very first frame already
  // paints the right brand) and kicks off a background refresh — see
  // BrandingService's doc comment for why this can never block startup.
  await Get.put(BrandingService(), permanent: true).init();
  // Resolves this build's one store in the background — every screen that
  // needs it (Home, Search, Category, the store info page, direct-chat)
  // awaits the same cached result instead of each re-resolving its own.
  Get.put(CurrentStoreService(), permanent: true).ensureResolved();
  if (StripeConfig.isConfigured) {
    Stripe.publishableKey = StripeConfig.publishableKey;
    await Stripe.instance.applySettings();
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveSizer(
      builder: (context, orientation, screenType) {
        return GetMaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.light,
          debugShowCheckedModeBanner: false,
          title: Get.find<BrandingService>().config.value.appName,
          initialRoute: AppPages.initialRoute,
          getPages: AppPages.routes,
          // Clamp OS accessibility text scaling so extreme settings can't
          // compound with CustomText's device-pixel-ratio-driven `.sp` and
          // blow out hand-fit layouts (icon buttons, search bar, badges).
          builder: (context, child) {
            final mq = MediaQuery.of(context);
            return MediaQuery(
              data: mq.copyWith(
                textScaler: TextScaler.linear(
                  mq.textScaler.scale(1).clamp(0.9, 1.2),
                ),
              ),
              child: child!,
            );
          },
        );
      },
    );
  }
}
