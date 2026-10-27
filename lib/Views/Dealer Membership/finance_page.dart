import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:otobix/Controllers/Dealer%20Membership/dealer_finance_controller.dart';
import 'package:otobix/Utils/app_colors.dart';
import 'package:otobix/Utils/global_functions.dart';
import 'package:otobix/Widgets/Dealer%20Membership/dealer_common_widgets.dart';
import 'package:otobix/Widgets/Dealer%20Membership/dealer_option_picker.dart';
import 'package:otobix/Widgets/app_bar_widget.dart';
import 'package:otobix/Widgets/button_widget.dart';

class FinancePage extends StatefulWidget {
  const FinancePage({super.key});

  @override
  State<FinancePage> createState() => _FinancePageState();
}

class _FinancePageState extends State<FinancePage> {
  final DealerFinanceController controller = Get.put(DealerFinanceController());
  final _name = TextEditingController();
  final _mobile = TextEditingController();
  final _registration = TextEditingController();
  final _year = TextEditingController();

  @override
  void dispose() {
    for (final c in [_name, _mobile, _registration, _year]) {
      c.dispose();
    }
    Get.delete<DealerFinanceController>();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final sent = await controller.submit(
      customerName: _name.text,
      customerMobile: _mobile.text,
      registration: _registration.text,
      year: _year.text,
    );
    if (sent && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBarWidget(title: 'Car Finance'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Obx(_emiCard),
            const SizedBox(height: 14),
            Obx(_requestCard),
          ],
        ),
      ),
    );
  }

  Widget _emiCard() {
    final c = controller;
    return DealerSectionCard(
      title: 'EMI Estimate',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _slider(
            'Loan Amount',
            GlobalFunctions.formatLakh(c.loanAmount.value),
            c.loanAmount.value,
            DealerFinanceController.minLoan,
            DealerFinanceController.maxLoan,
            99,
            (v) => c.loanAmount.value = v,
          ),
          _slider(
            'Tenure',
            '${c.tenureMonths.value} months',
            c.tenureMonths.value.toDouble(),
            DealerFinanceController.minTenure.toDouble(),
            DealerFinanceController.maxTenure.toDouble(),
            7,
            (v) => c.tenureMonths.value = v.round(),
          ),
          _slider(
            'Interest Rate',
            '${c.interestRate.value.toStringAsFixed(1)}% p.a.',
            c.interestRate.value,
            DealerFinanceController.minRate,
            DealerFinanceController.maxRate,
            8,
            (v) => c.interestRate.value = v,
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              for (final (value, label, color) in [
                (
                  GlobalFunctions.formatRupees(c.monthlyEmi),
                  'Monthly EMI',
                  AppColors.green,
                ),
                (
                  GlobalFunctions.formatLakh(c.totalInterest),
                  'Total interest',
                  AppColors.deepOrange,
                ),
                (
                  GlobalFunctions.formatLakh(c.totalPayable),
                  'Total payable',
                  AppColors.blue,
                ),
              ])
                Expanded(
                  child: DealerStatTile(
                    value: value,
                    label: label,
                    color: color,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'An estimate only - the lender confirms the final rate and amount.',
            style: TextStyle(fontSize: 11, color: AppColors.grey),
          ),
        ],
      ),
    );
  }

  Widget _requestCard() {
    final c = controller;
    final rc = c.catalogue;
    return DealerSectionCard(
      title: 'Request Finance for a Customer',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            children: [
              for (final type in DealerFinanceController.carTypes)
                ChoiceChip(
                  label: Text(type, style: const TextStyle(fontSize: 12)),
                  selected: c.carType.value == type,
                  selectedColor: AppColors.green.withValues(alpha: 0.2),
                  onSelected: (_) => c.carType.value = type,
                ),
            ],
          ),
          const SizedBox(height: 12),
          _field(_name, 'Customer Name', caps: TextCapitalization.words),
          const SizedBox(height: 10),
          _field(
            _mobile,
            'Customer Mobile',
            keyboard: TextInputType.phone,
            formatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: DealerPickerField(
                  label: 'Make',
                  hintText: 'Select make',
                  value: c.make.value,
                  onTap:
                      () => showDealerOptionPicker(
                        context,
                        title: 'Select Make',
                        options: rc.makeOptions,
                        isLoading: rc.isMakeLoading,
                        onSearch: rc.onMakeSearchChanged,
                        onSelect: c.pickMake,
                      ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DealerPickerField(
                  label: 'Model',
                  hintText:
                      c.make.value.isEmpty
                          ? 'Select make first'
                          : 'Select model',
                  value: c.model.value,
                  enabled: c.make.value.isNotEmpty,
                  onTap:
                      () => showDealerOptionPicker(
                        context,
                        title: 'Select Model',
                        options: rc.modelOptions,
                        isLoading: rc.isModelLoading,
                        onSearch:
                            (q) => rc.onModelSearchChanged(c.make.value, q),
                        onSelect: c.pickModel,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          DealerPickerField(
            label: 'Variant (optional)',
            hintText:
                c.model.value.isEmpty ? 'Select model first' : 'Select variant',
            value: c.variant.value,
            enabled: c.model.value.isNotEmpty,
            onTap:
                () => showDealerOptionPicker(
                  context,
                  title: 'Select Variant',
                  options: c.variantOptions,
                  isLoading: c.isVariantLoading,
                  onSearch: c.onVariantSearchChanged,
                  onSelect: (v) => c.variant.value = v,
                ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              if (c.carType.value != 'New Car') ...[
                Expanded(
                  flex: 3,
                  child: _field(
                    _registration,
                    'Registration (optional)',
                    caps: TextCapitalization.characters,
                    formatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'[A-Za-z0-9 ]'),
                      ),
                      LengthLimitingTextInputFormatter(13),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                flex: 2,
                child: _field(
                  _year,
                  'Year (optional)',
                  keyboard: TextInputType.number,
                  formatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                ),
              ),
            ],
          ),
          if (c.error.value.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              c.error.value,
              style: const TextStyle(color: AppColors.red, fontSize: 12),
            ),
          ],
          const SizedBox(height: 12),
          ButtonWidget(
            text: 'Request Callback',
            isLoading: c.isSubmitting,
            width: double.infinity,
            onTap: _submit,
          ),
          const SizedBox(height: 6),
          const Text(
            'The OtoBix finance team calls your customer with lender offers. The estimate above goes with the request.',
            style: TextStyle(fontSize: 11, color: AppColors.grey),
          ),
        ],
      ),
    );
  }

  Widget _slider(
    String label,
    String value,
    double current,
    double min,
    double max,
    int divisions,
    ValueChanged<double> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.green,
              ),
            ),
          ],
        ),
        Slider(
          value: current.clamp(min, max),
          min: min,
          max: max,
          divisions: divisions,
          activeColor: AppColors.green,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    TextInputType? keyboard,
    TextCapitalization caps = TextCapitalization.none,
    List<TextInputFormatter>? formatters,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      textCapitalization: caps,
      inputFormatters: formatters,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        isDense: true,
        labelText: label,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
