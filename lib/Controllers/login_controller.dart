import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:otobix/Network/api_service.dart';
import 'package:otobix/Services/notification_sevice.dart';
import 'package:otobix/Services/user_activity_log_service.dart';
import 'package:otobix/Utils/app_constants.dart';
import 'package:otobix/Utils/app_urls.dart';
import 'package:otobix/Views/Dealer%20Panel/rejected_screen.dart';
import 'package:otobix/Views/Register/waiting_for_approval_page.dart';
import 'package:otobix/Views/Dealer%20Panel/bottom_navigation_page.dart';
import 'package:otobix/Widgets/toast_widget.dart';
import 'package:otobix/helpers/shared_prefs_helper.dart';

class LoginController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    clearFields();
  }

  RxBool isLoading = false.obs;
  RxBool obsecureText = true.obs;
  final userNameController = TextEditingController();
  final phoneNumberController = TextEditingController();
  final passwordController = TextEditingController();

  Future<void> loginUser() async {
    isLoading.value = true;
    try {
      String dealerName = userNameController.text.trim();
      String contactNumber = phoneNumberController.text.trim();
      final requestBody = {
        "userName": dealerName,
        "phoneNumber": contactNumber,
        "password": passwordController.text.trim(),
      };
      // debugPrint("Sending body: $requestBody");
      final response = await ApiService.post(
        endpoint: AppUrls.login,
        body: requestBody,
      );
      final data = jsonDecode(response.body);
      // debugPrint("Status Code: ${response.statusCode}");
      if (response.statusCode == 200) {
        final token = data['token'];
        final user = data['user'];
        final userType = user['userType'];
        final userId = user['id'];
        final phoneNumber = user['phoneNumber'];
        final email = user['email'];
        final approvalStatus = user['approvalStatus'];
        final entityType = user['entityType'] ?? "";
        // debugPrint("userType: $userType");
        // debugPrint("token: $token");
        // debugPrint("approvalStatus: $approvalStatus");

        // Link current userid in OneSignal to receive push notifications
        await NotificationService.instance.login(userId);

        if (approvalStatus == AppConstants.roles.userStatusApproved) {
          await SharedPrefsHelper.saveString(SharedPrefsHelper.tokenKey, token);
          await SharedPrefsHelper.saveString(
            SharedPrefsHelper.userApprovalStatusKey,
            approvalStatus,
          );
        }

        // debugPrint("Token saved in local: $token");
        await SharedPrefsHelper.saveString(
          SharedPrefsHelper.userKey,
          jsonEncode(user),
        );
        await SharedPrefsHelper.saveString(
          SharedPrefsHelper.userTypeKey,
          userType,
        );
        await SharedPrefsHelper.saveString(
          SharedPrefsHelper.userPhoneNumberKey,
          phoneNumber,
        );
        await SharedPrefsHelper.saveString(
          SharedPrefsHelper.userEmailKey,
          email,
        );
        await SharedPrefsHelper.saveString(SharedPrefsHelper.userIdKey, userId);
        await SharedPrefsHelper.saveString(
          SharedPrefsHelper.entityTypeKey,
          entityType,
        );
        // debugPrint("userId: $userId");
        // if (userType == AppConstants.roles.admin) {
        //   Get.offAll(() => AdminDashboard());
        // } else {
        if (approvalStatus == AppConstants.roles.userStatusPending) {
          final entityType = (user['entityType'] as String?)?.trim();
          final entityDocuments = await _fetchEntityDocuments(entityType);
          Get.to(
            () => WaitingForApprovalPage(
              documents: entityDocuments,
              userRole: userType,
            ),
          );

          // Log event
          UserActivityLogService.logEvent(
            userId: userId,
            event: AppConstants.userActivityLogEvents.login,
            eventDetails: 'User status was pending',
            metadata: {'approvalStatus': approvalStatus},
          );
        } else if (approvalStatus == AppConstants.roles.userStatusApproved) {
          // if (userType == AppConstants.roles.customer) {
          //   Get.offAll(() => CustomerHomepage());
          // } else if (userType == AppConstants.roles.salesManager) {
          //   Get.offAll(() => SalesManagerHomepage());
          // } else
          if (userType == AppConstants.roles.dealer) {
            Get.offAll(() => BottomNavigationPage());

            // Log event
            UserActivityLogService.logEvent(
              userId: userId,
              event: AppConstants.userActivityLogEvents.login,
              eventDetails: 'Logged in successfully',
              metadata: {'approvalStatus': approvalStatus},
            );
          } else {
            ToastWidget.show(
              context: Get.context!,
              title: "No Account associated with these credentials.",
              type: ToastType.error,
            );
          }
        } else if (approvalStatus == AppConstants.roles.userStatusRejected) {
          Get.to(() => RejectedScreen(userId: user['id']));

          // Log event
          UserActivityLogService.logEvent(
            userId: userId,
            event: AppConstants.userActivityLogEvents.login,
            eventDetails: 'User status was rejected',
            metadata: {'approvalStatus': approvalStatus},
          );
        } else {
          ToastWidget.show(
            context: Get.context!,
            title: "Invalid approval status. Please contact admin.",
            type: ToastType.error,
          );
        }
        // }
      } else {
        debugPrint("data: $data");
        ToastWidget.show(
          context: Get.context!,
          title: data['message'] ?? "Invalid credentials",
          type: ToastType.error,
        );
      }
    } catch (e) {
      debugPrint("Error: $e");
      ToastWidget.show(
        context: Get.context!,
        title: "Something went wrong. Please try again.",
        type: ToastType.error,
      );
    } finally {
      isLoading.value = false;
    }
  }

  String? validatePassword(String password) {
    if (password.isEmpty) return "Password is required.";
    if (password.length < 8) {
      return "Password must be at least 8 characters long.";
    }
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return "At least one uppercase letter required.";
    }
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      return "At least one lowercase letter required.";
    }
    if (!RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-]').hasMatch(password)) {
      return "At least one special character required.";
    }
    return null;
  }

  // Fetch entity documents
  Future<List<String>> _fetchEntityDocuments(String? entityType) async {
    final fallback = <String>[
      // optional: keep empty list if you don't want a fallback
      'No documents found',
    ];

    if (entityType == null || entityType.trim().isEmpty) return fallback;

    try {
      final response = await ApiService.get(
        endpoint: AppUrls.getEntityDocumentsByName(
          entityName: entityType.trim(),
        ),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final data = (json['data'] ?? {}) as Map<String, dynamic>;
        final docs = (data['documents'] ?? []) as List;
        return docs.map((e) => '$e').toList();
      }
    } catch (error) {
      // ignore and use fallback
      debugPrint("Error: $error");
    }
    return fallback;
  }

  // Clear fields
  void clearFields() {
    userNameController.clear();
    phoneNumberController.clear();
    passwordController.clear();
    obsecureText.value = true;
  }
}
