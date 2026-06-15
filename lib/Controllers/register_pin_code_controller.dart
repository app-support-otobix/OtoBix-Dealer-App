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
          Get.delete<RegistrationFormController>();
          Get.to(
            () => RegistrationFormPage(
              userRole: AppConstants.roles.dealer,
              phoneNumber: phoneNumber,
            ),
          );
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
    }
  }

  // // Dummy verify OTP
  // Future<void> dummyVerifyOtp({
  //   required String phoneNumber,
  //   required String otp,
  //   required String userType,
  // }) async {
  //   ToastWidget.show(
  //     context: Get.context!,
  //     title: "OTP Verified Successfully",
  //     type: ToastType.success,
  //   );
  //   Get.delete<RegistrationFormController>();
  //   Get.to(
  //     () => RegistrationFormPage(userRole: userType, phoneNumber: phoneNumber),
  //   );
  // }
}
