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

class LiveBidsController extends GetxController {
  RxInt liveBidsCarsCount = 0.obs;
  List<CarsListModel> liveBidsCarsList = <CarsListModel>[];
  RxBool isLoading = false.obs;

  final RxSet<String> wishlistCarsIds = <String>{}.obs;

  // Countdown state (controller-owned)
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
    await fetchLiveBidsCarsList();
    await _fetchAndApplyWishlist();

    // Listen to realtime wishlist updates
    _listenWishlistRealtime();

    // Listen for patches
    _listenLiveBidsSectionRealtime();

    //Other listeners
    listenUpdatedBidAndChangeHighestBidLocally();
    // listenToAuctionWonEvent();
    _listenToExtendedTimerRealtime();
    _listenToCustomerExpectedPriceRealtime();
  }

  final RxList<CarsListModel> filteredLiveBidsCarsList = <CarsListModel>[].obs;

  // Live Bids Cars List
  Future<void> fetchLiveBidsCarsList() async {
    isLoading.value = true;
    try {
      final url = AppUrls.getCarsList(
        auctionStatus: AppConstants.auctionStatuses.live,
      );
      final response = await ApiService.get(endpoint: url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // final currentTime = DateTime.now();

        // liveBidsCarsList = List<CarsListModel>.from(
        //   (data as List).map(
        //     (car) => CarsListModel.fromJson(data: car, id: car['id']),
        //   ),
        // );

        liveBidsCarsList =
            (data as List<dynamic>)
                .map<CarsListModel>(
                  (e) => CarsListModel.fromJson(
                    id: e['id'] as String,
                    data: Map<String, dynamic>.from(e as Map),
                  ),
                )
                .toList(); // ✅ growable

        // liveBidsCarsList = (data as List<dynamic>)
        //     .map<CarsListModel>(
        //       (e) => CarsListModel.fromJson(
        //         id: e['id'] as String,
        //         data: Map<String, dynamic>.from(e as Map),
        //       ),
        //     )
        //     .toList(growable: false);

        // Only keep cars with live status
        final filtered =
            liveBidsCarsList
                .where(
                  (car) =>
                      car.auctionStatus == AppConstants.auctionStatuses.live,
                )
                .toList(); // <-- materialize snapshot

        // Check if user has bid on any car or he is the highest bidder
        await _seedParticipationForVisibleCars(filtered);

        filteredLiveBidsCarsList.assignAll(filtered);

        // filteredLiveBidsCarsList.assignAll(
        //   liveBidsCarsList.where(
        //     (car) => car.auctionStatus == AppConstants.auctionStatuses.live,
        //     //  &&  car.auctionEndTime != null &&
        //     // car.auctionEndTime!.isAfter(currentTime),
        //   ),
        // );

        // Sort
        _showLessRemainingTimeCarsOnTop();
        // filteredLiveBidsCarsList.value = liveBidsCarsList
        //     .where((car) {
        //       return car.auctionEndTime != null &&
        //           car.auctionStatus == AppConstants.auctionStatuses.live &&
        //           car.auctionEndTime!.isAfter(currentTime);
        //     })
        //     .toList(growable: false);

        // 🔁 one entry-point to handle every timer:
        setupCountdowns(filtered.toList());

        liveBidsCarsCount.value = filteredLiveBidsCarsList.length;

        // for (var car in liveBidsCarsList) {
        // for (var car in filteredLiveBidsCarsList) {
        //   await startAuctionCountdown(car);
        //   debugPrint(car.toJson().toString());
        // }
      } else {
        filteredLiveBidsCarsList.value = <CarsListModel>[];
        liveBidsCarsCount.value = 0;
        debugPrint('Failed to fetch data ${response.body}');
      }
    } catch (error, stackTrace) {
      // debugPrint('Error fetching data: $error');
      debugPrint('═══════════════════════════════════════');
      debugPrint('❌ ERROR: $error');
      debugPrint('📍 STACK TRACE: $stackTrace');
      debugPrint('═══════════════════════════════════════');
      filteredLiveBidsCarsList.value = <CarsListModel>[];
      liveBidsCarsCount.value = 0;
    } finally {
      isLoading.value = false;
    }
  }

  // Listen and Update Bid locally
  void listenUpdatedBidAndChangeHighestBidLocally() {
    SocketService.instance.on(SocketEvents.bidUpdated, (data) {
      final String carId = data['carId'];
      final int highestBid = data['highestBid'];
      final String? bidderId = data['userId']?.toString();

      final index = filteredLiveBidsCarsList.indexWhere((c) => c.id == carId);
      if (index != -1) {
        filteredLiveBidsCarsList[index].highestBid.value =
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

  // Auction Timer
  // Future<void> startAuctionCountdown(CarsListModel car) async {
  //   DateTime getAuctionEndTime() {
  //     // ✅ Prefer server's end time when present
  //     if (car.auctionEndTime != null) return car.auctionEndTime!.toLocal();
  //     final startTime = car.auctionStartTime!.toLocal() ?? DateTime.now();
  //     final duration = Duration(hours: car.auctionDuration);
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

  @override
  void onClose() {
    // for (var car in filteredLiveBidsCarsList) {
    // car.auctionTimer?.cancel();
    // }
    setupCountdowns(const []); // cancels all timers + clears times
    super.onClose();
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

  Future<void> _fetchAndApplyWishlist() async {
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

  // Listen to live bids section realtime
  void _listenLiveBidsSectionRealtime() {
    SocketService.instance.joinRoom(SocketEvents.liveBidsSectionRoom);

    SocketService.instance.on(SocketEvents.liveBidsSectionUpdated, (
      data,
    ) async {
      final String action = '${data['action']}';

      if (action == 'removed') {
        final String id = '${data['id']}';
        // cancel its timer to avoid leaks
        // final idx = filteredLiveBidsCarsList.indexWhere((c) => c.id == id);
        // if (idx != -1) {
        //   filteredLiveBidsCarsList[idx].auctionTimer?.cancel();
        // }
        // cancel controller-owned timer + remove displayed time
        _timers[id]?.cancel();
        _timers.remove(id);
        remainingTimes.remove(id);
        // filteredLiveBidsCarsList.value =
        //     filteredLiveBidsCarsList.where((c) => c.id != id).toList();
        // liveBidsCarsCount.value = filteredLiveBidsCarsList.length;
        filteredLiveBidsCarsList.removeWhere(
          (c) => c.id == id,
        ); // simple & growable-safe
        _showLessRemainingTimeCarsOnTop();

        liveBidsCarsCount.value = filteredLiveBidsCarsList.length;
        return;
      }

      if (action == 'added') {
        final String id = '${data['id']}';
        final Map<String, dynamic> carJson = Map<String, dynamic>.from(
          data['car'] ?? const {},
        );

        final incoming = CarsListModel.fromJson(id: id, data: carJson);

        final idx = filteredLiveBidsCarsList.indexWhere((c) => c.id == id);

        if (idx == -1) {
          // brand-new → add, then start its timer
          filteredLiveBidsCarsList.add(incoming);
          // Seed participation for just this car (if not cached)
          await _seedParticipationForVisibleCars([incoming]);
          // await startAuctionCountdown(incoming);
        } else {
          // existing → cancel old timer, replace model, restart timer
          // filteredLiveBidsCarsList[idx].auctionTimer?.cancel();
          filteredLiveBidsCarsList[idx] = incoming;
          // Seed participation for just this car (if not cached)
          await _seedParticipationForVisibleCars([incoming]);
          // await startAuctionCountdown(filteredLiveBidsCarsList[idx]);
        }

        // 🔁 refresh all timers via the single entry-point
        setupCountdowns(filteredLiveBidsCarsList);

        // ✅ update count after mutation
        liveBidsCarsCount.value = filteredLiveBidsCarsList.length;
        return;
      }
    });
  }

  /// Wire countdowns to the given cars list:
  /// - cancels timers for cars not in the list
  /// - (re)starts timers for cars in the list
  /// - writes formatted time into remainingTimes[carId]
  void setupCountdowns(List<CarsListModel> cars) {
    // 1) cancel timers for cars that disappeared
    final newIds = cars.map((c) => c.id).toSet();
    final toRemove = _timers.keys.where((id) => !newIds.contains(id)).toList();
    for (final id in toRemove) {
      _timers[id]?.cancel();
      _timers.remove(id);
      remainingTimes.remove(id); // drops the RxString entry
    }

    String fmt(Duration d) {
      String two(int n) => n.toString().padLeft(2, '0');
      return '${two(d.inHours)}h : ${two(d.inMinutes % 60)}m : ${two(d.inSeconds % 60)}s';
    }

    DateTime? computeLiveEnd(CarsListModel car) {
      if (car.auctionEndTime != null) return car.auctionEndTime!.toLocal();
      final start = car.auctionStartTime?.toLocal();
      if (start == null) return null;
      return start.add(Duration(hours: car.auctionDuration));
    }

    void startFor(CarsListModel car) {
      // make sure an RxString exists for this id
      remainingTimes.putIfAbsent(car.id, () => ''.obs);

      _timers[car.id]?.cancel();

      final endAt = computeLiveEnd(car);
      if (endAt == null) {
        remainingTimes[car.id]!.value = 'N/A';
        return;
      }

      String fmt(Duration d) {
        String two(int n) => n.toString().padLeft(2, '0');
        return '${two(d.inHours)}h : ${two(d.inMinutes % 60)}m : ${two(d.inSeconds % 60)}s';
      }

      void tick() {
        final diff = endAt.difference(DateTime.now());
        if (diff.isNegative || diff.inSeconds <= 0) {
          remainingTimes[car.id]!.value = '00h : 00m : 00s';
          _timers[car.id]?.cancel();
          _timers.remove(car.id);

          // MINIMAL path: don’t mutate lists here (let socket/server remove it)
          // If you must remove here, use addPostFrameCallback (optional).

          return;
        }
        remainingTimes[car.id]!.value = fmt(diff);
      }

      tick();
      _timers[car.id] = Timer.periodic(
        const Duration(seconds: 1),
        (_) => tick(),
      );
    }

    void startFor1(CarsListModel car) {
      _timers[car.id]?.cancel();

      final endAt = computeLiveEnd(car);
      if (endAt == null) {
        // 🔴 IMPORTANT: write to .value of the RxString
        getCarRemainingTimeForNextScreen(car.id).value = 'N/A';
        return;
      }

      void tick() {
        final diff = endAt.difference(DateTime.now());
        if (diff.isNegative || diff.inSeconds <= 0) {
          getCarRemainingTimeForNextScreen(car.id).value = '00h : 00m : 00s';
          _timers[car.id]?.cancel();
          _timers.remove(car.id);

          // Remove the car from the list when timer becomes less than zero
          remainingTimes.remove(car.id);
          filteredLiveBidsCarsList.removeWhere((c) => c.id == car.id);
          liveBidsCarsCount.value = filteredLiveBidsCarsList.length;
          return;
        }
        getCarRemainingTimeForNextScreen(car.id).value = fmt(diff);
      }

      // prime immediately, then every second
      tick();
      _timers[car.id] = Timer.periodic(
        const Duration(seconds: 1),
        (_) => tick(),
      );
    }

    // 2) ensure every listed car has an active timer
    for (final car in cars) {
      startFor(car);
    }
  }

  // Listen to timer exteded updates
  void _listenToExtendedTimerRealtime() {
    SocketService.instance.joinRoom(SocketEvents.liveBidsSectionRoom);

    SocketService.instance.on(SocketEvents.auctionExtended, (data) {
      final carId = '${data['carId']}';
      final newEnd =
          data['newEndTime'] == null ? null : '${data['newEndTime']}';
      final extendedBy =
          data['extendedBy'] == null
              ? null
              : int.tryParse('${data['extendedBy']}') ??
                  (data['extendedBy'] as num).toInt();

      applyAuctionTimeUpdate(
        carId: carId,
        newEndIso: newEnd,
        extendedBySeconds: extendedBy,
      );
    });
  }

  /// Single entry-point to update ONE car’s end time and restart only its timer.
  /// Call from your socket listener whenever an auction time changes.
  ///
  /// Usage:
  /// applyAuctionTimeUpdate(
  ///   carId: id,
  ///   newEndIso: data['newEndTime'],      // optional ISO string
  ///   extendedBySeconds: data['extendedBy'] as int?, // optional delta seconds
  /// );
  void applyAuctionTimeUpdate({
    required String carId,
    String? newEndIso,
    int? extendedBySeconds,
  }) {
    // 1) find the car
    final idx = filteredLiveBidsCarsList.indexWhere((c) => c.id == carId);
    if (idx == -1) return;

    final car = filteredLiveBidsCarsList[idx];

    // 2) compute the new end time
    DateTime? computeLiveEnd() {
      if (car.auctionEndTime != null) return car.auctionEndTime!.toLocal();
      final start = car.auctionStartTime?.toLocal();
      if (start == null) return null;
      return start.add(Duration(hours: car.auctionDuration));
    }

    DateTime? endAt = computeLiveEnd();

    if (newEndIso != null && newEndIso.isNotEmpty) {
      // server gave us a concrete new end time
      endAt = DateTime.tryParse(newEndIso)?.toLocal();
    } else if (extendedBySeconds != null && extendedBySeconds != 0) {
      // server gave us a delta (extend/shrink)
      if (endAt != null) {
        endAt = endAt!.add(Duration(seconds: extendedBySeconds));
      }
    }

    // 3) update your model in-place (or via copyWith if fields are final)
    // If your model is immutable, replace with copyWith(auctionEndTime: endAt)
    car.auctionEndTime = endAt;
    filteredLiveBidsCarsList[idx] = car; // notify GetX that item changed

    // 4) (re)start ONLY this car’s timer
    _timers[carId]?.cancel();

    String fmt(Duration d) {
      String two(int n) => n.toString().padLeft(2, '0');
      return '${two(d.inHours)}h : ${two(d.inMinutes % 60)}m : ${two(d.inSeconds % 60)}s';
    }

    void write(String text) =>
        getCarRemainingTimeForNextScreen(carId).value = text;

    if (endAt == null) {
      write('N/A');
      _timers.remove(carId);
      return;
    }

    void tick() {
      final diff = endAt!.difference(DateTime.now());
      if (diff.isNegative) {
        write('00h : 00m : 00s');
        _timers[carId]?.cancel();
        _timers.remove(carId);
        return;
      }
      write(fmt(diff));
    }

    // prime and schedule
    tick();
    _timers[carId] = Timer.periodic(const Duration(seconds: 1), (_) => tick());
    _showLessRemainingTimeCarsOnTop();
  }

  // Sort Live Bids by less remaining auction time car on top
  void _showLessRemainingTimeCarsOnTop() {
    DateTime? liveEnd(CarsListModel c) {
      if (c.auctionEndTime != null) return c.auctionEndTime!.toLocal();
      final start = c.auctionStartTime?.toLocal();
      if (start == null) return null;
      return start.add(Duration(hours: c.auctionDuration));
    }

    Duration remaining(CarsListModel c) {
      final end = liveEnd(c);
      if (end == null) return const Duration(days: 9999); // push unknowns down
      final d = end.difference(DateTime.now());
      return d.isNegative ? Duration.zero : d;
    }

    filteredLiveBidsCarsList.sort(
      (a, b) => remaining(a).compareTo(remaining(b)),
    );
  }

  // Seed Participation For Visible Cars
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
            car = filteredLiveBidsCarsList.firstWhere((c) => c.id == carId);
          } catch (_) {
            try {
              car = liveBidsCarsList.firstWhere((c) => c.id == carId);
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
      final int index = filteredLiveBidsCarsList.indexWhere(
        (car) => car.id == carId,
      );

      if (index != -1) {
        // ✅ update the RxDouble correctly
        filteredLiveBidsCarsList[index].customerExpectedPrice.value =
            newCustomerExpectedPrice;
        filteredLiveBidsCarsList[index].variableMargin.value = variableMargin;

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

  // // Get remaining time for car details screen
  // RxString getCarRemainingTimeForNextScreen(String carId) =>
  //     remainingTimes.putIfAbsent(carId, () => ''.obs);

  RxString getCarRemainingTimeForNextScreen(String carId) {
    return remainingTimes[carId] ?? ''.obs;
  }
}
