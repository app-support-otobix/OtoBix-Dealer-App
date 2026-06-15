import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:otobix/Controllers/car_details_controller.dart';
import 'package:otobix/Utils/app_colors.dart';
import 'package:otobix/Widgets/button_widget.dart';

Future<void> offeringBidSheet(BuildContext context, String carId) async {
  final CarDetailsController bidController = Get.put(
    CarDetailsController(carId),
  );
  bidController.resetBidIncrement();

  // reset offering your bid increment
  bidController.startOfferingBidTimer(seconds: 30);

  await showModalBottomSheet(
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
        initialChildSize: 0.45,
        minChildSize: 0.45,
        builder: (_, controller) {
          return _buildOfferingSheetContent(context, bidController, controller);
        },
      );
    },
  );

  // 🔥 When sheet is dismissed (by back or drag), cleanup here too
  if (bidController.offeringYourBidTimer != null) {
    bidController.cancelOfferingBid();
  }
}

void showWinDialog() {
  final ConfettiController confettiController = ConfettiController(
    duration: const Duration(seconds: 2),
  );
  confettiController.play(); // Start confetti

  Get.dialog(
    Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "🎉 You Won the Bid!",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Congratulations on your successful offer!",
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ButtonWidget(
                  onTap: () => Get.back(),
                  text: "View Details",
                  isLoading: false.obs,
                  height: 40,
                  width: 150,
                  backgroundColor: AppColors.green,
                  textColor: AppColors.white,
                  loaderSize: 15,
                  loaderStrokeWidth: 1,
                  loaderColor: AppColors.white,
                ),
              ],
            ),
          ),
          Positioned(
            top: -10,
            child: ConfettiWidget(
              confettiController: confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              emissionFrequency: 0.05,
              numberOfParticles: 30,
              maxBlastForce: 20,
              minBlastForce: 5,
              gravity: 0.3,
            ),
          ),
        ],
      ),
    ),
    barrierDismissible: false,
  );
}

Widget _buildOfferingSheetContent(
  BuildContext context,
  CarDetailsController bidController,
  ScrollController controller,
) {
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
              color: AppColors.grey,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        const SizedBox(height: 20),
        // Top Row: Title + Timer
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Offering Your Bid...",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.green,
              ),
            ),

            // Row(
            //   children: [
            //     Icon(Icons.access_time, color: AppColors.red, size: 15),
            //     SizedBox(width: 4),
            //     Obx(
            //       () => Text(
            //         bidController.remainingTime.value,
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

        const SizedBox(height: 30),
        Obx(
          () => Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.access_time, color: AppColors.red, size: 15),
              SizedBox(width: 4),
              Text(
                '${bidController.offeringYourBidCountdown.value}s left',
                style: TextStyle(fontSize: 12, color: AppColors.red),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Obx(
          () => LinearProgressIndicator(
            value: bidController.offeringYourBidProgress.value,
            backgroundColor: AppColors.grey.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(50),
            color: AppColors.green,
            minHeight: 4,
          ),
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
        //             "Current Bid",
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
        //             "Your Bid",
        //             style: TextStyle(
        //               color: AppColors.grey,
        //               fontSize: 10,
        //             ),
        //           ),
        //           SizedBox(height: 4),
        //           Obx(
        //             () => Text(
        //               "Rs ${NumberFormat.decimalPattern('en_IN').format(bidController.yourOfferAmount.value)}",
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
                  child: Icon(Icons.remove, color: AppColors.red, size: 20),
                ),
              ),
              SizedBox(width: 30),
              // Bid Value
              Obx(
                () => Column(
                  children: [
                    Text(
                      "Rs ${NumberFormat.decimalPattern('en_IN').format(bidController.yourOfferAmount.value)}",
                      style: TextStyle(
                        color: AppColors.blue,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      // "Bid increase by ${NumberFormat.decimalPattern('en_IN').format(bidController.yourOfferAmount.value - 54000)}",
                      'Your offer',
                      style: TextStyle(color: AppColors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 30),
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
                  child: Icon(Icons.add, color: AppColors.green, size: 20),
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
                text: "Cancel Bid",
                isLoading: bidController.isLoading,
                onTap: () {
                  bidController.cancelOfferingBid(); // stop timer manually
                },
                height: 35,
                fontSize: 12,
                elevation: 10,
                backgroundColor: AppColors.red,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
