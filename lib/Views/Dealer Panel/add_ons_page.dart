import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:otobix/Utils/app_colors.dart';
import 'package:otobix/Utils/app_images.dart';
import 'package:otobix/Views/Dealer%20Panel/service_history_page.dart';

class AddOnsPage extends StatelessWidget {
  const AddOnsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.topCenter,
                  child: Image.asset(
                    AppImages.addOnsHeaderImage,
                    height: 200,
                    width: double.infinity,
                    // fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 20),

                /// Header
                Text(
                  "Available Add-Ons",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.green,
                  ),
                ),
                const SizedBox(height: 10),

                /// Add-On Cards
                AddOnCard(
                  icon: Icons.receipt_long,
                  color: AppColors.blue,
                  title: "Service History",
                  description:
                      "View your car’s previous service and maintenance records in one place.",
                  onTap: () => Get.to(() => ServiceHistoryPage()),
                ),
                // AddOnCard(
                //   icon: Icons.verified,
                //   color: Colors.green,
                //   title: "Premium Inspection",
                //   description:
                //       "Get a detailed 200-point inspection report for peace of mind.",
                //   price: "999",
                // ),
                // AddOnCard(
                //   icon: Icons.security,
                //   color: Colors.red,
                //   title: "Extended Warranty",
                //   description:
                //       "Protect your car with 1 year extended warranty on engine & gearbox.",
                //   price: "2,999",
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AddOnCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String description;
  final VoidCallback onTap;
  // final String price;

  const AddOnCard({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
    required this.onTap,
    // required this.price,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 7),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              /// Colored Icon Container
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 28, color: color),
              ),
              const SizedBox(width: 16),

              /// Text Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      description,
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
              // const SizedBox(width: 3),
              // Text(
              //   'Rs. $price/-',
              //   style: TextStyle(
              //     fontSize: 14,
              //     fontWeight: FontWeight.bold,
              //     color: color,
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
