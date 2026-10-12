import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:otobix/Controllers/Dealer%20Membership/dealer_membership_controller.dart';
import 'package:otobix/Controllers/Dealer%20Membership/dealer_profile_update_controller.dart';
import 'package:otobix/Utils/app_colors.dart';
import 'package:otobix/Utils/app_constants.dart';
import 'package:otobix/Widgets/Dealer%20Membership/dealer_common_widgets.dart';
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
  final _city = TextEditingController();
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
      _city.text = m.city;
      _gstin.text = m.gstin;
      _state = AppConstants.indianStates.contains(m.state) ? m.state : null;
      _radiusKm = m.tradeRadiusKm.clamp(10, 500).toDouble();
    }
  }

  @override
  void dispose() {
    _gstin.dispose();
    _city.dispose();
    super.dispose();
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
            : _city.text.trim().isEmpty
            ? 'Enter the city you trade from.'
            : _state == null
            ? 'Select your state.'
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
      city: _city.text.trim(),
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
              _labeledField('City', _city, hint: 'e.g. Kolkata'),
              const SizedBox(height: 10),
              const Text(
                'State',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _state,
                isExpanded: true,
                hint: const Text(
                  'Select state',
                  style: TextStyle(fontSize: 13),
                ),
                style: const TextStyle(fontSize: 13, color: AppColors.black),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                items: [
                  for (final s in AppConstants.indianStates)
                    DropdownMenuItem(value: s, child: Text(s)),
                ],
                onChanged:
                    (v) => setState(() {
                      _state = v;
                      _error = null;
                    }),
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
