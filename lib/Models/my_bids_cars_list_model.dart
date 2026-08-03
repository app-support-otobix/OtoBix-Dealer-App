import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:otobix/Models/car_model.dart';

class MyBidsCarsListModel {
  final String? id;
  final String imageUrl;
  final String make;
  final String model;
  final String variant;
  final double priceDiscovery;
  final DateTime? yearMonthOfManufacture;
  final DateTime? yearAndMonthOfManufacture;
  final int odometerReadingInKms;
  final int odometerReadingBeforeTestDrive;
  final String fuelType;
  final String inspectionLocation;
  final String inspectionCity;
  final String city;
  final bool isInspected;
  final String roadTaxValidity;
  final DateTime? taxValidTill;
  final int ownerSerialNumber;
  final String commentsOnTransmission;
  final List<String> transmissionTypeDropdownList;
  final String registrationNumber;
  final String registeredRto;
  final RxDouble highestBid;
  final RxDouble oneClickPrice;
  final RxDouble customerExpectedPrice;
  final RxDouble fixedMargin;
  final RxDouble variableMargin;

  MyBidsCarsListModel({
    this.id,
    required this.imageUrl,
    required this.make,
    required this.model,
    required this.variant,
    required this.priceDiscovery,
    required this.yearMonthOfManufacture,
    required this.yearAndMonthOfManufacture,
    required this.odometerReadingInKms,
    required this.odometerReadingBeforeTestDrive,
    required this.fuelType,
    required this.inspectionLocation,
    required this.inspectionCity,
    required this.city,
    required this.isInspected,
    required this.roadTaxValidity,
    required this.taxValidTill,
    required this.ownerSerialNumber,
    required this.commentsOnTransmission,
    required this.transmissionTypeDropdownList,
    required this.registrationNumber,
    required this.registeredRto,
    required this.highestBid,
    required this.oneClickPrice,
    required this.customerExpectedPrice,
    required this.fixedMargin,
    required this.variableMargin,
  });

  // Factory constructor to create a Car from JSON map
  factory MyBidsCarsListModel.fromJson({
    required String documentId,
    required Map<String, dynamic> data,
  }) {
    return MyBidsCarsListModel(
      id: documentId,
      imageUrl: data['imageUrl'] ?? '',
      make: data['make'] ?? '',
      model: data['model'] ?? '',
      variant: data['variant'] ?? '',
      priceDiscovery:
          data['priceDiscovery'] is double
              ? data['priceDiscovery']
              : double.tryParse(data['priceDiscovery']?.toString() ?? '0') ??
                  0.0,
      yearMonthOfManufacture: parseMongoDbDate(data["yearMonthOfManufacture"]),
      yearAndMonthOfManufacture: parseMongoDbDate(
        data["yearAndMonthOfManufacture"],
      ),
      odometerReadingInKms:
          data['odometerReadingInKms'] is int
              ? data['odometerReadingInKms']
              : int.tryParse(data['odometerReadingInKms']?.toString() ?? '0'),
      odometerReadingBeforeTestDrive:
          data['odometerReadingBeforeTestDrive'] is int
              ? data['odometerReadingBeforeTestDrive']
              : int.tryParse(
                data['odometerReadingBeforeTestDrive']?.toString() ?? '0',
              ),
      fuelType: data['fuelType'] ?? '',
      inspectionLocation: data['inspectionLocation'],
      inspectionCity: data['inspectionCity'] ?? '',
      city: data['city'] ?? '',
      isInspected: data['isInspected'] ?? false,
      roadTaxValidity: data['roadTaxValidity'] ?? '',
      taxValidTill: parseMongoDbDate(data["taxValidTill"]),
      ownerSerialNumber:
          data['ownerSerialNumber'] is int
              ? data['ownerSerialNumber']
              : int.tryParse(data['ownerSerialNumber']?.toString() ?? ''),
      commentsOnTransmission: data['commentsOnTransmission'] ?? '',
      transmissionTypeDropdownList:
          (data['transmissionTypeDropdownList'] as List?)
              ?.where((e) => e != null)
              .map((e) => e.toString())
              .toList() ??
          [],
      registrationNumber: data['registrationNumber'] ?? '',
      registeredRto: data['registeredRto'] ?? '',
      highestBid: RxDouble(
        double.tryParse(data['highestBid']?.toString() ?? '0') ?? 0.0,
      ),
      oneClickPrice: RxDouble(
        double.tryParse(data['oneClickPrice']?.toString() ?? '0') ?? 0.0,
      ),
      customerExpectedPrice: RxDouble(
        double.tryParse(data['customerExpectedPrice']?.toString() ?? '0') ??
            0.0,
      ),
      fixedMargin: RxDouble(
        double.tryParse(data['fixedMargin']?.toString() ?? '0') ?? 0.0,
      ),
      variableMargin: RxDouble(
        double.tryParse(data['variableMargin']?.toString() ?? '0') ?? 0.0,
      ),
    );
  }

  // Convert Car object to JSON map
  Map<String, dynamic> toJson() {
    return {
      'imageUrl': imageUrl,
      'make': make,
      'model': model,
      'variant': variant,
      'priceDiscovery': priceDiscovery,
      'yearMonthOfManufacture': yearMonthOfManufacture,
      'yearAndMonthOfManufacture': yearAndMonthOfManufacture,
      'odometerReadingInKms': odometerReadingInKms,
      'odometerReadingBeforeTestDrive': odometerReadingBeforeTestDrive,
      'fuelType': fuelType,
      'inspectionLocation': inspectionLocation,
      'inspectionCity': inspectionCity,
      'city': city,
      'isInspected': isInspected,
      'roadTaxValidity': roadTaxValidity,
      'taxValidTill': taxValidTill,
      'ownerSerialNumber': ownerSerialNumber,
      'commentsOnTransmission': commentsOnTransmission,
      'transmissionTypeDropdownList': transmissionTypeDropdownList,
      'registrationNumber': registrationNumber,
      'registeredRto': registeredRto,
      'highestBid': highestBid.value,
      'oneClickPrice': oneClickPrice.value,
      'customerExpectedPrice': customerExpectedPrice.value,
      'fixedMargin': fixedMargin.value,
      'variableMargin': variableMargin.value,
    };
  }
}
