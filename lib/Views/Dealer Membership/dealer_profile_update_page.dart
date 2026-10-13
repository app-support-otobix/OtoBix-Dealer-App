import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:otobix/Controllers/Dealer%20Membership/dealer_membership_controller.dart';
import 'package:otobix/Controllers/Dealer%20Membership/dealer_profile_update_controller.dart';
import 'package:otobix/Utils/app_colors.dart';
import 'package:otobix/Utils/app_constants.dart';
import 'package:otobix/Utils/indian_cities.dart';
import 'package:otobix/Widgets/Dealer%20Membership/dealer_common_widgets.dart';
import 'package:otobix/Widgets/Dealer%20Membership/dealer_option_picker.dart';
import 'package:otobix/Widgets/Dealer%20Membership/showroom_location_widgets.dart';
import 'package:otobix/Widgets/app_bar_widget.dart';
import 'package:otobix/Widgets/button_widget.dart';

class DealerProfileUpdatePage extends StatefulWidget {
  const DealerProfileUpdatePage({super.key});

  @override
  State<DealerProfileUpdatePage> createState() =>
      _DealerProfileUpdatePageState();
}

class _DealerProfileUpdatePageState extends State<DealerProfileUpdatePage> {
  final DealerMembershipController controller = DealerMembershipController.to;
  final DealerProfileUpdateController profile =
      DealerProfileUpdateController.to;
  final _gstin = TextEditingController();
  String? _city;
  String? _state;
  String? _dealerType;
  double _radiusKm = 100;
  String? _error;

  @override
  void initState() {
    super.initState();
    controller.ensureConfig();
    final m = controller.membership.value;
    if (m != null) {
      _dealerType = m.dealerType.isEmpty ? null : m.dealerType;
      _gstin.text = m.gstin;
      // Older records were given the registration state as their city
      // ("West Bengal"); that belongs in State. Delhi, Chandigarh and
      // Puducherry are cities too, so those stay.
      final city = m.city.trim();
      final cityAsState = _matchState(city);
      final misplaced =
          cityAsState != null &&
          !IndianCities.of(cityAsState).contains(cityAsState);
      _city = city.isEmpty || misplaced ? null : city;
      _state =
          _matchState(m.state) ??
          cityAsState ??
          (_city == null ? null : IndianCities.stateOf(_city!));
      _radiusKm = m.tradeRadiusKm.clamp(10, 500).toDouble();
    }
  }

  @override
  void dispose() {
    _gstin.dispose();
    super.dispose();
  }

  String? _matchState(String value) {
    final v = value.trim().toLowerCase();
    if (v.isEmpty) return null;
    return AppConstants.indianStates.firstWhereOrNull(
      (s) => s.toLowerCase() == v,
    );
  }

  void _pickState() {
    showDealerOptionPicker(
      context,
      title: 'Select state',
      options: <String>[...AppConstants.indianStates].obs,
      onSelect:
          (state) => setState(() {
            // A city of the old state is not one of the new state's.
            if (state != _state &&
                !IndianCities.of(state).contains(_city ?? '')) {
              _city = null;
            }
            _state = state;
            _error = null;
          }),
    );
  }

  void _pickCity() {
    showDealerOptionPicker(
      context,
      title: 'Select city in $_state',
      options: <String>[...IndianCities.of(_state)].obs,
      allowTyped: true,
      onSelect:
          (city) => setState(() {
            _city = city;
            _error = null;
          }),
    );
  }

  Future<void> _save() async {
    final gstin = _gstin.text.trim().toUpperCase();
    // A type the server no longer offers (e.g. an older "Broker" pick) has to
    // be chosen again.
    final types = controller.config.value?.dealerTypes ?? const <String>[];
    final error =
        _dealerType == null ||
                (types.isNotEmpty && !types.contains(_dealerType))
            ? 'Select your dealer type.'
            : _state == null
            ? 'Select your state.'
            : _city == null
            ? 'Select the city you trade from.'
            : gstin.isNotEmpty &&
                !RegExp(
                  r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z][1-9A-Z]Z[0-9A-Z]$',
                ).hasMatch(gstin)
            ? 'Enter a valid 15 character GSTIN, or leave it empty.'
            : null;
    setState(() => _error = error);
    if (error != null) return;
    final saved = await profile.updateProfile(
      dealerType: _dealerType!,
      city: _city!,
      state: _state!,
      gstin: gstin,
      tradeRadiusKm: _radiusKm.round(),
    );
    if (saved && mounted) Get.back();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBarWidget(title: 'Dealer Profile'),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SingleChildScrollView(child: _buildDetailsStep()),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: AppColors.red, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 12),
              ButtonWidget(
                text: 'Save Details',
                isLoading: profile.isSubmitting,
                width: double.infinity,
                onTap: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DealerSectionCard(
          title: 'Business Details',
          child: _labeledField(
            'GSTIN (optional)',
            _gstin,
            hint: 'e.g. 19AABCS1429P1ZT',
            caps: true,
          ),
        ),
        const SizedBox(height: 12),
        DealerSectionCard(
          title: 'Dealer Type',
          child: Obx(
            () => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final type
                    in controller.config.value?.dealerTypes ?? const <String>[])
                  ChoiceChip(
                    label: Text(type, style: const TextStyle(fontSize: 12)),
                    selected: type == _dealerType,
                    selectedColor: AppColors.green.withValues(alpha: 0.2),
                    onSelected:
                        (_) => setState(() {
                          _dealerType = type;
                          _error = null;
                        }),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        DealerSectionCard(
          title: 'Location & Trade Area',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DealerPickerField(
                label: 'State',
                hintText: 'Select state',
                value: _state,
                onTap: _pickState,
              ),
              const SizedBox(height: 10),
              DealerPickerField(
                label: 'City',
                hintText:
                    _state == null ? 'Select a state first' : 'Select city',
                value: _city,
                enabled: _state != null,
                onTap: _pickCity,
              ),
              const SizedBox(height: 10),
              const Text(
                'Showroom location',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const ShowroomLocationCard(),
              const SizedBox(height: 10),
              Text(
                'Trade distance · ${_radiusKm.round()} km',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Slider(
                value: _radiusKm,
                min: 10,
                max: 500,
                divisions: 49,
                activeColor: AppColors.green,
                label: '${_radiusKm.round()} km',
                onChanged: (v) => setState(() => _radiusKm = v),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _labeledField(
    String label,
    TextEditingController controller, {
    required String hint,
    bool caps = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppColors.black,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          textCapitalization:
              caps ? TextCapitalization.characters : TextCapitalization.words,
          decoration: InputDecoration(
            isDense: true,
            hintText: hint,
            hintStyle: TextStyle(
              color: AppColors.grey.withValues(alpha: 0.6),
              fontSize: 13,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.black),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.green, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
