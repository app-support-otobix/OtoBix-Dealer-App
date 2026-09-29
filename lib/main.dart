import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:otobix/Services/app_update_service.dart';
import 'package:otobix/Utils/app_colors.dart';
import 'package:otobix/app_initialization.dart';
import 'package:otobix/Utils/app_constants.dart';

void main() async {
  // debugPrint still writes to the device log in release builds, and several
  // screens log API responses that contain personal data. Silence it there;
  // debug and profile builds keep their logs.
  if (kReleaseMode) {
    debugPrint = (String? message, {int? wrapWidth}) {};
  }

  final start = await initializeApp();
  runApp(MyApp(home: start));
}

class MyApp extends StatefulWidget {
  final Widget home;
  const MyApp({super.key, required this.home});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();

    // ✅ run after first frame to ensure context exists
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppUpdateService.instance.checkOnLaunch(appKey: AppConstants.appKey);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      navigatorKey:
          Get.key, // enables Get.* navigation from services (for route to specific screen via notification click)
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        // fontFamily: 'Poppins',
        scaffoldBackgroundColor: AppColors.white,
        canvasColor: AppColors.white,
        // dialogTheme: const DialogTheme(backgroundColor: AppColors.white),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: AppColors.white,
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.white,
          brightness: Brightness.light,
        ),
      ),

      home: widget.home,
    );
  }
}
