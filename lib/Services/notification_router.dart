// lib/Services/notification_router.dart
import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:otobix/Models/cars_list_model.dart';
import 'package:otobix/Network/api_service.dart';
import 'package:otobix/Services/auction_countdown_for_notification_car.dart';
import 'package:otobix/Utils/app_constants.dart';
import 'package:otobix/Utils/app_urls.dart';
import 'package:otobix/Views/Dealer%20Panel/car_details_page.dart';
import 'package:otobix/Widgets/toast_widget.dart';

// Notification Routes
class NotificationRoutes {
  static const String carAddedInUpcoming = 'carAddedInUpcoming';
  static const String carAddedInLive = 'carAddedInLive';
  static const String carAddedInOtobuy = 'carAddedInOtobuy';
  static const String userOutbidOnCar = 'userOutbidOnCar';
}

class NotificationRouter {
  NotificationRouter._();

  // Go to screen
  static Future<void> go(
    Map<String, dynamic> data, {
    bool replacePreviousScreens = false,
  }) async {
    final navigateToScreen =
        (data['navigateToScreen'] ?? data['screen']) as String?;
    if (navigateToScreen == null) return;

    final parametersForScreen = Map<String, dynamic>.from(
      data['parametersForScreen'] ?? {},
    );

    final Widget? page = await _buildPage(
      navigateToScreen,
      parametersForScreen,
    );

    push() {
      if (page == null) {
        // Get.to(() => SplashScreen());
        return;
      } else if (replacePreviousScreens) {
        Get.offAll(() => page);
      } else {
        Get.to(() => page);
      }
    }

    Future.microtask(push); // preferred
  }

  // Build Pages to navigate to
  static Future<Widget?> _buildPage(
    String navigateToScreen,
    Map<String, dynamic> parametersForScreen,
  ) async {
    // Car Details Screen If Car Added In Upcoming Auction
    if (navigateToScreen == NotificationRoutes.carAddedInUpcoming ||
        navigateToScreen == NotificationRoutes.carAddedInLive ||
        navigateToScreen == NotificationRoutes.carAddedInOtobuy) {
      return _buildCarDetailsFromParams(navigateToScreen, parametersForScreen);
    }

    // Default fallback
    return null;
  }

  // ---------- Helpers ----------

  static String? _sectionFor(String s) {
    if (s == NotificationRoutes.carAddedInUpcoming) {
      return AppConstants.homeScreenSections.upcomingSectionScreen;
    }
    if (s == NotificationRoutes.carAddedInLive) {
      return AppConstants.homeScreenSections.liveBidsSectionScreen;
    }
    if (s == NotificationRoutes.carAddedInOtobuy) {
      return AppConstants.homeScreenSections.otobuySectionScreen;
    }
    return null;
  }

  // 👇 Your extracted function: builds CarDetails page inputs from notification params
  static Future<Widget?> _buildCarDetailsFromParams(
    String screen,
    Map<String, dynamic> params,
  ) async {
    final carId = params['carId'] as String?;
    final currentOpenSection = _sectionFor(screen);

    if (carId == null || carId.isEmpty || currentOpenSection == null) {
      return null;
    }

    final auctionStatusAndRemainingTime =
        await getAuctionStatusAndRemainingTime(carId);

    // Check if auction status is valid
    final fetchedStatus =
        '${auctionStatusAndRemainingTime?['auctionStatus'] ?? ''}';
    final fetchedRemainingTime =
        '${auctionStatusAndRemainingTime?['remainingTime'] ?? ''}';
    final canOpen = _validateAuctionStatusAndMaybeToast(
      expectedSection: currentOpenSection,
      fetchedStatus: fetchedStatus,
    );
    if (!canOpen) return null;

    // ⬇️ Get ISO8601 "remainingTime" from server (example: 2025-10-16T06:29:47.529+00:00)
    final isoEnd =
        fetchedStatus == AppConstants.auctionStatuses.otobuy
            ? DateTime.now()
                .toUtc()
                .add(const Duration(days: 365))
                .toIso8601String()
            : fetchedRemainingTime;

    // Create/find the singleton timer service
    final timers =
        Get.isRegistered<AuctionCountdownForNotificationCar>()
            ? Get.find<AuctionCountdownForNotificationCar>()
            : Get.put(AuctionCountdownForNotificationCar(), permanent: true);

    // This is the RxString you'll pass to the page
    final remainingAuctionTime = timers.timeFor(carId);

    // Try to start from ISO; if it fails (null, bad format, already ended), block navigation.
    final started = timers.startFromIso(carId, isoEnd);
    if (!started) {
      ToastWidget.show(
        context: Get.context!,
        title: 'Auction has ended. Car is no longer available.',
        type: ToastType.error,
      );
      return null;
    }

    // (Optional) Fallback: if you already have auctionEndTime in carModel, the ISO above is enough.
    // Only fetch the model if you need to show details immediately:
    final carModel = await getCarDetailsForNotification(carId);
    if (carModel == null) {
      // Could show a toast/snackbar here if you want.
      return null;
    }

    // 🚩 Pass ONLY primitives to the page; page will fetch the model by carId
    return CarDetailsPage(
      carId: carId,
      car: carModel,
      currentOpenSection: currentOpenSection,
      remainingAuctionTime: remainingAuctionTime,
    );
  }

  // Map section → canonical status
  static String? _statusForSection(String section) {
    final s = AppConstants.homeScreenSections;
    final a = AppConstants.auctionStatuses;

    if (section == s.upcomingSectionScreen) return a.upcoming;
    if (section == s.liveBidsSectionScreen) return a.live;
    if (section == s.otobuySectionScreen) return a.otobuy;
    return null;
  }

  /// Validates fetched status against the section in the notification.
  /// Returns true if navigation should proceed; false if it should be blocked.
  /// Also shows the correct toast message when blocking.
  static bool _validateAuctionStatusAndMaybeToast({
    required String expectedSection, // from notification (currentOpenSection)
    required String
    fetchedStatus, // from server (getAuctionStatusAndRemainingTime)
  }) {
    final a = AppConstants.auctionStatuses;
    final expectedStatus = _statusForSection(expectedSection);

    // If the car is no longer in a known state -> block
    final isKnown = {a.upcoming, a.live, a.otobuy}.contains(fetchedStatus);
    if (!isKnown) {
      ToastWidget.show(
        context: Get.context!,
        title: 'Auction has ended. Car is no longer available.',
        type: ToastType.error,
      );
      return false;
    }

    // If expected "upcoming" but car is now "live" -> block with specific toast
    if (expectedStatus == a.upcoming && fetchedStatus == a.live) {
      ToastWidget.show(
        context: Get.context!,
        title: 'Car moved to Live Auction',
        type: ToastType.error,
      );
      return false;
    }

    // If expected "live" but car is now "otobuy" -> block with specific toast
    if (expectedStatus == a.live && fetchedStatus == a.otobuy) {
      ToastWidget.show(
        context: Get.context!,
        title: 'Car is now in OtoBuy',
        type: ToastType.error,
      );
      return false;
    }

    // (Optional safety) If you want to block any other mismatch, keep this.
    // If you prefer to allow navigation for other mismatches, remove this block.
    if (expectedStatus != null && expectedStatus != fetchedStatus) {
      // Example: upcoming -> otobuy (wasn't explicitly asked, but safer to block)
      final pretty =
          {
            a.upcoming: 'Upcoming',
            a.live: 'Live Auction',
            a.otobuy: 'OtoBuy',
          }[fetchedStatus] ??
          fetchedStatus;

      ToastWidget.show(
        context: Get.context!,
        title: 'Car moved to $pretty',
        type: ToastType.error,
      );
      return false;
    }

    // All good → proceed
    return true;
  }
}

// 👇 Helper function to get auction status and remaining time
Future<Map<String, dynamic>?> getAuctionStatusAndRemainingTime(
  String carId,
) async {
  try {
    final response = await ApiService.post(
      endpoint: AppUrls.getAuctionStatusAndRemainingTime,
      body: {'carId': carId},
    );

    // Expect 200 with { carsListModel: {...} }
    if (response.statusCode != 200) {
      return null; // 400, 404, 500 -> null per your current API contract
    }

    final data = jsonDecode(response.body);
    final auctionStatus = data['auctionStatus'];
    final remainingTime = data['remainingTime'];

    return {'auctionStatus': auctionStatus, 'remainingTime': remainingTime};
  } catch (e) {
    // Optionally log e
    return null;
  }
}

// 👇 Helper function to fetch car details from notification params
Future<CarsListModel?> getCarDetailsForNotification(String carId) async {
  try {
    final response = await ApiService.post(
      endpoint: AppUrls.getCarDetailsForNotification,
      body: {'carId': carId},
    );

    // Expect 200 with { carsListModel: {...} }
    if (response.statusCode != 200) {
      return null; // 400, 404, 500 -> null per your current API contract
    }

    final data = jsonDecode(response.body);
    if (data is! Map) return null;

    final raw = data['carsListModel'];
    if (raw is! Map) return null;

    final carMap = Map<String, dynamic>.from(raw);
    final id = (carMap['id'] ?? carMap['_id'] ?? carId).toString();

    return CarsListModel.fromJson(id: id, data: carMap);
  } catch (e) {
    // Optionally log e
    return null;
  }
}
