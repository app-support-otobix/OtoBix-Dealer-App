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

/// Something a dealer pays for from Membership: a plan, or a points top-up.
/// The server takes the price from its own table, by [code].
abstract interface class DealerPurchasable {
  String get code;
  String get name;
  int get priceRupees;
}

class DealerPlanModel implements DealerPurchasable {
  @override
  final String code;
  @override
  final String name;
  @override
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

/// More points for the current cycle (1,000 for ₹1,000): usable for any
/// feature, until the cycle ends.
class DealerTopUpModel implements DealerPurchasable {
  @override
  final String code;
  @override
  final String name;
  @override
  final int priceRupees;
  final int points;
  final List<String> benefits;

  DealerTopUpModel.fromJson(Map<String, dynamic> j)
    : code = _str(j['code']),
      name = _str(j['name']),
      priceRupees = _int(j['priceRupees']),
      points = _int(j['points']),
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

  /// The choices when the server's list (with plan details) can't be loaded.
  static const fallback = [
    DealerRegisterAsModel('New-Car Dealer', 'New Car Dealer (NCD)'),
    DealerRegisterAsModel('Used Car Dealer', 'Used Car Dealer (UCD)'),
    DealerRegisterAsModel('Broker', 'Broker'),
  ];

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
  final DealerTopUpModel? topUp;
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
      topUp =
          j['topUp'] is Map
              ? DealerTopUpModel.fromJson(Map<String, dynamic>.from(j['topUp']))
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
  // Points added by top-ups this cycle.
  final int toppedUp;
  final int reserved;
  final int pendingReservations;
  final int consumed;
  final int released;

  DealerCycleSummaryModel.fromJson(Map<String, dynamic> j)
    : allocated = _int(j['allocated']),
      toppedUp = _int(j['toppedUp']),
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
  // What it buys, e.g. "Dealer Pro" or "1,000 OtoBix Points".
  final String name;
  final bool isTopUp;
  final int amountRupees;
  final DateTime? requestedAt;

  DealerPendingPaymentModel.fromJson(Map<String, dynamic> j)
    : code = _str(j['code']),
      planCode = _str(j['planCode']),
      name = _str(j['name']),
      isTopUp = j['isTopUp'] == true,
      amountRupees = _int(j['amountRupees']),
      requestedAt = _date(j['requestedAt']);
}

/// A plan the dealer is running. Plans stack: one bought while another runs
/// adds its points and allowances, and each ends on its own date.
class DealerRunningPlanModel {
  final String planCode;
  final String name;
  // Days in India, sent as YYYY-MM-DD and read as local dates; endDate is its last day.
  final DateTime? startDate;
  final DateTime? endDate;

  DealerRunningPlanModel.fromJson(Map<String, dynamic> j)
    : planCode = _str(j['planCode']),
      name = _str(j['name']),
      startDate = DateTime.tryParse(_str(j['startDate'])),
      endDate = DateTime.tryParse(_str(j['endDate']));

  /// Still in its days: its last day is today or later.
  bool get isRunningToday {
    final now = DateTime.now();
    return endDate != null &&
        !endDate!.isBefore(DateTime(now.year, now.month, now.day));
  }
}

class DealerMembershipModel {
  static const active = 'ACTIVE';
  static const grace = 'GRACE';

  final String dealerCode;
  final String dealerType;
  // Enrolled before registration asked the dealer type: chosen once in the
  // app before anything else (DealerTypeChoicePage).
  final bool needsDealerType;
  // Chose Broker, but OtoBix moves them to the Broker plan from the CRM.
  final DateTime? brokerRequestedAt;
  final String gstin;
  final String city;
  final String state;
  final int tradeRadiusKm;
  // Set from the phone GPS; other dealers' cars show their distance from it.
  final bool hasShowroomLocation;
  final DateTime? showroomLocationAt;
  final String status;
  final DealerPlanModel? plan;
  // The free Promo trial runs on dates OtoBix set from the CRM and they have
  // not begun yet: the first and last day (local dates). Null otherwise.
  final DateTime? trialStartDate;
  final DateTime? trialEndDate;
  // Where the dealer stands with the free Promo trial: NOT_SET (no dates yet),
  // SCHEDULED, DUE, RUNNING, MISSED or ENDED; empty for brokers.
  final String trialStatus;
  final int cycleNumber;
  final DateTime? cycleStartAt;
  final DateTime? cycleEndAt;
  final DateTime? graceEndAt;
  final int dayOfCycle;
  final int daysLeft;
  final bool showRenewalWarning;
  final int availablePoints;
  // Top-up points not used yet (already in availablePoints). They never
  // expire and are used after the plans' own points.
  final int topUpPoints;
  // The plans running now; more than one when a plan was bought while
  // another ran (their points and allowances add up).
  final List<DealerRunningPlanModel> plans;
  final int activeListings;
  final List<DealerUsageModel> usage;
  final DealerPendingPaymentModel? pendingPayment;
  final DealerCycleSummaryModel? summary;
  // Dealer Home tabs OtoBix switched on or off from the CRM, by module code
  // (SELL, BUY, SERVICES, LEADS, MEMBERSHIP). A missing code means on.
  final Map<String, bool> modules;

  bool get isActive => status == active || status == grace;
  bool get isGrace => status == grace;
  bool get trialScheduled => trialStartDate != null;
  // Waiting for the free Promo trial, with 0 points: OtoBix has not set its
  // dates yet, or they have not begun.
  bool get trialQueued =>
      !isActive && const ['NOT_SET', 'SCHEDULED', 'DUE'].contains(trialStatus);
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
      needsDealerType = j['needsDealerType'] == true,
      brokerRequestedAt = _date(j['brokerRequestedAt']),
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
      trialStartDate = _scheduledTrialDay(j['promoTrial'], 'startDate'),
      trialEndDate = _scheduledTrialDay(j['promoTrial'], 'endDate'),
      trialStatus =
          j['promoTrial'] is Map ? _str(j['promoTrial']['status']) : '',
      cycleNumber = _int(j['cycleNumber']),
      cycleStartAt = _date(j['cycleStartAt']),
      cycleEndAt = _date(j['cycleEndAt']),
      graceEndAt = _date(j['graceEndAt']),
      dayOfCycle = _int(j['dayOfCycle']),
      daysLeft = _int(j['daysLeft']),
      showRenewalWarning = j['showRenewalWarning'] == true,
      availablePoints = _int(j['availablePoints']),
      topUpPoints = _int(j['topUpPoints']),
      plans = _maps(j['plans']).map(DealerRunningPlanModel.fromJson).toList(),
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

  // A day of a SCHEDULED trial. The server sends days as YYYY-MM-DD (India),
  // read as a local date so it shows as the same day on any phone.
  static DateTime? _scheduledTrialDay(dynamic trial, String key) =>
      trial is Map && trial['status'] == 'SCHEDULED'
          ? DateTime.tryParse(_str(trial[key]))
          : null;
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
