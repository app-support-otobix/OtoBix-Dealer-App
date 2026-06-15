class ServiceHistoryReportsModel {
  final String? id;
  final String registrationNumber;
  final String make;
  final String model;
  final String fuelType;
  final String bodyType;
  final int ownerSerialNumber;
  final DateTime? registrationDate;
  final String status;
  final String paymentId;
  final String otobixPdfReportUrl;
  final String xlsxFileUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ServiceHistoryReportsModel({
    this.id,
    required this.registrationNumber,
    required this.make,
    required this.model,
    required this.bodyType,
    this.registrationDate,
    required this.fuelType,
    required this.ownerSerialNumber,
    required this.status,
    required this.paymentId,
    required this.otobixPdfReportUrl,
    required this.xlsxFileUrl,
    this.createdAt,
    this.updatedAt,
  });

  factory ServiceHistoryReportsModel.fromJson(Map<String, dynamic> json) {
    return ServiceHistoryReportsModel(
      id: json['_id']?.toString(),
      registrationNumber: json['registrationNumber'] ?? '',
      make: json['make'] ?? '',
      model: json['model'] ?? '',
      bodyType: json['bodyType'] ?? '',
      registrationDate:
          json['registrationDate'] != null
              ? DateTime.tryParse(json['registrationDate'].toString())
              : null,
      fuelType: json['fuelType'] ?? '',
      ownerSerialNumber: json['ownerSerialNumber'] ?? 1,
      status: json['status'] ?? 'Pending',
      paymentId: json['paymentId'] ?? '',
      otobixPdfReportUrl: json['otobixPdfReportUrl'] ?? '',
      xlsxFileUrl: json['xlsxFileUrl'] ?? '',
      createdAt:
          json['createdAt'] != null
              ? DateTime.tryParse(json['createdAt'].toString())
              : null,
      updatedAt:
          json['updatedAt'] != null
              ? DateTime.tryParse(json['updatedAt'].toString())
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'registrationNumber': registrationNumber,
      'make': make,
      'model': model,
      'bodyType': bodyType,
      'registrationDate': registrationDate?.toIso8601String(),
      'fuelType': fuelType,
      'ownerSerialNumber': ownerSerialNumber,
      'status': status,
      'paymentId': paymentId,
      'otobixPdfReportUrl': otobixPdfReportUrl,
      'xlsxFileUrl': xlsxFileUrl,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
