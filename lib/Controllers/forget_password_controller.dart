import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:otobix/Network/api_service.dart';
import 'package:otobix/Utils/app_constants.dart';
import 'package:otobix/Utils/app_urls.dart';
import 'package:otobix/Views/Login/login_page.dart';
import 'package:otobix/Widgets/toast_widget.dart';

class ForgetPasswordController extends GetxController {
  final formKey = GlobalKey<FormState>();

  RxBool isFourDigit = false.obs; // 👈 Reactive toggle for OTP length
  String requestId = '';
  String verificationToken = '';

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
    if (isSendOtpLoading.value) return;

    isSendOtpLoading.value = true;
    try {
      final phoneNumber = phoneCtrl.text.trim();

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

      final requestBody = {
        "mobile": phoneNumber,
        "purpose": AppConstants.otpPurposes.forgetPassword,
      };

      final response = await ApiService.post(
        endpoint: AppUrls.sendOtp,
        body: requestBody,
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // ✅ Success navigate to second page
        requestId = responseBody['data']['requestId'].toString();
        goToPage(1);
        ToastWidget.show(
          context: Get.context!,
          title: "Success",
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

  // Verify OTP
  Future<void> verifyOtp() async {
    if (isVerifyOtpLoading.value) return;

    isVerifyOtpLoading.value = true;
    try {
      final response = await ApiService.post(
        endpoint: AppUrls.verifyOtp,
        body: {"requestId": requestId, "otp": otpCtrl.text.trim().toString()},
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        verificationToken =
            responseBody['data']['verificationToken'].toString();

        // ✅ OTP verified successfully
        goToPage(2);
        ToastWidget.show(
          context: Get.context!,
          title: "Success",
          subtitle: "OTP Verified Successfully",
          type: ToastType.success,
        );
      } else if (response.statusCode == 400) {
        // ❌ Invalid OTP
        final errorMessage = responseBody['message'] ?? 'Please try again';
        ToastWidget.show(
          context: Get.context!,
          title: "Failed to verify OTP",
          subtitle: errorMessage,
          toastDuration: 10,
          type: ToastType.error,
        );
      } else {
        ToastWidget.show(
          context: Get.context!,
          title: "Failed",
          subtitle: "Failed to verify OTP",
          type: ToastType.error,
        );
      }
    } catch (e) {
      debugPrint(e.toString());
      ToastWidget.show(
        context: Get.context!,
        title: "Error",
        subtitle: "Error verifying OTP",
        type: ToastType.error,
      );
    } finally {
      isVerifyOtpLoading.value = false;
    }
  }

  // Set new password
  Future<void> setNewPassword() async {
    if (isSetNewPasswordLoading.value) return;

    isSetNewPasswordLoading.value = true;
    try {
      final response = await ApiService.put(
        endpoint: AppUrls.forgetPassword,
        body: {
          "otpVerificationToken": verificationToken,
          "password": passwordCtrl.text.trim(),
        },
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        ToastWidget.show(
          context: Get.context!,
          title: "Success",
          subtitle: "Password updated successfully",
          type: ToastType.success,
        );

        phoneCtrl.clear();
        passwordCtrl.clear();
        confirmPasswordCtrl.clear();
        otpCtrl.clear();

        Get.offAll(() => LoginPage());
      } else if (response.statusCode == 400) {
        final String errorMessage =
            responseBody['message'] ?? 'Failed to update password';
        ToastWidget.show(
          context: Get.context!,
          title: "Failed",
          subtitle: errorMessage,
          toastDuration: 10,
          type: ToastType.error,
        );
      } else if (response.statusCode == 404) {
        ToastWidget.show(
          context: Get.context!,
          title: "Failed",
          subtitle: "No account associated with this phone number",
          type: ToastType.error,
        );
      } else {
        ToastWidget.show(
          context: Get.context!,
          title: "Failed",
          subtitle: "Failed to update password. Please try again",
          type: ToastType.error,
        );
      }
    } catch (e) {
      ToastWidget.show(
        context: Get.context!,
        title: "Error",
        subtitle: "Error updating password",
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
