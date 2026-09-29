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

  final isFetchingMobile = false.obs;
  final ownerMobile = ''.obs;
  final mobileConsentAt = Rxn<DateTime>();
  final mobileError = ''.obs;

  static const _membershipCodes = {
    'ONBOARDING_REQUIRED',
    'MEMBERSHIP_INACTIVE',
    'INSUFFICIENT_POINTS',
  };

  int get checkCost {
    return membership.config.value?.serviceCosts['RC_CHECK'] ?? 0;
  }

  int get mobileCost =>
      membership.config.value?.serviceCosts['RC_TO_MOBILE'] ?? 0;

  Future<void> check(String input) async {
    final reg = GlobalFunctions.normalizeRegistration(input);
    if (!GlobalFunctions.isValidRegistration(reg)) {
      error.value = 'Enter a valid registration number, e.g. WB02AB1234';
      return;
    }
    if (isChecking.value || !membership.requireMembership()) return;

    error.value = '';
    result.value = null;
    ownerMobile.value = '';
    mobileConsentAt.value = null;
    mobileError.value = '';
    isChecking.value = true;
    try {
      final data = await DealerMembershipApi.post(
        AppUrls.dealerServicesRcCheck,
        {'registrationNumber': reg},
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

  Future<void> fetchOwnerMobile() async {
    final reg = result.value?.vehicle.registrationNumber;
    if (reg == null || isFetchingMobile.value) return;
    isFetchingMobile.value = true;
    mobileError.value = '';
    try {
      final data = Map<String, dynamic>.from(
        await DealerMembershipApi.post(AppUrls.dealerServicesRcToMobile, {
          'registrationNumber': reg,
          'ownerConsent': true,
        }),
      );
      ownerMobile.value = (data['mobile'] ?? '').toString();
      mobileConsentAt.value =
          DateTime.tryParse('${data['consentRecordedAt']}') ?? DateTime.now();
      membership.loadHome(silent: true);
    } on DealerApiException catch (e) {
      if (_membershipCodes.contains(e.code)) {
        membership.handleError(e);
      } else {
        mobileError.value = e.message;
      }
    } finally {
      isFetchingMobile.value = false;
    }
  }
}
