import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:otobix/Models/self_inspected_cars_model.dart';
import 'package:otobix/Network/api_service.dart';
import 'package:otobix/Services/user_activity_log_service.dart';
import 'package:otobix/Utils/app_constants.dart';
import 'package:otobix/Utils/app_urls.dart';
import 'package:otobix/Widgets/toast_widget.dart';
import 'package:otobix/helpers/shared_prefs_helper.dart';

class SelfInspectedCarDetailsController extends GetxController {
  RxBool isPageLoading = false.obs;
  RxBool isRefreshing = false.obs;
  RxBool isMakeOfferLoading = false.obs;

  String carId = '';
  Rxn<SelfInspectedCarModel> carData = Rxn<SelfInspectedCarModel>();

  RxDouble yourOfferAmount = 0.0.obs;

  SelfInspectedCarDetailsController({
    required this.carId,
    SelfInspectedCarModel? initialCar,
  }) {
    // Set initial data from previous screen
    if (initialCar != null) {
      carData.value = initialCar;
    }
  }

  @override
  void onInit() async {
    super.onInit();

    // Only call API if data is missing or incomplete
    if (carData.value == null ||
        carData.value?.registrationNumber.isEmpty == true) {
      await fetchSelfInspectedCarDetails();
    }

    setYourOfferAmount();
  }

  // Set your offer amount on start
  void setYourOfferAmount() {
    final double priceDiscovery = carData.value!.priceDiscovery.toDouble();
    final double highestOfferAmount =
        carData.value!.highestOffer.value.toDouble();
    final double incrementDecrementStep = getIncrementDecrementStep(
      priceDiscovery,
    );
    final double amountIfHighestOfferIsNotZero =
        highestOfferAmount + incrementDecrementStep;
    final double amountIfHighestOfferIsZero = priceDiscovery * 0.75;
    yourOfferAmount.value =
        highestOfferAmount <= 0
            ? amountIfHighestOfferIsZero
            : amountIfHighestOfferIsNotZero;
  }

  Future<void> fetchSelfInspectedCarDetails() async {
    if (isPageLoading.value) return;

    isPageLoading.value = true;
    try {
      final response = await ApiService.get(
        endpoint: AppUrls.getSelfInspectedCarDetails(carId: carId),
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        final data = responseBody['data'];

        // Convert to model
        carData.value = SelfInspectedCarModel.fromJson(data);
      } else {
        ToastWidget.show(
          context: Get.context!,
          title: 'Failed',
          subtitle: 'Failed to fetch car details',
          type: ToastType.error,
        );
      }
    } catch (error) {
      ToastWidget.show(
        context: Get.context!,
        title: 'Error',
        subtitle: 'Error occurred while fetching car details',
        type: ToastType.error,
      );
    } finally {
      isPageLoading.value = false;
    }
  }

  Future<void> refreshData() async {
    isRefreshing.value = true;
    await fetchSelfInspectedCarDetails();
    isRefreshing.value = false;
  }

  String formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.day}/${date.month}/${date.year}';
  }

  String formatCurrency(int? amount) {
    if (amount == null) return 'N/A';
    return '₹${amount.toString()}';
  }

  Color getStatusColor(String? status) {
    if (status == null) return Colors.grey;
    switch (status.toLowerCase()) {
      case 'active':
      case 'valid':
        return Colors.green;
      case 'expired':
      case 'invalid':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  // Steps for increment and decrement
  double getIncrementDecrementStep(double pdValue) {
    if (pdValue <= 100000) {
      return 1000;
    } else if (pdValue <= 299000) {
      return 2000;
    } else if (pdValue <= 499000) {
      return 3000;
    } else if (pdValue <= 999000) {
      return 4000;
    } else {
      return 5000;
    }
  }

  // Increase offer
  void increaseOffer(incrementStep) {
    yourOfferAmount.value = yourOfferAmount.value + incrementStep;
  }

  // Decrease offer
  void decreaseOffer({
    required double decrementStep,
    required double highestOffer,
  }) {
    final double priceDiscovery = carData.value!.priceDiscovery.toDouble();
    final bool highestOfferIsZero = highestOffer == 0;
    final bool highestOfferIsNotZero = highestOffer != 0;
    if (yourOfferAmount.value <= 0) {
      return;
    }
    if (highestOfferIsZero &&
        (yourOfferAmount.value - decrementStep) <= priceDiscovery * 0.75) {
      return;
    }
    if (highestOfferIsNotZero &&
        (yourOfferAmount.value - decrementStep) <= highestOffer) {
      return;
    }
    yourOfferAmount.value = yourOfferAmount.value - decrementStep;
  }

  // Make offer on self inspected car
  Future<bool> makeOfferOnSelfInspectedCar({required String carId}) async {
    if (isMakeOfferLoading.value) return false;

    isMakeOfferLoading.value = true;

    final String userId =
        await SharedPrefsHelper.getString(SharedPrefsHelper.userIdKey) ?? '';

    try {
      final response = await ApiService.post(
        endpoint: AppUrls.makeOfferOnSelfInspectedCar,
        body: {
          'carId': carId,
          'userId': userId,
          'offerAmount': yourOfferAmount.value,
        },
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Log event
        UserActivityLogService.logEvent(
          userId: userId,
          event: AppConstants.userActivityLogEvents.pdTapToMakeOfferClicked,
          eventDetails: 'Offer placed successfully',
          metadata: {"carId": carId, "offerAmount": yourOfferAmount.value},
        );

        ToastWidget.show(
          context: Get.context!,
          title: 'Offer Placed',
          subtitle: 'Your offer has been placed.',
          type: ToastType.success,
        );

        return true;
      } else if (response.statusCode == 400) {
        final message = responseBody['message'];

        // Log event
        UserActivityLogService.logEvent(
          userId: userId,
          event: AppConstants.userActivityLogEvents.pdTapToMakeOfferClicked,
          eventDetails: message ?? 'Failed to place offer',
          metadata: {"carId": carId, "offerAmount": yourOfferAmount.value},
        );

        ToastWidget.show(
          context: Get.context!,
          title: 'Failed',
          subtitle: message ?? 'Failed to place the offer.',
          type: ToastType.error,
        );

        return false;
      } else {
        // Log event
        UserActivityLogService.logEvent(
          userId: userId,
          event: AppConstants.userActivityLogEvents.pdTapToMakeOfferClicked,
          eventDetails: 'Failed to place offer',
          metadata: {"carId": carId, "offerAmount": yourOfferAmount.value},
        );

        ToastWidget.show(
          context: Get.context!,
          title: 'Failed',
          subtitle: 'Failed to place the offer',
          type: ToastType.error,
        );

        return false;
      }
    } catch (error) {
      // Log event
      UserActivityLogService.logEvent(
        userId: userId,
        event: AppConstants.userActivityLogEvents.pdTapToMakeOfferClicked,
        eventDetails: 'Error placing offer',
        metadata: {
          "carId": carId,
          "offerAmount": yourOfferAmount.value,
          "error": error.toString(),
        },
      );

      ToastWidget.show(
        context: Get.context!,
        title: 'Error',
        subtitle: 'Error placing offer on the car',
        type: ToastType.error,
      );
      return false;
    } finally {
      isMakeOfferLoading.value = false;
    }
  }
}
