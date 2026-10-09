import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:otobix/Controllers/Dealer%20Membership/dealer_inventory_controller.dart';
import 'package:otobix/Controllers/Dealer%20Membership/dealer_membership_controller.dart';
import 'package:otobix/Models/Dealer%20Membership/dealer_inventory_car_model.dart';
import 'package:otobix/Utils/app_colors.dart';
import 'package:otobix/Views/Dealer%20Membership/car_intake_page.dart';
import 'package:otobix/Views/Dealer%20Membership/dealer_membership_navigator.dart';
import 'package:otobix/Widgets/Dealer%20Membership/dealer_common_widgets.dart';
import 'package:otobix/Widgets/Dealer%20Membership/inventory_car_card.dart';
import 'package:otobix/Widgets/app_bar_widget.dart';

class DealerSellPage extends StatefulWidget {
  final int initialTab;
  const DealerSellPage({super.key, this.initialTab = 0});

  @override
  State<DealerSellPage> createState() => _DealerSellPageState();
}

class _DealerSellPageState extends State<DealerSellPage>
    with SingleTickerProviderStateMixin {
  final controller = DealerInventoryController.to;
  late final TabController tabController = TabController(
    length: 2,
    vsync: this,
    initialIndex: widget.initialTab,
  )..addListener(_onTabChanged);
  late int currentTab = widget.initialTab;

  static const _ownerships = [
    DealerInventoryCarModel.dealerOwned,
    DealerInventoryCarModel.customerOwned,
  ];

  // Brokers sell customers' cars only: no My Inventory tab.
  final bool isBroker = DealerMembershipController.to.isBroker;

  @override
  void initState() {
    super.initState();
    for (final o
        in isBroker ? [DealerInventoryCarModel.customerOwned] : _ownerships) {
      controller.loadCars(o, reset: true);
    }
  }

  void _onTabChanged() {
    if (tabController.indexIsChanging) return;
    setState(() => currentTab = tabController.index);
  }

  @override
  void dispose() {
    tabController.removeListener(_onTabChanged);
    tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ownership =
        isBroker
            ? DealerInventoryCarModel.customerOwned
            : _ownerships[currentTab];
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBarWidget(
        title: isBroker ? "My Customer's Inventory" : 'Sell',
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.green,
        foregroundColor: AppColors.white,
        icon: const Icon(Icons.add),
        label: Text(
          ownership == DealerInventoryCarModel.dealerOwned
              ? 'Add Car'
              : 'Add Customer Car',
        ),
        onPressed: () => Get.to(() => CarIntakePage(ownership: ownership)),
      ),
      body: SafeArea(
        child:
            isBroker
                ? Column(
                  children: [
                    const _BrokerCarsThisMonth(),
                    Expanded(child: _InventoryList(ownership: ownership)),
                  ],
                )
                : _tabs(),
      ),
    );
  }

  Widget _tabs() {
    return Column(
      children: [
        TabBar(
          controller: tabController,
          labelColor: AppColors.green,
          unselectedLabelColor: AppColors.grey,
          indicatorColor: AppColors.green,
          tabs: const [
            Tab(text: 'My Inventory'),
            Tab(text: "My Customer's Inventory"),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: tabController,
            children: [
              for (final o in _ownerships) _InventoryList(ownership: o),
            ],
          ),
        ),
      ],
    );
  }
}

/// A broker's customer cars this month against the plan's limit.
class _BrokerCarsThisMonth extends StatelessWidget {
  const _BrokerCarsThisMonth();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final cars = DealerMembershipController.to.membership.value?.usageFor(
        'CUSTOMER_CARS',
      );
      if (cars == null) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Text(
          '${cars.used} of ${cars.limit} customer cars added this month',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: cars.leftPoints == 0 ? AppColors.red : AppColors.grey,
          ),
        ),
      );
    });
  }
}

class _InventoryList extends StatelessWidget {
  final String ownership;
  const _InventoryList({required this.ownership});

  @override
  Widget build(BuildContext context) {
    final controller = DealerInventoryController.to;
    final list = controller.listFor(ownership);
    final isCustomer = ownership == DealerInventoryCarModel.customerOwned;
    return Obx(
      () => RefreshIndicator(
        color: AppColors.green,
        onRefresh: () => controller.loadCars(ownership, reset: true),
        child: DealerStateView(
          isLoading: list.isLoading.value,
          error: list.error.value,
          isEmpty: list.items.isEmpty,
          emptyIcon: Icons.directions_car_outlined,
          emptyMessage:
              isCustomer
                  ? "No customer cars yet. Add a customer's car to get dealer offers."
                  : 'No cars in your inventory yet. Tap Add Car to list one.',
          onRetry: () => controller.loadCars(ownership, reset: true),
          child: NotificationListener<ScrollNotification>(
            onNotification: (n) {
              if (n.metrics.pixels > n.metrics.maxScrollExtent - 300) {
                controller.loadCars(ownership);
              }
              return false;
            },
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
              itemCount: list.items.length + (list.isLoading.value ? 1 : 0),
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                if (i == list.items.length) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.green),
                  );
                }
                final car = list.items[i];
                return InventoryCarCard(
                  car: car,
                  onEdit:
                      () => Get.to(
                        () => CarIntakePage(ownership: car.ownership, car: car),
                      ),
                  onLeads: () => DealerMembershipNavigator.openCarLeads(car),
                  onOffers: () => DealerMembershipNavigator.openCarOffers(car),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
