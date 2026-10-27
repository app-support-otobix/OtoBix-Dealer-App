import 'package:get/get.dart';
import 'package:otobix/Controllers/Dealer%20Membership/dealer_membership_controller.dart';
import 'package:otobix/Controllers/Dealer%20Membership/dealer_paged_list.dart';
import 'package:otobix/Controllers/razorpay_payment_controller.dart';
import 'package:otobix/Models/Dealer%20Membership/dealer_connection_model.dart';
import 'package:otobix/Models/Dealer%20Membership/dealer_deal_room_model.dart';
import 'package:otobix/Network/dealer_membership_api.dart';
import 'package:otobix/Network/socket_service.dart';
import 'package:otobix/Services/razorpay_payment_service.dart';
import 'package:otobix/Utils/app_constants.dart';
import 'package:otobix/Utils/app_urls.dart';
import 'package:otobix/Utils/socket_events.dart';
import 'package:otobix/Widgets/toast_widget.dart';
import 'package:otobix/helpers/shared_prefs_helper.dart';

class DealerConnectionsController extends GetxController {
  static DealerConnectionsController get to =>
      Get.isRegistered<DealerConnectionsController>()
          ? Get.find<DealerConnectionsController>()
          : Get.put(DealerConnectionsController(), permanent: true);

  final membership = DealerMembershipController.to;
  final isActing = false.obs;

  late final connections = DealerPagedList<DealerConnectionModel>(
    (page) async => DealerPagedList.parse(
      await DealerMembershipApi.get(
        AppUrls.dealerConnections({'page': '$page', 'limit': '20'}),
      ),
      DealerConnectionModel.fromJson,
    ),
  );

  late final dealRooms = DealerPagedList<DealerDealRoomModel>(
    (page) async => DealerPagedList.parse(
      await DealerMembershipApi.get(
        AppUrls.dealerDealRooms(page: page, limit: 20),
      ),
      DealerDealRoomModel.fromJson,
    ),
  );

  @override
  void onInit() {
    super.onInit();
    SocketService.instance.on(SocketEvents.dealerConnectionUpdated, _onChange);
    SocketService.instance.on(SocketEvents.dealerDealRoomUpdated, _onChange);
  }

  @override
  void onClose() {
    SocketService.instance.off(SocketEvents.dealerConnectionUpdated, _onChange);
    SocketService.instance.off(SocketEvents.dealerDealRoomUpdated, _onChange);
    super.onClose();
  }

  void _onChange(dynamic _) {
    if (connections.items.isNotEmpty) connections.refresh();
    if (dealRooms.items.isNotEmpty) dealRooms.refresh();
    membership.loadHome(silent: true);
  }

  Future<DealerConnectionPrecheckModel?> precheck(
    Map<String, String> target,
  ) async {
    try {
      final data = await DealerMembershipApi.get(
        AppUrls.dealerConnectionPrecheck(target),
      );
      return DealerConnectionPrecheckModel.fromJson(
        Map<String, dynamic>.from(data),
      );
    } on DealerApiException catch (e) {
      membership.handleError(e, title: 'Could not check this request');
      return null;
    }
  }

  Future<List<DealerConnectionCandidateModel>?> candidates(String carId) async {
    try {
      final data = Map<String, dynamic>.from(
        await DealerMembershipApi.get(
          AppUrls.dealerConnectionCandidates(carId),
        ),
      );
      return (data['items'] as List? ?? [])
          .map(
            (e) => DealerConnectionCandidateModel.fromJson(
              Map<String, dynamic>.from(e),
            ),
          )
          .toList();
    } on DealerApiException catch (e) {
      membership.handleError(e, title: 'Could not load buyers');
      return null;
    }
  }

  Future<DealerConnectionModel?> get(String id) =>
      _connection(() => DealerMembershipApi.get(AppUrls.dealerConnection(id)));

  Future<DealerConnectionModel?> request(Map<String, String> target) => _act(
    () => _connection(
      () => DealerMembershipApi.post(AppUrls.dealerConnectionRequest, target),
    ),
    success: 'Request sent',
  );

  Future<DealerConnectionModel?> respond(String id, {required bool accept}) =>
      _act(
        () => _connection(
          () => DealerMembershipApi.post(AppUrls.dealerConnectionRespond(id), {
            'action': accept ? 'ACCEPT' : 'DECLINE',
          }),
        ),
        success: accept ? 'Connected · Deal Room open' : 'Request declined',
      );

  Future<DealerConnectionModel?> cancel(String id) => _act(
    () => _connection(
      () => DealerMembershipApi.post(AppUrls.dealerConnectionCancel(id)),
    ),
    success: 'Request withdrawn',
  );

  /// Premium Listing: once the car owner accepts, pays through the app's
  /// shared Razorpay flow; the server checks the payment with Razorpay, then
  /// opens the Deal Room with the owner's name and phone.
  Future<DealerConnectionModel?> pay(DealerConnectionModel c) => _act(
    () async {
      final userId =
          await SharedPrefsHelper.getString(SharedPrefsHelper.userIdKey) ?? '';
      final payment =
          Get.isRegistered<RazorpayPaymentController>()
              ? Get.find<RazorpayPaymentController>()
              : Get.put(RazorpayPaymentController());
      final PaymentSuccessData success;
      try {
        success = await payment.pay(
          amountRupees: c.priceRupees.toDouble(),
          name: AppConstants.appDisplayName,
          description: 'Connect with the owner · ${c.carTitle}',
          email:
              await SharedPrefsHelper.getString(
                SharedPrefsHelper.userEmailKey,
              ) ??
              '',
          phone:
              await SharedPrefsHelper.getString(
                SharedPrefsHelper.userPhoneNumberKey,
              ) ??
              '',
          notes: {
            'purpose': 'premium_listing_connection',
            'userId': userId,
            'connectionId': c.id,
          },
          receipt: 'premium_connection_${DateTime.now().millisecondsSinceEpoch}',
          userId: userId,
          meta: {'connectionId': c.id},
        );
      } catch (e) {
        _toast(
          'Payment not completed',
          e.toString().replaceAll('Exception: ', ''),
          ToastType.error,
        );
        return null;
      }
      return _connection(
        () => DealerMembershipApi.post(
          AppUrls.dealerConnectionVerifyPayment(c.id),
          success.toJson(),
        ),
      );
    },
    success: 'Paid · Deal Room open',
  );

  Future<DealerDealRoomModel?> getDealRoom(String id) =>
      _room(() => DealerMembershipApi.get(AppUrls.dealerDealRoom(id)));

  Future<DealerDealRoomModel?> updateDealStatus(
    String id, {
    required String status,
    String note = '',
    int agreedAmount = 0,
  }) => _act(
    () => _room(
      () => DealerMembershipApi.put(AppUrls.dealerDealRoomStatus(id), {
        'status': status,
        'note': note,
        if (agreedAmount > 0) 'agreedAmount': agreedAmount,
      }),
    ),
    success:
        'Deal ${DealerDealRoomModel.labels[status]?.toLowerCase() ?? 'updated'}',
  );

  Future<T?> _act<T>(
    Future<T?> Function() call, {
    required String success,
  }) async {
    if (isActing.value) return null;
    isActing.value = true;
    try {
      final result = await call();
      if (result != null) {
        _toast(success);
        membership.loadHome(silent: true);
        membership.refreshMembership();
      }
      return result;
    } finally {
      isActing.value = false;
    }
  }

  Future<DealerConnectionModel?> _connection(
    Future<dynamic> Function() call,
  ) async {
    try {
      return DealerConnectionModel.fromJson(
        Map<String, dynamic>.from(await call()),
      );
    } on DealerApiException catch (e) {
      membership.handleError(e);
      return null;
    }
  }

  Future<DealerDealRoomModel?> _room(Future<dynamic> Function() call) async {
    try {
      return DealerDealRoomModel.fromJson(
        Map<String, dynamic>.from(await call()),
      );
    } on DealerApiException catch (e) {
      membership.handleError(e);
      return null;
    }
  }

  void _toast(
    String title, [
    String subtitle = '',
    ToastType type = ToastType.success,
  ]) {
    final context = Get.context;
    if (context == null) return;
    ToastWidget.show(
      context: context,
      title: title,
      subtitle: subtitle,
      type: type,
    );
  }
}
