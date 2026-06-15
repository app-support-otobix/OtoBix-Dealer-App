import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:otobix/Controllers/privacy_policy_controller.dart';
import 'package:otobix/Utils/app_colors.dart';
import 'package:otobix/Widgets/empty_page_widget.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final privacyPolicyController = Get.put(PrivacyPolicyController());

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Privacy Policy',
          style: TextStyle(fontSize: 16, color: AppColors.white),
        ),
        backgroundColor: AppColors.green,
        iconTheme: const IconThemeData(color: AppColors.white),
        // actions: [
        //   Obx(
        //     () => IconButton(
        //       icon: const Icon(Icons.refresh),
        //       onPressed:
        //           privacyPolicyController.isLoading.value
        //               ? null
        //               : privacyPolicyController.reload,
        //       tooltip: 'Reload',
        //     ),
        //   ),
        // ],
      ),

      body: Obx(() {
        if (privacyPolicyController.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.green),
          );
        }
        if (privacyPolicyController.error.value != null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  EmptyPageWidget(
                    icon: Icons.lock,
                    iconColor: AppColors.red,
                    title: 'Privacy Policy',
                    description: 'Error loading privacy policy.',
                  ),
                  // Text(
                  //   privacyPolicyController.error.value!,
                  //   textAlign: TextAlign.center,
                  // ),
                  // const SizedBox(height: 12),
                  // ElevatedButton(
                  //   onPressed: privacyPolicyController.reload,
                  //   child: const Text('Retry'),
                  // ),
                ],
              ),
            ),
          );
        }
        return WebViewWidget(controller: privacyPolicyController.webController);
      }),
    );
  }
}
