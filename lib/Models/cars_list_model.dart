import 'dart:async';

import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:otobix/Models/car_model.dart';

class CarsListModel {
  RxString remainingAuctionTime = '00h : 00m : 00s'.obs;
  Timer? auctionTimer;

  ///
  final String id;
  final String imageUrl;
  final String make;
  final String model;
  final String variant;
  final double priceDiscovery;
  final DateTime? yearMonthOfManufacture;
  final int odometerReadingInKms;
  final int ownerSerialNumber;
  final String fuelType;
  final String commentsOnTransmission;
  final String roadTaxValidity;
  final DateTime? taxValidTill;
  final String registrationNumber;
  final String registeredRto;
  final String registrationState;
  final DateTime? registrationDate;
  final String inspectionLocation;
  final bool isInspected;
  final int cubicCapacity;
  final RxDouble highestBid;
  DateTime? auctionStartTime;
  DateTime? auctionEndTime;
  int auctionDuration;
  final String auctionStatus;
  final int upcomingTime;
  final DateTime? upcomingUntil;
  final DateTime? liveAt;
  final RxDouble oneClickPrice;
  final double otobuyOffer;
  final double soldAt;
  final RxDouble customerExpectedPrice;
  final RxDouble fixedMargin;
  final RxDouble variableMargin;
  final List<CarsListTitleAndImage>? imageUrls;

  final RxBool isFavorite;

  CarsListModel({
    required this.id,
    required this.imageUrl,
    required this.make,
    required this.model,
    required this.variant,
    required this.priceDiscovery,
    required this.yearMonthOfManufacture,
    required this.odometerReadingInKms,
    required this.ownerSerialNumber,
    required this.fuelType,
    required this.commentsOnTransmission,
    required this.roadTaxValidity,
    required this.taxValidTill,
    required this.registrationNumber,
    required this.registeredRto,
    required this.registrationState,
    required this.registrationDate,
    required this.inspectionLocation,
    required this.isInspected,
    required this.cubicCapacity,
    required this.highestBid,
    required this.auctionStartTime,
    required this.auctionEndTime,
    required this.auctionDuration,
    required this.auctionStatus,
    required this.upcomingTime,
    required this.upcomingUntil,
    required this.liveAt,
    required this.oneClickPrice,
    required this.otobuyOffer,
    required this.soldAt,
    required this.customerExpectedPrice,
    required this.fixedMargin,
    required this.variableMargin,
    required this.imageUrls,
    bool isFavorite = false,
  }) : isFavorite = isFavorite.obs;

  // Factory constructor to create a Car from JSON map
  factory CarsListModel.fromJson({
    required String id,
    required Map<String, dynamic> data,
  }) {
    return CarsListModel(
      id: id,
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
      odometerReadingInKms:
          data['odometerReadingInKms'] is int
              ? data['odometerReadingInKms']
              : int.tryParse(data['odometerReadingInKms']?.toString() ?? '0'),
      ownerSerialNumber:
          data['ownerSerialNumber'] is int
              ? data['ownerSerialNumber']
              : int.tryParse(data['ownerSerialNumber']?.toString() ?? ''),
      fuelType: data['fuelType'] ?? '',
      commentsOnTransmission: data['commentsOnTransmission'] ?? '',
      roadTaxValidity: data['roadTaxValidity'] ?? '',
      taxValidTill: parseMongoDbDate(data["taxValidTill"]),
      registrationNumber: data['registrationNumber'],
      registeredRto: data['registeredRto'],
      registrationState: data["registrationState"] ?? 'N/A',
      registrationDate: parseMongoDbDate(data["registrationDate"]),
      inspectionLocation: data['inspectionLocation'],
      isInspected: data['isInspected'] ?? false,
      cubicCapacity: data['cubicCapacity'] ?? 0,
      highestBid: RxDouble(
        double.tryParse(data['highestBid']?.toString() ?? '0') ?? 0.0,
      ),
      auctionStartTime: parseMongoDbDate(data["auctionStartTime"]),
      auctionEndTime: parseMongoDbDate(data["auctionEndTime"]),
      auctionDuration: data['auctionDuration'] ?? 0,
      auctionStatus: data['auctionStatus'] ?? '',
      upcomingTime: data['upcomingTime'] ?? 0,
      upcomingUntil: parseMongoDbDate(data["upcomingUntil"]),
      liveAt: parseMongoDbDate(data["liveAt"]),
      oneClickPrice: RxDouble(
        double.tryParse(data['oneClickPrice']?.toString() ?? '0') ?? 0.0,
      ),
      otobuyOffer:
          double.tryParse(data['otobuyOffer']?.toString() ?? '0') ?? 0.0,
      soldAt: double.tryParse(data['soldAt']?.toString() ?? '0') ?? 0.0,
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
      imageUrls:
          (data['imageUrls'] as List<dynamic>?)
              ?.map((e) => CarsListTitleAndImage.fromJson(e))
              .toList(),
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
      'odometerReadingInKms': odometerReadingInKms,
      'ownerSerialNumber': ownerSerialNumber,
      'fuelType': fuelType,
      'commentsOnTransmission': commentsOnTransmission,
      'roadTaxValidity': roadTaxValidity,
      'taxValidTill': taxValidTill,
      'registrationNumber': registrationNumber,
      'registeredRto': registeredRto,
      'registrationState': registrationState,
      'registrationDate': registrationDate,
      'inspectionLocation': inspectionLocation,
      'isInspected': isInspected,
      'cubicCapacity': cubicCapacity,
      'highestBid': highestBid.value,
      'auctionStartTime': auctionStartTime,
      'auctionEndTime': auctionEndTime,
      'auctionDuration': auctionDuration,
      'auctionStatus': auctionStatus,
      'upcomingTime': upcomingTime,
      'upcomingUntil': upcomingUntil,
      'liveAt': liveAt,
      'oneClickPrice': oneClickPrice.value,
      'otobuyOffer': otobuyOffer,
      'soldAt': soldAt,
      'customerExpectedPrice': customerExpectedPrice.value,
      'fixedMargin': fixedMargin.value,
      'variableMargin': variableMargin.value,
      'imageUrls': imageUrls?.map((e) => e.toJson()).toList(),
    };
  }
}

class CarsListTitleAndImage {
  final String title;
  final String url;

  CarsListTitleAndImage({required this.title, required this.url});

  factory CarsListTitleAndImage.fromJson(Map<String, dynamic> json) {
    return CarsListTitleAndImage(
      title: json['title'] ?? '',
      url: json['url'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'title': title, 'url': url};
}
