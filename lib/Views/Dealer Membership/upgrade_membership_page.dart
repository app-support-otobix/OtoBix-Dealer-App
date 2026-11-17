import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:otobix/Controllers/Dealer%20Membership/dealer_membership_controller.dart';
import 'package:otobix/Models/Dealer%20Membership/dealer_membership_model.dart';
import 'package:otobix/Utils/app_colors.dart';
import 'package:otobix/Utils/global_functions.dart';
import 'package:otobix/Widgets/Dealer%20Membership/dealer_common_widgets.dart';
import 'package:otobix/Widgets/app_bar_widget.dart';
import 'package:otobix/Widgets/button_widget.dart';
import 'package:otobix/Widgets/toast_widget.dart';

/// Upgrade (or renew) the plan, or with [addPoints] buy more points for the
/// current cycle. Both pay the same way: UPI or an offline payment OtoBix
/// confirms.
class UpgradeMembershipPage extends StatefulWidget {
  const UpgradeMembershipPage({super.key, this.addPoints = false});

  final bool addPoints;

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

  Future<void> _submit(DealerPurchasable item) async {
    FocusScope.of(context).unfocus();
    if (_method == 'UPI') {
      controller.purchasePlan(item);
      return;
    }
    await controller.requestOfflinePayment(item, reference: _reference.text);
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
      appBar: AppBarWidget(
        title: widget.addPoints ? 'Add Points' : 'Upgrade Membership',
      ),
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

          final topUp = widget.addPoints ? config.topUp : null;
          if (widget.addPoints && (topUp == null || !(m?.isActive ?? false))) {
            return _noTopUpState();
          }
          final plans = config.plans;
          // A plan running now cannot be bought again until it ends.
          DateTime? activeTill(DealerPlanModel p) =>
              m?.plans
                  .firstWhereOrNull(
                    (r) => r.planCode == p.code && r.isRunningToday,
                  )
                  ?.endDate;
          final buyable = plans.where((p) => activeTill(p) == null).toList();
          final DealerPurchasable? plan =
              topUp ??
              buyable.firstWhereOrNull((p) => p.code == _planCode) ??
              buyable.firstOrNull;
          final method =
              _method ??
              config.paymentMethods.firstWhereOrNull((p) => p.enabled)?.code;
          if (plan == null) {
            if (plans.isEmpty) return const SizedBox();
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _sectionTitle('Your plans'),
                for (final p in plans) ...[
                  _planTile(p, selected: false, activeTill: activeTill(p)),
                  const SizedBox(height: 10),
                ],
                const Text(
                  'All your plans are running. You can buy one again once it ends.',
                  style: TextStyle(fontSize: 12, color: AppColors.grey),
                ),
              ],
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (m != null)
                Text(
                  'You are on ${m.plan?.name ?? 'membership'} · ${GlobalFunctions.formatNumber(m.availablePoints)} points left this cycle.',
                  style: const TextStyle(fontSize: 12, color: AppColors.grey),
                ),
              const SizedBox(height: 14),
              if (topUp != null) ...[
                _sectionTitle('Add points'),
                _topUpTile(topUp),
                const SizedBox(height: 10),
              ] else ...[
                _sectionTitle('Choose a plan'),
                for (final p in plans) ...[
                  _planTile(
                    p,
                    selected: p.code == plan.code,
                    activeTill: activeTill(p),
                  ),
                  const SizedBox(height: 10),
                ],
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
                Text(
                  topUp != null
                      ? 'Pay OtoBix by bank transfer, cheque or cash. The points are added when OtoBix confirms your payment.'
                      : 'Pay OtoBix by bank transfer, cheque or cash. The new plan starts when OtoBix confirms your payment; your current plan keeps working until then.',
                  style: const TextStyle(fontSize: 11, color: AppColors.grey),
                ),
              ],
              const SizedBox(height: 16),
              ButtonWidget(
                text:
                    method == 'UPI'
                        ? 'Pay ${GlobalFunctions.formatRupees(plan.priceRupees)}'
                        : '${topUp != null ? 'Request Points' : 'Request Upgrade'} · ${GlobalFunctions.formatRupees(plan.priceRupees)}',
                isLoading:
                    method == 'UPI'
                        ? controller.isPaying
                        : controller.isSubmitting,
                width: double.infinity,
                onTap: () => _submit(plan),
              ),
              if (plan.price.hasGst) ...[
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    plan.price.breakdownText,
                    style: const TextStyle(fontSize: 11, color: AppColors.grey),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                topUp != null
                    ? 'Added points never expire: what is left carries over to your next plan. They are used after your plan\'s own points.'
                    : 'A plan bought while your membership is active adds to it: its points, checks, Service History and connections add up, and each plan ends on its own date. What you use counts against the plan ending first. A plan you already have can be bought again once it ends.',
                style: const TextStyle(fontSize: 11, color: AppColors.grey),
              ),
            ],
          );
        }),
      ),
    );
  }

  // Points can be added only while the membership works.
  Widget _noTopUpState() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Points can be added while your membership is active. Renew your membership first.',
          style: TextStyle(fontSize: 13),
        ),
        const SizedBox(height: 16),
        ButtonWidget(
          text: 'Renew Membership',
          isLoading: false.obs,
          width: double.infinity,
          onTap: () => Get.off(() => const UpgradeMembershipPage()),
        ),
      ],
    );
  }

  Widget _topUpTile(DealerTopUpModel t) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.green.withValues(alpha: 0.06),
        border: Border.all(color: AppColors.green, width: 1.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${GlobalFunctions.formatNumber(t.points)} OTOBIX POINTS',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.blue,
                ),
              ),
              Text(
                t.price.listText,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          for (final line in t.benefits)
            Text('• $line', style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _pendingState(
    DealerMembershipConfigModel config,
    DealerPendingPaymentModel pending,
  ) {
    final plan =
        pending.name.isNotEmpty
            ? pending.name
            : config.plans
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
                      '$plan · ${GlobalFunctions.formatRupees(pending.amountRupees)}${pending.gstRupees > 0 ? ' incl. GST' : ''}',
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
              Text(
                pending.isTopUp
                    ? 'OtoBix will confirm your payment and add the points. You can request something else once this is confirmed.'
                    : 'OtoBix will confirm your payment and start the plan. Your current plan keeps working until then.',
                style: const TextStyle(fontSize: 12),
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

  // `activeTill`: the last day of this plan while the dealer has it running;
  // it shows a tick and cannot be chosen (the same plan cannot run twice).
  Widget _planTile(
    DealerPlanModel p, {
    required bool selected,
    DateTime? activeTill,
  }) {
    final active = activeTill != null;
    return InkWell(
      onTap: active ? null : () => setState(() => _planCode = p.code),
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
              active
                  ? Icons.check_circle
                  : selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
              color: active || selected ? AppColors.green : AppColors.grey,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (active)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        'Active till ${DateFormat('dd-MM-yyyy').format(activeTill)} · buy again once it ends',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.green,
                        ),
                      ),
                    ),
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
                        '${p.price.listText} / ${p.cycleDays} days',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  for (final line in [
                    if (p.pointsPerCycle > 0)
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
