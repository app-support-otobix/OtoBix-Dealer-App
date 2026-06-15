import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:otobix/Controllers/home_controller.dart';
import 'package:otobix/Widgets/empty_page_widget.dart';

class OcbNegoPage extends StatelessWidget {
  OcbNegoPage({super.key});

  // final HomeController getxController = Get.put(HomeController());
  final HomeController getxController = Get.find<HomeController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            children: [
              EmptyPageWidget(
                icon: Icons.handshake_outlined,
                title: 'No Ocb Nego',
                description: 'You have no ocb nego yet.',
              ),
              // Obx(() {
              //   if (getxController.isLoading.value) {
              //     return _buildLoadingWidget();
              //   } else if (getxController.carsList.isEmpty) {
              //     return const EmptyDataWidget(
              //       icon: Icons.gavel,
              //       message: 'No Live Bids',
              //     );
              //   } else {
              //     return _buildOcbNegoList();
              //   }
              // }),
            ],
          ),
        ),
      ),
    );
  }

  // Live Bids List
  // Widget _buildOcbNegoList() {
  //   return Padding(
  //     padding: const EdgeInsets.symmetric(horizontal: 15),
  //     child: ListView.separated(
  //       shrinkWrap: true,
  //       itemCount: getxController.carsList.length - 8,
  //       separatorBuilder: (_, __) => const SizedBox(height: 16),
  //       itemBuilder: (context, index) {
  //         final car = getxController.carsList.reversed.toList()[index];
  //         // InkWell for car card
  //         return InkWell(
  //           onTap: () {
  //             Get.to(
  //               () => CarDetailsPage(
  //                 carId: car.id,
  //                 car: car,
  //                 currentOpenSection: 'ocb_nego',
  //               ),
  //             );
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
  //                           // Car Image
  //                           ClipRRect(
  //                             borderRadius: BorderRadius.circular(8),
  //                             child: CachedNetworkImage(
  //                               imageUrl: car.imageUrl,
  //                               width: 120,
  //                               height: 80,
  //                               fit: BoxFit.cover,
  //                               placeholder:
  //                                   (context, url) => Container(
  //                                     height: 80,
  //                                     width: 120,
  //                                     color: AppColors.grey.withValues(
  //                                       alpha: .3,
  //                                     ),
  //                                     child: const Center(
  //                                       child: SizedBox(
  //                                         height: 20,
  //                                         width: 20,
  //                                         child: CircularProgressIndicator(
  //                                           color: AppColors.green,
  //                                           strokeWidth: 2,
  //                                         ),
  //                                       ),
  //                                     ),
  //                                   ),
  //                               errorWidget: (context, error, stackTrace) {
  //                                 return Image.asset(
  //                                   AppImages.carAlternateImage,
  //                                   width: 120,
  //                                   height: 80,
  //                                   fit: BoxFit.cover,
  //                                 );
  //                               },
  //                             ),
  //                           ),
  //                           const SizedBox(width: 12),

  //                           // Car details
  //                           Expanded(
  //                             child: Column(
  //                               crossAxisAlignment: CrossAxisAlignment.start,
  //                               children: [
  //                                 Text(
  //                                   '${car.make} ${car.model} ${car.variant}',
  //                                   style: const TextStyle(
  //                                     fontSize: 16,
  //                                     fontWeight: FontWeight.bold,
  //                                   ),
  //                                 ),
  //                                 const SizedBox(height: 4),
  //                                 Text(
  //                                   'Rs. ${NumberFormat.decimalPattern('en_IN').format(car.priceDiscovery)}/-',

  //                                   style: const TextStyle(
  //                                     fontSize: 14,
  //                                     color: AppColors.green,
  //                                     fontWeight: FontWeight.bold,
  //                                   ),
  //                                 ),
  //                                 const SizedBox(height: 4),
  //                                 Row(
  //                                   children: [
  //                                     Icon(
  //                                       Icons.calendar_today,
  //                                       size: 14,
  //                                       color: Colors.grey,
  //                                     ),
  //                                     const SizedBox(width: 4),
  //                                     Text(
  //                                       GlobalFunctions.getFormattedDate(
  //                                             date: car.yearMonthOfManufacture,
  //                                             type: GlobalFunctions.monthYear,
  //                                           ) ??
  //                                           'N/A',
  //                                       style: const TextStyle(fontSize: 12),
  //                                     ),
  //                                     const SizedBox(width: 10),
  //                                     Icon(
  //                                       Icons.speed,
  //                                       size: 14,
  //                                       color: Colors.grey,
  //                                     ),
  //                                     const SizedBox(width: 4),
  //                                     Text(
  //                                       '${NumberFormat.decimalPattern('en_IN').format(car.odometerReadingInKms)} km',
  //                                       style: const TextStyle(fontSize: 12),
  //                                     ),
  //                                   ],
  //                                 ),
  //                                 const SizedBox(height: 4),
  //                                 Row(
  //                                   children: [
  //                                     Icon(
  //                                       Icons.local_gas_station,
  //                                       size: 14,
  //                                       color: Colors.grey,
  //                                     ),
  //                                     const SizedBox(width: 4),
  //                                     Text(
  //                                       car.fuelType,
  //                                       style: const TextStyle(fontSize: 12),
  //                                     ),
  //                                     const SizedBox(width: 10),
  //                                     Icon(
  //                                       Icons.location_on,
  //                                       size: 14,
  //                                       color: Colors.grey,
  //                                     ),
  //                                     const SizedBox(width: 4),
  //                                     Text(
  //                                       car.inspectionLocation,
  //                                       style: const TextStyle(fontSize: 12),
  //                                     ),
  //                                   ],
  //                                 ),
  //                               ],
  //                             ),
  //                           ),

  //                           // // Watchlist button
  //                           // Row(
  //                           //   crossAxisAlignment: CrossAxisAlignment.start,
  //                           //   children: [
  //                           //     Padding(
  //                           //       padding: const EdgeInsets.only(right: 10),
  //                           //       child: InkWell(
  //                           //         onTap: () {},
  //                           //         child: const Icon(
  //                           //           Icons.favorite_outline,
  //                           //           color: AppColors.gray,
  //                           //           size: 22,
  //                           //         ),
  //                           //       ),
  //                           //     ),
  //                           //   ],
  //                           // ),
  //                         ],
  //                       ),
  //                       const SizedBox(height: 5),
  //                       car.isInspected == true
  //                           ? Column(
  //                             children: [
  //                               Divider(),
  //                               // const SizedBox(height: 5),
  //                               Row(
  //                                 children: [
  //                                   Icon(
  //                                     Icons.verified_user,
  //                                     size: 14,
  //                                     color: AppColors.green,
  //                                   ),
  //                                   const SizedBox(width: 4),
  //                                   Text(
  //                                     'Inspected 8.2/10',
  //                                     style: TextStyle(
  //                                       fontSize: 10,
  //                                       // fontWeight: FontWeight.bold,
  //                                       color: AppColors.green,
  //                                     ),
  //                                   ),
  //                                 ],
  //                               ),
  //                             ],
  //                           )
  //                           : const SizedBox.shrink(),
  //                     ],
  //                   ),
  //                 ),

  //                 Obx(
  //                   () => Positioned(
  //                     top: 10,
  //                     right: 10,
  //                     child: InkWell(
  //                       onTap: () => getxController.changeFavoriteCars(car),
  //                       borderRadius: BorderRadius.circular(20),
  //                       child: Container(
  //                         padding: const EdgeInsets.all(6),
  //                         decoration: BoxDecoration(
  //                           color: Colors.grey[200],
  //                           shape: BoxShape.circle,
  //                         ),
  //                         child: Icon(
  //                           car.isFavorite.value
  //                               ? Icons.favorite
  //                               : Icons.favorite_outline,
  //                           color:
  //                               car.isFavorite.value
  //                                   ? AppColors.red
  //                                   : AppColors.grey,
  //                           size: 20,
  //                         ),
  //                       ),
  //                     ),
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           ),
  //         );
  //       },
  //     ),
  //   );
  // }

  // Widget _buildLoadingWidget() {
  //   return Padding(
  //     padding: const EdgeInsets.symmetric(horizontal: 15),
  //     child: ListView.separated(
  //       itemCount: 3,
  //       separatorBuilder: (_, __) => const SizedBox(height: 15),
  //       itemBuilder: (context, index) {
  //         return Card(
  //           elevation: 4,
  //           shape: RoundedRectangleBorder(
  //             borderRadius: BorderRadius.circular(12),
  //           ),
  //           child: Column(
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               // Image shimmer
  //               const ShimmerWidget(height: 160, borderRadius: 12),

  //               Padding(
  //                 padding: const EdgeInsets.all(12.0),
  //                 child: Column(
  //                   crossAxisAlignment: CrossAxisAlignment.start,
  //                   children: const [
  //                     // Title shimmer
  //                     ShimmerWidget(height: 14, width: 150),
  //                     SizedBox(height: 10),

  //                     // Bid row shimmer
  //                     ShimmerWidget(height: 12, width: 100),
  //                     SizedBox(height: 6),

  //                     // Year and KM
  //                     Row(
  //                       children: [
  //                         ShimmerWidget(height: 10, width: 60),
  //                         SizedBox(width: 10),
  //                         ShimmerWidget(height: 10, width: 80),
  //                       ],
  //                     ),
  //                     SizedBox(height: 6),

  //                     // Fuel and Location
  //                     Row(
  //                       children: [
  //                         ShimmerWidget(height: 10, width: 60),
  //                         SizedBox(width: 10),
  //                         ShimmerWidget(height: 10, width: 80),
  //                       ],
  //                     ),
  //                     SizedBox(height: 8),

  //                     // Inspection badge
  //                     ShimmerWidget(height: 10, width: 100),
  //                   ],
  //                 ),
  //               ),
  //             ],
  //           ),
  //         );
  //       },
  //     ),
  //   );
  // }
}
