import 'package:flutter/material.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:otobix/Models/cars_list_model.dart';

class DealerHomeSearchSortFilterHelper {
  // Search cars using search text
  static List<CarsListModel> searchCarsBySearchText({
    required List<CarsListModel> carsList,
    required String searchText,
  }) {
    final query = searchText.trim().toLowerCase();
    if (query.isEmpty) return carsList;
    return carsList.where((c) {
      final s =
          '${c.make} ${c.model} ${c.variant} ${c.inspectionLocation}'
              .toLowerCase();
      return s.contains(query);
    }).toList();
  }

  // ---------------- SORT (state + options) ----------------
  static final RxString selectedSortLabel = 'Price Low to High'.obs;

  /// Whether sorting is currently applied. If false, we return the list as-is.
  static final RxBool isSortApplied = false.obs;

  static const List<String> sortOptions = <String>[
    'Price Low to High',
    'Price High to Low',
    'Newest First',
    'Oldest First',
    // 'KMs Low to High',
    // 'KMs High to Low',
  ];

  static void setSelectedSortLabel(String label) {
    if (sortOptions.contains(label)) {
      selectedSortLabel.value = label;
    }
  }

  /// Apply the currently selected sort (called when user taps "Apply")
  static void applySort() => isSortApplied.value = true;

  /// Clear any sort (return to original order, radios visually reset if you want)
  static void clearSort() {
    isSortApplied.value = false;
    // (Optional) also reset selection to default:
    // selectedSortLabel.value = 'Price Low to High';
  }

  /// Flexible: let caller specify which "price" field to use.
  static List<CarsListModel> sortCars({
    required List<CarsListModel> carsList,
    num Function(CarsListModel)? priceOf,
    DateTime Function(CarsListModel)? yearOf,
    int Function(CarsListModel)? kmsOf,
  }) {
    // If sort not applied, return as-is (keeps source/original order)
    if (!isSortApplied.value) return carsList;

    final list = [...carsList];

    final _priceOf = priceOf ?? (c) => (c.priceDiscovery);
    final _yearOf = yearOf ?? (c) => (c.yearMonthOfManufacture ?? DateTime(0));
    final _kmsOf = kmsOf ?? (c) => (c.odometerReadingInKms);

    switch (selectedSortLabel.value) {
      case 'Price Low to High':
        list.sort((a, b) => _priceOf(a).compareTo(_priceOf(b)));
        break;
      case 'Price High to Low':
        list.sort((a, b) => _priceOf(b).compareTo(_priceOf(a)));
        break;
      case 'Newest First':
        list.sort((a, b) => _yearOf(b).compareTo(_yearOf(a)));
        break;
      case 'Oldest First':
        list.sort((a, b) => _yearOf(a).compareTo(_yearOf(b)));
        break;
      // case 'KMs Low to High': list.sort((a, b) => _kmsOf(a).compareTo(_kmsOf(b))); break;
      // case 'KMs High to Low': list.sort((a, b) => _kmsOf(b).compareTo(_kmsOf(a))); break;
      default:
        list.sort((a, b) => _priceOf(a).compareTo(_priceOf(b)));
    }
    return list;
  }

  // ===================== STATE  (new) ================================

  static final RxList<String> stateOptions = <String>['All States'].obs;
  static final RxString selectedState = 'All States'.obs;
  static final RxBool isStateFilterApplied = false.obs;

  /// Call once (e.g., on Home init) to provide the states list.
  static void initStates(List<String> states) {
    final ops = states.toList();
    if (ops.isEmpty || ops.first != 'All States') {
      stateOptions.assignAll(['All States', ...ops]);
    } else {
      stateOptions.assignAll(ops);
    }
    // ensure selected is valid
    if (!stateOptions.contains(selectedState.value)) {
      selectedState.value = 'All States';
    }
  }

  static void setSelectedState(String state) {
    if (stateOptions.contains(state)) selectedState.value = state;
  }

  static void applyStateFilter() {
    // treat 'All States' as "no filter"
    isStateFilterApplied.value = selectedState.value != 'All States';
  }

  static void clearStateFilter() {
    isStateFilterApplied.value = false;
    selectedState.value = 'All States';
  }

  /// Filter cars by state. You can pass how to read the state from a car.
  /// Defaults to using `inspectionLocation`.
  static List<CarsListModel> filterCarsByState({
    required List<CarsListModel> carsList,
    String Function(CarsListModel)? stateOf,
  }) {
    if (!isStateFilterApplied.value || selectedState.value == 'All States') {
      return carsList;
    }
    final _stateOf = stateOf ?? (c) => (c.registrationState);
    final needle = selectedState.value.toLowerCase();

    return carsList
        .where((c) => _stateOf(c).toLowerCase().contains(needle))
        .toList();
  }

  // ---------------- ALL FILTERS IN ONE FUNCTION ----------------------------

  // TRANSMISSION
  static final List<String> transmissionTypes = const ['Manual', 'Automatic'];
  static final RxList<String> selectedTransmissionFilter = <String>[].obs;

  // PRICE
  static TextEditingController minPriceController = TextEditingController();
  static TextEditingController maxPriceController = TextEditingController();

  // KMS
  static const double minKms = 0;
  static const double maxKms = 300000;
  static final Rx<RangeValues> selectedKmsRange =
      const RangeValues(minKms, maxKms).obs;
  static final TextEditingController minKmsController = TextEditingController(
    text: '0',
  );
  static final TextEditingController maxKmsController = TextEditingController(
    text: '300000',
  );

  // OWNERSHIP (Serial No.)
  static const int minOwnership = 1;
  static const int maxOwnership = 5;
  static final Rx<RangeValues> selectedOwnershipRange =
      RangeValues(minOwnership.toDouble(), maxOwnership.toDouble()).obs;
  static final TextEditingController minOwnershipController =
      TextEditingController(text: '1');
  static final TextEditingController maxOwnershipController =
      TextEditingController(text: '5');

  // PRICE (in Lacs)
  static const double minPrice = 0;
  static const double maxPrice = 50;
  static final Rx<RangeValues> selectedPriceRange =
      const RangeValues(minPrice, maxPrice).obs; // default UI range

  // FUEL
  static final RxList<String> selectedFuelTypesFilter = <String>[].obs;

  // MAKE / MODEL / VARIANT / YEAR
  static final Rx<String?> selectedMakeFilter = Rx<String?>(null);
  static final Rx<String?> selectedModelFilter = Rx<String?>(null);
  static final Rx<String?> selectedVariantFilter = Rx<String?>(null);
  static final Rx<int?> selectedYearFilter = Rx<int?>(null);

  static final List<String> makesListFilter = [
    'Mahindra',
    'Renault',
    'Ford',
    'Maruti Suzuki',
    'Hyundai',
  ];

  static final Map<String, List<String>> modelsListFilter = {
    'Mahindra': ['Scorpio [2014-2017]', 'Verito', 'XUV500 [2011-2015]'],
    'Renault': ['Kiger [2022-2023]'],
    'Ford': ['Figo [2010-2012]'],
    'Maruti Suzuki': [
      'Alto K10',
      'S-Presso [2019-2022]',
      'Alto 800 [2012-2016]',
      'Swift',
    ],
    'Hyundai': ['Grand i10 Nios'],
  };

  static final Map<String, List<String>> variantsListFilter = {
    'Scorpio [2014-2017]': ['S10'],
    'Kiger [2022-2023]': ['RXZ MT'],
    'Verito': ['1.5 D6 BS-IV'],
    'XUV500 [2011-2015]': ['W8'],
    'Figo [2010-2012]': ['Duratec Petrol Titanium 1.2'],
    'Alto K10': ['VXi'],
    'S-Presso [2019-2022]': ['VXi AMT'],
    'Alto 800 [2012-2016]': ['Lxi'],
    'Swift': ['VXi (O)'],
    'Grand i10 Nios': ['Corporate1.2 Kappa'],
  };

  // ===================== APPLIED SNAPSHOT + FLOW =====================
  /// Are filters currently applied? (default: false)
  static final RxBool isFiltersApplied = false.obs;

  // Snapshot of what was applied on "Apply"
  static final RxSet<String> appliedFuelTypes = <String>{}.obs;
  static final Rxn<RangeValues> appliedPriceRange = Rxn<RangeValues>();
  static final RxInt appliedYear = 0.obs; // 0 = no year filter
  static final RxString appliedMake = ''.obs;
  static final RxString appliedModel = ''.obs;
  static final RxString appliedVariant = ''.obs;
  static final RxSet<String> appliedTransmissions = <String>{}.obs;
  static final Rxn<RangeValues> appliedKmsRange = Rxn<RangeValues>();
  static final Rxn<RangeValues> appliedOwnershipRange = Rxn<RangeValues>();

  /// User tapped "Apply" in the filter sheet: copy selected -> applied.
  static void applyFilters() {
    // Fuel
    appliedFuelTypes
      ..clear()
      ..addAll(selectedFuelTypesFilter);

    // Price
    appliedPriceRange.value = selectedPriceRange.value;

    // Year
    appliedYear.value = (selectedYearFilter.value ?? 0);

    // Make/Model/Variant
    appliedMake.value = (selectedMakeFilter.value ?? '').trim();
    appliedModel.value = (selectedModelFilter.value ?? '').trim();
    appliedVariant.value = (selectedVariantFilter.value ?? '').trim();

    // Transmission
    appliedTransmissions
      ..clear()
      ..addAll(selectedTransmissionFilter);

    // KMs
    appliedKmsRange.value = selectedKmsRange.value;

    // Ownership
    appliedOwnershipRange.value = selectedOwnershipRange.value;

    isFiltersApplied.value = true;
  }

  /// User tapped "Reset": clear applied snapshot and UI selections.
  static void resetFilters() {
    // Clear applied
    appliedFuelTypes.clear();
    appliedPriceRange.value = null;
    appliedYear.value = 0;
    appliedMake.value = '';
    appliedModel.value = '';
    appliedVariant.value = '';
    appliedTransmissions.clear();
    appliedKmsRange.value = null;
    appliedOwnershipRange.value = null;
    isFiltersApplied.value = false;

    // Reset UI selections
    selectedFuelTypesFilter.clear();
    selectedPriceRange.value = const RangeValues(minPrice, 20);
    selectedYearFilter.value = null;
    selectedMakeFilter.value = null;
    selectedModelFilter.value = null;
    selectedVariantFilter.value = null;
    selectedTransmissionFilter.clear();
    selectedKmsRange.value = const RangeValues(minKms, maxKms);
    selectedOwnershipRange.value = RangeValues(
      minOwnership.toDouble(),
      maxOwnership.toDouble(),
    );

    // sync text controllers
    minKmsController.text = minKms.toInt().toString();
    maxKmsController.text = maxKms.toInt().toString();
    minOwnershipController.text = minOwnership.toString();
    maxOwnershipController.text = maxOwnership.toString();
    // price: restore UI to slider default (minPrice..20)
    minPriceController.text = selectedPriceRange.value.start.toStringAsFixed(0);
    maxPriceController.text = selectedPriceRange.value.end.toStringAsFixed(0);
  }

  /// Normalize helper (trims + lowercase)
  static String _norm(String? s) => (s ?? '').trim().toLowerCase();

  /// Apply *all* non-state filters in one pass.
  /// - priceRangeLacs expects values in Lacs (same as UI)
  /// - year is exact match when provided
  /// - make/model/variant are case-insensitive exact matches when provided
  /// - fuel/transmissions are case-insensitive IN sets when provided
  /// - kms/ownership are inclusive ranges
  static List<CarsListModel> applyAllFilters({
    required List<CarsListModel> source,

    // fuel
    Set<String>? fuelTypes, // e.g. {'Petrol','Diesel'}; null/empty = no filter
    String Function(CarsListModel)? fuelOf,

    // price (Lacs in your UI)
    RangeValues? priceRangeLacs, // null = no filter
    num Function(CarsListModel)? priceOf, // default = priceDiscovery (Lacs)
    // year
    int? manufacturingYear, // null = no filter
    DateTime Function(CarsListModel)? yearOf,

    // make/model/variant
    String? make, // '' or null = no filter
    String? model, // '' or null = no filter
    String? variant, // '' or null = no filter
    String Function(CarsListModel)? makeOf,
    String Function(CarsListModel)? modelOf,
    String Function(CarsListModel)? variantOf,

    // transmission
    Set<String>? transmissions, // e.g. {'Manual','Automatic'}; ''/null ignored
    String Function(CarsListModel)? transmissionOf,

    // kms
    RangeValues? kmsRange, // null = no filter
    int Function(CarsListModel)? kmsOf,

    // ownership (serial no. as integer range)
    RangeValues? ownershipRange, // null = no filter
    int Function(CarsListModel)? ownershipOf,
  }) {
    // Field readers (null-safe defaults)
    final _fuelOf = fuelOf ?? (c) => c.fuelType;
    final _priceOf = priceOf ?? (c) => (c.priceDiscovery);
    final _yearOf = yearOf ?? (c) => c.yearMonthOfManufacture ?? DateTime(0);
    final _makeOf = makeOf ?? (c) => c.make;
    final _modelOf = modelOf ?? (c) => c.model;
    final _variantOf = variantOf ?? (c) => c.variant;
    // NOTE: use an explicit transmission field if you have it;
    // fall back to commentsOnTransmission to preserve current behavior.
    final _transOf = transmissionOf ?? (c) => c.commentsOnTransmission;
    final _kmsOf = kmsOf ?? (c) => c.odometerReadingInKms;
    final _ownOf = ownershipOf ?? (c) => c.ownerSerialNumber;

    // Normalize incoming filter values once
    final fuelsWanted =
        (fuelTypes ?? const {}).map(_norm).where((e) => e.isNotEmpty).toSet();
    final txsWanted =
        (transmissions ?? const {})
            .map(_norm)
            .where((e) => e.isNotEmpty)
            .toSet();

    final wantMake = _norm(make);
    final wantModel = _norm(model);
    final wantVariant = _norm(variant);

    // Clamp helpers for ranges (avoid NaNs / inverted ranges)
    bool _withinDouble(num v, RangeValues rv) =>
        v.toDouble() >= rv.start && v.toDouble() <= rv.end;

    return source.where((c) {
      // Fuel (case-insensitive IN set)
      if (fuelsWanted.isNotEmpty) {
        final carFuel = _norm(_fuelOf(c));
        if (!fuelsWanted.contains(carFuel)) return false;
      }

      // Price in Lacs (inclusive)
      if (priceRangeLacs != null) {
        final p = (_priceOf(c) as num?)?.toDouble() ?? 0.0;
        if (!_withinDouble(p, priceRangeLacs)) return false;
      }

      // Year (exact year match)
      if (manufacturingYear != null && manufacturingYear > 0) {
        final y = (_yearOf(c)).year;
        if (y != manufacturingYear) return false;
      }

      // Make / Model / Variant (case-insensitive exact match when provided)
      if (wantMake.isNotEmpty && _norm(_makeOf(c)) != wantMake) return false;
      if (wantModel.isNotEmpty && _norm(_modelOf(c)) != wantModel) return false;
      if (wantVariant.isNotEmpty && _norm(_variantOf(c)) != wantVariant)
        return false;

      // Transmission (case-insensitive IN set)
      if (txsWanted.isNotEmpty) {
        final raw = _norm(_transOf(c));

        String normalizedTx;
        if (raw.contains('auto'))
          normalizedTx = 'automatic';
        else if (raw.contains('manu'))
          normalizedTx = 'manual';
        else if (raw.contains('amt'))
          normalizedTx = 'amt';
        else if (raw.contains('cvt'))
          normalizedTx = 'cvt';
        else if (raw.contains('dct'))
          normalizedTx = 'dct';
        else
          normalizedTx = raw;

        if (!txsWanted.contains(normalizedTx)) return false;
      }

      // KMs (inclusive)
      if (kmsRange != null) {
        final kms = (_kmsOf(c)).toDouble();
        if (!_withinDouble(kms, kmsRange)) return false;
      }

      // Ownership (integers, inclusive)
      if (ownershipRange != null) {
        final o = (_ownOf(c)).toDouble();
        if (!_withinDouble(o, ownershipRange)) return false;
      }

      return true;
    }).toList();
  }
}
