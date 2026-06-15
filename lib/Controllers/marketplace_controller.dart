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

class MarketplaceController extends GetxController {
  RxInt marketplaceCarsCount = 0.obs;
  List<CarsListModel> marketplaceCarsList = [];
  RxBool isLoading = false.obs;

  final RxSet<String> wishlistCarsIds = <String>{}.obs;

  @override
  void onInit() async {
    super.onInit();
    final userId =
        await SharedPrefsHelper.getString(SharedPrefsHelper.userIdKey) ?? '';

    // Fetch cars then wishlist, then apply hearts
    await fetchMarketplaceCarsList();
    await _fetchAndApplyWishlist(userId: userId);

    // Listen to realtime wishlist updates
    _listenWishlistRealtime();
  }

  final RxList<CarsListModel> filteredMarketplaceCarsList =
      <CarsListModel>[].obs;

  // Live Cars List
  Future<void> fetchMarketplaceCarsList() async {
    isLoading.value = true;
    try {
      final url = AppUrls.getCarsList(
        auctionStatus: AppConstants.auctionStatuses.marketplace,
      );
      final response = await ApiService.get(endpoint: url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final currentTime = DateTime.now();

        marketplaceCarsList = List<CarsListModel>.from(
          (data as List).map(
            (car) => CarsListModel.fromJson(data: car, id: car['id']),
          ),
        );

        marketplaceCarsCount.value = marketplaceCarsList.length;

        // Only keep cars with future auctionEndTime
        filteredMarketplaceCarsList.value =
            marketplaceCarsList.where((car) {
              return car.auctionEndTime != null &&
                  car.auctionEndTime!.isAfter(currentTime);
            }).toList();

        for (var car in marketplaceCarsList) {
          await startAuctionCountdown(car);
        }
      } else {
        filteredMarketplaceCarsList.value = [];
        debugPrint('Failed to fetch data ${response.body}');
      }
    } catch (error) {
      debugPrint('Failed to fetch data: $error');
      filteredMarketplaceCarsList.value = [];
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
    for (var car in marketplaceCarsList) {
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
}
