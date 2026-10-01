import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:otobix/Controllers/Dealer%20Membership/dealer_exchange_controller.dart';
import 'package:otobix/Controllers/Dealer%20Membership/dealer_requirements_controller.dart';
import 'package:otobix/Models/Dealer%20Membership/dealer_exchange_model.dart';
import 'package:otobix/Utils/app_colors.dart';
import 'package:otobix/Views/Dealer%20Membership/requirement_form_page.dart';
import 'package:otobix/Widgets/Dealer%20Membership/dealer_common_widgets.dart';
import 'package:otobix/Widgets/Dealer%20Membership/exchange_filters_panel.dart';
import 'package:otobix/Widgets/Dealer%20Membership/exchange_listing_card.dart';
import 'package:otobix/Widgets/Dealer%20Membership/showroom_location_widgets.dart';
import 'package:otobix/Widgets/app_bar_widget.dart';
import 'package:otobix/Widgets/button_widget.dart';

class DealerInventoryPage extends StatefulWidget {
  final int initialTab;
  const DealerInventoryPage({super.key, this.initialTab = 0});

  @override
  State<DealerInventoryPage> createState() => _DealerInventoryPageState();
}

class _DealerInventoryPageState extends State<DealerInventoryPage>
    with SingleTickerProviderStateMixin {
  late final TabController tabController = TabController(
    length: 3,
    vsync: this,
    initialIndex: widget.initialTab,
  );
  final exchange = DealerExchangeController.to;
  final requirements = DealerRequirementsController.to;

  @override
  void initState() {
    super.initState();
    exchange.loadOptions();
    exchange.search(reset: true);
    requirements.loadRequirements();
    exchange.loadMatches(reset: true);
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBarWidget(title: 'Dealer Inventory'),
      body: SafeArea(
        child: Column(
          children: [
            TabBar(
              controller: tabController,
              labelColor: AppColors.green,
              unselectedLabelColor: AppColors.grey,
              indicatorColor: AppColors.green,
              labelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(fontSize: 12),
              labelPadding: const EdgeInsets.symmetric(horizontal: 4),
              tabs: const [
                Tab(
                  icon: Icon(Icons.search, size: 20),
                  text: 'Find Cars',
                  iconMargin: EdgeInsets.only(bottom: 4),
                ),
                Tab(
                  icon: Icon(Icons.tune, size: 20),
                  text: 'Your Requirements',
                  iconMargin: EdgeInsets.only(bottom: 4),
                ),
                Tab(
                  icon: Icon(Icons.filter_alt_outlined, size: 20),
                  text: 'Matching Inventory',
                  iconMargin: EdgeInsets.only(bottom: 4),
                ),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: tabController,
                children: [
                  const _FindCarsTab(),
                  _RequirementsTab(
                    onShowMatches: (r) {
                      exchange.showMatchesFor(r.id);
                      tabController.animateTo(2);
                    },
                  ),
                  _MatchingTab(
                    onManageFilters: () => tabController.animateTo(1),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FindCarsTab extends StatefulWidget {
  const _FindCarsTab();

  @override
  State<_FindCarsTab> createState() => _FindCarsTabState();
}

class _FindCarsTabState extends State<_FindCarsTab> {
  final fc = DealerExchangeController.to;
  late final _searchController = TextEditingController(
    text: fc.searchText.value,
  );

  static const _sorts = {
    'nearest': 'Nearest first',
    'recent': 'Recently added',
    'price_asc': 'Price: low to high',
    'price_desc': 'Price: high to low',
    'km': 'Lowest KM',
  };

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _submitSearch(String value) {
    fc.searchText.value = value;
    fc.search(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
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
                      hintText: 'Search registration, make, model, dealer ID',
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
                                      icon: const Icon(Icons.close, size: 18),
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
                  initialValue: fc.sort.value,
                  onSelected: (v) {
                    fc.sort.value = v;
                    fc.search(reset: true);
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
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ShowroomLocationCard(
            promptOnly: true,
            onSaved: () => fc.search(reset: true),
          ),
        ),
        ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.5,
          ),
          child: const SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: ExchangeFiltersPanel(),
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: Obx(
            () => _ListingList(
              items: fc.results,
              isLoading: fc.isLoading.value,
              error: fc.error.value,
              emptyMessage:
                  'No cars match this search. Try widening the filters.',
              onRefresh: () => fc.search(reset: true),
              onEndReached: fc.search,
            ),
          ),
        ),
      ],
    );
  }
}

class _RequirementsTab extends StatelessWidget {
  final void Function(DealerRequirementModel requirement) onShowMatches;
  const _RequirementsTab({required this.onShowMatches});

  @override
  Widget build(BuildContext context) {
    final rc = DealerRequirementsController.to;
    return Obx(() {
      final list = rc.requirements;
      return RefreshIndicator(
        color: AppColors.green,
        onRefresh: rc.loadRequirements,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Save the make, model, year, kms, fuel, price, transmission and city as a filter. '
              'Every new matching car alerts you, and filters expire after 30 days unless you edit them.',
              style: TextStyle(color: AppColors.grey, fontSize: 12),
            ),
            const SizedBox(height: 14),
            if (rc.isLoading.value && list.isEmpty)
              const Center(
                child: CircularProgressIndicator(color: AppColors.green),
              )
            else if (rc.error.value.isNotEmpty && list.isEmpty)
              DealerStateView(
                isLoading: false,
                error: rc.error.value,
                isEmpty: true,
                emptyMessage: '',
                onRetry: rc.loadRequirements,
                child: const SizedBox(),
              )
            else if (list.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Text(
                    'No saved filters yet.',
                    style: TextStyle(color: AppColors.grey, fontSize: 13),
                  ),
                ),
              )
            else
              for (final r in list) ...[
                _requirementCard(r, rc),
                const SizedBox(height: 12),
              ],
            const SizedBox(height: 8),
            ButtonWidget(
              text: '+ Add Filter',
              isLoading: false.obs,
              width: double.infinity,
              onTap: () => Get.to(() => const RequirementFormPage()),
            ),
          ],
        ),
      );
    });
  }

  Widget _requirementCard(
    DealerRequirementModel r,
    DealerRequirementsController rc,
  ) {
    return DealerSectionCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        r.name.trim().isNotEmpty ? r.name : r.requirementCode,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.black,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    DealerStatusChip(
                      label: r.isActive ? '${r.daysLeft}d LEFT' : 'EXPIRED',
                      color: r.isActive ? AppColors.green : AppColors.grey,
                      small: true,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  r.summary,
                  style: const TextStyle(fontSize: 12, color: AppColors.grey),
                ),
                const SizedBox(height: 6),
                InkWell(
                  onTap: () => onShowMatches(r),
                  child: Text(
                    '${r.matchCount} matches ›',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.blue,
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.edit_outlined,
              size: 20,
              color: AppColors.blue,
            ),
            tooltip: r.isActive ? 'Edit' : 'Edit & renew',
            onPressed: () => Get.to(() => RequirementFormPage(existing: r)),
          ),
          IconButton(
            icon: const Icon(
              Icons.delete_outline,
              size: 20,
              color: AppColors.red,
            ),
            onPressed: () async {
              final ok = await Get.dialog<bool>(
                AlertDialog(
                  title: const Text(
                    'Delete this filter?',
                    style: TextStyle(fontSize: 16),
                  ),
                  content: const Text(
                    'You will stop getting alerts for matching cars.',
                    style: TextStyle(fontSize: 13),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Get.back(result: false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Get.back(result: true),
                      child: const Text(
                        'Delete',
                        style: TextStyle(color: AppColors.red),
                      ),
                    ),
                  ],
                ),
              );
              if (ok == true) rc.delete(r);
            },
          ),
        ],
      ),
    );
  }
}

class _MatchingTab extends StatelessWidget {
  final VoidCallback onManageFilters;
  const _MatchingTab({required this.onManageFilters});

  @override
  Widget build(BuildContext context) {
    final fc = DealerExchangeController.to;
    final rc = DealerRequirementsController.to;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Inventory filtered against the make, model, year range and price range you've saved - set them up once and every match shows up here.",
                style: TextStyle(color: AppColors.grey, fontSize: 12),
              ),
              Obx(() {
                final id = fc.matchRequirementId.value;
                if (id.isEmpty) return const SizedBox(height: 16);
                final name =
                    rc.requirements.firstWhereOrNull((r) => r.id == id)?.name ??
                    'one filter';
                return Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 8),
                  child: InputChip(
                    label: Text(
                      'Showing: $name',
                      style: const TextStyle(fontSize: 11),
                    ),
                    onDeleted: () => fc.showMatchesFor(''),
                  ),
                );
              }),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: AppColors.green),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: onManageFilters,
                  icon: const Icon(Icons.tune, color: AppColors.green),
                  label: const Text(
                    'Manage Saved Filters',
                    style: TextStyle(
                      color: AppColors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Obx(
            () => _ListingList(
              items: fc.matches,
              isLoading: fc.isLoadingMatches.value,
              error: fc.matchesError.value,
              emptyMessage:
                  rc.requirements.isEmpty
                      ? 'Save a filter to see matching cars here.'
                      : 'No cars match your saved filters yet. You will be alerted when one is listed.',
              onRefresh: () => fc.loadMatches(reset: true),
              onEndReached: fc.loadMatches,
            ),
          ),
        ),
      ],
    );
  }
}

class _ListingList extends StatelessWidget {
  final List<DealerExchangeListingModel> items;
  final bool isLoading;
  final String error;
  final String emptyMessage;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onEndReached;

  const _ListingList({
    required this.items,
    required this.isLoading,
    required this.error,
    required this.emptyMessage,
    required this.onRefresh,
    required this.onEndReached,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.green,
      onRefresh: onRefresh,
      child: DealerStateView(
        isLoading: isLoading,
        error: error,
        isEmpty: items.isEmpty,
        emptyIcon: Icons.directions_car_outlined,
        emptyMessage: emptyMessage,
        onRetry: onRefresh,
        child: NotificationListener<ScrollNotification>(
          onNotification: (n) {
            if (n.metrics.pixels > n.metrics.maxScrollExtent - 300) {
              onEndReached();
            }
            return false;
          },
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: items.length + (isLoading ? 1 : 0),
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              if (i == items.length) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.green),
                );
              }
              return ExchangeListingCard(listing: items[i]);
            },
          ),
        ),
      ),
    );
  }
}
