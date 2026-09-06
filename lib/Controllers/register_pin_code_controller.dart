import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:otobix/Controllers/registration_form_controller.dart';
import 'package:otobix/Network/api_service.dart';
import 'package:otobix/Utils/app_constants.dart';
import 'package:otobix/Utils/app_urls.dart';
import 'package:otobix/Views/Register/registration_form_page.dart';
import 'package:otobix/Widgets/toast_widget.dart';

class RegisterPinCodeController extends GetxController {
  RxBool isFourDigit = false.obs; // 👈 Reactive toggle for OTP length

  // Verify OTP
  Future<void> verifyOtp({
    required String requestId,
    required String otp,
    required String phoneNumber,
  }) async {
    try {
      final response = await ApiService.post(
        endpoint: AppUrls.verifyOtp,
        body: {"requestId": requestId, "otp": otp},
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final String verificationToken =
            responseBody['data']['verificationToken'].toString();

        // ✅ OTP verified successfully
        ToastWidget.show(
          context: Get.context!,
          title: "Success",
          subtitle: "OTP Verified Successfully",
          type: ToastType.success,
        );
        Get.delete<RegistrationFormController>();
        Get.to(
          () => RegistrationFormPage(
            userRole: AppConstants.roles.dealer,
            phoneNumber: phoneNumber,
            verificationToken: verificationToken,
          ),
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
    }
  }
}
