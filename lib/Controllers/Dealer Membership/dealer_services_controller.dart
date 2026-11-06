import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:otobix/Controllers/Dealer%20Membership/dealer_membership_controller.dart';
import 'package:otobix/Models/Dealer%20Membership/dealer_rc_check_model.dart';
import 'package:otobix/Network/dealer_membership_api.dart';
import 'package:otobix/Utils/app_urls.dart';
import 'package:otobix/Utils/global_functions.dart';

class DealerServicesController extends GetxController {
  final membership = DealerMembershipController.to;

  final isChecking = false.obs;
  final result = Rxn<DealerRcCheckModel>();
  final error = ''.obs;

  static const _membershipCodes = {
    'MEMBERSHIP_INACTIVE',
    'INSUFFICIENT_POINTS',
    'ALLOWANCE_EXHAUSTED',
  };

  int get checkCost => membership.config.value?.serviceCosts['RC_CHECK'] ?? 0;

  /// The registration to check, or null (with [error] set) when it is not valid.
  String? validRegistration(String input) {
    final reg = GlobalFunctions.normalizeRegistration(input);
    if (GlobalFunctions.isValidRegistration(reg)) return reg;
    error.value = 'Enter a valid registration number, e.g. WB02AB1234';
    return null;
  }

  /// One check: RC details, the owner's mobile and challans for one charge.
  /// Only called after the dealer confirms the owner's consent.
  Future<void> check(String reg) async {
    if (isChecking.value || !membership.requireMembership()) return;
    error.value = '';
    result.value = null;
    isChecking.value = true;
    try {
      final data = await DealerMembershipApi.post(
        AppUrls.dealerServicesRcCheck,
        {'registrationNumber': reg, 'ownerConsent': true},
      );
      result.value = DealerRcCheckModel.fromJson(
        Map<String, dynamic>.from(data),
      );
      membership.loadHome(silent: true);
    } on DealerApiException catch (e) {
      if (_membershipCodes.contains(e.code)) {
        membership.handleError(e);
      } else {
        error.value = e.message;
      }
    } finally {
      isChecking.value = false;
    }
  }

  /// The dealer pressed Cancel on the consent notice. The server keeps the
  /// answer (DPDP); nothing else depends on it, so a failure is not shown.
  Future<void> declineConsent(String reg) async {
    try {
      await DealerMembershipApi.post(AppUrls.dealerServicesRcCheckDecline, {
        'registrationNumber': reg,
      });
    } on DealerApiException catch (e) {
      debugPrint('Consent decline not recorded: ${e.message}');
    }
  }
}
