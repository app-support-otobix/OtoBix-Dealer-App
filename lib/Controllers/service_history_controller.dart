import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:otobix/Models/service_history_reports_model.dart';
import 'package:otobix/Network/api_service.dart';
import 'package:otobix/Utils/app_urls.dart';
import 'package:otobix/Views/Dealer Panel/service_history_checkout_page.dart';
import 'package:otobix/Widgets/toast_widget.dart';
import 'package:otobix/helpers/shared_prefs_helper.dart';
import 'package:path_provider/path_provider.dart';

class ServiceHistoryController extends GetxController {
  final TextEditingController registrationController = TextEditingController();

  final RxBool isServiceHistoryLoading = false.obs;
  final RxBool isSampleServiceHistoryPdfLoading = false.obs;
  final RxBool isServiceHistoryReportsListLoading = false.obs;
  final RxBool isDownloadReportLoading = false.obs;
  final RxBool isDownloadDetailsLoading = false.obs;
  final RxBool hasLoadedReports = false.obs;

  final RxList<ServiceHistoryReportsModel> serviceHistoryReportsList =
      <ServiceHistoryReportsModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchServiceHistoryReportsList();
  }

  void onDownloadReport({
    required String pdfFileUrl,
    required String paymentId,
  }) {
    if (isDownloadReportLoading.value) {
      return;
    }
    isDownloadReportLoading.value = true;
    try {
      downloadAndOpenFile(
        url: pdfFileUrl,
        fileName: 'service_history_report_$paymentId.pdf',
      );
    } catch (e) {
      ToastWidget.show(
        context: Get.context!,
        title: 'Error',
        subtitle: 'Failed to open file. Please try again.',
        type: ToastType.error,
      );
    } finally {
      isDownloadReportLoading.value = false;
    }
  }

  void onDownloadDetails({
    required String xlsxFileUrl,
    required String paymentId,
  }) {
    if (isDownloadDetailsLoading.value) {
      return;
    }
    isDownloadDetailsLoading.value = true;
    try {
      downloadAndOpenFile(
        url: xlsxFileUrl,
        fileName: 'service_history_report_$paymentId.xlsx',
      );
    } catch (e) {
      ToastWidget.show(
        context: Get.context!,
        title: 'Error',
        subtitle: 'Failed to open file. Please try again.',
        type: ToastType.error,
      );
    } finally {
      isDownloadDetailsLoading.value = false;
    }
  }

  // Fetch service history
  Future<void> fetchServiceHistory() async {
    final reg = registrationController.text.trim();
    if (reg.isEmpty) {
      ToastWidget.show(
        context: Get.context!,
        title: 'Required',
        subtitle: 'Please enter car registration number.',
        type: ToastType.error,
      );
      return;
    }

    if (isServiceHistoryLoading.value) {
      return;
    }
    isServiceHistoryLoading.value = true;

    final userId =
        await SharedPrefsHelper.getString(SharedPrefsHelper.userIdKey) ?? '';

    try {
      final response = await ApiService.get(
        endpoint: AppUrls.fetchServiceHistory(
          registrationNumber: reg,
          userId: userId,
        ),
      );
      final body = jsonDecode(response.body);
      final String message = body['message']?.toString() ?? '';
      final data = body['data'] ?? {};

      if (response.statusCode == 400) {
        ToastWidget.show(
          context: Get.context!,
          title: "Failed",
          subtitle:
              message.isNotEmpty ? message : "Unable to get service history",
          type: ToastType.error,
        );
        return;
      }

      if (response.statusCode == 200) {
        final String make = data['make']?.toString() ?? '';
        final String model = data['model']?.toString() ?? '';
        final String registrationNumber =
            data['registrationNumber']?.toString() ?? '';
        final String chassisNumber = data['chassisNumber']?.toString() ?? '';
        final String engineNumber = data['engineNumber']?.toString() ?? '';

        final String registrationDateStr =
            data['registrationDate']?.toString() ?? '';
        final DateTime? registrationDate =
            registrationDateStr.isNotEmpty
                ? DateTime.tryParse(registrationDateStr)
                : null;

        final String fuelType = data['fuelType']?.toString() ?? 'NA';
        final String bodyType = data['bodyType']?.toString() ?? 'NA';
        final int ownerSerialNumber = data['ownerSerialNumber'] ?? 1;

        final Map<String, dynamic> serviceHistory = Map<String, dynamic>.from(
          data['serviceHistory'] ?? {},
        );

        final double rate = (serviceHistory['rate'] as num?)?.toDouble() ?? 0.0;
        final double gst = (serviceHistory['gst'] as num?)?.toDouble() ?? 0.0;
        final double total =
            (serviceHistory['total'] as num?)?.toDouble() ?? 0.0;

        Get.to(
          () => ServiceHistoryCheckoutPage(
            make: make,
            model: model,
            registrationNumber: registrationNumber,
            chassisNumber: chassisNumber,
            engineNumber: engineNumber,
            bodyType: bodyType,
            registrationDate: registrationDate,
            fuelType: fuelType,
            ownerSerialNumber: ownerSerialNumber,
            rate: rate,
            gst: gst,
            total: total,
          ),
        );
      } else {
        ToastWidget.show(
          context: Get.context!,
          title: "Failed",
          subtitle: "Failed to get service history",
          type: ToastType.error,
        );
      }
    } catch (e) {
      debugPrint(e.toString());
      ToastWidget.show(
        context: Get.context!,
        title: 'Error',
        subtitle: 'Error getting service history',
        type: ToastType.error,
      );
    } finally {
      isServiceHistoryLoading.value = false;
    }
  }

  // Download and open Sample Service History PDF
  Future<void> downloadAndOpenSampleServiceHistoryPdf() async {
    try {
      if (isSampleServiceHistoryPdfLoading.value) {
        return;
      }

      isSampleServiceHistoryPdfLoading.value = true;

      final response = await ApiService.get(
        endpoint: AppUrls.fetchSampleServiceHistoryPdf,
      );

      final body = jsonDecode(response.body);
      final String message = body['message']?.toString() ?? '';
      final pdfUrl = body['data']['pdfUrl'] ?? '';

      if (response.statusCode == 400) {
        ToastWidget.show(
          context: Get.context!,
          title: "Failed",
          subtitle: message.isNotEmpty ? message : "Unable to download PDF",
          type: ToastType.error,
        );
        return; // keep unlocked
      }

      if (response.statusCode == 200) {
        final dir = await getApplicationDocumentsDirectory();
        final String fileName = 'Sample Service History Report.pdf';
        final filePath = "${dir.path}/$fileName";

        // If already downloaded, open directly
        if (File(filePath).existsSync()) {
          await OpenFilex.open(filePath);
          return;
        }

        final dio = Dio();
        await dio.download(
          pdfUrl,
          filePath,
          options: Options(
            responseType: ResponseType.bytes,
            followRedirects: true,
            receiveTimeout: const Duration(seconds: 60),
            sendTimeout: const Duration(seconds: 60),
          ),
          onReceiveProgress: (received, total) {
            // Optional: you can store progress in RxDouble and show in UI
            // final progress = total > 0 ? received / total : 0.0;
          },
        );

        ToastWidget.show(
          context: Get.context!,
          title: 'Downloaded',
          subtitle: 'Sample report downloaded successfully.',
          type: ToastType.success,
        );

        await OpenFilex.open(filePath);
      } else {
        ToastWidget.show(
          context: Get.context!,
          title: "Failed",
          subtitle: "Unable to download PDF",
          type: ToastType.error,
        );
      }
    } catch (e) {
      debugPrint("PDF download error: $e");
      ToastWidget.show(
        context: Get.context!,
        title: 'Error',
        subtitle: 'Unable to download PDF. Please try again.',
        type: ToastType.error,
      );
    } finally {
      isSampleServiceHistoryPdfLoading.value = false;
    }
  }

  // Download and open file
  Future<void> downloadAndOpenFile({
    required String url,
    required String fileName,
  }) async {
    final dir = await getApplicationDocumentsDirectory();
    final filePath = "${dir.path}/$fileName";

    // If already downloaded, open directly
    if (File(filePath).existsSync()) {
      await OpenFilex.open(filePath);
      return;
    }

    final dio = Dio();
    await dio.download(
      url,
      filePath,
      options: Options(
        responseType: ResponseType.bytes,
        followRedirects: true,
        receiveTimeout: const Duration(seconds: 60),
        sendTimeout: const Duration(seconds: 60),
      ),
      onReceiveProgress: (received, total) {
        // Optional: you can store progress in RxDouble and show in UI
        // final progress = total > 0 ? received / total : 0.0;
      },
    );

    await OpenFilex.open(filePath);
  }

  String getOwnerSerialNumberString({required int ownerSerialNumber}) {
    if (ownerSerialNumber == 1) {
      return '1st';
    } else if (ownerSerialNumber == 2) {
      return '2nd';
    } else if (ownerSerialNumber == 3) {
      return '3rd';
    } else {
      return '$ownerSerialNumber th';
    }
  }

  String formatDateWithSuffix(DateTime? date) {
    if (date == null) return '';

    final day = date.day;
    String suffix = 'th';

    if (day % 10 == 1 && day % 100 != 11) {
      suffix = 'st';
    } else if (day % 10 == 2 && day % 100 != 12) {
      suffix = 'nd';
    } else if (day % 10 == 3 && day % 100 != 13) {
      suffix = 'rd';
    }

    final monthYear = DateFormat('MMMM, y').format(date);
    return '$day$suffix $monthYear';
  }

  // Fetch reports list
  Future<void> fetchServiceHistoryReportsList() async {
    if (isServiceHistoryReportsListLoading.value) {
      return;
    }
    isServiceHistoryReportsListLoading.value = true;

    final userId =
        await SharedPrefsHelper.getString(SharedPrefsHelper.userIdKey) ?? '';

    try {
      final response = await ApiService.get(
        endpoint: AppUrls.fetchServiceHistoryReportsList(userId: userId),
      );
      final body = jsonDecode(response.body);
      final String message = body['message']?.toString() ?? '';
      final data = body['data'] ?? {};

      // debugPrint('Service history reports list: $body');

      if (response.statusCode == 400) {
        ToastWidget.show(
          context: Get.context!,
          title: "Failed",
          subtitle:
              message.isNotEmpty ? message : "Unable to get service history",
          type: ToastType.error,
        );
        return;
      }

      if (response.statusCode == 200) {
        final List reports = data['reportsList'] ?? [];
        final List<ServiceHistoryReportsModel> reportsList =
            reports.map((e) => ServiceHistoryReportsModel.fromJson(e)).toList();

        serviceHistoryReportsList.value = reportsList;

        // You can now use reportsList as needed
        debugPrint('Fetched ${reportsList.length} reports');
      } else {
        serviceHistoryReportsList.value = [];
      }
    } catch (e) {
      debugPrint(e.toString());
      serviceHistoryReportsList.value = [];
    } finally {
      isServiceHistoryReportsListLoading.value = false;
      hasLoadedReports.value = true;
    }
  }

  @override
  void onClose() {
    registrationController.dispose();
    super.onClose();
  }
}
