import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:otobix/Controllers/Dealer%20Membership/dealer_exchange_controller.dart';
import 'package:otobix/Utils/app_colors.dart';
import 'package:otobix/Widgets/Dealer%20Membership/exchange_listing_card.dart';
import 'package:otobix/Widgets/app_bar_widget.dart';

/// Buy › Customer Inventory: customers' cars their owners listed for dealers
/// (Premium Listing). Chatting and offers are free; the owner's name and phone
/// cost ₹2,000 once they accept a connection.
class CustomerInventoryPage extends StatefulWidget {
  const CustomerInventoryPage({super.key});

  @override
  State<CustomerInventoryPage> createState() => _CustomerInventoryPageState();
}

class _CustomerInventoryPageState extends State<CustomerInventoryPage> {
  final fc = DealerExchangeController.to;
  late final _searchController = TextEditingController(
    text: fc.customerSearchText.value,
  );

  static const _sorts = {
    'recent': 'Recently listed',
    'price_asc': 'Price: low to high',
    'price_desc': 'Price: high to low',
    'km': 'Lowest KM',
  };

  @override
  void initState() {
    super.initState();
    fc.customerCars.refresh();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _submitSearch(String value) {
    fc.customerSearchText.value = value;
    fc.customerCars.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final cars = fc.customerCars;
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBarWidget(title: 'Customer Inventory'),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: TextField(
                        controller: _searchController,
                        textInputAction: TextInputAction.search,
                        onSubmitted: _submitSearch,
                        decoration: InputDecoration(
                          isDense: true,
                          hintText: 'Search make, model, variant',
                          hintStyle: TextStyle(
                            color: AppColors.grey.withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                          prefixIcon: const Icon(
                            Icons.search,
                            size: 20,
                            color: AppColors.grey,
                          ),
                          suffixIcon: ValueListenableBuilder(
                            valueListenable: _searchController,
                            builder:
                                (_, value, __) =>
                                    value.text.isEmpty
                                        ? const SizedBox.shrink()
                                        : IconButton(
                                          icon: const Icon(
                                            Icons.close,
                                            size: 18,
                                          ),
                                          onPressed: () {
                                            _searchController.clear();
                                            _submitSearch('');
                                          },
                                        ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(100),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(100),
                            borderSide: const BorderSide(
                              color: AppColors.green,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Obx(
                    () => PopupMenuButton<String>(
                      tooltip: 'Sort',
                      icon: const Icon(Icons.sort, color: AppColors.green),
                      initialValue: fc.customerSort.value,
                      onSelected: (v) {
                        fc.customerSort.value = v;
                        cars.refresh();
                      },
                      itemBuilder:
                          (_) => [
                            for (final e in _sorts.entries)
                              PopupMenuItem(value: e.key, child: Text(e.value)),
                          ],
                    ),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 10),
              child: Text(
                'Cars their owners listed on OtoBix. Chat and offers are free; '
                'once an owner accepts your connection, pay ₹2,000 to see their name and phone.',
                style: TextStyle(fontSize: 11, color: AppColors.grey),
              ),
            ),
            Expanded(
              child: Obx(
                () => ExchangeListingList(
                  items: cars.items.toList(),
                  isLoading: cars.isLoading.value,
                  error: cars.error.value,
                  emptyMessage: 'No customer cars are listed right now.',
                  onRefresh: cars.refresh,
                  onEndReached: cars.load,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
