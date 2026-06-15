import 'dart:async';
import 'dart:convert';
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

class OtoBuyController extends GetxController {
  RxInt otoBuyCarsCount = 0.obs;
  List<CarsListModel> otoBuyCarsList = [];
  RxBool isLoading = false.obs;

  final RxSet<String> wishlistCarsIds = <String>{}.obs;

  @override
  void onInit() async {
    super.onInit();
    final userId =
        await SharedPrefsHelper.getString(SharedPrefsHelper.userIdKey) ?? '';

    // Fetch cars then wishlist, then apply hearts
    await fetchOtoBuyCarsList();
    await _fetchAndApplyWishlist(userId: userId);

    // Listen to realtime wishlist updates
    _listenWishlistRealtime();

    // Listen to realtime otobuy cars section updates
    _listenOtoBuyCarsSectionRealtime();

    // List if customer updated the one click price of car
    _listenToCustomerUpdatedOneClickPriceRealtime();
  }

  final RxList<CarsListModel> filteredOtoBuyCarsList = <CarsListModel>[].obs;

  // Live Cars List
  Future<void> fetchOtoBuyCarsList() async {
    isLoading.value = true;
    try {
      final url = AppUrls.getCarsList(
        auctionStatus: AppConstants.auctionStatuses.otobuy,
      );
      final response = await ApiService.get(endpoint: url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        otoBuyCarsList = List<CarsListModel>.from(
          (data as List).map(
            (car) => CarsListModel.fromJson(data: car, id: car['id']),
          ),
        );

        otoBuyCarsCount.value = otoBuyCarsList.length;

        filteredOtoBuyCarsList.assignAll(otoBuyCarsList);

        for (var car in filteredOtoBuyCarsList) {
          await startAuctionCountdown(car);
        }
      } else {
        filteredOtoBuyCarsList.clear();
        debugPrint('Failed to fetch data ${response.body}');
      }
    } catch (error) {
      debugPrint('Failed to fetch data: $error');
      filteredOtoBuyCarsList.clear();
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

  @override
  void onClose() {
    for (var car in otoBuyCarsList) {
      car.auctionTimer?.cancel();
    }
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

  // Listen to otobuy cars section realtime
  void _listenOtoBuyCarsSectionRealtime() {
    SocketService.instance.joinRoom(SocketEvents.otobuyCarsSectionRoom);

    SocketService.instance.on(SocketEvents.otobuyCarsSectionUpdated, (
      data,
    ) async {
      final String action = '${data['action']}';

      debugPrint('action: $action');
      debugPrint('data: $data');

      if (action == 'removed') {
        final String id = '${data['id']}';

        // remove from list
        filteredOtoBuyCarsList.removeWhere((c) => c.id == id);

        // update count
        otoBuyCarsCount.value = filteredOtoBuyCarsList.length;
        return;
      }

      if (action == 'added') {
        final String id = '${data['id']}';
        final Map<String, dynamic> carJson = Map<String, dynamic>.from(
          data['car'] ?? const {},
        );
        final incoming = CarsListModel.fromJson(id: id, data: carJson);

        final idx = filteredOtoBuyCarsList.indexWhere((c) => c.id == id);
        if (idx == -1) {
          filteredOtoBuyCarsList.add(incoming);
        } else {
          // replace model (no model timers to cancel anymore)
          filteredOtoBuyCarsList[idx] = incoming;
        }

        // update count
        otoBuyCarsCount.value = filteredOtoBuyCarsList.length;
        return;
      }
    });
  }

  // Listen to Customer updated One Click Price realtime
  void _listenToCustomerUpdatedOneClickPriceRealtime() {
    SocketService.instance.on(SocketEvents.customerOneClickPriceUpdated, (
      data,
    ) {
      final String carId = data['carId'];
      final double newCustomerOneClickPrice =
          (data['newCustomerOneClickPrice'] as num).toDouble();

      // Check if the carId matches a car's id
      final idx = filteredOtoBuyCarsList.indexWhere((c) => c.id == carId);
      if (idx != -1) {
        // Update the customerOneClickPrice in auctionDetails
        filteredOtoBuyCarsList[idx].oneClickPrice.value =
            newCustomerOneClickPrice;
        debugPrint(
          '📢 New one click price update received for car $carId: $newCustomerOneClickPrice',
        );
      }
    });
  }
}
