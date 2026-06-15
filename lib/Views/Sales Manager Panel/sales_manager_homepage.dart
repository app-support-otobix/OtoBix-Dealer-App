import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:otobix/Utils/app_colors.dart';

class SalesManagerHomepage extends StatelessWidget {
  const SalesManagerHomepage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 2,
        automaticallyImplyLeading: false,
        title: const Text(
          'Welcome Sales Manager',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: AppColors.black,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: AppColors.green),
            onPressed: () {},
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats Summary
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatCard("Total Auctions", "23", FontAwesomeIcons.gavel),
                _buildStatCard("Bids Today", "58", FontAwesomeIcons.handPaper),
                _buildStatCard("Dealers", "12", FontAwesomeIcons.users),
              ],
            ),

            const SizedBox(height: 20),

            // Today's Activity
            const Text(
              'Today\'s Activity',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            _buildActivityCard(),

            const SizedBox(height: 20),

            // Active Dealers
            const Text(
              'Active Dealers',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: 4,
                itemBuilder: (_, index) => _buildDealerCard(index),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String count, IconData icon) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.green, size: 18),
            const SizedBox(height: 6),
            Text(
              count,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 10, color: AppColors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Row(
        children: [
          const Icon(
            FontAwesomeIcons.clipboardList,
            size: 20,
            color: AppColors.green,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              "3 new car listings need approval.\n2 dealer requests pending.",
              style: TextStyle(fontSize: 12, height: 1.3),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios, size: 14),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildDealerCard(int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.green.withOpacity(0.2),
            child: const Icon(Icons.person, color: AppColors.green),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Ali Motors",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                SizedBox(height: 4),
                Text(
                  "Active • 4 listings",
                  style: TextStyle(fontSize: 10, color: AppColors.grey),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, size: 16),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
