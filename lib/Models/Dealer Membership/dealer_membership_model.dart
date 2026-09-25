import 'package:otobix/Utils/global_functions.dart';

int _int(dynamic v) => GlobalFunctions.parse<int>(v) ?? 0;
String _str(dynamic v) => GlobalFunctions.parse<String>(v) ?? '';
DateTime? _date(dynamic v) => GlobalFunctions.parse<DateTime>(v);
List<String> _strings(dynamic v) =>
    v is List ? v.map((e) => e.toString()).toList() : <String>[];

class DealerPlanModel {
  final String code;
  final String name;
  final int priceRupees;
  final int pointsPerCycle;
  final int cycleDays;
  final List<String> benefits;

  DealerPlanModel.fromJson(Map<String, dynamic> j)
    : code = _str(j['code']),
      name = _str(j['name']),
      priceRupees = _int(j['priceRupees']),
      pointsPerCycle = _int(j['pointsPerCycle']),
      cycleDays = _int(j['cycleDays']),
      benefits = _strings(j['benefits']);
}

/// Catalogues served by the backend so the app never keeps its own copies.
class DealerMembershipConfigModel {
  final List<DealerPlanModel> plans;
  final DealerPlanModel? promo;
  final List<String> dealerTypes;

  DealerMembershipConfigModel.fromJson(Map<String, dynamic> j)
    : plans =
          (j['plans'] as List? ?? [])
              .map(
                (e) => DealerPlanModel.fromJson(Map<String, dynamic>.from(e)),
              )
              .toList(),
      promo =
          j['promo'] is Map
              ? DealerPlanModel.fromJson(Map<String, dynamic>.from(j['promo']))
              : null,
      dealerTypes = _strings(j['dealerTypes']);
}

class DealerCycleSummaryModel {
  final int allocated;
  final int expired;

  DealerCycleSummaryModel.fromJson(Map<String, dynamic> j)
    : allocated = _int(j['allocated']),
      expired = _int(j['expired']);
}

class DealerMembershipModel {
  static const active = 'ACTIVE';

  final bool isOnboarded;
  final String dealerCode;
  final String dealerType;
  final String gstin;
  final String city;
  final String state;
  final int tradeRadiusKm;
  final String status; // NONE | ACTIVE | EXPIRED
  final DealerPlanModel? plan;
  final int cycleNumber;
  final DateTime? cycleStartAt;
  final DateTime? cycleEndAt;
  final int availablePoints;
  final bool promoAvailable;
  final DealerCycleSummaryModel? summary;

  bool get isActive => status == active;

  DealerMembershipModel.fromJson(Map<String, dynamic> j)
    : isOnboarded = j['isOnboarded'] == true,
      dealerCode = _str(j['dealerCode']),
      dealerType = _str(j['dealerType']),
      gstin = _str(j['gstin']),
      city = _str(j['city']),
      state = _str(j['state']),
      tradeRadiusKm = _int(j['tradeRadiusKm']),
      status = _str(j['status']).isEmpty ? 'NONE' : _str(j['status']),
      plan =
          j['plan'] is Map
              ? DealerPlanModel.fromJson(Map<String, dynamic>.from(j['plan']))
              : null,
      cycleNumber = _int(j['cycleNumber']),
      cycleStartAt = _date(j['cycleStartAt']),
      cycleEndAt = _date(j['cycleEndAt']),
      availablePoints = _int(j['availablePoints']),
      promoAvailable = j['promoAvailable'] == true,
      summary =
          j['summary'] is Map
              ? DealerCycleSummaryModel.fromJson(
                Map<String, dynamic>.from(j['summary']),
              )
              : null;
}

class DealerLedgerEntryModel {
  final String id;
  final String type;
  final int points;
  final String note;
  final DateTime? createdAt;

  DealerLedgerEntryModel.fromJson(Map<String, dynamic> j)
    : id = _str(j['_id']),
      type = _str(j['type']),
      points = _int(j['points']),
      note = _str(j['note']),
      createdAt = _date(j['createdAt']);
}
