import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:otobix/Controllers/home_controller.dart';
import 'package:otobix/Controllers/wishlist_controller.dart';
import 'package:otobix/Views/Dealer%20Panel/car_details_page.dart';
import 'package:otobix/Widgets/car_deck_view_for_mybids_and_wishlist_widget.dart';
import 'package:otobix/Widgets/empty_data_widget.dart';
import 'package:otobix/Widgets/shimmer_widget.dart';

class WishlistPage extends StatelessWidget {
  WishlistPage({super.key});

  // Initialized in my cars page
  final WishlistController getxController = Get.find<WishlistController>();

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
                    icon: Icons.favorite_border,
                    message: 'No Cars in Wishlist',
                  ),
                ),
              );
            } else {
              return _buildWishlistList();
            }
          }),
        ],
      ),
    );
  }

  // Wishlist List

  Widget _buildWishlistList() {
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
            toggleFavorite: () => getxController.toggleFavoriteById(car.id),
          );
        },
      ),
    );
  }

  // Widget _buildWishlistList1() {
  //   return Expanded(
  //     child: ListView.separated(
  //       shrinkWrap: true,
  //       itemCount: getxController.carsList.length,
  //       separatorBuilder: (_, __) => const SizedBox(height: 10),
  //       padding: const EdgeInsets.symmetric(horizontal: 15),
  //       itemBuilder: (context, index) {
  //         final car = getxController.carsList[index];
  //         final String yearofManufacture =
  //             '${GlobalFunctions.getFormattedDate(date: car.yearMonthOfManufacture, type: GlobalFunctions.year)} ';
  //         // InkWell for car card
  //         return GestureDetector(
  //           onTap: () {
  //             // Get.to(
  //             //   () =>
  //             //       CarDetailsPage(carId: car.id!, car: car, type: 'wishlist'),
  //             // );
  //           },
  //           child: Card(
  //             elevation: 4,
  //             color: AppColors.white,
  //             shape: RoundedRectangleBorder(
  //               borderRadius: BorderRadius.circular(12),
  //             ),
  //             child: Stack(
  //               children: [
  //                 Padding(
  //                   padding: const EdgeInsets.all(12.0),
  //                   child: Column(
  //                     children: [
  //                       Row(
  //                         children: [
  //                           // Car details
  //                           Expanded(
  //                             child: Column(
  //                               crossAxisAlignment: CrossAxisAlignment.start,
  //                               children: [
  //                                 Row(
  //                                   children: [
  //                                     // Car Image
  //                                     ClipRRect(
  //                                       borderRadius: BorderRadius.circular(8),
  //                                       child: CachedNetworkImage(
  //                                         imageUrl: car.imageUrl,
  //                                         width: 120,
  //                                         height: 80,
  //                                         fit: BoxFit.cover,
  //                                         placeholder:
  //                                             (context, url) => Container(
  //                                               height: 80,
  //                                               width: 120,
  //                                               color: AppColors.grey
  //                                                   .withValues(alpha: .3),
  //                                               child: const Center(
  //                                                 child: SizedBox(
  //                                                   height: 20,
  //                                                   width: 20,
  //                                                   child:
  //                                                       CircularProgressIndicator(
  //                                                         color:
  //                                                             AppColors.green,
  //                                                         strokeWidth: 2,
  //                                                       ),
  //                                                 ),
  //                                               ),
  //                                             ),
  //                                         errorWidget: (
  //                                           context,
  //                                           error,
  //                                           stackTrace,
  //                                         ) {
  //                                           return Image.asset(
  //                                             AppImages.carAlternateImage,
  //                                             width: 120,
  //                                             height: 80,
  //                                             fit: BoxFit.cover,
  //                                           );
  //                                         },
  //                                       ),
  //                                     ),
  //                                     SizedBox(width: 10),
  //                                     Flexible(
  //                                       child: Column(
  //                                         crossAxisAlignment:
  //                                             CrossAxisAlignment.start,
  //                                         children: [
  //                                           Text(
  //                                             '$yearofManufacture${car.make} ${car.model} ${car.variant}',
  //                                             maxLines: 3,
  //                                             overflow: TextOverflow.ellipsis,
  //                                             style: const TextStyle(
  //                                               fontSize: 15,
  //                                               fontWeight: FontWeight.bold,
  //                                             ),
  //                                           ),
  //                                           // Row(
  //                                           //   children: [
  //                                           //     Text(
  //                                           //       'OCP: ',
  //                                           //       maxLines: 1,
  //                                           //       overflow:
  //                                           //           TextOverflow.ellipsis,
  //                                           //       style: const TextStyle(
  //                                           //         fontSize: 14,
  //                                           //         fontWeight: FontWeight.bold,
  //                                           //       ),
  //                                           //     ),
  //                                           //     Text(
  //                                           //       'Rs. ${NumberFormat.decimalPattern('en_IN').format(car.oneClickPrice)}/-',
  //                                           //       maxLines: 1,
  //                                           //       overflow:
  //                                           //           TextOverflow.ellipsis,
  //                                           //       style: const TextStyle(
  //                                           //         fontSize: 14,
  //                                           //         color: AppColors.green,
  //                                           //         fontWeight: FontWeight.bold,
  //                                           //       ),
  //                                           //     ),
  //                                           //   ],
  //                                           // ),
  //                                         ],
  //                                       ),
  //                                     ),
  //                                   ],
  //                                 ),
  //                                 const SizedBox(height: 5),

  //                                 const Divider(),
  //                                 const SizedBox(height: 5),

  //                                 Row(
  //                                   mainAxisAlignment:
  //                                       MainAxisAlignment.spaceEvenly,
  //                                   children: [
  //                                     Column(
  //                                       crossAxisAlignment:
  //                                           CrossAxisAlignment.start,
  //                                       children: [
  //                                         _buildIconAndTextWidget(
  //                                           icon: Icons.calendar_today,
  //                                           text:
  //                                               GlobalFunctions.getFormattedDate(
  //                                                 date:
  //                                                     car.yearMonthOfManufacture,
  //                                                 type:
  //                                                     GlobalFunctions.monthYear,
  //                                               ) ??
  //                                               'N/A',
  //                                         ),

  //                                         _buildIconAndTextWidget(
  //                                           icon: Icons.local_gas_station,
  //                                           text: car.fuelType,
  //                                         ),
  //                                       ],
  //                                     ),

  //                                     Column(
  //                                       crossAxisAlignment:
  //                                           CrossAxisAlignment.start,
  //                                       children: [
  //                                         _buildIconAndTextWidget(
  //                                           icon: Icons.speed,
  //                                           text:
  //                                               '${NumberFormat.decimalPattern('en_IN').format(car.odometerReadingInKms)} km',
  //                                         ),

  //                                         _buildIconAndTextWidget(
  //                                           icon: Icons.location_on,
  //                                           text: car.inspectionLocation,
  //                                         ),
  //                                       ],
  //                                     ),

  //                                     Column(
  //                                       crossAxisAlignment:
  //                                           CrossAxisAlignment.start,
  //                                       children: [
  //                                         _buildIconAndTextWidget(
  //                                           icon: Icons.receipt_long,
  //                                           text:
  //                                               car.roadTaxValidity == 'LTT' ||
  //                                                       car.roadTaxValidity ==
  //                                                           'OTT'
  //                                                   ? car.roadTaxValidity
  //                                                   : GlobalFunctions.getFormattedDate(
  //                                                         date:
  //                                                             car.taxValidTill,
  //                                                         type:
  //                                                             GlobalFunctions
  //                                                                 .monthYear,
  //                                                       ) ??
  //                                                       'N/A',
  //                                         ),
  //                                         _buildIconAndTextWidget(
  //                                           icon: Icons.person,
  //                                           text:
  //                                               car.ownerSerialNumber == 1
  //                                                   ? 'First Owner'
  //                                                   : '${car.ownerSerialNumber} Owners',
  //                                         ),
  //                                       ],
  //                                     ),
  //                                   ],
  //                                 ),
  //                               ],
  //                             ),
  //                           ),
  //                         ],
  //                       ),
  //                       const SizedBox(height: 5),
  //                     ],
  //                   ),
  //                 ),

  //                 Positioned(
  //                   top: 10,
  //                   right: 10,
  //                   child: Obx(() {
  //                     final isFav = getxController.isFav(car.id!);
  //                     return InkWell(
  //                       onTap: () => getxController.toggleFavoriteById(car.id!),
  //                       borderRadius: BorderRadius.circular(20),
  //                       child: Container(
  //                         padding: const EdgeInsets.all(6),
  //                         decoration: BoxDecoration(
  //                           color: AppColors.white.withValues(alpha: .8),
  //                           shape: BoxShape.circle,
  //                           boxShadow: const [
  //                             BoxShadow(color: Colors.black12, blurRadius: 4),
  //                           ],
  //                         ),
  //                         child: Icon(
  //                           isFav ? Icons.favorite : Icons.favorite_outline,
  //                           color: isFav ? AppColors.red : AppColors.grey,
  //                           size: 20,
  //                         ),
  //                       ),
  //                     );
  //                   }),
  //                 ),
  //               ],
  //             ),
  //           ),
  //         );
  //       },
  //     ),
  //   );
  // }

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

  // // Icon and text widget
  // Widget _buildIconAndTextWidget({
  //   required IconData icon,
  //   required String text,
  // }) {
  //   return Row(
  //     children: [
  //       Icon(icon, size: 14, color: AppColors.grey),
  //       const SizedBox(width: 5),
  //       Text(text, style: const TextStyle(fontSize: 12)),
  //     ],
  //   );
  // }
}
