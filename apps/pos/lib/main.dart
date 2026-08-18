import 'package:book_store_app/app/data/services/branding_service.dart';
import 'package:book_store_app/app/network/dio_service.dart';
import 'package:book_store_app/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:solvexo_pos/app/routes/app_pages.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  DioService.onForceLogout = () {
    if (Get.currentRoute != Routes.posLogin) {
      Get.offAllNamed(Routes.posLogin);
    }
  };

  // Shares the buyer app's Firebase project for now — a later phase decides
  // on per-app Firebase config.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await SharedPreferences.getInstance();
  // Same shared BrandingService the buyer app uses (from book_store_app) —
  // not duplicated. Loads any cached branding instantly, then refreshes
  // from the backend in the background; see BrandingService's doc comment.
  await Get.put(BrandingService(), permanent: true).init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveSizer(
      builder: (context, orientation, screenType) {
        return GetMaterialApp(
          debugShowCheckedModeBanner: false,
          title: '${Get.find<BrandingService>().config.value.appName} POS',
          initialRoute: AppPages.initialRoute,
          getPages: AppPages.routes,
          // Clamp OS accessibility text scaling so extreme settings can't
          // compound with CustomText's device-pixel-ratio-driven `.sp` and
          // blow out hand-fit layouts — same clamp as the buyer app.
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
