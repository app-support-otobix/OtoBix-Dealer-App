/// One address suggestion while the dealer types
/// (`POST /api/places/autocomplete`).
class PlaceSuggestionModel {
  final String placeId;
  final String title; // the showroom's name, or the street
  final String subtitle; // the rest: area, city, state

  PlaceSuggestionModel.fromJson(Map<String, dynamic> j)
    : placeId = (j['placeId'] ?? '').toString(),
      title = (j['title'] ?? '').toString(),
      subtitle = (j['subtitle'] ?? '').toString();

  String get fullText => subtitle.isEmpty ? title : '$title, $subtitle';
}

/// A picked address with its position (`POST /api/places/details`).
class PlaceDetailsModel {
  final String placeId;
  final String address;
  final double? latitude;
  final double? longitude;
  final String city;
  final String state;
  final String pincode;

  PlaceDetailsModel.fromJson(Map<String, dynamic> j)
    : placeId = (j['placeId'] ?? '').toString(),
      address = (j['address'] ?? '').toString(),
      latitude = (j['latitude'] as num?)?.toDouble(),
      longitude = (j['longitude'] as num?)?.toDouble(),
      city = (j['city'] ?? '').toString(),
      state = (j['state'] ?? '').toString(),
      pincode = (j['pincode'] ?? '').toString();

  bool get hasPosition => latitude != null && longitude != null;
}
