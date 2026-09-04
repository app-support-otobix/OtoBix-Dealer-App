import 'dart:convert';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:otobix/Services/notification_sevice.dart';
import 'package:otobix/Utils/app_constants.dart';
import 'package:otobix/Views/Login/login_page.dart';
import 'package:otobix/helpers/shared_prefs_helper.dart';
import 'package:otobix/utils/app_urls.dart';
import 'package:otobix/widgets/toast_widget.dart';

class ApiService {
  static int _requestCounter = 0; // Temporary For Testing

  /// Prevent multiple API calls from refreshing the token at the same time.
  static Future<(bool isSuccessful, String message)>?
  _isAccessTokenRefreshInProgress;

  // -------------- GET Request --------------
  static Future<http.Response> get({
    required String endpoint,
    Map<String, String>? customHeaders,
  }) async {
    final url = Uri.parse(endpoint);

    return _sendRequest(() async {
      final requestHeaders = await _createHeaders(customHeaders);

      return http.get(url, headers: requestHeaders);
    }, endpoint);
  }

  // -------------- POST Request --------------
  static Future<http.Response> post({
    required String endpoint,
    Map<String, dynamic>? body,
    Map<String, String>? customHeaders,
  }) async {
    final url = Uri.parse(endpoint);

    return _sendRequest(() async {
      final requestHeaders = await _createHeaders(customHeaders);

      return http.post(
        url,
        headers: requestHeaders,
        body: jsonEncode(body ?? {}),
      );
    }, endpoint);
  }

  // -------------- PUT Request --------------
  static Future<http.Response> put({
    required String endpoint,
    Map<String, dynamic>? body,
    Map<String, String>? customHeaders,
  }) async {
    final url = Uri.parse(endpoint);

    return _sendRequest(() async {
      final requestHeaders = await _createHeaders(customHeaders);

      return http.put(
        url,
        headers: requestHeaders,
        body: jsonEncode(body ?? {}),
      );
    }, endpoint);
  }

  // -------------- Create Headers --------------
  static Future<Map<String, String>> _createHeaders([
    Map<String, String>? customHeaders,
  ]) async {
    final accessToken = await SharedPrefsHelper.getString(
      SharedPrefsHelper.accessTokenKey,
    );
    final appCheckToken = await FirebaseAppCheck.instance.getToken();

    return {
      // JWT Access Token
      if (accessToken != null && accessToken.isNotEmpty)
        'Authorization': 'Bearer $accessToken',

      // Firebase App Check
      if (appCheckToken != null && appCheckToken.isNotEmpty)
        'X-Firebase-AppCheck': appCheckToken,

      'Accept': 'application/json',
      'Content-Type': 'application/json',

      // Add Custom Headers
      ...?customHeaders,
    };
  }

  // -------------- Send Request --------------
  static Future<http.Response> _sendRequest(
    Future<http.Response> Function() originalRequest,
    String endpoint,
  ) async {
    final requestId = ++_requestCounter; // Temporary For Testing
    debugPrint(
      '➡️ [$requestId] API REQUEST: $endpoint',
    ); // Temporary For Testing

    final originalApiResponse = await originalRequest();

    debugPrint(
      '⬅️ [$requestId] API RESPONSE: [${originalApiResponse.statusCode}] $endpoint',
    ); // Temporary For Testing

    // Request successful and access token is valid
    if (originalApiResponse.statusCode != 401) {
      return originalApiResponse;
    }

    // Read server response
    String? errorCode;
    String incomingApprovalStatus = '';

    try {
      final dynamic responseBody = jsonDecode(originalApiResponse.body);

      if (responseBody is Map<String, dynamic>) {
        errorCode = responseBody['code'] as String?;
        incomingApprovalStatus = responseBody['approvalStatus'] ?? '';
      }
    } catch (_) {
      // Ignore JSON parsing errors.
    }

    debugPrint(
      '⬅️ [$requestId] Error Code: $errorCode',
    ); // Temporary For Testing

    // Access token expired
    if (errorCode == 'TOKEN_EXPIRED') {
      final (isSuccessful, message) = await _refreshAccessTokenIfNeeded();

      if (isSuccessful) {
        // New access token has been saved.
        // Retry the ORIGINAL request once.
        return await originalRequest();
      }

      // Refresh failed.
      await _handleAuthenticationFailure(message: message);

      return originalApiResponse;
    }

    // Access token invalid
    if (errorCode == 'TOKEN_INVALID') {
      await _handleAuthenticationFailure(
        message: 'Your session is no longer valid. Please log in again.',
      );

      return originalApiResponse;
    }

    // User no longer exists
    if (errorCode == 'USER_NOT_FOUND') {
      await _handleAuthenticationFailure(
        message: 'Your account could not be found. Please try to log in again.',
      );

      return originalApiResponse;
    }

    // User not approved
    if (errorCode == 'USER_NOT_APPROVED') {
      // Store new approval status
      final bool isIncomingApprovalStatusValid =
          incomingApprovalStatus.isNotEmpty &&
          (incomingApprovalStatus == AppConstants.roles.userStatusPending ||
              incomingApprovalStatus == AppConstants.roles.userStatusRejected ||
              incomingApprovalStatus == AppConstants.roles.userStatusApproved);
      if (isIncomingApprovalStatusValid) {
        await SharedPrefsHelper.saveString(
          SharedPrefsHelper.userApprovalStatusKey,
          incomingApprovalStatus,
        );
      }

      await _handleAuthenticationFailure(
        message: 'Your account is not approved yet. Please contact support.',
        clearSessionAndData: false,
      );

      return originalApiResponse;
    }

    // Token missing
    if (errorCode == 'TOKEN_MISSING') {
      await _handleAuthenticationFailure(
        message: 'Your session has expired. Please log in again.',
      );

      return originalApiResponse;
    }

    return originalApiResponse;
  }

  // -------------- Refresh Access Token If Needed --------------
  static Future<(bool isSuccessful, String message)>
  _refreshAccessTokenIfNeeded() async {
    // If another API request is already refreshing the token,
    // wait for that same refresh request instead of creating another one.
    if (_isAccessTokenRefreshInProgress != null) {
      return await _isAccessTokenRefreshInProgress!;
    }

    _isAccessTokenRefreshInProgress = _refreshAccessToken();

    try {
      return await _isAccessTokenRefreshInProgress!;
    } finally {
      _isAccessTokenRefreshInProgress = null;
    }
  }

  // -------------- Refresh Access Token API --------------
  static Future<(bool isSuccessful, String message)>
  _refreshAccessToken() async {
    try {
      final refreshToken = await SharedPrefsHelper.getString(
        SharedPrefsHelper.refreshTokenKey,
      );

      if (refreshToken == null || refreshToken.isEmpty) {
        return (false, 'Your session has expired. Please log in again.');
      }

      final appCheckToken = await FirebaseAppCheck.instance.getToken();

      final headers = {
        'Accept': 'application/json',
        'Content-Type': 'application/json',

        if (appCheckToken != null && appCheckToken.isNotEmpty)
          'X-Firebase-AppCheck': appCheckToken,
      };

      final response = await http.post(
        Uri.parse(AppUrls.refreshAccessToken),
        headers: headers,
        body: jsonEncode({'refreshToken': refreshToken}),
      );

      dynamic responseBody;

      try {
        responseBody = jsonDecode(response.body);
      } catch (_) {
        responseBody = null;
      }

      // Refresh successful
      if (response.statusCode == 200 && responseBody is Map<String, dynamic>) {
        final newAccessToken = responseBody['accessToken'] as String? ?? '';

        if (newAccessToken.isEmpty) {
          return (
            false,
            'Your session could not be refreshed. Please log in again.',
          );
        }

        await SharedPrefsHelper.saveString(
          SharedPrefsHelper.accessTokenKey,
          newAccessToken,
        );

        return (true, 'Access token refreshed successfully');
      }

      String errorMessage = 'Your session has expired. Please log in again.';

      if (responseBody is Map<String, dynamic>) {
        final serverMessage = responseBody['message'] as String?;
        if (serverMessage != null && serverMessage.isNotEmpty) {
          errorMessage = serverMessage;
        }
      }

      return (false, errorMessage);
    } catch (error) {
      debugPrint('[REFRESH_ACCESS_TOKEN] Error: $error');

      return (false, 'Unable to refresh your session. Please log in again.');
    }
  }

  // -------------- Handle Refresh Token Failure --------------
  static bool _isHandlingAuthenticationFailure = false;

  static void resetAuthenticationFailure() =>
      _isHandlingAuthenticationFailure = false;

  static Future<void> _handleAuthenticationFailure({
    required String message,
    bool clearSessionAndData = true,
  }) async {
    if (_isHandlingAuthenticationFailure) return;

    _isHandlingAuthenticationFailure = true;

    // Clear All Data & Logout from OneSignal
    if (clearSessionAndData) {
      await NotificationService.instance
          .logout(); // unlink the device from one signal
      await SharedPrefsHelper.clearUserData();
    }

    // Go to Login Page
    Get.offAll(() => LoginPage());

    // Show message after navigating to login page.
    ToastWidget.show(
      context: Get.context!,
      title: 'Session Expired',
      subtitle: message,
      toastDuration: 5,
      type: ToastType.info,
    );
  }
}

// import 'dart:convert';
// import 'package:firebase_app_check/firebase_app_check.dart';
// import 'package:http/http.dart' as http;
// import 'package:otobix/helpers/shared_prefs_helper.dart';

// typedef UnauthorizedHandler = Future<void> Function();

// class ApiService {
//   /// Optional: set this once (e.g., in main/init) to handle 401s globally.
//   /// Example:
//   /// ApiService.configure(onUnauthorized: () async {
//   ///   await SharedPrefsHelper.clear();
//   ///   Get.offAll(() => LoginPage());
//   /// });
//   static UnauthorizedHandler? _onUnauthorized;

//   static void configure({UnauthorizedHandler? onUnauthorized}) {
//     _onUnauthorized = onUnauthorized;
//   }

//   // ---- public HTTP methods ----

//   static Future<http.Response> get({
//     required String endpoint,
//     Map<String, String>? headers,
//   }) async {
//     final url = Uri.parse(endpoint);
//     final h = await _headers(headers);
//     return _send(() => http.get(url, headers: h));
//   }

//   static Future<http.Response> post({
//     required String endpoint,
//     Map<String, dynamic>? body,
//     Map<String, String>? headers,
//   }) async {
//     final url = Uri.parse(endpoint);
//     final h = await _headers(headers);
//     return _send(
//       () => http.post(url, headers: h, body: jsonEncode(body ?? {})),
//     );
//   }

//   static Future<http.Response> put({
//     required String endpoint,
//     Map<String, dynamic>? body,
//     Map<String, String>? headers,
//   }) async {
//     final url = Uri.parse(endpoint);
//     final h = await _headers(headers);
//     return _send(() => http.put(url, headers: h, body: jsonEncode(body ?? {})));
//   }

//   // ---- internals ----

//   static Future<Map<String, String>> _headers([
//     Map<String, String>? headers,
//   ]) async {
//     final token = await SharedPrefsHelper.getString(
//       SharedPrefsHelper.accessTokenKey,
//     );
//     final appCheckToken = await FirebaseAppCheck.instance.getToken();
//     return {
//       // JWT
//       if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
//       // Firebase App Check
//       if (appCheckToken != null && appCheckToken.isNotEmpty)
//         'X-Firebase-AppCheck': appCheckToken,

//       'Accept': 'application/json',
//       'Content-Type': 'application/json',
//       // Custom headers
//       ...?headers,
//     };
//   }

//   /// Single place to handle auth failures. If the server returns 401 with a code
//   /// like TOKEN_MISSING / TOKEN_INVALID / TOKEN_EXPIRED / USER_NOT_FOUND,
//   /// we call the configured handler so you can clear storage and redirect.
//   static Future<http.Response> _send(
//     Future<http.Response> Function() request,
//   ) async {
//     final res = await request();

//     if (res.statusCode == 401) {
//       try {
//         final dynamic body = jsonDecode(res.body);
//         final code =
//             (body is Map<String, dynamic>) ? body['code'] as String? : null;

//         if (code == 'TOKEN_MISSING' ||
//             code == 'TOKEN_INVALID' ||
//             code == 'TOKEN_EXPIRED' ||
//             code == 'USER_NOT_FOUND') {
//           // Let the app decide what to do (clear prefs, route to login, etc.)
//           if (_onUnauthorized != null) {
//             await _onUnauthorized!.call();
//           }
//         }
//       } catch (_) {
//         // ignore JSON parse errors and still treat as unauthorized
//         if (_onUnauthorized != null) {
//           await _onUnauthorized!.call();
//         }
//       }
//     }

//     return res;
//   }
// }
