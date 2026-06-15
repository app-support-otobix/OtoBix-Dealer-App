import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:otobix/Controllers/razorpay_payment_controller.dart';
import 'package:otobix/Controllers/service_history_controller.dart';
import 'package:otobix/Network/api_service.dart';
import 'package:otobix/Utils/app_urls.dart';
import 'package:otobix/Widgets/toast_widget.dart';
import 'package:otobix/helpers/shared_prefs_helper.dart';

class ServiceHistoryCheckoutController extends GetxController {
  final String registrationNumber;
  final String chassisNumber;
  final String engineNumber;
  final String make;
  final String model;
  final String bodyType;
  final DateTime? registrationDate;
  final String fuelType;
  final int ownerSerialNumber;
  final double rate;
  final double gst;
  final double total;

  ServiceHistoryCheckoutController({
    required this.registrationNumber,
    required this.chassisNumber,
    required this.engineNumber,
    required this.make,
    required this.model,
    required this.bodyType,
    required this.registrationDate,
    required this.fuelType,
    required this.ownerSerialNumber,
    required this.rate,
    required this.gst,
    required this.total,
  });

  RxBool isSubmitServiceHistoryRequestLoading = false.obs;

  final List<String> leftSummaryItems = [
    'Vehicle Service History',
    'Odometer Status',
    'Engine Status',
    'Gearbox Status',
    'Structural Status',
    'Flooded Status',
    'Blacklist Status',
  ];

  final List<String> rightSummaryItems = [
    'RC Status',
    'Hypothecation Details',
    'Insurance Details',
    'Challan Details',
    'PUC Details',
    'Registered RTO Details',
  ];

  String getOwnerSerialNumberString() {
    if (ownerSerialNumber == 1) {
      return '1st';
    } else if (ownerSerialNumber == 2) {
      return '2nd';
    } else if (ownerSerialNumber == 3) {
      return '3rd';
    } else {
      return '$ownerSerialNumber th';
    }
  }

  // Request Service History
  Future<void> submitServiceHistoryRequest() async {
    if (isSubmitServiceHistoryRequestLoading.value) return;

    isSubmitServiceHistoryRequestLoading.value = true;

    try {
      final userData = await _getUserData();
      if (userData == null) return;

      final userId = userData['userId'] ?? "";
      final userEmail = userData['email'] ?? "";
      final userPhone = userData['phone'] ?? "";

      // ✅ 1) Start payment and WAIT for success
      final RazorpayPaymentController paymentController =
          Get.isRegistered<RazorpayPaymentController>()
              ? Get.find<RazorpayPaymentController>()
              : Get.put(RazorpayPaymentController());

      final success = await paymentController
          .pay(
            amountRupees: total,
            name: "Get Service History",
            description: "Service History Purchase",
            email: userEmail,
            phone: userPhone,
            notes: {"userId": userId, "registrationNumber": registrationNumber},
            receipt: "service_history_${DateTime.now().millisecondsSinceEpoch}",
            userId: userId,
            meta: {"registrationNumber": registrationNumber},
          )
          .timeout(
            const Duration(minutes: 3),
            onTimeout: () {
              throw Exception("Payment timed out. Please try again.");
            },
          );

      // ✅ 2) Payment success => now call actual API with paymentId
      final requestBody = {
        "paymentId": success.paymentId, // ✅ IMPORTANT
        "userId": userId,
        "registrationNumber": registrationNumber,
        "chassisNumber": chassisNumber,
        "engineNumber": engineNumber,
        "make": make,
        "model": model,
        "bodyType": bodyType,
        "registrationDate": registrationDate?.toIso8601String(),
        "fuelType": fuelType,
        "ownerSerialNumber": ownerSerialNumber,
        "rate": rate,
        "gst": gst,
        "total": total,
      };

      final response = await ApiService.post(
        endpoint: AppUrls.submitServiceHistoryRequest,
        body: requestBody,
      );

      // debugPrint(response.body);

      if (response.statusCode == 200) {
        final ServiceHistoryController serviceHistoryController =
            Get.isRegistered<ServiceHistoryController>()
                ? Get.find<ServiceHistoryController>()
                : Get.put(ServiceHistoryController());
        serviceHistoryController.fetchServiceHistoryReportsList();
        Get.back();
        ToastWidget.show(
          context: Get.context!,
          title: 'Submitted',
          subtitle: 'Service history request successfully submitted.',
          type: ToastType.success,
        );
      } else if (response.statusCode == 409) {
        final ServiceHistoryController serviceHistoryController =
            Get.isRegistered<ServiceHistoryController>()
                ? Get.find<ServiceHistoryController>()
                : Get.put(ServiceHistoryController());
        serviceHistoryController.fetchServiceHistoryReportsList();
        Get.back();
        ToastWidget.show(
          context: Get.context!,
          title: 'Already Submitted',
          subtitle:
              'Service history request already submitted for this vehicle.',
          type: ToastType.success,
        );
      } else {
        ToastWidget.show(
          context: Get.context!,
          title: 'Failed',
          subtitle:
              'Failed to submit service history request. Please try again.',
          type: ToastType.error,
        );
      }
    } catch (error) {
      debugPrint('Error submitting service history request: $error');
      ToastWidget.show(
        context: Get.context!,
        title: 'Error',
        subtitle: 'Error submitting service history request. Please try again.',
        type: ToastType.error,
      );
    } finally {
      isSubmitServiceHistoryRequestLoading.value = false;
    }
  }

  // Get email and phone and store in shared prefs if they are empty
  Future<Map<String, String>?> _getUserData() async {
    String userId =
        await SharedPrefsHelper.getString(SharedPrefsHelper.userIdKey) ?? "";
    String userEmail =
        await SharedPrefsHelper.getString(SharedPrefsHelper.userEmailKey) ?? "";
    String userPhone =
        await SharedPrefsHelper.getString(
          SharedPrefsHelper.userPhoneNumberKey,
        ) ??
        "";

    // all data already available
    if (userId.isNotEmpty && userEmail.isNotEmpty && userPhone.isNotEmpty) {
      return {"userId": userId, "email": userEmail, "phone": userPhone};
    }

    // if userId itself is missing, can't recover from profile response
    if (userId.isEmpty) {
      _showSessionToast();
      return null;
    }

    try {
      final response = await ApiService.get(endpoint: AppUrls.getUserProfile);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true && data['profile'] != null) {
          final profile = data['profile'];

          final fetchedEmail = profile['email']?.toString() ?? "";
          final fetchedPhone = profile['phoneNumber']?.toString() ?? "";

          if (fetchedEmail.isNotEmpty) {
            await SharedPrefsHelper.saveString(
              SharedPrefsHelper.userEmailKey,
              fetchedEmail,
            );
            userEmail = fetchedEmail;
          }

          if (fetchedPhone.isNotEmpty) {
            await SharedPrefsHelper.saveString(
              SharedPrefsHelper.userPhoneNumberKey,
              fetchedPhone,
            );
            userPhone = fetchedPhone;
          }
        }
      }

      if (userId.isNotEmpty && userEmail.isNotEmpty && userPhone.isNotEmpty) {
        return {"userId": userId, "email": userEmail, "phone": userPhone};
      }

      _showSessionToast();
      return null;
    } catch (e) {
      debugPrint('Error getting user data: $e');
      _showSessionToast();
      return null;
    }
  }

  void _showSessionToast() {
    if (Get.context == null) return;

    ToastWidget.show(
      context: Get.context!,
      title: 'Session update required',
      subtitle: 'Please sign in again to continue.',
      toastDuration: 10,
      type: ToastType.error,
    );
  }
}
