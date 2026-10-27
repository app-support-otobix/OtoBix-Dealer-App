import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:otobix/Controllers/Dealer%20Membership/dealer_connections_controller.dart';
import 'package:otobix/Models/Dealer%20Membership/dealer_connection_model.dart';
import 'package:otobix/Models/Dealer%20Membership/dealer_inventory_car_model.dart';
import 'package:otobix/Utils/app_colors.dart';
import 'package:otobix/Utils/global_functions.dart';
import 'package:otobix/Views/Dealer%20Membership/dealer_membership_navigator.dart';
import 'package:otobix/Widgets/Dealer%20Membership/dealer_common_widgets.dart';
import 'package:otobix/Widgets/app_bar_widget.dart';

class SellerInitiatedConnectionPage extends StatefulWidget {
  final DealerInventoryCarModel car;
  const SellerInitiatedConnectionPage({super.key, required this.car});

  @override
  State<SellerInitiatedConnectionPage> createState() =>
      _SellerInitiatedConnectionPageState();
}

class _SellerInitiatedConnectionPageState
    extends State<SellerInitiatedConnectionPage> {
  final candidates = <DealerConnectionCandidateModel>[].obs;
  final isLoading = true.obs;
  final error = ''.obs;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    isLoading.value = true;
    final list = await DealerConnectionsController.to.candidates(widget.car.id);
    if (list != null) candidates.assignAll(list);
    error.value = list == null ? 'Buyers could not be loaded.' : '';
    isLoading.value = false;
  }

  @override
  Widget build(BuildContext context) {
    final car = widget.car;
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBarWidget(title: 'Offer to Dealers'),
      body: SafeArea(
        child: Obx(
          () => RefreshIndicator(
            color: AppColors.green,
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                DealerSectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${car.title} · ${GlobalFunctions.formatLakh(car.exchangePrice)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${car.isCustomerCar ? 'Customer car' : 'Your stock'} · ${car.city} · you are the seller',
                        style: const TextStyle(
                          color: AppColors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Matched buyers · ${candidates.length} eligible',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 10),
                if (candidates.isEmpty)
                  DealerStateView(
                    isLoading: isLoading.value,
                    error: error.value,
                    isEmpty: true,
                    emptyIcon: Icons.groups_outlined,
                    emptyMessage:
                        'No matching buyers yet. Dealers whose requirements match this car, or who start negotiating on it, appear here.',
                    onRetry: _load,
                    child: const SizedBox(),
                  )
                else
                  for (final c in candidates) ...[
                    _candidateCard(c),
                    const SizedBox(height: 10),
                  ],
                const SizedBox(height: 8),
                const Text(
                  'Requesting reserves your points per request; they are charged only if the buyer accepts, and released in full if they decline or do not reply in time.',
                  style: TextStyle(color: AppColors.grey, fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _candidateCard(DealerConnectionCandidateModel c) {
    final busy = c.connectionStatus.isNotEmpty;
    return DealerSectionCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (c.matchPercent > 0) ...[
                      DealerStatusChip(
                        label: '${c.matchPercent}% MATCH',
                        color: AppColors.blue,
                        small: true,
                      ),
                      const SizedBox(width: 6),
                    ],
                    Flexible(
                      child: Text(
                        c.reason,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${c.dealerType} · ${c.dealerCode}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                Text(
                  c.city,
                  style: const TextStyle(fontSize: 11, color: AppColors.grey),
                ),
              ],
            ),
          ),
          busy
              ? DealerStatusChip(
                label: c.connectionStatus,
                color:
                    c.connectionStatus == 'ACCEPTED'
                        ? AppColors.green
                        : AppColors.deepOrange,
              )
              : FilledButton(
                onPressed: () async {
                  await DealerMembershipNavigator.openRequestConnection(
                    carId: widget.car.id,
                    buyerDealerCode: c.dealerCode,
                  );
                  _load();
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.green,
                  minimumSize: const Size(0, 34),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                child: const Text('Connect', style: TextStyle(fontSize: 12)),
              ),
        ],
      ),
    );
  }
}
