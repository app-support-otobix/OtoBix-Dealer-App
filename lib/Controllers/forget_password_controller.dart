import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:otobix/Network/api_service.dart';
import 'package:otobix/Utils/app_urls.dart';
import 'package:otobix/Views/Login/login_page.dart';
import 'package:otobix/Widgets/toast_widget.dart';

class ForgetPasswordController extends GetxController {
  final formKey = GlobalKey<FormState>();

  RxBool isFourDigit = false.obs; // 👈 Reactive toggle for OTP length
  String requestId = '';

  // Page control
  final pageController = PageController();
  final currentPage = 0.obs;

  // Text controllers
  final phoneCtrl = TextEditingController();
  final otpCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  final confirmPasswordCtrl = TextEditingController();

  // UI state
  final isSendOtpLoading = false.obs;
  final isVerifyOtpLoading = false.obs;
  final isSetNewPasswordLoading = false.obs;
  final newPasswordObscureText = true.obs;
  final confirmPasswordObscureText = true.obs;

  // Send OTP
  Future<void> sendOTP() async {
    isSendOtpLoading.value = true;
    try {
      final phoneNumber = phoneCtrl.text.trim();
      // final formattedPhoneNumber =
      //     phoneNumber.startsWith('0')
      //         ? '+92${phoneNumber.substring(1)}'
      //         : '+92$phoneNumber';

      // For indian numbers only
      final RegExp indianRegex = RegExp(r'^[6-9]\d{9}$');

      if (!indianRegex.hasMatch(phoneNumber)) {
        ToastWidget.show(
          context: Get.context!,
          title: "Invalid mobile number",
          subtitle: "Please enter a valid mobile number (starts with 6-9)",
          type: ToastType.error,
        );
        return;
      }

      final requestBody = {"mobile": phoneNumber};

      final response = await ApiService.post(
        endpoint: AppUrls.sendOtp,
        body: requestBody,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        requestId = data['data']['requestId'] ?? '';
        final String internalStatusCode =
            data['data']?['statusCode']?.toString() ?? '';

        if (internalStatusCode == "101") {
          // ✅ Success navigate to second page
          goToPage(1);
          ToastWidget.show(
            context: Get.context!,
            title: "OTP Sent Successfully",
            type: ToastType.success,
          );
        } else if (internalStatusCode == "102") {
          // ❌ Invalid details
          ToastWidget.show(
            context: Get.context!,
            title: "Invalid Details",
            subtitle: "Invalid ID or input combination.",
            type: ToastType.error,
          );
        } else if (internalStatusCode == "104") {
          // ❌ Retry limit exceeded
          ToastWidget.show(
            context: Get.context!,
            title: "Retry Limit Exceeded",
            subtitle: "You have reached maximum OTP attempts.",
            type: ToastType.error,
          );
        } else {
          // ❌ Unknown or unhandled code
          ToastWidget.show(
            context: Get.context!,
            title: "Failed to send OTP",
            subtitle: "Unexpected response code: $internalStatusCode",
            type: ToastType.error,
          );
        }
      } else {
        debugPrint(
          "Failed to send OTP: $data, status code ${response.statusCode}",
        );
        ToastWidget.show(
          context: Get.context!,
          title: "Failed to send OTP",
          type: ToastType.error,
        );
      }
    } catch (e) {
      debugPrint(e.toString());
      ToastWidget.show(
        context: Get.context!,
        title: "Error sending OTP",
        type: ToastType.error,
      );
    } finally {
      isSendOtpLoading.value = false;
    }
  }

  // Verify OTP
  Future<void> verifyOtp() async {
    try {
      isVerifyOtpLoading.value = true;
      final response = await ApiService.post(
        endpoint: AppUrls.verifyOtp,
        body: {"requestId": requestId, "otp": otpCtrl.text.trim().toString()},
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final String internalStatusCode =
            data['data']?['statusCode']?.toString() ?? '';

        if (internalStatusCode == "101") {
          // ✅ OTP verified successfully
          ToastWidget.show(
            context: Get.context!,
            title: "OTP Verified Successfully",
            type: ToastType.success,
          );
          goToPage(2);
        } else if (internalStatusCode == "102") {
          // ❌ Invalid OTP
          ToastWidget.show(
            context: Get.context!,
            title: "Invalid OTP",
            subtitle: "The OTP you entered is incorrect.",
            type: ToastType.error,
          );
        } else if (internalStatusCode == "104") {
          // ❌ Retry limit exceeded
          ToastWidget.show(
            context: Get.context!,
            title: "Retry Limit Exceeded",
            subtitle: "You have exceeded the maximum verification attempts.",
            type: ToastType.error,
          );
        } else {
          // ❌ Unknown internal code
          ToastWidget.show(
            context: Get.context!,
            title: "Verification Failed",
            subtitle: "Unexpected response code: $internalStatusCode",
            type: ToastType.error,
          );
        }
      } else {
        debugPrint(data);
        ToastWidget.show(
          context: Get.context!,
          title: "Failed to verify OTP",
          type: ToastType.error,
        );
      }
    } catch (e) {
      debugPrint(e.toString());
      ToastWidget.show(
        context: Get.context!,
        title: "Error Verifying OTP",
        type: ToastType.error,
      );
    } finally {
      isVerifyOtpLoading.value = false;
    }
  }

  // Set new password
  Future<void> setNewPassword() async {
    try {
      isSetNewPasswordLoading.value = true;

      final response = await ApiService.put(
        endpoint: AppUrls.setNewPassword,
        body: {
          "phoneNumber": phoneCtrl.text.trim(),
          "password": passwordCtrl.text.trim(),
        },
      );
      debugPrint(response.body);
      if (response.statusCode == 200) {
        ToastWidget.show(
          context: Get.context!,
          title: "Password Updated Successfully",
          type: ToastType.success,
        );

        phoneCtrl.clear();
        passwordCtrl.clear();
        confirmPasswordCtrl.clear();
        otpCtrl.clear();

        Get.offAll(() => LoginPage());
      } else if (response.statusCode == 404) {
        ToastWidget.show(
          context: Get.context!,
          title: "No account associated with this phone number",
          type: ToastType.error,
        );
      } else {
        ToastWidget.show(
          context: Get.context!,
          title: "Failed to update password",
          type: ToastType.error,
        );
      }
    } catch (e) {
      ToastWidget.show(
        context: Get.context!,
        title: "Error updating password",
        type: ToastType.error,
      );
    } finally {
      isSetNewPasswordLoading.value = false;
    }
  }

  // Navigation helper
  void goToPage(int index) {
    currentPage.value = index;
    pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void unfocusKeyBoardOnApiCall() => FocusScope.of(Get.context!).unfocus();

  @override
  void onClose() {
    pageController.dispose();
    phoneCtrl.dispose();
    otpCtrl.dispose();
    passwordCtrl.dispose();
    confirmPasswordCtrl.dispose();
    super.onClose();
  }
}
