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
    isLoading.value = true;
    try {
      // final formattedPhoneNumber =
      //     phoneNumber.startsWith('0')
      //         ? '+92${phoneNumber.substring(1)}'
      //         : '+92$phoneNumber';

      if (selectedRole.value.isEmpty) {
        // ToastWidget.show(
        //   context: Get.context!,
        //   title: "Please select a role",
        //   type: ToastType.error,
        // );
        // return;
        selectedRole.value = AppConstants.roles.dealer;
      }
      // if (selectedRole.value == 'Customer' ||
      //     selectedRole.value == 'Sales\nManager') {
      //   ToastWidget.show(
      //     context: Get.context!,
      //     message: "${selectedRole.value} role is not available yet",
      //     type: ToastType.error,
      //   );
      //   return;
      // }

      // For both pak and indian numbers
      // final RegExp pakIndiaRegex = RegExp(r'^[3-9]\d{9}$');

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
        final String requestId = data['data']['requestId'] ?? '';
        final String internalStatusCode =
            data['data']?['statusCode']?.toString() ?? '';

        if (internalStatusCode == "101") {
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
      isLoading.value = false;
    }
  }

  // Dummy send OTP
  // Future<void> dummySendOtp({required String phoneNumber}) async {
  //   isLoading.value = true;
  //   // debugPrint("Sending OTP to $phoneNumber");
  //   try {
  //     if (selectedRole.value.isEmpty) {
  //       //   ToastWidget.show(
  //       //     context: Get.context!,
  //       //     title: "Please select a role",
  //       //     type: ToastType.error,
  //       //   );
  //       //   return;
  //       selectedRole.value = AppConstants.roles.dealer;
  //     }

  //     // For indian numbers only
  //     final RegExp indianRegex = RegExp(r'^[6-9]\d{9}$');

  //     // For both pak and indian numbers
  //     // final RegExp pakIndiaRegex = RegExp(r'^[3-9]\d{9}$');

  //     if (!indianRegex.hasMatch(phoneNumber)) {
  //       ToastWidget.show(
  //         context: Get.context!,
  //         title: "Invalid mobile number",
  //         subtitle: "Please enter a valid mobile number (starts with 6-9)",
  //         type: ToastType.error,
  //       );
  //       return;
  //     }

  //     await Future.delayed(const Duration(seconds: 2), () {
  //       Get.to(
  //         () => RegisterPinCodePage(
  //           phoneNumber: phoneNumber,
  //           userRole: selectedRole.value,
  //           requestId: "",
  //         ),
  //       );
  //     });
  //     debugPrint("OTP Sent Successfully (Dummy) $phoneNumber $selectedRole");
  //     ToastWidget.show(
  //       context: Get.context!,
  //       title: "OTP Sent Successfully (Dummy)",
  //       type: ToastType.success,
  //     );
  //   } catch (e) {
  //     debugPrint(e.toString());
  //     ToastWidget.show(
  //       context: Get.context!,
  //       title: "Failed to send OTP",
  //       type: ToastType.error,
  //     );
  //   } finally {
  //     isLoading.value = false;
  //   }
  // }

  // Clear fields
  void clearFields() {
    isLoading.value = false;
    phoneController.clear();
    selectedRole.value = '';
  }
}
