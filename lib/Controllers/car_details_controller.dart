import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:otobix/Controllers/home_controller.dart';
import 'package:otobix/Models/cars_list_model.dart';
import 'package:otobix/Models/car_model.dart';
import 'package:otobix/Network/api_service.dart';
import 'package:otobix/Network/socket_service.dart';
import 'package:otobix/Utils/app_colors.dart';
import 'package:otobix/Utils/app_constants.dart';
import 'package:otobix/Utils/app_urls.dart';
import 'package:otobix/Utils/socket_events.dart';
import 'package:otobix/Widgets/congratulations_dialog_widget.dart';
import 'package:otobix/Widgets/offering_bid_sheet.dart';
import 'package:otobix/Widgets/toast_widget.dart';
import 'package:otobix/helpers/shared_prefs_helper.dart';

class CarDetailsController extends GetxController {
  static const String imagesSectionKey = 'images';
  // static const String basicDetailsSectionKey = 'basic';
  static const String documentDetailsSectionKey = 'document';
  static const String exteriorSectionKey = 'exterior';
  static const String engineBaySectionKey = 'engineBay';
  static const String steeringBrakesAndSuspensionSectionKey =
      'steeringBrakesAndSuspension';
  static const String interiorAndElectricalsSectionKey =
      'interiorAndElectricals';
  static const String airConditioningSectionKey = 'airConditioning';

  final sectionKeys = {
    imagesSectionKey: GlobalKey(),
    // basicDetailsSectionKey: GlobalKey(),
    documentDetailsSectionKey: GlobalKey(),
    exteriorSectionKey: GlobalKey(),
    engineBaySectionKey: GlobalKey(),
    steeringBrakesAndSuspensionSectionKey: GlobalKey(),
    interiorAndElectricalsSectionKey: GlobalKey(),
    airConditioningSectionKey: GlobalKey(),
  };

  final ScrollController scrollController = ScrollController();
  final sectionTabScrollController = ScrollController();
  final sectionTabKeys = <String, GlobalKey>{};
  RxString currentSection = imagesSectionKey.obs;

  final currentIndex = 0.obs;
  // final imageUrls = <String>[].obs;
  final RxList<CarsListTitleAndImage> imageUrls = <CarsListTitleAndImage>[].obs;

  RxBool isLoading = false.obs;
  RxBool isPlaceBidButtonLoading = false.obs;
  RxBool isPreBidButtonLoading = false.obs;
  RxBool isBuyNowButtonLoading = false.obs;
  RxBool isMakeOfferButtonLoading = false.obs;

  // final remainingTime = ''.obs;
  // Timer? _timer;

  RxDouble currentHighestBidAmount = 0.0.obs;
  RxDouble yourOfferAmount = 0.0.obs;
  RxDouble oneClickPriceAmount = 0.0.obs;

  /// NEW: keep track of first click
  bool isFirstClick = true;

  CarModel? carDetails;

  Worker? _timerWatcher;
  bool _closedOnce = false;

  // ===== Add near other Rx fields =====
  final RxnString _highestBidderUserId = RxnString();
  final RxBool _hasUserBidOnThisCar = false.obs;
  String? _currentUserId;
  // public getters for UI
  String? get currentUserId => _currentUserId;
  String? get latestHighestBidderId => _highestBidderUserId.value;
  bool get userHasBid => _hasUserBidOnThisCar.value;

  final String carId;
  CarDetailsController(this.carId);

  @override
  void onInit() async {
    super.onInit();

    _currentUserId = await SharedPrefsHelper.getString(
      SharedPrefsHelper.userIdKey,
    );
    // currentHighestBidAmount.value == 0  ? currentHighestBidAmount.value =  carDetails?.priceDiscovery.toDouble() ?? 0 : currentHighestBidAmount.value;
    await fetchCarDetails(carId: carId);

    // To Set the highest bid color
    _initParticipationState();

    listenUpdatedBidAndChangeHighestBidLocally();
    listenOtobuyOfferAndChangeHighestBidLocally();
    _listenToCustomerUpdatedOneClickPriceRealtime();
    // await fetchCarDetails(carId: '68821747968635d593293346');
    // debugPrint(carDetails?.toJson().toString() ?? 'null');
    // Initialize keys for each tab
    for (var key in sectionKeys.keys) {
      sectionTabKeys[key] = GlobalKey();
    }
    scrollController.addListener(() {
      for (var entry in sectionKeys.entries) {
        final context = entry.value.currentContext;
        if (context == null) continue;

        final box = context.findRenderObject() as RenderBox?;
        if (box == null || !box.attached) continue;

        final position = box.localToGlobal(Offset.zero).dy;

        // Get a safe screen height even if no BuildContext yet
        final window = WidgetsBinding.instance.platformDispatcher.views.first;
        final physicalSize = window.physicalSize / window.devicePixelRatio;
        final screenHeight = physicalSize.height;

        if (position >= 20 && position < screenHeight / 2) {
          currentSection.value = entry.key;
          scrollToSectionTab(entry.key);
          break;
        }
      }
    });

    // scrollController.addListener(() {
    //   for (var entry in sectionKeys.entries) {
    //     final context = entry.value.currentContext;
    //     if (context != null) {
    //       final box = context.findRenderObject() as RenderBox;
    //       final position = box.localToGlobal(Offset.zero, ancestor: null).dy;

    //       // Only mark section active if its top is at least 20px below the top
    //       if (position >= 20 && position < Get.context!.size!.height / 2) {
    //         currentSection.value = entry.key;
    //         scrollToSectionTab(entry.key);
    //         break;
    //       }
    //     }
    //   }
    // });
  }

  Future<void> fetchCarDetails({required String carId}) async {
    isLoading.value = true;
    try {
      final url = AppUrls.getCarDetails(carId);
      final response = await ApiService.get(endpoint: url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        carDetails = CarModel.fromJson(
          json: data['carDetails'],
          documentId: data['carDetails']['_id'],
        );
        debugPrint('Car Details Fetched Successfully');
      } else {
        debugPrint('Failed to load data ${response.body}');
        carDetails = null;
      }
    } catch (error) {
      debugPrint('Failed to load data: $error');
      carDetails = null;
    } finally {
      isLoading.value = false;
    }
  }

  ////////////////////////////////////////////////
  // Offering your bid progress
  Timer? offeringYourBidTimer;
  RxDouble offeringYourBidProgress = 1.0.obs;
  RxInt offeringYourBidCountdown = 30.obs;
  void startOfferingBidTimer({required int seconds}) {
    offeringYourBidTimer?.cancel();
    offeringYourBidProgress.value = 1.0;
    offeringYourBidCountdown.value = seconds;

    const tickInterval = Duration(milliseconds: 100);
    int ticks = 0;
    int totalTicks = seconds * 10;

    offeringYourBidTimer = Timer.periodic(tickInterval, (timer) {
      ticks++;
      offeringYourBidProgress.value = 1.0 - (ticks / totalTicks);
      offeringYourBidCountdown.value = seconds - (ticks ~/ 10);

      if (ticks >= totalTicks) {
        timer.cancel();
        offeringYourBidTimer = null;
        Get.back(); // auto close bottom sheet
        Future.delayed(Duration(milliseconds: 300), () {
          showWinDialog(); // Call your dialog
        });
      }
    });
  }

  void cancelOfferingBid() {
    offeringYourBidTimer?.cancel();
    offeringYourBidTimer = null;
    Get.back(); // auto close bottom sheet
  }

  ////////////////////////////////////////
  // Later if you want to increment/decrement by PD
  double getIncrementStep(double pdValue) {
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

  /// Increase bid logic
  void increaseBid() {
    final double pd = carDetails?.priceDiscovery.toDouble() ?? 0.0;
    final step = getIncrementStep(pd);

    yourOfferAmount.value += step;

    if (isFirstClick) isFirstClick = false;
  }

  /// Decrease bid logic
  void decreaseBid() {
    final pd = carDetails?.priceDiscovery.toDouble() ?? 0.0;
    final step = getIncrementStep(pd);

    if (yourOfferAmount.value - step >= currentHighestBidAmount.value) {
      yourOfferAmount.value -= step;
    }
  }

  // /// increase bid logic
  // void increaseBid() {
  //   double increment = isFirstClick ? 1000 : 1000;
  //   yourOfferAmount.value += increment;

  //   // After first click, switch to 1000 increment
  //   if (isFirstClick) {
  //     isFirstClick = false;
  //   }
  // }

  // void decreaseBid() {
  //   double decrement = isFirstClick ? 4000 : 1000;
  //   if (yourOfferAmount.value - decrement >= currentHighestBidAmount.value) {
  //     yourOfferAmount.value -= decrement;
  //   }
  // }

  /// Reset increments whenever sheet opens
  void resetBidIncrement() {
    isFirstClick = true;
  }

  // void setImageUrls(List<String> urls) {
  //   imageUrls.assignAll(urls);
  // }
  void setImageUrls(List<CarsListTitleAndImage> urls) {
    imageUrls.assignAll(urls);
  }

  void updateIndex(int index) {
    currentIndex.value = index;
  }

  // void startCountdown(DateTime endTime) {
  //   _timer?.cancel();
  //   _timer = Timer.periodic(const Duration(seconds: 1), (_) {
  //     final now = DateTime.now();
  //     final diff = endTime.difference(now);

  //     if (diff.isNegative) {
  //       remainingTime.value = "00h : 00m : 00s";
  //       _timer?.cancel();
  //     } else {
  //       final hours = diff.inHours.toString().padLeft(2, '0');
  //       final minutes = (diff.inMinutes % 60).toString().padLeft(2, '0');
  //       final seconds = (diff.inSeconds % 60).toString().padLeft(2, '0');
  //       remainingTime.value = "${hours}h : ${minutes}m : ${seconds}s";
  //     }
  //   });
  // }

  bool isValidComment(String? comment) {
    final val = comment?.trim().toLowerCase() ?? '';
    return val.isNotEmpty && val != 'n/a' && val != 'na';
  }

  void scrollToSection(String key) {
    final context = sectionKeys[key]?.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        alignment: 0.0,
      );
    }
    // Workaround: Scroll again with offset to account for pinned header height
    Future.delayed(const Duration(milliseconds: 450), () {
      scrollController.animateTo(
        scrollController.offset - 10, // Adjust based on your sticky headers
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  void scrollToSectionTab(String key) {
    final keyContext = sectionTabKeys[key]?.currentContext;
    if (keyContext != null) {
      final box = keyContext.findRenderObject() as RenderBox;
      final position = box.localToGlobal(Offset.zero, ancestor: null).dx;

      final screenWidth = Get.context!.size!.width;
      final scrollOffset = sectionTabScrollController.offset;

      // Center the selected tab
      final targetOffset =
          scrollOffset + position - (screenWidth / 2) + (box.size.width / 2);

      sectionTabScrollController.animateTo(
        targetOffset.clamp(
          sectionTabScrollController.position.minScrollExtent,
          sectionTabScrollController.position.maxScrollExtent,
        ),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  //  Listen and Update Bid locally
  void listenUpdatedBidAndChangeHighestBidLocally() {
    SocketService.instance.joinRoom('car-$carId');
    SocketService.instance.on(SocketEvents.bidUpdated, (data) {
      final String incomingCarId = data['carId'];
      final double newBid = (data['highestBid'] as num).toDouble();
      final String? bidderId = data['userId']?.toString();

      if (carDetails != null && carDetails!.id == incomingCarId) {
        currentHighestBidAmount.value = newBid;
        yourOfferAmount.value = newBid + 1000;
        // getIncrementStep(carDetails?.priceDiscovery.toDouble() ?? 1000);

        // To change the highest bid color
        if (bidderId != null && bidderId.isNotEmpty) {
          _highestBidderUserId.value = bidderId;
          if (_currentUserId != null && bidderId == _currentUserId) {
            _hasUserBidOnThisCar.value = true;
          }
        }
        // debugPrint('✅ Updated currentHighestBidAmount to $newBid');
      }
      debugPrint('📢 Bid update received: $data');
    });
  }

  //  Listen and Update Bid locally
  void listenOtobuyOfferAndChangeHighestBidLocally() {
    SocketService.instance.joinRoom(SocketEvents.otobuyCarsSectionRoom);
    SocketService.instance.on(SocketEvents.otobuyCarsSectionUpdated, (data) {
      final String action = data['action'] ?? '';

      // Handle different actions
      if (action == 'removed') {
        debugPrint('Car was removed from Otobuy section');
        // Handle removal logic if needed
        return;
      }

      if (action == 'sold') {
        final int soldAt = data['soldAt'] ?? 0;
        final String soldTo = data['soldTo'] ?? '';
        debugPrint('Car was sold at: $soldAt to: $soldTo');
        // Handle sold logic if needed
        return;
      }

      // Only update if otobuyOffer exists and is not null
      // final double newOtobuyOffer = (data['highestBid'] as num).toDouble();
      final double newOtobuyOffer = (data['otobuyOffer'] as num).toDouble();
      final String incomingCarId = data['id'];

      if (carDetails != null && carDetails!.id == incomingCarId) {
        currentHighestBidAmount.value = newOtobuyOffer;
        yourOfferAmount.value = newOtobuyOffer + 1000;
        // getIncrementStep(carDetails?.priceDiscovery.toDouble() ?? 1000);
        debugPrint(
          '✅ Updated currentHighestBidAmount to Otobuy Offer $newOtobuyOffer',
        );
      }
      debugPrint('📢 Otobuy offer update received: $data');
    });
  }

  // place bid
  Future<bool> placeBid({
    required String carId,
    required double newBidAmount,
  }) async {
    try {
      isPlaceBidButtonLoading.value = true;

      // final currentUserId = await SharedPrefsHelper.getString(
      //   SharedPrefsHelper.userIdKey,
      // );

      final response = await ApiService.post(
        endpoint: AppUrls.updateCarBid,
        body: {
          'carId': carId,
          'newBidAmount': newBidAmount,
          // 'userId': currentUserId,
          'auctionSection':
              AppConstants.homeScreenSections.liveBidsSectionScreen,
        },
      );

      if (response.statusCode == 200) {
        // final data = jsonDecode(response.body);
        // debugPrint("✅ Bid updated successfully: $data");
        ToastWidget.show(
          context: Get.context!,
          title: "You're Winning! 🏆",
          subtitle: "Great job! Currently, you're the highest bidder now.",
          toastDuration: 5,
          type: ToastType.success,
        );

        return true;
      } else if (response.statusCode == 403) {
        debugPrint("❌ Failed to update bid: ${response.body}");
        ToastWidget.show(
          context: Get.context!,
          title: "Bid must be higher than current highest bid.",
          type: ToastType.error,
        );
        return false;
      } else {
        debugPrint("❌ Failed to update bid: ${response.body}");
        ToastWidget.show(
          context: Get.context!,
          title: "Failed to place bid",
          type: ToastType.error,
        );
        return false;
      }
    } catch (e) {
      debugPrint("❗ Exception updating bid: $e");
      return false;
    } finally {
      isPlaceBidButtonLoading.value = false;
    }
  }

  // submit auto bid
  Future<void> submitAutoBidForLiveSection({
    required String carId,
    required int maxAmount,
  }) async {
    // final increment = getIncrementStep( carDetails?.priceDiscovery.toDouble() ?? 1000,  );
    final increment = 1000;
    try {
      Get.back();
      // final userId = await SharedPrefsHelper.getString(
      //   SharedPrefsHelper.userIdKey,
      // );
      final res = await ApiService.post(
        endpoint: AppUrls.submitAutoBidForLiveSection,
        body: {
          'carId': carId,
          // 'userId': userId,
          'autoBidAmount': maxAmount,
          'increment': increment,
          'auctionSection':
              AppConstants.homeScreenSections.liveBidsSectionScreen,
        },
      );

      if (res.statusCode == 200) {
        Get.dialog(
          CongratulationsDialogWidget(
            icon: Icons.gavel,
            iconSize: 25,
            title: "Auto Bid Submitted!",
            message: "Your auto bid has been set successfully.",
            buttonText: "OK",
            onButtonTap: () => Get.back(),
          ),
        );
      } else {
        ToastWidget.show(
          context: Get.context!,
          title: 'Failed to submit auto bid',
          type: ToastType.error,
        );
      }
    } catch (e) {
      debugPrint("❗ Exception updating bid: $e");
    }
  }

  //   pre bid for upcoming section
  Future<bool> preBid({
    required String carId,
    required double newBidAmount,
  }) async {
    try {
      isPreBidButtonLoading.value = true;

      // final currentUserId = await SharedPrefsHelper.getString(
      //   SharedPrefsHelper.userIdKey,
      // );

      final response = await ApiService.post(
        endpoint: AppUrls.updateCarBid,
        body: {
          'carId': carId,
          'newBidAmount': newBidAmount,
          // 'userId': currentUserId,
          'auctionSection':
              AppConstants.homeScreenSections.upcomingSectionScreen,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint("✅ Pre-Bid updated successfully: $data");
        Get.dialog(
          CongratulationsDialogWidget(
            icon: Icons.timer_outlined,
            iconColor: AppColors.grey,
            iconSize: 25,
            title: "Pre-Bid Set!",
            message: "Your pre-bid has been successfully recorded.",
            buttonText: "OK",
            onButtonTap: () => Get.back(),
          ),
        );

        return true;
      } else if (response.statusCode == 403) {
        debugPrint("❌ Failed to update pre-bid: ${response.body}");
        ToastWidget.show(
          context: Get.context!,
          title: "Bid must be higher than current pre-bid amount.",
          type: ToastType.error,
        );
        return false;
      } else {
        debugPrint("❌ Failed to update pre-bid: ${response.body}");
        ToastWidget.show(
          context: Get.context!,
          title: "Failed to place pre-bid",
          type: ToastType.error,
        );
        return false;
      }
    } catch (e) {
      debugPrint("❗ Exception updating pre-bid: $e");
      return false;
    } finally {
      isPreBidButtonLoading.value = false;
    }
  }

  // submit auto bid upto for upcoming section
  Future<void> submitAutoBidUpto({
    required String carId,
    required int maxAmount,
  }) async {
    // final increment = getIncrementStep( carDetails?.priceDiscovery.toDouble() ?? 1000,  );
    final increment = 1000;
    try {
      Get.back();
      // final userId = await SharedPrefsHelper.getString(
      //   SharedPrefsHelper.userIdKey,
      // );
      final res = await ApiService.post(
        endpoint: AppUrls.submitAutoBidForLiveSection,
        body: {
          'carId': carId,
          // 'userId': userId,
          'autoBidAmount': maxAmount,
          'increment': increment,
          'auctionSection':
              AppConstants.homeScreenSections.upcomingSectionScreen,
        },
      );

      if (res.statusCode == 200) {
        Get.dialog(
          CongratulationsDialogWidget(
            icon: Icons.gavel,
            iconSize: 25,
            title: "Auto Bid Submitted!",
            message: "Your auto bid has been set successfully.",
            buttonText: "OK",
            onButtonTap: () => Get.back(),
          ),
        );
      } else {
        ToastWidget.show(
          context: Get.context!,
          title: 'Failed to submit auto bid',
          type: ToastType.error,
        );
      }
    } catch (e) {
      debugPrint("❗ Exception updating bid: $e");
    }
  }

  // Buy now for otobuy section
  Future<bool> buyNow({required String carId}) async {
    try {
      isBuyNowButtonLoading.value = true;

      final currentUserId = await SharedPrefsHelper.getString(
        SharedPrefsHelper.userIdKey,
      );

      final response = await ApiService.post(
        endpoint: AppUrls.buyCar,
        body: {'carId': carId, 'userId': currentUserId},
      );

      if (response.statusCode == 200) {
        Get.dialog(
          CongratulationsDialogWidget(
            title: "🎉 You Bought the Car!",
            message: "Congratulations on your successful purchase!",
            buttonText: "Ok",
            onButtonTap: () {
              // handle navigation or close
              Get.back();
            },
          ),
        );

        return true;
      } else {
        debugPrint("❌ Failed to buy car: ${response.body}");
        ToastWidget.show(
          context: Get.context!,
          title: "Failed to buy car",
          type: ToastType.error,
        );
        return false;
      }
    } catch (e) {
      debugPrint("❗ Exception buying car: $e");
      return false;
    } finally {
      isBuyNowButtonLoading.value = false;
    }
  }

  // Make offer for otobuy section
  Future<bool> makeOffer({required String carId}) async {
    try {
      isMakeOfferButtonLoading.value = true;

      final currentUserId = await SharedPrefsHelper.getString(
        SharedPrefsHelper.userIdKey,
      );

      final response = await ApiService.post(
        endpoint: AppUrls.makeOfferForCar,
        body: {
          'carId': carId,
          'userId': currentUserId,
          'otobuyOffer': yourOfferAmount.value,
        },
      );

      if (response.statusCode == 200) {
        Get.dialog(
          CongratulationsDialogWidget(
            icon: Icons.emoji_events,
            iconColor: AppColors.yellow,
            iconSize: 25,
            title: "Offer Placed!",
            message: "Your offer has been successfully placed.",
            buttonText: "OK",
            onButtonTap: () {
              // handle navigation or close
              Get.back();
            },
          ),
        );

        return true;
      }

      // Try to read JSON error payload
      Map<String, dynamic>? data;
      try {
        data = jsonDecode(response.body);
      } catch (_) {}

      if (response.statusCode == 404) {
        debugPrint("Error: ${response.body}");
        final currentHighestOffer =
            (data?['currentHighestOffer'] as num?)?.toDouble() ?? 0.0;
        // final data = jsonDecode(response.body);
        // final double currentHighestOffer = double.parse(
        //   data['currentHighestOffer'],
        // );
        ToastWidget.show(
          context: Get.context!,
          title: "Cannot make offer less than highest offer.",
          subtitle:
              'Current highest offer price is Rs. ${NumberFormat.decimalPattern('en_IN').format(currentHighestOffer)}/-',
          toastDuration: 5,
          type: ToastType.error,
        );
        return false;
      }
      debugPrint("❌ Failed to make offer: ${response.body}");
      ToastWidget.show(
        context: Get.context!,
        title: "Failed to make offer",
        type: ToastType.error,
      );
      return false;
    } catch (e) {
      debugPrint("❗ Exception in make offer: $e");
      return false;
    } finally {
      isMakeOfferButtonLoading.value = false;
    }
  }

  // pick image for images section
  String pickImageForImagesSection(
    List<String>? primary, {
    List<List<String>?> alts = const [],
    required String fallbackUrl,
  }) {
    if (primary != null &&
        primary.isNotEmpty &&
        primary.first.trim().isNotEmpty) {
      return primary.first;
    }
    for (final list in alts) {
      if (list != null && list.isNotEmpty && list.first.trim().isNotEmpty) {
        return list.first;
      }
    }
    return fallbackUrl; // final fallback (e.g., picsum or your CDN placeholder)
  }

  /// Call this once (e.g., from the view) and pass the RxString that displays the timer.
  void watchAndCloseOnTimerEnd({
    required String carName,
    RxString? remainingAuctionTime,
    required String currentOpenSection,
  }) {
    // No timer? Nothing to watch.
    if (remainingAuctionTime == null) return;

    bool _isZero(String s) => s.trim() == '00h : 00m : 00s';

    void _maybeClose() {
      if (_closedOnce) return;
      _closedOnce = true;
      // If you’re using GetX navigation:
      Get.back<void>();

      // Show toast
      final homeController = Get.find<HomeController>();
      if (currentOpenSection == homeController.upcomingSectionScreen) {
        ToastWidget.show(
          context: Get.context!,
          title: "Car is live now.",
          type: ToastType.success,
        );
      }
      if (currentOpenSection == homeController.liveBidsSectionScreen) {
        ToastWidget.show(
          context: Get.context!,
          title: "Auction ended for $carName.",
          type: ToastType.error,
        );
      }
      // If you prefer Navigator:
      // if (Get.context != null) Navigator.of(Get.context!).maybePop();
    }

    // Immediate defensive check (in case it's already zero)
    if (_isZero(remainingAuctionTime.value)) {
      _maybeClose();
      return;
    }

    // Watch future changes
    _timerWatcher?.dispose(); // ensure only one watcher
    _timerWatcher = ever<String>(remainingAuctionTime, (val) {
      if (_isZero(val)) {
        _maybeClose();
      }
    });
  }

  Future<void> _initParticipationState() async {
    // 1) set current user id (if not already)
    _currentUserId ??= await SharedPrefsHelper.getString(
      SharedPrefsHelper.userIdKey,
    );

    // 2) highest bidder from carDetails (if your API returns it)
    final hbId = carDetails?.highestBidder.toString();
    if (hbId != null && hbId.isNotEmpty) {
      _highestBidderUserId.value = hbId;
    }

    // 3) decide if the user has bid on this car
    // Fast path: if user is current highest bidder, they obviously participated
    if (_currentUserId != null &&
        _currentUserId == _highestBidderUserId.value) {
      _hasUserBidOnThisCar.value = true;
      return;
    }

    // Pick ONE of the options below that fits your backend.
    _hasUserBidOnThisCar.value = await _checkHasUserBidFromBackend(
      carId: carId,
      userId: _currentUserId,
    );
  }

  /// Example backend checker (choose the API that matches your server)
  Future<bool> _checkHasUserBidFromBackend({
    required String carId,
    required String? userId,
  }) async {
    if (userId == null) return false;

    try {
      final url = AppUrls.getUserBidsForCar(userId: userId, carId: carId);
      final res = await ApiService.get(endpoint: url);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final List<dynamic> bids = data['bids'] ?? [];
        return bids.isNotEmpty;
      }

      return false;
    } catch (_) {
      return false;
    }
  }

  // Listen to Customer updated One Click Price realtime
  void _listenToCustomerUpdatedOneClickPriceRealtime() {
    SocketService.instance.on(SocketEvents.customerOneClickPriceUpdated, (
      data,
    ) {
      final String incomingCarId = '${data['carId']}';
      if (incomingCarId != carId) return; // ✅ SUPER IMPORTANT

      final double newPrice =
          (data['newCustomerOneClickPrice'] as num).toDouble();

      oneClickPriceAmount.value = newPrice;

      debugPrint('📢 One click price updated for $incomingCarId: $newPrice');
    });
  }

  // Update one click price on variable margin change
  void listenToVariableMarginChangeUpdatedOneClickPriceRealtime(
    RxDouble variableMargin,
  ) {
    SocketService.instance.on(SocketEvents.customerExpectedPriceUpdated, (
      data,
    ) {
      final String incomingCarId = '${data['carId']}';
      if (incomingCarId != carId) return; // ✅ SUPER IMPORTANT

      final double newVariableMargin =
          (data['newVariableMargin'] as num).toDouble();

      variableMargin.value = newVariableMargin;

      debugPrint(
        '📢 One click price updated because of margin change for $incomingCarId: $newVariableMargin',
      );
    });
  }

  @override
  void onClose() {
    // _timer?.cancel();
    _timerWatcher?.dispose();
    super.onClose();
  }
}
