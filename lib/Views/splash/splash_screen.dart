import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:otobix/Controllers/splash_controller.dart';
import 'package:otobix/Utils/app_images.dart' show AppImages;

class SplashScreen extends StatelessWidget {
  SplashScreen({super.key});
  final SplashController splashController = Get.put(SplashController());
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Image.asset(AppImages.otobixLogo, height: 200)),
    );
  }
}
