import 'package:otobix/Utils/app_constants.dart';

class AppUrls {
  static String get baseUrl => AppConstants.renderBaseUrl;

  static final String socketBaseUrl = _extractSocketBaseUrl(
    baseUrl,
  ); // Socket base URL

  static String get sendOtp => "${baseUrl}otp/v2/send-otp";

  static String get verifyOtp => "${baseUrl}otp/v2/verify-otp";

  static String get login => "${baseUrl}auth/login";

  static String get register => "${baseUrl}auth/register";

  static String get forgetPassword => "${baseUrl}auth/forget-password";

  static String get logout => "${baseUrl}auth/logout";

  static String get refreshAccessToken => "${baseUrl}auth/refresh-access-token";

  static String get allUsersList => "${baseUrl}user/all-users-list";

  static String get approvedUsersList => "${baseUrl}user/approved-users-list";

  static String get pendingUsersList => "${baseUrl}user/pending-users-list";

  static String get rejectedUsersList => "${baseUrl}user/rejected-users-list";

  static String get usersLength => "${baseUrl}user/users-length";

  static String get updateProfile => "${baseUrl}user/update-profile";

  static String get getUserProfile => "${baseUrl}user/user-profile";

  static String checkUsernameExists(String username) =>
      "${baseUrl}user/check-username?username=$username";

  static String get checkUserApprovalStatus =>
      "${baseUrl}user/check-user-approval-status";

  // static String updateUserStatus(String userId) =>
  //     "${baseUrl}user/update-user-status/$userId";

  static String getUserStatus(String userId) =>
      "${baseUrl}user/user-status/$userId";

  static String getCarDetails(String carId) => "${baseUrl}car/details/$carId";

  static String getCarsList({required String auctionStatus}) =>
      "${baseUrl}car/cars-list?auctionStatus=$auctionStatus";

  static String get getCarDetailsForNotification =>
      "${baseUrl}car/get-cars-list-model-for-a-car";

  static String get getAuctionStatusAndRemainingTime =>
      "${baseUrl}car/get-car-auction-status-and-remaining-time";

  static String updateUserThroughAdmin(String userId) =>
      "${baseUrl}user/update-user-through-admin/?userId=$userId";

  static String get updateCarBid => "${baseUrl}car/update-bid";

  static String get updateCarAuctionTime => "${baseUrl}car/update-auction-time";

  static String get schedulAuction =>
      "${baseUrl}upcoming/update-car-auction-time";

  static String get checkHighestBidder => "${baseUrl}car/check-highest-bidder";

  static String get submitAutoBidForLiveSection =>
      "${baseUrl}car/submit-auto-bid-for-live-section";

  static String get userNotifications =>
      "${baseUrl}user/notifications/create-notification";

  static String userNotificationsList({
    required int page,
    required int limit,
  }) =>
      "${baseUrl}user/notifications/notifications-list?page=$page&limit=$limit";

  static String userNotificationsDetail({required String notificationId}) =>
      "${baseUrl}user/notifications/notification-details?notificationId=$notificationId";

  static String get userNotificationsMarkRead =>
      "${baseUrl}user/notifications/mark-notification-as-read";

  static String get userNotificationsMarkAllRead =>
      "${baseUrl}user/notifications/mark-all-notifications-as-read";

  static String get userNotificationsUnreadNotificationsCount =>
      "${baseUrl}user/notifications/get-unread-notifications-count";

  static String get getUserWishlist => "${baseUrl}user/get-user-wishlist";

  static String get addToWishlist => "${baseUrl}user/add-to-wishlist";

  static String get removeFromWishlist => "${baseUrl}user/remove-from-wishlist";

  static String get getUserWishlistCarsList =>
      "${baseUrl}user/get-user-wishlist-cars-list";

  static String get getUserMyBidsList => "${baseUrl}user/get-user-my-bids";

  static String get addToMyBids => "${baseUrl}user/add-to-my-bids";

  static String get removeFromMyBids => "${baseUrl}user/remove-from-my-bids";

  static String get getUserMyBidsCarsList =>
      "${baseUrl}user/get-user-my-bids-cars-list";

  static String getUserBidsForCar({
    required String userId,
    required String carId,
  }) => "${baseUrl}user/get-user-bids-for-car?userId=$userId&carId=$carId";

  static String get getUserPurchasedCarsCount =>
      "${baseUrl}user/get-user-purchased-cars-count";

  static String get getUserPurchasedCarsList =>
      "${baseUrl}user/get-user-purchased-cars-list";

  static String get addUserActivityLog =>
      "${baseUrl}user/add-user-activity-log";

  static String get saveAppVersionOnAppLaunch =>
      "${baseUrl}user/save-app-version-on-app-launch";

  static String get uploadTermsAndConditions => "${baseUrl}terms/upload";

  static String get getLatestTermsAndConditions => "${baseUrl}terms/latest";

  static String get uploadPrivacyPolicy => "${baseUrl}privacy-policy/upload";

  static String get getLatestPrivacyPolicy => "${baseUrl}privacy-policy/latest";

  static String get uploadDealerGuide => "${baseUrl}dealer-guide/upload";

  static String get getLatestDealerGuide => "${baseUrl}dealer-guide/latest";

  static String get moveCarToOtobuy => "${baseUrl}otobuy/move-car-to-otobuy";

  static String get buyCar => "${baseUrl}otobuy/buy-car";

  static String get makeOfferForCar => "${baseUrl}otobuy/make-offer-for-car";

  static String get markCarAsSold => "${baseUrl}otobuy/mark-car-as-sold";

  static String get removeCar => "${baseUrl}car/remove-car";

  static String get getEntityNamesList =>
      "${baseUrl}entity-documents/get-entity-names-list";

  static String get fetchSampleServiceHistoryPdf =>
      "${baseUrl}service-history/fetch-sample-pdf";

  static String fetchServiceHistory({
    required String registrationNumber,
    required String userId,
  }) =>
      "${baseUrl}service-history/fetch-details?registrationNumber=$registrationNumber&userId=$userId";

  static String fetchServiceHistoryReportsList({required String userId}) =>
      "${baseUrl}service-history/fetch-reports-list?userId=$userId";

  static String get submitServiceHistoryRequest =>
      "${baseUrl}service-history/submit-request";

  static String get createRazorpayOrder => "${baseUrl}razorpay/create-order";

  static String get verifyRazorpayPayment =>
      "${baseUrl}razorpay/verify-payment";

  // GET one entity (with documents) by name
  static String getEntityDocumentsByName({required String entityName}) =>
      "${baseUrl}entity-documents/get-entity-documents-by-name/${Uri.encodeComponent(entityName)}";

  // GET app update info
  static String getAppUpdateInfo({required String appKey}) =>
      "${baseUrl}admin/get-app-update-info?appKey=$appKey";

  static String getLiveSelfInspectedCarsList({
    required int page,
    required int limit,
  }) =>
      "${baseUrl}self-inspection/get-live-self-inspected-cars-list?page=$page&limit=$limit";

  static String getSelfInspectedCarDetails({required String carId}) =>
      "${baseUrl}self-inspection/get-self-inspected-car-by-id?carId=$carId";

  static String getPriceOfferedSelfInspectedCarsList({
    required String userId,
  }) =>
      "${baseUrl}self-inspection/get-price-offered-self-inspected-cars-list?userId=$userId";

  static String get makeOfferOnSelfInspectedCar =>
      "${baseUrl}self-inspection/make-offer-on-self-inspected-car";

  static String get createGuestUser => "${baseUrl}guest-user/create";

  // Socket URL Extraction
  static String _extractSocketBaseUrl(String url) {
    final uri = Uri.parse(url);
    return '${uri.scheme}://${uri.host}:${uri.port}';
  }
}
