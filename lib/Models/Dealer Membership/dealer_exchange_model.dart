import 'package:otobix/Models/Dealer%20Membership/dealer_negotiation_model.dart';
import 'package:otobix/Utils/global_functions.dart';

String _str(dynamic v) => GlobalFunctions.parse<String>(v) ?? '';
int _int(dynamic v) => GlobalFunctions.parse<int>(v) ?? 0;
List<String> _strings(dynamic v) =>
    v is List ? v.map((e) => e.toString()).toList() : <String>[];

/// The viewer's own offer on a listing, and where the seller stands on it.
class DealerMyOfferModel {
  final String negotiationId;
  final String
  displayStatus; // OFFER SENT | COUNTERED | ACTION NEEDED | AGREED | ...
  final int amount; // the latest price on the thread, from either side
  final bool byMe;
  final int agreedAmount;

  /// My own latest price, still known after the seller counters (0 = none).
  final int myAmount;

  /// The seller's latest price in the chat (0 = they have not countered).
  final int sellerAmount;

  DealerMyOfferModel.fromJson(Map<String, dynamic> j)
    : negotiationId = _str(j['negotiationId']),
      displayStatus = _str(j['displayStatus']),
      amount = _int(j['amount']),
      byMe = j['byMe'] == true,
      agreedAmount = _int(j['agreedAmount']),
      myAmount = _myAmount(
        _int(j['myAmount']),
        j['byMe'] == true,
        _int(j['amount']),
      ),
      sellerAmount = _myAmount(
        _int(j['sellerAmount']),
        j['byMe'] != true,
        _int(j['amount']),
      );

  /// From a conversation where I am the buyer: the quick offer's reply, the
  /// chat, or the seller's answer.
  DealerMyOfferModel.of(DealerNegotiationModel n)
    : negotiationId = n.id,
      displayStatus = n.displayStatus,
      amount = n.lastOfferAmount ?? 0,
      byMe = n.lastOfferByMe,
      agreedAmount = n.agreedAmount,
      myAmount = _myAmount(
        n.buyerPrice,
        n.lastOfferByMe,
        n.lastOfferAmount ?? 0,
      ),
      sellerAmount = _myAmount(
        n.sellerPrice,
        !n.lastOfferByMe,
        n.lastOfferAmount ?? 0,
      );

  // A backend that does not send a side's own price yet: the latest one, if
  // that side made it.
  static int _myAmount(int own, bool theirs, int latest) =>
      own > 0 ? own : (theirs ? latest : 0);

  /// The price that matters now: the agreed one, else [own].
  int priceOr(int own) => agreedAmount > 0 ? agreedAmount : own;
}

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
  final DealerMyOfferModel? myOffer;
  // From my showroom to the seller's; null when either has no location set.
  final double? distanceKm;
  // PREMIUM_LISTING: a customer's car its owner listed for dealers
  // (Customer inventory); exchangePrice is then the owner's expected price.
  final String carSource;
  final bool hasInspectionReport;

  bool get isPremiumListing => carSource == 'PREMIUM_LISTING';

  DealerExchangeListingModel.fromJson(Map<String, dynamic> j)
    : id = _str(j['id']),
      carSource = _str(j['carSource']),
      hasInspectionReport = j['hasInspectionReport'] == true,
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
      matchedRequirement = _str(j['matchedRequirement']),
      distanceKm = (j['distanceKm'] as num?)?.toDouble(),
      myOffer =
          j['myOffer'] is Map
              ? DealerMyOfferModel.fromJson(
                Map<String, dynamic>.from(j['myOffer']),
              )
              : null;
}

class DealerRequirementModel {
  final String id;
  final String requirementCode;
  final String name;
  final List<String> makes; // empty = any make
  final String make;
  final String model; // only with exactly one make
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
      makes = _requirementMakes(j),
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

  // `makes` from a current server; an older one sends a single `make`.
  static List<String> _requirementMakes(Map<String, dynamic> j) {
    final makes = _strings(j['makes']);
    if (makes.isNotEmpty) return makes;
    final make = _str(j['make']);
    return make.isEmpty ? const [] : [make];
  }

  String get summary {
    final parts = <String>[
      [makes.join(' / '), model].where((s) => s.isNotEmpty).join(' '),
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
