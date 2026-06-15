import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:otobix/Utils/app_colors.dart';
import 'package:otobix/Widgets/empty_page_widget.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:otobix/Controllers/terms_and_conditions_controller.dart';

class TermsAndConditionsPage extends StatelessWidget {
  const TermsAndConditionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final termsAndConditionsController = Get.put(
      TermsAndConditionsController(),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Terms & Conditions',
          style: TextStyle(fontSize: 16, color: AppColors.white),
        ),
        backgroundColor: AppColors.green,
        iconTheme: const IconThemeData(color: AppColors.white),
        // actions: [
        //   Obx(
        //     () => IconButton(
        //       icon: const Icon(Icons.refresh),
        //       onPressed:
        //           termsAndConditionsController.isLoading.value
        //               ? null
        //               : termsAndConditionsController.reload,
        //       tooltip: 'Reload',
        //     ),
        //   ),
        // ],
      ),

      body: Obx(() {
        if (termsAndConditionsController.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.green),
          );
        }
        if (termsAndConditionsController.error.value != null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  EmptyPageWidget(
                    icon: Icons.description,
                    iconColor: AppColors.red,
                    title: 'Terms & Conditions',
                    description: 'Error loading terms & conditions.',
                  ),
                  // Text(
                  //   termsAndConditionsController.error.value!,
                  //   textAlign: TextAlign.center,
                  // ),
                  // const SizedBox(height: 12),
                  // ElevatedButton(
                  //   onPressed: termsAndConditionsController.reload,
                  //   child: const Text('Retry'),
                  // ),
                ],
              ),
            ),
          );
        }
        return WebViewWidget(
          controller: termsAndConditionsController.webController,
        );
      }),
    );
  }
}
