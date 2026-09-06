import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:otobix/Network/api_service.dart';
import 'package:otobix/Utils/app_constants.dart';
import 'package:otobix/Utils/app_urls.dart';
import 'package:otobix/Views/Register/register_pin_code_page.dart';
import 'package:otobix/Widgets/toast_widget.dart';

class RegisterController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    clearFields();
  }

  final TextEditingController phoneController = TextEditingController();

  RxBool isLoading = false.obs;
  RxString selectedRole = ''.obs;

  void setSelectedRole(String role) {
    selectedRole.value = role;
    update();
  }

  // Send OTP
  Future<void> sendOTP({required String phoneNumber}) async {
    if (isLoading.value) return;

    isLoading.value = true;
    try {
      if (selectedRole.value.isEmpty) {
        selectedRole.value = AppConstants.roles.dealer;
      }

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
        "purpose": AppConstants.otpPurposes.register,
      };

      final response = await ApiService.post(
        endpoint: AppUrls.sendOtp,
        body: requestBody,
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final String requestId = responseBody['data']['requestId'].toString();

        // ✅ Success
        Get.to(
          () => RegisterPinCodePage(
            phoneNumber: phoneNumber,
            userRole: selectedRole.value,
            requestId: requestId,
          ),
        );
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
      isLoading.value = false;
    }
  }

  // Clear fields
  void clearFields() {
    isLoading.value = false;
    phoneController.clear();
    selectedRole.value = '';
  }
}
