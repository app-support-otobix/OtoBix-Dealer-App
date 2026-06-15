import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:otobix/Models/user_model.dart';
import 'package:otobix/Utils/app_animations.dart';
import 'package:otobix/Utils/app_colors.dart';
import 'package:otobix/Utils/app_constants.dart';
import 'package:otobix/helpers/shared_prefs_helper.dart';

class WaitingForApprovalPage extends StatefulWidget {
  final List<String> documents;
  final String userRole;

  const WaitingForApprovalPage({
    super.key,
    required this.documents,
    required this.userRole,
  });

  @override
  State<WaitingForApprovalPage> createState() => _WaitingForApprovalPageState();
}

class _WaitingForApprovalPageState extends State<WaitingForApprovalPage> {
  @override
  initState() {
    super.initState();
  }

  Future<void> deletetoken() async {
    await SharedPrefsHelper.remove('token');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text('Approval Status'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.white,
        elevation: 4,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 30),

            // Illustration
            // Icon(Icons.hourglass_empty, size: 50, color: AppColors.green),
            Lottie.asset(AppAnimations.waitingAnimation, height: 100),
            const SizedBox(height: 20),

            // Main Title
            Text(
              'Waiting for Approval',
              // _buildTitleForRole(widget.userRole),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.green,
              ),
            ),

            const SizedBox(height: 10),
            // Subtitle
            _buildSubtitleForRole(widget.userRole),

            const SizedBox(height: 30),

            // Documents List
            if (widget.userRole == AppConstants.roles.dealer)
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.documents.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final doc = widget.documents[index];
                  return _buildDocumentCard(doc);
                },
              ),

            const SizedBox(height: 20),

            const Text(
              "For assistance, contact us at:",
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const Text(
              "support@otobix.com",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentCard(String docName) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
      child: Row(
        children: [
          Icon(Icons.description, color: AppColors.green, size: 30),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              docName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // String _buildTitleForRole(String role) {
  //   switch (role.toLowerCase()) {
  //     case UserModel.customer:
  //       return 'Customer Approval Pending';
  //     case UserModel.salesManager:
  //       return 'Sales Manager Review';
  //     case UserModel.dealer:
  //       return 'Waiting for Approval';
  //     default:
  //       return 'Waiting for Approval';
  //   }
  // }

  Widget _buildSubtitleForRole(String role) {
    switch (role.toLowerCase()) {
      // case AppConstants.roles.customer:
      case var s
          when s.toLowerCase() == AppConstants.roles.customer.toLowerCase():
        return const Text(
          'Thank you for registering. Your account is being reviewed. You will receive an email once approved.',
          style: TextStyle(fontSize: 13, color: Colors.black87, height: 1.4),
          textAlign: TextAlign.center,
        );

      // case AppConstants.roles.salesManager:
      case var s
          when s.toLowerCase() == AppConstants.roles.salesManager.toLowerCase():
        return const Text(
          'Your registration is under review. Please wait while the admin verifies your information.',
          style: TextStyle(fontSize: 13, color: Colors.black87, height: 1.4),
          textAlign: TextAlign.center,
        );
      // case AppConstants.roles.dealer:
      case var s
          when s.toLowerCase() == AppConstants.roles.dealer.toLowerCase():
        return RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text:
                    'Your account is currently under review. '
                    'Please check your email for details to pay the required security deposit. '
                    'After completing the payment, ',
                style: TextStyle(fontSize: 13, color: Colors.black87),
              ),
              TextSpan(
                text:
                    'kindly submit the following documents along with your payment receipt for verification.',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
            style: TextStyle(fontSize: 12, color: Colors.black87, height: 1.3),
          ),

          textAlign: TextAlign.center,
        );
      default:
        return const Text(
          'Your account is currently under review. '
          'Please check again after some time.',
          style: TextStyle(fontSize: 13, color: Colors.black87, height: 1.4),
          textAlign: TextAlign.center,
        );
    }
  }
}
