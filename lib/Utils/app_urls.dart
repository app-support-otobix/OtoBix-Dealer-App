import 'package:otobix/Utils/app_constants.dart';

class AppUrls {
  static String get baseUrl => AppConstants.renderBaseUrl;

  static final String socketBaseUrl = _extractSocketBaseUrl(
    baseUrl,
  ); // Socket base URL

  static String get sendOtp => "${baseUrl}otp/v2/send-otp";

  static String get verifyOtp => "${baseUrl}otp/v2/verify-otp";

  static String get loginOrRegisterUsingOtp =>
      "${baseUrl}auth/login-or-register-using-otp";

  static String get register => "${baseUrl}auth/register";

  // Showroom address search (Google Places through the backend)
  static String get placesAutocomplete => "${baseUrl}places/autocomplete";

  static String get placesDetails => "${baseUrl}places/details";

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
      "${baseUrl}auth/get-app-update-info?appKey=$appKey";

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

  static String get _dealerMembership => "${baseUrl}dealer-membership/";

  // Before login: "Register as" choices and their plans.
  static String get dealerRegistrationOptions =>
      "${_dealerMembership}registration-options";

  static String get dealerMembershipConfig => "${_dealerMembership}config";

  static String get dealerMembershipHome => "${_dealerMembership}home";

  static String get dealerMembership => "${_dealerMembership}membership";

  // Voice assistant (Dealer Home mic)
  static String get dealerAssistantChat => "${_dealerMembership}assistant/chat";

  static String get dealerProfileUpdate =>
      "${_dealerMembership}membership/register";

  static String get dealerShowroomLocation =>
      "${_dealerMembership}membership/showroom-location";

  static String dealerMembershipLedger({
    required String type,
    required int page,
    required int limit,
  }) =>
      "${_dealerMembership}membership/ledger?type=$type&page=$page&limit=$limit";

  static String get dealerMembershipOfflinePayment =>
      "${_dealerMembership}membership/offline-payment";

  // Once, for dealers enrolled before registration asked the dealer type.
  static String get dealerMembershipDealerType =>
      "${_dealerMembership}membership/dealer-type";

  static String get dealerMembershipVerifyPayment =>
      "${_dealerMembership}membership/verify-payment";

  static String get dealerServicesRcCheck =>
      "${_dealerMembership}services/rc-check";

  static String get dealerServicesRcCheckDecline =>
      "${_dealerMembership}services/rc-check/decline";

  // Service History paid with points, and the rest online ({ paymentId }).
  static String get dealerServicesServiceHistory =>
      "${_dealerMembership}services/service-history";

  static String get dealerInventory => "${_dealerMembership}inventory";

  static String dealerInventoryList({
    required String ownership,
    required int page,
    required int limit,
  }) =>
      "${_dealerMembership}inventory?ownership=$ownership&page=$page&limit=$limit";

  static String dealerInventoryCar(String id) =>
      "${_dealerMembership}inventory/$id";

  static String dealerInventoryCarStatus(String id) =>
      "${_dealerMembership}inventory/$id/status";

  static String get dealerInventoryFetchDetails =>
      "${_dealerMembership}inventory/fetch-details";

  static String get dealerInventoryUploadImage =>
      "${_dealerMembership}inventory/upload-image";

  static String dealerExchangeCars(Map<String, String> query) =>
      Uri.parse(
        "${_dealerMembership}exchange/cars",
      ).replace(queryParameters: query).toString();

  static String dealerExchangeFilterOptions({String make = ''}) =>
      "${_dealerMembership}exchange/filter-options?make=${Uri.encodeQueryComponent(make)}";

  static String dealerExchangeMatches({
    required int page,
    required int limit,
    String requirementId = '',
  }) =>
      "${_dealerMembership}exchange/matches?page=$page&limit=$limit&requirementId=$requirementId";

  static String dealerExchangeCar(String id) =>
      "${_dealerMembership}exchange/cars/$id";

  static String dealerExchangeQuickOffer(String id) =>
      "${_dealerMembership}exchange/cars/$id/offer";

  // Customer inventory: Premium Listing cars
  static String dealerCustomerCars(Map<String, String> query) =>
      Uri.parse(
        "${_dealerMembership}exchange/customer-cars",
      ).replace(queryParameters: query).toString();

  static String dealerCustomerCarOffer(String id) =>
      "${_dealerMembership}exchange/customer-cars/$id/offer";

  static String get dealerRequirements => "${_dealerMembership}requirements";

  static String dealerRequirement(String id) =>
      "${_dealerMembership}requirements/$id";

  static String get dealerNegotiationStart =>
      "${_dealerMembership}negotiations/start";

  static String dealerNegotiations(Map<String, String> query) =>
      Uri.parse(
        "${_dealerMembership}negotiations",
      ).replace(queryParameters: query).toString();

  static String dealerNegotiation(String id) =>
      "${_dealerMembership}negotiations/$id";

  static String dealerNegotiationMessages(
    String id, {
    String before = '',
    int limit = 30,
  }) =>
      "${_dealerMembership}negotiations/$id/messages?limit=$limit&before=${Uri.encodeQueryComponent(before)}";

  static String dealerNegotiationSend(String id) =>
      "${_dealerMembership}negotiations/$id/messages";

  static String dealerNegotiationOffer(String id) =>
      "${_dealerMembership}negotiations/$id/offer";

  static String dealerNegotiationRespond(String id) =>
      "${_dealerMembership}negotiations/$id/respond";

  static String dealerConnectionPrecheck(Map<String, String> query) =>
      Uri.parse(
        "${_dealerMembership}connections/precheck",
      ).replace(queryParameters: query).toString();

  static String dealerConnectionCandidates(String carId) =>
      "${_dealerMembership}connections/candidates?carId=$carId";

  static String dealerConnections(Map<String, String> query) =>
      Uri.parse(
        "${_dealerMembership}connections",
      ).replace(queryParameters: query).toString();

  static String get dealerConnectionRequest =>
      "${_dealerMembership}connections";

  static String dealerConnection(String id) =>
      "${_dealerMembership}connections/$id";

  static String dealerConnectionRespond(String id) =>
      "${_dealerMembership}connections/$id/respond";

  static String dealerConnectionCancel(String id) =>
      "${_dealerMembership}connections/$id/cancel";

  static String dealerConnectionVerifyPayment(String id) =>
      "${_dealerMembership}connections/$id/verify-payment";

  static String dealerDealRooms({required int page, required int limit}) =>
      "${_dealerMembership}deal-rooms?page=$page&limit=$limit";

  static String dealerDealRoom(String id) =>
      "${_dealerMembership}deal-rooms/$id";

  static String dealerDealRoomStatus(String id) =>
      "${_dealerMembership}deal-rooms/$id/status";

  static String dealerLeads(Map<String, String> query) =>
      Uri.parse(
        "${_dealerMembership}leads",
      ).replace(queryParameters: query).toString();

  static String get dealerLeadCreate => "${_dealerMembership}leads";

  static String dealerLeadStatus(String id) =>
      "${_dealerMembership}leads/$id/status";

  static String dealerActivity({
    required String module,
    required String service,
    required int page,
    required int limit,
  }) =>
      "${_dealerMembership}activity?module=$module&service=$service&page=$page&limit=$limit";

  static String get searchCarMakes =>
      "${baseUrl}customer/sell-my-car/search-car-makes";

  static String get searchCarModelsByMake =>
      "${baseUrl}customer/sell-my-car/search-car-models-by-make";

  static String get searchCarVariantsByMakeModel =>
      "${baseUrl}customer/sell-my-car/search-car-variants-by-make-model";

  static String get insuranceFetchQuotes =>
      "${baseUrl}customer/insurance/fetch-quotes";

  static String get insuranceGeneratedQuotes =>
      "${baseUrl}customer/insurance/get-generated-quotes-list";

  static String get insuranceRtoList =>
      "${baseUrl}customer/insurance/get-rto-list";

  static String get insuranceMakesList =>
      "${baseUrl}customer/insurance/get-makes-list";

  static String insuranceModelsList(int makeId) =>
      "${baseUrl}customer/insurance/get-models-list?makeId=$makeId";

  static String insuranceVariantsList(int modelId) =>
      "${baseUrl}customer/insurance/get-variants-list?modelId=$modelId";

  static String get addTelecallingRequest =>
      "${baseUrl}inspection/telecallings/add";

  // Socket URL Extraction
  static String _extractSocketBaseUrl(String url) {
    final uri = Uri.parse(url);
    return '${uri.scheme}://${uri.host}:${uri.port}';
  }
}
