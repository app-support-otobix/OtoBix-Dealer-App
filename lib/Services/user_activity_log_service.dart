import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:otobix/Network/api_service.dart';
import 'package:otobix/Utils/app_constants.dart';
import 'package:otobix/Utils/app_urls.dart';
import 'package:package_info_plus/package_info_plus.dart';

class UserActivityLogService {
  // Cache app version for reuse
  static String? _cachedAppVersion;

  // Get app version
  static Future<String> getAppVersion() async {
    try {
      if (_cachedAppVersion != null && _cachedAppVersion!.isNotEmpty) {
        return _cachedAppVersion!;
      }
      final packageInfo = await PackageInfo.fromPlatform();
      // packageInfo.version => "1.0.7"
      // packageInfo.buildNumber => "12"
      _cachedAppVersion = '${packageInfo.version} (${packageInfo.buildNumber})';
      return _cachedAppVersion ?? '';
    } catch (e) {
      debugPrint("App version fetch error: $e");
      return '';
    }
  }

  // Helper function to add log on app launch
  static Future<void> logAppLaunchEvent({required String userId}) async {
    try {
      final safeUserId = userId.trim();
      final safeEvent = AppConstants.userActivityLogEvents.appLaunched;

      if (safeUserId.isEmpty || safeEvent.isEmpty) return;

      final appVersion = await getAppVersion();

      final requestBody = {
        'userId': safeUserId,
        'event': safeEvent,
        'eventDetails': 'User launched the app',
        'appName': AppConstants.appDisplayName,
        'appVersion': appVersion,
        'metadata': {},
      };

      final response = await ApiService.post(
        endpoint: AppUrls.saveAppVersionOnAppLaunch,
        body: requestBody,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint("Activity log for ($safeEvent) added successfully.");
      } else {
        debugPrint(
          "Activity log failed: ${response.statusCode} ${response.body}",
        );
      }
    } catch (e) {
      debugPrint("Activity log error: $e");
    }
  }

  // Helper function to add log
  static Future<void> rawLogEvent({
    required String userId,
    required String event,
    String eventDetails = '',
    Map<String, dynamic> metadata = const {},
  }) async {
    try {
      final safeUserId = userId.trim();
      final safeEvent = event.trim();

      if (safeUserId.isEmpty || safeEvent.isEmpty) return;

      final appVersion = await getAppVersion();

      final requestBody = {
        'userId': safeUserId,
        'event': safeEvent,
        'eventDetails': eventDetails.trim(),
        'appName': AppConstants.appDisplayName,
        'appVersion': appVersion,
        'metadata': Map<String, dynamic>.from(metadata),
      };

      final response = await ApiService.post(
        endpoint: AppUrls.addUserActivityLog,
        body: requestBody,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint("Activity log for ($safeEvent) added successfully.");
      } else {
        debugPrint(
          "Activity log failed: ${response.statusCode} ${response.body}",
        );
      }
    } catch (e) {
      debugPrint("Activity log error: $e");
    }
  }

  // Actual log event function used everywhere
  static void logEvent({
    required String userId,
    required String event,
    String eventDetails = '',
    Map<String, dynamic> metadata = const {},
  }) {
    unawaited(
      rawLogEvent(
        userId: userId,
        event: event,
        eventDetails: eventDetails,
        metadata: metadata,
      ),
    );
  }
}
