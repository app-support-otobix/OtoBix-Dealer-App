import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:otobix/Controllers/Dealer%20Membership/dealer_inventory_controller.dart';
import 'package:otobix/Controllers/Dealer%20Membership/dealer_membership_controller.dart';
import 'package:otobix/Models/Dealer%20Membership/dealer_inventory_car_model.dart';
import 'package:otobix/Utils/app_colors.dart';
import 'package:otobix/Utils/global_functions.dart';
import 'package:otobix/Widgets/Dealer%20Membership/car_images_picker.dart';
import 'package:otobix/Widgets/Dealer%20Membership/dealer_common_widgets.dart';
import 'package:otobix/Widgets/Dealer%20Membership/vehicle_spec_sheet.dart';
import 'package:otobix/Widgets/address_search_field.dart';
import 'package:otobix/Widgets/app_bar_widget.dart';
import 'package:otobix/Widgets/button_widget.dart';

class CarIntakePage extends StatefulWidget {
  final String ownership;
  final DealerInventoryCarModel? car;

  const CarIntakePage({super.key, required this.ownership, this.car});

  @override
  State<CarIntakePage> createState() => _CarIntakePageState();
}

class _CarIntakePageState extends State<CarIntakePage> {
  final controller = DealerInventoryController.to;
  final membership = DealerMembershipController.to;

  final _reg = TextEditingController();
  final _kms = TextEditingController();
  final _retailPrice = TextEditingController();
  final _exchangePrice = TextEditingController();
  final _description = TextEditingController();
  final _city = TextEditingController();
  final _customerName = TextEditingController();
  final _customerPhone = TextEditingController();
  final _isFetching = false.obs;

  // A customer car's own place: other dealers' distances are measured to it.
  // A dealer's own car is at their showroom, known since registration.
  final _carAddress = TextEditingController();
  double? _carLat;
  double? _carLng;

  DealerRcPrefillModel? _facts;
  String? _transmission;
  bool _exchangeEnabled = true;
  String _visibility = 'OPEN';
  List<String> _imageUrls = [];
  int _imagesNotReady = 0;
  String? _error;
  String? _regError;

  bool get _isEdit => widget.car != null;
  bool get _isCustomerCar =>
      widget.ownership == DealerInventoryCarModel.customerOwned;

  static const _visibilities = {
    'OPEN': 'Open Dealer Exchange',
    'REQUIREMENT': 'Requirement matched',
    'PAUSED': 'Paused',
  };

  @override
  void initState() {
    super.initState();
    membership.ensureConfig();
    final car = widget.car;
    if (car != null) {
      _facts = DealerRcPrefillModel.fromCar(car);
      _reg.text = car.registrationNumber;
      _transmission = car.transmission.isEmpty ? null : car.transmission;
      _kms.text = car.kms > 0 ? '${car.kms}' : '';
      _retailPrice.text = car.retailPrice > 0 ? '${car.retailPrice}' : '';
      _exchangePrice.text = car.exchangePrice > 0 ? '${car.exchangePrice}' : '';
      _exchangeEnabled = car.isCustomerCar || car.exchangeEnabled;
      _visibility =
          _visibilities.containsKey(car.exchangeVisibility)
              ? car.exchangeVisibility
              : 'OPEN';
      _description.text = car.description;
      _city.text = car.city;
      _customerName.text = car.customerName;
      _customerPhone.text = car.customerPhone;
      _carAddress.text = car.carAddress;
      _carLat = car.carLatitude;
      _carLng = car.carLongitude;
      _imageUrls = List.of(car.images);
    } else if (!_isCustomerCar) {
      // A dealer's own car is in their city; a customer's car takes the city
      // of the place picked for it (or the RC's).
      _city.text = membership.membership.value?.city ?? '';
    }
  }

  @override
  void dispose() {
    for (final c in [
      _reg,
      _kms,
      _retailPrice,
      _exchangePrice,
      _description,
      _city,
      _customerName,
      _customerPhone,
      _carAddress,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _fetchDetails() async {
    final reg = GlobalFunctions.normalizeRegistration(_reg.text);
    if (!GlobalFunctions.isValidRegistration(reg)) {
      setState(
        () => _regError = 'Enter a valid registration number, e.g. WB02AB1234.',
      );
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _regError = null);
    _isFetching.value = true;
    final facts = await controller.fetchDetails(reg);
    _isFetching.value = false;
    if (facts == null || !mounted) return;
    setState(() {
      _facts = facts;
      if (_city.text.trim().isEmpty && facts.rto.contains(',')) {
        _city.text = facts.rto.split(',').first.trim();
      }
    });
  }

  int _amount(TextEditingController c) =>
      int.tryParse(c.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

  String? _validate() {
    if (_facts == null) return 'Fetch the vehicle details first.';
    if (_transmission == null) return 'Select the transmission.';
    if (_imagesNotReady > 0) {
      return 'Wait for the photos to finish uploading, or remove the ones that failed.';
    }
    if (_imageUrls.isEmpty) return 'Add at least one car photo.';
    if (_amount(_kms) <= 0) return 'Enter the kilometers driven.';
    if (_isCustomerCar) {
      if (_carLat == null || _carLng == null) {
        return "Add where the car is: search the customer's address or use your current location.";
      }
      if (_city.text.trim().isEmpty) return 'Enter the city the car is in.';
      if (_amount(_exchangePrice) <= 0) return 'Enter the expected price.';
      final phone = _customerPhone.text.trim();
      if (phone.isNotEmpty && !RegExp(r'^[6-9][0-9]{9}$').hasMatch(phone)) {
        return "Enter the customer's 10 digit mobile number.";
      }
    } else {
      if (_amount(_retailPrice) <= 0 && !_exchangeEnabled) {
        return 'Add a retail price or turn on Offer to Dealers.';
      }
      if (_exchangeEnabled && _amount(_exchangePrice) <= 0) {
        return 'Enter the Dealer Exchange price.';
      }
    }
    return null;
  }

  Future<void> _save() async {
    final error = _validate();
    setState(() => _error = error);
    if (error != null) return;
    if (!_isEdit && !membership.requireMembership()) return;

    final body = <String, dynamic>{
      ..._facts!.toJson(),
      'ownership': widget.ownership,
      'transmission': _transmission,
      'images': _imageUrls,
      'kms': _amount(_kms),
      // A dealer's own car: the dealer's city (the server fills it in when blank).
      if (_isCustomerCar || _city.text.trim().isNotEmpty)
        'city': _city.text.trim(),
      'description': _description.text.trim(),
      'exchangeEnabled': _isCustomerCar || _exchangeEnabled,
      'exchangePrice': _amount(_exchangePrice),
      'exchangeVisibility': _visibility,
      if (!_isCustomerCar) ...{
        'retailEnabled': _amount(_retailPrice) > 0,
        'retailPrice': _amount(_retailPrice),
      },
      if (_isCustomerCar) ...{
        'customerName': _customerName.text.trim(),
        'customerPhone': _customerPhone.text.trim(),
        'carLocation': {
          'latitude': _carLat,
          'longitude': _carLng,
          'address': _carAddress.text.trim(),
        },
      },
    };
    if (_isEdit) body.remove('registrationNumber');

    final saved = await controller.saveCar(body, id: widget.car?.id);
    if (saved && mounted) Get.back();
  }

  Future<void> _changeStatus(String status) async {
    final car = widget.car!;
    final labels = {
      'PAUSED': 'Pause this listing?',
      'LIVE': 'Relist this car?',
      'SOLD': 'Mark this car as sold?',
      'ARCHIVED': 'Remove this car?',
    };
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text(
          labels[status] ?? 'Update status?',
          style: const TextStyle(fontSize: 16),
        ),
        content: Text(
          status == 'SOLD' || status == 'ARCHIVED'
              ? 'The listing closes for everyone and cannot be reopened.'
              : status == 'PAUSED'
              ? 'Dealers will not see it until you relist it.'
              : 'It becomes visible again and counts towards your listing limit.',
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text(
              'Confirm',
              style: TextStyle(color: AppColors.green),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (await controller.setStatus(car, status) && mounted) Get.back();
  }

  @override
  Widget build(BuildContext context) {
    final car = widget.car;
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBarWidget(
        title:
            car?.title ??
            (_isCustomerCar ? 'Add Customer Car' : 'Upload a Car'),
        actions: [
          if (car != null)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: AppColors.green),
              onSelected: _changeStatus,
              itemBuilder:
                  (_) => [
                    if (car.status == 'LIVE')
                      const PopupMenuItem(
                        value: 'PAUSED',
                        child: Text('Pause listing'),
                      ),
                    if (car.status == 'PAUSED')
                      const PopupMenuItem(value: 'LIVE', child: Text('Relist')),
                    const PopupMenuItem(
                      value: 'SOLD',
                      child: Text('Mark as sold'),
                    ),
                    const PopupMenuItem(
                      value: 'ARCHIVED',
                      child: Text('Remove'),
                    ),
                  ],
            ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(10),
          children: [
            if (!_isEdit) ...[_documentsCard(), const SizedBox(height: 8)],
            if (_facts != null) ...[_vehicleCard(), const SizedBox(height: 8)],
            DealerSectionCard(
              padding: const EdgeInsets.all(10),
              title: 'Car Images',
              child: Obx(
                () => CarImagesPicker(
                  maxImageCount: membership.config.value?.maxCarImages ?? 14,
                  initialUrls: widget.car?.images ?? const [],
                  onChanged:
                      (urls, notReady) => setState(() {
                        _imageUrls = urls;
                        _imagesNotReady = notReady;
                      }),
                ),
              ),
            ),
            const SizedBox(height: 8),
            _listingCard(),
            if (_isCustomerCar) ...[const SizedBox(height: 8), _customerCard()],
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  _error!,
                  style: const TextStyle(color: AppColors.red, fontSize: 12),
                ),
              ),
            const SizedBox(height: 12),
            ButtonWidget(
              text:
                  _isEdit
                      ? 'Save Changes'
                      : (_isCustomerCar
                          ? 'Publish to Dealer Exchange'
                          : 'Save & List Car'),
              isLoading: controller.isSaving,
              width: double.infinity,
              height: 40,
              onTap: _save,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _documentsCard() {
    return DealerSectionCard(
      padding: const EdgeInsets.all(10),
      title: 'Documents — auto-filled',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _reg,
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9 ]')),
                    LengthLimitingTextInputFormatter(13),
                  ],
                  onChanged: (_) {
                    if (_facts != null || _regError != null) {
                      setState(() {
                        _facts = null;
                        _regError = null;
                      });
                    }
                  },
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'e.g. WB02AB1234',
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ButtonWidget(
                text: 'Fetch Details',
                isLoading: _isFetching,
                width: 110,
                height: 36,
                fontSize: 13,
                onTap: _fetchDetails,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _regError ??
                'Fetch Details pulls the vehicle specs, registration, ownership, tax & insurance from the RC.',
            style: TextStyle(
              fontSize: _regError == null ? 10 : 12,
              color: _regError == null ? AppColors.grey : AppColors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _vehicleCard() {
    final f = _facts!;
    final transmissions =
        membership.config.value?.transmissions ?? const ['Manual', 'Automatic'];
    return DealerSectionCard(
      padding: const EdgeInsets.all(10),
      title: 'Vehicle — auto-filled',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          VehicleSpecSheet(
            labelSize: 12,
            valueSize: 15,
            specs: [
              ('Registration', f.registrationNumber),
              ('Make', f.make),
              ('Model', f.model),
              ('Variant', f.variant),
              ('Mfg Year', f.mfgYear > 0 ? '${f.mfgYear}' : ''),
              ('Reg Year', f.regnYear > 0 ? '${f.regnYear}' : ''),
              ('Own Srl No', f.ownerSerialNo > 0 ? '${f.ownerSerialNo}' : ''),
              ('Fuel Type', f.fuelType),
              ('Colour', f.colour),
              ('Tax Validity', f.taxValidity),
              ('Insurance Validity', f.insuranceValidity),
              ('RTO', f.rto),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Transmission',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            children: [
              for (final t in transmissions)
                ChoiceChip(
                  label: Text(t, style: const TextStyle(fontSize: 12)),
                  visualDensity: VisualDensity.compact,
                  selected: _transmission?.toLowerCase() == t.toLowerCase(),
                  selectedColor: AppColors.green.withValues(alpha: 0.2),
                  onSelected: (_) => setState(() => _transmission = t),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _listingCard() {
    return DealerSectionCard(
      padding: const EdgeInsets.all(10),
      title: 'Listing — dealer fills',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _field('Kilometers', _kms, hint: 'e.g. 48000', number: true),
          const SizedBox(height: 6),
          if (!_isCustomerCar) ...[
            _field(
              'Retail Price',
              _retailPrice,
              hint: 'e.g. 495000 (leave empty for dealers only)',
              number: true,
            ),
            const SizedBox(height: 6),
            SwitchListTile(
              value: _exchangeEnabled,
              onChanged: (v) => setState(() => _exchangeEnabled = v),
              activeThumbColor: AppColors.green,
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: const Text(
                'Offer to Dealers',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              subtitle: const Text(
                'Lists this car on Dealer Exchange with its own price',
                style: TextStyle(fontSize: 11),
              ),
            ),
          ],
          if (_isCustomerCar || _exchangeEnabled) ...[
            _field(
              _isCustomerCar ? 'Expected Price' : 'Exchange Price',
              _exchangePrice,
              hint: 'e.g. 460000',
              number: true,
            ),
            const SizedBox(height: 6),
            const Text(
              'Visibility',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
            Wrap(
              spacing: 6,
              children: [
                for (final e in _visibilities.entries)
                  ChoiceChip(
                    label: Text(e.value, style: const TextStyle(fontSize: 11)),
                    visualDensity: VisualDensity.compact,
                    selected: _visibility == e.key,
                    selectedColor: AppColors.green.withValues(alpha: 0.2),
                    onSelected: (_) => setState(() => _visibility = e.key),
                  ),
              ],
            ),
            const SizedBox(height: 6),
          ],
          _field(
            'Description',
            _description,
            hint: 'Condition, ownership, service notes',
            maxLines: 2,
          ),
          // A dealer's own car is in the dealer's city, known since registration.
          if (_isCustomerCar) ...[
            const SizedBox(height: 6),
            _field('City', _city, hint: 'e.g. Kolkata'),
          ],
        ],
      ),
    );
  }

  /// The phone's GPS as the car's place: the dealer is with the car.
  Future<void> _useCurrentLocation() async {
    final position = await membership.phonePosition();
    if (position == null || !mounted) return;
    _carAddress.clear(); // first: clearing a picked address drops its position
    setState(() {
      _carLat = position.latitude;
      _carLng = position.longitude;
    });
  }

  Widget _carLocation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Where is the car? *',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        AddressSearchField(
          controller: _carAddress,
          decoration: InputDecoration(
            isDense: true,
            hintText: "Search the customer's address",
            hintStyle: const TextStyle(fontSize: 12),
            prefixIcon: const Icon(Icons.search, size: 18),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 8,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPicked:
              (place) => setState(() {
                _carLat = place.latitude;
                _carLng = place.longitude;
                if (place.city.isNotEmpty) _city.text = place.city;
              }),
          onCleared:
              () => setState(() {
                _carLat = null;
                _carLng = null;
              }),
        ),
        Obx(
          () =>
              membership.isLocating.value
                  ? const Padding(
                    padding: EdgeInsets.all(8),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                  : TextButton.icon(
                    onPressed: _useCurrentLocation,
                    icon: const Icon(Icons.my_location, size: 16),
                    label: const Text(
                      "Use my current location (I'm at the car)",
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
        ),
        Text(
          _carLat == null
              ? 'Other dealers see how far the car is from them, never where it is.'
              : _carAddress.text.trim().isEmpty
              ? "Your current location is saved as the car's place."
              : "Car's place saved. Other dealers see only the distance.",
          style: TextStyle(
            fontSize: 10,
            color: _carLat == null ? AppColors.grey : AppColors.green,
          ),
        ),
      ],
    );
  }

  Widget _customerCard() {
    return DealerSectionCard(
      padding: const EdgeInsets.all(10),
      title: 'Customer & Objective',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Customer details stay private to you - other dealers never see them.',
            style: TextStyle(fontSize: 10, color: AppColors.grey),
          ),
          const SizedBox(height: 6),
          _field(
            'Customer Name (optional)',
            _customerName,
            hint: 'e.g. Amit Roy',
          ),
          const SizedBox(height: 6),
          _field(
            'Customer Mobile (optional)',
            _customerPhone,
            hint: '10 digit number',
            number: true,
            maxLength: 10,
          ),
          const SizedBox(height: 8),
          _carLocation(),
        ],
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    required String hint,
    bool number = false,
    int maxLines = 1,
    int? maxLength,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: number ? TextInputType.number : TextInputType.text,
          inputFormatters: [
            if (number) FilteringTextInputFormatter.digitsOnly,
            if (maxLength != null) LengthLimitingTextInputFormatter(maxLength),
          ],
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            isDense: true,
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 12),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 8,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }
}
