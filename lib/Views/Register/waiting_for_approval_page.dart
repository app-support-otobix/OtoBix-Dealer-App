import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:otobix/Network/api_service.dart';
import 'package:otobix/Utils/app_animations.dart';
import 'package:otobix/Utils/app_colors.dart';
import 'package:otobix/Utils/app_urls.dart';
import 'package:otobix/Views/Login/login_page.dart';
import 'package:otobix/Widgets/app_bar_widget.dart';

class WaitingForApprovalPage extends StatefulWidget {
  final String entityType;
  const WaitingForApprovalPage({super.key, required this.entityType});

  @override
  State<WaitingForApprovalPage> createState() => _WaitingForApprovalPageState();
}

class _WaitingForApprovalPageState extends State<WaitingForApprovalPage> {
  List<String> documents = [];

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  // Load documents
  Future<void> _loadDocuments() async {
    final fetchedDocuments = await _fetchEntityDocuments(
      entityType: widget.entityType,
    );

    if (!mounted) return;

    setState(() {
      documents = fetchedDocuments;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBarWidget(
        title: 'Approval Status',
        onBackPressed: () {
          Get.offAll(() => LoginPage());
        },
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

            // Title
            Text(
              'Waiting for Approval',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.green,
              ),
            ),
            const SizedBox(height: 10),

            // Subtitle
            _buildSubtitle(),
            const SizedBox(height: 30),

            // Documents List
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: documents.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final doc = documents[index];
                return _buildDocumentCard(doc);
              },
            ),
            const SizedBox(height: 20),

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
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// Builds a document card widget
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

  // Subtitle
  Widget _buildSubtitle() {
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
  }

  // Fetch entity documents
  Future<List<String>> _fetchEntityDocuments({
    required String entityType,
  }) async {
    final fallback = <String>['No documents found'];

    if (entityType.isEmpty) return fallback;

    try {
      final response = await ApiService.get(
        endpoint: AppUrls.getEntityDocumentsByName(
          entityName: entityType.trim(),
        ),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final data = (json['data'] ?? {}) as Map<String, dynamic>;
        final docs = (data['documents'] ?? []) as List;
        return docs.map((e) => '$e').toList();
      }
    } catch (error) {
      // ignore and use fallback
      debugPrint("Error: $error");
    }
    return fallback;
  }
}
