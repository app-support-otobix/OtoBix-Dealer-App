import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:otobix/Controllers/car_details_controller.dart';
import 'package:otobix/Utils/app_colors.dart';
import 'package:otobix/Widgets/button_widget.dart';
import 'package:otobix/helpers/car_margin_helpers.dart';

void placeBidButtonForOtobuySection(
  BuildContext context,
  String carId,
  RxString remainingAuctionTime,
  double priceDiscovery,
  RxDouble fixedMargin,
  RxDouble variableMargin,
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
        maxChildSize: 0.5,
        initialChildSize: 0.35,
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
                      "One Click Buy",
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
                SizedBox(height: 30),
                // Bids Box
                // Container(
                //   padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                //   decoration: BoxDecoration(
                //     border: Border.all(color: AppColors.grey),
                //     borderRadius: BorderRadius.circular(12),
                //   ),
                //   child: Row(
                //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                //     children: [
                //       // Starting Bid
                //       Column(
                //         crossAxisAlignment: CrossAxisAlignment.start,
                //         children: [
                //           Text(
                //             "One Click Price",
                //             style: TextStyle(
                //               color: AppColors.grey,
                //               fontSize: 10,
                //             ),
                //           ),
                //           SizedBox(height: 4),
                //           Text(
                //             "Rs 54,000",
                //             style: TextStyle(
                //               fontWeight: FontWeight.w600,
                //               fontSize: 12,
                //               color: AppColors.black,
                //             ),
                //           ),
                //         ],
                //       ),
                //       Container(width: 1, height: 30, color: AppColors.grey),
                //       // Last Bid
                //       Column(
                //         crossAxisAlignment: CrossAxisAlignment.end,
                //         children: [
                //           Text(
                //             "Your Offer",
                //             style: TextStyle(
                //               color: AppColors.grey,
                //               fontSize: 10,
                //             ),
                //           ),
                //           SizedBox(height: 4),
                //           Obx(
                //             () => Text(
                //               "Rs ${NumberFormat.decimalPattern('en_IN').format(bidController.bidAmount.value)}",
                //               style: TextStyle(
                //                 fontWeight: FontWeight.w600,
                //                 fontSize: 12,
                //                 color: AppColors.black,
                //               ),
                //             ),
                //           ),
                //         ],
                //       ),
                //     ],
                //   ),
                // ),
                // SizedBox(height: 30),
                // Bid Controller
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Minus
                      // GestureDetector(
                      //   onTap: () {
                      //     bidController.decreaseBid();
                      //   },
                      //   child: Container(
                      //     padding: EdgeInsets.all(12),
                      //     decoration: BoxDecoration(
                      //       border: Border.all(color: AppColors.red),
                      //       shape: BoxShape.circle,
                      //     ),
                      //     child: Icon(
                      //       Icons.remove,
                      //       color: AppColors.red,
                      //       size: 20,
                      //     ),
                      //   ),
                      // ),
                      // SizedBox(width: 30),
                      // Bid Value
                      Obx(() {
                        // Add margin in one click price
                        final double oneClickPriceAmountAfterMarginAdjustment =
                            CarMarginHelpers.netAfterMarginsFlexible(
                              originalPrice:
                                  bidController.oneClickPriceAmount.value,
                              priceDiscovery: priceDiscovery,
                              fixedMargin: fixedMargin.value,
                              variableMargin: variableMargin.value,
                            );

                        return Column(
                          children: [
                            Text(
                              // 'Rs. ${NumberFormat.decimalPattern('en_IN').format(GlobalFunctions.roundToNearestThousand<int>(bidController.oneClickPriceAmount.value))}/-',
                              'Rs. ${NumberFormat.decimalPattern('en_IN').format(oneClickPriceAmountAfterMarginAdjustment)}/-',

                              style: TextStyle(
                                color: AppColors.blue,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "Buy now at",
                              style: TextStyle(
                                color: AppColors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        );
                      }),
                      // SizedBox(width: 30),
                      // // Plus
                      // GestureDetector(
                      //   onTap: () {
                      //     bidController.increaseBid();
                      //   },
                      //   child: Container(
                      //     padding: EdgeInsets.all(12),
                      //     decoration: BoxDecoration(
                      //       border: Border.all(color: AppColors.green),
                      //       shape: BoxShape.circle,
                      //     ),
                      //     child: Icon(
                      //       Icons.add,
                      //       color: AppColors.green,
                      //       size: 20,
                      //     ),
                      //   ),
                      // ),
                    ],
                  ),
                ),
                SizedBox(height: 30),
                // Bid Button
                Row(
                  children: [
                    Expanded(
                      child: ButtonWidget(
                        text: "Buy Now",
                        isLoading: bidController.isBuyNowButtonLoading,
                        onTap: () {
                          bidController.buyNow(carId: carId);
                          Get.back();
                          Get.back();
                          // Get.dialog(
                          //   CongratulationsDialogWidget(
                          //     title: "🎉 You Bought the Car!",
                          //     message:
                          //         "Congratulations on your successful purchase!",
                          //     buttonText: "Check Details",
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
