import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:otobix/Controllers/Dealer%20Membership/dealer_membership_controller.dart';
import 'package:otobix/Controllers/Dealer%20Membership/dealer_requirements_controller.dart';
import 'package:otobix/Models/Dealer%20Membership/dealer_exchange_model.dart';
import 'package:otobix/Utils/app_colors.dart';
import 'package:otobix/Widgets/Dealer%20Membership/dealer_common_widgets.dart';
import 'package:otobix/Widgets/Dealer%20Membership/dealer_option_picker.dart';
import 'package:otobix/Widgets/app_bar_widget.dart';
import 'package:otobix/Widgets/button_widget.dart';

class RequirementFormPage extends StatefulWidget {
  final DealerRequirementModel? existing;
  const RequirementFormPage({super.key, this.existing});

  @override
  State<RequirementFormPage> createState() => _RequirementFormPageState();
}

class _RequirementFormPageState extends State<RequirementFormPage> {
  static const double _minYear = 2000;
  static const double _maxKms = 200000;
  static const double _maxPriceLakh = 50;
  static const int _maxMakes = 10;

  final rc = DealerRequirementsController.to;
  final membership = DealerMembershipController.to;
  final double _maxYear = DateTime.now().year.toDouble();

  late final _name = TextEditingController(text: widget.existing?.name);
  late final _city = TextEditingController(
    text: widget.existing?.city ?? membership.membership.value?.city ?? '',
  );
  final List<String> _makes = []; // empty = any make
  String? _model; // only with exactly one make
  late RangeValues _years;
  late RangeValues _kms;
  late RangeValues _priceLakh;
  late Set<String> _fuelTypes;
  late Set<String> _transmissions;

  @override
  void initState() {
    super.initState();
    final r = widget.existing;
    _makes.addAll(r?.makes ?? const []);
    _model = (r?.model ?? '').isEmpty ? null : r!.model;
    _years = RangeValues(
      (r?.yearFrom ?? 0) > 0 ? r!.yearFrom.toDouble() : _minYear,
      (r?.yearTo ?? 0) > 0 ? r!.yearTo.toDouble() : _maxYear,
    );
    _kms = RangeValues(
      (r?.kmMin ?? 0).toDouble(),
      (r?.kmMax ?? 0) > 0 ? r!.kmMax.toDouble().clamp(0, _maxKms) : _maxKms,
    );
    _priceLakh = RangeValues(
      ((r?.priceMin ?? 0) / 100000).clamp(0, _maxPriceLakh).toDouble(),
      (r?.priceMax ?? 0) > 0
          ? (r!.priceMax / 100000).clamp(0, _maxPriceLakh).toDouble()
          : 20,
    );
    _fuelTypes = {...?r?.fuelTypes};
    _transmissions = {...?r?.transmissions};
    membership.ensureConfig();
    rc.fetchMakes('');
    if (_singleMake != null) rc.fetchModels(make: _singleMake!, query: '');
  }

  String? get _singleMake => _makes.length == 1 ? _makes.first : null;

  // A model belongs to one make, so it is cleared whenever the makes change.
  void _setMakes(void Function() change) {
    setState(() {
      change();
      _model = null;
    });
    rc.modelOptions.clear();
    if (_singleMake != null) rc.fetchModels(make: _singleMake!, query: '');
  }

  @override
  void dispose() {
    _name.dispose();
    _city.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final body = {
      'name': _name.text.trim(),
      'makes': _makes,
      'make': _singleMake ?? '', // for a server from before multiple makes
      'model': _singleMake == null ? '' : _model ?? '',
      'yearFrom': _years.start > _minYear ? _years.start.round() : 0,
      'yearTo': _years.end < _maxYear ? _years.end.round() : 0,
      'kmMin': _kms.start.round(),
      'kmMax': _kms.end < _maxKms ? _kms.end.round() : 0,
      'fuelTypes': _fuelTypes.toList(),
      'transmissions': _transmissions.toList(),
      'priceMin': (_priceLakh.start * 100000).round(),
      'priceMax':
          _priceLakh.end < _maxPriceLakh
              ? (_priceLakh.end * 100000).round()
              : 0,
      'city': _city.text.trim(),
    };
    if (await rc.save(body, id: widget.existing?.id) && mounted) Get.back();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;
    final config = membership.config.value;
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBarWidget(title: isEditing ? 'Edit Filter' : 'Add Car Filter'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DealerSectionCard(
              title: 'Filter Name',
              child: TextField(
                controller: _name,
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'e.g. Budget SUVs',
                  hintStyle: TextStyle(
                    color: AppColors.grey.withValues(alpha: 0.6),
                    fontSize: 13,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: AppColors.green,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            DealerSectionCard(
              title: 'Make & Model',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Obx(
                          () => DealerPickerField(
                            label: 'Make',
                            hintText:
                                _makes.isEmpty
                                    ? 'Any Make'
                                    : _makes.length < _maxMakes
                                    ? 'Add another make'
                                    : 'Up to $_maxMakes makes',
                            value: null,
                            enabled: _makes.length < _maxMakes,
                            isLoading: rc.isMakeLoading.value,
                            onTap:
                                () => showDealerOptionPicker(
                                  context,
                                  title: 'Select Make',
                                  options: rc.makeOptions,
                                  isLoading: rc.isMakeLoading,
                                  onSearch: rc.onMakeSearchChanged,
                                  onSelect: (v) {
                                    if (!_makes.contains(v)) {
                                      _setMakes(() => _makes.add(v));
                                    }
                                  },
                                ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Obx(
                          () => DealerPickerField(
                            label: 'Model',
                            hintText:
                                _makes.isEmpty
                                    ? 'Select make first'
                                    : _singleMake == null
                                    ? 'Any model'
                                    : 'Any Model',
                            value: _model,
                            enabled: _singleMake != null,
                            isLoading: rc.isModelLoading.value,
                            onTap:
                                () => showDealerOptionPicker(
                                  context,
                                  title: 'Select Model',
                                  options: rc.modelOptions,
                                  isLoading: rc.isModelLoading,
                                  onSearch:
                                      (q) => rc.onModelSearchChanged(
                                        _singleMake ?? '',
                                        q,
                                      ),
                                  onSelect: (v) => setState(() => _model = v),
                                ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_makes.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final m in _makes)
                          InputChip(
                            label: Text(m, style: const TextStyle(fontSize: 12)),
                            selected: true,
                            showCheckmark: false,
                            selectedColor: AppColors.green.withValues(
                              alpha: 0.18,
                            ),
                            deleteIconColor: AppColors.green,
                            visualDensity: VisualDensity.compact,
                            onDeleted: () => _setMakes(() => _makes.remove(m)),
                          ),
                      ],
                    ),
                  ],
                  if (_makes.length > 1) ...[
                    const SizedBox(height: 6),
                    const Text(
                      'A model can be picked when only one make is selected.',
                      style: TextStyle(fontSize: 11, color: AppColors.grey),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            _rangeCard(
              'Year of Manufacture',
              _years,
              _minYear,
              _maxYear,
              (_maxYear - _minYear).round(),
              '${_years.start.round()} – ${_years.end.round()}',
              (v) => setState(
                () =>
                    _years = RangeValues(
                      v.start.roundToDouble(),
                      v.end.roundToDouble(),
                    ),
              ),
            ),
            const SizedBox(height: 12),
            _rangeCard(
              'Kilometers Driven',
              _kms,
              0,
              _maxKms,
              40,
              '${(_kms.start / 1000).round()}k – ${(_kms.end / 1000).round()}k${_kms.end >= _maxKms ? '+' : ''} km',
              (v) => setState(() => _kms = v),
            ),
            const SizedBox(height: 12),
            _multiSelectCard(
              'Fuel Type',
              config?.fuelTypes ?? const [],
              _fuelTypes,
            ),
            const SizedBox(height: 12),
            _rangeCard(
              'Price Range (₹ Lakh)',
              _priceLakh,
              0,
              _maxPriceLakh,
              _maxPriceLakh.round(),
              '₹${_priceLakh.start.round()}L – ₹${_priceLakh.end.round()}L${_priceLakh.end >= _maxPriceLakh ? '+' : ''}',
              (v) => setState(
                () =>
                    _priceLakh = RangeValues(
                      v.start.roundToDouble(),
                      v.end.roundToDouble(),
                    ),
              ),
            ),
            const SizedBox(height: 12),
            _multiSelectCard(
              'Transmission',
              config?.transmissions ?? const [],
              _transmissions,
            ),
            const SizedBox(height: 12),
            DealerSectionCard(
              title: 'Location (City)',
              child: TextField(
                controller: _city,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'Leave empty for all cities',
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ButtonWidget(
              text: isEditing ? 'Save Changes' : 'Save Filter',
              isLoading: rc.isSaving,
              width: double.infinity,
              onTap: _save,
            ),
          ],
        ),
      ),
    );
  }

  Widget _rangeCard(
    String title,
    RangeValues values,
    double min,
    double max,
    int divisions,
    String label,
    ValueChanged<RangeValues> onChanged,
  ) {
    return DealerSectionCard(
      title: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RangeSlider(
            values: values,
            min: min,
            max: max,
            divisions: divisions,
            activeColor: AppColors.green,
            inactiveColor: AppColors.grey.withValues(alpha: 0.3),
            onChanged: onChanged,
          ),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _multiSelectCard(
    String title,
    List<String> options,
    Set<String> selected,
  ) {
    return DealerSectionCard(
      title: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final o in options)
                FilterChip(
                  label: Text(o, style: const TextStyle(fontSize: 12)),
                  selected: selected.contains(o),
                  selectedColor: AppColors.green.withValues(alpha: 0.18),
                  checkmarkColor: AppColors.green,
                  visualDensity: VisualDensity.compact,
                  onSelected:
                      (on) => setState(
                        () => on ? selected.add(o) : selected.remove(o),
                      ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            selected.isEmpty
                ? 'Any ${title.toLowerCase()}'
                : selected.join(', '),
            style: const TextStyle(fontSize: 12, color: AppColors.grey),
          ),
        ],
      ),
    );
  }
}
