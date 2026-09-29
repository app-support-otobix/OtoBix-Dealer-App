import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:otobix/Controllers/Dealer%20Membership/dealer_membership_controller.dart';
import 'package:otobix/Models/Dealer%20Membership/dealer_exchange_model.dart';
import 'package:otobix/Network/dealer_membership_api.dart';
import 'package:otobix/Utils/app_urls.dart';

class DealerExchangeController extends GetxController {
  static DealerExchangeController get to =>
      Get.isRegistered<DealerExchangeController>()
          ? Get.find<DealerExchangeController>()
          : Get.put(DealerExchangeController(), permanent: true);

  static const double minYear = 2000;
  final double maxYear = DateTime.now().year.toDouble();
  static const double maxKms = 200000;
  static const double maxPriceLakh = 50;

  final searchText = ''.obs;
  final sort = 'recent'.obs;
  final selectedMake = RxnString();
  final selectedModel = RxnString();
  final selectedFuelTypes = <String>{}.obs;
  final selectedTransmissions = <String>{}.obs;
  late final yearRange = RangeValues(minYear, maxYear).obs;
  final kmRange = const RangeValues(0, maxKms).obs;
  final priceRangeLakh = const RangeValues(0, maxPriceLakh).obs;
  final appliedFilterCount = 0.obs;
  Map<String, String> _applied = {};

  final makeOptions = <String>[].obs;
  final modelOptions = <String>[].obs;
  final fuelOptions = <String>[].obs;
  final transmissionOptions = <String>[].obs;

  final results = <DealerExchangeListingModel>[].obs;
  final isLoading = false.obs;
  final error = ''.obs;
  final hasMore = true.obs;
  int _page = 0;

  final matches = <DealerExchangeListingModel>[].obs;
  final isLoadingMatches = false.obs;
  final matchesError = ''.obs;
  final matchesHasMore = true.obs;
  final matchRequirementId = ''.obs;
  int _matchesPage = 0;

  Future<void> loadOptions({String make = ''}) async {
    try {
      final data = Map<String, dynamic>.from(
        await DealerMembershipApi.get(
          AppUrls.dealerExchangeFilterOptions(make: make),
        ),
      );
      List<String> strings(dynamic v) =>
          (v as List? ?? []).map((e) => e.toString()).toList();
      if (make.isEmpty) {
        makeOptions.assignAll(strings(data['makes']));
        fuelOptions.assignAll(strings(data['fuelTypes']));
        transmissionOptions.assignAll(strings(data['transmissions']));
      } else {
        modelOptions.assignAll(strings(data['models']));
      }
    } on DealerApiException catch (e) {
      DealerMembershipController.to.handleError(
        e,
        title: 'Could not load filters',
      );
    }
  }

  void pickMake(String? make) {
    selectedMake.value = make;
    selectedModel.value = null;
    modelOptions.clear();
    if (make != null && make.isNotEmpty) loadOptions(make: make);
  }

  Map<String, String> _query() {
    final q = <String, String>{..._applied, 'sort': sort.value};
    if (searchText.value.trim().isNotEmpty) q['q'] = searchText.value.trim();
    return q;
  }

  Future<void> search({bool reset = false}) async {
    if (isLoading.value || (!reset && !hasMore.value)) return;
    if (reset) {
      _page = 0;
      hasMore.value = true;
      error.value = '';
    }
    isLoading.value = true;
    try {
      final data = Map<String, dynamic>.from(
        await DealerMembershipApi.get(
          AppUrls.dealerExchangeCars({
            ..._query(),
            'page': '${_page + 1}',
            'limit': '20',
          }),
        ),
      );
      final items = (data['items'] as List? ?? []).map(
        (e) =>
            DealerExchangeListingModel.fromJson(Map<String, dynamic>.from(e)),
      );
      if (reset) results.clear();
      results.addAll(items);
      _page += 1;
      hasMore.value = data['hasMore'] == true;
    } on DealerApiException catch (e) {
      if (e.code == 'ONBOARDING_REQUIRED') {
        DealerMembershipController.to.handleError(e);
      }
      error.value = e.message;
    } finally {
      isLoading.value = false;
    }
  }

  void applyFilters() {
    final make = selectedMake.value ?? '';
    final model = selectedModel.value ?? '';
    final years = yearRange.value;
    final kms = kmRange.value;
    final price = priceRangeLakh.value;
    final applied = <String, String>{
      if (make.isNotEmpty) 'make': make,
      if (model.isNotEmpty) 'model': model,
      if (selectedFuelTypes.isNotEmpty)
        'fuelTypes': selectedFuelTypes.join(','),
      if (selectedTransmissions.isNotEmpty)
        'transmissions': selectedTransmissions.join(','),
      if (years.start > minYear) 'yearMin': '${years.start.round()}',
      if (years.end < maxYear) 'yearMax': '${years.end.round()}',
      if (kms.start > 0) 'kmMin': '${kms.start.round()}',
      if (kms.end < maxKms) 'kmMax': '${kms.end.round()}',
      if (price.start > 0) 'priceMin': '${(price.start * 100000).round()}',
      if (price.end < maxPriceLakh)
        'priceMax': '${(price.end * 100000).round()}',
    };
    _applied = applied;
    bool has(String a, [String? b]) =>
        applied.containsKey(a) || (b != null && applied.containsKey(b));
    appliedFilterCount.value =
        [
          has('make'),
          has('model'),
          has('fuelTypes'),
          has('transmissions'),
          has('yearMin', 'yearMax'),
          has('kmMin', 'kmMax'),
          has('priceMin', 'priceMax'),
        ].where((applied) => applied).length;
    search(reset: true);
  }

  void resetFilters() {
    selectedMake.value = null;
    selectedModel.value = null;
    modelOptions.clear();
    selectedFuelTypes.clear();
    selectedTransmissions.clear();
    yearRange.value = RangeValues(minYear, maxYear);
    kmRange.value = const RangeValues(0, maxKms);
    priceRangeLakh.value = const RangeValues(0, maxPriceLakh);
    _applied = {};
    appliedFilterCount.value = 0;
    search(reset: true);
  }

  Future<void> loadMatches({bool reset = false}) async {
    if (isLoadingMatches.value || (!reset && !matchesHasMore.value)) return;
    if (reset) {
      _matchesPage = 0;
      matchesHasMore.value = true;
      matchesError.value = '';
    }
    isLoadingMatches.value = true;
    try {
      final data = Map<String, dynamic>.from(
        await DealerMembershipApi.get(
          AppUrls.dealerExchangeMatches(
            page: _matchesPage + 1,
            limit: 20,
            requirementId: matchRequirementId.value,
          ),
        ),
      );
      final items = (data['items'] as List? ?? []).map(
        (e) =>
            DealerExchangeListingModel.fromJson(Map<String, dynamic>.from(e)),
      );
      if (reset) matches.clear();
      matches.addAll(items);
      _matchesPage += 1;
      matchesHasMore.value = data['hasMore'] == true;
    } on DealerApiException catch (e) {
      matchesError.value = e.message;
    } finally {
      isLoadingMatches.value = false;
    }
  }

  void showMatchesFor(String requirementId) {
    matchRequirementId.value = requirementId;
    loadMatches(reset: true);
  }

  Future<DealerExchangeListingModel?> getListing(String id) async {
    try {
      final data = await DealerMembershipApi.get(AppUrls.dealerExchangeCar(id));
      return DealerExchangeListingModel.fromJson(
        Map<String, dynamic>.from(data),
      );
    } on DealerApiException catch (e) {
      DealerMembershipController.to.handleError(
        e,
        title: 'Listing unavailable',
      );
      return null;
    }
  }
}
