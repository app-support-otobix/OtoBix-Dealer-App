import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:otobix/Controllers/my_bids_controller.dart';
import 'package:otobix/Utils/app_colors.dart';
import 'package:otobix/Utils/global_functions.dart';
import 'package:otobix/Widgets/car_deck_view_for_mybids_and_wishlist_widget.dart';
import 'package:otobix/Widgets/empty_data_widget.dart';
import 'package:otobix/Widgets/shimmer_widget.dart';
import 'package:otobix/Widgets/toast_widget.dart';

class MyBidsPage extends StatelessWidget {
  MyBidsPage({super.key});

  // Initialized in my cars page
  final MyBidsController getxController = Get.find<MyBidsController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Obx(() {
            if (getxController.isLoading.value) {
              return _buildLoadingWidget();
            } else if (getxController.myBidCarsList.isEmpty) {
              return Expanded(
                child: Center(
                  child: const EmptyDataWidget(
                    icon: Icons.gavel,
                    message: 'No Bids Yet',
                  ),
                ),
              );
            } else {
              return _buildMyBidsList();
            }
          }),
        ],
      ),
    );
  }

  Widget _buildMyBidsList() {
    return Expanded(
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: getxController.myBidCarsList.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        padding: const EdgeInsets.symmetric(horizontal: 15),
        itemBuilder: (context, index) {
          final car = getxController.myBidCarsList[index];

          return CarDeckViewForMyBidsAndWishlistWidget(
            car: car,
            footer: SizedBox(),
            onCarTap:
                () => _buildPreviousBidsSheet(context, car.id!, getxController),
            showAddToWishlistIcon: false,
            toggleFavorite: () {},
          );
        },
      ),
    );
  }

  // My Bids List
  // Widget _buildMyBidsList1() {
  //   return Expanded(
  //     child: ListView.separated(
  //       shrinkWrap: true,
  //       itemCount: getxController.myBidCarsList.length,
  //       separatorBuilder: (_, __) => const SizedBox(height: 10),
  //       padding: const EdgeInsets.symmetric(horizontal: 15),
  //       itemBuilder: (context, index) {
  //         final car = getxController.myBidCarsList[index];
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

  //                 // Positioned(
  //                 //   top: 10,
  //                 //   right: 10,
  //                 //   child: Obx(() {
  //                 //     final isFav = getxController.isFav(car.id!);
  //                 //     return InkWell(
  //                 //       onTap: () => getxController.toggleFavoriteById(car.id!),
  //                 //       borderRadius: BorderRadius.circular(20),
  //                 //       child: Container(
  //                 //         padding: const EdgeInsets.all(6),
  //                 //         decoration: BoxDecoration(
  //                 //           color: AppColors.white.withValues(alpha: .8),
  //                 //           shape: BoxShape.circle,
  //                 //           boxShadow: const [
  //                 //             BoxShadow(color: Colors.black12, blurRadius: 4),
  //                 //           ],
  //                 //         ),
  //                 //         child: Icon(
  //                 //           isFav ? Icons.favorite : Icons.favorite_outline,
  //                 //           color: isFav ? AppColors.red : AppColors.grey,
  //                 //           size: 20,
  //                 //         ),
  //                 //       ),
  //                 //     );
  //                 //   }),
  //                 // ),
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

  // Icon and text widget
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

  // Build previous bids sheet
  Future<void> _buildPreviousBidsSheet(
    BuildContext context,
    String carId,
    MyBidsController getxController,
  ) async {
    // Show loader while fetching
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => const Center(
            child: CircularProgressIndicator(color: AppColors.green),
          ),
    );

    // final data = await getxController.getUserBidsForCar(carId);
    // Navigator.pop(context); // close loader

    final resp = await getxController.getUserBidsForCar(carId);
    Navigator.pop(context);

    final String? auctionStatus = resp['auctionStatus'] as String?;
    final num? highestBid = resp['highestBid'] as num?;
    final String? highestBidColor = resp['highestBidColor'] as String?;
    final List<Map<String, dynamic>> bids =
        (resp['bids'] as List).cast<Map<String, dynamic>>();

    if (bids.isEmpty) {
      ToastWidget.show(
        context: Get.context!,
        title: 'No Bids',
        subtitle: 'You haven’t placed any bids on this car yet.',
        type: ToastType.error,
      );
      return;
    }

    // If your API returns both car info + bids, you can unpack them:
    // final carInfo =
    //     data.firstWhere(
    //       (e) => e.containsKey('carInfo'),
    //       orElse: () => {'carInfo': null},
    //     )['carInfo'];

    // final bids =
    //     carInfo == null
    //         ? data
    //         : data.where((e) => e.containsKey('bidAmount')).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Container(
                    height: 5,
                    width: 60,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // === Car Header (Optional) ===
                  // if (carInfo != null)
                  //   Padding(
                  //     padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  //     child: Row(
                  //       children: [
                  //         ClipRRect(
                  //           borderRadius: BorderRadius.circular(10),
                  //           child: Image.network(
                  //             carInfo['imageUrl'] ?? '',
                  //             height: 60,
                  //             width: 90,
                  //             fit: BoxFit.cover,
                  //             errorBuilder:
                  //                 (_, __, ___) => Container(
                  //                   height: 60,
                  //                   width: 90,
                  //                   color: Colors.grey.shade200,
                  //                   child: const Icon(
                  //                     Icons.directions_car,
                  //                     color: Colors.grey,
                  //                   ),
                  //                 ),
                  //           ),
                  //         ),
                  //         const SizedBox(width: 12),
                  //         Expanded(
                  //           child: Column(
                  //             crossAxisAlignment: CrossAxisAlignment.start,
                  //             children: [
                  //               Text(
                  //                 carInfo['name'] ?? '',
                  //                 style: const TextStyle(
                  //                   fontSize: 16,
                  //                   fontWeight: FontWeight.bold,
                  //                 ),
                  //               ),
                  //               const SizedBox(height: 4),
                  //               Text(
                  //                 "FMV/PD: ₹${NumberFormat('#,##,###').format(carInfo['priceDiscovery'] ?? 0)}",
                  //                 style: TextStyle(
                  //                   fontSize: 13,
                  //                   color: AppColors.grey,
                  //                 ),
                  //               ),
                  //             ],
                  //           ),
                  //         ),
                  //       ],
                  //     ),
                  //   ),

                  // if (carInfo != null) const Divider(height: 25),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      if (auctionStatus != null)
                        _buildSheetTopContainer(
                          label: 'Auction Status',
                          value: auctionStatus,
                          color: getxController.auctionStatusColor(
                            auctionStatus,
                          ),
                        ),
                      if (highestBid != null)
                        _buildSheetTopContainer(
                          label: 'Highest Bid',
                          value:
                              'Rs. ${NumberFormat.decimalPattern('en_IN').format(GlobalFunctions.roundToNearestThousand<int>(highestBid))}/-',
                          color:
                              highestBidColor == 'green'
                                  ? AppColors.green
                                  : AppColors.red,
                        ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 15),
                      child: const Text(
                        "Your Previous Bids",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const Divider(),

                  // === Bid List ===
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: bids.length,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      itemBuilder: (_, index) {
                        final bid = bids[index];
                        final bidAmount = bid['bidAmount'] ?? 0;
                        final time = DateTime.tryParse(bid['time'] ?? '');
                        final formattedTime =
                            time != null
                                ? DateFormat(
                                  'dd MMM yyyy, hh:mm a',
                                ).format(time.toLocal())
                                : 'Unknown time';

                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.symmetric(
                            vertical: 6,
                            horizontal: 5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ListTile(
                            leading: const Icon(
                              // Icons.currency_rupee,
                              Icons.gavel,
                              color: AppColors.green,
                            ),
                            title: Text(
                              'Rs. ${NumberFormat.decimalPattern('en_IN').format(GlobalFunctions.roundToNearestThousand<int>(bidAmount))}/-',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              'Placed on: $formattedTime',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Sheet top container
  Widget _buildSheetTopContainer({
    required String label,
    required String value,
    required Color color,
  }) {
    final card = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 10),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.grey,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );

    return Flexible(
      fit: FlexFit.loose, // allows shrinking when space is tight
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 100, maxWidth: 150),
        child: SizedBox(
          width: 150, // preferred/initial width when space allows
          child: card,
        ),
      ),
    );
  }
}
