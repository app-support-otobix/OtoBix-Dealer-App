import 'package:get/get.dart';
import 'package:otobix/Controllers/Dealer%20Membership/dealer_paged_list.dart';
import 'package:otobix/Models/Dealer%20Membership/dealer_activity_model.dart';
import 'package:otobix/Models/Dealer%20Membership/dealer_membership_model.dart';
import 'package:otobix/Network/dealer_membership_api.dart';
import 'package:otobix/Network/socket_service.dart';
import 'package:otobix/Services/razorpay_payment_service.dart';
import 'package:otobix/Utils/app_constants.dart';
import 'package:otobix/Utils/app_urls.dart';
import 'package:otobix/Utils/socket_events.dart';
import 'package:otobix/Widgets/toast_widget.dart';
import 'package:otobix/helpers/shared_prefs_helper.dart';

/// Membership state for the Dealer Membership section: the catalogues from
/// the server, the dealer's membership record, the Home summary and the
/// point ledger.
class DealerMembershipController extends GetxController {
  static DealerMembershipController get to =>
      Get.isRegistered<DealerMembershipController>()
          ? Get.find<DealerMembershipController>()
          : Get.put(DealerMembershipController(), permanent: true);

  final config = Rxn<DealerMembershipConfigModel>();
  final membership = Rxn<DealerMembershipModel>();

  // Home
  final dealerName = ''.obs;
  final latestActivities = <DealerActivityModel>[].obs;
  final isLoadingHome = false.obs;
  final homeError = ''.obs;

  // Point ledger
  final ledger = <DealerLedgerEntryModel>[].obs;
  final ledgerFilter = 'ALL'.obs;
  final isLoadingLedger = false.obs;
  final ledgerError = ''.obs;
  final ledgerHasMore = true.obs;
  int _ledgerPage = 0;

  // Actions
  final isSubmitting = false.obs;
  final isPaying = false.obs;

  final _razorpay = RazorpayPaymentService();

  @override
  void onInit() {
    super.onInit();
    _razorpay.init(
      onSuccess: _onPaymentSuccess,
      onFailure: (f) {
        isPaying.value = false;
        _toast('Payment not completed', f.message, ToastType.error);
      },
      onExternalWallet: (_) => isPaying.value = false,
    );
    SocketService.instance.on(
      SocketEvents.dealerMembershipUpdated,
      _onMembershipEvent,
    );
    SocketService.instance.on(
      SocketEvents.dealerActivityCreated,
      _onActivityEvent,
    );
    syncSession();
  }

  String _sessionUserId = '';
  Future<void>? _sync;

  /// Home calls this whenever it is shown. The Dealer Membership controllers
  /// outlive logout, so when another dealer has signed in, the previous
  /// dealer's data is dropped, the private socket room is joined with the new
  /// token and Home loads again.
  Future<void> syncSession() =>
      _sync ??= _syncSession().whenComplete(() => _sync = null);

  Future<void> _syncSession() async {
    final userId =
        await SharedPrefsHelper.getString(SharedPrefsHelper.userIdKey) ?? '';
    if (userId == _sessionUserId) return;
    if (_sessionUserId.isNotEmpty) {
      membership.value = null;
      dealerName.value = '';
      latestActivities.clear();
      ledger.clear();
    }
    _sessionUserId = userId;
    SocketService.instance.joinDealerRoom();
    await loadHome();
  }

  @override
  void onClose() {
    SocketService.instance.off(
      SocketEvents.dealerMembershipUpdated,
      _onMembershipEvent,
    );
    SocketService.instance.off(
      SocketEvents.dealerActivityCreated,
      _onActivityEvent,
    );
    _razorpay.dispose();
    super.onClose();
  }

  void _onMembershipEvent(dynamic _) => refreshMembership();

  // A new activity shows up in Home's latest activity.
  void _onActivityEvent(dynamic _) => loadHome(silent: true);

  // ---------------------------------------------------------------- Loading

  Future<DealerMembershipConfigModel?> ensureConfig() async {
    if (config.value != null) return config.value;
    try {
      final data = await DealerMembershipApi.get(
        AppUrls.dealerMembershipConfig,
      );
      config.value = DealerMembershipConfigModel.fromJson(
        Map<String, dynamic>.from(data),
      );
    } on DealerApiException catch (e) {
      _toast('Could not load membership details', e.message, ToastType.error);
    }
    return config.value;
  }

  Future<void> loadHome({bool silent = false}) async {
    if (!silent) {
      isLoadingHome.value = true;
      homeError.value = '';
    }
    try {
      await ensureConfig();
      final data = Map<String, dynamic>.from(
        await DealerMembershipApi.get(AppUrls.dealerMembershipHome),
      );
      dealerName.value = (data['dealer']?['name'] ?? '').toString();
      membership.value = DealerMembershipModel.fromJson(
        Map<String, dynamic>.from(data['membership'] ?? {}),
      );
      latestActivities.assignAll(
        (data['latestActivities'] as List? ?? []).map(
          (e) => DealerActivityModel.fromJson(Map<String, dynamic>.from(e)),
        ),
      );
    } on DealerApiException catch (e) {
      if (!silent) homeError.value = e.message;
    } finally {
      isLoadingHome.value = false;
    }
  }

  /// Full membership record including the current-cycle summary.
  Future<void> refreshMembership() async {
    try {
      final data = await DealerMembershipApi.get(AppUrls.dealerMembership);
      membership.value = DealerMembershipModel.fromJson(
        Map<String, dynamic>.from(data),
      );
    } on DealerApiException catch (e) {
      _toast('Could not load membership', e.message, ToastType.error);
    }
  }

  Future<void> loadLedger({bool reset = false}) async {
    if (isLoadingLedger.value || (!reset && !ledgerHasMore.value)) return;
    if (reset) {
      _ledgerPage = 0;
      ledgerHasMore.value = true;
      ledger.clear();
    }
    isLoadingLedger.value = true;
    ledgerError.value = '';
    try {
      final data = Map<String, dynamic>.from(
        await DealerMembershipApi.get(
          AppUrls.dealerMembershipLedger(
            type: ledgerFilter.value,
            page: _ledgerPage + 1,
            limit: 20,
          ),
        ),
      );
      ledger.addAll(
        (data['items'] as List? ?? []).map(
          (e) => DealerLedgerEntryModel.fromJson(Map<String, dynamic>.from(e)),
        ),
      );
      _ledgerPage += 1;
      ledgerHasMore.value = data['hasMore'] == true;
    } on DealerApiException catch (e) {
      ledgerError.value = e.message; // shown in the list with Retry
    } finally {
      isLoadingLedger.value = false;
    }
  }

  /// Activity Log, newest first.
  DealerPagedList<DealerActivityModel> activity() => DealerPagedList(
    (page) async => DealerPagedList.parse(
      await DealerMembershipApi.get(
        AppUrls.dealerActivity(page: page, limit: 20),
      ),
      DealerActivityModel.fromJson,
    ),
  );

  void setLedgerFilter(String filter) {
    if (ledgerFilter.value == filter) return;
    ledgerFilter.value = filter;
    loadLedger(reset: true);
  }

  // ---------------------------------------------------------------- Onboarding & purchase

  Future<bool> register({
    required String dealerType,
    required String city,
    required String state,
    required String gstin,
    required int tradeRadiusKm,
  }) async {
    if (isSubmitting.value) return false;
    isSubmitting.value = true;
    try {
      final data =
          await DealerMembershipApi.post(AppUrls.dealerMembershipRegister, {
            'dealerType': dealerType,
            'city': city,
            'state': state,
            'gstin': gstin,
            'tradeRadiusKm': tradeRadiusKm,
          });
      membership.value = DealerMembershipModel.fromJson(
        Map<String, dynamic>.from(data),
      );
      return true;
    } on DealerApiException catch (e) {
      _toast('Could not save your details', e.message, ToastType.error);
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<bool> applyPromo(String code) async {
    if (isSubmitting.value) return false;
    isSubmitting.value = true;
    try {
      final data = await DealerMembershipApi.post(
        AppUrls.dealerMembershipApplyPromo,
        {'code': code.trim()},
      );
      membership.value = DealerMembershipModel.fromJson(
        Map<String, dynamic>.from(data),
      );
      _toast('Promo applied', 'Your membership is active.', ToastType.success);
      loadHome(silent: true);
      return true;
    } on DealerApiException catch (e) {
      _toast('Promo not applied', e.message, ToastType.error);
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  /// Buys (or renews) a plan. The order amount comes from the server.
  Future<void> purchasePlan(DealerPlanModel plan) async {
    if (isPaying.value) return;
    isPaying.value = true;
    try {
      final order = Map<String, dynamic>.from(
        await DealerMembershipApi.post(AppUrls.dealerMembershipCreateOrder, {
          'planCode': plan.code,
        }),
      );
      _razorpay.openOrder(
        keyId: order['keyId'].toString(),
        orderId: order['orderId'].toString(),
        amountPaise: (order['amountPaise'] as num).toInt(),
        name: AppConstants.appDisplayName,
        description: '${plan.name} membership',
        customerEmail:
            await SharedPrefsHelper.getString(SharedPrefsHelper.userEmailKey) ??
            '',
        customerPhone:
            await SharedPrefsHelper.getString(
              SharedPrefsHelper.userPhoneNumberKey,
            ) ??
            '',
      );
    } on DealerApiException catch (e) {
      isPaying.value = false;
      _toast('Could not start payment', e.message, ToastType.error);
    } catch (_) {
      isPaying.value = false;
      _toast('Could not start payment', 'Please try again.', ToastType.error);
    }
  }

  Future<void> _onPaymentSuccess(PaymentSuccessData success) async {
    try {
      final data = await DealerMembershipApi.post(
        AppUrls.dealerMembershipVerifyPayment,
        success.toJson(),
      );
      membership.value = DealerMembershipModel.fromJson(
        Map<String, dynamic>.from(data),
      );
      _toast(
        'Membership active',
        'Your points have been allocated.',
        ToastType.success,
      );
      loadHome(silent: true);
    } on DealerApiException catch (e) {
      _toast(
        'Payment received, activation pending',
        e.message,
        ToastType.warning,
      );
    } finally {
      isPaying.value = false;
    }
  }

  void _toast(String title, String subtitle, ToastType type) {
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
