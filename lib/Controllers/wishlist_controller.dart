import 'dart:convert';
import 'package:get/get.dart';
import 'package:otobix/Models/cars_list_model.dart';
import 'package:otobix/Network/api_service.dart';
import 'package:otobix/Network/socket_service.dart';
import 'package:otobix/Utils/app_urls.dart';
import 'package:otobix/Utils/socket_events.dart';
import 'package:otobix/helpers/shared_prefs_helper.dart';
import 'package:otobix/Widgets/toast_widget.dart';

class WishlistController extends GetxController {
  // UI state
  final RxBool isLoading = false.obs;
  final RxList<CarsListModel> carsList = <CarsListModel>[].obs;

  // 🔴 Single source of truth for hearts in this page
  final RxSet<String> wishlistCarsIds = <String>{}.obs;

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
    await Future.wait([refreshWishlistIdsFromServer(), fetchCarsList()]);

    _bindRealtime();
  }

  /// 1) Fetch only the ids: { wishlist: [...] }
  Future<void> refreshWishlistIdsFromServer() async {
    try {
      if (_userId.isEmpty) return;
      final url = AppUrls.getUserWishlist(userId: _userId);
      final res = await ApiService.get(endpoint: url);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final List<dynamic> ids = data['wishlist'] ?? [];
        wishlistCarsIds
          ..clear()
          ..addAll(ids.map((e) => '$e'));
        wishlistCarsIds.refresh();
      }
    } catch (_) {
      /* ignore */
    }
  }

  /// 2) Fetch full wishlist cars list
  Future<void> fetchCarsList() async {
    isLoading.value = true;
    try {
      if (_userId.isEmpty) {
        carsList.clear();
      } else {
        final url = AppUrls.getUserWishlistCarsList(userId: _userId);
        final res = await ApiService.get(endpoint: url);
        if (res.statusCode == 200) {
          final json = jsonDecode(res.body);
          final List list = (json['myWishlistCars'] ?? []) as List;
          final fetched =
              list
                  // .map(
                  //   (car) => WishlistCarsListModel.fromJson(
                  //     documentId: '${car['id']}',
                  //     data: car,
                  //   ),
                  // )
                  // .toList();
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

    SocketService.instance.on(SocketEvents.wishlistUpdated, (payload) async {
      final action = '${payload['action']}';
      final carId = '${payload['carId']}';

      if (action == 'add') {
        wishlistCarsIds.add(carId);
        wishlistCarsIds.refresh();
        // Bring in newly added cars (user may have favorited elsewhere)
        await fetchCarsList();
      } else if (action == 'remove') {
        wishlistCarsIds.remove(carId);
        wishlistCarsIds.refresh();
        // Remove row instantly if present
        carsList.removeWhere((c) => c.id == carId);
      }
    });
  }

  /// Helper for UI
  bool isFav(String carId) => wishlistCarsIds.contains(carId);

  /// 4) Toggle favorite by carId (optimistic)
  Future<void> toggleFavoriteById(String carId) async {
    final id = carId;
    final isCurrentlyFav = wishlistCarsIds.contains(id);

    // Optimistic local changes
    if (isCurrentlyFav) {
      wishlistCarsIds.remove(id);
      carsList.removeWhere((c) => c.id == id); // this page only shows favs
    } else {
      wishlistCarsIds.add(id);
      // We don't yet know the car's subset fields → refetch list
    }
    wishlistCarsIds.refresh();

    try {
      final endpoint =
          isCurrentlyFav ? AppUrls.removeFromWishlist : AppUrls.addToWishlist;
      final res = await ApiService.post(
        endpoint: endpoint,
        body: {'userId': _userId, 'carId': id},
      );
      if (res.statusCode != 200) throw Exception(res.body);

      ToastWidget.show(
        context: Get.context!,
        title: isCurrentlyFav ? 'Removed from wishlist' : 'Added to wishlist',
        type: isCurrentlyFav ? ToastType.error : ToastType.success,
      );

      // If added, fetch to append full row; if removed, we already removed it.
      if (!isCurrentlyFav) {
        await fetchCarsList();
      }
    } catch (e) {
      // Rollback on failure
      if (isCurrentlyFav) {
        wishlistCarsIds.add(id);
        await fetchCarsList(); // restore row
      } else {
        wishlistCarsIds.remove(id);
        carsList.removeWhere((c) => c.id == id);
      }
      wishlistCarsIds.refresh();

      ToastWidget.show(
        context: Get.context!,
        title: 'Failed to update wishlist',
        type: ToastType.error,
      );
    }
  }

  /// If your UI calls this version:
  Future<void> toggleFavorite(CarsListModel car) => toggleFavoriteById(car.id);
}
