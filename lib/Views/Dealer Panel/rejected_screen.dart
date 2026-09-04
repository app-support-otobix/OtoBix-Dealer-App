import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:otobix/Controllers/rejection_controller.dart';
import 'package:otobix/Utils/app_images.dart';
import 'package:otobix/Views/Login/login_page.dart';
import 'package:otobix/Widgets/app_bar_widget.dart';

class RejectedScreen extends StatefulWidget {
  final String userId;

  const RejectedScreen({super.key, required this.userId});

  @override
  State<RejectedScreen> createState() => _RejectedScreenState();
}

class _RejectedScreenState extends State<RejectedScreen> {
  final RejectionController rejectionController = Get.put(
    RejectionController(),
  );

  @override
  void initState() {
    super.initState();
    _fetchComment();
  }

  Future<void> _fetchComment() async {
    await rejectionController.fetchUserComment(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarWidget(
        title: 'Account Rejected',
        onBackPressed: () {
          Get.offAll(() => LoginPage());
        },
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Obx(() {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 100),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Lottie.asset(
                  AppImages.rejectedIcon,
                  height: 120,
                  repeat: true,
                  fit: BoxFit.contain,
                ),
              ),

              const SizedBox(height: 10),
              const Text(
                "Application Rejected",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),

              const SizedBox(height: 20),
              if (rejectionController.rejectionComment.value.isNotEmpty)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16, bottom: 5),
                    child: Text(
                      'Reason:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.redAccent, width: 1.2),
                  ),
                  child:
                      rejectionController.isLoading.value
                          ? const Center(child: CircularProgressIndicator())
                          : Text(
                            rejectionController
                                    .rejectionComment
                                    .value
                                    .isNotEmpty
                                ? rejectionController.rejectionComment.value
                                : "Your application has been rejected. Please contact support for more details.",
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                            textAlign: TextAlign.center,
                          ),
                ),
              ),

              const SizedBox(height: 150),

              const Text(
                "For assistance, contact us at:",
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
              const Text(
                "app.support@otobix.in",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 30),
            ],
          );
        }),
      ),
    );
  }
}
