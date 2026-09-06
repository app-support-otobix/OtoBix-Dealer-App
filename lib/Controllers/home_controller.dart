import 'dart:async';
import 'dart:convert';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:otobix/Models/cars_list_model.dart';
import 'package:otobix/Network/socket_service.dart';
import 'package:otobix/Utils/app_colors.dart';
import 'package:otobix/Utils/app_constants.dart';
import 'package:otobix/Utils/app_urls.dart';
import 'package:otobix/Utils/socket_events.dart';
import 'package:otobix/Widgets/button_widget.dart';
import 'package:otobix/Widgets/toast_widget.dart';
import 'package:otobix/helpers/shared_prefs_helper.dart';
import 'package:otobix/helpers/dealer_home_search_sort_filter_helper.dart';
import '../Network/api_service.dart';

class HomeController extends GetxController {
  // List<CarsListModel> carsList = [];
  // RxBool isLoading = false.obs;
  final RxInt unreadNotificationsCount = 0.obs;

  final RxSet<String> wishlistCarsIds = <String>{}.obs;
  // // RxString remainingAuctionTime = '00h : 00m : 00s'.obs;
  // // Timer? _auctionTimer;

  TextEditingController searchController = TextEditingController();
  // TextEditingController minPriceController = TextEditingController();
  // TextEditingController maxPriceController = TextEditingController();
  TextEditingController searchStateController = TextEditingController();

  // Screen types
  // final String liveBidsSectionScreen = 'live_bids';
  final String liveBidsSectionScreen = 'live';
  final String upcomingSectionScreen = 'upcoming';
  final String otobuySectionScreen = 'otobuy';
  final String marketplaceSectionScreen = 'marketplace';
  final String defaultSectionScreen = 'default';

  // Search functionality
  final RxString searchText = ''.obs;
  void changeSearchText(String v) => searchText.value = v;

  final selectedSegmentNotifier = ValueNotifier<String>('live');

  // // final segments =
  // //     {'live': 'Live (23)', 'ocb': 'OCB (10)', 'marketplace': 'Marketplace (5)'}.obs;

  RxString selectedSegment = 'live'.obs;

  // RxString selectedCity = 'All States'.obs;

  // final List<String> cities = ['All States', ...AppConstants.indianStates];

  // // TRANSMISSION
  // final List<String> transmissionTypes = const [
  //   'Manual',
  //   'Automatic',
  //   'AMT',
  //   'CVT',
  //   'DCT',
  // ];
  // final RxList<String> selectedTransmissionFilter = <String>[].obs;

  // // KMS
  // final double minKms = 0; // in kms
  // final double maxKms = 300000; // 0–300k kms
  // final Rx<RangeValues> selectedKmsRange = const RangeValues(0, 300000).obs;
  // final TextEditingController minKmsController = TextEditingController(
  //   text: '0',
  // );
  // final TextEditingController maxKmsController = TextEditingController(
  //   text: '300000',
  // );

  // // OWNERSHIP (Serial No.)
  // final int minOwnership = 1;
  // final int maxOwnership = 5;
  // final Rx<RangeValues> selectedOwnershipRange =
  //     const RangeValues(1, 5).obs; // integers only
  // final TextEditingController minOwnershipController = TextEditingController(
  //   text: '1',
  // );
  // final TextEditingController maxOwnershipController = TextEditingController(
  //   text: '5',
  // );

  // Optional: central apply/reset helpers
  // void resetFilters() {
  //   selectedYearFilter.value = 2022;
  //   selectedMakeFilter.value = '';
  //   selectedModelFilter.value = '';
  //   selectedVariantFilter.value = '';

  //   // new ones
  //   selectedTransmissionFilter.clear();

  //   selectedKmsRange.value = const RangeValues(0, 300000);
  //   minKmsController.text = '0';
  //   maxKmsController.text = '300000';

  //   selectedOwnershipRange.value = const RangeValues(1, 5);
  //   minOwnershipController.text = '1';
  //   maxOwnershipController.text = '5';

  //   // keep your existing price reset if needed:
  //   // selectedPriceRange.value = RangeValues(minPrice, maxPrice);
  //   // minPriceController.text = minPrice.toInt().toString();
  //   // maxPriceController.text = maxPrice.toInt().toString();
  // }

  // void resetFilters() {
  //   // Fuel
  //   selectedFuelTypesFilter.clear();

  //   // Price (Lacs)
  //   selectedPriceRange.value = RangeValues(minPrice, maxPrice);
  //   minPriceController.text = minPrice.toInt().toString();
  //   maxPriceController.text = maxPrice.toInt().toString();

  //   // Year / Make / Model / Variant
  //   selectedYearFilter.value = null; // or 0 if you prefer
  //   selectedMakeFilter.value = '';
  //   selectedModelFilter.value = '';
  //   selectedVariantFilter.value = '';

  //   // Transmission
  //   selectedTransmissionFilter.clear();

  //   // KMs
  //   selectedKmsRange.value = RangeValues(minKms, maxKms);
  //   minKmsController.text = minKms.toInt().toString();
  //   maxKmsController.text = maxKms.toInt().toString();

  //   // Ownership
  //   selectedOwnershipRange.value = RangeValues(
  //     minOwnership.toDouble(),
  //     maxOwnership.toDouble(),
  //   );
  //   minOwnershipController.text = minOwnership.toString();
  //   maxOwnershipController.text = maxOwnership.toString();

  //   // (If you use state filter)
  //   // selectedCity.value = 'All States';

  //   // Re-apply (will effectively clear)
  //   // applyFilters();
  // }

  // void applyFilters({required List<CarsListModel> carsList}) {
  //   // 1) Start from whatever list you show before filtering, e.g. fetched list:
  //   // final base = carsList; // or marketplace/upcoming/otobuy

  //   // 2) Search (if you do search first)
  //   // final searched = DealerHomeSearchSortFilterHelper.searchCarsBySearchText(
  //   //   carsList: base,
  //   //   searchText: searchText.value, // your existing RxString
  //   // );

  //   // 3) (Optional) State filter if you have it
  //   // final byState = DealerHomeSearchSortFilterHelper.filterCarsByState(
  //   //   carsList: searched,
  //   //   selectedState: selectedCity.value, // 'All States' => no-op
  //   //   // stateOf: (c) => c.registrationState ?? c.inspectionLocation ?? '',
  //   // );

  //   // 4) Apply ALL filters at once
  //   final filtered = DealerHomeSearchSortFilterHelper.applyAllFilters(
  //     source: carsList,

  //     // Fuel
  //     fuelTypes: selectedFuelTypesFilter.toSet(),

  //     // Price (Lacs)
  //     priceRangeLacs: selectedPriceRange.value,
  //     priceOf: (c) => (c.highestBid.toDouble()), // LIVE BIDS example
  //     // For marketplace:
  //     // priceOf: (c) => (c.priceDiscovery ?? 0),
  //     // For upcoming:
  //     // priceOf: (c) => (c.upcomingPrice ?? 0),

  //     // Year
  //     manufacturingYear:
  //         selectedYearFilter.value == null || selectedYearFilter.value == 0
  //             ? null
  //             : selectedYearFilter.value,

  //     // Make/Model/Variant
  //     make: selectedMakeFilter.value,
  //     model: selectedModelFilter.value,
  //     variant: selectedVariantFilter.value,

  //     // Transmission
  //     transmissions: selectedTransmissionFilter.toSet(),

  //     // KMs
  //     kmsRange: selectedKmsRange.value,

  //     // Ownership (serial no.)
  //     ownershipRange: selectedOwnershipRange.value,
  //   );

  //   // 5) (Optional) Sort using your existing sort helper
  //   final finalList = DealerHomeSearchSortFilterHelper.sortCars(
  //     carsList: filtered,
  //     priceOf:
  //         (c) =>
  //             (c.highestBid.toDouble()), // keep consistent with applyAllFilters
  //   );

  //   // 6) Assign to the list your page renders (e.g., an RxList you show in Obx)
  //   visibleLiveBidsCarsList.value = finalList;
  // }

  // void applyFilters() {
  // Call your fetch/filter logic here.
  // Example predicate if you filter locally:
  /*
  final cars = allCars.where((c) {
    final okFuel = selectedFuelTypesFilter.isEmpty || selectedFuelTypesFilter.contains(c.fuelType);
    final okPrice = c.priceLacs >= selectedPriceRange.value.start && c.priceLacs <= selectedPriceRange.value.end;
    final okYear  = selectedYearFilter.value == null ? true : c.year == selectedYearFilter.value;
    final okMake  = selectedMakeFilter.value.isEmpty ? true : c.make == selectedMakeFilter.value;
    final okModel = selectedModelFilter.value.isEmpty ? true : c.model == selectedModelFilter.value;
    final okVar   = selectedVariantFilter.value.isEmpty ? true : c.variant == selectedVariantFilter.value;

    final okTrans = selectedTransmissionFilter.isEmpty || selectedTransmissionFilter.contains(c.transmission);
    final okKms   = c.kms >= selectedKmsRange.value.start && c.kms <= selectedKmsRange.value.end;

    final owners  = (c.ownershipSerial ?? 1).toDouble();
    final okOwn   = owners >= selectedOwnershipRange.value.start && owners <= selectedOwnershipRange.value.end;

    return okFuel && okPrice && okYear && okMake && okModel && okVar && okTrans && okKms && okOwn;
  }).toList();

  filteredCars.assignAll(cars);
  */
  // }

  String formatKm(num n) {
    if (n >= 1000000) {
      return '${(n / 1000000).toStringAsFixed((n % 1000000) == 0 ? 0 : 1)}m';
    }
    if (n >= 1000) {
      return '${(n / 1000).toStringAsFixed((n % 1000) == 0 ? 0 : 1)}k';
    }
    return n.toStringAsFixed(0);
  }

  @override
  void onInit() async {
    super.onInit();

    DealerHomeSearchSortFilterHelper.initStates(AppConstants.indianStates);

    await getUnreadNotificationsCount();
    _listenAndUpdateUnreadNotificationsCount();
    final userId =
        await SharedPrefsHelper.getString(SharedPrefsHelper.userIdKey) ?? '';

    // 1) Join the user room so server can target this device
    SocketService.instance.socket.emit(
      SocketEvents.joinRoom,
      '${SocketEvents.userRoom}$userId',
    );

    // 2) Fetch cars then wishlist, then apply hearts
    // await fetchLiveCarsList();
    // await _fetchAndApplyWishlist(userId: userId);

    // 3) Listen to realtime wishlist updates
    _listenWishlistRealtime();

    // 4) 🌟 LIVE LIST: join room + listen for patches
    // _listenLiveBidsSectionRealtime();

    //Other listeners
    // listenUpdatedBidAndChangeHighestBidLocally();
    listenToAuctionWonEvent();
    // Listen to changes in ValueNotifier
    selectedSegmentNotifier.addListener(() {
      selectedSegment.value = selectedSegmentNotifier.value;
    });

    // Initialize controllers with default values
    // minPriceController.text = selectedPriceRange.value.start.toInt().toString();
    // maxPriceController.text = selectedPriceRange.value.end.toInt().toString();
  }

  // var selectedMakeFilter = Rx<String?>(null);
  // var selectedModelFilter = Rx<String?>(null);
  // var selectedVariantFilter = Rx<String?>(null);
  // var selectedYearFilter = Rx<int?>(null);

  // final RxList<String> selectedFuelTypesFilter = <String>[].obs;

  // final Rx<RangeValues> selectedPriceRange = RangeValues(0, 20).obs; // in Lacs
  // final double minPrice = 0;
  // final double maxPrice = 50; // Lacs

  // final List<String> makesListFilter = ['Toyota', 'Honda', 'Hyundai'];

  // final Map<String, List<String>> modelsListFilter = {
  //   'Toyota': ['Corolla', 'Yaris'],
  //   'Honda': ['Civic', 'City'],
  //   'Hyundai': ['i20', 'Creta'],
  // };

  // final Map<String, List<String>> variantsListFilter = {
  //   'Corolla': ['XLi', 'GLi'],
  //   'Yaris': ['1.3L', '1.5L'],
  //   'Civic': ['Oriel', 'Turbo'],
  //   'City': ['Aspire', 'i-VTEC'],
  //   'i20': ['Sportz', 'Asta'],
  //   'Creta': ['EX', 'SX'],
  // };

  // final RxList<CarsListModel> filteredCars = <CarsListModel>[].obs;

  // Live Bids Cars List
  // Future<void> fetchLiveCarsList() async {
  //   isLoading.value = true;
  //   try {
  //     final url = AppUrls.getCarsList(
  //       auctionStatus: AppConstants.auctionStatuses.live,
  //     );
  //     final response = await ApiService.get(endpoint: url);

  //     if (response.statusCode == 200) {
  //       final data = jsonDecode(response.body);

  //       final currentTime = DateTime.now();

  //       carsList = List<CarsListModel>.from(
  //         (data as List).map(
  //           (car) => CarsListModel.fromJson(data: car, id: car['id']),
  //         ),
  //       );

  //       liveCarsCount.value = carsList.length;
  //       // Temp for now
  //       upcomingCarsCount.value = carsList.length;
  //       otoBuyCarsCount.value = carsList.length;
  //       marketplaceCarsCount.value = carsList.length;
  //       ///////////////

  //       // filteredCars.value = carsList;
  //       // Only keep cars with future auctionEndTime
  //       filteredCars.value =
  //           carsList.where((car) {
  //             return car.auctionEndTime != null &&
  //                 car.auctionStatus == AppConstants.auctionStatuses.live &&
  //                 car.auctionEndTime!.isAfter(currentTime);
  //           }).toList();

  //       for (var car in carsList) {
  //         await startAuctionCountdown(car);
  //       }

  //       debugPrint('Cars List Fetched Successfully');
  //       // debugPrint(carsList[1].toJson().toString());
  //     } else {
  //       filteredCars.value = [];
  //       debugPrint('Failed to fetch data ${response.body}');
  //     }
  //   } catch (error) {
  //     debugPrint('Failed to fetch data: $error');
  //     filteredCars.value = [];
  //   } finally {
  //     isLoading.value = false;
  //   }
  // }

  // Listen and Update Bid locally
  // void listenUpdatedBidAndChangeHighestBidLocally() {
  //   SocketService.instance.on(SocketEvents.bidUpdated, (data) {
  //     final String carId = data['carId'];
  //     final int highestBid = data['highestBid'];

  //     final index = filteredCars.indexWhere((c) => c.id == carId);
  //     if (index != -1) {
  //       filteredCars[index].highestBid.value =
  //           highestBid.toDouble(); // ✅ this is the real-time field
  //     }
  //     debugPrint('📢 Bid update received: $data');
  //   });
  // }

  // Auction Timer
  // Future<void> startAuctionCountdown(CarsListModel car) async {
  //   DateTime getAuctionEndTime() {
  //     // ✅ Prefer server's end time when present
  //     if (car.auctionEndTime != null) return car.auctionEndTime!;
  //     final startTime = car.auctionStartTime ?? DateTime.now();
  //     final duration = Duration(
  //       hours: car.auctionDuration > 0 ? car.auctionDuration : 12,
  //     );
  //     return startTime.add(duration);
  //   }

  //   car.auctionTimer?.cancel(); // cancel previous if any

  //   car.auctionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
  //     final now = DateTime.now();
  //     final endAt = getAuctionEndTime();
  //     final diff = endAt.difference(now);

  //     if (diff.isNegative) {
  //       // stop at zero instead of silently rolling another 12h
  //       car.remainingAuctionTime.value = '00h : 00m : 00s';
  //       car.auctionTimer?.cancel();
  //       return;
  //     }

  //     final hours = diff.inHours.toString().padLeft(2, '0');
  //     final minutes = (diff.inMinutes % 60).toString().padLeft(2, '0');
  //     final seconds = (diff.inSeconds % 60).toString().padLeft(2, '0');
  //     car.remainingAuctionTime.value = '${hours}h : ${minutes}m : ${seconds}s';
  //   });
  // }

  // Future<void> startAuctionCountdown1(CarsListModel car) async {
  //   DateTime getAuctionEndTime() {
  //     // ✅ Prefer server's end time when present
  //     if (car.auctionEndTime != null) return car.auctionEndTime!;

  //     final startTime = car.auctionStartTime ?? DateTime.now();
  //     final duration = Duration(
  //       hours: car.auctionDuration > 0 ? car.auctionDuration : 12,
  //       // hours: car.defaultAuctionTime,
  //     );
  //     return startTime.add(duration);
  //   }

  //   car.auctionTimer?.cancel(); // cancel previous

  //   car.auctionTimer = Timer.periodic(Duration(seconds: 1), (_) {
  //     final now = DateTime.now();
  //     final diff = getAuctionEndTime().difference(now);

  //     if (diff.isNegative) {
  //       // 🟥 Timer expired — reset startTime and countdown to now + 12 hours
  //       car.auctionStartTime = DateTime.now();
  //       car.auctionDuration = 12;

  //       final newDiff = Duration(hours: 12);
  //       // final newDiff = Duration(hours: 0);

  //       final hours = newDiff.inHours.toString().padLeft(2, '0');
  //       final minutes = (newDiff.inMinutes % 60).toString().padLeft(2, '0');
  //       final seconds = (newDiff.inSeconds % 60).toString().padLeft(2, '0');
  //       car.remainingAuctionTime.value =
  //           '${hours}h : ${minutes}m : ${seconds}s';
  //     } else {
  //       final hours = diff.inHours.toString().padLeft(2, '0');
  //       final minutes = (diff.inMinutes % 60).toString().padLeft(2, '0');
  //       final seconds = (diff.inSeconds % 60).toString().padLeft(2, '0');
  //       car.remainingAuctionTime.value =
  //           '${hours}h : ${minutes}m : ${seconds}s';
  //     }
  //   });
  // }

  @override
  void onClose() {
    searchController.dispose();
    // for (var car in carsList) {
    //   car.auctionTimer?.cancel();
    // }
    super.onClose();
  }

  // Listen to Auction Won Event
  void listenToAuctionWonEvent() async {
    final currentUserId = await SharedPrefsHelper.getString(
      SharedPrefsHelper.userIdKey,
    );
    SocketService.instance.on(SocketEvents.auctionEnded, (data) {
      // Defensive parsing
      final registrationYear = '${data['registrationYear'] ?? ''}';
      final winnerId = '${data['winnerId'] ?? ''}';
      // final winnerName = '${data['winnerName'] ?? ''}';
      final carName = '${data['carName'] ?? ''}';
      final carId = '${data['carId'] ?? ''}';
      final num bidAmountNum =
          (data['bidAmount'] is num)
              ? data['bidAmount'] as num
              : num.tryParse('${data['bidAmount']}') ?? 0;
      final biddersList =
          (data['biddersList'] as List? ?? const []).map((e) => '$e').toSet();

      final bool isWinner = winnerId == currentUserId;
      final bool isLoser = !isWinner && biddersList.contains(currentUserId);

      // Format INR nicely
      final amount = NumberFormat.currency(
        locale: 'en_IN',
        symbol: '₹',
        decimalDigits: 0,
      ).format(bidAmountNum);

      debugPrint(data.toString());

      if (isWinner) {
        // 🎉 Show dialog if the current user won
        showWinDialog();
        return;
      }
      if (isLoser) {
        final ctx = Get.overlayContext ?? Get.context;
        if (ctx != null) {
          ToastWidget.show(
            context: ctx,
            toastDuration: 10,
            title:
                'You did not win the Auction for ${registrationYear.isNotEmpty ? '$registrationYear ' : ''}${carName.isEmpty ? 'car $carId' : carName}.'
                'The Winning Bid was Rs. $amount',
            type: ToastType.error,
          );
        }
      }
    });
  }

  // Show dialog if the current user won
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
                    text: "Ok",
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

  // Unread Notifications Count
  Future<void> getUnreadNotificationsCount() async {
    try {
      final url = AppUrls.userNotificationsUnreadNotificationsCount;
      final response = await ApiService.get(endpoint: url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        unreadNotificationsCount.value = data['unreadCount'] ?? 0;
        // debugPrint(
        //   'Unread Notifications Count: ${unreadNotificationsCount.value}',
        // );
      } else {
        debugPrint(
          'Failed to fetch unread notifications count ${response.body}',
        );
      }
    } catch (error) {
      debugPrint('Failed to fetch unread notifications count: $error');
    }
  }

  // Notifications listener
  void _listenAndUpdateUnreadNotificationsCount() async {
    final userId =
        await SharedPrefsHelper.getString(SharedPrefsHelper.userIdKey) ?? '';
    SocketService.instance.joinRoom(
      SocketEvents.userNotificationsRoom + userId,
    );
    SocketService.instance.on(SocketEvents.userNotificationCreated, (data) {
      unreadNotificationsCount.value = _extractUnreadNotificationsCount(data);
    });
    SocketService.instance.on(SocketEvents.userNotificationMarkedAsRead, (
      data,
    ) {
      unreadNotificationsCount.value = _extractUnreadNotificationsCount(data);
    });
    SocketService.instance.on(SocketEvents.userAllNotificationsMarkedAsRead, (
      data,
    ) {
      unreadNotificationsCount.value = _extractUnreadNotificationsCount(data);
    });
  }

  // Helper Function to Extract Unread Count
  int _extractUnreadNotificationsCount(dynamic payload) {
    try {
      // Normalize to Map<String, dynamic>
      final Map<String, dynamic> map =
          payload is Map
              ? Map<String, dynamic>.from(payload)
              : payload is String
              ? (jsonDecode(payload) as Map<String, dynamic>)
              : <String, dynamic>{};

      final dynamic v = map['unreadNotificationsCount'];

      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    } catch (_) {
      return 0;
    }
  }

  // Add Car To Wishlist
  // Future<void> addCarToWishlist({required String carId}) async {
  //   final userId =
  //       await SharedPrefsHelper.getString(SharedPrefsHelper.userIdKey) ?? '';
  //   try {
  //     final url = AppUrls.addToWishlist;
  //     final response = await ApiService.post(
  //       endpoint: url,
  //       body: {'userId': userId, 'carId': carId},
  //     );

  //     if (response.statusCode == 200) {
  //       ToastWidget.show(
  //         context: Get.context!,
  //         title: 'Car added to favourites',
  //         type: ToastType.success,
  //       );
  //     } else {
  //       debugPrint('Failed to add car to favourites ${response.body}');
  //       ToastWidget.show(
  //         context: Get.context!,
  //         title: 'Failed to add car to favourites',
  //         type: ToastType.error,
  //       );
  //     }
  //   } catch (error) {
  //     debugPrint('Failed to add car to favourites: $error');
  //   }
  // }

  Future<void> _fetchAndApplyWishlist({required String userId}) async {
    try {
      final url = AppUrls.getUserWishlist;
      final response = await ApiService.get(endpoint: url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> ids = data['wishlist'] ?? [];

        wishlistCarsIds
          ..clear()
          ..addAll(ids.map((e) => '$e'));
      }
    } catch (e) {
      debugPrint('_fetchAndApplyWishlist error: $e');
    }
  }

  void _listenWishlistRealtime() {
    SocketService.instance.on(SocketEvents.wishlistUpdated, (data) {
      final String action = '${data['action']}';
      final String carId = '${data['carId']}';

      if (action == 'add') {
        wishlistCarsIds.add(carId);
      } else if (action == 'remove') {
        wishlistCarsIds.remove(carId);
      }
    });
  }

  // /// Toggle (optimistic UI + rollback on error)
  Future<void> toggleFavorite(CarsListModel car) async {
    final userId =
        await SharedPrefsHelper.getString(SharedPrefsHelper.userIdKey) ?? '';
    final isFav = wishlistCarsIds.contains(car.id);

    // optimistic
    if (isFav) {
      wishlistCarsIds.remove(car.id);
    } else {
      wishlistCarsIds.add(car.id);
    }

    try {
      if (isFav) {
        final res = await ApiService.post(
          endpoint: AppUrls.removeFromWishlist,
          body: {'userId': userId, 'carId': car.id},
        );
        if (res.statusCode != 200) throw Exception(res.body);
        ToastWidget.show(
          context: Get.context!,
          title: 'Removed from wishlist',
          type: ToastType.error,
        );
      } else {
        final res = await ApiService.post(
          endpoint: AppUrls.addToWishlist,
          body: {'userId': userId, 'carId': car.id},
        );
        if (res.statusCode != 200) throw Exception(res.body);
        ToastWidget.show(
          context: Get.context!,
          title: 'Added to wishlist',
          type: ToastType.success,
        );
      }
      // Server will also emit wishlist:updated → sync other devices.
    } catch (e) {
      debugPrint('Failed to update wishlist: $e');
      // rollback
      if (isFav) {
        wishlistCarsIds.add(car.id);
      } else {
        wishlistCarsIds.remove(car.id);
      }
      ToastWidget.show(
        context: Get.context!,
        title: 'Failed to update wishlist',
        type: ToastType.error,
      );
    }
  }

  // // Listen to live bids section realtime
  // void _listenLiveBidsSectionRealtime() {
  //   SocketService.instance.joinRoom(SocketEvents.liveBidsSectionRoom);

  //   SocketService.instance.on(SocketEvents.liveBidsSectionUpdated, (
  //     data,
  //   ) async {
  //     final String action = '${data['action']}';

  //     if (action == 'removed') {
  //       final String id = '${data['id']}';
  //       // cancel its timer to avoid leaks
  //       final idx = filteredCars.indexWhere((c) => c.id == id);
  //       if (idx != -1) {
  //         filteredCars[idx].auctionTimer?.cancel();
  //       }
  //       filteredCars.value = filteredCars.where((c) => c.id != id).toList();
  //       return;
  //     }

  //     if (action == 'added' || action == 'updated') {
  //       final String id = '${data['id']}';
  //       final Map<String, dynamic> carJson = Map<String, dynamic>.from(
  //         data['car'] ?? const {},
  //       );

  //       final incoming = CarsListModel.fromJson(id: id, data: carJson);

  //       final idx = filteredCars.indexWhere((c) => c.id == id);
  //       if (idx == -1) {
  //         // brand-new → add, then start its timer
  //         filteredCars.add(incoming);
  //         await startAuctionCountdown(incoming);
  //       } else {
  //         // existing → cancel old timer, replace model, restart timer
  //         filteredCars[idx].auctionTimer?.cancel();
  //         filteredCars[idx] = incoming;
  //         await startAuctionCountdown(filteredCars[idx]);
  //       }
  //       return;
  //     }
  //   });
  // }

  // void _listenLiveBidsSectionRealtime() {
  //   SocketService.instance.joinRoom(SocketEvents.liveBidsSectionRoom);
  //   SocketService.instance.on(SocketEvents.liveBidsSectionUpdated, (data) {
  //     if (data['action'] == 'removed') {
  //       filteredCars.value =
  //           filteredCars.where((car) {
  //             return car.id != data['id'];
  //           }).toList();
  //     } else if (data['action'] == 'added') {
  //       final String id = '${data['id']}';

  //       // Expecting the server to send a listing-shaped map under 'car'
  //       final Map<String, dynamic> carJson = Map<String, dynamic>.from(
  //         data['car'] ?? const {},
  //       );

  //       // Build model using your factory
  //       final newModel = CarsListModel.fromJson(id: id, data: carJson);

  //       // Append if missing, otherwise update in place
  //       final idx = filteredCars.indexWhere((c) => c.id == id);
  //       if (idx == -1) {
  //         filteredCars.add(newModel);
  //       } else {
  //         filteredCars[idx] = newModel; // replace to reflect latest fields
  //       }
  //       return;
  //     }
  //     debugPrint('Live Bids Section Updated: $data');
  //   });
  // }
}














 // final List<CarModel> carsList1 = [
  //   CarModel(
  //     imageUrl: AppImages.tataNexon1,
  //     name: 'Tata Nexon',
  //     price: 1200000,
  //     year: 2021,
  //     kmDriven: 15000,
  //     fuelType: 'Petrol',
  //     location: 'Mumbai',
  //     isInspected: true,
  //     imageUrls: [
  //       AppImages.tataNexon1,
  //       AppImages.tataNexon2,
  //       AppImages.tataNexon3,
  //     ],
  //   ),
  //   CarModel(
  //     imageUrl: AppImages.marutiSuzukiBaleno1,
  //     name: 'Maruti Suzuki Baleno',
  //     price: 850000,
  //     year: 2020,
  //     kmDriven: 22000,
  //     fuelType: 'Petrol',
  //     location: 'Delhi',
  //     imageUrls: [
  //       AppImages.marutiSuzukiBaleno1,
  //       AppImages.marutiSuzukiBaleno2,
  //       AppImages.marutiSuzukiBaleno3,
  //     ],
  //   ),
  //   CarModel(
  //     imageUrl: AppImages.hyundaiCreta1,
  //     name: 'Hyundai Creta',
  //     price: 1600000,
  //     year: 2022,
  //     kmDriven: 8000,
  //     fuelType: 'Diesel',
  //     location: 'Bengaluru',
  //     isInspected: true,
  //     imageUrls: [
  //       AppImages.hyundaiCreta1,
  //       AppImages.hyundaiCreta2,
  //       AppImages.hyundaiCreta3,
  //     ],
  //   ),
  //   CarModel(
  //     imageUrl: AppImages.marutiSuzukiSwift1,
  //     name: 'Maruti Suzuki Swift',
  //     price: 700000,
  //     year: 2019,
  //     kmDriven: 30000,
  //     fuelType: 'Petrol',
  //     location: 'Pune',
  //     isInspected: true,
  //     imageUrls: [AppImages.marutiSuzukiSwift1],
  //   ),
  //   CarModel(
  //     imageUrl: AppImages.mahindraThar1,
  //     name: 'Mahindra Thar',
  //     price: 1450000,
  //     year: 2021,
  //     kmDriven: 12000,
  //     fuelType: 'Diesel',
  //     location: 'Chandigarh',
  //     imageUrls: [
  //       AppImages.mahindraThar1,
  //       AppImages.mahindraThar2,
  //       AppImages.mahindraThar3,
  //     ],
  //   ),
  //   CarModel(
  //     imageUrl: AppImages.tataHarrier1,
  //     name: 'Tata Harrier',
  //     price: 1750000,
  //     year: 2022,
  //     kmDriven: 5000,
  //     fuelType: 'Diesel',
  //     location: 'Hyderabad',
  //     imageUrls: [AppImages.tataHarrier1],
  //   ),
  //   CarModel(
  //     imageUrl: AppImages.kiaSeltos1,
  //     name: 'Kia Seltos',
  //     price: 1400000,
  //     year: 2020,
  //     kmDriven: 18000,
  //     fuelType: 'Petrol',
  //     location: 'Ahmedabad',
  //     isInspected: true,
  //     imageUrls: [
  //       AppImages.kiaSeltos1,
  //       AppImages.kiaSeltos2,
  //       AppImages.kiaSeltos3,
  //     ],
  //   ),
  //   CarModel(
  //     imageUrl: AppImages.hondaCity1,
  //     name: 'Honda City',
  //     price: 1100000,
  //     year: 2019,
  //     kmDriven: 35000,
  //     fuelType: 'Petrol',
  //     location: 'Kolkata',
  //     imageUrls: [AppImages.hondaCity1],
  //   ),
  //   CarModel(
  //     imageUrl: AppImages.jeepCompass1,
  //     name: 'Jeep Compass',
  //     price: 1850000,
  //     year: 2021,
  //     kmDriven: 10000,
  //     fuelType: 'Diesel',
  //     location: 'Jaipur',
  //     isInspected: true,
  //     imageUrls: [AppImages.jeepCompass1],
  //   ),
  //   CarModel(
  //     imageUrl: AppImages.renaultKwid1,
  //     name: 'Renault Kwid',
  //     price: 450000,
  //     year: 2018,
  //     kmDriven: 42000,
  //     fuelType: 'Petrol',
  //     location: 'Surat',
  //     isInspected: true,
  //     imageUrls: [AppImages.renaultKwid1],
  //   ),
  // ];