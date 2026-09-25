import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:otobix/Network/api_service.dart';

/// A failure the dealer can read. [code] carries the server's machine code
/// (e.g. INSUFFICIENT_POINTS, MEMBERSHIP_INACTIVE) so screens can react.
class DealerApiException implements Exception {
  final String message;
  final String code;
  final int statusCode;

  const DealerApiException(this.message, {this.code = '', this.statusCode = 0});

  @override
  String toString() => message;
}

/// Calls the Dealer Membership APIs through [ApiService] (auth, token refresh,
/// App Check) and unwraps the `{ success, message, data }` envelope.
class DealerMembershipApi {
  DealerMembershipApi._();

  static const _timeout = Duration(seconds: 45);

  static Future<dynamic> get(String url) =>
      _send(() => ApiService.get(endpoint: url));

  static Future<dynamic> post(String url, [Map<String, dynamic>? body]) =>
      _send(() => ApiService.post(endpoint: url, body: body));

  static Future<dynamic> _send(Future<http.Response> Function() call) async {
    final http.Response response;
    try {
      response = await call().timeout(_timeout);
    } on SocketException {
      throw const DealerApiException(
        'No internet connection. Please check your network and try again.',
        code: 'NETWORK',
      );
    } on TimeoutException {
      throw const DealerApiException(
        'The server is taking too long to respond. Please try again.',
        code: 'TIMEOUT',
      );
    } on http.ClientException {
      throw const DealerApiException(
        'Could not reach OtoBix. Please try again.',
        code: 'NETWORK',
      );
    }

    Map<String, dynamic>? body;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) body = decoded;
    } catch (_) {
      body = null;
    }

    if (response.statusCode >= 200 &&
        response.statusCode < 300 &&
        body?['success'] == true) {
      return body!['data'];
    }

    if (response.statusCode == 401) {
      // ApiService has already sent the dealer back to login.
      throw const DealerApiException(
        'Your session has expired. Please log in again.',
        code: 'UNAUTHORIZED',
        statusCode: 401,
      );
    }

    // 4xx messages and coded 5xx ones (e.g. provider down) are written for
    // dealers; uncoded 5xx details are never shown.
    final serverMessage = body?['message'];
    final code = (body?['code'] ?? '').toString();
    final message =
        (response.statusCode < 500 || code.isNotEmpty) &&
                serverMessage is String &&
                serverMessage.trim().isNotEmpty
            ? serverMessage
            : 'Something went wrong. Please try again later.';
    throw DealerApiException(
      message,
      code: code,
      statusCode: response.statusCode,
    );
  }
}
