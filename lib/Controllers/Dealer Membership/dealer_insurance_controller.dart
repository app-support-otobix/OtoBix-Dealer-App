import 'package:get/get.dart';
import 'package:otobix/Models/Dealer%20Membership/dealer_insurance_model.dart';
import 'package:otobix/Network/dealer_membership_api.dart';
import 'package:otobix/Utils/app_urls.dart';
import 'package:otobix/Utils/global_functions.dart';
import 'package:otobix/helpers/shared_prefs_helper.dart';

class DealerInsuranceOptionList {
  final names = <String>[].obs;
  final isLoading = false.obs;
  final _items = <DealerInsuranceOption>[];

  void set(Iterable<DealerInsuranceOption> items) {
    _items
      ..clear()
      ..addAll(items.where((o) => o.name.isNotEmpty));
    names.assignAll(_items.map((o) => o.name));
  }

  DealerInsuranceOption? byName(String name) =>
      _items.firstWhereOrNull((o) => o.name == name);
}

class DealerInsuranceController extends GetxController {
  static const policyTypes = {
    'Comprehensive': 'Comprehensive',
    'Third Party': 'TP',
  };
  static const ownerTypes = {'Individual': 1, 'Corporate': 2};

  final isNewCar = false.obs;
  final policyType = 'Comprehensive'.obs;
  final ownerType = 1.obs;

  final rtos = DealerInsuranceOptionList();
  final makes = DealerInsuranceOptionList();
  final models = DealerInsuranceOptionList();
  final variants = DealerInsuranceOptionList();
  final rto = Rxn<DealerInsuranceOption>();
  final make = Rxn<DealerInsuranceOption>();
  final model = Rxn<DealerInsuranceOption>();
  final variant = Rxn<DealerInsuranceOption>();
  final manufacturingMonth = Rxn<DateTime>();

  final isFetching = false.obs;
  final error = ''.obs;
  final result = Rxn<DealerInsuranceQuoteReportModel>();

  final history = <DealerInsuranceQuoteReportModel>[].obs;
  final isLoadingHistory = false.obs;
  final historyError = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadHistory();
  }

  void setNewCar(bool value) {
    isNewCar.value = value;
    error.value = '';
    result.value = null;
    if (value && makes.names.isEmpty) {
      _loadOptions(rtos, AppUrls.insuranceRtoList, DealerInsuranceOption.rto);
      _loadOptions(
        makes,
        AppUrls.insuranceMakesList,
        DealerInsuranceOption.make,
      );
    }
  }

  void pickMake(String name) {
    make.value = makes.byName(name);
    model.value = null;
    variant.value = null;
    variants.set(const []);
    final id = make.value?.id ?? 0;
    if (id > 0) {
      _loadOptions(
        models,
        AppUrls.insuranceModelsList(id),
        DealerInsuranceOption.model,
      );
    }
  }

  void pickModel(String name) {
    model.value = models.byName(name);
    variant.value = null;
    final id = model.value?.id ?? 0;
    if (id > 0) {
      _loadOptions(
        variants,
        AppUrls.insuranceVariantsList(id),
        DealerInsuranceOption.variant,
      );
    }
  }

  Future<void> _loadOptions(
    DealerInsuranceOptionList list,
    String url,
    DealerInsuranceOption Function(Map<String, dynamic>) parse,
  ) async {
    list.isLoading.value = true;
    list.set(const []);
    try {
      final data = await DealerMembershipApi.get(url);
      list.set(
        (data as List? ?? const []).whereType<Map>().map(
          (e) => parse(Map<String, dynamic>.from(e)),
        ),
      );
    } on DealerApiException catch (e) {
      error.value = e.message;
    } finally {
      list.isLoading.value = false;
    }
  }

  Future<void> fetchQuotes(String registration) async {
    if (isFetching.value) return;
    final body = <String, dynamic>{
      'userId':
          await SharedPrefsHelper.getString(SharedPrefsHelper.userIdKey) ?? '',
    };
    if (isNewCar.value) {
      final problem =
          rto.value == null
              ? 'Select the RTO the car will be registered at.'
              : make.value == null || model.value == null
              ? 'Select the make and model.'
              : variant.value == null
              ? 'Select the variant.'
              : manufacturingMonth.value == null
              ? 'Select the month of manufacture.'
              : null;
      if (problem != null) {
        error.value = problem;
        return;
      }
      final m = manufacturingMonth.value!;
      body.addAll({
        'carType': 'New Car',
        'policyType': 'New',
        'makeId': make.value!.id,
        'modelId': model.value!.id,
        'variantId': variant.value!.id,
        'fuelTypeId': variant.value!.fuelTypeId,
        'registeredCityId': rto.value!.id,
        'regionCode': rto.value!.regionCode,
        'stateName': rto.value!.stateName,
        'cityName': rto.value!.cityName,
        'manufacturingDate':
            '${m.year}-${m.month.toString().padLeft(2, '0')}-01T00:00:00.000Z',
        'vehicleOwnedBy': ownerType.value,
        'makeName': make.value!.name,
        'modelName': model.value!.name,
        'variantName': variant.value!.name,
        'fuelType': variant.value!.fuelType,
      });
    } else {
      final reg = GlobalFunctions.normalizeRegistration(registration);
      if (!GlobalFunctions.isValidRegistration(reg)) {
        error.value = 'Enter a valid registration number, e.g. WB02AB1234';
        return;
      }
      body.addAll({
        'carType': 'Used Car',
        'registrationNumber': reg,
        'policyType': policyType.value,
      });
    }

    error.value = '';
    result.value = null;
    isFetching.value = true;
    try {
      final data = Map<String, dynamic>.from(
        await DealerMembershipApi.post(AppUrls.insuranceFetchQuotes, body),
      );
      result.value = DealerInsuranceQuoteReportModel.fromJson({
        ...body,
        ...data,
      });
      if (result.value!.quotes.isEmpty) {
        error.value = 'PolicyBazaar has no quotes for this car right now.';
      }
      loadHistory();
    } on DealerApiException catch (e) {
      error.value = e.message;
    } finally {
      isFetching.value = false;
    }
  }

  Future<void> loadHistory() async {
    isLoadingHistory.value = true;
    historyError.value = '';
    try {
      final data = await DealerMembershipApi.get(
        AppUrls.insuranceGeneratedQuotes,
      );
      history.assignAll(
        (data as List? ?? const []).whereType<Map>().map(
          (e) => DealerInsuranceQuoteReportModel.fromJson(
            Map<String, dynamic>.from(e),
          ),
        ),
      );
    } on DealerApiException catch (e) {
      historyError.value = e.message;
    } finally {
      isLoadingHistory.value = false;
    }
  }
}
