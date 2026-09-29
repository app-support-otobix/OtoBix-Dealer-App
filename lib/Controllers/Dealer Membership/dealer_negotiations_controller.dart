import 'package:get/get.dart';
import 'package:otobix/Controllers/Dealer%20Membership/dealer_membership_controller.dart';
import 'package:otobix/Controllers/Dealer%20Membership/dealer_paged_list.dart';
import 'package:otobix/Models/Dealer%20Membership/dealer_negotiation_model.dart';
import 'package:otobix/Network/dealer_membership_api.dart';
import 'package:otobix/Utils/app_urls.dart';
import 'package:otobix/Widgets/toast_widget.dart';

class DealerNegotiationsController extends GetxController {
  static DealerNegotiationsController get to =>
      Get.isRegistered<DealerNegotiationsController>()
          ? Get.find<DealerNegotiationsController>()
          : Get.put(DealerNegotiationsController(), permanent: true);

  final membership = DealerMembershipController.to;
  final isActing = false.obs;

  late final received = inbox({'role': 'SELLER'});
  late final sent = inbox({'role': 'BUYER'});

  DealerPagedList<DealerNegotiationModel> inbox(Map<String, String> query) =>
      DealerPagedList(
        (page) async => DealerPagedList.parse(
          await DealerMembershipApi.get(
            AppUrls.dealerNegotiations({
              ...query,
              'page': '$page',
              'limit': '20',
            }),
          ),
          DealerNegotiationModel.fromJson,
        ),
      );

  Future<(List<DealerNegotiationModel>, DealerPriceDiscoveryModel)?> carOffers(
    String carId,
  ) async {
    try {
      final data = Map<String, dynamic>.from(
        await DealerMembershipApi.get(
          AppUrls.dealerNegotiations({'carId': carId, 'limit': '50'}),
        ),
      );
      return (
        (data['items'] as List? ?? [])
            .map(
              (e) =>
                  DealerNegotiationModel.fromJson(Map<String, dynamic>.from(e)),
            )
            .toList(),
        DealerPriceDiscoveryModel.fromJson(
          data['priceDiscovery'] is Map
              ? Map<String, dynamic>.from(data['priceDiscovery'])
              : null,
        ),
      );
    } on DealerApiException catch (e) {
      membership.handleError(e, title: 'Could not load offers');
      return null;
    }
  }

  Future<DealerNegotiationModel?> get(String id) =>
      _call(() => DealerMembershipApi.get(AppUrls.dealerNegotiation(id)));

  Future<DealerNegotiationModel?> openForListing(String carId) => _call(
    () => DealerMembershipApi.post(AppUrls.dealerNegotiationStart, {
      'carId': carId,
    }),
  );

  Future<DealerNegotiationModel?> makeOffer(String id, int amount) => _act(
    () => DealerMembershipApi.post(AppUrls.dealerNegotiationOffer(id), {
      'amount': amount,
    }),
    success: 'Offer sent',
  );

  Future<DealerNegotiationModel?> respond(String id, {required bool accept}) =>
      _act(
        () => DealerMembershipApi.post(AppUrls.dealerNegotiationRespond(id), {
          'action': accept ? 'ACCEPT' : 'REJECT',
        }),
        success: accept ? 'Offer accepted' : 'Offer rejected',
      );

  Future<DealerNegotiationModel?> _act(
    Future<dynamic> Function() call, {
    required String success,
  }) async {
    if (isActing.value) return null;
    isActing.value = true;
    try {
      final result = await _call(call);
      if (result != null) {
        _toast(success);
        received.refresh();
        sent.refresh();
        membership.loadHome(silent: true);
      }
      return result;
    } finally {
      isActing.value = false;
    }
  }

  Future<DealerNegotiationModel?> _call(Future<dynamic> Function() call) async {
    try {
      return DealerNegotiationModel.fromJson(
        Map<String, dynamic>.from(await call()),
      );
    } on DealerApiException catch (e) {
      membership.handleError(e);
      return null;
    }
  }

  void _toast(String title) {
    final context = Get.context;
    if (context == null) return;
    ToastWidget.show(context: context, title: title, type: ToastType.success);
  }
}
