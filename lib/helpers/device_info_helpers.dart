import 'dart:io';

import 'package:android_id/android_id.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

class DeviceInfoHelper {
  static final DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();
  static final AndroidId _androidIdPlugin = AndroidId();

  /// Returns the platform.
  static String getPlatform() {
    if (Platform.isAndroid) {
      return 'android';
    }

    if (Platform.isIOS) {
      return 'ios';
    }

    return 'unknown';
  }

  /// Returns the application version.
  static Future<String> getAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    // packageInfo.version => "1.0.7"
    // packageInfo.buildNumber => "12"
    return '${packageInfo.version} (${packageInfo.buildNumber})';
  }

  /// Returns the operating system version.
  static Future<String> getOsVersion() async {
    if (Platform.isAndroid) {
      final androidInfo = await _deviceInfoPlugin.androidInfo;

      return androidInfo.version.release;
    }

    if (Platform.isIOS) {
      final iosInfo = await _deviceInfoPlugin.iosInfo;

      return iosInfo.systemVersion;
    }

    return '';
  }

  /// Returns the device model.
  static Future<String> getDeviceModel() async {
    if (Platform.isAndroid) {
      final androidInfo = await _deviceInfoPlugin.androidInfo;

      return androidInfo.model;
    }

    if (Platform.isIOS) {
      final iosInfo = await _deviceInfoPlugin.iosInfo;

      return iosInfo.utsname.machine;
    }

    return '';
  }

  /// Returns the device manufacturer.
  static Future<String> getDeviceManufacturer() async {
    if (Platform.isAndroid) {
      final androidInfo = await _deviceInfoPlugin.androidInfo;

      return androidInfo.manufacturer;
    }

    if (Platform.isIOS) {
      return 'Apple';
    }

    return '';
  }

  /// Returns the device timezone.
  static String getTimezone() {
    return DateTime.now().timeZoneName;
  }

  /// Returns Device ID (Android ID or iOS Identifier for Vendor)
  static Future<String> getDeviceId() async {
    if (Platform.isAndroid) {
      return await _androidIdPlugin.getId() ?? '';
    }

    if (Platform.isIOS) {
      final iosInfo = await _deviceInfoPlugin.iosInfo;
      return iosInfo.identifierForVendor ?? '';
    }

    return '';
  }
}
