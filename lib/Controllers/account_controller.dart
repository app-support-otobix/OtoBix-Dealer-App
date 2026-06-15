import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:otobix/Controllers/login_controller.dart';
import 'package:otobix/Services/notification_sevice.dart';
import 'package:otobix/Utils/app_constants.dart';
import 'package:otobix/Views/Login/login_page.dart';
import 'package:otobix/Widgets/toast_widget.dart';
import 'package:otobix/helpers/shared_prefs_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:otobix/Network/api_service.dart';
import 'package:otobix/Utils/app_urls.dart';

class AccountController extends GetxController {
  // String userRoleFromSharedPrefs = '';
  final RxString userRoleFromSharedPrefs = ''.obs;
  RxString userRole = ''.obs;
  final RxBool roleReady = false.obs;

  TextEditingController userName = TextEditingController();
  TextEditingController userEmail = TextEditingController();
  TextEditingController phoneNumber = TextEditingController();
  TextEditingController location = TextEditingController();

  TextEditingController dealershipName = TextEditingController();
  TextEditingController entityType = TextEditingController();
  TextEditingController primaryContactPerson = TextEditingController();
  TextEditingController primaryContactNumber = TextEditingController();
  TextEditingController secondaryContactPerson = TextEditingController();
  TextEditingController secondaryContactNumber = TextEditingController();

  RxList<String> addressList = <String>[].obs;

  Rx<File?> imageFile = Rx<File?>(null); // for mobile
  Rx<Uint8List?> imageBytes = Rx<Uint8List?>(null); // for web
  RxString imageName = ''.obs;
  RxString imageUrl = ''.obs; // network image
  RxString username = ''.obs;
  RxString useremail = ''.obs;
  RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    // getUserRoleFromSharedPrefs();
    getUserProfile();
  }

  // void getUserRoleFromSharedPrefs() async {
  //   userRoleFromSharedPrefs.value =
  //       await SharedPrefsHelper.getString(SharedPrefsHelper.userTypeKey) ?? '';
  // }

  // convenience getter: single source of truth
  bool get isAdmin =>
      (userRoleFromSharedPrefs.value == AppConstants.roles.admin) ||
      (userRole.value == AppConstants.roles.admin);

  // getUserProfile: keep as-is, but DON’T call it again from the page

  Future<void> getUserProfile() async {
    try {
      isLoading.value = true;

      final token = await SharedPrefsHelper.getString(
        SharedPrefsHelper.tokenKey,
      );
      // debugPrint('Token: $token');

      if (token == null) {
        debugPrint('User not logged in');
        return;
      }

      final response = await ApiService.get(
        endpoint: AppUrls.getUserProfile,
        // headers: {
        //   'Authorization': 'Bearer $token',
        //   'Content-Type': 'application/json',
        // },
      );

      // debugPrint('API response: ${response.body}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['profile'];

        userRole.value = data['role'] ?? '';
        userName.text = data['name'] ?? '';
        username.value = data['name'] ?? '';
        userEmail.text = data['email'] ?? '';
        useremail.value = data['email'] ?? '';
        phoneNumber.text = data['phoneNumber'] ?? '';
        location.text = data['location'] ?? '';
        imageUrl.value = data['image'] ?? '';

        if (userRole.value == 'Dealer') {
          dealershipName.text = data['dealershipName'] ?? '';
          entityType.text = data['entityType'] ?? '';
          primaryContactPerson.text = data['primaryContactPerson'] ?? '';
          primaryContactNumber.text = data['primaryContactNumber'] ?? '';
          secondaryContactPerson.text = data['secondaryContactPerson'] ?? '';
          secondaryContactNumber.text = data['secondaryContactNumber'] ?? '';
        }

        if (data['addressList'] != null) {
          addressList.value = List<String>.from(data['addressList']);
        }

        SharedPrefsHelper.saveString(
          SharedPrefsHelper.userTypeKey,
          userRole.value,
        );
      } else {
        debugPrint('Profile fetch failed: ${response.statusCode}');
        debugPrint(response.body);
      }
    } catch (e) {
      debugPrint('Error in getUserProfile: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> pickImageFromDevice() async {
    if (kIsWeb) {
      final result = await FilePicker.platform.pickFiles(type: FileType.image);
      if (result != null) {
        imageBytes.value = result.files.first.bytes;
        imageName.value = result.files.first.name;
        imageUrl.value = '';
        imageFile.value = null;
      }
    } else {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
      );
      if (pickedFile != null) {
        imageFile.value = File(pickedFile.path);
        imageUrl.value = '';
        imageBytes.value = null;
      }
    }
  }

  Future<void> updateProfile() async {
    // debugPrint('Update profile called');
    try {
      isLoading.value = true;

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        ToastWidget.show(
          context: Get.context!,
          title: 'Error',
          subtitle: 'User not logged in',
          type: ToastType.error,
        );
        return;
      }

      final uri = Uri.parse(AppUrls.updateProfile);
      final request = http.MultipartRequest('PUT', uri);
      request.headers['Authorization'] = 'Bearer $token';

      // Add text fields
      request.fields.addAll({
        "userName": userName.text,
        "email": userEmail.text,
        "phoneNumber": phoneNumber.text,
        "location": location.text,
        "dealershipName": dealershipName.text,
        "entityType": entityType.text,
        "primaryContactPerson": primaryContactPerson.text,
        "primaryContactNumber": primaryContactNumber.text,
        "secondaryContactPerson": secondaryContactPerson.text,
        "secondaryContactNumber": secondaryContactNumber.text,
        "addressList": addressList.join(','),
      });

      // Add image if selected
      if (kIsWeb && imageBytes.value != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'image',
            imageBytes.value!,
            filename: imageName.value,
            contentType: MediaType('image', 'jpeg'),
          ),
        );
      } else if (!kIsWeb && imageFile.value != null) {
        final file = imageFile.value!;
        final fileName = file.path.split('/').last;
        request.files.add(
          await http.MultipartFile.fromPath(
            'image',
            file.path,
            filename: fileName,
            contentType: MediaType('image', 'png'),
          ),
        );
      } else if (imageUrl.value.isNotEmpty) {
        request.fields['image'] = imageUrl.value;
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('Update response: ${response.statusCode}');
      debugPrint(response.body);

      if (response.statusCode == 200) {
        ToastWidget.show(
          context: Get.context!,
          title: 'Success',
          subtitle: 'Profile updated successfully',
          type: ToastType.success,
        );
        imageFile.value = null;
        getUserProfile();

        Get.back();
        // ToastWidget.show(
        //   context: Get.context!,
        //   title: 'Profile updated successfully',
        //   type: ToastType.success,
        // );
      } else {
        ToastWidget.show(
          context: Get.context!,
          title: 'Error',
          subtitle: 'Failed to update profile',
          type: ToastType.error,
        );
      }
    } catch (e) {
      debugPrint('Update Exception: $e');
      ToastWidget.show(
        context: Get.context!,
        title: 'Error',
        subtitle: 'Something went wrong',
        type: ToastType.error,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    try {
      isLoading.value = true;

      final userId = await SharedPrefsHelper.getString(
        SharedPrefsHelper.userIdKey,
      );
      if (userId == null) {
        ToastWidget.show(
          context: Get.context!,
          title: 'Error',
          subtitle: 'User ID not found',
          type: ToastType.error,
        );
        return;
      }

      final endpoint = AppUrls.logout(userId);
      final response = await ApiService.post(endpoint: endpoint, body: {});
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        // unlink the device from the current user (call on sign-out)
        NotificationService.instance.logout();
        await SharedPrefsHelper.remove(SharedPrefsHelper.tokenKey);
        await SharedPrefsHelper.remove(SharedPrefsHelper.userKey);
        await SharedPrefsHelper.remove(SharedPrefsHelper.userTypeKey);
        await SharedPrefsHelper.remove(SharedPrefsHelper.userIdKey);

        ToastWidget.show(
          context: Get.context!,
          title: 'Logout successful',
          type: ToastType.success,
        );
        Get.delete<LoginController>();
        Get.offAll(() => LoginPage());
      } else {
        ToastWidget.show(
          context: Get.context!,
          title: 'Logout Failed',
          subtitle: data['message'] ?? 'Server error',
          type: ToastType.error,
        );
      }
    } catch (e) {
      debugPrint('Logout Exception: $e');
      ToastWidget.show(
        context: Get.context!,
        title: 'Error',
        subtitle: 'Something went wrong',
        type: ToastType.error,
      );
    } finally {
      isLoading.value = false;
    }
  }
}
