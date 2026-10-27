import 'package:otobix/Utils/global_functions.dart';

String _str(dynamic v) => GlobalFunctions.parse<String>(v) ?? '';
int _int(dynamic v) => GlobalFunctions.parse<int>(v) ?? 0;

class DealerInventoryCarModel {
  static const dealerOwned = 'DEALER_OWNED';
  static const customerOwned = 'CUSTOMER_OWNED';

  final String id;
  final String inventoryCode;
  final String listingCode;
  final String ownership;
  final String customerName;
  final String customerPhone;

  /// A customer car's own place (private to this dealer); null when not set.
  final String carAddress;
  final double? carLatitude;
  final double? carLongitude;
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
  final String bodyType;
  final int ownerSerialNo;
  final String taxValidity;
  final String insuranceValidity;
  final String rto;
  final int kms;
  final String city;
  final String state;
  final String description;
  final List<String> images;
  final bool retailEnabled;
  final int retailPrice;
  final bool exchangeEnabled;
  final int exchangePrice;
  final String exchangeVisibility;
  final String qcStatus; // PENDING | APPROVED | REJECTED
  final String qcReason;
  final String status;
  final int offerCount;

  /// The highest price dealers are offering now (0 = no open offer).
  final int bestOffer;
  final int leadCount;

  bool get isCustomerCar => ownership == customerOwned;
  bool get isQcPending => qcStatus == 'PENDING';
  bool get isQcRejected => qcStatus == 'REJECTED';

  DealerInventoryCarModel.fromJson(Map<String, dynamic> j)
    : id = _str(j['id']),
      inventoryCode = _str(j['inventoryCode']),
      listingCode = _str(j['listingCode']),
      ownership = _str(j['ownership']),
      customerName = _str(j['customerName']),
      customerPhone = _str(j['customerPhone']),
      carAddress = _str(j['carAddress']),
      carLatitude = (j['carLocation']?['latitude'] as num?)?.toDouble(),
      carLongitude = (j['carLocation']?['longitude'] as num?)?.toDouble(),
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
      bodyType = _str(j['bodyType']),
      ownerSerialNo = _int(j['ownerSerialNo']),
      taxValidity = _str(j['taxValidity']),
      insuranceValidity = _str(j['insuranceValidity']),
      rto = _str(j['rto']),
      kms = _int(j['kms']),
      city = _str(j['city']),
      state = _str(j['state']),
      description = _str(j['description']),
      images = (j['images'] as List? ?? []).map((e) => e.toString()).toList(),
      retailEnabled = j['retail']?['enabled'] == true,
      retailPrice = _int(j['retail']?['price']),
      exchangeEnabled = j['exchange']?['enabled'] == true,
      exchangePrice = _int(j['exchange']?['price']),
      exchangeVisibility = _str(j['exchange']?['visibility']),
      qcStatus = _str(j['qc']?['status']),
      qcReason = _str(j['qc']?['reason']),
      status = _str(j['status']),
      offerCount = _int(j['offerCount']),
      bestOffer = _int(j['bestOffer']),
      leadCount = _int(j['leadCount']);
}

class DealerRcPrefillModel {
  final String registrationNumber;
  final String make;
  final String model;
  final String variant;
  final int mfgYear;
  final int regnYear;
  final String colour;
  final String fuelType;
  final String bodyType;
  final int ownerSerialNo;
  final String taxValidity;
  final String insuranceValidity;
  final String rto;
  final String state;

  DealerRcPrefillModel.fromJson(Map<String, dynamic> j)
    : registrationNumber = _str(j['registrationNumber']),
      make = _str(j['make']),
      model = _str(j['model']),
      variant = _str(j['variant']),
      mfgYear = _int(j['mfgYear']),
      regnYear = _int(j['regnYear']),
      colour = _str(j['colour']),
      fuelType = _str(j['fuelType']),
      bodyType = _str(j['bodyType']),
      ownerSerialNo = _int(j['ownerSerialNo']),
      taxValidity = _str(j['taxValidity']),
      insuranceValidity = _str(j['insuranceValidity']),
      rto = _str(j['rto']),
      state = _str(j['state']);

  DealerRcPrefillModel.fromCar(DealerInventoryCarModel c)
    : registrationNumber = c.registrationNumber,
      make = c.make,
      model = c.model,
      variant = c.variant,
      mfgYear = c.mfgYear,
      regnYear = c.regnYear,
      colour = c.colour,
      fuelType = c.fuelType,
      bodyType = c.bodyType,
      ownerSerialNo = c.ownerSerialNo,
      taxValidity = c.taxValidity,
      insuranceValidity = c.insuranceValidity,
      rto = c.rto,
      state = c.state;

  Map<String, dynamic> toJson() => {
    'registrationNumber': registrationNumber,
    'make': make,
    'model': model,
    'variant': variant,
    'mfgYear': mfgYear,
    'regnYear': regnYear,
    'colour': colour,
    'fuelType': fuelType,
    'bodyType': bodyType,
    'ownerSerialNo': ownerSerialNo,
    'taxValidity': taxValidity,
    'insuranceValidity': insuranceValidity,
    'rto': rto,
    'state': state,
  };
}
