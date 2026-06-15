import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:otobix/Controllers/car_details_controller.dart';
import 'package:otobix/Utils/app_colors.dart';
import 'package:otobix/Utils/global_functions.dart';
import 'package:otobix/Widgets/button_widget.dart';

void placeBidButtonForLiveBidsSection(
  BuildContext context,
  String carId,
  RxString remainingAuctionTime,
  double priceDiscovery,
) {
  final CarDetailsController bidController = Get.put(
    CarDetailsController(carId),
  );
  bidController.resetBidIncrement();
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return DraggableScrollableSheet(
        expand: false,
        maxChildSize: 0.9,
        initialChildSize: 0.5,
        minChildSize: 0.5,
        builder: (_, controller) {
          return Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.green,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Top Row: Title + Timer
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Place Your Bid",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.black,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(Icons.access_time, color: AppColors.red, size: 15),
                        SizedBox(width: 4),
                        Obx(
                          () => Text(
                            remainingAuctionTime.value,
                            style: TextStyle(
                              color: AppColors.red,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 20),
                // Bids Box
                Container(
                  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.grey),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Starting Bid
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Current Bid",
                            style: TextStyle(
                              color: AppColors.grey,
                              fontSize: 10,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            // "Rs. ${NumberFormat.decimalPattern('en_IN').format(bidController.currentHighestBidAmount.value)}",
                            'Rs. ${NumberFormat.decimalPattern('en_IN').format(GlobalFunctions.roundToNearestThousand<int>(bidController.currentHighestBidAmount.value))}/-',

                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              color: AppColors.black,
                            ),
                          ),
                        ],
                      ),
                      Container(width: 1, height: 30, color: AppColors.grey),
                      // Last Bid
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            "Your Bid",
                            style: TextStyle(
                              color: AppColors.grey,
                              fontSize: 10,
                            ),
                          ),
                          SizedBox(height: 4),
                          Obx(() {
                            final newPriceDiscovery = priceDiscovery * 0.75;
                            final yourOffer =
                                bidController.currentHighestBidAmount.value == 0
                                    ? newPriceDiscovery +
                                        bidController.yourOfferAmount.value
                                    : bidController.yourOfferAmount.value;
                            return Text(
                              // "Rs. ${NumberFormat.decimalPattern('en_IN').format(yourOffer)}",
                              'Rs. ${NumberFormat.decimalPattern('en_IN').format(GlobalFunctions.roundToNearestThousand<int>(yourOffer))}/-',

                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                                color: AppColors.black,
                              ),
                            );
                          }),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 30),
                // Bid Controller
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Minus
                      GestureDetector(
                        onTap: () {
                          bidController.decreaseBid();
                        },
                        child: Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.red),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.remove,
                            color: AppColors.red,
                            size: 20,
                          ),
                        ),
                      ),
                      SizedBox(width: 20),
                      // Bid Value
                      Obx(() {
                        final newPriceDiscovery = priceDiscovery * 0.75;
                        final yourOffer =
                            bidController.currentHighestBidAmount.value == 0
                                ? newPriceDiscovery +
                                    bidController.yourOfferAmount.value
                                : bidController.yourOfferAmount.value;
                        return Column(
                          children: [
                            Text(
                              // "Rs. ${NumberFormat.decimalPattern('en_IN').format(yourOffer)}",
                              'Rs. ${NumberFormat.decimalPattern('en_IN').format(GlobalFunctions.roundToNearestThousand<int>(yourOffer))}/-',

                              style: TextStyle(
                                color: AppColors.blue,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              // "Bid increase by ${NumberFormat.decimalPattern('en_IN').format(bidController.yourOfferAmount.value - bidController.currentHighestBidAmount.value)}",
                              "Bid increase by ${NumberFormat.decimalPattern('en_IN').format(GlobalFunctions.roundToNearestThousand<int>(bidController.yourOfferAmount.value - bidController.currentHighestBidAmount.value))}/-",
                              style: TextStyle(
                                color: AppColors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        );
                      }),
                      SizedBox(width: 20),
                      // Plus
                      GestureDetector(
                        onTap: () {
                          bidController.increaseBid();
                        },
                        child: Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.green),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.add,
                            color: AppColors.green,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 30),
                // Bid Button
                Row(
                  children: [
                    Expanded(
                      child: ButtonWidget(
                        text: "Place Bid",
                        isLoading: bidController.isPlaceBidButtonLoading,
                        onTap: () {
                          // debugPrint("Place Bid Button Tapped");
                          final newPriceDiscovery = priceDiscovery * 0.75;
                          final yourOffer =
                              bidController.currentHighestBidAmount.value == 0
                                  ? newPriceDiscovery +
                                      bidController.yourOfferAmount.value
                                  : bidController.yourOfferAmount.value;

                          bidController.placeBid(
                            carId: carId,
                            newBidAmount: yourOffer,
                          );
                          Get.back();
                          // offeringBidSheet(context);

                          // ToastWidget.show(
                          //   context: context,
                          //   title: "You're Winning! 🏆",
                          //   subtitle:
                          //       "Great job! Currently, you're the highest bidder.",
                          //   toastDuration: 5,
                          //   type: ToastType.success,
                          // );

                          //////////////////////////
                          // Get.dialog(
                          //   CongratulationsDialogWidget(
                          //     icon: Icons.gavel,
                          //     iconSize: 25,
                          //     title: "Bid Placed!",
                          //     message:
                          //         "Your bid has been successfully submitted.",
                          //     buttonText: "View Details",
                          //     onButtonTap: () => Get.back(),
                          //   ),
                          // );
                        },
                        height: 35,
                        fontSize: 12,
                        elevation: 10,
                        backgroundColor: AppColors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
