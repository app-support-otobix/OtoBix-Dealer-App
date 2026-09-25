import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:otobix/Controllers/Dealer%20Membership/dealer_membership_controller.dart';
import 'package:otobix/Models/Dealer%20Membership/dealer_membership_model.dart';
import 'package:otobix/Utils/app_colors.dart';
import 'package:otobix/Utils/global_functions.dart';
import 'package:otobix/Views/Dealer%20Membership/dealer_membership_navigator.dart';
import 'package:otobix/Views/Dealer%20Membership/dealer_registration_page.dart';
import 'package:otobix/Widgets/Dealer%20Membership/dealer_common_widgets.dart';
import 'package:otobix/Widgets/Dealer%20Membership/dealer_plan_picker.dart';
import 'package:otobix/Widgets/app_bar_widget.dart';

/// Membership Dashboard & Point Ledger.
class MembershipDashboardPage extends StatefulWidget {
  const MembershipDashboardPage({super.key});

  @override
  State<MembershipDashboardPage> createState() =>
      _MembershipDashboardPageState();
}

class _MembershipDashboardPageState extends State<MembershipDashboardPage> {
  final DealerMembershipController controller = DealerMembershipController.to;

  static const _filters = ['ALL', 'EXPIRED'];

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
      appBar: AppBarWidget(title: 'Membership & Point Ledger'),
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
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (m == null || !m.isOnboarded)
                    _registerCard()
                  else ...[
                    _planCard(m),
                    const SizedBox(height: 14),
                    const Text(
                      'Points are platform credits, not currency — allocated with each '
                      'membership cycle and expired at cycle end.',
                      style: TextStyle(color: AppColors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      m.isActive ? 'Renew or Change Plan' : 'Choose a Plan',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const DealerPlanPicker(),
                    const SizedBox(height: 16),
                    DealerSectionCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          _settingsTile(
                            Icons.history,
                            'Activity Log',
                            DealerMembershipNavigator.openActivityLog,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Point Ledger',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _filterChips(),
                    const SizedBox(height: 10),
                    ..._ledger(),
                  ],
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _settingsTile(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      dense: true,
      leading: Icon(icon, color: AppColors.green, size: 20),
      title: Text(label, style: const TextStyle(fontSize: 13)),
      trailing: const Icon(
        Icons.chevron_right,
        color: AppColors.grey,
        size: 18,
      ),
      onTap: onTap,
    );
  }

  Widget _registerCard() {
    return DealerSectionCard(
      title: 'Become a Dealer Member',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tell us your dealer type and trade area, then pick a plan to get '
            'OtoBix Points every membership cycle.',
            style: TextStyle(fontSize: 12, color: AppColors.grey),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.green),
              onPressed: () => Get.to(() => const DealerRegistrationPage()),
              child: const Text('Start Registration'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _planCard(DealerMembershipModel m) {
    final plan = m.plan;
    final summary = m.summary;
    final endDate =
        GlobalFunctions.getFormattedDate(
          date: m.cycleEndAt,
          type: GlobalFunctions.date,
        ) ??
        '';
    final statusLine =
        m.isActive
            ? 'Cycle ${m.cycleNumber} · renews by $endDate'
            : m.status == 'EXPIRED'
            ? 'Ended on $endDate · renew to continue'
            : 'No active plan yet';
    return DealerSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                (plan?.name ?? 'Dealer Membership').toUpperCase(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.blue,
                  fontSize: 14,
                ),
              ),
              DealerStatusChip(
                label: m.isActive ? 'ACTIVE' : m.status,
                color: m.isActive ? AppColors.green : AppColors.red,
                small: true,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${m.dealerCode} · ${m.dealerType} · ${m.city}',
            style: const TextStyle(color: AppColors.grey, fontSize: 11),
          ),
          Text(
            statusLine,
            style: const TextStyle(color: AppColors.grey, fontSize: 11),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              DealerStatTile(
                value: '${m.availablePoints}',
                label: 'Available points',
              ),
              DealerStatTile(
                value: '${summary?.allocated ?? 0}',
                label: 'Allocated this cycle',
                color: AppColors.blue,
              ),
            ],
          ),
        ],
      ),
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
                        [e.note].where((s) => s.isNotEmpty).join(' · '),
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
                  '${e.points >= 0 ? '+' : '−'} ${e.points.abs()}',
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
        'Unused points expire at cycle end — no rollover. Points cannot be bought, transferred or withdrawn.',
        style: TextStyle(color: AppColors.grey, fontSize: 11),
      ),
    ];
  }

  Color _colorFor(String type) {
    switch (type) {
      case 'MEMBERSHIP_ALLOCATED':
      case 'PROMO_ALLOCATED':
        return AppColors.green;
      case 'EXPIRED':
        return AppColors.red;
      default:
        return AppColors.grey;
    }
  }
}
