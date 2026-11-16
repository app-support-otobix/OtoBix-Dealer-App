import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:otobix/Controllers/Dealer%20Membership/dealer_connections_controller.dart';
import 'package:otobix/Controllers/Dealer%20Membership/dealer_leads_controller.dart';
import 'package:otobix/Controllers/Dealer%20Membership/dealer_negotiations_controller.dart';
import 'package:otobix/Controllers/Dealer%20Membership/dealer_paged_list.dart';
import 'package:otobix/Models/Dealer%20Membership/dealer_connection_model.dart';
import 'package:otobix/Models/Dealer%20Membership/dealer_deal_room_model.dart';
import 'package:otobix/Utils/app_colors.dart';
import 'package:otobix/Utils/global_functions.dart';
import 'package:otobix/Views/Dealer%20Membership/dealer_membership_navigator.dart';
import 'package:otobix/Widgets/Dealer%20Membership/customer_leads_list.dart';
import 'package:otobix/Widgets/Dealer%20Membership/dealer_common_widgets.dart';
import 'package:otobix/Widgets/Dealer%20Membership/offer_card.dart';
import 'package:otobix/Widgets/app_bar_widget.dart';

/// Customer leads (enquiries from the OtoBix app and website) and dealer leads
/// (offers received and sent, connections, Deal Rooms). Add Lead is off for now.
class DealerLeadsPage extends StatefulWidget {
  final int initialTab;
  final int dealerSection;
  const DealerLeadsPage({
    super.key,
    this.initialTab = 0,
    this.dealerSection = 0,
  });

  @override
  State<DealerLeadsPage> createState() => _DealerLeadsPageState();
}

class _DealerLeadsPageState extends State<DealerLeadsPage>
    with SingleTickerProviderStateMixin {
  late final TabController tabs = TabController(
    length: 2,
    vsync: this,
    initialIndex: widget.initialTab,
  );
  late int section = widget.dealerSection;
  final leads = DealerLeadsController.to.allLeads;
  final negotiations = DealerNegotiationsController.to;
  final connections = DealerConnectionsController.to;

  static const _sections = [
    'Offers Received',
    'Offers Sent',
    'Connections',
    'Deal Rooms',
  ];

  @override
  void initState() {
    super.initState();
    leads.refresh();
    _loadSection();
  }

  @override
  void dispose() {
    tabs.dispose();
    super.dispose();
  }

  DealerPagedList _list() =>
      [
        negotiations.received,
        negotiations.sent,
        connections.connections,
        connections.dealRooms,
      ][section];

  void _loadSection() => _list().refresh();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBarWidget(title: 'Leads'),
      body: SafeArea(
        child: Column(
          children: [
            TabBar(
              controller: tabs,
              labelColor: AppColors.green,
              unselectedLabelColor: AppColors.grey,
              indicatorColor: AppColors.green,
              tabs: const [Tab(text: 'Customer'), Tab(text: 'Dealer')],
            ),
            Expanded(
              child: TabBarView(
                controller: tabs,
                children: [CustomerLeadsList(leads: leads), _dealerTab()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dealerTab() {
    return Column(
      children: [
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            itemCount: _sections.length,
            separatorBuilder: (_, __) => const SizedBox(width: 6),
            itemBuilder:
                (_, i) => ChoiceChip(
                  label: Text(
                    _sections[i],
                    style: const TextStyle(fontSize: 11),
                  ),
                  visualDensity: VisualDensity.compact,
                  selected: section == i,
                  selectedColor: AppColors.green.withValues(alpha: 0.2),
                  onSelected: (_) {
                    setState(() => section = i);
                    _loadSection();
                  },
                ),
          ),
        ),
        Expanded(
          child: Obx(() {
            final list = _list();
            return RefreshIndicator(
              color: AppColors.green,
              onRefresh: list.refresh,
              child: DealerStateView(
                isLoading: list.isLoading.value,
                error: list.error.value,
                isEmpty: list.items.isEmpty,
                emptyIcon: Icons.handshake_outlined,
                emptyMessage:
                    const [
                      'No offers on your cars yet.',
                      'You have not made any offers yet. Find cars under Buy > Dealer Inventory.',
                      'No connection requests yet.',
                      'No Deal Rooms yet. One opens when a connection is accepted.',
                    ][section],
                onRetry: list.refresh,
                child: NotificationListener<ScrollNotification>(
                  onNotification: (n) {
                    if (n.metrics.pixels > n.metrics.maxScrollExtent - 300) {
                      list.load();
                    }
                    return false;
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: list.items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _row(list.items[i]),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _row(dynamic item) {
    if (item is DealerConnectionModel) return _connectionRow(item);
    if (item is DealerDealRoomModel) return _dealRoomRow(item);
    return OfferCard(
      negotiation: item,
      onTap: () => DealerMembershipNavigator.openNegotiation(item),
    );
  }

  Widget _connectionRow(DealerConnectionModel c) {
    final color =
        {
          'PENDING': AppColors.deepOrange,
          'PAYMENT_DUE': AppColors.blue,
          'ACCEPTED': AppColors.green,
        }[c.status] ??
        AppColors.grey;
    // A Premium Listing request reserves nothing: it is paid once accepted.
    final released =
        c.isPremiumListing ? 'nothing charged' : 'reservation released';
    final detail = switch (c.status) {
      'PENDING' =>
        '${c.isPremiumListing ? 'Free request' : '${c.pointsPerSide} reserved'} · ${GlobalFunctions.timeLeft(c.expiresAt)}',
      'PAYMENT_DUE' =>
        'Owner accepted · pay ${GlobalFunctions.formatRupees(c.priceRupees)}',
      'ACCEPTED' => 'Identity revealed · Deal Room open',
      'DECLINED' => 'Declined · $released',
      'EXPIRED' => 'No reply in time · nothing charged',
      _ => 'Withdrawn · $released',
    };
    return InkWell(
      onTap: () => DealerMembershipNavigator.openConnection(c.id),
      borderRadius: BorderRadius.circular(12),
      child: DealerSectionCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.carTitle,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${c.initiatedByMe ? 'Sent to' : 'From'} ${c.counterpart.label} · $detail',
                    style: const TextStyle(fontSize: 11, color: AppColors.grey),
                  ),
                ],
              ),
            ),
            DealerStatusChip(label: c.status, color: color),
          ],
        ),
      ),
    );
  }

  Widget _dealRoomRow(DealerDealRoomModel r) {
    return InkWell(
      onTap: () => DealerMembershipNavigator.openDealRoom(r.id),
      borderRadius: BorderRadius.circular(12),
      child: DealerSectionCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    r.carTitle,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${r.counterpart.name} · ${r.agreedAmount > 0 ? 'agreed ${GlobalFunctions.formatLakh(r.agreedAmount)}' : 'asking ${GlobalFunctions.formatLakh(r.askingPrice)}'}',
                    style: const TextStyle(fontSize: 11, color: AppColors.grey),
                  ),
                ],
              ),
            ),
            DealerStatusChip(
              label: r.statusLabel.toUpperCase(),
              color:
                  r.status == 'COMPLETED'
                      ? AppColors.green
                      : r.isClosed
                      ? AppColors.red
                      : AppColors.blue,
            ),
          ],
        ),
      ),
    );
  }
}
