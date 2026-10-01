import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:otobix/Controllers/Dealer%20Membership/dealer_connections_controller.dart';
import 'package:otobix/Controllers/Dealer%20Membership/dealer_exchange_controller.dart';
import 'package:otobix/Controllers/Dealer%20Membership/dealer_inventory_controller.dart';
import 'package:otobix/Controllers/Dealer%20Membership/dealer_leads_controller.dart';
import 'package:otobix/Controllers/Dealer%20Membership/dealer_negotiations_controller.dart';
import 'package:otobix/Controllers/Dealer%20Membership/dealer_paged_list.dart';
import 'package:otobix/Controllers/Dealer%20Membership/dealer_requirements_controller.dart';
import 'package:otobix/Models/Dealer%20Membership/dealer_activity_model.dart';
import 'package:otobix/Models/Dealer%20Membership/dealer_membership_model.dart';
import 'package:otobix/Network/dealer_membership_api.dart';
import 'package:otobix/Network/socket_service.dart';
import 'package:otobix/Services/razorpay_payment_service.dart';
import 'package:otobix/Utils/app_colors.dart';
import 'package:otobix/Utils/app_constants.dart';
import 'package:otobix/Utils/app_urls.dart';
import 'package:otobix/Utils/socket_events.dart';
import 'package:otobix/Views/Dealer%20Membership/upgrade_membership_page.dart';
import 'package:otobix/Widgets/toast_widget.dart';
import 'package:otobix/helpers/shared_prefs_helper.dart';

class DealerMembershipController extends GetxController {
  static DealerMembershipController get to =>
      Get.isRegistered<DealerMembershipController>()
          ? Get.find<DealerMembershipController>()
          : Get.put(DealerMembershipController(), permanent: true);

  final config = Rxn<DealerMembershipConfigModel>();
  final membership = Rxn<DealerMembershipModel>();

  final dealerName = ''.obs;
  final pendingActivities = <DealerPendingActivityModel>[].obs;
  final latestActivities = <DealerActivityModel>[].obs;
  final newLeads = 0.obs;
  final isLoadingHome = false.obs;
  final homeError = ''.obs;

  final ledger = <DealerLedgerEntryModel>[].obs;
  final ledgerFilter = 'ALL'.obs;
  final isLoadingLedger = false.obs;
  final ledgerError = ''.obs;
  final ledgerHasMore = true.obs;
  int _ledgerPage = 0;

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

  Future<void> syncSession() =>
      _sync ??= _syncSession().whenComplete(() => _sync = null);

  Future<void> _syncSession() async {
    final userId =
        await SharedPrefsHelper.getString(SharedPrefsHelper.userIdKey) ?? '';
    if (userId == _sessionUserId) return;
    if (_sessionUserId.isNotEmpty) {
      membership.value = null;
      dealerName.value = '';
      newLeads.value = 0;
      pendingActivities.clear();
      latestActivities.clear();
      ledger.clear();
      Get.delete<DealerInventoryController>(force: true);
      Get.delete<DealerExchangeController>(force: true);
      Get.delete<DealerRequirementsController>(force: true);
      Get.delete<DealerNegotiationsController>(force: true);
      Get.delete<DealerConnectionsController>(force: true);
      Get.delete<DealerLeadsController>(force: true);
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

  void _onActivityEvent(dynamic _) => loadHome(silent: true);

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
      newLeads.value = (data['counts']?['newLeads'] as num?)?.toInt() ?? 0;
      pendingActivities.assignAll(
        (data['pendingActivities'] as List? ?? []).map(
          (e) =>
              DealerPendingActivityModel.fromJson(Map<String, dynamic>.from(e)),
        ),
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
      ledgerError.value = e.message;
    } finally {
      isLoadingLedger.value = false;
    }
  }

  DealerPagedList<DealerActivityModel> activity({
    String module = '',
    String service = '',
  }) => DealerPagedList(
    (page) async => DealerPagedList.parse(
      await DealerMembershipApi.get(
        AppUrls.dealerActivity(
          module: module,
          service: service,
          page: page,
          limit: 20,
        ),
      ),
      DealerActivityModel.fromJson,
    ),
  );

  void setLedgerFilter(String filter) {
    if (ledgerFilter.value == filter) return;
    ledgerFilter.value = filter;
    loadLedger(reset: true);
  }

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
      _toast(
        'Details saved',
        'Your dealer details are updated.',
        ToastType.success,
      );
      return true;
    } on DealerApiException catch (e) {
      _toast('Could not save your details', e.message, ToastType.error);
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  final isLocating = false.obs;

  /// Reads the phone's GPS (the dealer is asked to do this at the showroom) and
  /// saves it as the showroom location; other dealers' cars then show their
  /// distance from it. Only the distance ever reaches other dealers.
  Future<bool> setShowroomLocation() async {
    if (isLocating.value) return false;
    isLocating.value = true;
    try {
      final position = await _currentPosition();
      final data = await DealerMembershipApi.put(
        AppUrls.dealerShowroomLocation,
        {'latitude': position.latitude, 'longitude': position.longitude},
      );
      membership.value = DealerMembershipModel.fromJson(
        Map<String, dynamic>.from(data),
      );
      _toast(
        'Showroom location saved',
        "Other dealers' cars now show how far they are from you.",
        ToastType.success,
      );
      return true;
    } on _LocationUnavailable catch (e) {
      _toast('Location not available', e.message, ToastType.error);
      return false;
    } on DealerApiException catch (e) {
      _toast('Could not save the location', e.message, ToastType.error);
      return false;
    } finally {
      isLocating.value = false;
    }
  }

  Future<Position> _currentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const _LocationUnavailable(
        'Turn on location (GPS) on your phone and try again.',
      );
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
      throw const _LocationUnavailable(
        'Allow location for OtoBix in Settings, then try again.',
      );
    }
    if (permission == LocationPermission.denied) {
      throw const _LocationUnavailable(
        'Allow location access to set your showroom location.',
      );
    }
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
    } catch (_) {
      throw const _LocationUnavailable(
        'Could not get a GPS fix. Step outside or near a window and try again.',
      );
    }
  }

  Future<bool> requestOfflinePayment(
    DealerPlanModel plan, {
    String reference = '',
  }) async {
    if (isSubmitting.value) return false;
    isSubmitting.value = true;
    try {
      final data = await DealerMembershipApi.post(
        AppUrls.dealerMembershipOfflinePayment,
        {'planCode': plan.code, 'reference': reference.trim()},
      );
      membership.value = DealerMembershipModel.fromJson(
        Map<String, dynamic>.from(data),
      );
      _toast(
        'Upgrade requested',
        'OtoBix will confirm your payment and start ${plan.name}.',
        ToastType.success,
      );
      loadHome(silent: true);
      return true;
    } on DealerApiException catch (e) {
      _toast('Upgrade not requested', e.message, ToastType.error);
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

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

  bool requireMembership() {
    final m = membership.value;
    if (m != null && !m.isActive) {
      _showUpgradeDialog('Your membership has ended. Upgrade to continue.');
      return false;
    }
    return true;
  }

  void handleError(
    DealerApiException e, {
    String title = 'Something went wrong',
  }) {
    switch (e.code) {
      case 'MEMBERSHIP_INACTIVE':
      case 'INSUFFICIENT_POINTS':
      case 'ALLOWANCE_EXHAUSTED':
        _showUpgradeDialog(e.message);
        return;
      default:
        _toast(title, e.message, ToastType.error);
    }
  }

  void _showUpgradeDialog(String message) {
    Get.dialog(
      AlertDialog(
        title: const Text('Membership', style: TextStyle(fontSize: 16)),
        content: Text(message, style: const TextStyle(fontSize: 13)),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('Later')),
          TextButton(
            onPressed: () {
              Get.back();
              Get.to(() => const UpgradeMembershipPage());
            },
            child: const Text(
              'Upgrade Membership',
              style: TextStyle(color: AppColors.green),
            ),
          ),
        ],
      ),
    );
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

/// Why the phone could not give a showroom location, in the dealer's words.
class _LocationUnavailable implements Exception {
  final String message;
  const _LocationUnavailable(this.message);
}
