import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:otobix/Controllers/service_history_controller.dart';
import 'package:otobix/Models/service_history_reports_model.dart';
import 'package:otobix/Utils/app_colors.dart';
import 'package:otobix/Utils/app_images.dart';
import 'package:otobix/Widgets/app_bar_widget.dart';
import 'package:otobix/Widgets/button_widget.dart';
import 'package:otobix/Widgets/empty_data_widget.dart';
import 'package:otobix/Widgets/shimmer_widget.dart';

class ServiceHistoryPage extends StatelessWidget {
  ServiceHistoryPage({super.key});

  final ServiceHistoryController serviceHistoryController = Get.put(
    ServiceHistoryController(),
  );

  // Simple colors to match the screenshot look
  static const Color _lightBlueBg = Color(0xFFEAF2FF);
  // static const Color _border = Color(0xFFCED7E6);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarWidget(title: 'Service History'),
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                _buildTopBanner(
                  context: context,
                  bannerPath: AppImages.serviceHistoryBanner,
                ),
                const SizedBox(height: 12),
                _buildRegistrationCard(),
                const SizedBox(height: 20),
                _buildSampleReportSection(),
                const SizedBox(height: 20),
                _buildReportsSection(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===== BANNER =====
  Widget _buildTopBanner({
    required BuildContext context,
    required String bannerPath,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        color: _lightBlueBg,
        child: Image.asset(
          bannerPath,
          width: MediaQuery.of(context).size.width,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildRegistrationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xff8fa4c1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: const TextSpan(
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              children: [
                TextSpan(
                  text: 'Enter Your ',
                  style: TextStyle(color: Colors.black87),
                ),
                TextSpan(
                  text: 'Car Registration Number*',
                  style: TextStyle(color: AppColors.red),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xffb8c6d8)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: serviceHistoryController.registrationController,
                    textCapitalization: TextCapitalization.characters,
                    style: const TextStyle(color: Colors.black87, fontSize: 13),
                    decoration: const InputDecoration(
                      isDense: true,
                      hintText: '(e.g. WB02ANXXXX)',
                      hintStyle: TextStyle(color: AppColors.grey, fontSize: 13),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 1,
                      ),
                      border: InputBorder.none,
                    ),
                    onChanged: (value) {
                      serviceHistoryController
                          .registrationController
                          .value = TextEditingValue(
                        text: value.toUpperCase(),
                        selection: TextSelection.collapsed(
                          offset: value.length,
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  child: const Icon(
                    CupertinoIcons.search,
                    color: Color(0xff1b3f78),
                    size: 22,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: ButtonWidget(
              text: 'Get Service History',
              isLoading: serviceHistoryController.isServiceHistoryLoading,
              onTap: serviceHistoryController.fetchServiceHistory,
              height: 34,
              width: 175,
              elevation: 2,
              borderRadius: 20,
              fontSize: 13,
              backgroundColor: AppColors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSampleReportSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Not sure what a Car Service History looks like ?',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xff143d79),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xffe4e7eb),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                padding: EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: const Color(0xffd0d8e4),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.receipt_long,
                  color: Color(0xff3d5f92),
                  size: 28,
                ),
                // child: SvgPicture.asset(
                //   AppIcons.deleteIcon,
                //   height: 20,
                //   width: 20,
                // ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'View A Sample Report',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xff143d79),
                        height: 1.1,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Before You Buy',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xff51657d),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 26,
                child: ButtonWidget(
                  text: 'VIEW',
                  isLoading:
                      serviceHistoryController.isSampleServiceHistoryPdfLoading,
                  onTap:
                      serviceHistoryController
                          .downloadAndOpenSampleServiceHistoryPdf,
                  width: 70,
                  fontSize: 11,
                  borderRadius: 4,
                  elevation: 1,
                  backgroundColor: const Color(0xff153d79),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReportsSection() {
    return Obx(() {
      final isLoading = serviceHistoryController.isServiceHistoryLoading.value;
      final hasLoaded = serviceHistoryController.hasLoadedReports.value;
      final reports = serviceHistoryController.serviceHistoryReportsList;

      if (!hasLoaded || (isLoading && reports.isEmpty)) {
        return _buildLoadingWidget();
      }

      if (reports.isEmpty) {
        return Column(
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: const Text(
                'Your Reports',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xff143d79),
                ),
              ),
            ),
            const SizedBox(height: 20),
            EmptyDataWidget(
              message: 'No reports available',
              icon: Icons.article_outlined,
            ),
          ],
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Reports',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xff143d79),
            ),
          ),
          const SizedBox(height: 8),
          ListView.separated(
            itemCount:
                serviceHistoryController.serviceHistoryReportsList.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final report =
                  serviceHistoryController.serviceHistoryReportsList[index];
              return _buildReportCard(report);
            },
          ),
        ],
      );
    });
  }

  Widget _buildReportCard(ServiceHistoryReportsModel report) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xff8fa4c1)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Column(
                children: [
                  Container(
                    width: 78,
                    height: 55,
                    decoration: BoxDecoration(
                      color: const Color(0xffeef2f7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      CupertinoIcons.car_detailed,
                      size: 40,
                      color: Color(0xff4a5e78),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    report.registrationNumber,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Color(0xff143d79),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${report.make} ${report.model}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Color(0xff143d79),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color:
                                report.status.toLowerCase() == 'completed'
                                    ? const Color(0xffd6ffd9)
                                    : AppColors.grey.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color:
                                  report.status.toLowerCase() == 'completed'
                                      ? const Color(0xff7ed58c)
                                      : AppColors.grey.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            report.status.toLowerCase() == 'completed'
                                ? 'GENERATED'
                                : 'PENDING',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color:
                                  report.status.toLowerCase() == 'completed'
                                      ? const Color(0xff1e9f39)
                                      : AppColors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Body Type - ${report.bodyType}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              'Year - ${report.registrationDate?.year}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 15),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Fuel Type - ${report.fuelType}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              'Ownership - ${serviceHistoryController.getOwnerSerialNumberString(ownerSerialNumber: report.ownerSerialNumber)}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Transaction ID',
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    report.paymentId,
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: Colors.black87,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: Colors.black87,
                      ),
                      children: [
                        const TextSpan(
                          text: 'Date - ',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        TextSpan(
                          text: serviceHistoryController.formatDateWithSuffix(
                            report.updatedAt,
                          ),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // const SizedBox(width: 10),
              Column(
                children: [
                  // ButtonWidget(
                  //   text: 'VIEW',
                  //   isLoading: false.obs,
                  //   onTap:
                  //       () => serviceHistoryController.onViewReport(
                  //         xlsxFileUrl: report.xlsxFileUrl,
                  //       ),
                  //   width: 60,
                  //   height: 26,
                  //   fontSize: 11,
                  //   borderRadius: 4,
                  //   elevation: 1,
                  //   backgroundColor: const Color(0xff153d79),
                  // ),
                  // const SizedBox(width: 6),
                  // ButtonWidget(
                  //   text: 'DOWNLOAD REPORT',
                  //   isLoading: false.obs,
                  //   onTap:
                  //       () => serviceHistoryController.onDownloadReport(
                  //         pdfFileUrl: report.otobixPdfReportUrl,
                  //       ),
                  //   height: 26,
                  //   width: 120,
                  //   fontSize: 10,
                  //   borderRadius: 4,
                  //   elevation: 1,
                  //   backgroundColor: const Color(0xff153d79),
                  // ),
                  _buildDownloadButton(
                    text: 'PDF Report',
                    isLoading: serviceHistoryController.isDownloadReportLoading,
                    isRequestCompletedAndFilesAreAvailable:
                        report.status.toLowerCase() == 'completed' &&
                                report.otobixPdfReportUrl.isNotEmpty
                            ? true
                            : false,
                    onTap:
                        () => serviceHistoryController.onDownloadReport(
                          pdfFileUrl: report.otobixPdfReportUrl,
                          paymentId: report.paymentId,
                        ),
                  ),
                  const SizedBox(height: 3),
                  _buildDownloadButton(
                    text: 'Service Details',
                    isLoading:
                        serviceHistoryController.isDownloadDetailsLoading,
                    isRequestCompletedAndFilesAreAvailable:
                        report.status.toLowerCase() == 'completed' &&
                                report.xlsxFileUrl.isNotEmpty
                            ? true
                            : false,
                    onTap:
                        () => serviceHistoryController.onDownloadDetails(
                          xlsxFileUrl: report.xlsxFileUrl,
                          paymentId: report.paymentId,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadButton({
    required String text,
    required RxBool isLoading,
    required bool isRequestCompletedAndFilesAreAvailable,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 30,
      width: 130,
      child: ElevatedButton(
        onPressed: isRequestCompletedAndFilesAreAvailable ? onTap : null,

        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          side: const BorderSide(color: Color(0xFFD9D9D9)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
          padding: const EdgeInsets.symmetric(horizontal: 10),
        ),
        child: Obx(() {
          if (isLoading.value) {
            return const SizedBox(
              width: 13,
              height: 13,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: AppColors.blue,
              ),
            );
          }
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.download_rounded,
                size: 15,
                color:
                    isRequestCompletedAndFilesAreAvailable
                        ? AppColors.blue
                        : AppColors.grey,
              ),
              const SizedBox(width: 5),
              Text(
                text,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  color:
                      isRequestCompletedAndFilesAreAvailable
                          ? AppColors.blue
                          : AppColors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  // Loading widget for service history reports
  Widget _buildLoadingWidget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your Reports',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Color(0xff143d79),
          ),
        ),
        const SizedBox(height: 8),
        ListView.separated(
          itemCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xff8fa4c1)),
              ),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        children: [
                          const ShimmerWidget(
                            height: 55,
                            width: 78,
                            borderRadius: 6,
                          ),
                          const SizedBox(height: 4),
                          const ShimmerWidget(
                            height: 10,
                            width: 70,
                            borderRadius: 4,
                          ),
                        ],
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Expanded(
                                  child: ShimmerWidget(
                                    height: 12,
                                    width: double.infinity,
                                    borderRadius: 4,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const ShimmerWidget(
                                  height: 20,
                                  width: 70,
                                  borderRadius: 20,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: const [
                                      ShimmerWidget(
                                        height: 10,
                                        width: 100,
                                        borderRadius: 4,
                                      ),
                                      SizedBox(height: 6),
                                      ShimmerWidget(
                                        height: 10,
                                        width: 80,
                                        borderRadius: 4,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: const [
                                      ShimmerWidget(
                                        height: 10,
                                        width: 95,
                                        borderRadius: 4,
                                      ),
                                      SizedBox(height: 6),
                                      ShimmerWidget(
                                        height: 10,
                                        width: 85,
                                        borderRadius: 4,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            ShimmerWidget(
                              height: 10,
                              width: 85,
                              borderRadius: 4,
                            ),
                            SizedBox(height: 6),
                            ShimmerWidget(
                              height: 10,
                              width: 120,
                              borderRadius: 4,
                            ),
                            SizedBox(height: 10),
                            ShimmerWidget(
                              height: 10,
                              width: 110,
                              borderRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        children: const [
                          ShimmerWidget(
                            height: 30,
                            width: 130,
                            borderRadius: 7,
                          ),
                          SizedBox(height: 6),
                          ShimmerWidget(
                            height: 30,
                            width: 130,
                            borderRadius: 7,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
