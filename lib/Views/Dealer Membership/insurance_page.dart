import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:otobix/Controllers/Dealer%20Membership/dealer_insurance_controller.dart';
import 'package:otobix/Models/Dealer%20Membership/dealer_insurance_model.dart';
import 'package:otobix/Utils/app_colors.dart';
import 'package:otobix/Utils/global_functions.dart';
import 'package:otobix/Widgets/Dealer%20Membership/dealer_common_widgets.dart';
import 'package:otobix/Widgets/Dealer%20Membership/dealer_option_picker.dart';
import 'package:otobix/Widgets/app_bar_widget.dart';
import 'package:otobix/Widgets/button_widget.dart';
import 'package:otobix/Widgets/toast_widget.dart';
import 'package:url_launcher/url_launcher.dart';

class InsurancePage extends StatefulWidget {
  const InsurancePage({super.key});

  @override
  State<InsurancePage> createState() => _InsurancePageState();
}

class _InsurancePageState extends State<InsurancePage> {
  final DealerInsuranceController controller = Get.put(
    DealerInsuranceController(),
  );
  final _regController = TextEditingController();

  @override
  void dispose() {
    _regController.dispose();
    Get.delete<DealerInsuranceController>();
    super.dispose();
  }

  void _getQuotes() {
    FocusScope.of(context).unfocus();
    controller.fetchQuotes(_regController.text);
  }

  Future<void> _buy(String link) async {
    final uri = Uri.tryParse(link);
    final opened =
        uri != null &&
        await launchUrl(
          uri,
          mode: LaunchMode.inAppBrowserView,
        ).catchError((_) => false);
    if (!opened && mounted) {
      ToastWidget.show(
        context: context,
        title: 'Could not open PolicyBazaar',
        subtitle: 'Please try again.',
        type: ToastType.error,
      );
    }
  }

  Future<void> _pickMonth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: controller.manufacturingMonth.value ?? now,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
      initialDatePickerMode: DatePickerMode.year,
      helpText: 'Month of manufacture',
    );
    if (picked != null) {
      controller.manufacturingMonth.value = DateTime(picked.year, picked.month);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBarWidget(title: 'Insurance'),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.green,
          onRefresh: controller.loadHistory,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Obx(_requestCard),
              Obx(() {
                final r = controller.result.value;
                if (r == null || r.quotes.isEmpty) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: _reportCard(r, highlight: true),
                );
              }),
              const SizedBox(height: 20),
              const Text(
                'Your Quotes',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 10),
              Obx(
                () => DealerStateView(
                  isLoading: controller.isLoadingHistory.value,
                  error: controller.historyError.value,
                  isEmpty: controller.history.isEmpty,
                  emptyIcon: Icons.shield_outlined,
                  emptyMessage: 'Quotes you fetch are kept here.',
                  onRetry: controller.loadHistory,
                  child: Column(
                    children: [
                      for (final r in controller.history)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _reportCard(r),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _requestCard() {
    final isNew = controller.isNewCar.value;
    return DealerSectionCard(
      title: 'Get Insurance Quotes',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _chips(
            {'Used Car': false, 'New Car': true},
            isNew,
            controller.setNewCar,
          ),
          const SizedBox(height: 12),
          if (isNew) ..._newCarFields() else ..._usedCarFields(),
          if (controller.error.value.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              controller.error.value,
              style: const TextStyle(color: AppColors.red, fontSize: 12),
            ),
          ],
          const SizedBox(height: 12),
          ButtonWidget(
            text: 'Get Quotes',
            isLoading: controller.isFetching,
            width: double.infinity,
            onTap: _getQuotes,
          ),
          const SizedBox(height: 6),
          const Text(
            'Quotes from PolicyBazaar insurers · free. Buying continues on PolicyBazaar.',
            style: TextStyle(fontSize: 11, color: AppColors.grey),
          ),
        ],
      ),
    );
  }

  List<Widget> _usedCarFields() => [
    TextField(
      controller: _regController,
      textCapitalization: TextCapitalization.characters,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9 ]')),
        LengthLimitingTextInputFormatter(13),
      ],
      onSubmitted: (_) => _getQuotes(),
      style: const TextStyle(fontWeight: FontWeight.w600, letterSpacing: 1),
      decoration: InputDecoration(
        isDense: true,
        labelText: 'Registration Number',
        hintText: 'e.g. WB02AB1234',
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    const SizedBox(height: 12),
    _label('Policy Type'),
    _chips(
      DealerInsuranceController.policyTypes,
      controller.policyType.value,
      (v) => controller.policyType.value = v,
    ),
  ];

  List<Widget> _newCarFields() {
    final c = controller;
    final month = c.manufacturingMonth.value;
    return [
      _picker(
        'RTO',
        'Select RTO',
        c.rto.value?.name,
        c.rtos,
        (v) => c.rto.value = c.rtos.byName(v),
      ),
      const SizedBox(height: 10),
      Row(
        children: [
          Expanded(
            child: _picker(
              'Make',
              'Select make',
              c.make.value?.name,
              c.makes,
              c.pickMake,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _picker(
              'Model',
              c.make.value == null ? 'Select make first' : 'Select model',
              c.model.value?.name,
              c.models,
              c.pickModel,
              enabled: c.make.value != null,
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),
      _picker(
        'Variant',
        c.model.value == null ? 'Select model first' : 'Select variant',
        c.variant.value?.name,
        c.variants,
        (v) => c.variant.value = c.variants.byName(v),
        enabled: c.model.value != null,
      ),
      const SizedBox(height: 10),
      DealerPickerField(
        label: 'Month of Manufacture',
        hintText: 'Select month',
        value: month == null ? null : DateFormat('MMM yyyy').format(month),
        onTap: _pickMonth,
      ),
      const SizedBox(height: 12),
      _label('Owned By'),
      _chips(
        DealerInsuranceController.ownerTypes,
        c.ownerType.value,
        (v) => c.ownerType.value = v,
      ),
    ];
  }

  Widget _picker(
    String label,
    String hint,
    String? value,
    DealerInsuranceOptionList list,
    void Function(String) onSelect, {
    bool enabled = true,
  }) {
    return DealerPickerField(
      label: label,
      hintText: hint,
      value: value,
      enabled: enabled,
      isLoading: list.isLoading.value,
      onTap:
          () => showDealerOptionPicker(
            context,
            title: 'Select $label',
            options: list.names,
            isLoading: list.isLoading,
            onSelect: onSelect,
          ),
    );
  }

  Widget _reportCard(
    DealerInsuranceQuoteReportModel r, {
    bool highlight = false,
  }) {
    final lowest = r.lowestPremium;
    return DealerSectionCard(
      color: highlight ? AppColors.green.withValues(alpha: 0.06) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  r.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              if (r.updatedAt != null)
                Text(
                  GlobalFunctions.timeAgo(r.updatedAt),
                  style: const TextStyle(fontSize: 11, color: AppColors.grey),
                ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            [
              r.subtitle,
              '${r.quotes.length} quotes',
              if (lowest != null)
                'from ${GlobalFunctions.formatRupees(lowest)}',
            ].join(' · '),
            style: const TextStyle(fontSize: 12, color: AppColors.grey),
          ),
          const SizedBox(height: 10),
          for (final q in r.quotes) _quoteRow(q),
          if (r.redirectLink.isNotEmpty) ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => _buy(r.redirectLink),
              icon: const Icon(Icons.open_in_new, size: 16),
              label: const Text('Buy on PolicyBazaar'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.green,
                side: const BorderSide(color: AppColors.green),
                minimumSize: const Size(double.infinity, 40),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _quoteRow(DealerInsuranceQuoteModel q) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              q.insurer.isEmpty ? 'Insurer' : q.insurer,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            GlobalFunctions.formatRupees(q.premium),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.green,
            ),
          ),
          SizedBox(
            width: 110,
            child: Text(
              'IDV ${GlobalFunctions.formatLakh(q.idv)}',
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 11, color: AppColors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
    ),
  );

  Widget _chips<T>(Map<String, T> options, T selected, void Function(T) onTap) {
    return Wrap(
      spacing: 8,
      children: [
        for (final e in options.entries)
          ChoiceChip(
            label: Text(e.key, style: const TextStyle(fontSize: 12)),
            selected: e.value == selected,
            selectedColor: AppColors.green.withValues(alpha: 0.2),
            onSelected: (_) => onTap(e.value),
          ),
      ],
    );
  }
}
