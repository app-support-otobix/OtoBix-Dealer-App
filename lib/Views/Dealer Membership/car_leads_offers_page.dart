import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:otobix/Controllers/Dealer%20Membership/dealer_inventory_controller.dart';
import 'package:otobix/Controllers/Dealer%20Membership/dealer_leads_controller.dart';
import 'package:otobix/Controllers/Dealer%20Membership/dealer_negotiations_controller.dart';
import 'package:otobix/Models/Dealer%20Membership/dealer_inventory_car_model.dart';
import 'package:otobix/Models/Dealer%20Membership/dealer_negotiation_model.dart';
import 'package:otobix/Utils/app_colors.dart';
import 'package:otobix/Utils/global_functions.dart';
import 'package:otobix/Views/Dealer%20Membership/dealer_membership_navigator.dart';
import 'package:otobix/Widgets/Dealer%20Membership/chat_message_bubble.dart';
import 'package:otobix/Widgets/Dealer%20Membership/customer_leads_list.dart';
import 'package:otobix/Widgets/Dealer%20Membership/dealer_common_widgets.dart';
import 'package:otobix/Widgets/Dealer%20Membership/offer_card.dart';
import 'package:otobix/Widgets/Dealer%20Membership/vehicle_spec_sheet.dart';
import 'package:otobix/Widgets/app_bar_widget.dart';

class CarLeadsOffersPage extends StatefulWidget {
  final DealerInventoryCarModel car;
  final int initialTab;
  const CarLeadsOffersPage({super.key, required this.car, this.initialTab = 0});

  @override
  State<CarLeadsOffersPage> createState() => _CarLeadsOffersPageState();
}

class _CarLeadsOffersPageState extends State<CarLeadsOffersPage>
    with SingleTickerProviderStateMixin {
  late DealerInventoryCarModel car = widget.car;
  late final leads = DealerLeadsController.to.leadsFor(carId: car.id);
  final offers = <DealerNegotiationModel>[].obs;
  final discovery = Rxn<DealerPriceDiscoveryModel>();
  final isLoadingOffers = true.obs;
  final offersError = ''.obs;
  late final TabController tabs = TabController(
    length: 2,
    vsync: this,
    initialIndex: widget.initialTab,
  );

  @override
  void initState() {
    super.initState();
    if (!car.isCustomerCar) leads.refresh();
    _loadOffers();
  }

  @override
  void dispose() {
    tabs.dispose();
    super.dispose();
  }

  Future<void> _loadOffers() async {
    isLoadingOffers.value = true;
    final result = await DealerNegotiationsController.to.carOffers(car.id);
    if (result != null) {
      offers.assignAll(result.$1);
      discovery.value = result.$2;
    }
    offersError.value = result == null ? 'Offers could not be loaded.' : '';
    isLoadingOffers.value = false;
  }

  Future<void> _revisePrice() async {
    final amount = await showDealerOfferDialog(
      context,
      title: 'Revise Dealer Price',
      suggested: car.exchangePrice,
    );
    if (amount == null) return;
    final saved = await DealerInventoryController.to.saveCar({
      'exchangeEnabled': true,
      'exchangePrice': amount,
      'exchangeVisibility':
          car.exchangeVisibility.isEmpty ? 'OPEN' : car.exchangeVisibility,
    }, id: car.id);
    if (!saved) return;
    final updated = DealerInventoryController.to
        .listFor(car.ownership)
        .items
        .firstWhereOrNull((c) => c.id == car.id);
    if (updated != null) setState(() => car = updated);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBarWidget(
        title: car.isCustomerCar ? 'Dealer Offers' : car.title,
      ),
      floatingActionButton:
          car.isCustomerCar
              ? null
              : FloatingActionButton.small(
                backgroundColor: AppColors.green,
                foregroundColor: AppColors.white,
                tooltip: 'Add lead',
                onPressed: () async {
                  if (await showAddLeadDialog(context, carId: car.id) != null) {
                    leads.refresh();
                  }
                },
                child: const Icon(Icons.person_add_alt),
              ),
      body: SafeArea(
        child:
            car.isCustomerCar
                ? _offersList(header: true)
                : Column(
                  children: [
                    Obx(
                      () => TabBar(
                        controller: tabs,
                        labelColor: AppColors.green,
                        unselectedLabelColor: AppColors.grey,
                        indicatorColor: AppColors.green,
                        tabs: [
                          Tab(text: 'Customer Leads (${leads.items.length})'),
                          Tab(text: 'Dealer Offers (${offers.length})'),
                        ],
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: tabs,
                        children: [
                          CustomerLeadsList(leads: leads),
                          _offersList(header: false),
                        ],
                      ),
                    ),
                  ],
                ),
      ),
    );
  }

  Widget _offersList({required bool header}) {
    return Obx(() {
      final list = offers.toList();
      return RefreshIndicator(
        color: AppColors.green,
        onRefresh: _loadOffers,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (header) ...[
              _askingPriceCard(),
              const SizedBox(height: 12),
              _discoveryCard(),
              const SizedBox(height: 16),
            ],
            Text(
              'Offers (${list.length})',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 4),
            const Text(
              'Buyers stay anonymous until a connection is accepted. Answering questions and responding to offers is free.',
              style: TextStyle(fontSize: 11, color: AppColors.grey),
            ),
            const SizedBox(height: 10),
            if (list.isEmpty)
              DealerStateView(
                isLoading: isLoadingOffers.value,
                error: offersError.value,
                isEmpty: true,
                emptyIcon: Icons.local_offer_outlined,
                emptyMessage: 'No dealer offers on this car yet.',
                onRetry: _loadOffers,
                child: const SizedBox(),
              )
            else
              for (final n in list) ...[
                OfferCard(
                  negotiation: n,
                  showCar: false,
                  onTap: () => DealerMembershipNavigator.openNegotiation(n),
                ),
                if (n.questionCount > 0 && n.lastOfferAmount == null)
                  TextButton(
                    onPressed: () => DealerMembershipNavigator.openChat(n.id),
                    child: Text(
                      'Answer ${n.questionCount} question${n.questionCount == 1 ? '' : 's'} ›',
                    ),
                  ),
                const SizedBox(height: 12),
              ],
          ],
        ),
      );
    });
  }

  Widget _askingPriceCard() {
    return DealerSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CarThumbnail(
                imageUrl: car.images.isEmpty ? '' : car.images.first,
                iconColor: AppColors.blue,
                size: 48,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  car.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Asking Dealer Price',
                      style: TextStyle(fontSize: 11, color: AppColors.grey),
                    ),
                    Text(
                      GlobalFunctions.formatRupees(car.exchangePrice),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.blue,
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: _revisePrice,
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Revise'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.blue,
                  side: const BorderSide(color: AppColors.blue),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed:
                  () => DealerMembershipNavigator.openOfferToDealers(car),
              icon: const Icon(Icons.campaign_outlined, size: 16),
              label: const Text('Offer to Dealers · approach matched buyers'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.green,
                side: const BorderSide(color: AppColors.green),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _discoveryCard() {
    final d = discovery.value;
    return DealerSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CURRENT DEALER MARKET RANGE',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            d == null || d.count == 0
                ? 'No offers yet'
                : '${GlobalFunctions.formatLakh(d.min)} – ${GlobalFunctions.formatLakh(d.max)} · ${d.count} offer${d.count == 1 ? '' : 's'} · avg ${GlobalFunctions.formatLakh(d.average)}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppColors.green,
            ),
          ),
          if (d != null && d.count > 0 && d.max >= car.exchangePrice)
            const Text(
              'At least one offer meets your asking price',
              style: TextStyle(fontSize: 11, color: AppColors.green),
            ),
        ],
      ),
    );
  }
}
