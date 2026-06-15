import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:otobix/Controllers/car_details_controller.dart';
import 'package:otobix/Utils/app_colors.dart';
import 'package:otobix/Utils/global_functions.dart';
import 'package:otobix/Widgets/button_widget.dart';
import 'package:intl/intl.dart';
import 'package:otobix/helpers/car_margin_helpers.dart';

// Auto Bid Sheet
void autoBidButtonForOtobuySection(
  String carId,
  RxString remainingAuctionTime,
  double priceDiscovery,
  RxDouble fixedMargin,
  RxDouble variableMargin,
) {
  final CarDetailsController getxController = Get.put(
    CarDetailsController(carId),
  );
  getxController.resetBidIncrement();

  // Calculate adjusted one-click price once and make it reactive
  final RxDouble adjustedOneClickPrice = RxDouble(0.0);

  // Function to update adjusted price
  void updateAdjustedPrice() {
    adjustedOneClickPrice.value = CarMarginHelpers.netAfterMarginsFlexible(
      originalPrice: getxController.oneClickPriceAmount.value,
      priceDiscovery: priceDiscovery,
      fixedMargin: fixedMargin.value,
      variableMargin: variableMargin.value,
    );
  }

  // Initial calculation
  updateAdjustedPrice();

  // Listen to changes in oneClickPrice, fixedMargin, variableMargin
  everAll([getxController.oneClickPriceAmount, fixedMargin, variableMargin], (
    _,
  ) {
    updateAdjustedPrice();
  });

  showModalBottomSheet(
    context: Get.context!,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.5,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
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
                      "Make Offer",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.black,
                      ),
                    ),
                    // Row(
                    //   children: [
                    //     Icon(Icons.access_time, color: AppColors.red, size: 15),
                    //     SizedBox(width: 4),
                    //     Obx(
                    //       () => Text(
                    //         remainingAuctionTime.value,
                    //         style: TextStyle(
                    //           color: AppColors.red,
                    //           fontSize: 12,
                    //           fontWeight: FontWeight.w600,
                    //         ),
                    //       ),
                    //     ),
                    //   ],
                    // ),
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
                            "One Click Price",
                            style: TextStyle(
                              color: AppColors.grey,
                              fontSize: 10,
                            ),
                          ),
                          SizedBox(height: 4),
                          Obx(() {
                            return Text(
                              // 'Rs. ${NumberFormat.decimalPattern('en_IN').format(GlobalFunctions.roundToNearestThousand<int>(getxController.oneClickPriceAmount.value))}/-',
                              'Rs. ${NumberFormat.decimalPattern('en_IN').format(adjustedOneClickPrice.value)}/-',

                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                                color: AppColors.black,
                              ),
                            );
                          }),
                        ],
                      ),
                      Container(width: 1, height: 30, color: AppColors.grey),
                      // Last Bid
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            // "Current Highest Bid",
                            "Current Highest Offer",
                            style: TextStyle(
                              color: AppColors.grey,
                              fontSize: 10,
                            ),
                          ),
                          SizedBox(height: 4),
                          Obx(
                            () => Text(
                              // "Rs. ${NumberFormat.decimalPattern('en_IN').format(getxController.currentHighestBidAmount.value)}",
                              'Rs. ${NumberFormat.decimalPattern('en_IN').format(GlobalFunctions.roundToNearestThousand<int>(getxController.currentHighestBidAmount.value))}/-',

                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                                color: AppColors.black,
                              ),
                            ),
                          ),
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
                          final decrement = getxController.getIncrementStep(
                            priceDiscovery,
                          );
                          // int decrement = 1000;
                          if (getxController.yourOfferAmount.value -
                                  decrement <=
                              getxController.currentHighestBidAmount.value) {
                            // ToastWidget.show(
                            //   title:
                            //       "You can't bid less than the highest bid amount",
                            //   context: Get.context!,
                            //   type: ToastType.error,
                            // );
                            debugPrint(
                              "You can't bid less than the highest bid amount",
                            );
                          } else {
                            getxController.yourOfferAmount.value -= decrement;
                          }
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
                      Obx(
                        () => Column(
                          children: [
                            Text(
                              'Rs. ${NumberFormat.decimalPattern('en_IN').format(GlobalFunctions.roundToNearestThousand<int>(getxController.yourOfferAmount.value))}/-',

                              style: TextStyle(
                                color: AppColors.blue,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Obx(
                              () => Text(
                                // "Bid increased by Rs. ${NumberFormat.decimalPattern('en_IN').format(getxController.yourOfferAmount.value - getxController.currentHighestBidAmount.value)}",
                                "Bid increased by Rs. ${NumberFormat.decimalPattern('en_IN').format(GlobalFunctions.roundToNearestThousand<int>(getxController.yourOfferAmount.value - getxController.currentHighestBidAmount.value))}/-",
                                style: TextStyle(
                                  color: AppColors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 20),
                      // Plus
                      GestureDetector(
                        onTap: () {
                          final increment = getxController.getIncrementStep(
                            priceDiscovery,
                          );
                          // // int increment = 1000;
                          // if (getxController.yourOfferAmount.value +
                          //         increment <=
                          //     getxController.oneClickPriceAmount.value) {
                          //   getxController.yourOfferAmount.value += increment;
                          // }

                          // Use adjustedOneClickPrice.value instead of getxController.oneClickPriceAmount.value
                          if (getxController.yourOfferAmount.value +
                                  increment <=
                              adjustedOneClickPrice.value) {
                            getxController.yourOfferAmount.value += increment;
                          }
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
                        text: "Make Offer",
                        isLoading: getxController.isMakeOfferButtonLoading,
                        onTap: () {
                          getxController.makeOffer(carId: carId);
                          Get.back();
                          // Get.dialog(
                          //   CongratulationsDialogWidget(
                          //     icon: Icons.emoji_events,
                          //     iconColor: AppColors.yellow,
                          //     iconSize: 25,
                          //     title: "Offer Placed!",
                          //     message:
                          //         "Your offer has been successfully placed.",
                          //     buttonText: "OK",
                          //     onButtonTap: () {
                          //       // handle navigation or close
                          //       Get.back();
                          //     },
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
