import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:open_filex/open_filex.dart';
import 'package:otobix/Controllers/Dealer%20Membership/dealer_membership_controller.dart';
import 'package:otobix/Controllers/Dealer%20Membership/dealer_paged_list.dart';
import 'package:otobix/Models/Dealer%20Membership/dealer_exchange_model.dart';
import 'package:otobix/Models/Dealer%20Membership/dealer_negotiation_model.dart';
import 'package:otobix/Network/api_service.dart';
import 'package:otobix/Network/dealer_membership_api.dart';
import 'package:otobix/Network/socket_service.dart';
import 'package:otobix/Utils/app_urls.dart';
import 'package:otobix/Utils/global_functions.dart';
import 'package:otobix/Utils/socket_events.dart';
import 'package:otobix/Widgets/toast_widget.dart';
import 'package:path_provider/path_provider.dart';

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
  // Nearest first; the server falls back to newest when no showroom location is set.
  final sort = 'nearest'.obs;
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

  // Customer inventory: Premium Listing cars, customers' auction cars their
  // owners listed for dealers.
  final customerSearchText = ''.obs;
  final customerSort = 'recent'.obs;
  late final customerCars = DealerPagedList<DealerExchangeListingModel>(
    (page) async => DealerPagedList.parse(
      await DealerMembershipApi.get(
        AppUrls.dealerCustomerCars({
          'page': '$page',
          'limit': '20',
          'sort': customerSort.value,
          if (customerSearchText.value.trim().isNotEmpty)
            'q': customerSearchText.value.trim(),
        }),
      ),
      DealerExchangeListingModel.fromJson,
    ),
  );
  final reportLoadingFor = ''.obs;

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
      for (final l in items) {
        sentOffers.remove(l.id); // the server's view is newer
      }
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
      for (final l in items) {
        sentOffers.remove(l.id);
      }
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

  // Offers that changed after the list loaded (sent from a card or the chat,
  // or answered by the seller), by listing id. They override the listing's
  // own myOffer until the list is next loaded.
  final sentOffers = <String, DealerMyOfferModel>{}.obs;
  final offeringOn = ''.obs;

  DealerMyOfferModel? myOfferOn(DealerExchangeListingModel l) =>
      sentOffers[l.id] ?? l.myOffer;

  @override
  void onInit() {
    super.onInit();
    SocketService.instance.on(
      SocketEvents.dealerNegotiationUpdated,
      _onNegotiationUpdated,
    );
  }

  @override
  void onClose() {
    SocketService.instance.off(
      SocketEvents.dealerNegotiationUpdated,
      _onNegotiationUpdated,
    );
    super.onClose();
  }

  /// Keeps the card's Your Offer box in step with a conversation where I am
  /// the buyer, wherever it changed.
  void trackOffer(DealerNegotiationModel n) {
    if (n.isBuyer && n.carId.isNotEmpty) {
      sentOffers[n.carId] = DealerMyOfferModel.of(n);
    }
  }

  // An offer, counter or acceptance on a conversation a card shows: reload it
  // so the card changes without reopening the list.
  Future<void> _onNegotiationUpdated(dynamic data) async {
    final id = data is Map ? '${data['negotiationId'] ?? ''}' : '';
    if (id.isEmpty ||
        ![
          ...results,
          ...matches,
          ...customerCars.items,
        ].any((l) => myOfferOn(l)?.negotiationId == id)) {
      return;
    }
    try {
      trackOffer(
        DealerNegotiationModel.fromJson(
          Map<String, dynamic>.from(
            await DealerMembershipApi.get(AppUrls.dealerNegotiation(id)),
          ),
        ),
      );
    } on DealerApiException catch (e) {
      debugPrint('Offer not refreshed: ${e.message}'); // the next load has it
    }
  }

  /// Sends [amount] to the seller from the Dealer Inventory card, without
  /// opening the chat. The card then shows where the seller stands.
  Future<bool> quickOffer(
    DealerExchangeListingModel listing,
    int amount,
  ) async {
    if (offeringOn.value.isNotEmpty) return false;
    offeringOn.value = listing.id;
    try {
      final data = await DealerMembershipApi.post(
        listing.isPremiumListing
            ? AppUrls.dealerCustomerCarOffer(listing.id)
            : AppUrls.dealerExchangeQuickOffer(listing.id),
        {'amount': amount},
      );
      trackOffer(
        DealerNegotiationModel.fromJson(Map<String, dynamic>.from(data)),
      );
      _toast(
        'Offer sent',
        '${GlobalFunctions.formatRupees(amount)} on ${listing.title} · the ${listing.isPremiumListing ? 'owner' : 'seller'} has been told',
      );
      return true;
    } on DealerApiException catch (e) {
      DealerMembershipController.to.handleError(e, title: 'Offer not sent');
      return false;
    } finally {
      offeringOn.value = '';
    }
  }

  void _toast(String title, String subtitle) {
    final context = Get.context;
    if (context == null) return;
    ToastWidget.show(
      context: context,
      title: title,
      subtitle: subtitle,
      type: ToastType.success,
    );
  }

  /// A Customer inventory car's OtoBix inspection report: downloaded with my
  /// login, then opened in the phone's PDF viewer.
  Future<void> openInspectionReport(DealerExchangeListingModel listing) async {
    if (reportLoadingFor.value.isNotEmpty) return;
    reportLoadingFor.value = listing.id;
    try {
      final response = await ApiService.get(
        endpoint: AppUrls.dealerCustomerCarReport(listing.id),
      );
      if (response.statusCode != 200 ||
          !(response.headers['content-type'] ?? '').contains('pdf')) {
        throw const DealerApiException(
          'The inspection report could not be loaded. Please try again.',
        );
      }
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/inspection_report_${listing.id}.pdf');
      await file.writeAsBytes(response.bodyBytes);
      await OpenFilex.open(file.path);
    } on DealerApiException catch (e) {
      DealerMembershipController.to.handleError(e, title: 'Report unavailable');
    } catch (_) {
      DealerMembershipController.to.handleError(
        const DealerApiException(
          'The inspection report could not be opened. Please try again.',
        ),
        title: 'Report unavailable',
      );
    } finally {
      reportLoadingFor.value = '';
    }
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
