import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:otobix/Models/cars_list_model.dart';
import 'package:otobix/Network/api_service.dart';
import 'package:otobix/Network/socket_service.dart';
import 'package:otobix/Utils/app_urls.dart';
import 'package:otobix/Utils/socket_events.dart';
import 'package:otobix/helpers/shared_prefs_helper.dart';

class PurchasedCarsController extends GetxController {
  // UI state
  final RxBool isLoading = false.obs;
  final RxList<CarsListModel> carsList = <CarsListModel>[].obs;

  // 🔴 Single source of truth for hearts in this page
  final RxSet<String> purchasedCarsIds = <String>{}.obs;

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
    await Future.wait([refreshPurchasedCarsIdsFromServer(), fetchCarsList()]);

    _bindRealtime();
  }

  /// 1) Fetch only the ids: { purchasedCars: [...] }
  Future<void> refreshPurchasedCarsIdsFromServer() async {
    try {
      if (_userId.isEmpty) return;
      final url = AppUrls.getUserPurchasedCarsCount(userId: _userId);
      final res = await ApiService.get(endpoint: url);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final List<dynamic> ids = data['purchasedCarsCount'] ?? [];
        purchasedCarsIds
          ..clear()
          ..addAll(ids.map((e) => '$e'));
        purchasedCarsIds.refresh();
      }
    } catch (e) {
      /* ignore */
      debugPrint('Error fetching purchased cars ids: $e');
    }
  }

  /// 2) Fetch full purchased cars list
  Future<void> fetchCarsList() async {
    isLoading.value = true;
    try {
      if (_userId.isEmpty) {
        carsList.clear();
      } else {
        final url = AppUrls.getUserPurchasedCarsList(userId: _userId);
        final res = await ApiService.get(endpoint: url);
        if (res.statusCode == 200) {
          final json = jsonDecode(res.body);
          final List list = (json['purchasedCars'] ?? []) as List;
          final fetched =
              list
                  .map<CarsListModel>(
                    (e) => CarsListModel.fromJson(
                      id: e['id'] as String,
                      data: Map<String, dynamic>.from(e as Map),
                    ),
                  )
                  .toList();
          carsList
            ..clear()
            ..addAll(fetched);
        } else {
          carsList.clear();
        }
      }
    } catch (_) {
      carsList.clear();
    } finally {
      isLoading.value = false;
    }
  }

  /// 3) Realtime updates from server
  void _bindRealtime() {
    if (_socketBound) return;
    _socketBound = true;

    SocketService.instance.on(SocketEvents.purchasedCarsUpdated, (
      payload,
    ) async {
      final action = '${payload['action']}';
      final carId = '${payload['carId']}';

      if (action == 'add') {
        purchasedCarsIds.add(carId);
        purchasedCarsIds.refresh();
        // Bring in newly added cars (user may have favorited elsewhere)
        await fetchCarsList();
      } else if (action == 'remove') {
        purchasedCarsIds.remove(carId);
        purchasedCarsIds.refresh();
        // Remove row instantly if present
        carsList.removeWhere((c) => c.id == carId);
      }
    });
  }
}
