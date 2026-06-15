import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:otobix/Controllers/wishlist_controller.dart';
import 'package:otobix/Utils/app_colors.dart';
import 'package:otobix/Utils/app_images.dart';
import 'package:get/get.dart';
import 'package:otobix/Utils/global_functions.dart';

class CarDeckViewForMyBidsAndWishlistWidget extends StatelessWidget {
  final dynamic car;
  final VoidCallback toggleFavorite;
  final Widget footer;
  final VoidCallback onCarTap;
  final bool showAddToWishlistIcon;
  final bool isMyBidsCarsModel;
  const CarDeckViewForMyBidsAndWishlistWidget({
    super.key,
    required this.car,
    required this.toggleFavorite,
    required this.footer,
    required this.onCarTap,
    this.showAddToWishlistIcon = true,
    this.isMyBidsCarsModel = false,
  });

  @override
  Widget build(BuildContext context) {
    final wishlistController = Get.find<WishlistController>();
    return _buildCarCard(wishlistController);
  }

  Widget _buildCarCard(WishlistController wishlistController) {
    final String yearofManufacture =
        '${GlobalFunctions.getFormattedDate(date: car.yearMonthOfManufacture, type: GlobalFunctions.year)} ';
    return InkWell(
      onTap: onCarTap,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Car image
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(5),
                  ),

                  child: CachedNetworkImage(
                    imageUrl: car.imageUrl,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder:
                        (context, url) => Container(
                          height: 160,
                          width: double.infinity,
                          color: Colors.grey[300],
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.green,
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                    errorWidget: (context, error, stackTrace) {
                      return Image.asset(
                        AppImages.carAlternateImage,
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      );
                    },
                  ),
                ),
                if (showAddToWishlistIcon)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Obx(() {
                      final isThisCarFav = wishlistController.wishlistCarsIds
                          .contains(car.id);
                      return InkWell(
                        onTap: () => toggleFavorite(),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.white.withValues(alpha: .8),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: Colors.black12, blurRadius: 4),
                            ],
                          ),
                          child: Icon(
                            isThisCarFav
                                ? Icons.favorite
                                : Icons.favorite_outline,
                            color:
                                isThisCarFav ? AppColors.red : AppColors.grey,
                            size: 20,
                          ),
                        ),
                      );
                    }),
                  ),
              ],
            ),

            // Car details
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$yearofManufacture${car.make} ${car.model} ${car.variant}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 6),
                  _buildOtherDetails(car),
                  // const SizedBox(height: 10),
                  // Row(
                  //   children: [
                  //     Text(
                  //       'Highest Bid: ',
                  //       style: const TextStyle(
                  //         fontSize: 14,
                  //         color: AppColors.grey,
                  //         fontWeight: FontWeight.w600,
                  //       ),
                  //     ),
                  //     Obx(
                  //       () => Text(
                  //         'Rs. ${NumberFormat.decimalPattern('en_IN').format(car.highestBid.value)}/-',
                  //         key: ValueKey(car.highestBid.value),
                  //         style: const TextStyle(
                  //           fontSize: 14,
                  //           color: AppColors.green,
                  //           fontWeight: FontWeight.w600,
                  //         ),
                  //       ),
                  //     ),

                  //     // Text(
                  //     //   'Rs. ${NumberFormat.decimalPattern('en_IN').format(car.highestBid)}/-',
                  //     //   style: const TextStyle(
                  //     //     fontSize: 14,
                  //     //     color: AppColors.green,
                  //     //     fontWeight: FontWeight.w600,
                  //     //   ),
                  //     // ),
                  //   ],
                  // ),
                  const SizedBox(height: 5),
                  footer,
                  // if (car.isInspected == true)
                  //   Column(
                  //     children: [
                  //       Divider(),
                  //       Row(
                  //         children: [
                  //           Icon(
                  //             Icons.verified_user,
                  //             size: 14,
                  //             color: AppColors.green,
                  //           ),
                  //           const SizedBox(width: 4),
                  //           Text(
                  //             'Inspected 8.2/10',
                  //             style: TextStyle(
                  //               fontSize: 10,
                  //               color: AppColors.green,
                  //             ),
                  //           ),
                  //         ],
                  //       ),
                  //     ],
                  //   ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOtherDetails(dynamic car) {
    Widget iconDetail(IconData icon, String label, String value) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 15, color: AppColors.grey),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          // Divider(),
          // Text(
          //   label,
          //   style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          // ),
        ],
      );
    }

    String maskRegistrationNumber(String? input) {
      if (input == null || input.length <= 5) return '*****';
      final visible = input.substring(0, input.length - 5);
      return '$visible*****';
    }

    final items = [
      // iconDetail(Icons.factory, 'Make', 'Mahindra'),
      // iconDetail(Icons.directions_car, 'Model', 'Scorpio'),
      // iconDetail(Icons.confirmation_number, 'Variant', '[2014–2017]'),
      iconDetail(
        Icons.calendar_month,
        'Year of Manufacture',
        GlobalFunctions.getFormattedDate(
              date: car.yearMonthOfManufacture,
              type: GlobalFunctions.monthYear,
            ) ??
            'N/A',
      ),
      iconDetail(
        Icons.speed,
        'Odometer Reading in Kms',
        '${NumberFormat.decimalPattern('en_IN').format(car.odometerReadingInKms)} km',
      ),
      iconDetail(Icons.local_gas_station, 'Fuel Type', car.fuelType),

      // iconDetail(
      //   Icons.calendar_month,
      //   'Year of Manufacture',
      //   GlobalFunctions.getFormattedDate(
      //         date: carDetails.yearMonthOfManufacture,
      //         type: GlobalFunctions.year,
      //       ) ??
      //       'N/A',
      // ),
      iconDetail(Icons.settings, 'Transmission', car.commentsOnTransmission),
      iconDetail(
        Icons.person,
        'Owner Serial Number',
        car.ownerSerialNumber == 1
            ? 'First Owner'
            : '${car.ownerSerialNumber} Owners',
      ),
      iconDetail(
        Icons.receipt_long,
        'Tax Validity',
        car.roadTaxValidity == 'LTT' || car.roadTaxValidity == 'OTT'
            ? car.roadTaxValidity
            : GlobalFunctions.getFormattedDate(
                  date: car.taxValidTill,
                  type: GlobalFunctions.monthYear,
                ) ??
                'N/A',
      ),

      // iconDetail(
      //   Icons.science,
      //   'Cubic Capacity',
      //   car.cubicCapacity != 0 ? '${car.cubicCapacity} cc' : 'N/A',
      // ),
      iconDetail(
        Icons.location_on,
        'Inspection Location',
        car.inspectionLocation,
      ),
      iconDetail(
        Icons.directions_car_filled,
        'Registration No.',
        maskRegistrationNumber(car.registrationNumber),
      ),
      iconDetail(Icons.apartment, 'Registered RTO', car.registeredRto),
    ];

    return Container(
      // padding: const EdgeInsets.all(12),
      // margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Wrap(
          //   spacing: 10,
          //   runSpacing: 5,
          //   alignment: WrapAlignment.start,
          //   children: items,
          // ),
          GridView.count(
            padding: EdgeInsets.zero,
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 5, // controls vertical space
            crossAxisSpacing: 10, // controls horizontal space
            childAspectRatio: 4, // width / height ratio — adjust as needed
            children: items,
          ),
        ],
      ),
    );
  }
}
