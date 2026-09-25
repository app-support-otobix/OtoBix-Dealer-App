import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:otobix/Controllers/Dealer%20Membership/dealer_membership_controller.dart';
import 'package:otobix/Models/Dealer%20Membership/dealer_membership_model.dart';
import 'package:otobix/Utils/app_colors.dart';
import 'package:otobix/Utils/global_functions.dart';
import 'package:otobix/Widgets/Dealer%20Membership/dealer_common_widgets.dart';
import 'package:otobix/Widgets/button_widget.dart';

/// Promo code entry plus the purchasable plans, from the server's catalogue.
/// Used by registration and by the Membership dashboard (renew / upgrade).
class DealerPlanPicker extends StatefulWidget {
  const DealerPlanPicker({super.key});

  @override
  State<DealerPlanPicker> createState() => _DealerPlanPickerState();
}

class _DealerPlanPickerState extends State<DealerPlanPicker> {
  final DealerMembershipController controller = DealerMembershipController.to;
  final _promoController = TextEditingController();

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final config = controller.config.value;
      final m = controller.membership.value;
      if (config == null) {
        return const Center(
          child: CircularProgressIndicator(color: AppColors.green),
        );
      }
      final promo = config.promo;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (m != null && m.promoAvailable && promo != null) ...[
            DealerSectionCard(
              title: 'Have a promo code?',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${promo.pointsPerCycle} OtoBix Points + one promotional membership cycle for new members.',
                    style: const TextStyle(fontSize: 12, color: AppColors.grey),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _promoController,
                          textCapitalization: TextCapitalization.characters,
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: 'e.g. OTOBIX10',
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
                      const SizedBox(width: 8),
                      ButtonWidget(
                        text: 'Apply',
                        isLoading: controller.isSubmitting,
                        width: 90,
                        height: 40,
                        onTap: () {
                          if (_promoController.text.trim().isEmpty) return;
                          FocusScope.of(context).unfocus();
                          controller.applyPromo(_promoController.text);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          for (final plan in config.plans) ...[
            _planCard(plan, m),
            const SizedBox(height: 10),
          ],
          const Text(
            'Unused allocation expires at cycle end · no cash top-up. '
            'Points cannot be bought, transferred or withdrawn.',
            style: TextStyle(color: AppColors.grey, fontSize: 11),
          ),
        ],
      );
    });
  }

  Widget _planCard(DealerPlanModel plan, DealerMembershipModel? m) {
    final isCurrent = m?.isActive == true && m?.plan?.code == plan.code;
    final action =
        isCurrent ? 'Renew' : (m?.isActive == true ? 'Switch' : 'Activate');
    return DealerSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                plan.name.toUpperCase(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppColors.blue,
                ),
              ),
              const SizedBox(width: 8),
              if (isCurrent)
                const DealerStatusChip(
                  label: 'CURRENT',
                  color: AppColors.green,
                  small: true,
                ),
              const Spacer(),
              Text(
                '${GlobalFunctions.formatRupees(plan.priceRupees)} / ${plan.cycleDays} days',
                style: const TextStyle(color: AppColors.grey, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '• ${plan.pointsPerCycle} OtoBix Points each cycle',
            style: const TextStyle(fontSize: 12),
          ),
          for (final b in plan.benefits)
            Text('• $b', style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ButtonWidget(
              text:
                  '$action · ${GlobalFunctions.formatRupees(plan.priceRupees)}',
              isLoading: controller.isPaying,
              width: double.infinity,
              height: 38,
              fontSize: 13,
              onTap: () => _confirmAndPay(plan, m),
            ),
          ),
        ],
      ),
    );
  }

  /// Buying while a cycle is running starts a fresh cycle now, so say so first.
  Future<void> _confirmAndPay(
    DealerPlanModel plan,
    DealerMembershipModel? m,
  ) async {
    if (m?.isActive == true) {
      final endsOn =
          GlobalFunctions.getFormattedDate(
            date: m!.cycleEndAt,
            type: GlobalFunctions.date,
          ) ??
          '';
      final ok = await Get.dialog<bool>(
        AlertDialog(
          title: const Text(
            'Start a new cycle now?',
            style: TextStyle(fontSize: 16),
          ),
          content: Text(
            'Your current cycle runs until $endsOn. Paying now starts a new ${plan.cycleDays}-day '
            '${plan.name} cycle immediately and your ${m.availablePoints} unused points expire.',
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
                'Continue',
                style: TextStyle(color: AppColors.green),
              ),
            ),
          ],
        ),
      );
      if (ok != true) return;
    }
    controller.purchasePlan(plan);
  }
}
