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
  final int listingCap;
  // Broker plans: customer cars only, this many a cycle.
  final int customerCarsPerCycle;
  final bool isBroker;
  final int cycleDays;
  final List<String> benefits;

  bool get isTrial => priceRupees == 0;

  DealerPlanModel.fromJson(Map<String, dynamic> j)
    : code = _str(j['code']),
      name = _str(j['name']),
      priceRupees = _int(j['priceRupees']),
      pointsPerCycle = _int(j['pointsPerCycle']),
      listingCap = _int(j['listingCap']),
      customerCarsPerCycle = _int(j['customerCarsPerCycle']),
      isBroker = j['broker'] == true,
      cycleDays = _int(j['cycleDays']),
      benefits = _strings(j['benefits']);
}

/// A "Register as" choice on the registration form (New Car Dealer, Used Car
/// Dealer, Broker) with the plans it gets.
class DealerRegisterAsModel {
  final String dealerType;
  final String label;
  final List<DealerPlanModel> plans;

  const DealerRegisterAsModel(
    this.dealerType,
    this.label, [
    this.plans = const [],
  ]);

  DealerRegisterAsModel.fromJson(Map<String, dynamic> j)
    : dealerType = _str(j['dealerType']),
      label = _str(j['label']),
      plans = _maps(j['plans']).map(DealerPlanModel.fromJson).toList();
}

class DealerPaymentMethodModel {
  final String code;
  final String label;
  final bool enabled;

  DealerPaymentMethodModel.fromJson(Map<String, dynamic> j)
    : code = _str(j['code']),
      label = _str(j['label']),
      enabled = j['enabled'] == true;
}

class DealerMembershipConfigModel {
  final List<DealerPlanModel> plans;
  final DealerPlanModel? promo;
  final List<DealerPaymentMethodModel> paymentMethods;
  final List<String> dealerTypes;
  final List<String> fuelTypes;
  final List<String> transmissions;
  final Map<String, int> serviceCosts;
  final int connectionPoints;
  final int connectionExpiryHours;
  final int maxCarImages;
  final Map<String, List<String>> quickMessages;
  final String offerQuickMessage;
  final String connectionQuickMessage;
  final Map<String, List<String>> presetAnswers;
  final List<String> fallbackAnswers;
  final List<String> leadStatuses;
  final Map<String, List<String>> dealTransitions;

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
      dealerTypes = _strings(j['dealerTypes']),
      fuelTypes = _strings(j['fuelTypes']),
      transmissions = _strings(j['transmissions']),
      serviceCosts = {
        for (final e
            in Map<String, dynamic>.from(j['serviceCosts'] ?? {}).entries)
          e.key: _int(e.value),
      },
      connectionPoints = _int(j['connection']?['pointsPerSide']),
      connectionExpiryHours = _int(j['connection']?['expiryHours']),
      maxCarImages = _int(j['maxCarImages']),
      quickMessages = _stringListMap(j['quickMessages']),
      offerQuickMessage = _str(j['offerQuickMessage']),
      connectionQuickMessage = _str(j['connectionQuickMessage']),
      presetAnswers = _stringListMap(j['presetAnswers']),
      fallbackAnswers = _strings(j['fallbackAnswers']),
      leadStatuses = _strings(j['leadStatuses']),
      dealTransitions = _stringListMap(j['dealTransitions']);

  static Map<String, List<String>> _stringListMap(dynamic v) => {
    for (final e in Map<String, dynamic>.from(v ?? {}).entries)
      e.key: _strings(e.value),
  };
}

class DealerCycleSummaryModel {
  final int allocated;
  final int reserved;
  final int pendingReservations;
  final int consumed;
  final int released;

  DealerCycleSummaryModel.fromJson(Map<String, dynamic> j)
    : allocated = _int(j['allocated']),
      reserved = _int(j['reserved']),
      pendingReservations = _int(j['pendingReservations']),
      consumed = _int(j['consumed']),
      released = _int(j['released']);
}

class DealerUsageModel {
  final String feature;
  final String label;
  final String unit;
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
  // Set from the phone GPS; other dealers' cars show their distance from it.
  final bool hasShowroomLocation;
  final DateTime? showroomLocationAt;
  final String status;
  final DealerPlanModel? plan;
  final int cycleNumber;
  final DateTime? cycleStartAt;
  final DateTime? cycleEndAt;
  final DateTime? graceEndAt;
  final int dayOfCycle;
  final int daysLeft;
  final bool showRenewalWarning;
  final int availablePoints;
  final int activeListings;
  final List<DealerUsageModel> usage;
  final DealerPendingPaymentModel? pendingPayment;
  final DealerCycleSummaryModel? summary;
  // Dealer Home tabs OtoBix switched on or off from the CRM, by module code
  // (SELL, BUY, SERVICES, LEADS, MEMBERSHIP). A missing code means on.
  final Map<String, bool> modules;

  bool get isActive => status == active || status == grace;
  bool get isGrace => status == grace;
  // Brokers see Sell (My Customer's Inventory) and Membership only.
  bool get isBroker => plan?.isBroker ?? false;
  bool moduleEnabled(String code) => modules[code] ?? true;

  DealerMembershipModel.fromJson(Map<String, dynamic> j)
    : modules =
          j['modules'] is Map
              ? {
                for (final e in (j['modules'] as Map).entries)
                  if (e.value is bool) e.key.toString(): e.value as bool,
              }
              : const {},
      dealerCode = _str(j['dealerCode']),
      dealerType = _str(j['dealerType']),
      gstin = _str(j['gstin']),
      city = _str(j['city']),
      state = _str(j['state']),
      tradeRadiusKm = _int(j['tradeRadiusKm']),
      hasShowroomLocation = j['showroomLocation'] is Map,
      showroomLocationAt = _date(j['showroomLocation']?['updatedAt']),
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
      activeListings = _int(j['activeListings']),
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

  DealerUsageModel? usageFor(String feature) =>
      usage.where((u) => u.feature == feature).firstOrNull;
}

class DealerLedgerEntryModel {
  final String id;
  final String type;
  final int points;
  final String connectionId;
  final String service;
  final String note;
  final DateTime? createdAt;

  DealerLedgerEntryModel.fromJson(Map<String, dynamic> j)
    : id = _str(j['_id']),
      type = _str(j['type']),
      points = _int(j['points']),
      connectionId = _str(j['connectionId']),
      service = _str(j['service']),
      note = _str(j['note']),
      createdAt = _date(j['createdAt']);
}

class DealerPendingActivityModel {
  final String type;
  final String title;
  final String subtitle;
  final DateTime? expiresAt;
  final String targetType;
  final String targetId;

  DealerPendingActivityModel.fromJson(Map<String, dynamic> j)
    : type = _str(j['type']),
      title = _str(j['title']),
      subtitle = _str(j['subtitle']),
      expiresAt = _date(j['expiresAt']),
      targetType = _str(j['target']?['type']),
      targetId = _str(j['target']?['id']);
}
