import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import 'package:otobix/Controllers/Dealer%20Membership/dealer_membership_controller.dart';
import 'package:otobix/Models/Dealer%20Membership/dealer_membership_model.dart';
import 'package:otobix/Utils/app_colors.dart';
import 'package:otobix/Utils/global_functions.dart';
import 'package:otobix/Views/Dealer%20Membership/dealer_membership_navigator.dart';
import 'package:otobix/Widgets/Dealer%20Membership/dealer_common_widgets.dart';
import 'package:otobix/Widgets/Dealer%20Membership/dealer_renewal_banner.dart';
import 'package:otobix/Widgets/app_bar_widget.dart';

class MembershipDashboardPage extends StatefulWidget {
  const MembershipDashboardPage({super.key});

  @override
  State<MembershipDashboardPage> createState() =>
      _MembershipDashboardPageState();
}

class _MembershipDashboardPageState extends State<MembershipDashboardPage> {
  final DealerMembershipController controller = DealerMembershipController.to;

  static const _filters = ['ALL', 'RESERVED', 'CONSUMED', 'EXPIRED'];

  @override
  void initState() {
    super.initState();
    controller.ensureConfig();
    controller.refreshMembership();
    controller.loadLedger(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBarWidget(
        title: 'Membership & Point Ledger',
        actions: [
          IconButton(
            tooltip: 'Activity Log',
            icon: const Icon(Icons.history, color: AppColors.green),
            onPressed: DealerMembershipNavigator.openActivityLog,
          ),
        ],
      ),
      body: SafeArea(
        child: NotificationListener<ScrollNotification>(
          onNotification: (n) {
            if (n.metrics.pixels > n.metrics.maxScrollExtent - 200) {
              controller.loadLedger();
            }
            return false;
          },
          child: RefreshIndicator(
            color: AppColors.green,
            onRefresh: () async {
              await controller.refreshMembership();
              await controller.loadLedger(reset: true);
            },
            child: Obx(() {
              final m = controller.membership.value;
              if (m == null) {
                return DealerStateView(
                  isLoading: true,
                  error: '',
                  isEmpty: true,
                  emptyMessage: '',
                  child: const SizedBox(),
                );
              }
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _planCard(m),
                  const SizedBox(height: 12),
                  const DealerRenewalBanner(),
                  _usageCard(m),
                  const SizedBox(height: 20),
                  const Text(
                    'Point Ledger',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 8),
                  _filterChips(),
                  const SizedBox(height: 10),
                  ..._ledger(),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _planCard(DealerMembershipModel m) {
    final plan = m.plan;
    final summary = m.summary;
    final date = DateFormat('dd-MM-yyyy');
    final statusLine =
        m.isGrace
            ? 'Grace period · ends ${m.graceEndAt == null ? '' : date.format(m.graceEndAt!.toLocal())}'
            : m.isActive
            ? 'Day ${m.dayOfCycle} of ${plan?.cycleDays ?? 30} · renews by ${m.cycleEndAt == null ? '' : date.format(m.cycleEndAt!.toLocal())}'
            : m.trialScheduled
            ? 'Free trial ${date.format(m.trialStartDate!)} to ${m.trialEndDate == null ? '' : date.format(m.trialEndDate!)}'
            : m.trialQueued
            ? 'Free trial queued · OtoBix will set its dates'
            : 'Ended · upgrade to continue';
    final dealerName = controller.dealerName.value;
    return DealerSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (plan?.name ??
                              (m.trialQueued
                                  ? 'Promo Membership'
                                  : 'Dealer Membership'))
                          .toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.blue,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      [
                        if (dealerName.isNotEmpty) dealerName,
                        m.dealerCode,
                      ].join(' · '),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.black,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (m.cycleStartAt != null)
                          '${DateFormat('MMMM').format(m.cycleStartAt!.toLocal())} cycle',
                        if (m.city.isNotEmpty) m.city,
                      ].join(' · '),
                      style: const TextStyle(
                        color: AppColors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  DealerStatusChip(
                    label:
                        m.isGrace
                            ? 'GRACE PERIOD'
                            : m.isActive
                            ? 'ACTIVE'
                            : m.trialQueued
                            ? 'QUEUED'
                            : 'ENDED',
                    color:
                        m.isGrace
                            ? AppColors.deepOrange
                            : m.isActive
                            ? AppColors.green
                            : m.trialQueued
                            ? AppColors.blue
                            : AppColors.red,
                    small: true,
                  ),
                  const SizedBox(height: 10),
                  FilledButton(
                    onPressed: DealerMembershipNavigator.openUpgrade,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.green,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Upgrade Now',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: DealerStatTile(
                  value: GlobalFunctions.formatNumber(m.availablePoints),
                  label: 'Available points',
                ),
              ),
              Expanded(
                child: DealerStatTile(
                  value: '${summary?.reserved ?? 0}',
                  label:
                      'Reserved · ${summary?.pendingReservations ?? 0} pending',
                  color: AppColors.deepOrange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            statusLine,
            style: const TextStyle(color: AppColors.grey, fontSize: 11),
          ),
          // Bought plans waiting their turn, each after the one before it.
          for (final q in m.queuedPlans)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Next: ${q.name} · from ${q.startDate == null ? '' : date.format(q.startDate!)}',
                style: const TextStyle(
                  color: AppColors.green,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          if (summary != null && m.isActive) ...[
            const SizedBox(height: 10),
            Text(
              [
                'This cycle: ${GlobalFunctions.formatNumber(summary.allocated)} allocated',
                if (summary.toppedUp > 0)
                  '${GlobalFunctions.formatNumber(summary.toppedUp)} added',
                '${summary.consumed} consumed',
                '${summary.released} released',
              ].join(' · '),
              style: const TextStyle(fontSize: 11, color: AppColors.grey),
            ),
          ],
          // Ran out mid-cycle: buy more points for this cycle.
          if (m.isActive && controller.config.value?.topUp != null) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: DealerMembershipNavigator.openAddPoints,
                icon: const Icon(Icons.add_circle_outline, size: 18),
                label: Text(
                  'Add ${GlobalFunctions.formatNumber(controller.config.value!.topUp!.points)} points · ${GlobalFunctions.formatRupees(controller.config.value!.topUp!.priceRupees)}',
                  style: const TextStyle(fontSize: 12),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.green,
                  side: const BorderSide(color: AppColors.green),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
          // Not for a dealer waiting to be moved to the Broker plan: Dealer
          // Details offers the dealer types only.
          if (m.dealerType.isEmpty && m.brokerRequestedAt == null) ...[
            const SizedBox(height: 4),
            TextButton(
              onPressed: DealerMembershipNavigator.openDealerProfileUpdate,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 30),
                foregroundColor: AppColors.green,
              ),
              child: const Text(
                'Add your dealer type and trade area',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _usageCard(DealerMembershipModel m) {
    return DealerSectionCard(
      title: 'Current Month Usage',
      child: Column(
        children: [
          for (final u in m.usage) ...[
            _usageRow(u),
            if (u != m.usage.last) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  Widget _usageRow(DealerUsageModel u) {
    final used =
        u.isRupees
            ? '${GlobalFunctions.formatRupees(u.used)} of ${GlobalFunctions.formatRupees(u.limit)}'
            : '${u.used} of ${u.limit} ${u.unit}';
    final full = u.leftPoints == 0 && u.limitPoints > 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              u.label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            Text(
              used,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: full ? AppColors.red : AppColors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: u.progress.clamp(0, 1).toDouble(),
            minHeight: 6,
            color: full ? AppColors.red : AppColors.green,
            backgroundColor: AppColors.grey.withValues(alpha: 0.15),
          ),
        ),
      ],
    );
  }

  Widget _filterChips() {
    return Wrap(
      spacing: 6,
      children: [
        for (final f in _filters)
          ChoiceChip(
            label: Text(
              f == 'ALL' ? 'All' : f[0] + f.substring(1).toLowerCase(),
              style: const TextStyle(fontSize: 11),
            ),
            visualDensity: VisualDensity.compact,
            selected: controller.ledgerFilter.value == f,
            selectedColor: AppColors.green.withValues(alpha: 0.2),
            onSelected: (_) => controller.setLedgerFilter(f),
          ),
      ],
    );
  }

  List<Widget> _ledger() {
    final entries = controller.ledger;
    final error = controller.ledgerError.value;
    if (entries.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: DealerStateView(
            isLoading: controller.isLoadingLedger.value,
            error: error,
            isEmpty: true,
            emptyIcon: Icons.receipt_long_outlined,
            emptyMessage: 'No ledger entries yet.',
            onRetry: () => controller.loadLedger(reset: true),
            child: const SizedBox(),
          ),
        ),
      ];
    }
    return [
      for (final e in entries)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: DealerSectionCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DealerStatusChip(label: e.type, color: _colorFor(e.type)),
                      const SizedBox(height: 6),
                      Text(
                        [
                          if (e.connectionId.isNotEmpty) e.connectionId,
                          e.note,
                        ].where((s) => s.isNotEmpty).join(' · '),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.black,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        GlobalFunctions.getFormattedDate(
                              date: e.createdAt,
                              type: GlobalFunctions.clearDateTime,
                            ) ??
                            '',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${e.points >= 0 ? '+' : '−'} ${GlobalFunctions.formatNumber(e.points.abs())}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: e.points >= 0 ? AppColors.green : AppColors.red,
                  ),
                ),
              ],
            ),
          ),
        ),
      if (controller.isLoadingLedger.value)
        const Padding(
          padding: EdgeInsets.all(12),
          child: Center(
            child: CircularProgressIndicator(color: AppColors.green),
          ),
        )
      else if (error.isNotEmpty)
        TextButton(
          onPressed: controller.loadLedger,
          child: Text(
            '$error Tap to retry.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: AppColors.red),
          ),
        ),
      const SizedBox(height: 8),
      const Text(
        'Unused points, added ones included, expire at cycle end — no rollover. Points cannot be transferred or withdrawn.',
        style: TextStyle(color: AppColors.grey, fontSize: 11),
      ),
    ];
  }

  Color _colorFor(String type) {
    switch (type) {
      case 'MEMBERSHIP_ALLOCATED':
      case 'PROMO_ALLOCATED':
      case 'TOP_UP':
        return AppColors.green;
      case 'RESERVED':
        return AppColors.deepOrange;
      case 'CONSUMED':
      case 'EXPIRED':
        return AppColors.red;
      case 'RELEASED':
      case 'REFUNDED':
        return AppColors.blue;
      default:
        return AppColors.grey;
    }
  }
}
