import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:otobix/Network/api_service.dart';
import 'package:otobix/Utils/app_constants.dart';
import 'package:otobix/Utils/app_urls.dart';
import 'package:otobix/helpers/device_info_helpers.dart';
import 'package:otobix/helpers/shared_prefs_helper.dart';

class GuestUserSetup {
  /// Checks whether a guest ID exists.
  static Future<bool> hasGuestId() async {
    final String guestId =
        await SharedPrefsHelper.getString(SharedPrefsHelper.guestIdKey) ?? '';
    return guestId.isNotEmpty;
  }

  /// Creates a guest user if one does not already exist.
  static Future<void> setupGuestUser() async {
    try {
      // Check if guest ID already exists
      final existingGuestId = await hasGuestId();

      if (existingGuestId) {
        return;
      }

      // Get device information
      final body = {
        'role': AppConstants.roles.dealer,
        'deviceId': await DeviceInfoHelper.getDeviceId(),
        'platform': DeviceInfoHelper.getPlatform(),
        'appVersion': await DeviceInfoHelper.getAppVersion(),
        'osVersion': await DeviceInfoHelper.getOsVersion(),
        'deviceModel': await DeviceInfoHelper.getDeviceModel(),
        'deviceManufacturer': await DeviceInfoHelper.getDeviceManufacturer(),
        'timezone': DeviceInfoHelper.getTimezone(),
      };

      // Call backend create guest API
      final response = await ApiService.post(
        endpoint: AppUrls.createGuestUser,
        body: body,
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final guestId = responseBody['guestId'] ?? '';
        // Store guest ID securely
        await SharedPrefsHelper.saveString(
          SharedPrefsHelper.guestIdKey,
          guestId,
        );
      } else {
        debugPrint('GuestUserSetup Error: ${responseBody['message']}');
      }
    } catch (error) {
      debugPrint('GuestUserSetup Error: $error');
    }
  }
}
