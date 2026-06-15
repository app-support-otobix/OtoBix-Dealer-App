import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:otobix/Controllers/home_controller.dart';
import 'package:otobix/Controllers/purchased_cars_controller.dart';
import 'package:otobix/Views/Dealer%20Panel/car_details_page.dart';
import 'package:otobix/Widgets/car_deck_view_for_mybids_and_wishlist_widget.dart';
import 'package:otobix/Widgets/empty_data_widget.dart';
import 'package:otobix/Widgets/shimmer_widget.dart';

class PurchasedCarsPage extends StatelessWidget {
  PurchasedCarsPage({super.key});

  // Initialized in my cars page
  final PurchasedCarsController getxController =
      Get.find<PurchasedCarsController>();

  final HomeController homeController = Get.find<HomeController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Obx(() {
            if (getxController.isLoading.value) {
              return _buildLoadingWidget();
            } else if (getxController.carsList.isEmpty) {
              return Expanded(
                child: Center(
                  child: const EmptyDataWidget(
                    icon: Icons.directions_car_outlined,
                    message: 'No Cars Purchased Yet',
                  ),
                ),
              );
            } else {
              return _buildPurchasedCarsList();
            }
          }),
        ],
      ),
    );
  }

  // Purchased Cars List
  Widget _buildPurchasedCarsList() {
    return Expanded(
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: getxController.carsList.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        padding: const EdgeInsets.symmetric(horizontal: 15),
        itemBuilder: (context, index) {
          final car = getxController.carsList[index];

          return CarDeckViewForMyBidsAndWishlistWidget(
            car: car,
            footer: SizedBox(),
            onCarTap: () {
              Get.to(
                () => CarDetailsPage(
                  carId: car.id,
                  car: car,
                  currentOpenSection: homeController.defaultSectionScreen,
                  remainingAuctionTime: '00h : 00m : 00s'.obs,
                ),
              );
            },
            showAddToWishlistIcon: false,
            toggleFavorite: () {},
          );
        },
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Expanded(
      child: ListView.separated(
        itemCount: 3,
        separatorBuilder: (_, __) => const SizedBox(height: 15),
        padding: const EdgeInsets.symmetric(horizontal: 15),
        itemBuilder: (context, index) {
          return Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image shimmer
                const ShimmerWidget(height: 160, borderRadius: 12),

                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      // Title shimmer
                      ShimmerWidget(height: 14, width: 150),
                      SizedBox(height: 10),

                      // Bid row shimmer
                      ShimmerWidget(height: 12, width: 100),
                      SizedBox(height: 6),

                      // Year and KM
                      Row(
                        children: [
                          ShimmerWidget(height: 10, width: 60),
                          SizedBox(width: 10),
                          ShimmerWidget(height: 10, width: 80),
                        ],
                      ),
                      SizedBox(height: 6),

                      // Fuel and Location
                      Row(
                        children: [
                          ShimmerWidget(height: 10, width: 60),
                          SizedBox(width: 10),
                          ShimmerWidget(height: 10, width: 80),
                        ],
                      ),
                      SizedBox(height: 8),

                      // Inspection badge
                      ShimmerWidget(height: 10, width: 100),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
