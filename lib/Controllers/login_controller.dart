import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:otobix/Network/api_service.dart';
import 'package:otobix/Utils/app_constants.dart';
import 'package:otobix/Utils/app_urls.dart';
import 'package:otobix/Views/Login/login_pin_code_page.dart';
import 'package:otobix/Widgets/toast_widget.dart';
import 'package:otobix/helpers/shared_prefs_helper.dart';

class LoginController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    insertPhoneNumber();
  }

  // Loaders
  RxBool isSendOtpLoading = false.obs;

  final phoneNumberController = TextEditingController();

  RxBool whatsappConsent = true.obs;

  // Method to update consent
  void updateWhatsappConsent(bool value) {
    whatsappConsent.value = value;
  }

  // Send OTP
  Future<void> sendOTP() async {
    if (isSendOtpLoading.value) return;

    isSendOtpLoading.value = true;
    try {
      final phoneNumber = phoneNumberController.text.trim();

      if (phoneNumber.isEmpty) {
        ToastWidget.show(
          context: Get.context!,
          title: 'Required',
          subtitle: "Please enter a mobile number",
          type: ToastType.error,
        );
        return;
      }

      // For indian numbers only
      final RegExp indianRegex = RegExp(r'^[6-9]\d{9}$');

      if (!indianRegex.hasMatch(phoneNumber)) {
        ToastWidget.show(
          context: Get.context!,
          title: "Invalid mobile number",
          subtitle:
              "Please enter a valid indian mobile number (starts with 6-9)",
          type: ToastType.error,
        );
        return;
      }

      if (phoneNumber == AppConstants.dealerAppTestPhoneNumber) {
        Get.to(
          () => LoginPinCodePage(
            requestId: AppConstants.dealerAppTestRequestId,
            phoneNumber: phoneNumber,
            whatsappConsent: whatsappConsent.value,
          ),
        );
        ToastWidget.show(
          context: Get.context!,
          title: "OTP Sent",
          subtitle: "OTP Sent Successfully",
          type: ToastType.success,
        );
        return;
      }

      final requestBody = {
        "mobile": phoneNumber,
        "purpose": AppConstants.otpPurposes.login,
      };

      final response = await ApiService.post(
        endpoint: AppUrls.sendOtp,
        body: requestBody,
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // ✅ Success navigate to second page
        final String requestId = responseBody['data']['requestId'].toString();
        Get.to(
          () => LoginPinCodePage(
            requestId: requestId,
            phoneNumber: phoneNumber,
            whatsappConsent: whatsappConsent.value,
          ),
        );
        ToastWidget.show(
          context: Get.context!,
          title: "OTP Sent",
          subtitle: "OTP Sent Successfully",
          type: ToastType.success,
        );
      } else if (response.statusCode == 400) {
        // ❌ Failed to send OTP
        String errorMessage = responseBody['message'] ?? 'Please try again';
        ToastWidget.show(
          context: Get.context!,
          title: "Failed to send OTP",
          subtitle: errorMessage,
          toastDuration: 10,
          type: ToastType.error,
        );
      } else {
        debugPrint(
          "Failed to send OTP: $responseBody, status code ${response.statusCode}",
        );
        ToastWidget.show(
          context: Get.context!,
          title: "Failed",
          subtitle: "Failed to send OTP",
          type: ToastType.error,
        );
      }
    } catch (e) {
      debugPrint(e.toString());
      ToastWidget.show(
        context: Get.context!,
        title: "Error",
        subtitle: "Error sending OTP",
        type: ToastType.error,
      );
    } finally {
      isSendOtpLoading.value = false;
    }
  }

  // Insert Phone Number
  void insertPhoneNumber() async {
    final String phoneNumber =
        await SharedPrefsHelper.getString(
          SharedPrefsHelper.userPhoneNumberKey,
        ) ??
        '';
    // Check if it is a valid 10 digit indian phone number
    final RegExp indianRegex = RegExp(r'^[6-9]\d{9}$');
    if (indianRegex.hasMatch(phoneNumber)) {
      phoneNumberController.text = phoneNumber;
    }
  }
}

// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:otobix/Network/api_service.dart';
// import 'package:otobix/Services/notification_sevice.dart';
// import 'package:otobix/Services/user_activity_log_service.dart';
// import 'package:otobix/Utils/app_constants.dart';
// import 'package:otobix/Utils/app_urls.dart';
// import 'package:otobix/Views/Dealer%20Panel/rejected_screen.dart';
// import 'package:otobix/Views/Register/waiting_for_approval_page.dart';
// import 'package:otobix/Views/Dealer%20Panel/bottom_navigation_page.dart';
// import 'package:otobix/Widgets/toast_widget.dart';
// import 'package:otobix/helpers/shared_prefs_helper.dart';

// class LoginController extends GetxController {
//   @override
//   void onInit() {
//     super.onInit();
//     clearFields();
//   }

//   RxBool isLoading = false.obs;
//   RxBool obsecureText = true.obs;
//   final userNameController = TextEditingController();
//   final phoneNumberController = TextEditingController();
//   final passwordController = TextEditingController();

//   // Login User
//   Future<void> loginUser() async {
//     if (isLoading.value) return;

//     isLoading.value = true;
//     try {
//       String userName = userNameController.text.trim();
//       String contactNumber = phoneNumberController.text.trim();
//       String password = passwordController.text.trim();

//       final requestBody = {
//         "userName": userName,
//         "phoneNumber": contactNumber,
//         "password": password,
//       };

//       final response = await ApiService.post(
//         endpoint: AppUrls.login,
//         body: requestBody,
//       );

//       final responseBody = jsonDecode(response.body);

//       if (response.statusCode == 200) {
//         final accessToken = responseBody['accessToken'] ?? '';
//         final refreshToken = responseBody['refreshToken'] ?? '';

//         final user = responseBody['user'] ?? {};

//         final userId = user['id'] ?? '';
//         final userName = user['userName'] ?? '';
//         final imageUrl = user['imageUrl'] ?? '';
//         final userRole = user['userRole'] ?? '';
//         final approvalStatus = user['approvalStatus'] ?? '';
//         final phoneNumber = user['phoneNumber'] ?? '';
//         final email = user['email'] ?? '';
//         final entityType = user['entityType'] ?? '';

//         // Link current userid in OneSignal to receive push notifications
//         await NotificationService.instance.login(userId);

//         // Check if not dealer
//         if (userRole != AppConstants.roles.dealer) {
//           ToastWidget.show(
//             context: Get.context!,
//             title: "Failed",
//             subtitle: "No account found for this user.",
//             toastDuration: 5,
//             type: ToastType.error,
//           );
//           return;
//         }

//         await SharedPrefsHelper.saveString(
//           SharedPrefsHelper.userApprovalStatusKey,
//           approvalStatus,
//         );

//         // Check if user is Pending
//         if (approvalStatus == AppConstants.roles.userStatusPending) {
//           Get.to(() => WaitingForApprovalPage(entityType: entityType));

//           // Log event
//           UserActivityLogService.logEvent(
//             userId: userId,
//             event: AppConstants.userActivityLogEvents.login,
//             eventDetails: 'User status was pending',
//             metadata: {'approvalStatus': approvalStatus},
//           );
//           return;
//         }

//         // Check if user is Rejected
//         if (approvalStatus == AppConstants.roles.userStatusRejected) {
//           Get.to(() => RejectedScreen(userId: userId));

//           // Log event
//           UserActivityLogService.logEvent(
//             userId: userId,
//             event: AppConstants.userActivityLogEvents.login,
//             eventDetails: 'User status was rejected',
//             metadata: {'approvalStatus': approvalStatus},
//           );
//           return;
//         }

//         // Check if user is Approved
//         if (approvalStatus == AppConstants.roles.userStatusApproved) {
//           await SharedPrefsHelper.saveString(
//             SharedPrefsHelper.accessTokenKey,
//             accessToken,
//           );

//           await SharedPrefsHelper.saveString(
//             SharedPrefsHelper.refreshTokenKey,
//             refreshToken,
//           );

//           await SharedPrefsHelper.saveString(
//             SharedPrefsHelper.userKey,
//             jsonEncode(user),
//           );

//           await SharedPrefsHelper.saveString(
//             SharedPrefsHelper.userIdKey,
//             userId,
//           );

//           await SharedPrefsHelper.saveString(
//             SharedPrefsHelper.userNameKey,
//             userName,
//           );

//           await SharedPrefsHelper.saveString(
//             SharedPrefsHelper.userImageUrlKey,
//             imageUrl,
//           );

//           await SharedPrefsHelper.saveString(
//             SharedPrefsHelper.userRoleKey,
//             userRole,
//           );

//           await SharedPrefsHelper.saveString(
//             SharedPrefsHelper.userPhoneNumberKey,
//             phoneNumber,
//           );

//           await SharedPrefsHelper.saveString(
//             SharedPrefsHelper.userEmailKey,
//             email,
//           );

//           await SharedPrefsHelper.saveString(
//             SharedPrefsHelper.entityTypeKey,
//             entityType,
//           );

//           ApiService.resetAuthenticationFailure(); // To prevent multiple token failure toasts

//           Get.offAll(() => BottomNavigationPage());

//           // Log event
//           UserActivityLogService.logEvent(
//             userId: userId,
//             event: AppConstants.userActivityLogEvents.login,
//             eventDetails: 'Logged in successfully',
//             metadata: {'approvalStatus': approvalStatus},
//           );
//         }
//       } else if (response.statusCode == 400) {
//         final String message = responseBody['message'] ?? "Failed to login.";
//         debugPrint("message: $message");
//         ToastWidget.show(
//           context: Get.context!,
//           title: "Failed",
//           subtitle: message,
//           toastDuration: 10,
//           type: ToastType.error,
//         );
//       } else {
//         debugPrint("responseBody: $responseBody");
//         ToastWidget.show(
//           context: Get.context!,
//           title: "Failed",
//           subtitle: "Failed to login, please try again later.",
//           type: ToastType.error,
//         );
//       }
//     } catch (e) {
//       debugPrint("Error: $e");
//       ToastWidget.show(
//         context: Get.context!,
//         title: "Something went wrong",
//         subtitle: "Please try again later.",
//         type: ToastType.error,
//       );
//     } finally {
//       isLoading.value = false;
//     }
//   }

//   String? validatePassword(String password) {
//     if (password.isEmpty) return "Password is required.";
//     if (password.length < 8) {
//       return "Password must be at least 8 characters long.";
//     }
//     if (!RegExp(r'[A-Z]').hasMatch(password)) {
//       return "At least one uppercase letter required.";
//     }
//     if (!RegExp(r'[a-z]').hasMatch(password)) {
//       return "At least one lowercase letter required.";
//     }
//     if (!RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-]').hasMatch(password)) {
//       return "At least one special character required.";
//     }
//     return null;
//   }

//   // Clear fields
//   void clearFields() {
//     userNameController.clear();
//     phoneNumberController.clear();
//     passwordController.clear();
//     obsecureText.value = true;
//   }
// }
