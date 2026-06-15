import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:otobix/Models/cars_list_model.dart';
import 'package:otobix/Network/socket_service.dart';
import 'package:otobix/Utils/app_constants.dart';
import 'package:otobix/Utils/app_urls.dart';
import 'package:otobix/Utils/socket_events.dart';
import 'package:otobix/Widgets/toast_widget.dart';
import 'package:otobix/helpers/shared_prefs_helper.dart';
import '../Network/api_service.dart';

class UpcomingController extends GetxController {
  RxInt upcomingCarsCount = 0.obs;
  List<CarsListModel> upcomingCarsList = [];
  RxBool isLoading = false.obs;

  final RxSet<String> wishlistCarsIds = <String>{}.obs;

  // Countdown state
  final RxMap<String, RxString> remainingTimes = <String, RxString>{}.obs;
  final Map<String, Timer> _timers = {};

  // Who is currently winning each car (already suggested)
  final RxMap<String, String> highestBidders = <String, String>{}.obs;

  // Set of cars the current user has *ever* bid on
  final RxSet<String> carsUserHasBidOn = <String>{}.obs;

  // Cache to avoid re-hitting the API for the same car again
  final Map<String, bool> _userHasBidCache = <String, bool>{};

  String? currentUserId;

  @override
  void onInit() async {
    super.onInit();
    currentUserId =
        await SharedPrefsHelper.getString(SharedPrefsHelper.userIdKey) ?? '';

    // Fetch cars then wishlist, then apply hearts
    await fetchUpcomingCarsList();
    await _fetchAndApplyWishlist(userId: currentUserId!);

    // Listen to realtime wishlist updates
    _listenWishlistRealtime();
    _listenUpcomingCarsSectionRealtime();
    _listenUpdatedBidAndChangeHighestBidLocally();
    _listenToCustomerExpectedPriceRealtime();
  }

  final RxList<CarsListModel> filteredUpcomingCarsList = <CarsListModel>[].obs;

  // Live Cars List
  Future<void> fetchUpcomingCarsList() async {
    isLoading.value = true;
    try {
      final url = AppUrls.getCarsList(
        auctionStatus: AppConstants.auctionStatuses.upcoming,
      );
      final response = await ApiService.get(endpoint: url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final currentTime = DateTime.now();

        upcomingCarsList = List<CarsListModel>.from(
          (data as List).map(
            (car) => CarsListModel.fromJson(data: car, id: car['id']),
          ),
        );

        // Only keep cars with upcoming time
        filteredUpcomingCarsList.value =
            upcomingCarsList.where((car) {
              return car.upcomingUntil != null &&
                  car.upcomingUntil!.isAfter(currentTime);
            }).toList();

        await _seedParticipationForVisibleCars(
          filteredUpcomingCarsList.toList(),
        );

        upcomingCarsCount.value = filteredUpcomingCarsList.length;

        // 🔁 Single entry-point to handle ALL timers
        setupCountdowns(filteredUpcomingCarsList);

        // for (var car in upcomingCarsList) {
        //   await startAuctionCountdown(car);
        // }
        // for (var car in filteredUpcomingCarsList) {
        //   debugPrint('Upcoming cars list: ${car.toJson()}');
        // }
      } else {
        filteredUpcomingCarsList.value = [];
        upcomingCarsCount.value = 0;
        debugPrint('Failed to fetch data ${response.body}');
      }
    } catch (error) {
      debugPrint('Failed to fetch data: $error');
      filteredUpcomingCarsList.value = [];
      upcomingCarsCount.value = 0;
    } finally {
      isLoading.value = false;
    }
  }

  // Auction Timer
  Future<void> startAuctionCountdown(CarsListModel car) async {
    DateTime getAuctionEndTime() {
      final startTime = car.auctionStartTime ?? DateTime.now();
      final duration = Duration(
        hours: car.auctionDuration > 0 ? car.auctionDuration : 12,
        // hours: car.defaultAuctionTime,
      );
      return startTime.add(duration);
    }

    car.auctionTimer?.cancel(); // cancel previous

    car.auctionTimer = Timer.periodic(Duration(seconds: 1), (_) {
      final now = DateTime.now();
      final diff = getAuctionEndTime().difference(now);

      if (diff.isNegative) {
        // 🟥 Timer expired — reset startTime and countdown to now + 12 hours
        car.auctionStartTime = DateTime.now();
        car.auctionDuration = 12;

        final newDiff = Duration(hours: 12);
        // final newDiff = Duration(hours: 0);

        final hours = newDiff.inHours.toString().padLeft(2, '0');
        final minutes = (newDiff.inMinutes % 60).toString().padLeft(2, '0');
        final seconds = (newDiff.inSeconds % 60).toString().padLeft(2, '0');
        car.remainingAuctionTime.value =
            '${hours}h : ${minutes}m : ${seconds}s';
      } else {
        final hours = diff.inHours.toString().padLeft(2, '0');
        final minutes = (diff.inMinutes % 60).toString().padLeft(2, '0');
        final seconds = (diff.inSeconds % 60).toString().padLeft(2, '0');
        car.remainingAuctionTime.value =
            '${hours}h : ${minutes}m : ${seconds}s';
      }
    });
  }

  // Add Car To Wishlist
  Future<void> addCarToWishlist({required String carId}) async {
    final userId =
        await SharedPrefsHelper.getString(SharedPrefsHelper.userIdKey) ?? '';
    try {
      final url = AppUrls.addToWishlist;
      final response = await ApiService.post(
        endpoint: url,
        body: {'userId': userId, 'carId': carId},
      );

      if (response.statusCode == 200) {
        ToastWidget.show(
          context: Get.context!,
          title: 'Car added to favourites',
          type: ToastType.success,
        );
      } else {
        debugPrint('Failed to add car to favourites ${response.body}');
        ToastWidget.show(
          context: Get.context!,
          title: 'Failed to add car to favourites',
          type: ToastType.error,
        );
      }
    } catch (error) {
      debugPrint('Failed to add car to favourites: $error');
    }
  }

  Future<void> _fetchAndApplyWishlist({required String userId}) async {
    try {
      final url = AppUrls.getUserWishlist(userId: userId);
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

  /// Toggle (optimistic UI + rollback on error)
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

  /// Single entry-point: wire countdowns to the given cars list.
  /// - Cancels timers for cars that disappeared
  /// - (Re)starts timers for provided cars
  /// - Formats "15h : 22m : 44s"
  // ---- Countdown: single entry-point ----
  void setupCountdowns(List<CarsListModel> cars) {
    // 1) cancel timers for cars that disappeared from the provided list
    final newIds = cars.map((c) => c.id).toSet();
    final toRemove = _timers.keys.where((id) => !newIds.contains(id)).toList();
    for (final id in toRemove) {
      _timers[id]?.cancel();
      _timers.remove(id);
      // keep the RxString instance but show zero, so any screen still bound remains stable
      getCarRemainingTimeForNextScreen(id).value = '00h : 00m : 00s';
    }

    String fmt(Duration d) {
      String two(int n) => n.toString().padLeft(2, '0');
      return '${two(d.inHours)}h : ${two(d.inMinutes % 60)}m : ${two(d.inSeconds % 60)}s';
    }

    void startFor(CarsListModel car) {
      // ensure an Rx exists BEFORE any widget reads it
      remainingTimes.putIfAbsent(car.id, () => ''.obs);

      _timers[car.id]?.cancel();
      final until = car.upcomingUntil;
      if (until == null) {
        remainingTimes[car.id]!.value = 'N/A';
        return;
      }

      void tick() {
        final diff = until.difference(DateTime.now());
        if (diff.isNegative || diff.inSeconds <= 0) {
          remainingTimes[car.id]!.value = '00h : 00m : 00s';
          // ... (see section 2 for list mutations)
          return;
        }
        String two(int n) => n.toString().padLeft(2, '0');
        remainingTimes[car.id]!.value =
            '${two(diff.inHours)}h : ${two(diff.inMinutes % 60)}m : ${two(diff.inSeconds % 60)}s';
      }

      tick();
      _timers[car.id] = Timer.periodic(
        const Duration(seconds: 1),
        (_) => tick(),
      );
    }

    void startFor1(CarsListModel car) {
      _timers[car.id]?.cancel();

      final until = car.upcomingUntil; // your model’s target DateTime
      if (until == null) {
        getCarRemainingTimeForNextScreen(car.id).value = 'N/A';
        return;
      }

      void tick() {
        final diff = until.difference(DateTime.now());
        if (diff.isNegative || diff.inSeconds <= 0) {
          getCarRemainingTimeForNextScreen(car.id).value = '00h : 00m : 00s';
          _timers[car.id]?.cancel();
          _timers.remove(car.id);

          // Remove the car from the list when timer becomes less than zero
          remainingTimes.remove(car.id);
          filteredUpcomingCarsList.removeWhere((c) => c.id == car.id);
          upcomingCarsCount.value = filteredUpcomingCarsList.length;

          return;
        }
        getCarRemainingTimeForNextScreen(car.id).value = fmt(diff);
      }

      // Prime immediately, then every second
      tick();
      _timers[car.id] = Timer.periodic(
        const Duration(seconds: 1),
        (_) => tick(),
      );
    }

    // 2) ensure each car in the list has an active timer
    for (final car in cars) {
      startFor(car);
    }
  }

  // Listen to upcoming cars section realtime
  void _listenUpcomingCarsSectionRealtime() {
    SocketService.instance.joinRoom(SocketEvents.upcomingBidsSectionRoom);

    SocketService.instance.on(SocketEvents.upcomingBidsSectionUpdated, (
      data,
    ) async {
      final String action = '${data['action']}';

      if (action == 'removed') {
        final String id = '${data['id']}';

        // cancel controller-owned timer & remove readable time
        _timers[id]?.cancel();
        _timers.remove(id);
        getCarRemainingTimeForNextScreen(id).value = '00h : 00m : 00s';

        // remove from list
        filteredUpcomingCarsList.value =
            filteredUpcomingCarsList.where((c) => c.id != id).toList();

        // update count
        upcomingCarsCount.value = filteredUpcomingCarsList.length;
        return;
      }

      if (action == 'added') {
        final String id = '${data['id']}';
        final Map<String, dynamic> carJson = Map<String, dynamic>.from(
          data['car'] ?? const {},
        );
        final incoming = CarsListModel.fromJson(id: id, data: carJson);

        final idx = filteredUpcomingCarsList.indexWhere((c) => c.id == id);
        if (idx == -1) {
          filteredUpcomingCarsList.add(incoming);
          // Seed participation for just this car (if not cached)
          await _seedParticipationForVisibleCars([incoming]);
        } else {
          // replace model (no model timers to cancel anymore)
          filteredUpcomingCarsList[idx] = incoming;
          // Seed participation for just this car (if not cached)
          await _seedParticipationForVisibleCars([incoming]);
        }

        // refresh all timers via the single entry-point
        setupCountdowns(filteredUpcomingCarsList);

        // update count
        upcomingCarsCount.value = filteredUpcomingCarsList.length;
        return;
      }
    });
  }

  // Listen and Update Bid locally
  void _listenUpdatedBidAndChangeHighestBidLocally() {
    SocketService.instance.on(SocketEvents.bidUpdated, (data) {
      final String carId = data['carId'];
      final int highestBid = data['highestBid'];
      final String? bidderId = data['userId']?.toString();

      final index = filteredUpcomingCarsList.indexWhere((c) => c.id == carId);
      if (index != -1) {
        filteredUpcomingCarsList[index].highestBid.value =
            highestBid.toDouble(); // ✅ this is the real-time field
      }
      // 🔹 Track who is now highest bidder
      if (bidderId != null && bidderId.isNotEmpty) {
        highestBidders[carId] = bidderId;

        // 🔹 If it's the current user, mark that they have participated
        if (currentUserId != null && bidderId == currentUserId) {
          carsUserHasBidOn.add(carId);
        }
      }
      debugPrint('📢 Bid update received: $data');
    });
  }

  //  Seed Participation For Visible Cars
  Future<void> _seedParticipationForVisibleCars(
    List<CarsListModel> cars,
  ) async {
    if ((currentUserId ?? '').isEmpty) return;

    // Only check those we haven't cached yet
    final idsToCheck = <String>[];
    for (final c in cars) {
      if (!_userHasBidCache.containsKey(c.id)) {
        idsToCheck.add(c.id);
      }
    }
    if (idsToCheck.isEmpty) return;

    const int maxConcurrent = 6; // be nice to your API
    for (int i = 0; i < idsToCheck.length; i += maxConcurrent) {
      final chunk = idsToCheck.sublist(
        i,
        math.min(i + maxConcurrent, idsToCheck.length),
      );
      final results = await Future.wait(
        chunk.map(
          (id) => _checkHasUserBidFromBackend(carId: id, userId: currentUserId),
        ),
      );
      for (int j = 0; j < chunk.length; j++) {
        final id = chunk[j];
        final has = results[j];
        _userHasBidCache[id] = has; // memoize
        if (has) carsUserHasBidOn.add(id); // drive UI color
      }
    }
  }

  // Example backend checker (choose the API that matches your server)
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
        final has = bids.isNotEmpty;

        // ✅ Minimal fix: if the user's top bid equals the current highestBid we have,
        // mark them as the highest bidder so your helper shows GREEN after cold start.
        if (has) {
          double maxUserBid = 0;
          for (final b in bids) {
            // Adjust the key to whatever your API uses: amount / bidAmount / value
            final raw =
                (b is Map)
                    ? (b['amount'] ?? b['bidAmount'] ?? b['value'])
                    : null;
            double? v;
            if (raw is num) v = raw.toDouble();
            if (raw is String) v = double.tryParse(raw);
            if (v != null && v > maxUserBid) maxUserBid = v;
          }

          // Find the car we already loaded
          CarsListModel? car;
          try {
            car = filteredUpcomingCarsList.firstWhere((c) => c.id == carId);
          } catch (_) {
            try {
              car = upcomingCarsList.firstWhere((c) => c.id == carId);
            } catch (_) {}
          }

          if (car != null) {
            final currentHighest = car.highestBid.value.toDouble();
            // Use a tiny tolerance for rounding issues
            if ((currentHighest - maxUserBid).abs() < 0.5) {
              highestBidders[carId] =
                  userId; // ← this makes it GREEN on relaunch
            }
          }
        }

        return has;
      }

      return false;
    } catch (_) {
      return false;
    }
  }

  // Listen to Customer Expected Price realtime
  void _listenToCustomerExpectedPriceRealtime() {
    SocketService.instance.on(SocketEvents.customerExpectedPriceUpdated, (
      data,
    ) {
      final String carId = data['carId'].toString();
      final double newCustomerExpectedPrice =
          (data['newCustomerExpectedPrice'] as num).toDouble();
      final double variableMargin =
          (data['newVariableMargin'] as num).toDouble();

      // find the car in the list by its id
      final int index = filteredUpcomingCarsList.indexWhere(
        (car) => car.id == carId,
      );

      if (index != -1) {
        // ✅ update the RxDouble correctly
        filteredUpcomingCarsList[index].customerExpectedPrice.value =
            newCustomerExpectedPrice;
        filteredUpcomingCarsList[index].variableMargin.value = variableMargin;

        debugPrint(
          '📢 New expected price / variable margin received for car $carId: $newCustomerExpectedPrice',
        );
      } else {
        debugPrint('⚠️ carId $carId not found in filteredUpcomingCarsList');
      }
    });
  }

  // Future<bool> _checkHasUserBidFromBackend1({
  //   required String carId,
  //   required String? userId,
  // }) async {
  //   if (userId == null) return false;

  //   try {
  //     final url = AppUrls.getUserBidsForCar(userId: userId, carId: carId);
  //     final res = await ApiService.get(endpoint: url);

  //     if (res.statusCode == 200) {
  //       final data = jsonDecode(res.body);
  //       final List<dynamic> bids = data['bids'] ?? [];
  //       return bids.isNotEmpty;
  //     }

  //     return false;
  //   } catch (_) {
  //     return false;
  //   }
  // }

  @override
  void onClose() {
    // stop all timers and clear remaining times via the same single function
    setupCountdowns(const []);
    super.onClose();
  }

  // // Get remaining time for car details screen
  // RxString getCarRemainingTimeForNextScreen(String carId) =>
  //     remainingTimes.putIfAbsent(carId, () => ''.obs);
  RxString getCarRemainingTimeForNextScreen(String carId) {
    return remainingTimes[carId] ?? ''.obs; // do NOT insert into the map here
  }
}
