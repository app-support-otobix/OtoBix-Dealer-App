import 'dart:async';
import 'dart:math';

import 'package:get/get.dart';
import 'package:otobix/Controllers/Dealer%20Membership/dealer_membership_controller.dart';
import 'package:otobix/Controllers/Dealer%20Membership/dealer_requirements_controller.dart';
import 'package:otobix/Network/dealer_membership_api.dart';
import 'package:otobix/Utils/app_constants.dart';
import 'package:otobix/Utils/app_urls.dart';
import 'package:otobix/Utils/global_functions.dart';
import 'package:otobix/Widgets/toast_widget.dart';
import 'package:otobix/helpers/shared_prefs_helper.dart';

class DealerFinanceController extends GetxController {
  static const carTypes = ['Used Car', 'New Car', 'Loan Against Car'];
  static const minLoan = 50000.0;
  static const maxLoan = 5000000.0;
  static const minTenure = 12;
  static const maxTenure = 96;
  static const minRate = 13.5;
  static const maxRate = 17.5;

  final catalogue = DealerRequirementsController.to;

  final loanAmount = 500000.0.obs;
  final tenureMonths = 60.obs;
  final interestRate = minRate.obs;

  final carType = carTypes.first.obs;
  final make = ''.obs;
  final model = ''.obs;
  final variant = ''.obs;
  final variantOptions = <String>[].obs;
  final isVariantLoading = false.obs;
  Timer? _variantDebounce;

  final isSubmitting = false.obs;
  final error = ''.obs;

  @override
  void onInit() {
    super.onInit();
    catalogue.fetchMakes('');
  }

  @override
  void onClose() {
    _variantDebounce?.cancel();
    super.onClose();
  }

  double get monthlyEmi {
    final p = loanAmount.value;
    final n = tenureMonths.value;
    final r = interestRate.value / 12 / 100;
    if (r == 0) return p / n;
    final f = pow(1 + r, n);
    return p * r * f / (f - 1);
  }

  double get totalPayable => monthlyEmi * tenureMonths.value;
  double get totalInterest => totalPayable - loanAmount.value;

  void pickMake(String value) {
    make.value = value;
    model.value = '';
    variant.value = '';
    catalogue.fetchModels(make: value, query: '');
  }

  void pickModel(String value) {
    model.value = value;
    variant.value = '';
    fetchVariants('');
  }

  void onVariantSearchChanged(String q) {
    _variantDebounce?.cancel();
    _variantDebounce = Timer(
      const Duration(milliseconds: 350),
      () => fetchVariants(q.trim()),
    );
  }

  Future<void> fetchVariants(String query) async {
    if (model.value.isEmpty) return;
    isVariantLoading.value = true;
    try {
      final data = await DealerMembershipApi.post(
        AppUrls.searchCarVariantsByMakeModel,
        {'make': make.value, 'model': model.value, 'q': query, 'limit': 30},
      );
      variantOptions.assignAll((data as List).map((e) => e.toString()));
    } on DealerApiException {
      variantOptions.clear();
    } finally {
      isVariantLoading.value = false;
    }
  }

  Future<bool> submit({
    required String customerName,
    required String customerMobile,
    required String registration,
    required String year,
  }) async {
    if (isSubmitting.value) return false;
    final name = customerName.trim();
    final mobile = customerMobile.replaceAll(RegExp(r'\D'), '');
    final reg = GlobalFunctions.normalizeRegistration(registration);
    final yearValue = int.tryParse(year.trim());
    final problem =
        name.isEmpty
            ? "Enter the customer's name."
            : !RegExp(r'^[6-9][0-9]{9}$').hasMatch(mobile)
            ? "Enter the customer's 10 digit mobile number."
            : make.value.isEmpty || model.value.isEmpty
            ? 'Select the car make and model.'
            : reg.isNotEmpty && !GlobalFunctions.isValidRegistration(reg)
            ? 'Enter a valid registration number, or leave it empty.'
            : year.trim().isNotEmpty &&
                (yearValue == null ||
                    yearValue < 1990 ||
                    yearValue > DateTime.now().year)
            ? 'Enter a valid year of manufacture, or leave it empty.'
            : null;
    error.value = problem ?? '';
    if (problem != null) return false;

    isSubmitting.value = true;
    try {
      final dealer = DealerMembershipController.to.membership.value;
      await DealerMembershipApi.post(AppUrls.addTelecallingRequest, {
        'carRegistrationNumber': reg.isEmpty ? 'NA' : reg,
        'yearOfRegistration': 'NA',
        'ownerName': name,
        'ownershipSerialNumber': '0',
        'make': make.value,
        'model': model.value,
        'variant': variant.value.isEmpty ? 'NA' : variant.value,
        'yearOfManufacture': year.trim(),
        'customerContactNumber': mobile,
        'appointmentSource': AppConstants.appDisplayName,
        'priority': 'Medium',
        'createdBy':
            await SharedPrefsHelper.getString(SharedPrefsHelper.userIdKey) ??
            '',
        'inspectionRequestedThrough': 'Finance',
        'addedBy': 'Dealer (Seller)',
        'additionalNotes': [
          if (dealer != null && dealer.dealerCode.isNotEmpty)
            'Requested by dealer ${dealer.dealerCode}',
          'Car Type: ${carType.value}',
          'Loan Amount: ${GlobalFunctions.formatRupees(loanAmount.value)}',
          'Tenure: ${tenureMonths.value} months',
          'Interest Rate: ${interestRate.value}%',
          'Monthly EMI: ${GlobalFunctions.formatRupees(monthlyEmi)}',
        ].join('\n'),
      });
      _toastSent(name);
      return true;
    } on DealerApiException catch (e) {
      error.value = e.message;
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  void _toastSent(String name) {
    final context = Get.context;
    if (context == null) return;
    ToastWidget.show(
      context: context,
      title: 'Finance request sent',
      subtitle: 'The OtoBix finance team will call $name shortly.',
      type: ToastType.success,
    );
  }
}
