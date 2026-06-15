import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:otobix/Controllers/dealer_guide_controller.dart';
import 'package:otobix/Utils/app_colors.dart';
import 'package:otobix/Widgets/empty_page_widget.dart';
import 'package:webview_flutter/webview_flutter.dart';

class DealerGuidePage extends StatelessWidget {
  const DealerGuidePage({super.key});

  @override
  Widget build(BuildContext context) {
    final dealerGuideController = Get.put(DealerGuideController());

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Dealer Guide',
          style: TextStyle(fontSize: 16, color: AppColors.white),
        ),
        backgroundColor: AppColors.green,
        iconTheme: const IconThemeData(color: AppColors.white),
        // actions: [
        //   Obx(
        //     () => IconButton(
        //       icon: const Icon(Icons.refresh),
        //       onPressed:
        //           dealerGuideController.isLoading.value
        //               ? null
        //               : dealerGuideController.reload,
        //       tooltip: 'Reload',
        //     ),
        //   ),
        // ],
      ),

      body: Obx(() {
        if (dealerGuideController.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.green),
          );
        }
        if (dealerGuideController.error.value != null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  EmptyPageWidget(
                    icon: Icons.menu_book,
                    iconColor: AppColors.red,
                    title: 'Dealer Guide',
                    description: 'Error loading dealer guide.',
                  ),
                  // Text(
                  //   dealerGuideController.error.value!,
                  //   textAlign: TextAlign.center,
                  // ),
                  // const SizedBox(height: 12),
                  // ElevatedButton(
                  //   onPressed: dealerGuideController.reload,
                  //   child: const Text('Retry'),
                  // ),
                ],
              ),
            ),
          );
        }
        return WebViewWidget(controller: dealerGuideController.webController);
      }),
    );
  }
}
