import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:otobix/Controllers/home_controller.dart';
import 'package:otobix/Controllers/live_bids_controller.dart';
import 'package:otobix/Controllers/oto_buy_controller.dart';
import 'package:otobix/Controllers/self_inspected_cars_list_controller.dart';
import 'package:otobix/Controllers/tab_bar_buttons_controller.dart';
import 'package:otobix/Controllers/upcoming_controller.dart';
import 'package:otobix/Utils/app_colors.dart';
import 'package:otobix/Utils/app_constants.dart';
import 'package:otobix/Views/Dealer%20Panel/live_bids_page.dart';
import 'package:otobix/Views/Dealer%20Panel/oto_buy_page.dart';
import 'package:otobix/Views/Dealer%20Panel/self_inspected_cars_list_page.dart';
import 'package:otobix/Views/Dealer%20Panel/upcoming_page.dart';
import 'package:otobix/Views/Dealer%20Panel/user_notifications_page.dart';
import 'package:otobix/Widgets/button_widget.dart';
import 'package:otobix/Widgets/tab_bar_buttons_widget.dart';
import 'package:otobix/helpers/dealer_home_search_sort_filter_helper.dart';

class HomePage extends StatelessWidget {
  HomePage({super.key});

  final HomeController getxController = Get.put(HomeController());
  final tabBarController = Get.put(
    TabBarButtonsController(tabLength: 4, initialIndex: 1),
    // TabBarButtonsController(tabLength: 3, initialIndex: 1),
  );
  // Different tabs controllers
  final UpcomingController upcomingController = Get.put(UpcomingController());
  final LiveBidsController liveBidsController = Get.put(LiveBidsController());
  final OtoBuyController otoBuyController = Get.put(OtoBuyController());
  final SelfInspectedCarsListController selfInspectedCarsListController =
      Get.put(SelfInspectedCarsListController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // TabBar Screens / Sections
            Padding(
              padding: const EdgeInsets.only(top: 110, left: 15, right: 15),
              child: TabBarView(
                controller: tabBarController.tabController,
                children: [
                  UpcomingPage(),
                  LiveBidsPage(),
                  OtoBuyPage(),
                  SelfInspectedCarsListPage(),
                ],
              ),
            ),

            Material(
              elevation: 4,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 20),

                    // Search bar + city filter
                    _buildSearchBar(context),
                    const SizedBox(height: 15),

                    // TabBar Buttons
                    Obx(
                      () => TabBarButtonsWidget(
                        titles: ['Upcoming', 'Live', 'OtoBuy', 'PD'],

                        counts: [
                          upcomingController.upcomingCarsCount.value,
                          liveBidsController.liveBidsCarsCount.value,
                          otoBuyController.otoBuyCarsCount.value,
                          selfInspectedCarsListController
                              .selfInspectedCarsCount
                              .value,
                        ],
                        controller: tabBarController.tabController,
                        selectedIndex: tabBarController.selectedIndex,

                        // titleSize: 10,
                        titleSize: 11,
                        countSize: 7,
                        tabsHeight: 30,
                        spaceFromSides: 15,
                      ),
                    ),

                    const SizedBox(height: 15),

                    // Filter and Sort buttons
                    // _buildFilterAndSortButtons(),
                    // const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return SizedBox(
      height: 35,
      child: Row(
        children: [
          Flexible(
            child: Padding(
              padding: const EdgeInsets.only(left: 15, right: 7),
              child: TextFormField(
                controller: getxController.searchController,
                keyboardType: TextInputType.text,
                style: TextStyle(fontSize: 12),
                decoration: InputDecoration(
                  hintText: 'Search...',
                  hintStyle: TextStyle(
                    color: AppColors.grey.withValues(alpha: .5),
                    fontSize: 12,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Colors.grey,
                    size: 20,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(100),
                    borderSide: BorderSide(color: AppColors.black),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(100),
                    borderSide: BorderSide(color: AppColors.green, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 3,
                    horizontal: 10,
                  ),
                  suffixIcon: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Obx(
                      //   () =>
                      Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: GestureDetector(
                          onTap: () => _buildStateSelector(context),
                          // child: Row(
                          //   mainAxisSize: MainAxisSize.min,
                          //   children: [
                          //     Text(
                          //       getxController.selectedCity.value,
                          //       style: TextStyle(fontSize: 10, color: Colors.black),
                          //     ),
                          child: Icon(
                            Icons.location_on_outlined,
                            size: 20,
                            color: AppColors.grey,
                          ),
                          //   ],
                          // ),
                        ),
                      ),
                      // ),

                      // const SizedBox(width: 10),
                      _buildFilterAndSortButtons(),
                    ],
                  ),

                  // suffixIcon: Obx(
                  //   () => Padding(
                  //     padding: const EdgeInsets.only(right: 20),
                  //     child: DropdownButtonHideUnderline(
                  //       child: DropdownButton<String>(
                  //         alignment: Alignment.centerRight,
                  //         value: getxController.selectedCity.value,

                  //         icon: const Icon(
                  //           Icons.keyboard_arrow_down,
                  //           color: Colors.grey,
                  //           size: 20,
                  //         ),
                  //         onChanged: (value) {
                  //           if (value != null) {
                  //             getxController.selectedCity.value = value;
                  //           }
                  //         },
                  //         items:
                  //             getxController.cities
                  //                 .map(
                  //                   (city) => DropdownMenuItem<String>(
                  //                     value: city,
                  //                     child: Text(
                  //                       city,
                  //                       style: TextStyle(
                  //                         fontSize: 10,
                  //                         color: Colors.black,
                  //                       ),
                  //                     ),
                  //                   ),
                  //                 )
                  //                 .toList(),
                  //       ),
                  //     ),
                  //   ),
                  // ),
                ),
                onChanged: (value) => getxController.changeSearchText(value),
                // onChanged: (value) {
                // getxController.filteredCars.value =
                //     getxController.carsList
                //         .where(
                //           (car) => '${car.make} ${car.model} ${car.variant}'
                //               .toLowerCase()
                //               .contains(value.toLowerCase()),
                //         )
                //         .toList();
                // },
              ),
            ),
          ),

          GestureDetector(
            onTap: () => Get.to(() => UserNotificationsPage()),
            child: Obx(
              () => Badge.count(
                count: getxController.unreadNotificationsCount.value,
                child: Icon(
                  Icons.notifications_outlined,
                  size: 25,
                  color: AppColors.grey,
                ),
              ),
            ),
          ),

          SizedBox(width: 15),
        ],
      ),
    );
  }

  void _buildStateSelector(BuildContext context) {
    // Make sure options are initialized (safe to call multiple times)
    DealerHomeSearchSortFilterHelper.initStates(AppConstants.indianStates);

    final options = DealerHomeSearchSortFilterHelper.stateOptions; // RxList
    final filteredStates = options.toList().obs; // local filtered view
    getxController.searchStateController.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.8,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: const Text(
                      'Select State',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Search
                  SizedBox(
                    height: 35,
                    child: TextFormField(
                      controller: getxController.searchStateController,
                      keyboardType: TextInputType.text,
                      style: const TextStyle(fontSize: 12),
                      decoration: InputDecoration(
                        hintText: 'Search states...',
                        hintStyle: TextStyle(
                          color: AppColors.grey.withValues(alpha: .5),
                          fontSize: 12,
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: AppColors.grey,
                          size: 20,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(100),
                          borderSide: const BorderSide(color: AppColors.black),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(100),
                          borderSide: const BorderSide(
                            color: AppColors.green,
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 3,
                          horizontal: 10,
                        ),
                      ),
                      onChanged: (value) {
                        final v = value.toLowerCase();
                        filteredStates.value =
                            options
                                .where((s) => s.toLowerCase().contains(v))
                                .toList();
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

                  // List
                  Obx(() {
                    final selected =
                        DealerHomeSearchSortFilterHelper.selectedState.value;
                    final list = filteredStates;
                    return Expanded(
                      child: ListView.separated(
                        controller: scrollController,
                        itemCount: list.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, index) {
                          final city = list[index];
                          final isSelected = city == selected;
                          return InkWell(
                            onTap: () {
                              DealerHomeSearchSortFilterHelper.setSelectedState(
                                city,
                              );
                              DealerHomeSearchSortFilterHelper.applyStateFilter();
                              Navigator.pop(context);
                            },
                            borderRadius: BorderRadius.circular(100),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 10,
                                horizontal: 25,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(100),
                                color: AppColors.grey.withValues(alpha: .1),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    city,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  Icon(
                                    isSelected
                                        ? Icons.check_circle
                                        : Icons.location_on,
                                    size: 15,
                                    color: AppColors.green,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  }),

                  // const SizedBox(height: 10),

                  // // Clear filter
                  // Align(
                  //   alignment: Alignment.centerRight,
                  //   child: TextButton(
                  //     onPressed: () {
                  //       DealerHomeSearchSortFilterHelper.clearStateFilter();
                  //       Navigator.pop(context);
                  //     },
                  //     child: const Text('Clear state filter'),
                  //   ),
                  // ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Widget _buildChangeSegmentsButton() {
  //   return Container(
  //     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
  //     margin: const EdgeInsets.symmetric(horizontal: 16),
  //     width: double.infinity,
  //     decoration: BoxDecoration(
  //       // color: AppColors.gray.withValues(alpha: .1),
  //       borderRadius: BorderRadius.circular(50),
  //     ),
  //     child: AdvancedSegment(
  //       controller: getxController.selectedSegmentNotifier,
  //       segments: getxController.segments,
  //       activeStyle: const TextStyle(
  //         color: AppColors.white,
  //         fontWeight: FontWeight.bold,
  //       ),
  //       inactiveStyle: const TextStyle(color: AppColors.black),
  //       backgroundColor: AppColors.gray.withValues(alpha: .1),
  //       sliderDecoration: BoxDecoration(
  //         color: AppColors.green,
  //         borderRadius: BorderRadius.circular(50),
  //       ),
  //       borderRadius: BorderRadius.circular(50),
  //     ),
  //   );
  // }

  // Filter and Sort buttons
  Widget _buildFilterAndSortButtons() {
    return Padding(
      padding: const EdgeInsets.only(right: 20),

      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          //Filter Button
          GestureDetector(
            // onTap:
            //     () => _showFilterDialog(context: Get.context!, title: 'Filter'),
            onTap:
                () => showModalBottomSheet(
                  context: Get.context!,
                  isScrollControlled: true,

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  // builder: (_) => _buildFilterContent(),
                  builder:
                      (ctx) => DraggableScrollableSheet(
                        expand: false,
                        initialChildSize: 0.85, // 80%
                        maxChildSize: 0.9, // cap at 90%
                        minChildSize: 0.7,
                        builder:
                            (_, scrollController) => SingleChildScrollView(
                              controller: scrollController,
                              child: Padding(
                                padding: EdgeInsets.only(
                                  bottom: MediaQuery.of(ctx).viewInsets.bottom,
                                ),
                                child: _buildFilterContent(),
                              ),
                            ),
                      ),
                ),
            // child: Row(
            //   children: [
            child: Icon(
              Icons.filter_alt_outlined,
              size: 20,
              color: AppColors.grey,
            ),
            // SizedBox(width: 5),
            // Text('Filter', style: const TextStyle(fontSize: 14)),
            //   ],
            // ),
          ),
          SizedBox(width: 10),

          // Padding(
          //   padding: const EdgeInsets.symmetric(horizontal: 10),
          //   child: Text(
          //     '|',
          //     style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          //   ),
          // ),

          //Sort Button
          GestureDetector(
            onTap:
                () => showModalBottomSheet(
                  context: Get.context!,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  builder: (_) => _buildSortContent(),
                ),
            // child: Row(
            //   children: [
            // Text(
            //   getxController.selectedSegment.value != 'live'
            //       ? 'Default'
            //       : 'Sort',
            //   style: const TextStyle(fontSize: 14),
            // ),
            // SizedBox(width: 5),
            child: Icon(
              getxController.selectedSegment.value != 'live'
                  ? Icons.import_export_outlined
                  : Icons.sort,
              size: 20,
              color: AppColors.grey,
            ),
            //   ],
            // ),
          ),
        ],
      ),
    );
  }

  // // Segments Screens
  // Widget _buildSegmentsScreens() {
  //   return Expanded(
  //     child: SingleChildScrollView(
  //       padding: const EdgeInsets.all(16.0),
  //       child: Column(
  //         children: [
  //           Obx(
  //             () =>
  //                 getxController.selectedSegment.value != 'live'
  //                     ? Ocb70Section()
  //                     : LiveBidsSection(),
  //           ),
  //           const SizedBox(height: 10),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  // Filter Content
  Widget _buildFilterContent() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.green,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Filter Cars',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Fuel Type',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            Wrap(
              spacing: 8,
              children:
                  ['Petrol', 'Diesel'].map((type) {
                    return Obx(() {
                      // Fuel chips
                      final isSelected = DealerHomeSearchSortFilterHelper
                          .selectedFuelTypesFilter
                          .contains(type);

                      return FilterChip(
                        label: Text(
                          type,
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                isSelected ? AppColors.green : AppColors.black,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: AppColors.green.withValues(alpha: .1),
                        // backgroundColor: AppColors.gray.withValues(alpha: .1),
                        checkmarkColor: AppColors.green,
                        showCheckmark: true,
                        labelPadding: const EdgeInsets.symmetric(
                          horizontal: 3,
                          vertical: 0,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),

                        onSelected: (selected) {
                          final s =
                              DealerHomeSearchSortFilterHelper
                                  .selectedFuelTypesFilter;
                          if (selected)
                            s.add(type);
                          else
                            s.remove(type);
                        },
                      );
                    });
                  }).toList(),
            ),

            const SizedBox(height: 15),

            // Price Range Inputs
            const Text(
              'Price Range (Lacs)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            const SizedBox(height: 5),
            Obx(
              () => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RangeSlider(
                    values:
                        DealerHomeSearchSortFilterHelper
                            .selectedPriceRange
                            .value,
                    min: DealerHomeSearchSortFilterHelper.minPrice,
                    max: DealerHomeSearchSortFilterHelper.maxPrice,
                    divisions: 50,
                    labels: RangeLabels(
                      '${DealerHomeSearchSortFilterHelper.selectedPriceRange.value.start.toStringAsFixed(0)} Lacs',
                      '${DealerHomeSearchSortFilterHelper.selectedPriceRange.value.end.toStringAsFixed(0)} Lacs',
                    ),

                    onChanged: (values) {
                      DealerHomeSearchSortFilterHelper
                          .selectedPriceRange
                          .value = values;
                      DealerHomeSearchSortFilterHelper
                          .minPriceController
                          .text = values.start.toStringAsFixed(0);
                      DealerHomeSearchSortFilterHelper
                          .maxPriceController
                          .text = values.end.toStringAsFixed(0);
                    },

                    activeColor: AppColors.green,
                    inactiveColor: AppColors.grey.withValues(alpha: .3),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Rs. ${DealerHomeSearchSortFilterHelper.selectedPriceRange.value.start.toStringAsFixed(0)}L - Rs. ${DealerHomeSearchSortFilterHelper.selectedPriceRange.value.end.toStringAsFixed(0)}L',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      ////////////////////////
                      SizedBox(
                        width: 200,
                        height: 40,
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller:
                                    DealerHomeSearchSortFilterHelper
                                        .minPriceController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Min (Lacs)',
                                  labelStyle: TextStyle(
                                    fontSize: 10,
                                    color: AppColors.grey,
                                  ),
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 10,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                ),
                                onChanged: (value) {
                                  final min = double.tryParse(value);
                                  final currentMax =
                                      DealerHomeSearchSortFilterHelper
                                          .selectedPriceRange
                                          .value
                                          .end;
                                  if (min != null) {
                                    final clampedMin = min.clamp(
                                      DealerHomeSearchSortFilterHelper.minPrice,
                                      DealerHomeSearchSortFilterHelper.maxPrice,
                                    );
                                    if (clampedMin <= currentMax) {
                                      DealerHomeSearchSortFilterHelper
                                          .selectedPriceRange
                                          .value = RangeValues(
                                        clampedMin,
                                        currentMax,
                                      );
                                    }
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller:
                                    DealerHomeSearchSortFilterHelper
                                        .maxPriceController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Max (Lacs)',
                                  labelStyle: TextStyle(
                                    fontSize: 10,
                                    color: AppColors.grey,
                                  ),
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 10,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                ),
                                onChanged: (value) {
                                  final max = double.tryParse(value);
                                  final currentMin =
                                      DealerHomeSearchSortFilterHelper
                                          .selectedPriceRange
                                          .value
                                          .start;
                                  if (max != null) {
                                    final clampedMax = max.clamp(
                                      DealerHomeSearchSortFilterHelper.minPrice,
                                      DealerHomeSearchSortFilterHelper.maxPrice,
                                    );
                                    if (clampedMax >= currentMin) {
                                      DealerHomeSearchSortFilterHelper
                                          .selectedPriceRange
                                          .value = RangeValues(
                                        currentMin,
                                        clampedMax,
                                      );
                                    }
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 15),

            // Inside _buildFilterContent()
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: _buildFilterDropdown<int>(
                    label: 'Manufacturing Year',
                    hintText: 'Select Year',
                    selectedValue:
                        DealerHomeSearchSortFilterHelper.selectedYearFilter,
                    items: List.generate(100, (i) => 2025 - i),
                    onChanged: (val) {
                      if (val != null) {
                        DealerHomeSearchSortFilterHelper
                            .selectedYearFilter
                            .value = val;
                      }
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildFilterDropdown<String>(
                    label: 'Make',
                    hintText: 'Select Make',
                    selectedValue:
                        DealerHomeSearchSortFilterHelper.selectedMakeFilter,
                    items: DealerHomeSearchSortFilterHelper.makesListFilter,
                    onChanged: (val) {
                      if (val != null) {
                        // When Make changes
                        DealerHomeSearchSortFilterHelper
                            .selectedMakeFilter
                            .value = val;
                        DealerHomeSearchSortFilterHelper
                            .selectedModelFilter
                            .value = null;
                        DealerHomeSearchSortFilterHelper
                            .selectedVariantFilter
                            .value = null;
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: Obx(
                    () => _buildFilterDropdown<String>(
                      label: 'Model',
                      hintText: 'Select Model',
                      selectedValue:
                          DealerHomeSearchSortFilterHelper.selectedModelFilter,
                      items:
                          DealerHomeSearchSortFilterHelper
                              .modelsListFilter[DealerHomeSearchSortFilterHelper
                              .selectedMakeFilter
                              .value] ??
                          [],
                      onChanged: (val) {
                        if (val != null) {
                          // When Model changes
                          DealerHomeSearchSortFilterHelper
                              .selectedModelFilter
                              .value = val;
                          DealerHomeSearchSortFilterHelper
                              .selectedVariantFilter
                              .value = null;
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Obx(
                    () => _buildFilterDropdown<String>(
                      label: 'Variant',
                      hintText: 'Select Variant',
                      selectedValue:
                          DealerHomeSearchSortFilterHelper
                              .selectedVariantFilter,
                      items:
                          DealerHomeSearchSortFilterHelper
                              .variantsListFilter[DealerHomeSearchSortFilterHelper
                              .selectedModelFilter
                              .value] ??
                          [],
                      onChanged: (val) {
                        if (val != null) {
                          // When Variant changes
                          DealerHomeSearchSortFilterHelper
                              .selectedVariantFilter
                              .value = val;
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 15),
            // Transmission Filter
            const Text(
              'Transmission',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children:
                  DealerHomeSearchSortFilterHelper.transmissionTypes.map((t) {
                    return Obx(() {
                      final isSelected = DealerHomeSearchSortFilterHelper
                          .selectedTransmissionFilter
                          .contains(t);
                      return FilterChip(
                        label: Text(
                          t,
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                isSelected ? AppColors.green : AppColors.black,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: AppColors.green.withValues(alpha: .1),
                        checkmarkColor: AppColors.green,
                        showCheckmark: true,
                        labelPadding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 0,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        onSelected: (sel) {
                          if (sel) {
                            DealerHomeSearchSortFilterHelper
                                .selectedTransmissionFilter
                                .add(t);
                          } else {
                            DealerHomeSearchSortFilterHelper
                                .selectedTransmissionFilter
                                .remove(t);
                          }
                        },
                      );
                    });
                  }).toList(),
            ),

            // KM range filter
            const SizedBox(height: 15),
            const Text(
              'KMs Driven',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            const SizedBox(height: 5),
            LayoutBuilder(
              builder: (ctx, constraints) {
                final isNarrow = constraints.maxWidth < 360;

                return Obx(() {
                  final rv =
                      DealerHomeSearchSortFilterHelper.selectedKmsRange.value;

                  Widget valueAndInputs =
                      isNarrow
                          ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Compact summary line
                              Text(
                                '${getxController.formatKm(rv.start)}–${getxController.formatKm(rv.end)} km',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  // Inputs share space on narrow screens
                                  Expanded(
                                    child: TextField(
                                      controller:
                                          DealerHomeSearchSortFilterHelper
                                              .minKmsController,
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        labelText: 'Min (km)',
                                        labelStyle: TextStyle(
                                          fontSize: 10,
                                          color: AppColors.grey,
                                        ),
                                        isDense: true,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 10,
                                            ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            5,
                                          ),
                                        ),
                                      ),
                                      onChanged: (v) {
                                        final min = double.tryParse(v);
                                        final currentMax =
                                            DealerHomeSearchSortFilterHelper
                                                .selectedKmsRange
                                                .value
                                                .end;
                                        if (min != null) {
                                          final clampedMin = min.clamp(
                                            DealerHomeSearchSortFilterHelper
                                                .minKms,
                                            DealerHomeSearchSortFilterHelper
                                                .maxKms,
                                          );
                                          if (clampedMin <= currentMax) {
                                            DealerHomeSearchSortFilterHelper
                                                .selectedKmsRange
                                                .value = RangeValues(
                                              clampedMin,
                                              currentMax,
                                            );
                                          }
                                        }
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: TextField(
                                      controller:
                                          DealerHomeSearchSortFilterHelper
                                              .maxKmsController,
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        labelText: 'Max (km)',
                                        labelStyle: TextStyle(
                                          fontSize: 10,
                                          color: AppColors.grey,
                                        ),
                                        isDense: true,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 10,
                                            ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            5,
                                          ),
                                        ),
                                      ),
                                      onChanged: (v) {
                                        final max = double.tryParse(v);
                                        final currentMin =
                                            DealerHomeSearchSortFilterHelper
                                                .selectedKmsRange
                                                .value
                                                .start;
                                        if (max != null) {
                                          final clampedMax = max.clamp(
                                            DealerHomeSearchSortFilterHelper
                                                .minKms,
                                            DealerHomeSearchSortFilterHelper
                                                .maxKms,
                                          );
                                          if (clampedMax >= currentMin) {
                                            DealerHomeSearchSortFilterHelper
                                                .selectedKmsRange
                                                .value = RangeValues(
                                              currentMin,
                                              clampedMax,
                                            );
                                          }
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          )
                          : Row(
                            children: [
                              // Left text gets flexible space and ellipsizes
                              Expanded(
                                child: Text(
                                  '${getxController.formatKm(rv.start)}–${getxController.formatKm(rv.end)} km',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              // Right inputs have a max width and won't push beyond screen
                              Flexible(
                                flex: 0,
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 240,
                                  ), // tweak if needed
                                  child: SizedBox(
                                    height: 40,
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            controller:
                                                DealerHomeSearchSortFilterHelper
                                                    .minKmsController,
                                            keyboardType: TextInputType.number,
                                            decoration: InputDecoration(
                                              labelText: 'Min (km)',
                                              labelStyle: TextStyle(
                                                fontSize: 10,
                                                color: AppColors.grey,
                                              ),
                                              isDense: true,
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 10,
                                                  ),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(5),
                                              ),
                                            ),
                                            onChanged: (v) {
                                              final min = double.tryParse(v);
                                              final currentMax =
                                                  DealerHomeSearchSortFilterHelper
                                                      .selectedKmsRange
                                                      .value
                                                      .end;
                                              if (min != null) {
                                                final clampedMin = min.clamp(
                                                  DealerHomeSearchSortFilterHelper
                                                      .minKms,
                                                  DealerHomeSearchSortFilterHelper
                                                      .maxKms,
                                                );
                                                if (clampedMin <= currentMax) {
                                                  DealerHomeSearchSortFilterHelper
                                                      .selectedKmsRange
                                                      .value = RangeValues(
                                                    clampedMin,
                                                    currentMax,
                                                  );
                                                }
                                              }
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: TextField(
                                            controller:
                                                DealerHomeSearchSortFilterHelper
                                                    .maxKmsController,
                                            keyboardType: TextInputType.number,
                                            decoration: InputDecoration(
                                              labelText: 'Max (km)',
                                              labelStyle: TextStyle(
                                                fontSize: 10,
                                                color: AppColors.grey,
                                              ),
                                              isDense: true,
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 10,
                                                  ),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(5),
                                              ),
                                            ),
                                            onChanged: (v) {
                                              final max = double.tryParse(v);
                                              final currentMin =
                                                  DealerHomeSearchSortFilterHelper
                                                      .selectedKmsRange
                                                      .value
                                                      .start;
                                              if (max != null) {
                                                final clampedMax = max.clamp(
                                                  DealerHomeSearchSortFilterHelper
                                                      .minKms,
                                                  DealerHomeSearchSortFilterHelper
                                                      .maxKms,
                                                );
                                                if (clampedMax >= currentMin) {
                                                  DealerHomeSearchSortFilterHelper
                                                      .selectedKmsRange
                                                      .value = RangeValues(
                                                    currentMin,
                                                    clampedMax,
                                                  );
                                                }
                                              }
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RangeSlider(
                        values: rv,
                        min: DealerHomeSearchSortFilterHelper.minKms,
                        max: DealerHomeSearchSortFilterHelper.maxKms,
                        divisions: 60,
                        labels: RangeLabels(
                          getxController.formatKm(
                            rv.start,
                          ), // compact labels => no overflow
                          getxController.formatKm(rv.end),
                        ),
                        onChanged: (RangeValues values) {
                          final start = values.start.clamp(
                            DealerHomeSearchSortFilterHelper.minKms,
                            DealerHomeSearchSortFilterHelper.maxKms,
                          );
                          final end = values.end.clamp(
                            DealerHomeSearchSortFilterHelper.minKms,
                            DealerHomeSearchSortFilterHelper.maxKms,
                          );
                          DealerHomeSearchSortFilterHelper
                              .selectedKmsRange
                              .value = RangeValues(start, end);
                          DealerHomeSearchSortFilterHelper
                              .minKmsController
                              .text = start.toInt().toString();
                          DealerHomeSearchSortFilterHelper
                              .maxKmsController
                              .text = end.toInt().toString();
                        },
                        activeColor: AppColors.green,
                        inactiveColor: AppColors.grey.withValues(alpha: .3),
                      ),
                      const SizedBox(height: 5),
                      valueAndInputs,
                    ],
                  );
                });
              },
            ),

            // Ownership Serial No range filter
            const SizedBox(height: 15),
            const Text(
              'Ownership (Serial No.)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            const SizedBox(height: 5),
            Obx(() {
              final rv =
                  DealerHomeSearchSortFilterHelper.selectedOwnershipRange.value;
              String _label(double v) {
                final i = v.round();
                if (i == 1) return '1st';
                if (i == 2) return '2nd';
                if (i == 3) return '3rd';
                return '${i}th';
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RangeSlider(
                    values: RangeValues(
                      rv.start.roundToDouble(),
                      rv.end.roundToDouble(),
                    ),
                    min:
                        DealerHomeSearchSortFilterHelper.minOwnership
                            .toDouble(),
                    max:
                        DealerHomeSearchSortFilterHelper.maxOwnership
                            .toDouble(),
                    divisions:
                        (DealerHomeSearchSortFilterHelper.maxOwnership -
                            DealerHomeSearchSortFilterHelper.minOwnership),
                    labels: RangeLabels(_label(rv.start), _label(rv.end)),
                    onChanged: (RangeValues values) {
                      final s = values.start.round().toDouble();
                      final e = values.end.round().toDouble();
                      DealerHomeSearchSortFilterHelper
                          .selectedOwnershipRange
                          .value = RangeValues(s, e);
                      DealerHomeSearchSortFilterHelper
                          .minOwnershipController
                          .text = s.toInt().toString();
                      DealerHomeSearchSortFilterHelper
                          .maxOwnershipController
                          .text = e.toInt().toString();
                    },
                    activeColor: AppColors.green,
                    inactiveColor: AppColors.grey.withValues(alpha: .3),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_label(rv.start)} – ${_label(rv.end)} owner',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(
                        width: 220,
                        height: 40,
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller:
                                    DealerHomeSearchSortFilterHelper
                                        .minOwnershipController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Min',
                                  labelStyle: TextStyle(
                                    fontSize: 10,
                                    color: AppColors.grey,
                                  ),
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 10,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                ),
                                onChanged: (v) {
                                  final min = int.tryParse(v);
                                  final currentMax =
                                      DealerHomeSearchSortFilterHelper
                                          .selectedOwnershipRange
                                          .value
                                          .end
                                          .toInt();
                                  if (min != null) {
                                    final clampedMin = min.clamp(
                                      DealerHomeSearchSortFilterHelper
                                          .minOwnership,
                                      DealerHomeSearchSortFilterHelper
                                          .maxOwnership,
                                    );
                                    if (clampedMin <= currentMax) {
                                      DealerHomeSearchSortFilterHelper
                                          .selectedOwnershipRange
                                          .value = RangeValues(
                                        clampedMin.toDouble(),
                                        currentMax.toDouble(),
                                      );
                                    }
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller:
                                    DealerHomeSearchSortFilterHelper
                                        .maxOwnershipController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Max',
                                  labelStyle: TextStyle(
                                    fontSize: 10,
                                    color: AppColors.grey,
                                  ),
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 10,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                ),
                                onChanged: (v) {
                                  final max = int.tryParse(v);
                                  final currentMin =
                                      DealerHomeSearchSortFilterHelper
                                          .selectedOwnershipRange
                                          .value
                                          .start
                                          .toInt();
                                  if (max != null) {
                                    final clampedMax = max.clamp(
                                      DealerHomeSearchSortFilterHelper
                                          .minOwnership,
                                      DealerHomeSearchSortFilterHelper
                                          .maxOwnership,
                                    );
                                    if (clampedMax >= currentMin) {
                                      DealerHomeSearchSortFilterHelper
                                          .selectedOwnershipRange
                                          .value = RangeValues(
                                        currentMin.toDouble(),
                                        clampedMax.toDouble(),
                                      );
                                    }
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              );
            }),

            const SizedBox(height: 24),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: ButtonWidget(
                    text: 'Reset',
                    textColor: AppColors.white,
                    backgroundColor: AppColors.red,
                    height: 35,
                    isLoading: false.obs,
                    elevation: 5,
                    onTap: () {
                      DealerHomeSearchSortFilterHelper.resetFilters();
                      Navigator.pop(Get.context!);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ButtonWidget(
                    text: 'Apply',
                    height: 35,
                    isLoading: false.obs,
                    elevation: 5,
                    onTap: () {
                      DealerHomeSearchSortFilterHelper.applyFilters();
                      Navigator.pop(Get.context!);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Filter Dropdowns
  Widget _buildFilterDropdown<T>({
    required String label,
    required Rx<T?> selectedValue,
    required List<T> items,
    required Function(T?) onChanged,
    required String hintText,
  }) {
    return Obx(
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          const SizedBox(height: 5),
          Container(
            height: 35,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.white,
              border: Border.all(color: AppColors.grey.withValues(alpha: .3)),
              borderRadius: BorderRadius.circular(5),
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withValues(alpha: .05),
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                isExpanded: true,
                menuMaxHeight: 300,
                value: selectedValue.value,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                style: const TextStyle(fontSize: 13, color: AppColors.black),
                hint: Text(hintText, style: const TextStyle(fontSize: 12)),
                items:
                    items
                        .map(
                          (item) => DropdownMenuItem(
                            value: item,
                            child: Text(
                              item.toString(),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        )
                        .toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortContent() {
    // local temp selection (starts from global selection)
    final tempSelected = RxString(
      DealerHomeSearchSortFilterHelper.selectedSortLabel.value,
    );

    return Obx(() {
      final options = DealerHomeSearchSortFilterHelper.sortOptions;

      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.green,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Sort By',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // Radios
            ...options.map((option) {
              return RadioListTile<String>(
                title: Text(option, style: const TextStyle(fontSize: 15)),
                value: option,
                groupValue: tempSelected.value,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                onChanged: (value) {
                  if (value != null) tempSelected.value = value;
                },
              );
            }),

            const SizedBox(height: 10),

            // Row: Clear sort (left) + Apply (right)
            Row(
              children: [
                Expanded(
                  child: ButtonWidget(
                    text: 'Clear sort',
                    // width: 140,
                    isLoading: false.obs,
                    elevation: 5,
                    backgroundColor: AppColors.red,
                    onTap: () {
                      // Clear + close
                      DealerHomeSearchSortFilterHelper.clearSort();
                      Navigator.pop(Get.context!);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ButtonWidget(
                    text: 'Apply',
                    // width: 140,
                    isLoading: false.obs,
                    elevation: 5,
                    onTap: () {
                      // Persist selection, then mark as applied
                      DealerHomeSearchSortFilterHelper.setSelectedSortLabel(
                        tempSelected.value,
                      );
                      DealerHomeSearchSortFilterHelper.applySort();
                      Navigator.pop(Get.context!);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }
}
