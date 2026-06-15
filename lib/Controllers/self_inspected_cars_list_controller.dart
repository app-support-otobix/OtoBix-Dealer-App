import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:otobix/Models/self_inspected_cars_model.dart';
import 'package:otobix/Network/api_service.dart';
import 'package:otobix/Network/socket_service.dart';
import 'package:otobix/Utils/app_urls.dart';
import 'package:otobix/Utils/socket_events.dart';
import 'package:otobix/helpers/shared_prefs_helper.dart';

class SelfInspectedCarsListController extends GetxController {
  List<SelfInspectedCarModel> selfInspectedCarsList = <SelfInspectedCarModel>[];
  RxBool isPageLoading = false.obs;

  RxInt selfInspectedCarsCount = 0.obs;

  int currentPage = 1;
  final int limit = 20;

  bool hasMore = true; // tells if more data is available
  bool isFetchingMore = false; // prevents duplicate calls

  final ScrollController scrollController = ScrollController();

  final Rx<DateTime> now = DateTime.now().obs;
  Timer? _ticker;

  String? currentUserId;

  RxList<String> priceOfferedCarsList = <String>[].obs;

  @override
  void onInit() async {
    super.onInit();

    currentUserId =
        await SharedPrefsHelper.getString(SharedPrefsHelper.userIdKey) ?? '';

    fetchPriceOfferedSelfInspectedCarsList(userId: currentUserId ?? '');
    fetchSelfInspectedCarsList();

    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      now.value = DateTime.now();
    });

    scrollController.addListener(() {
      if (scrollController.position.pixels >=
          scrollController.position.maxScrollExtent - 200) {
        fetchSelfInspectedCarsList(isLoadMore: true);
      }
    });

    _listenPdSectionRealtime();
    listenToNewOfferAndChangeHighestOfferLocally();
    _listenToSelfInspectedCarExpectedPriceRealtime();
  }

  final RxList<SelfInspectedCarModel> filteredSelfInspectedCarsList =
      <SelfInspectedCarModel>[].obs;

  // Self Inspected Cars List
  Future<void> fetchSelfInspectedCarsList({bool isLoadMore = false}) async {
    if (isPageLoading.value || isFetchingMore) return;
    if (!hasMore && isLoadMore) return;

    if (isLoadMore) {
      isFetchingMore = true;
      currentPage++;
    } else {
      isPageLoading.value = true;
      currentPage = 1;
      hasMore = true;
    }

    try {
      final response = await ApiService.get(
        endpoint: AppUrls.getLiveSelfInspectedCarsList(
          page: currentPage,
          limit: limit,
        ),
      );

      // debugPrint('Response: ${response.body}');

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        final data = responseBody['data'];

        selfInspectedCarsCount.value = responseBody['total'] ?? 0;

        final newCars =
            (data as List<dynamic>)
                .map<SelfInspectedCarModel>(
                  (e) => SelfInspectedCarModel.fromJson(
                    Map<String, dynamic>.from(e as Map),
                  ),
                )
                .toList();

        if (isLoadMore) {
          selfInspectedCarsList.addAll(newCars);
        } else {
          selfInspectedCarsList = newCars;
        }

        filteredSelfInspectedCarsList.assignAll(selfInspectedCarsList);

        // 🔑 IMPORTANT: check if more data exists
        if (newCars.length < limit) {
          hasMore = false;
        }
      } else {
        debugPrint('Failed to fetch data ${response.body}');
      }
    } catch (error) {
      debugPrint('ERROR: $error');
    } finally {
      isPageLoading.value = false;
      isFetchingMore = false;
    }
  }

  // Listen to pd section realtime
  void _listenPdSectionRealtime() {
    SocketService.instance.joinRoom(SocketEvents.pdSectionRoom);

    SocketService.instance.on(SocketEvents.pdSectionUpdated, (data) async {
      final String action = data['action']?.toString() ?? '';
      final String carId = data['id']?.toString() ?? '';

      if (action == 'removed') {
        final beforeCount = filteredSelfInspectedCarsList.length;

        filteredSelfInspectedCarsList.removeWhere((car) => car.id == carId);

        final removedCount = beforeCount - filteredSelfInspectedCarsList.length;

        if (removedCount > 0) {
          selfInspectedCarsCount.value--;
        }
        return;
      }

      if (action == 'added') {
        final carJson = (data['car'] as Map?)?.cast<String, dynamic>() ?? {};

        final incomingCar = SelfInspectedCarModel.fromJson(carJson);

        final idx = filteredSelfInspectedCarsList.indexWhere(
          (c) => c.id == carId,
        );

        if (idx == -1) {
          filteredSelfInspectedCarsList.add(incomingCar);
          selfInspectedCarsCount.value++;
        } else {
          filteredSelfInspectedCarsList[idx] = incomingCar;
        }
        return;
      }
    });
  }

  // Listen and Update highest offer locally
  void listenToNewOfferAndChangeHighestOfferLocally() {
    SocketService.instance.on(SocketEvents.selfInspectedCarOfferUpdated, (
      data,
    ) {
      final String action = data['action']?.toString() ?? '';
      final String carId = data['id']?.toString() ?? '';

      if (action == 'offer-made') {
        final int highestOffer =
            int.tryParse(data['offerAmount']?.toString() ?? '0') ?? 0;
        final String offerMakerId = data['offerBy']?.toString() ?? '';
        final double fixedMargin =
            double.tryParse(data['fixedMargin']?.toString() ?? '0') ?? 0.0;
        final double variableMargin =
            double.tryParse(data['variableMargin']?.toString() ?? '0') ?? 0.0;

        final index = filteredSelfInspectedCarsList.indexWhere(
          (car) => car.id == carId,
        );

        if (index != -1) {
          filteredSelfInspectedCarsList[index].highestOffer.value =
              highestOffer;
          filteredSelfInspectedCarsList[index].highestOfferBy.value =
              offerMakerId;
          filteredSelfInspectedCarsList[index].fixedMargin.value = fixedMargin;
          filteredSelfInspectedCarsList[index].variableMargin.value =
              variableMargin;
        }

        if (offerMakerId == currentUserId &&
            !priceOfferedCarsList.contains(carId)) {
          priceOfferedCarsList.add(carId);
        }

        debugPrint('📢 Self inspected car offer update received: $data');
      }
    });
  }

  // Listen to Self Inspected Car Expected Price realtime
  void _listenToSelfInspectedCarExpectedPriceRealtime() {
    SocketService.instance.on(
      SocketEvents.selfInspectedCarExpectedPriceUpdated,
      (data) {
        final String carId = data['carId'].toString();
        final int newExpectedPrice =
            int.tryParse(data['newExpectedPrice']?.toString() ?? '0') ?? 0;
        final double fixedMargin =
            double.tryParse(data['fixedMargin']?.toString() ?? '0') ?? 0.0;
        final double variableMargin =
            double.tryParse(data['variableMargin']?.toString() ?? '0') ?? 0.0;

        // find the car in the list by its id
        final int index = filteredSelfInspectedCarsList.indexWhere(
          (car) => car.id == carId,
        );

        if (index != -1) {
          // ✅ update the RxDouble correctly
          filteredSelfInspectedCarsList[index].expectedPrice.value =
              newExpectedPrice;
          filteredSelfInspectedCarsList[index].fixedMargin.value = fixedMargin;
          filteredSelfInspectedCarsList[index].variableMargin.value =
              variableMargin;

          debugPrint(
            '📢 New expected price received for car $carId: $newExpectedPrice',
          );
        } else {
          debugPrint(
            '⚠️ carId $carId not found in filteredSelfInspectedCarsList',
          );
        }
      },
    );
  }

  String getRemainingTime(DateTime endTime) {
    final diff = endTime.difference(now.value);

    if (diff.isNegative) return "Ended";

    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;
    final seconds = diff.inSeconds % 60;

    return '${hours}h:${minutes}m:${seconds}s';
  }

  // Has user made offer on car
  RxBool hasUserMadeOfferOnCar(String carId) {
    return priceOfferedCarsList.contains(carId).obs;
  }

  // Fetch Price Offered Self Inspected Cars List
  Future<void> fetchPriceOfferedSelfInspectedCarsList({
    required String userId,
  }) async {
    try {
      final response = await ApiService.get(
        endpoint: AppUrls.getPriceOfferedSelfInspectedCarsList(userId: userId),
      );

      // debugPrint('Response: ${response.body}');

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        final data = responseBody['data'];

        priceOfferedCarsList.value =
            (data as List<dynamic>).map<String>((e) => e.toString()).toList();
      } else {
        debugPrint('Failed to fetch data ${response.body}');
      }
    } catch (error) {
      debugPrint('ERROR: $error');
    }
  }

  /// Search in cars list
  List<SelfInspectedCarModel> filterCarsBySearchText({
    required String searchText,
  }) {
    if (searchText.isEmpty) {
      return filteredSelfInspectedCarsList;
    }

    final lowerCaseSearchText = searchText.toLowerCase().trim();

    return filteredSelfInspectedCarsList.where((car) {
      // Check registration number (always available as it's required)
      final registrationNumberMatch = car.registrationNumber
          .toLowerCase()
          .contains(lowerCaseSearchText);

      // Check make (nullable)
      final makeMatch = car.make.toLowerCase().contains(lowerCaseSearchText);

      // Check model (nullable)
      final modelMatch = car.model.toLowerCase().contains(lowerCaseSearchText);

      // Return true if any field matches
      return registrationNumberMatch || makeMatch || modelMatch;
    }).toList();
  }

  @override
  void onClose() {
    _ticker?.cancel();
    scrollController.dispose();
    super.onClose();
  }
}
