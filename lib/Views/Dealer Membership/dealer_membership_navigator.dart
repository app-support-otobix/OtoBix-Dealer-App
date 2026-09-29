import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:otobix/Controllers/Dealer%20Membership/dealer_exchange_controller.dart';
import 'package:otobix/Controllers/Dealer%20Membership/dealer_inventory_controller.dart';
import 'package:otobix/Controllers/Dealer%20Membership/dealer_negotiations_controller.dart';
import 'package:otobix/Controllers/bottom_navigation_controller.dart';
import 'package:otobix/Models/Dealer%20Membership/dealer_exchange_model.dart';
import 'package:otobix/Models/Dealer%20Membership/dealer_inventory_car_model.dart';
import 'package:otobix/Models/Dealer%20Membership/dealer_negotiation_model.dart';
import 'package:otobix/Utils/app_colors.dart';
import 'package:otobix/Views/Dealer%20Membership/activity_log_page.dart';
import 'package:otobix/Views/Dealer%20Membership/car_intake_page.dart';
import 'package:otobix/Views/Dealer%20Membership/car_leads_offers_page.dart';
import 'package:otobix/Views/Dealer%20Membership/deal_chat_page.dart';
import 'package:otobix/Views/Dealer%20Membership/deal_room_page.dart';
import 'package:otobix/Views/Dealer%20Membership/dealer_inventory_page.dart';
import 'package:otobix/Views/Dealer%20Membership/dealer_leads_page.dart';
import 'package:otobix/Views/Dealer%20Membership/dealer_registration_page.dart';
import 'package:otobix/Views/Dealer%20Membership/dealer_sell_page.dart';
import 'package:otobix/Views/Dealer%20Membership/exchange_listing_page.dart';
import 'package:otobix/Views/Dealer%20Membership/finance_page.dart';
import 'package:otobix/Views/Dealer%20Membership/insurance_page.dart';
import 'package:otobix/Views/Dealer%20Membership/membership_dashboard_page.dart';
import 'package:otobix/Views/Dealer%20Membership/rc_challan_check_page.dart';
import 'package:otobix/Views/Dealer%20Membership/request_connection_page.dart';
import 'package:otobix/Views/Dealer%20Membership/review_offer_page.dart';
import 'package:otobix/Views/Dealer%20Membership/seller_initiated_connection_page.dart';
import 'package:otobix/Views/Dealer%20Membership/upgrade_membership_page.dart';
import 'package:otobix/Views/Dealer%20Panel/service_history_page.dart';
import 'package:otobix/Widgets/Dealer%20Membership/dealer_renewal_banner.dart';
import 'package:otobix/Widgets/app_bar_widget.dart';

class DealerFeature {
  final String label;
  final IconData icon;
  final List<String> keywords;
  final void Function(BuildContext context) open;

  const DealerFeature(this.label, this.icon, this.keywords, this.open);
}

class DealerMembershipNavigator {
  DealerMembershipNavigator._();

  static final List<DealerFeature> features = [
    DealerFeature(
      'Membership & Point Ledger',
      Icons.workspace_premium_outlined,
      ['membership', 'points', 'ledger', 'plan', 'renew', 'upgrade'],
      (_) => openMembership(),
    ),
    DealerFeature('Sell · My Inventory', Icons.directions_car_filled_outlined, [
      'sell',
      'inventory',
      'my cars',
      'upload',
      'stock',
      'listing',
    ], (_) => openSell()),
    DealerFeature(
      "My Customer's Inventory",
      Icons.person_add_alt_outlined,
      ['sell', 'customer', 'customer car', 'add customer car'],
      (_) => openSell(tab: 1),
    ),
    DealerFeature('Dealer Inventory · Find Cars', Icons.search, [
      'buy',
      'find',
      'dealer inventory',
      'exchange',
      'wholesale',
      'search cars',
    ], (_) => openDealerInventory()),
    DealerFeature('Saved Filters & Requirements', Icons.tune, [
      'buy',
      'filters',
      'requirement',
      'saved',
    ], (_) => openDealerInventory(tab: 1)),
    DealerFeature(
      'Matching Inventory',
      Icons.filter_alt_outlined,
      ['buy', 'matching', 'match'],
      (_) => openDealerInventory(tab: 2),
    ),
    DealerFeature('OtoBix Auctions', Icons.gavel_outlined, [
      'buy',
      'auction',
      'live',
      'bid',
      'otobuy',
    ], (_) => openAuctions()),
    DealerFeature('Customer Leads', Icons.groups_outlined, [
      'leads',
      'customer',
      'enquiry',
      'walk-in',
    ], (_) => openLeads()),
    DealerFeature('Offers Received', Icons.local_offer_outlined, [
      'offers',
      'dealer leads',
      'received',
      'negotiation',
    ], (_) => openLeads(tab: 1)),
    DealerFeature('My Offers Sent', Icons.send_outlined, [
      'offers',
      'sent',
      'my offers',
    ], (_) => openLeads(tab: 1, section: 1)),
    DealerFeature('Connections', Icons.link, [
      'connection',
      'request',
      'deal room request',
    ], (_) => openLeads(tab: 1, section: 2)),
    DealerFeature('Deal Rooms', Icons.meeting_room_outlined, [
      'deal room',
      'deal',
      'chat',
    ], (_) => openLeads(tab: 1, section: 3)),
    DealerFeature('RC Check', Icons.assignment_outlined, [
      'services',
      'rc',
      'challan',
      'registration',
      'owner',
      'mobile',
      'rc check',
    ], (_) => openRcCheck()),
    DealerFeature('Service History', Icons.build_outlined, [
      'services',
      'service history',
    ], (_) => openServiceHistory()),
    DealerFeature('Insurance', Icons.shield_outlined, [
      'services',
      'insurance',
      'policy',
      'quote',
      'renew',
    ], (_) => openInsurance()),
    DealerFeature('Car Finance', Icons.account_balance_outlined, [
      'services',
      'finance',
      'loan',
      'emi',
    ], (_) => openFinance()),
    DealerFeature('Activity Log', Icons.history, [
      'activity',
      'log',
      'history',
      'notifications',
    ], (_) => openActivityLog()),
    DealerFeature('Upgrade Membership', Icons.upgrade, [
      'membership',
      'upgrade',
      'renew',
      'plan',
      'pro',
      'payment',
    ], (_) => openUpgrade()),
  ];

  static void openMembership() => Get.to(() => const MembershipDashboardPage());

  static void openSell({int tab = 0}) =>
      Get.to(() => DealerSellPage(initialTab: tab));

  static void openLeads({int tab = 0, int section = 0}) =>
      Get.to(() => DealerLeadsPage(initialTab: tab, dealerSection: section));

  static void openActivityLog() => Get.to(() => const ActivityLogPage());

  static void openUpgrade() => Get.to(() => const UpgradeMembershipPage());

  static void openDealerDetails() =>
      Get.to(() => const DealerRegistrationPage());

  static void openAddCustomerCar() => Get.to(
    () => const CarIntakePage(ownership: DealerInventoryCarModel.customerOwned),
  );

  static Future<void> openListing(String id) async {
    final car = await DealerInventoryController.to.getCar(id);
    if (car != null) {
      Get.to(() => CarIntakePage(ownership: car.ownership, car: car));
    }
  }

  static void openCarLeads(DealerInventoryCarModel car) =>
      Get.to(() => CarLeadsOffersPage(car: car));

  static void openCarOffers(DealerInventoryCarModel car) =>
      Get.to(() => CarLeadsOffersPage(car: car, initialTab: 1));

  static void openOfferToDealers(DealerInventoryCarModel car) =>
      Get.to(() => SellerInitiatedConnectionPage(car: car));

  static void openDealerInventory({int tab = 0}) =>
      Get.to(() => DealerInventoryPage(initialTab: tab));

  static Future<void> openExchangeListing(String id) async {
    final listing = await DealerExchangeController.to.getListing(id);
    if (listing != null) Get.to(() => ExchangeListingPage(listing: listing));
  }

  static void openAuctions() => Get.to(
    () => Scaffold(
      appBar: AppBarWidget(title: 'Auctions'),
      body: Get.find<BottomNavigationController>().auctionsPage,
    ),
  );

  static void openServiceHistory() => Get.to(() => ServiceHistoryPage());

  static void openRcCheck() => Get.to(() => const RcChallanCheckPage());

  static void openInsurance() => Get.to(() => const InsurancePage());

  static void openFinance() => Get.to(() => const FinancePage());

  static void openChat(String negotiationId) =>
      Get.to(() => DealChatPage(negotiationId: negotiationId));

  static void openReviewOffer(String negotiationId) =>
      Get.to(() => ReviewOfferPage(negotiationId: negotiationId));

  static void openNegotiation(DealerNegotiationModel n) {
    if (n.dealRoomId.isNotEmpty) return openDealRoom(n.dealRoomId);
    if (n.lastOfferAmount != null || n.agreedAmount > 0) {
      return openReviewOffer(n.id);
    }
    openChat(n.id);
  }

  static Future<void> openRequestConnection({
    String negotiationId = '',
    String carId = '',
    String buyerDealerCode = '',
  }) async {
    await Get.to(
      () => RequestConnectionPage(
        negotiationId: negotiationId,
        carId: carId,
        buyerDealerCode: buyerDealerCode,
      ),
    );
  }

  static void openConnection(String connectionId) =>
      Get.to(() => RequestConnectionPage(connectionId: connectionId));

  static void openDealRoom(String dealRoomId, {bool replace = false}) {
    if (replace) {
      Get.off(() => DealRoomPage(dealRoomId: dealRoomId));
    } else {
      Get.to(() => DealRoomPage(dealRoomId: dealRoomId));
    }
  }

  static Future<void> openChatForListing(
    DealerExchangeListingModel listing,
  ) async {
    final n = await DealerNegotiationsController.to.openForListing(listing.id);
    if (n != null) openChat(n.id);
  }

  static Future<void> requestConnectionForListing(
    DealerExchangeListingModel listing,
  ) async {
    final n = await DealerNegotiationsController.to.openForListing(listing.id);
    if (n == null) return;
    if (n.dealRoomId.isNotEmpty) return openDealRoom(n.dealRoomId);
    if (n.hasPendingConnection) return openConnection(n.connectionId);
    openRequestConnection(negotiationId: n.id);
  }

  static void openBuyDrawer(BuildContext context) => _drawer(context, 'Buy', [
    _DrawerItem(
      Icons.gavel_outlined,
      Colors.deepOrange,
      'Auctions',
      'Live bidding on new inventory',
      openAuctions,
    ),
    _DrawerItem(
      Icons.directions_car_filled_outlined,
      AppColors.green,
      'Dealer Inventory',
      'Active Dealer Stock on OtoBix',
      openDealerInventory,
    ),
  ]);

  static void openServicesDrawer(BuildContext context) =>
      _drawer(context, 'Services', header: const DealerRenewalBanner(), [
        _DrawerItem(
          Icons.assignment_outlined,
          AppColors.blue,
          'RC Check',
          'RC details, owner mobile & challans',
          openRcCheck,
        ),
        _DrawerItem(
          Icons.build_outlined,
          AppColors.green,
          'Service History',
          'Past maintenance records',
          openServiceHistory,
        ),
        _DrawerItem(
          Icons.shield_outlined,
          Colors.deepPurple,
          'Insurance',
          'Compare & buy policies',
          openInsurance,
        ),
        _DrawerItem(
          Icons.account_balance_outlined,
          AppColors.deepOrange,
          'Finance',
          'EMI estimate & customer loans',
          openFinance,
        ),
      ]);

  static Future<void> openTarget(String type, String id) async {
    switch (type) {
      case 'RC_CHECK':
        return openRcCheck();
      case 'SERVICE_HISTORY':
        return openServiceHistory();
      case 'LISTING':
        return openListing(id);
      case 'EXCHANGE_LISTING':
        return openExchangeListing(id);
      case 'REQUIREMENT':
        return openDealerInventory(tab: 1);
      case 'NEGOTIATION':
        final n = await DealerNegotiationsController.to.get(id);
        if (n != null) openNegotiation(n);
        return;
      case 'CONNECTION':
        return openConnection(id);
      case 'DEAL_ROOM':
        return openDealRoom(id);
      case 'LEAD':
      case 'LEADS':
        return openLeads();
      default:
        return openMembership();
    }
  }

  static Color categoryColor(String category) {
    switch (category) {
      case 'MATCH':
        return AppColors.blue;
      case 'OFFER':
        return AppColors.deepOrange;
      case 'CONNECTION':
      case 'DEAL':
        return AppColors.green;
      case 'LEAD':
      case 'MEMBERSHIP':
        return Colors.teal;
      case 'SERVICE':
        return Colors.deepPurple;
      default:
        return AppColors.grey;
    }
  }

  static void _drawer(
    BuildContext context,
    String title,
    List<_DrawerItem> items, {
    Widget? header,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (sheetContext) => Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(sheetContext).size.height * 0.6,
            ),
            decoration: const BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.grey.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (header != null) header,
                      Card(
                        elevation: 1,
                        margin: EdgeInsets.zero,
                        color: AppColors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(
                            color: AppColors.grey.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Column(
                          children: [
                            for (var i = 0; i < items.length; i++) ...[
                              if (i > 0)
                                const Divider(
                                  height: 1,
                                  indent: 16,
                                  endIndent: 16,
                                ),
                              _drawerTile(sheetContext, items[i]),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
    );
  }

  static Widget _drawerTile(BuildContext sheetContext, _DrawerItem item) {
    return InkWell(
      onTap: () {
        Navigator.of(sheetContext).pop();
        item.onTap();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: item.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(item.icon, color: item.color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.subtitle,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.grey, size: 20),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem {
  final IconData icon;
  final Color color;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  _DrawerItem(this.icon, this.color, this.label, this.subtitle, this.onTap);
}
