import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:otobix/Models/Dealer%20Membership/dealer_membership_model.dart';
import 'package:otobix/Utils/app_colors.dart';
import 'package:otobix/Utils/global_functions.dart';

/// Dealer type chips (New Car Dealer, Used Car Dealer, Broker) and, under
/// them, the chosen type's plans in short. Used on the registration form and
/// on the one-time choice for dealers enrolled before registration asked it.
class DealerTypePicker extends StatelessWidget {
  const DealerTypePicker({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
    this.errorText,
  });

  final List<DealerRegisterAsModel> options;

  /// The chosen dealer type (e.g. 'Used Car Dealer'), or null.
  final String? selected;
  final ValueChanged<String> onSelected;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final chosen = options.firstWhereOrNull((o) => o.dealerType == selected);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final o in options)
              ChoiceChip(
                label: Text(o.label, style: const TextStyle(fontSize: 12)),
                selected: o == chosen,
                selectedColor: AppColors.green.withValues(alpha: 0.2),
                onSelected: (_) => onSelected(o.dealerType),
              ),
          ],
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(left: 10, top: 4),
            child: Text(
              errorText!,
              style: const TextStyle(
                color: AppColors.validationErrorRed,
                fontSize: 12,
              ),
            ),
          ),
        if (chosen != null && chosen.plans.isNotEmpty) ...[
          const SizedBox(height: 12),
          DealerPlansSummaryCard(plans: chosen.plans),
        ],
      ],
    );
  }
}

/// A dealer type's plans in short: the free trial it starts on, then each
/// paid plan (Pro and Pro+, or Broker) with what it gives on one line.
class DealerPlansSummaryCard extends StatelessWidget {
  const DealerPlansSummaryCard({super.key, required this.plans});

  final List<DealerPlanModel> plans;

  @override
  Widget build(BuildContext context) {
    final trial = plans.firstWhereOrNull((p) => p.isTrial);
    final paid = plans.where((p) => !p.isTrial).toList();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.green.withValues(alpha: 0.06),
        border: Border.all(color: AppColors.green.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (trial != null && paid.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                'Starts with ${trial.name}, free for ${trial.cycleDays} days. Then:',
                style: const TextStyle(fontSize: 12, color: AppColors.black),
              ),
            ),
          for (final p in paid) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  p.name.toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: AppColors.blue,
                  ),
                ),
                Text(
                  '${GlobalFunctions.formatRupees(p.priceRupees)} / ${p.cycleDays} days',
                  style: const TextStyle(fontSize: 11, color: AppColors.grey),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              [
                ...p.benefits,
                if (p.listingCap > 0) '${p.listingCap} active listings',
              ].join(' · '),
              style: const TextStyle(fontSize: 12),
            ),
            if (p != paid.last) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}
