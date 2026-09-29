import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:otobix/Controllers/Dealer%20Membership/dealer_exchange_controller.dart';
import 'package:otobix/Utils/app_colors.dart';
import 'package:otobix/Widgets/Dealer%20Membership/dealer_common_widgets.dart';
import 'package:otobix/Widgets/Dealer%20Membership/dealer_option_picker.dart';
import 'package:otobix/Widgets/button_widget.dart';

class ExchangeFiltersPanel extends StatefulWidget {
  const ExchangeFiltersPanel({super.key});

  @override
  State<ExchangeFiltersPanel> createState() => _ExchangeFiltersPanelState();
}

class _ExchangeFiltersPanelState extends State<ExchangeFiltersPanel> {
  final fc = DealerExchangeController.to;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.grey.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: DealerSectionCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        color: AppColors.white,
        elevation: 0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Row(
                children: [
                  Expanded(
                    child: Obx(
                      () => Text(
                        fc.appliedFilterCount.value == 0
                            ? 'Filter Inventory'
                            : 'Filter Inventory · ${fc.appliedFilterCount.value} applied',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.black,
                        ),
                      ),
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.tune,
                    color: AppColors.green,
                    size: 20,
                  ),
                ],
              ),
            ),
            if (_expanded) ..._filters(context),
          ],
        ),
      ),
    );
  }

  List<Widget> _filters(BuildContext context) {
    return [
      const SizedBox(height: 10),
      Row(
        children: [
          Expanded(
            child: Obx(
              () => DealerPickerField(
                label: 'Make',
                hintText: 'Any Make',
                value: fc.selectedMake.value,
                onTap:
                    () => showDealerOptionPicker(
                      context,
                      title: 'Select Make',
                      options: fc.makeOptions,
                      onSelect: fc.pickMake,
                    ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Obx(
              () => DealerPickerField(
                label: 'Model',
                hintText:
                    (fc.selectedMake.value ?? '').isEmpty
                        ? 'Select make first'
                        : 'Any Model',
                value: fc.selectedModel.value,
                enabled: (fc.selectedMake.value ?? '').isNotEmpty,
                onTap:
                    () => showDealerOptionPicker(
                      context,
                      title: 'Select Model',
                      options: fc.modelOptions,
                      onSelect: (v) => fc.selectedModel.value = v,
                    ),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      const Text(
        'Fuel Type',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
      ),
      const SizedBox(height: 4),
      Obx(() => _chips(fc.fuelOptions, fc.selectedFuelTypes)),
      const SizedBox(height: 8),
      const Text(
        'Transmission',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
      ),
      const SizedBox(height: 4),
      Obx(() => _chips(fc.transmissionOptions, fc.selectedTransmissions)),
      Obx(() {
        final rv = fc.yearRange.value;
        return _range(
          label: 'Year of Manufacture',
          valueLabel: '${rv.start.round()} – ${rv.end.round()}',
          values: rv,
          min: DealerExchangeController.minYear,
          max: fc.maxYear,
          divisions: (fc.maxYear - DealerExchangeController.minYear).round(),
          onChanged:
              (v) =>
                  fc.yearRange.value = RangeValues(
                    v.start.roundToDouble(),
                    v.end.roundToDouble(),
                  ),
        );
      }),
      Obx(() {
        final rv = fc.kmRange.value;
        final max = DealerExchangeController.maxKms;
        return _range(
          label: 'Mileage (KM Driven)',
          valueLabel:
              '${(rv.start / 1000).round()}k – ${(rv.end / 1000).round()}k${rv.end >= max ? '+' : ''} km',
          values: rv,
          min: 0,
          max: max,
          divisions: 40,
          onChanged: (v) => fc.kmRange.value = v,
        );
      }),
      Obx(() {
        final rv = fc.priceRangeLakh.value;
        final max = DealerExchangeController.maxPriceLakh;
        return _range(
          label: 'Price Range (₹ Lakh)',
          valueLabel:
              '₹${rv.start.round()}L – ₹${rv.end.round()}L${rv.end >= max ? '+' : ''}',
          values: rv,
          min: 0,
          max: max,
          divisions: max.round(),
          onChanged:
              (v) =>
                  fc.priceRangeLakh.value = RangeValues(
                    v.start.roundToDouble(),
                    v.end.roundToDouble(),
                  ),
        );
      }),
      const SizedBox(height: 8),
      Row(
        children: [
          Expanded(
            child: ButtonWidget(
              text: 'Reset',
              backgroundColor: AppColors.red,
              height: 32,
              isLoading: false.obs,
              onTap: fc.resetFilters,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ButtonWidget(
              text: 'Apply',
              height: 32,
              isLoading: false.obs,
              onTap: () {
                setState(() => _expanded = false);
                fc.applyFilters();
              },
            ),
          ),
        ],
      ),
    ];
  }

  Widget _chips(List<String> options, RxSet<String> selected) {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        for (final o in options)
          FilterChip(
            label: Text(
              o,
              style: TextStyle(
                fontSize: 12,
                color: selected.contains(o) ? AppColors.green : AppColors.black,
              ),
            ),
            selected: selected.contains(o),
            selectedColor: AppColors.green.withValues(alpha: .1),
            checkmarkColor: AppColors.green,
            labelPadding: const EdgeInsets.symmetric(horizontal: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            onSelected: (on) => on ? selected.add(o) : selected.remove(o),
          ),
      ],
    );
  }

  Widget _range({
    required String label,
    required String valueLabel,
    required RangeValues values,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<RangeValues> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
              Text(
                valueLabel,
                style: const TextStyle(fontSize: 11, color: AppColors.grey),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 2,
              rangeThumbShape: const RoundRangeSliderThumbShape(
                enabledThumbRadius: 6,
              ),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
            ),
            child: RangeSlider(
              values: values,
              min: min,
              max: max,
              divisions: divisions,
              activeColor: AppColors.green,
              inactiveColor: AppColors.grey.withValues(alpha: 0.3),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
