import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:otobix/Network/api_service.dart';
import 'package:otobix/Services/notification_sevice.dart';
import 'package:otobix/Services/user_activity_log_service.dart';
import 'package:otobix/Utils/app_constants.dart';
import 'package:otobix/Utils/app_urls.dart';
import 'package:otobix/Views/Dealer%20Panel/bottom_navigation_page.dart';
import 'package:otobix/Views/Dealer%20Panel/rejected_screen.dart';
import 'package:otobix/Views/Register/waiting_for_approval_page.dart';
import 'package:otobix/Widgets/toast_widget.dart';
import 'package:otobix/helpers/shared_prefs_helper.dart';

class LoginPinCodeController extends GetxController {
  // Loaders
  RxBool isLoading = false.obs;

  // Send OTP
  Future<void> verifyOtp({
    required String requestId,
    required String otp,
    required String phoneNumber,
    bool? whatsappConsent,
  }) async {
    if (isLoading.value) return;

    isLoading.value = true;
    try {
      final String finalRequestId =
          phoneNumber == AppConstants.dealerAppTestPhoneNumber
              ? AppConstants.dealerAppTestRequestId
              : requestId;

      final response = await ApiService.post(
        endpoint: AppUrls.loginOrRegisterUsingOtp,
        body: {
          "requestId": finalRequestId,
          "otp": otp,
          "userRole": AppConstants.roles.dealer,
          if (whatsappConsent != null) "whatsappConsent": whatsappConsent,
        },
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        await _loginUser(responseBody: responseBody);
      } else if (response.statusCode == 400) {
        final String message = responseBody['message'] ?? "Failed to login.";
        debugPrint("message: $message");
        ToastWidget.show(
          context: Get.context!,
          title: "Failed",
          subtitle: message,
          toastDuration: 10,
          type: ToastType.error,
        );
      } else {
        debugPrint("responseBody: $responseBody");
        ToastWidget.show(
          context: Get.context!,
          title: "Failed",
          subtitle: "Failed to login, please try again later.",
          type: ToastType.error,
        );
      }
    } catch (e) {
      debugPrint("Error: $e");
      ToastWidget.show(
        context: Get.context!,
        title: "Something went wrong",
        subtitle: "Please try again later.",
        type: ToastType.error,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Login user helper
  Future<void> _loginUser({required dynamic responseBody}) async {
    try {
      final accessToken = responseBody['accessToken'] ?? '';
      final refreshToken = responseBody['refreshToken'] ?? '';

      final user = responseBody['user'] ?? {};

      final userId = user['id'] ?? '';
      final userName = user['userName'] ?? '';
      final imageUrl = user['imageUrl'] ?? '';
      final userRole = user['userRole'] ?? '';
      final approvalStatus = user['approvalStatus'] ?? '';
      final phoneNumber = user['phoneNumber'] ?? '';
      final email = user['email'] ?? '';
      final entityType = user['entityType'] ?? '';

      // Link current userId in OneSignal to receive push notifications
      await NotificationService.instance.login(userId);

      // Check if not dealer
      if (userRole != AppConstants.roles.dealer) {
        ToastWidget.show(
          context: Get.context!,
          title: "Failed",
          subtitle: "No account found for this user.",
          toastDuration: 5,
          type: ToastType.error,
        );
        return;
      }

      await SharedPrefsHelper.saveString(
        SharedPrefsHelper.userApprovalStatusKey,
        approvalStatus,
      );

      // Check if user is Pending
      if (approvalStatus == AppConstants.roles.userStatusPending) {
        Get.to(() => WaitingForApprovalPage(entityType: entityType));

        // Log event
        UserActivityLogService.logEvent(
          userId: userId,
          event: AppConstants.userActivityLogEvents.login,
          eventDetails: 'User status was pending',
          metadata: {'approvalStatus': approvalStatus},
        );

        return;
      }

      // Check if user is Rejected
      if (approvalStatus == AppConstants.roles.userStatusRejected) {
        Get.to(() => RejectedScreen(userId: userId));

        // Log event
        UserActivityLogService.logEvent(
          userId: userId,
          event: AppConstants.userActivityLogEvents.login,
          eventDetails: 'User status was rejected',
          metadata: {'approvalStatus': approvalStatus},
        );

        return;
      }

      // 🟢 Check if user is Approved
      if (approvalStatus == AppConstants.roles.userStatusApproved) {
        await SharedPrefsHelper.saveString(
          SharedPrefsHelper.accessTokenKey,
          accessToken,
        );

        await SharedPrefsHelper.saveString(
          SharedPrefsHelper.refreshTokenKey,
          refreshToken,
        );

        await SharedPrefsHelper.saveString(
          SharedPrefsHelper.userKey,
          jsonEncode(user),
        );

        await SharedPrefsHelper.saveString(SharedPrefsHelper.userIdKey, userId);

        await SharedPrefsHelper.saveString(
          SharedPrefsHelper.userNameKey,
          userName,
        );

        await SharedPrefsHelper.saveString(
          SharedPrefsHelper.userImageUrlKey,
          imageUrl,
        );

        await SharedPrefsHelper.saveString(
          SharedPrefsHelper.userRoleKey,
          userRole,
        );

        await SharedPrefsHelper.saveString(
          SharedPrefsHelper.userPhoneNumberKey,
          phoneNumber,
        );

        await SharedPrefsHelper.saveString(
          SharedPrefsHelper.userEmailKey,
          email,
        );

        await SharedPrefsHelper.saveString(
          SharedPrefsHelper.entityTypeKey,
          entityType,
        );

        ApiService.resetAuthenticationFailure(); // To prevent multiple token failure toasts

        // Navigate to homepage
        Get.offAll(() => BottomNavigationPage());

        // Log event
        UserActivityLogService.logEvent(
          userId: userId,
          event: AppConstants.userActivityLogEvents.login,
          eventDetails: 'Logged in successfully',
          metadata: {'approvalStatus': approvalStatus},
        );
      }
    } catch (e) {
      debugPrint("Error: $e");
      ToastWidget.show(
        context: Get.context!,
        title: "Error",
        subtitle: "Something went wrong. Please try again.",
        toastDuration: 5,
        type: ToastType.error,
      );
    }
  }
}

// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:otobix/Network/api_service.dart';
// import 'package:otobix/Utils/app_urls.dart';
// import 'package:otobix/Widgets/toast_widget.dart';

// class LoginPinCodeController extends GetxController {
//   RxBool isFourDigit = false.obs; // 👈 Reactive toggle for OTP length

//   // Send OTP
//   Future<void> verifyOtp({
//     required String requestId,
//     required String otp,
//     required String phoneNumber,
//   }) async {
//     try {
//       final response = await ApiService.post(
//         endpoint: AppUrls.verifyOtp,
//         body: {"requestId": requestId, "otp": otp},
//       );

//       final data = jsonDecode(response.body);

//       if (response.statusCode == 200) {
//         final String internalStatusCode =
//             data['data']?['statusCode']?.toString() ?? '';

//         if (internalStatusCode == "101") {
//           // ✅ OTP verified successfully
//           ToastWidget.show(
//             context: Get.context!,
//             title: "OTP Verified Successfully",
//             type: ToastType.success,
//           );
//           // Get.delete<LoginController>();
//           // Get.to(
//           //   () => RegistrationFormPage(
//           //     userRole: AppConstants.roles.dealer,
//           //     phoneNumber: phoneNumber,
//           //   ),
//           // );
//         } else if (internalStatusCode == "102") {
//           // ❌ Invalid OTP
//           ToastWidget.show(
//             context: Get.context!,
//             title: "Invalid OTP",
//             subtitle: "The OTP you entered is incorrect.",
//             type: ToastType.error,
//           );
//         } else if (internalStatusCode == "104") {
//           // ❌ Retry limit exceeded
//           ToastWidget.show(
//             context: Get.context!,
//             title: "Retry Limit Exceeded",
//             subtitle: "You have exceeded the maximum verification attempts.",
//             type: ToastType.error,
//           );
//         } else {
//           // ❌ Unknown internal code
//           ToastWidget.show(
//             context: Get.context!,
//             title: "Verification Failed",
//             subtitle: "Unexpected response code: $internalStatusCode",
//             type: ToastType.error,
//           );
//         }
//       } else {
//         debugPrint(response.body);
//         ToastWidget.show(
//           context: Get.context!,
//           title: "Failed to verify OTP",
//           type: ToastType.error,
//         );
//       }
//     } catch (e) {
//       debugPrint(e.toString());
//       ToastWidget.show(
//         context: Get.context!,
//         title: "Error Verifying OTP",
//         type: ToastType.error,
//       );
//     }
//   }
// }
