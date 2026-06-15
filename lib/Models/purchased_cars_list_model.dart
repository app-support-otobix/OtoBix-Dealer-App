// import 'package:get/get_rx/src/rx_types/rx_types.dart';
// import 'package:otobix/Models/car_model.dart';
// import 'package:otobix/Models/cars_list_model.dart';

// class PurchasedCarsListModel {
//   final String? id;
//   final String imageUrl;
//   final String make;
//   final String model;
//   final String variant;
//   final double priceDiscovery;
//   final DateTime? yearMonthOfManufacture;
//   final int odometerReadingInKms;
//   final String fuelType;
//   final String inspectionLocation;
//   final bool isInspected;
//   final String roadTaxValidity;
//   final DateTime? taxValidTill;
//   final int ownerSerialNumber;
//   final String commentsOnTransmission;
//   final String registrationNumber;
//   final String registeredRto;
//   final RxDouble highestBid;
//   final List<CarsListTitleAndImage>? imageUrls;

//   PurchasedCarsListModel({
//     this.id,
//     required this.imageUrl,
//     required this.make,
//     required this.model,
//     required this.variant,
//     required this.priceDiscovery,
//     required this.yearMonthOfManufacture,
//     required this.odometerReadingInKms,
//     required this.fuelType,
//     required this.inspectionLocation,
//     required this.isInspected,
//     required this.roadTaxValidity,
//     required this.taxValidTill,
//     required this.ownerSerialNumber,
//     required this.commentsOnTransmission,
//     required this.registrationNumber,
//     required this.registeredRto,
//     required this.highestBid,
//     required this.imageUrls,
//   });

//   // Factory constructor to create a Car from JSON map
//   factory PurchasedCarsListModel.fromJson({
//     required String documentId,
//     required Map<String, dynamic> data,
//   }) {
//     return PurchasedCarsListModel(
//       id: documentId,
//       imageUrl: data['imageUrl'] ?? '',
//       make: data['make'] ?? '',
//       model: data['model'] ?? '',
//       variant: data['variant'] ?? '',
//       priceDiscovery:
//           data['priceDiscovery'] is double
//               ? data['priceDiscovery']
//               : double.tryParse(data['priceDiscovery']?.toString() ?? '0') ??
//                   0.0,
//       yearMonthOfManufacture: parseMongoDbDate(data["yearMonthOfManufacture"]),
//       odometerReadingInKms:
//           data['odometerReadingInKms'] is int
//               ? data['odometerReadingInKms']
//               : int.tryParse(data['odometerReadingInKms']?.toString() ?? ''),
//       fuelType: data['fuelType'] ?? '',
//       inspectionLocation: data['inspectionLocation'],
//       isInspected: data['isInspected'] ?? false,
//       roadTaxValidity: data['roadTaxValidity'] ?? '',
//       taxValidTill: parseMongoDbDate(data["taxValidTill"]),
//       ownerSerialNumber:
//           data['ownerSerialNumber'] is int
//               ? data['ownerSerialNumber']
//               : int.tryParse(data['ownerSerialNumber']?.toString() ?? ''),
//       commentsOnTransmission: data['commentsOnTransmission'] ?? '',
//       registrationNumber: data['registrationNumber'] ?? '',
//       registeredRto: data['registeredRto'] ?? '',
//       highestBid: RxDouble(
//         double.tryParse(data['highestBid']?.toString() ?? '0') ?? 0.0,
//       ),
//       imageUrls:
//           (data['imageUrls'] as List<dynamic>?)
//               ?.map((e) => CarsListTitleAndImage.fromJson(e))
//               .toList(),
//     );
//   }

//   // Convert Car object to JSON map
//   Map<String, dynamic> toJson() {
//     return {
//       'imageUrl': imageUrl,
//       'make': make,
//       'model': model,
//       'variant': variant,
//       'priceDiscovery': priceDiscovery,
//       'yearMonthOfManufacture': yearMonthOfManufacture,
//       'odometerReadingInKms': odometerReadingInKms,
//       'fuelType': fuelType,
//       'inspectionLocation': inspectionLocation,
//       'isInspected': isInspected,
//       'roadTaxValidity': roadTaxValidity,
//       'taxValidTill': taxValidTill,
//       'ownerSerialNumber': ownerSerialNumber,
//       'commentsOnTransmission': commentsOnTransmission,
//       'registrationNumber': registrationNumber,
//       'registeredRto': registeredRto,
//       'highestBid': highestBid.value,
//       'imageUrls': imageUrls?.map((e) => e.toJson()).toList(),
//     };
//   }
// }
