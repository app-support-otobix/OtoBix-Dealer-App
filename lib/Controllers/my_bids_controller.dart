import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:otobix/Models/my_bids_cars_list_model.dart';
import 'package:otobix/Network/api_service.dart';
import 'package:otobix/Network/socket_service.dart';
import 'package:otobix/Utils/app_colors.dart';
import 'package:otobix/Utils/app_urls.dart';
import 'package:otobix/Utils/socket_events.dart';
import 'package:otobix/helpers/shared_prefs_helper.dart';
import 'package:otobix/Widgets/toast_widget.dart';

class MyBidsController extends GetxController {
  // UI state
  final RxBool isLoading = false.obs;
  final RxList<MyBidsCarsListModel> myBidCarsList = <MyBidsCarsListModel>[].obs;

  // 🔴 Single source of truth for hearts in this page
  final RxSet<String> myBidCarsIds = <String>{}.obs;

  String _userId = '';
  bool _socketBound = false;

  @override
  void onInit() {
    super.onInit();
    _init();
  }

  Future<void> _init() async {
    _userId =
        await SharedPrefsHelper.getString(SharedPrefsHelper.userIdKey) ?? '';
    if (_userId.isNotEmpty) {
      SocketService.instance.joinRoom('${SocketEvents.userRoom}$_userId');
    }

    // Prime ids + list
    await Future.wait([refreshMyBidsIdsFromServer(), fetchMyBidsCarsList()]);

    _bindRealtime();
  }

  /// 1) Fetch only the ids: { myBids: [...] }
  Future<void> refreshMyBidsIdsFromServer() async {
    try {
      if (_userId.isEmpty) return;
      final url = AppUrls.getUserMyBidsList(userId: _userId);
      final res = await ApiService.get(endpoint: url);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final List<dynamic> ids = data['myBids'] ?? [];
        myBidCarsIds
          ..clear()
          ..addAll(ids.map((e) => '$e'));
        myBidCarsIds.refresh();
      }
    } catch (_) {
      /* ignore */
    }
  }

  /// 2) Fetch full wishlist cars list
  Future<void> fetchMyBidsCarsList() async {
    isLoading.value = true;
    try {
      if (_userId.isEmpty) {
        myBidCarsList.clear();
      } else {
        final url = AppUrls.getUserMyBidsCarsList(userId: _userId);
        final res = await ApiService.get(endpoint: url);
        if (res.statusCode == 200) {
          final json = jsonDecode(res.body);
          final List list = (json['myBidsCars'] ?? []) as List;
          final fetched =
              list
                  .map(
                    (car) => MyBidsCarsListModel.fromJson(
                      documentId: '${car['id']}',
                      data: car,
                    ),
                  )
                  .toList();
          myBidCarsList
            ..clear()
            ..addAll(fetched);
          // debugPrint('myBidCarsList: ${myBidCarsList[0].toJson()}');
        } else {
          myBidCarsList.clear();
        }
      }
    } catch (error) {
      myBidCarsList.clear();
      debugPrint('myBidCarsList Error: $error');
    } finally {
      isLoading.value = false;
    }
  }

  /// 3) Realtime updates from server
  void _bindRealtime() {
    if (_socketBound) return;
    _socketBound = true;

    SocketService.instance.on(SocketEvents.myBidsUpdated, (payload) async {
      final action = '${payload['action']}';
      final carId = '${payload['carId']}';

      if (action == 'add') {
        myBidCarsIds.add(carId);
        myBidCarsIds.refresh();
        // Bring in newly added cars (user may have favorited elsewhere)
        await fetchMyBidsCarsList();
      } else if (action == 'remove') {
        myBidCarsIds.remove(carId);
        myBidCarsIds.refresh();
        // Remove row instantly if present
        myBidCarsList.removeWhere((c) => c.id == carId);
      }
    });
  }

  /// Helper for UI
  bool isFav(String carId) => myBidCarsIds.contains(carId);

  /// 4) Toggle favorite by carId (optimistic)
  Future<void> toggleFavoriteById(String carId) async {
    final id = carId;
    final isCurrentlyFav = myBidCarsIds.contains(id);

    // Optimistic local changes
    if (isCurrentlyFav) {
      myBidCarsIds.remove(id);
      myBidCarsList.removeWhere((c) => c.id == id); // this page only shows favs
    } else {
      myBidCarsIds.add(id);
      // We don't yet know the car's subset fields → refetch list
    }
    myBidCarsIds.refresh();

    try {
      final endpoint =
          isCurrentlyFav ? AppUrls.removeFromMyBids : AppUrls.addToMyBids;
      final res = await ApiService.post(
        endpoint: endpoint,
        body: {'userId': _userId, 'carId': id},
      );
      if (res.statusCode != 200) throw Exception(res.body);

      ToastWidget.show(
        context: Get.context!,
        title: isCurrentlyFav ? 'Removed from my bids' : 'Added to my bids',
        type: isCurrentlyFav ? ToastType.error : ToastType.success,
      );

      // If added, fetch to append full row; if removed, we already removed it.
      if (!isCurrentlyFav) {
        await fetchMyBidsCarsList();
      }
    } catch (e) {
      // Rollback on failure
      if (isCurrentlyFav) {
        myBidCarsIds.add(id);
        await fetchMyBidsCarsList(); // restore row
      } else {
        myBidCarsIds.remove(id);
        myBidCarsList.removeWhere((c) => c.id == id);
      }
      myBidCarsIds.refresh();

      ToastWidget.show(
        context: Get.context!,
        title: 'Failed to update my bids',
        type: ToastType.error,
      );
    }
  }

  /// If your UI calls this version:
  Future<void> toggleFavorite(MyBidsCarsListModel car) =>
      toggleFavoriteById(car.id!);

  // Get user bids for this car
  // was: Future<List<Map<String, dynamic>>> getUserBidsForCar(...)
  Future<Map<String, dynamic>> getUserBidsForCar(String carId) async {
    try {
      final url = AppUrls.getUserBidsForCar(userId: _userId, carId: carId);
      final res = await ApiService.get(endpoint: url);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final initialAuctionStatus = data['auctionStatus'];
        final auctionStatus =
            initialAuctionStatus == 'upcoming'
                ? 'Upcoming'
                : initialAuctionStatus == 'live'
                ? 'Live'
                : initialAuctionStatus == 'otobuy'
                ? 'OtoBuy'
                : 'Closed';
        final highestBid = data['highestBid'];
        final highestBidColor = data['highestBidColor'];
        final List bids = data['bids'] ?? [];

        return {
          'auctionStatus': auctionStatus,
          'highestBid': highestBid,
          'highestBidColor': highestBidColor,
          'bids':
              bids
                  .map<Map<String, dynamic>>(
                    (e) => {
                      'bidAmount': e['bidAmount'],
                      'time': e['time'],
                      'isActive': e['isActive'],
                    },
                  )
                  .toList(),
        };
      }
    } catch (e) {
      debugPrint("Error fetching previous bids: $e");
    }

    // safe empty shape
    return {
      'auctionStatus': null,
      'highestBid': null,
      'highestBidColor': null,
      'bids': <Map<String, dynamic>>[],
    };
  }

  Color auctionStatusColor(String? auctionStatus) {
    switch ((auctionStatus ?? '').toLowerCase()) {
      case 'upcoming':
        return AppColors.blue;
      case 'live':
        return AppColors.green;
      case 'otobuy':
        return AppColors.grey;
      default:
        return AppColors.red;
    }
  }
}
