import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:otobix/Models/Dealer%20Membership/dealer_membership_model.dart';
import 'package:otobix/Models/place_model.dart';
import 'package:otobix/Models/user_model.dart';
import 'package:otobix/Network/api_service.dart';
import 'package:otobix/Utils/app_constants.dart';
import 'package:otobix/Utils/app_urls.dart';
import 'package:otobix/Views/Login/login_page.dart';
import 'package:otobix/Widgets/terms_and_conditions_bottom_sheet_widget.dart';
import 'package:otobix/Widgets/toast_widget.dart';
import 'dart:convert';

class RegistrationFormController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    clearFields();
    filteredStates = List.from(indianStates);
    passwordController.clear();
    dealerNameController.clear();
    dealerEmailController.clear();
    dealershipNameController.clear();
    primaryContactPersonController.clear();
    primaryMobileController.clear();
    secondaryContactPersonController.clear();
    secondaryMobileController.clear();
    addressControllers.clear();
    addressPlaces.clear();
    selectedEntityType = null;
    selectedState = null;
    touchedFields.clear();

    formKey.currentState?.reset();

    // Ensure at least one address exists
    if (addressControllers.isEmpty) {
      addressControllers.add(TextEditingController());
    }

    // // Add listener for username change
    // dealerNameController.addListener(() {
    //   validateUsername();
    // });

    // NEW: load entity names for dropdown
    fetchEntityNames();
    fetchRegisterAsOptions();
  }

  @override
  void dispose() {
    super.dispose();
    dealerNameController.dispose();
    dealerEmailController.dispose();
    dealershipNameController.dispose();
    primaryContactPersonController.dispose();
    primaryMobileController.dispose();
    secondaryContactPersonController.dispose();
    secondaryMobileController.dispose();
    passwordController.dispose();
    for (var controller in addressControllers) {
      controller.dispose();
    }
  }

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  /// Track touched fields
  final Set<String> touchedFields = {};

  void markFieldTouched(String fieldKey) {
    touchedFields.add(fieldKey);
    update();
  }

  RxString usernameValidationError = ''.obs;

  RxBool isLoading = false.obs;
  String? selectedState;

  final RxList<String> entityTypes = <String>[].obs; // used by dropdown
  String? selectedEntityType;

  // "Register as": New Car Dealer, Used Car Dealer or Broker, each with the
  // plans it gets (from the server; the fallback has no plan details).
  List<DealerRegisterAsModel> registerAsOptions = const [
    DealerRegisterAsModel('New-Car Dealer', 'New Car Dealer'),
    DealerRegisterAsModel('Used Car Dealer', 'Used Car Dealer'),
    DealerRegisterAsModel('Broker', 'Broker'),
  ];
  String? selectedDealerType;

  List<String> filteredStates = [];
  List<String> indianStates = AppConstants.indianStates;

  final RxBool obscurePassword = true.obs;

  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController dealerNameController = TextEditingController();
  final TextEditingController dealerEmailController = TextEditingController();
  final TextEditingController dealershipNameController =
      TextEditingController();
  final TextEditingController primaryContactPersonController =
      TextEditingController();
  final TextEditingController primaryMobileController = TextEditingController();
  final TextEditingController secondaryContactPersonController =
      TextEditingController();
  final TextEditingController secondaryMobileController =
      TextEditingController();

  List<TextEditingController> addressControllers = [];

  /// The place picked from the suggestions for an address field. The first
  /// address with one is sent as the showroom location, which puts this
  /// dealer's cars in nearest-first order for other dealers.
  final Map<TextEditingController, PlaceDetailsModel> addressPlaces = {};

  void setAddressPlace(
    TextEditingController controller,
    PlaceDetailsModel place,
  ) {
    addressPlaces[controller] = place;
    if (selectedState == null) {
      final state = place.state.toLowerCase();
      selectedState = indianStates.firstWhereOrNull(
        (s) => s.toLowerCase() == state,
      );
    }
    update();
  }

  void clearAddressPlace(TextEditingController controller) {
    addressPlaces.remove(controller);
  }

  void filterStates(String query) {
    if (query.isEmpty) {
      filteredStates = List.from(indianStates);
    } else {
      filteredStates =
          indianStates
              .where(
                (state) => state.toLowerCase().contains(query.toLowerCase()),
              )
              .toList();
    }
    update();
  }

  void selectState(String state) {
    selectedState = state;
    update();
  }

  void addAddressField() {
    addressControllers.add(TextEditingController());
    update();
  }

  void removeAddressField(int index) {
    addressPlaces.remove(addressControllers.removeAt(index));
    update();
  }

  Future<void> submitForm({
    required String userRole,
    required String contactNumber,
    required String verificationToken,
  }) async {
    try {
      // Trigger username check
      bool isUsernameValid = await validateUsername();

      // Validate form
      bool isFormValid = formKey.currentState!.validate();

      if (!isUsernameValid || !isFormValid) {
        // Show toast
        ToastWidget.show(
          context: Get.context!,
          title: "Please fill all required fields",
          type: ToastType.error,
        );

        // Mark all required fields as touched so errors show
        touchedFields.addAll([
          "State",
          "Dealer Name",
          "Dealer Email",
          "Dealership Name",
          "Entity Type",
          "Primary Contact Person",
          "Primary Contact Mobile No.",
          "Password",
        ]);

        update();
        return;
      }

      isLoading.value = true;

      final userModel = UserModel(
        userRole: userRole,
        location: selectedState ?? "",
        userName: dealerNameController.text.trim(),
        email: dealerEmailController.text.trim(),
        dealershipName: dealershipNameController.text.trim(),
        entityType: selectedEntityType ?? "",
        primaryContactPerson: primaryContactPersonController.text.trim(),
        primaryContactNumber: primaryMobileController.text.trim(),
        password: passwordController.text,
        phoneNumber: contactNumber,
        secondaryContactPerson:
            secondaryContactPersonController.text.isEmpty
                ? null
                : secondaryContactPersonController.text.trim(),
        secondaryContactNumber:
            secondaryMobileController.text.isEmpty
                ? null
                : secondaryMobileController.text.trim(),
        addressList: addressControllers.map((e) => e.text).toList(),
        id: '',
        approvalStatus: 'Pending',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final showroom =
          addressControllers
              .map((c) => addressPlaces[c])
              .whereType<PlaceDetailsModel>()
              .firstOrNull;

      // Add verification token to the request body
      final requestBody = {
        ...userModel.toJson(),
        "otpVerificationToken": verificationToken,
        if (userRole == AppConstants.roles.dealer)
          "dealerType": selectedDealerType,
        if (showroom != null)
          "showroomLocation": {
            "latitude": showroom.latitude,
            "longitude": showroom.longitude,
          },
      };

      final response = await ApiService.post(
        endpoint: AppUrls.register,
        body: requestBody,
      );

      // debugPrint("Status Code → ${response.statusCode}");
      // debugPrint("Response → ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        ToastWidget.show(
          context: Get.context!,
          title: "registered successfully!",
          type: ToastType.success,
        );
        Get.offAll(() => LoginPage());
      } else if (response.statusCode == 400) {
        Map<String, dynamic> responseBody = jsonDecode(response.body);
        String errorMessage =
            responseBody['message'] ?? 'Failed to register user';
        ToastWidget.show(
          context: Get.context!,
          title: 'Failed',
          subtitle: errorMessage,
          toastDuration: 10,
          type: ToastType.error,
        );
      } else {
        ToastWidget.show(
          context: Get.context!,
          title: "Failed",
          subtitle: "Failed to register user",
          type: ToastType.error,
        );
      }
    } catch (e, stacktrace) {
      debugPrint("Error → $e");
      debugPrint("Stacktrace → $stacktrace");
      ToastWidget.show(
        context: Get.context!,
        title: "Error",
        subtitle: "Error registering user",
        type: ToastType.error,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Future<void> dummySubmitForm({required String userRole}) async {
  //   try {
  //     isLoading.value = true;
  //     await Future.delayed(const Duration(seconds: 2));
  //     final docs = await _fetchEntityDocuments(selectedEntityType ?? '');
  //     Get.to(
  //       () => WaitingForApprovalPage(
  //         // documents:  entityDocuments[selectedEntityType ?? 'Individual'] ??
  //         //   entityDocuments['Individual']!,
  //         documents: docs,
  //         userRole: userRole,
  //       ),
  //     );
  //   } catch (e) {
  //     debugPrint(e.toString());
  //   } finally {
  //     isLoading.value = false;
  //   }
  // }

  Future<bool> validateUsername() async {
    String userName = dealerNameController.text.trim();

    // ✅ Only if valid format, then check API for availability
    try {
      final response = await ApiService.post(
        endpoint: AppUrls.checkUsernameExists(userName),
        body: {},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        final bool isAvailable = data['available'] == true;

        if (isAvailable) {
          usernameValidationError.value = "Username is available ";
          return true;
        } else {
          usernameValidationError.value = "Username already exists";
          return false;
        }
      } else {
        usernameValidationError.value = "Error checking username";
        return false;
      }
    } catch (e) {
      debugPrint("Username validation error → $e");
      usernameValidationError.value = "Error checking username";
      return false;
    }
  }

  // Clear fields
  void clearFields() {
    dealerNameController.clear();
    dealerEmailController.clear();
    dealershipNameController.clear();
    primaryContactPersonController.clear();
    primaryMobileController.clear();
    secondaryContactPersonController.clear();
    secondaryMobileController.clear();
    passwordController.clear();

    obscurePassword.value = true;
    selectedEntityType = null;
    selectedDealerType = null;
    selectedState = null;

    addressControllers.clear();
    addressControllers.add(TextEditingController());
    addressPlaces.clear();

    // 🔁 Reset validation-related data
    formKey.currentState?.reset();
    usernameValidationError.value = '';
    touchedFields.clear();

    // 🔁 Reset state filtering if needed
    filteredStates = List.from(indianStates);

    update();
  }

  /// Call this from the Submit button.
  Future<void> showTermsAndConditionsThenSubmit({
    required String userRole,
    required String contactNumber,
    required String verificationToken,
  }) async {
    // 1) run same validations you already have
    final okUser = await validateUsername();
    final okForm = formKey.currentState?.validate() ?? false;

    if (!okUser || !okForm) {
      ToastWidget.show(
        context: Get.context!,
        title: "Please fill all required fields",
        type: ToastType.error,
      );

      touchedFields.addAll([
        "State",
        "Dealer Name",
        "Dealer Email",
        "Dealership Name",
        "Entity Type",
        "Primary Contact Person",
        "Primary Contact Mobile No.",
        "Password",
      ]);
      update();
      return;
    }

    // 2) fetch latest terms
    String title = 'Terms & Conditions';
    String html = '';
    try {
      isLoading.value = true;
      final resp = await ApiService.get(
        endpoint: AppUrls.getLatestTermsAndConditions,
      );
      if (resp.statusCode == 200 && resp.body.isNotEmpty) {
        final parsed = jsonDecode(resp.body) as Map<String, dynamic>;
        final data = parsed['data'] as Map<String, dynamic>?;
        if (data != null) {
          title =
              (data['title'] as String?)?.trim().isNotEmpty == true
                  ? data['title'] as String
                  : title;
          html = (data['content'] as String?) ?? '';
        }
      }
    } catch (e) {
      debugPrint('Failed to load terms: $e');
    } finally {
      isLoading.value = false;
    }

    // If no terms & conditions found in database, submit form directly
    if (html.trim().isEmpty) {
      submitForm(
        userRole: userRole,
        contactNumber: contactNumber,
        verificationToken: verificationToken,
      );
      return;
    }

    // 3) show bottom sheet; on agree run the real submit
    await Get.bottomSheet(
      TermsAndConditionsBottomSheetWidget(
        title: title,
        html: html,
        onAgree: () {
          submitForm(
            userRole: userRole,
            contactNumber: contactNumber,
            verificationToken: verificationToken,
          );
        },
      ),
      isScrollControlled: true, // allow tall sheet
      enableDrag: false,
      ignoreSafeArea: false,
      backgroundColor: Colors.transparent,
    );
  }

  // Fetch entity names from API
  Future<void> fetchEntityNames() async {
    try {
      final resp = await ApiService.get(endpoint: AppUrls.getEntityNamesList);
      if (resp.statusCode == 200) {
        final json = jsonDecode(resp.body) as Map<String, dynamic>;
        final List list = (json['data'] ?? []) as List;
        final names = list.map<String>((e) => '${e['name']}').toList();
        entityTypes.assignAll(names);
      } else {
        // optional fallback
        entityTypes.assignAll([
          'Individual',
          'Proprietary',
          'HUF',
          'Partnership',
          'LLP',
          'Ltd/Private Limited',
          'One person Company',
        ]);
      }
    } catch (e) {
      // optional fallback
      entityTypes.assignAll([
        'Individual',
        'Proprietary',
        'HUF',
        'Partnership',
        'LLP',
        'Ltd/Private Limited',
        'One person Company',
      ]);
    }
    update(); // refresh GetBuilder
  }

  Future<void> fetchRegisterAsOptions() async {
    try {
      final resp = await ApiService.get(
        endpoint: AppUrls.dealerRegistrationOptions,
      );
      if (resp.statusCode != 200) return;
      final data = (jsonDecode(resp.body) as Map<String, dynamic>)['data'];
      final options = [
        for (final o in (data?['options'] as List? ?? const []))
          if (o is Map)
            DealerRegisterAsModel.fromJson(Map<String, dynamic>.from(o)),
      ];
      if (options.isNotEmpty) registerAsOptions = options;
      update();
    } catch (e) {
      debugPrint('Register-as options not loaded: $e');
    }
  }

  // // Fetch entity documents
  // Future<List<String>> _fetchEntityDocuments(String? entityType) async {
  //   final fallback = <String>[
  //     // optional: keep empty list if you don't want a fallback
  //     'No documents found',
  //   ];

  //   if (entityType == null || entityType.trim().isEmpty) return fallback;

  //   try {
  //     final response = await ApiService.get(
  //       endpoint: AppUrls.getEntityDocumentsByName(
  //         entityName: entityType.trim(),
  //       ),
  //     );

  //     if (response.statusCode == 200) {
  //       final json = jsonDecode(response.body) as Map<String, dynamic>;
  //       final data = (json['data'] ?? {}) as Map<String, dynamic>;
  //       final docs = (data['documents'] ?? []) as List;
  //       return docs.map((e) => '$e').toList();
  //     }
  //   } catch (error) {
  //     // ignore and use fallback
  //     debugPrint("Error: $error");
  //   }
  //   return fallback;
  // }
}
