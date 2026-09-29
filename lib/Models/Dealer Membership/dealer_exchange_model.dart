import 'package:otobix/Utils/global_functions.dart';

String _str(dynamic v) => GlobalFunctions.parse<String>(v) ?? '';
int _int(dynamic v) => GlobalFunctions.parse<int>(v) ?? 0;
List<String> _strings(dynamic v) =>
    v is List ? v.map((e) => e.toString()).toList() : <String>[];

class DealerExchangeListingModel {
  final String id;
  final String listingCode;
  final String registrationNumber;
  final String title;
  final String make;
  final String model;
  final String variant;
  final int mfgYear;
  final int regnYear;
  final String colour;
  final String fuelType;
  final String transmission;
  final int ownerSerialNo;
  final String taxValidity;
  final String insuranceValidity;
  final String rto;
  final int kms;
  final String city;
  final String description;
  final List<String> images;
  final int exchangePrice;
  final String source;
  final String sellerCode;
  final String sellerType;
  final String sellerCity;
  final DateTime? listedAt;
  final int matchPercent;
  final String matchedRequirement;

  DealerExchangeListingModel.fromJson(Map<String, dynamic> j)
    : id = _str(j['id']),
      listingCode = _str(j['listingCode']),
      registrationNumber = _str(j['registrationNumber']),
      title = _str(j['title']),
      make = _str(j['make']),
      model = _str(j['model']),
      variant = _str(j['variant']),
      mfgYear = _int(j['mfgYear']),
      regnYear = _int(j['regnYear']),
      colour = _str(j['colour']),
      fuelType = _str(j['fuelType']),
      transmission = _str(j['transmission']),
      ownerSerialNo = _int(j['ownerSerialNo']),
      taxValidity = _str(j['taxValidity']),
      insuranceValidity = _str(j['insuranceValidity']),
      rto = _str(j['rto']),
      kms = _int(j['kms']),
      city = _str(j['city']),
      description = _str(j['description']),
      images = _strings(j['images']),
      exchangePrice = _int(j['exchangePrice']),
      source = _str(j['source']),
      sellerCode = _str(j['seller']?['dealerCode']),
      sellerType = _str(j['seller']?['dealerType']),
      sellerCity = _str(j['seller']?['city']),
      listedAt = GlobalFunctions.parse<DateTime>(j['listedAt']),
      matchPercent = _int(j['matchPercent']),
      matchedRequirement = _str(j['matchedRequirement']);
}

class DealerRequirementModel {
  final String id;
  final String requirementCode;
  final String name;
  final String make;
  final String model;
  final int yearFrom;
  final int yearTo;
  final int kmMin;
  final int kmMax;
  final List<String> fuelTypes;
  final List<String> transmissions;
  final int priceMin;
  final int priceMax;
  final String city;
  final String status;
  final DateTime? expiresAt;
  final int matchCount;

  bool get isActive => status == 'ACTIVE';

  int get daysLeft =>
      expiresAt == null
          ? 0
          : (expiresAt!.difference(DateTime.now()).inHours / 24).ceil().clamp(
            0,
            999,
          );

  DealerRequirementModel.fromJson(Map<String, dynamic> j)
    : id = _str(j['id']),
      requirementCode = _str(j['requirementCode']),
      name = _str(j['name']),
      make = _str(j['make']),
      model = _str(j['model']),
      yearFrom = _int(j['yearFrom']),
      yearTo = _int(j['yearTo']),
      kmMin = _int(j['kmMin']),
      kmMax = _int(j['kmMax']),
      fuelTypes = _strings(j['fuelTypes']),
      transmissions = _strings(j['transmissions']),
      priceMin = _int(j['priceMin']),
      priceMax = _int(j['priceMax']),
      city = _str(j['city']),
      status = _str(j['status']),
      expiresAt = GlobalFunctions.parse<DateTime>(j['expiresAt']),
      matchCount = _int(j['matchCount']);

  String get summary {
    final parts = <String>[
      [make, model].where((s) => s.isNotEmpty).join(' '),
      if (yearFrom > 0 || yearTo > 0)
        '${yearFrom > 0 ? yearFrom : 'Any'}–${yearTo > 0 ? yearTo : 'now'}',
      if (priceMin > 0 || priceMax > 0)
        '${GlobalFunctions.formatLakh(priceMin)}–${priceMax > 0 ? GlobalFunctions.formatLakh(priceMax) : 'any'}',
      if (kmMax > 0) 'up to ${GlobalFunctions.formatNumber(kmMax)} km',
      if (fuelTypes.isNotEmpty) fuelTypes.join('/'),
      if (transmissions.isNotEmpty) transmissions.join('/'),
      city.isEmpty ? 'All cities' : city,
    ];
    return parts.where((s) => s.isNotEmpty).join(' · ');
  }
}
