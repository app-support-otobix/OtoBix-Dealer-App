import 'dart:async';

import 'package:get/get.dart';
import 'package:otobix/Controllers/Dealer%20Membership/dealer_exchange_controller.dart';
import 'package:otobix/Controllers/Dealer%20Membership/dealer_membership_controller.dart';
import 'package:otobix/Models/Dealer%20Membership/dealer_exchange_model.dart';
import 'package:otobix/Network/dealer_membership_api.dart';
import 'package:otobix/Utils/app_urls.dart';
import 'package:otobix/Widgets/toast_widget.dart';

class DealerRequirementsController extends GetxController {
  static DealerRequirementsController get to =>
      Get.isRegistered<DealerRequirementsController>()
          ? Get.find<DealerRequirementsController>()
          : Get.put(DealerRequirementsController(), permanent: true);

  final requirements = <DealerRequirementModel>[].obs;
  final isLoading = false.obs;
  final error = ''.obs;
  final isSaving = false.obs;

  final makeOptions = <String>[].obs;
  final modelOptions = <String>[].obs;
  final isMakeLoading = false.obs;
  final isModelLoading = false.obs;
  Timer? _makeDebounce;
  Timer? _modelDebounce;

  @override
  void onClose() {
    _makeDebounce?.cancel();
    _modelDebounce?.cancel();
    super.onClose();
  }

  Future<void> loadRequirements() async {
    if (isLoading.value) return;
    isLoading.value = true;
    error.value = '';
    try {
      final data = await DealerMembershipApi.get(AppUrls.dealerRequirements);
      requirements.assignAll(
        (data as List).map(
          (e) => DealerRequirementModel.fromJson(Map<String, dynamic>.from(e)),
        ),
      );
    } on DealerApiException catch (e) {
      if (e.code == 'ONBOARDING_REQUIRED') {
        DealerMembershipController.to.handleError(e);
      }
      error.value = e.message;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> save(Map<String, dynamic> body, {String? id}) async {
    if (isSaving.value) return false;
    isSaving.value = true;
    try {
      final data =
          id == null
              ? await DealerMembershipApi.post(AppUrls.dealerRequirements, body)
              : await DealerMembershipApi.put(
                AppUrls.dealerRequirement(id),
                body,
              );
      final saved = DealerRequirementModel.fromJson(
        Map<String, dynamic>.from(data),
      );
      final index = requirements.indexWhere((r) => r.id == saved.id);
      if (index == -1) {
        requirements.insert(0, saved);
      } else {
        requirements[index] = saved;
      }
      DealerExchangeController.to.loadMatches(reset: true);
      _toast(
        'Filter saved',
        '${saved.matchCount} matching cars right now',
        ToastType.success,
      );
      return true;
    } on DealerApiException catch (e) {
      DealerMembershipController.to.handleError(
        e,
        title: 'Could not save the filter',
      );
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> delete(DealerRequirementModel r) async {
    try {
      await DealerMembershipApi.delete(AppUrls.dealerRequirement(r.id));
      requirements.removeWhere((x) => x.id == r.id);
      final exchange = DealerExchangeController.to;
      exchange.showMatchesFor(
        exchange.matchRequirementId.value == r.id
            ? ''
            : exchange.matchRequirementId.value,
      );
    } on DealerApiException catch (e) {
      DealerMembershipController.to.handleError(
        e,
        title: 'Could not delete the filter',
      );
    }
  }

  void onMakeSearchChanged(String q) {
    _makeDebounce?.cancel();
    _makeDebounce = Timer(
      const Duration(milliseconds: 350),
      () => fetchMakes(q.trim()),
    );
  }

  void onModelSearchChanged(String make, String q) {
    if (make.trim().isEmpty) return;
    _modelDebounce?.cancel();
    _modelDebounce = Timer(
      const Duration(milliseconds: 350),
      () => fetchModels(make: make.trim(), query: q.trim()),
    );
  }

  Future<void> fetchMakes(String query) async {
    isMakeLoading.value = true;
    try {
      final data = await DealerMembershipApi.post(AppUrls.searchCarMakes, {
        'q': query,
        'limit': 30,
      });
      makeOptions.assignAll((data as List).map((e) => e.toString()));
    } on DealerApiException {
      makeOptions.clear();
    } finally {
      isMakeLoading.value = false;
    }
  }

  Future<void> fetchModels({
    required String make,
    required String query,
  }) async {
    isModelLoading.value = true;
    try {
      final data = await DealerMembershipApi.post(
        AppUrls.searchCarModelsByMake,
        {'make': make, 'q': query, 'limit': 30},
      );
      modelOptions.assignAll((data as List).map((e) => e.toString()));
    } on DealerApiException {
      modelOptions.clear();
    } finally {
      isModelLoading.value = false;
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
