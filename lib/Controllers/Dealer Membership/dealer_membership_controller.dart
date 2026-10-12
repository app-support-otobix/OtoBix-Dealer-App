import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:otobix/Controllers/Dealer%20Membership/dealer_connections_controller.dart';
import 'package:otobix/Controllers/Dealer%20Membership/dealer_exchange_controller.dart';
import 'package:otobix/Controllers/Dealer%20Membership/dealer_inventory_controller.dart';
import 'package:otobix/Controllers/Dealer%20Membership/dealer_leads_controller.dart';
import 'package:otobix/Controllers/Dealer%20Membership/dealer_negotiations_controller.dart';
import 'package:otobix/Controllers/Dealer%20Membership/dealer_paged_list.dart';
import 'package:otobix/Controllers/Dealer%20Membership/dealer_requirements_controller.dart';
import 'package:otobix/Controllers/razorpay_payment_controller.dart';
import 'package:otobix/Models/Dealer%20Membership/dealer_activity_model.dart';
import 'package:otobix/Models/Dealer%20Membership/dealer_membership_model.dart';
import 'package:otobix/Network/dealer_membership_api.dart';
import 'package:otobix/Network/socket_service.dart';
import 'package:otobix/Services/razorpay_payment_service.dart';
import 'package:otobix/Utils/app_colors.dart';
import 'package:otobix/Utils/app_constants.dart';
import 'package:otobix/Utils/app_urls.dart';
import 'package:otobix/Utils/socket_events.dart';
import 'package:otobix/Views/Dealer%20Membership/dealer_type_choice_page.dart';
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

  @override
  void onInit() {
    super.onInit();
    SocketService.instance.on(
      SocketEvents.dealerMembershipUpdated,
      _onMembershipEvent,
    );
    SocketService.instance.on(
      SocketEvents.dealerActivityCreated,
      _onActivityEvent,
    );
    SocketService.instance.on(SocketEvents.connect, _joinDealerRoom);
    DealerMembershipApi.onModuleDisabled = _onModuleDisabled;
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
      SocketService.instance.leaveRoom(
        '${SocketEvents.userRoom}$_sessionUserId',
      );
      // Plans and dealer types follow the dealer (broker or not).
      config.value = null;
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
    _joinDealerRoom();
    await loadHome();
  }

  // Dealer Hub events come to the dealer's user room. A reconnect drops the
  // socket's rooms, so it is joined again on every connect.
  void _joinDealerRoom([dynamic _]) {
    if (_sessionUserId.isEmpty) return;
    SocketService.instance.joinRoom('${SocketEvents.userRoom}$_sessionUserId');
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
    SocketService.instance.off(SocketEvents.connect, _joinDealerRoom);
    DealerMembershipApi.onModuleDisabled = null;
    super.onClose();
  }

  void _onMembershipEvent(dynamic _) {
    refreshMembership();
    // A confirmed top-up or plan adds a ledger line; Membership shows it too.
    if (ledger.isNotEmpty) loadLedger(reset: true);
  }

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

  /// The dealer types on offer with their plans, for [DealerTypeChoicePage];
  /// empty when they can't be loaded (the page then has the fallback list).
  Future<List<DealerRegisterAsModel>> loadRegisterAsOptions() async {
    try {
      final data = await DealerMembershipApi.get(
        AppUrls.dealerRegistrationOptions,
      );
      return [
        for (final o in (data?['options'] as List? ?? const []))
          if (o is Map)
            DealerRegisterAsModel.fromJson(Map<String, dynamic>.from(o)),
      ];
    } on DealerApiException catch (e) {
      debugPrint('Dealer types not loaded: ${e.message}');
      return const [];
    }
  }

  /// The dealer type, chosen once by a dealer enrolled before registration
  /// asked it. Broker moves them to Broker Trial, or OtoBix does it later.
  Future<bool> chooseDealerType(String dealerType) async {
    if (isSubmitting.value) return false;
    isSubmitting.value = true;
    try {
      final data = await DealerMembershipApi.post(
        AppUrls.dealerMembershipDealerType,
        {'dealerType': dealerType},
      );
      final m = DealerMembershipModel.fromJson(Map<String, dynamic>.from(data));
      membership.value = m;
      // Plans, the top-up and dealer types follow the dealer (broker or not).
      config.value = null;
      ensureConfig();
      if (m.isBroker) {
        _toast(
          '${m.plan?.name ?? 'Broker plan'} started',
          "Add your customers' cars from Sell.",
          ToastType.success,
        );
      } else if (m.brokerRequestedAt != null) {
        _toast(
          'Broker plan requested',
          'OtoBix will move you to the Broker plan. Your current plan keeps working until then.',
          ToastType.success,
        );
      }
      loadHome(silent: true);
      return true;
    } on DealerApiException catch (e) {
      if (e.code == 'DEALER_TYPE_SET') {
        await refreshMembership();
        return true;
      }
      _toast('Dealer type not saved', e.message, ToastType.error);
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  /// Offline payment for a plan or a points top-up; OtoBix confirms it from
  /// the CRM, which starts the plan or adds the points.
  Future<bool> requestOfflinePayment(
    DealerPurchasable item, {
    String reference = '',
  }) async {
    if (isSubmitting.value) return false;
    isSubmitting.value = true;
    final isTopUp = item is DealerTopUpModel;
    try {
      final data = await DealerMembershipApi.post(
        AppUrls.dealerMembershipOfflinePayment,
        {'planCode': item.code, 'reference': reference.trim()},
      );
      membership.value = DealerMembershipModel.fromJson(
        Map<String, dynamic>.from(data),
      );
      _toast(
        isTopUp ? 'Points requested' : 'Upgrade requested',
        isTopUp
            ? 'OtoBix will confirm your payment and add the points.'
            : 'OtoBix will confirm your payment and start ${item.name}.',
        ToastType.success,
      );
      loadHome(silent: true);
      return true;
    } on DealerApiException catch (e) {
      _toast(
        isTopUp ? 'Points not requested' : 'Upgrade not requested',
        e.message,
        ToastType.error,
      );
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  /// UPI: pays through the app's shared Razorpay flow (its order and
  /// verification are kept in the payments collection), then the server checks
  /// that payment against the plan or top-up and starts the plan or adds the
  /// points.
  Future<void> purchasePlan(DealerPurchasable plan) async {
    if (isPaying.value) return;
    isPaying.value = true;
    final isTopUp = plan is DealerTopUpModel;
    try {
      final userId =
          await SharedPrefsHelper.getString(SharedPrefsHelper.userIdKey) ?? '';
      final payment =
          Get.isRegistered<RazorpayPaymentController>()
              ? Get.find<RazorpayPaymentController>()
              : Get.put(RazorpayPaymentController());
      final PaymentSuccessData success;
      try {
        success = await payment.pay(
          amountRupees: plan.priceRupees.toDouble(),
          name: AppConstants.appDisplayName,
          description: isTopUp ? plan.name : '${plan.name} membership',
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
            'purpose': 'dealer_membership',
            'userId': userId,
            'planCode': plan.code,
          },
          receipt: 'dealer_membership_${DateTime.now().millisecondsSinceEpoch}',
          userId: userId,
          meta: {'planCode': plan.code},
        );
      } catch (e) {
        _toast(
          'Payment not completed',
          e.toString().replaceAll('Exception: ', ''),
          ToastType.error,
        );
        return;
      }

      final data = await DealerMembershipApi.post(
        AppUrls.dealerMembershipVerifyPayment,
        {'planCode': plan.code, ...success.toJson()},
      );
      membership.value = DealerMembershipModel.fromJson(
        Map<String, dynamic>.from(data),
      );
      _toast(
        isTopUp ? 'Points added' : 'Membership active',
        isTopUp
            ? 'Use them until your current cycle ends.'
            : 'Your points have been allocated.',
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

  // Dealer Home tabs OtoBix can switch off from the CRM (the backend's
  // DEALER_APP_MODULES); the backend refuses their calls too.
  static const moduleSell = 'SELL';
  static const moduleBuy = 'BUY';
  static const moduleServices = 'SERVICES';
  static const moduleLeads = 'LEADS';
  static const moduleMembership = 'MEMBERSHIP';
  static const _moduleNames = {
    moduleSell: 'Sell',
    moduleBuy: 'Buy',
    moduleServices: 'Services',
    moduleLeads: 'Leads',
    moduleMembership: 'Membership',
  };

  /// On until the membership says otherwise, so a slow load never locks a tab.
  bool moduleEnabled(String code) =>
      membership.value?.moduleEnabled(code) ?? true;

  /// Brokers: Sell (My Customer's Inventory) and Membership only.
  bool get isBroker => membership.value?.isBroker ?? false;

  /// True when the dealer may open [code]; otherwise says it is locked.
  bool requireModule(String code) => requireAnyModule([code]);

  /// True when any of [codes] is on (chats and deal rooms serve both Buy and
  /// Sell); otherwise says it is locked.
  bool requireAnyModule(List<String> codes) {
    // Enrolled before registration asked the dealer type: that comes first.
    if (membership.value?.needsDealerType ?? false) {
      Get.to(() => const DealerTypeChoicePage(pushed: true));
      return false;
    }
    if (codes.any(moduleEnabled)) return true;
    final names = codes.map((c) => _moduleNames[c] ?? c).join(' and ');
    _showModuleLockedDialog(
      "$names ${codes.length > 1 ? "aren't" : "isn't"} enabled for your "
      'account. Contact OtoBix to turn it on.',
    );
    return false;
  }

  bool _explainingModuleOff = false;

  // OtoBix switched a tab off (CRM App Access) while one of its screens was
  // open: back to Home, which no longer shows it, and say why once even when
  // several of the screen's calls are refused together.
  Future<void> _onModuleDisabled(DealerApiException e) async {
    if (_explainingModuleOff) return;
    _explainingModuleOff = true;
    refreshMembership();
    Get.until((route) => route.isFirst);
    await _showModuleLockedDialog(e.message);
    _explainingModuleOff = false;
  }

  Future<void> _showModuleLockedDialog(String message) async {
    if (Get.isDialogOpen == true) return;
    await Get.dialog(
      AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.lock_outline, size: 18, color: AppColors.grey),
            SizedBox(width: 8),
            Text('Not enabled', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: Text(message, style: const TextStyle(fontSize: 13)),
        actions: [TextButton(onPressed: Get.back, child: const Text('OK'))],
      ),
    );
  }

  void handleError(
    DealerApiException e, {
    String title = 'Something went wrong',
  }) {
    switch (e.code) {
      case 'MEMBERSHIP_INACTIVE':
        _showUpgradeDialog(e.message);
        return;
      case 'INSUFFICIENT_POINTS':
      case 'ALLOWANCE_EXHAUSTED':
        _showUpgradeDialog(e.message, offerTopUp: true);
        return;
      case 'MODULE_DISABLED':
        return; // already handled when the call failed (_onModuleDisabled)
      default:
        _toast(title, e.message, ToastType.error);
    }
  }

  /// Out of points or of a feature's allowance ([offerTopUp]): adding points
  /// is offered next to upgrading. A broker has no plan to upgrade to.
  void _showUpgradeDialog(String message, {bool offerTopUp = false}) {
    final topUp = offerTopUp && (membership.value?.isActive ?? false);
    Get.dialog(
      AlertDialog(
        title: const Text('Membership', style: TextStyle(fontSize: 16)),
        content: Text(message, style: const TextStyle(fontSize: 13)),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('Later')),
          if (topUp)
            TextButton(
              onPressed: () {
                Get.back();
                if (requireModule(moduleMembership)) {
                  Get.to(() => const UpgradeMembershipPage(addPoints: true));
                }
              },
              child: const Text(
                'Add Points',
                style: TextStyle(color: AppColors.green),
              ),
            ),
          if (!(topUp && isBroker))
            TextButton(
              onPressed: () {
                Get.back();
                if (requireModule(moduleMembership)) {
                  Get.to(() => const UpgradeMembershipPage());
                }
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
