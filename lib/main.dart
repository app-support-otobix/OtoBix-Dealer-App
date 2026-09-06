import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:otobix/Services/app_update_service.dart';
import 'package:otobix/Utils/app_colors.dart';
import 'package:otobix/app_initialization.dart';
import 'package:otobix/Utils/app_constants.dart';

void main() async {
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

      // home: RegisterPinCodePage(phoneNumber: '', userRole: '', requestId: ''),
      home: widget.home,
    );
  }
}

// // Initialize important services and return first screen
// Future<Widget> init() async {
//   Get.config(enableLog: false);
//   WidgetsFlutterBinding.ensureInitialized();

//   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

//   await FirebaseAppCheck.instance.activate(
//     providerAndroid:
//         kDebugMode
//             ? const AndroidDebugProvider()
//             : const AndroidPlayIntegrityProvider(),
//     providerApple:
//         kDebugMode
//             ? const AppleDebugProvider()
//             : const AppleAppAttestProvider(),
//   ); // To give a token to the public APIs so that they know they are being hit from our app
//   // 40f0156c-ad04-4c3f-9d83-59b1b38e79d0 // Firebase App Check Debug Token for this App (Temporary)

//   await NotificationService.instance.init();

//   SharedPrefsHelper.init();

//   final userId = await SharedPrefsHelper.getString(SharedPrefsHelper.userIdKey);
//   if (userId != null && userId.isNotEmpty) {
//     await NotificationService.instance.login(userId);
//     // Save App Version On App Launch -> (do NOT await)
//     unawaited(UserActivityLogService.logAppLaunchEvent(userId: userId));
//   }

//   // Initialize socket connection globally
//   SocketService.instance.initSocket(AppUrls.socketBaseUrl);
//   // // await Get.putAsync<ConnectivityService>(() => ConnectivityService().init());

//   await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

//   final token = await SharedPrefsHelper.getString(
//     SharedPrefsHelper.accessTokenKey,
//   );
//   final userType = await SharedPrefsHelper.getString(
//     SharedPrefsHelper.userRoleKey,
//   );

//   Widget start;

//   if (token != null && token.isNotEmpty) {
//     if (userType == AppConstants.roles.dealer) {
//       start = BottomNavigationPage();
//     } else {
//       start = LoginPage();
//     }
//   } else {
//     start = LoginPage();
//   }
//   return start;
// }
