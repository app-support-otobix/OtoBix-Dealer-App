import 'package:otobix/Utils/global_functions.dart';

String _str(dynamic v) => GlobalFunctions.parse<String>(v) ?? '';

class DealerLeadModel {
  final String id;
  final String leadCode;
  final String carId;
  final String carImage; // front photo of the car, '' when there is none
  final String source;
  final String customerName;
  final String contactNo;
  final String make;
  final String model;
  final String variant;
  final String transmission;
  final String year;
  final String note;
  final String status;
  final Map<String, dynamic> statusDetails;
  final DateTime? updatedAt;

  String get sourceLabel =>
      const {
        'OTO_APP': 'OtoBix App',
        'OTO_WEBSITE': 'OtoBix Website',
        'OTHER': 'Other · walk-in',
      }[source] ??
      source;

  DealerLeadModel.fromJson(Map<String, dynamic> j)
    : id = _str(j['id']),
      leadCode = _str(j['leadCode']),
      carId = _str(j['carId']),
      carImage = _str(j['carImage']),
      source = _str(j['source']),
      customerName = _str(j['customerName']),
      contactNo = _str(j['contactNo']),
      make = _str(j['make']),
      model = _str(j['model']),
      variant = _str(j['variant']),
      transmission = _str(j['transmission']),
      year = _str(j['year']),
      note = _str(j['note']),
      status = _str(j['status']),
      statusDetails = Map<String, dynamic>.from(j['statusDetails'] ?? {}),
      updatedAt = GlobalFunctions.parse<DateTime>(j['updatedAt']);
}
