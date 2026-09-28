import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:otobix/Controllers/Dealer%20Membership/dealer_membership_controller.dart';
import 'package:otobix/Models/Dealer%20Membership/dealer_membership_model.dart';
import 'package:otobix/Utils/app_colors.dart';
import 'package:otobix/Utils/global_functions.dart';
import 'package:otobix/Widgets/Dealer%20Membership/dealer_common_widgets.dart';
import 'package:otobix/Widgets/app_bar_widget.dart';
import 'package:otobix/Widgets/button_widget.dart';
import 'package:otobix/Widgets/toast_widget.dart';

/// Upgrade Membership: pick Pro or Pro+, then how to pay. Only offline
/// payment is open for now - UPI and NACH show as coming soon. A new plan
/// starts a fresh cycle; unused points from the current one do not carry over.
class UpgradeMembershipPage extends StatefulWidget {
  const UpgradeMembershipPage({super.key});

  @override
  State<UpgradeMembershipPage> createState() => _UpgradeMembershipPageState();
}

class _UpgradeMembershipPageState extends State<UpgradeMembershipPage> {
  final controller = DealerMembershipController.to;
  final _reference = TextEditingController();
  String? _planCode;
  String? _method;

  @override
  void initState() {
    super.initState();
    controller.ensureConfig();
  }

  @override
  void dispose() {
    _reference.dispose();
    super.dispose();
  }

  Future<void> _submit(DealerPlanModel plan) async {
    FocusScope.of(context).unfocus();
    if (_method == 'UPI') {
      controller.purchasePlan(plan);
      return;
    }
    await controller.requestOfflinePayment(plan, reference: _reference.text);
  }

  void _comingSoon(DealerPaymentMethodModel method) {
    ToastWidget.show(
      context: context,
      title: '${method.label} is coming soon',
      subtitle: 'Please use offline payment for now.',
      type: ToastType.warning,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBarWidget(title: 'Upgrade Membership'),
      body: SafeArea(
        child: Obx(() {
          final config = controller.config.value;
          final m = controller.membership.value;
          if (config == null) {
            return DealerStateView(
              isLoading: true,
              error: '',
              isEmpty: true,
              emptyMessage: '',
              child: const SizedBox(),
            );
          }
          final pending = m?.pendingPayment;
          if (pending != null) return _pendingState(config, pending);

          final plans = config.plans;
          final plan =
              plans.firstWhereOrNull((p) => p.code == _planCode) ??
              plans.firstOrNull;
          final method =
              _method ??
              config.paymentMethods.firstWhereOrNull((p) => p.enabled)?.code;
          if (plan == null) return const SizedBox();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (m != null)
                Text(
                  'You are on ${m.plan?.name ?? 'membership'} · ${m.availablePoints} points left this cycle.',
                  style: const TextStyle(fontSize: 12, color: AppColors.grey),
                ),
              const SizedBox(height: 14),
              _sectionTitle('Choose a plan'),
              for (final p in plans) ...[
                _planTile(p, selected: p.code == plan.code),
                const SizedBox(height: 10),
              ],
              const SizedBox(height: 8),
              _sectionTitle('Payment method'),
              for (final pm in config.paymentMethods) ...[
                _methodTile(pm, selected: pm.code == method),
                const SizedBox(height: 8),
              ],
              if (method == 'OFFLINE') ...[
                const SizedBox(height: 6),
                TextField(
                  controller: _reference,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    isDense: true,
                    labelText: 'Payment reference (optional)',
                    hintText: 'Cheque no., UTR or "Cash"',
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Pay OtoBix by bank transfer, cheque or cash. The new plan starts when OtoBix confirms your payment; your current plan keeps working until then.',
                  style: TextStyle(fontSize: 11, color: AppColors.grey),
                ),
              ],
              const SizedBox(height: 16),
              ButtonWidget(
                text:
                    method == 'UPI'
                        ? 'Pay ${GlobalFunctions.formatRupees(plan.priceRupees)}'
                        : 'Request Upgrade · ${GlobalFunctions.formatRupees(plan.priceRupees)}',
                isLoading:
                    method == 'UPI'
                        ? controller.isPaying
                        : controller.isSubmitting,
                width: double.infinity,
                onTap: () => _submit(plan),
              ),
              const SizedBox(height: 8),
              const Text(
                'A new plan starts a fresh 30-day cycle. Unused points from the current cycle do not carry over.',
                style: TextStyle(fontSize: 11, color: AppColors.grey),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _pendingState(
    DealerMembershipConfigModel config,
    DealerPendingPaymentModel pending,
  ) {
    final plan =
        config.plans
            .firstWhereOrNull((p) => p.code == pending.planCode)
            ?.name ??
        pending.planCode;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        DealerSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '$plan · ${GlobalFunctions.formatRupees(pending.amountRupees)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  const DealerStatusChip(
                    label: 'WAITING',
                    color: AppColors.blue,
                    small: true,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Offline payment ${pending.code} · requested ${GlobalFunctions.timeAgo(pending.requestedAt)}',
                style: const TextStyle(fontSize: 12, color: AppColors.grey),
              ),
              const SizedBox(height: 10),
              const Text(
                'OtoBix will confirm your payment and start the plan. Your current plan keeps working until then.',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
    ),
  );

  Widget _planTile(DealerPlanModel p, {required bool selected}) {
    return InkWell(
      onTap: () => setState(() => _planCode = p.code),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? AppColors.green.withValues(alpha: 0.06) : null,
          border: Border.all(
            color:
                selected
                    ? AppColors.green
                    : AppColors.grey.withValues(alpha: 0.3),
            width: selected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? AppColors.green : AppColors.grey,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        p.name.toUpperCase(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.blue,
                        ),
                      ),
                      Text(
                        '${GlobalFunctions.formatRupees(p.priceRupees)} / ${p.cycleDays} days',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  for (final line in [
                    '${GlobalFunctions.formatNumber(p.pointsPerCycle)} OtoBix Points each cycle',
                    ...p.benefits,
                  ])
                    Text('• $line', style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _methodTile(DealerPaymentMethodModel pm, {required bool selected}) {
    return InkWell(
      onTap:
          pm.enabled
              ? () => setState(() => _method = pm.code)
              : () => _comingSoon(pm),
      borderRadius: BorderRadius.circular(12),
      child: Opacity(
        opacity: pm.enabled ? 1 : 0.55,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(
              color:
                  selected
                      ? AppColors.green
                      : AppColors.grey.withValues(alpha: 0.3),
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? AppColors.green : AppColors.grey,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  pm.label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (!pm.enabled)
                const DealerStatusChip(
                  label: 'COMING SOON',
                  color: AppColors.grey,
                  small: true,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
