import 'package:otobix/Utils/global_functions.dart';

int _int(dynamic v) => GlobalFunctions.parse<int>(v) ?? 0;
String _str(dynamic v) => GlobalFunctions.parse<String>(v) ?? '';
DateTime? _date(dynamic v) => GlobalFunctions.parse<DateTime>(v);
List<String> _strings(dynamic v) =>
    v is List ? v.map((e) => e.toString()).toList() : <String>[];
List<Map<String, dynamic>> _maps(dynamic v) => [
  for (final e in (v is List ? v : const []))
    if (e is Map) Map.from(e),
];

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

/// UPI / NACH / Offline. Disabled methods are shown as coming soon.
class DealerPaymentMethodModel {
  final String code;
  final String label;
  final bool enabled;

  DealerPaymentMethodModel.fromJson(Map<String, dynamic> j)
    : code = _str(j['code']),
      label = _str(j['label']),
      enabled = j['enabled'] == true;
}

/// Catalogues served by the backend so the app never keeps its own copies.
class DealerMembershipConfigModel {
  final List<DealerPlanModel> plans;
  final DealerPlanModel? promo;
  final List<DealerPaymentMethodModel> paymentMethods;
  final List<String> dealerTypes;

  DealerMembershipConfigModel.fromJson(Map<String, dynamic> j)
    : plans = _maps(j['plans']).map(DealerPlanModel.fromJson).toList(),
      promo =
          j['promo'] is Map
              ? DealerPlanModel.fromJson(Map<String, dynamic>.from(j['promo']))
              : null,
      paymentMethods =
          _maps(
            j['paymentMethods'],
          ).map(DealerPaymentMethodModel.fromJson).toList(),
      dealerTypes = _strings(j['dealerTypes']);
}

class DealerCycleSummaryModel {
  final int allocated;
  final int expired;

  DealerCycleSummaryModel.fromJson(Map<String, dynamic> j)
    : allocated = _int(j['allocated']),
      expired = _int(j['expired']);
}

/// One feature's share of the cycle's points (Current Month Usage).
class DealerUsageModel {
  final String feature; // RC | SERVICE_HISTORY | CONNECTION
  final String label;
  final String unit; // checks | connections | rupees
  final int unitPoints;
  final int usedPoints;
  final int limitPoints;

  DealerUsageModel.fromJson(Map<String, dynamic> j)
    : feature = _str(j['feature']),
      label = _str(j['label']),
      unit = _str(j['unit']),
      unitPoints = _int(j['unitPoints']),
      usedPoints = _int(j['usedPoints']),
      limitPoints = _int(j['limitPoints']);

  bool get isRupees => unit == 'rupees' || unitPoints <= 0;
  int get used => isRupees ? usedPoints : usedPoints ~/ unitPoints;
  int get limit => isRupees ? limitPoints : limitPoints ~/ unitPoints;
  int get leftPoints => (limitPoints - usedPoints).clamp(0, limitPoints);
  double get progress => limitPoints == 0 ? 0 : usedPoints / limitPoints;
}

/// An offline payment waiting for OtoBix to confirm it.
class DealerPendingPaymentModel {
  final String code;
  final String planCode;
  final int amountRupees;
  final DateTime? requestedAt;

  DealerPendingPaymentModel.fromJson(Map<String, dynamic> j)
    : code = _str(j['code']),
      planCode = _str(j['planCode']),
      amountRupees = _int(j['amountRupees']),
      requestedAt = _date(j['requestedAt']);
}

class DealerMembershipModel {
  static const active = 'ACTIVE';
  static const grace = 'GRACE';

  final String dealerCode;
  final String dealerType;
  final String gstin;
  final String city;
  final String state;
  final int tradeRadiusKm;
  final String status; // ACTIVE | GRACE | EXPIRED
  final DealerPlanModel? plan;
  final int cycleNumber;
  final DateTime? cycleStartAt;
  final DateTime? cycleEndAt;
  final DateTime? graceEndAt;
  final int dayOfCycle;
  final int daysLeft;
  final bool showRenewalWarning;
  final int availablePoints;
  final List<DealerUsageModel> usage;
  final DealerPendingPaymentModel? pendingPayment;
  final DealerCycleSummaryModel? summary;

  /// Usable inside the cycle and during the grace period after it.
  bool get isActive => status == active || status == grace;
  bool get isGrace => status == grace;

  DealerMembershipModel.fromJson(Map<String, dynamic> j)
    : dealerCode = _str(j['dealerCode']),
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
      graceEndAt = _date(j['graceEndAt']),
      dayOfCycle = _int(j['dayOfCycle']),
      daysLeft = _int(j['daysLeft']),
      showRenewalWarning = j['showRenewalWarning'] == true,
      availablePoints = _int(j['availablePoints']),
      usage = _maps(j['usage']).map(DealerUsageModel.fromJson).toList(),
      pendingPayment =
          j['pendingPayment'] is Map
              ? DealerPendingPaymentModel.fromJson(
                Map<String, dynamic>.from(j['pendingPayment']),
              )
              : null,
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
