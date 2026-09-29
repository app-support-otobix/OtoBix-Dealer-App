import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:otobix/Controllers/Dealer%20Membership/dealer_inventory_controller.dart';
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

  @override
  void initState() {
    super.initState();
    for (final o in _ownerships) {
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
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBarWidget(title: 'Sell'),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.green,
        foregroundColor: AppColors.white,
        icon: const Icon(Icons.add),
        label: Text(currentTab == 0 ? 'Add Car' : 'Add Customer Car'),
        onPressed:
            () =>
                Get.to(() => CarIntakePage(ownership: _ownerships[currentTab])),
      ),
      body: SafeArea(
        child: Column(
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
        ),
      ),
    );
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
