import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:otobix/Controllers/home_controller.dart';
import 'package:otobix/Controllers/self_inspected_cars_list_controller.dart';
import 'package:otobix/Models/self_inspected_cars_model.dart';
import 'package:otobix/Services/user_activity_log_service.dart';
import 'package:otobix/Utils/app_colors.dart';
import 'package:otobix/Utils/app_constants.dart';
import 'package:otobix/Utils/app_images.dart';
import 'package:otobix/Utils/global_functions.dart';
import 'package:otobix/Views/Dealer%20Panel/self_inspected_car_details_page.dart';
import 'package:otobix/Widgets/empty_data_widget.dart';
import 'package:otobix/Widgets/shimmer_widget.dart';
import 'package:otobix/helpers/bid_color_change_helper.dart';
import 'package:otobix/helpers/self_inspected_car_margin_helpers.dart';
import 'package:otobix/helpers/shared_prefs_helper.dart';

class SelfInspectedCarsListPage extends StatelessWidget {
  SelfInspectedCarsListPage({super.key});

  final SelfInspectedCarsListController selfInspectedCarsListController =
      Get.find<SelfInspectedCarsListController>();

  final HomeController homeController = Get.find<HomeController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const SizedBox(height: 10),

          Obx(() {
            // Search cars using homeController search text
            final searchTextFilteredCarsList = selfInspectedCarsListController
                .filterCarsBySearchText(
                  searchText: homeController.searchText.value,
                );

            // Check if cars list is loading
            if (selfInspectedCarsListController.isPageLoading.value) {
              return _buildLoadingWidget();
            } else if (searchTextFilteredCarsList.isEmpty) {
              // Check if cars list is empty
              return Expanded(
                child: Center(
                  child: const EmptyDataWidget(
                    icon: Icons.car_rental,
                    message: 'No Cars Found',
                  ),
                ),
              );
            } else {
              // Show fetched and filtered cars list
              return _buildCarsList(searchTextFilteredCarsList);
            }
          }),
        ],
      ),
    );
  }

  Widget _buildCarsList(List<SelfInspectedCarModel> carsList) {
    return Expanded(
      child: ListView.separated(
        controller: selfInspectedCarsListController.scrollController,
        itemCount:
            carsList.length +
            (selfInspectedCarsListController.isFetchingMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 15),
        itemBuilder: (context, index) {
          if (index >= carsList.length) {
            return _buildLoadingWidget();
          }

          final car = carsList[index];

          final String registerationDate =
              '${GlobalFunctions.getFormattedDate(date: car.registrationDate, type: GlobalFunctions.year)} ';

          return InkWell(
            onTap: () async {
              Get.to(() => SelfInspectedCarDetailsPage(car: car));

              final String userId =
                  await SharedPrefsHelper.getString(
                    SharedPrefsHelper.userIdKey,
                  ) ??
                  '';
              // Log event
              UserActivityLogService.logEvent(
                userId: userId,
                event:
                    AppConstants
                        .userActivityLogEvents
                        .carInspectionReportOpened,
                eventDetails: 'Clicked on car from pd cars page',
                metadata: {
                  "screen": "pd",
                  "carId": car.id,
                  "inspectionId": car.inspectionId,
                  "make": car.make,
                  "model": car.model,
                  "priceDiscovery": car.priceDiscovery,
                  "highestOffer": car.highestOffer.value,
                  "expectedPrice": car.expectedPrice.value,
                  "fixedMargin": car.fixedMargin.value,
                  "variableMargin": car.variableMargin.value,
                },
              );
            },
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Car image
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(10),
                        ),

                        child: CachedNetworkImage(
                          imageUrl: car.frontMainImage,
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
                    ],
                  ),
                  // Car details
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$registerationDate${car.make} ${car.model} ${car.variant}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 10),
                        _buildOtherDetails(car),
                        const SizedBox(height: 5),
                        _buildCarCardFooter(car),
                      ],
                    ),
                  ),
                ],
              ),
            ),
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
        itemBuilder: (context, index) {
          return Card(
            // elevation: 4,
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

  Widget _buildOtherDetails(SelfInspectedCarModel car) {
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
        ],
      );
    }

    String maskRegistrationNumber(String? input) {
      if (input == null || input.length <= 5) return '*****';
      final visible = input.substring(0, input.length - 5);
      return '$visible*****';
    }

    final items = [
      iconDetail(
        Icons.calendar_month,
        'Registration Date',
        GlobalFunctions.getFormattedDate(
              date: car.registrationDate,
              type: GlobalFunctions.monthYear,
            ) ??
            'N/A',
      ),
      iconDetail(
        Icons.speed,
        'Odometer Reading in Kms',
        '${NumberFormat.decimalPattern('en_IN').format(car.odometer)} km',
      ),
      iconDetail(
        Icons.local_gas_station,
        'Fuel Type',
        car.fuelType.isNotEmpty
            ? '${car.fuelType[0].toUpperCase()}${car.fuelType.substring(1).toLowerCase()}'
            : 'N/A',
      ),

      iconDetail(
        Icons.receipt_long,
        'Road Tax Validity',
        GlobalFunctions.getFormattedDate(
              date: car.taxValidTill,
              type: GlobalFunctions.monthYear,
            ) ??
            'N/A',
      ),
      iconDetail(
        Icons.person,
        'Owner Serial Number',
        car.ownershipSerialNo == 1
            ? 'First Owner'
            : '${car.ownershipSerialNo} Owners',
      ),

      iconDetail(
        Icons.science,
        'Cubic Capacity',
        car.cubicCapacity != 0 ? '${car.cubicCapacity} cc' : 'N/A',
      ),

      iconDetail(
        Icons.location_on,
        'Inspection Location',
        car.registrationState,
      ),
      iconDetail(
        Icons.directions_car_filled,
        'Registration No.',
        maskRegistrationNumber(car.registrationNumber),
      ),
      iconDetail(Icons.apartment, 'Registered RTO', car.registeredRTO),
    ];

    return Container(
      // padding: const EdgeInsets.all(12),
      // margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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

  Widget _buildCarCardFooter(SelfInspectedCarModel car) {
    return Obx(() {
      // final double highestOfferAmountAfterMarginAdjustment =
      //     SelfInspectedCarMarginHelpers.netAfterMarginsFlexible(
      //       originalPrice: car.highestOffer.value,
      //       priceDiscovery: car.priceDiscovery,
      //       fixedMargin: car.fixedMargin.value,
      //       variableMargin: car.variableMargin.value,
      //       roundToNext1000: true,
      //     );

      // Resolve color:
      RxBool hasUserMadeOfferOnCar = selfInspectedCarsListController
          .hasUserMadeOfferOnCar(car.id ?? '');
      final color = BidColorChangeHelper.getHighestBidColor(
        currentUserId: selfInspectedCarsListController.currentUserId,
        highestBidderUserId: car.highestOfferBy.value,
        hasUserBid: hasUserMadeOfferOnCar.value,
        neutralColor: AppColors.black,
        winningColor: AppColors.green,
        losingColor: AppColors.red,
      );

      final canShowExpectedPrice = BidColorChangeHelper.shouldShowExpectedPrice(
        hasUserBidOnCar: hasUserMadeOfferOnCar.value,
        customerExpectedPrice: car.expectedPrice.value.toDouble(),
      );

      final double expectedPriceAmountAfterMarginAdjustment =
          SelfInspectedCarMarginHelpers.getMarginAdjustedAmount(
            originalPrice: car.expectedPrice.value,
            priceDiscovery: car.priceDiscovery,
            fixedMargin: car.fixedMargin.value,
            variableMargin: car.variableMargin.value,
            shouldIncreaseMargin: true,
          );

      final Color expectedPriceColor =
          car.highestOffer.value >= expectedPriceAmountAfterMarginAdjustment
              ? AppColors.green
              : AppColors.red;

      return Column(
        children: [
          Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'Highest Offer: ',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Rs. ${NumberFormat.decimalPattern('en_IN').format(car.highestOffer.value)}/-',
                    key: ValueKey(car.highestOffer.value),
                    style: TextStyle(
                      fontSize: 14,
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              const SizedBox(width: 10),
              Text(
                selfInspectedCarsListController.getRemainingTime(
                  car.auctionEndTime ?? DateTime.now(),
                ),
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          if (canShowExpectedPrice)
            Column(
              children: [
                Divider(),
                Row(
                  children: [
                    Text(
                      'Deal Price: ',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Rs. ${NumberFormat.decimalPattern('en_IN').format(GlobalFunctions.roundToNearestThousand<int>(expectedPriceAmountAfterMarginAdjustment))}/-',

                      key: ValueKey(expectedPriceAmountAfterMarginAdjustment),
                      style: TextStyle(
                        fontSize: 14,
                        color: expectedPriceColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
        ],
      );
    });
  }
}
