import 'dart:async';

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:otobix/Network/socket_service.dart';
import 'package:otobix/Services/notification_sevice.dart';
import 'package:otobix/Services/user_activity_log_service.dart';
import 'package:otobix/Utils/app_constants.dart';
import 'package:otobix/Utils/app_urls.dart';
import 'package:otobix/Views/Dealer%20Panel/bottom_navigation_page.dart';
import 'package:otobix/Views/Dealer%20Panel/rejected_screen.dart';
import 'package:otobix/Views/Login/login_page.dart';
import 'package:otobix/Views/Register/waiting_for_approval_page.dart';
import 'package:otobix/firebase_options.dart';
import 'package:otobix/helpers/shared_prefs_helper.dart';

Future<Widget> initializeApp() async {
  Get.config(enableLog: false);
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await FirebaseAppCheck.instance.activate(
    providerAndroid:
        kDebugMode
            ? const AndroidDebugProvider()
            : const AndroidPlayIntegrityProvider(),
    providerApple:
        kDebugMode
            ? const AppleDebugProvider()
            : const AppleAppAttestProvider(),
  ); // To give a token to the public APIs so that they know they are being hit from our app
  // 40f0156c-ad04-4c3f-9d83-59b1b38e79d0 // Firebase App Check Debug Token for this App (Temporary)

  await NotificationService.instance.init();

  SharedPrefsHelper.init();

  // Check & Create Guest User
  // await GuestUserSetup.setupGuestUser(); // Un-comment this when you want to create guest users in this app

  final userId =
      await SharedPrefsHelper.getString(SharedPrefsHelper.userIdKey) ?? '';
  if (userId.isNotEmpty) {
    await NotificationService.instance.login(userId);
    // Save App Version On App Launch -> (do NOT await)
    unawaited(UserActivityLogService.logAppLaunchEvent(userId: userId));
  }

  // Initialize socket connection globally
  SocketService.instance.initSocket(AppUrls.socketBaseUrl);
  // // await Get.putAsync<ConnectivityService>(() => ConnectivityService().init());

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Get initial page
  return await _getInitialPage(userId: userId);
}

Future<Widget> _getInitialPage({required String userId}) async {
  final accessToken =
      await SharedPrefsHelper.getString(SharedPrefsHelper.accessTokenKey) ?? '';
  final refreshToken =
      await SharedPrefsHelper.getString(SharedPrefsHelper.refreshTokenKey) ??
      '';
  final userRole =
      await SharedPrefsHelper.getString(SharedPrefsHelper.userRoleKey) ?? '';
  final approvalStatus =
      await SharedPrefsHelper.getString(
        SharedPrefsHelper.userApprovalStatusKey,
      ) ??
      '';
  final entityType =
      await SharedPrefsHelper.getString(SharedPrefsHelper.entityTypeKey) ?? '';

  final isDealer = userRole == AppConstants.roles.dealer;
  final hasAccessToken = accessToken.isNotEmpty;
  final hasRefreshToken = refreshToken.isNotEmpty;
  final hasUserId = userId.isNotEmpty;
  final isPending = approvalStatus == AppConstants.roles.userStatusPending;
  final isRejected = approvalStatus == AppConstants.roles.userStatusRejected;
  final isApproved = approvalStatus == AppConstants.roles.userStatusApproved;

  final bool hasSession =
      isDealer && hasAccessToken && hasRefreshToken && hasUserId;

  // Pending
  if (hasSession && isPending) {
    return ApprovalInitialPage(
      child: WaitingForApprovalPage(entityType: entityType),
    );
  }
  // Rejected
  if (hasSession && isRejected) {
    return ApprovalInitialPage(child: RejectedScreen(userId: userId));
  }
  // Approved
  if (hasSession && isApproved) {
    return BottomNavigationPage();
  }

  // Otherwise, go to LoginPage
  return LoginPage();
}

class ApprovalInitialPage extends StatelessWidget {
  final Widget child;

  const ApprovalInitialPage({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Get.offAll(() => LoginPage());
        }
      },
      child: child,
    );
  }
}
