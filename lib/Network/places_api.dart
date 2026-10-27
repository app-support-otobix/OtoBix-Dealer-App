import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:otobix/Models/place_model.dart';
import 'package:otobix/Network/dealer_membership_api.dart';
import 'package:otobix/Utils/app_urls.dart';

/// Showroom address search through the backend (Google Places). One search
/// keeps one session token, so its suggestions and the picked place's details
/// are billed as a single session. Before login the caller is identified by
/// the registration's verified OTP; after login, by the access token.
class PlacesApi {
  PlacesApi._();

  /// The call to the backend; tests swap in a fake.
  @visibleForTesting
  static Future<dynamic> Function(String url, Map<String, dynamic> body) post =
      DealerMembershipApi.post;

  static Future<List<PlaceSuggestionModel>> suggest(
    String input, {
    required String sessionToken,
    String? otpVerificationToken,
  }) async {
    final data = await post(AppUrls.placesAutocomplete, {
      'input': input,
      'sessionToken': sessionToken,
      if (otpVerificationToken != null)
        'otpVerificationToken': otpVerificationToken,
    });
    final list = (data?['suggestions'] as List?) ?? const [];
    return list
        .map((e) => PlaceSuggestionModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  static Future<PlaceDetailsModel> details(
    String placeId, {
    required String sessionToken,
    String? otpVerificationToken,
  }) async {
    final data = await post(AppUrls.placesDetails, {
      'placeId': placeId,
      'sessionToken': sessionToken,
      if (otpVerificationToken != null)
        'otpVerificationToken': otpVerificationToken,
    });
    return PlaceDetailsModel.fromJson(Map<String, dynamic>.from(data['place']));
  }

  /// A new session token: URL-safe base64, 32 characters (Google allows 36).
  static String newSessionToken() {
    final random = Random.secure();
    return base64Url.encode(List.generate(24, (_) => random.nextInt(256)));
  }
}
