import 'package:otobix/Utils/global_functions.dart';

String _str(dynamic v) => GlobalFunctions.parse<String>(v) ?? '';
int _int(dynamic v) => GlobalFunctions.parse<int>(v) ?? 0;
double _num(dynamic v) => GlobalFunctions.parse<double>(v) ?? 0;

const dealerInsuranceFuelTypes = {
  3: 'CNG',
  4: 'Diesel',
  5: 'LPG',
  7: 'Petrol',
  8: 'LPG + Petrol',
  9: 'Electric',
};

class DealerInsuranceOption {
  final int id;
  final String name;
  final int fuelTypeId;
  final String regionCode;
  final String stateName;
  final String cityName;

  const DealerInsuranceOption({
    required this.id,
    required this.name,
    this.fuelTypeId = 0,
    this.regionCode = '',
    this.stateName = '',
    this.cityName = '',
  });

  factory DealerInsuranceOption.rto(Map<String, dynamic> j) {
    final code = _str(j['RegionCode']);
    final city = _str(j['CityName']);
    final state = _str(j['StateName']);
    return DealerInsuranceOption(
      id: _int(j['RegisteredCityId']),
      name: [code, city, if (state.isNotEmpty) '($state)'].join(' ').trim(),
      regionCode: code,
      stateName: state,
      cityName: city,
    );
  }

  DealerInsuranceOption.make(Map<String, dynamic> j)
    : this(id: _int(j['makeId']), name: _str(j['makeName']));

  DealerInsuranceOption.model(Map<String, dynamic> j)
    : this(id: _int(j['modelId']), name: _str(j['modelName']));

  factory DealerInsuranceOption.variant(Map<String, dynamic> j) {
    final fuelTypeId = _int(j['fuelTypeId']);
    final fuel = dealerInsuranceFuelTypes[fuelTypeId];
    return DealerInsuranceOption(
      id: _int(j['variantId']),
      name: [_str(j['variantName']), if (fuel != null) fuel].join(' · '),
      fuelTypeId: fuelTypeId,
    );
  }

  String get fuelType => dealerInsuranceFuelTypes[fuelTypeId] ?? '';
}

class DealerInsuranceQuoteModel {
  final String insurer;
  final double premium;
  final double idv;

  DealerInsuranceQuoteModel.fromJson(Map<String, dynamic> j)
    : insurer = _str(j['insurer']),
      premium = _num(j['premium']),
      idv = _num(j['idv']);
}

class DealerInsuranceQuoteReportModel {
  final String carType;
  final String policyType;
  final String registrationNumber;
  final String makeName;
  final String modelName;
  final String variantName;
  final String regionCode;
  final String redirectLink;
  final List<DealerInsuranceQuoteModel> quotes;
  final DateTime? updatedAt;

  DealerInsuranceQuoteReportModel.fromJson(Map<String, dynamic> j)
    : carType = _str(j['carType']),
      policyType = _str(j['policyType']),
      registrationNumber = _str(j['registrationNumber']),
      makeName = _str(j['makeName']),
      modelName = _str(j['modelName']),
      variantName = _str(j['variantName']),
      regionCode = _str(j['regionCode']),
      redirectLink = _str(j['redirectLink']),
      quotes = [
        for (final q in (j['quotes'] as List? ?? const []))
          if (q is Map) DealerInsuranceQuoteModel.fromJson(Map.from(q)),
      ],
      updatedAt = DateTime.tryParse(_str(j['updatedAt']));

  bool get isNewCar => carType == 'New Car';

  String get title =>
      isNewCar
          ? [
            makeName,
            modelName,
            variantName,
          ].where((s) => s.isNotEmpty).join(' ')
          : registrationNumber;

  String get subtitle =>
      isNewCar
          ? 'New car · RTO $regionCode'
          : 'Used car · ${policyType == 'TP' ? 'Third Party' : policyType}';

  double? get lowestPremium =>
      quotes.isEmpty
          ? null
          : quotes.map((q) => q.premium).reduce((a, b) => a < b ? a : b);
}
