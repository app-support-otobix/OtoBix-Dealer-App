import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:otobix/Controllers/user_preferences_controller.dart';
import 'package:otobix/Utils/app_colors.dart';
import 'package:otobix/Widgets/button_widget.dart';

class UserPreferencesPage extends StatelessWidget {
  UserPreferencesPage({super.key});

  final UserPreferencesController getxController = Get.put(
    UserPreferencesController(),
  );
  final RxInt expandedIndex = (-1).obs;

  final List<String> sectionTitles = [
    'Preferred Car Types',
    'Preferred Fuel Types',
    'Bid Price Range',
    'Transmission Type',
    'Body Type',
    'Preferred Brands',
    'Car Condition',
    'Color Preferences',
    'Location Preference',
    'Show Inspected Cars',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'User Preferences',
          style: TextStyle(color: Colors.black, fontSize: 15),
        ),
        backgroundColor: AppColors.white,
        centerTitle: true,
        elevation: 0.5,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        itemCount: sectionTitles.length + 1,
        itemBuilder: (context, index) {
          if (index == sectionTitles.length) {
            return Padding(
              padding: const EdgeInsets.only(top: 30),
              child: Row(
                children: [
                  Expanded(
                    child: ButtonWidget(
                      text: 'Save Preferences',
                      isLoading: false.obs,
                      onTap: () {
                        showDialog(
                          context: context,
                          builder:
                              (_) => AlertDialog(
                                title: const Text('Preferences Saved'),
                                content: const Text(
                                  'Your car filters have been updated.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('OK'),
                                  ),
                                ],
                              ),
                        );
                      },
                      height: 40,
                      fontSize: 12,
                      elevation: 5,
                      backgroundColor: AppColors.green,
                      textColor: AppColors.white,
                      loaderSize: 15,
                      loaderStrokeWidth: 1,
                      loaderColor: AppColors.white,
                    ),
                  ),
                ],
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Obx(() {
              final isExpanded = expandedIndex.value == index;

              return AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    border: Border.all(
                      color: AppColors.green.withValues(alpha: 0.2),
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      if (isExpanded)
                        BoxShadow(
                          color: AppColors.black.withValues(alpha: 0.05),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                    ],
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        title: Text(
                          sectionTitles[index],
                          style: const TextStyle(
                            fontSize: 12,
                            // fontWeight: FontWeight.bold,
                            color: CupertinoColors.inactiveGray,
                          ),
                        ),
                        trailing: Icon(
                          isExpanded ? Icons.expand_less : Icons.expand_more,
                          color: AppColors.grey,
                        ),
                        onTap: () {
                          expandedIndex.value = isExpanded ? -1 : index;
                        },
                      ),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (child, animation) {
                          return SizeTransition(
                            sizeFactor: animation,
                            axis: Axis.vertical,
                            child: child,
                          );
                        },
                        child:
                            isExpanded
                                ? Padding(
                                  key: ValueKey(index),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 10,
                                  ),
                                  child: _buildSectionWidget(index),
                                )
                                : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }

  Widget _buildSectionWidget(int index) {
    switch (index) {
      // Car Types
      case 0:
        return _buildChips(
          options: getxController.carTypes,
          selectedList: getxController.selectedCarTypes,
        );
      // Fuel Types
      case 1:
        return _buildChips(
          options: getxController.fuelTypes,
          selectedList: getxController.selectedFuelTypes,
        );
      // Price Slider
      case 2:
        return _buildPriceSlider();
      // Transmission Types
      case 3:
        return _buildChips(
          options: getxController.transmissionTypes,
          selectedList: getxController.selectedTransmissionTypes,
        );
      // Body Types
      case 4:
        return _buildChips(
          options: getxController.bodyTypes,
          selectedList: getxController.selectedBodyTypes,
        );
      // Brands
      case 5:
        return _buildBrandSelector();
      // Car Conditions
      case 6:
        return _buildChips(
          options: getxController.carConditions,
          selectedList: getxController.selectedCarConditions,
        );
      // Color Preferences
      case 7:
        return _buildColorPreferences();
      // Location Preferences
      case 8:
        return _buildChips(
          options: getxController.cityList,
          selectedList: getxController.selectedCities,
        );
      // Show only trusted sellers
      case 9:
        return _buildInspectedCarsCheckbox();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildChips({
    required List<String> options,
    required RxList<String> selectedList,
  }) {
    return Center(
      child: Wrap(
        spacing: 10,
        runSpacing: 5,
        alignment: WrapAlignment.center,
        children:
            options.map((option) {
              return Obx(() {
                final isSelected = selectedList.contains(option);
                return ChoiceChip(
                  label: Text(option),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      getxController.addToSelectedList(
                        selectedList: selectedList,
                        selectedValue: option,
                      );
                    } else {
                      getxController.removeFromSelectedList(
                        selectedList: selectedList,
                        selectedValue: option,
                      );
                    }
                  },
                  selectedColor: AppColors.green.withValues(alpha: .1),
                  // backgroundColor: AppColors.gray.withValues(alpha: .1),
                  checkmarkColor: AppColors.green,
                  showCheckmark: true,
                  labelPadding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 0,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  labelStyle: TextStyle(
                    color: isSelected ? AppColors.green : AppColors.black,
                    fontSize: 12,
                  ),
                );
              });
            }).toList(),
      ),
    );
  }

  Widget _buildPriceSlider() {
    return Obx(() {
      final range = getxController.selectedPriceRange.value;

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Max and Min Range
            Text(
              'Min: ${range.start.toStringAsFixed(0)}Lacs  -  Max: ${range.end.toStringAsFixed(0)}Lacs',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 5),
            // Range Slider
            RangeSlider(
              values: range,
              min: getxController.minPrice,
              max: getxController.maxPrice,
              divisions: 50,
              labels: RangeLabels(
                '${range.start.toStringAsFixed(0)} Lacs',
                '${range.end.toStringAsFixed(0)} Lacs',
              ),
              onChanged: (values) {
                getxController.selectedPriceRange.value = values;
                getxController.minPriceController.value.text =
                    values.start.toInt().toString();
                getxController.maxPriceController.value.text =
                    values.end.toInt().toString();
              },
              activeColor: AppColors.green,
              inactiveColor: AppColors.grey.withValues(alpha: .3),
            ),

            const SizedBox(height: 5),

            // Price Display + Inputs
            SizedBox(
              width: 200,
              height: 40,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Min Price
                  Expanded(
                    child: TextField(
                      controller: getxController.minPriceController.value,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Min (Lacs)',
                        labelStyle: const TextStyle(
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
                      onChanged: (value) {
                        final min = double.tryParse(value);
                        final max = getxController.selectedPriceRange.value.end;

                        if (min != null) {
                          final clampedMin = min.clamp(
                            getxController.minPrice,
                            getxController.maxPrice,
                          );
                          if (clampedMin <= max) {
                            getxController
                                .selectedPriceRange
                                .value = RangeValues(clampedMin, max);
                          }
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 10),

                  Expanded(
                    child: TextField(
                      controller: getxController.maxPriceController.value,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Max (Lacs)',
                        labelStyle: const TextStyle(
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
                      onChanged: (value) {
                        final max = double.tryParse(value);
                        final min =
                            getxController.selectedPriceRange.value.start;

                        if (max != null) {
                          final clampedMax = max.clamp(
                            getxController.minPrice,
                            getxController.maxPrice,
                          );
                          if (clampedMax >= min) {
                            getxController
                                .selectedPriceRange
                                .value = RangeValues(min, clampedMax);
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
      );
    });
  }

  Widget _buildBrandSelector() {
    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: getxController.brandList.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, index) {
          final brand = getxController.brandList[index];
          return Obx(() {
            final isSelected = getxController.selectedBrands.contains(brand);
            return GestureDetector(
              onTap: () {
                if (isSelected) {
                  getxController.selectedBrands.remove(brand);
                } else {
                  getxController.selectedBrands.add(brand);
                }
              },
              child: Column(
                children: [
                  CircleAvatar(
                    backgroundColor:
                        isSelected
                            ? AppColors.green.withValues(alpha: .2)
                            : AppColors.grey.withValues(alpha: .2),
                    child: Text(
                      brand[0],
                      style: const TextStyle(color: AppColors.black),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(brand, style: const TextStyle(fontSize: 10)),
                ],
              ),
            );
          });
        },
      ),
    );
  }

  Widget _buildColorPreferences() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Obx(
          () => Center(
            child: Wrap(
              spacing: 10,
              runSpacing: 5,
              alignment: WrapAlignment.center,
              children:
                  getxController.carColors.map((color) {
                    final isSelected = getxController.selectedColors.contains(
                      color,
                    );
                    return ChoiceChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 4,
                            backgroundColor: color['dot'],
                          ),
                          const SizedBox(width: 4),
                          Text(color['name']),
                        ],
                      ),
                      selected: isSelected,
                      onSelected: (_) {
                        isSelected
                            ? getxController.selectedColors.remove(color)
                            : getxController.selectedColors.add(color);
                      },
                      selectedColor: AppColors.green.withValues(alpha: .2),
                    );
                  }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInspectedCarsCheckbox() {
    return Obx(
      () => CheckboxListTile(
        title: const Text('Show inspected cars'),
        value: getxController.showVerifiedOnly.value,
        activeColor: AppColors.green,
        checkColor: AppColors.white,
        onChanged:
            (val) => getxController.showVerifiedOnly.value = val ?? false,
      ),
    );
  }
}

// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:otobix/Controllers/Home%20Tab/user_preferences_controller.dart';
// import 'package:otobix/Utils/app_colors.dart';
// import 'package:otobix/Widgets/button_widget.dart';

// class UserPreferencesPage extends StatelessWidget {
//   UserPreferencesPage({super.key});

//   final UserPreferencesController getxController = Get.put(
//     UserPreferencesController(),
//   );

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text(
//           'User Preferences',
//           style: TextStyle(color: Colors.black, fontSize: 15),
//         ),
//         backgroundColor: AppColors.white,
//         centerTitle: true,
//         elevation: 0.5,
//       ),
//       body: ListView(
//         padding: const EdgeInsets.all(16),
//         children: [
//           _buildSectionTitle('Preferred Car Types'),
//           _buildChips(
//             options: getxController.carTypes,
//             selectedList: getxController.selectedCarTypes,
//           ),

//           const SizedBox(height: 20),
//           _buildSectionTitle('Preferred Fuel Types'),
//           _buildChips(
//             options: getxController.fuelTypes,
//             selectedList: getxController.selectedFuelTypes,
//           ),

//           const SizedBox(height: 20),
//           _buildSectionTitle('Bid Price Range'),
//           _buildPriceSlider(),

//           const SizedBox(height: 20),
//           _buildTransmissionType(),

//           const SizedBox(height: 20),
//           _buildBodyType(),

//           const SizedBox(height: 20),
//           _buildBrandSelector(),

//           const SizedBox(height: 20),
//           _buildCarCondition(),

//           const SizedBox(height: 20),
//           _buildColorPreferences(),

//           const SizedBox(height: 20),
//           _buildLocationSelector(),

//           const SizedBox(height: 20),
//           _buildVerifiedSellerCheckbox(),

//           const SizedBox(height: 30),
//           Row(
//             children: [
//               Expanded(
//                 child: ButtonWidget(
//                   text: 'Save Preferences',
//                   isLoading: false.obs,
//                   onTap: () {
//                     showDialog(
//                       context: context,
//                       builder:
//                           (_) => AlertDialog(
//                             title: const Text('Preferences Saved'),
//                             content: const Text(
//                               'Your car filters have been updated.',
//                             ),
//                             actions: [
//                               TextButton(
//                                 onPressed: () => Navigator.pop(context),
//                                 child: const Text('OK'),
//                               ),
//                             ],
//                           ),
//                     );
//                   },
//                   height: 40,
//                   fontSize: 12,
//                   elevation: 5,
//                   backgroundColor: AppColors.green,
//                   textColor: AppColors.white,
//                   loaderSize: 15,
//                   loaderStrokeWidth: 1,
//                   loaderColor: AppColors.white,
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildSectionTitle(String title) {
//     return Text(
//       title,
//       style: const TextStyle(
//         fontSize: 12,
//         fontWeight: FontWeight.bold,
//         color: CupertinoColors.inactiveGray,
//       ),
//     );
//   }

//   Widget _buildChips({
//     required List<String> options,
//     required RxList<String> selectedList,
//   }) {
//     return Wrap(
//       spacing: 10,
//       runSpacing: 5,
//       children:
//           options.map((option) {
//             return Obx(() {
//               final isSelected = selectedList.contains(option);
//               return ChoiceChip(
//                 label: Text(option),
//                 selected: isSelected,
//                 onSelected: (selected) {
//                   if (selected) {
//                     getxController.addToSelectedList(
//                       selectedList: selectedList,
//                       selectedValue: option,
//                     );
//                   } else {
//                     getxController.removeFromSelectedList(
//                       selectedList: selectedList,
//                       selectedValue: option,
//                     );
//                   }
//                 },
//                 selectedColor: AppColors.green.withValues(alpha: .1),
//                 // backgroundColor: AppColors.gray.withValues(alpha: .1),
//                 checkmarkColor: AppColors.green,
//                 showCheckmark: true,
//                 labelPadding: const EdgeInsets.symmetric(
//                   horizontal: 5,
//                   vertical: 0,
//                 ),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(30),
//                 ),
//                 labelStyle: TextStyle(
//                   color: isSelected ? AppColors.green : AppColors.black,
//                   fontSize: 12,
//                 ),
//               );
//             });
//           }).toList(),
//     );
//   }

//   Widget _buildPriceSlider() {
//     return Obx(() {
//       final range = getxController.selectedPriceRange.value;

//       return Container(
//         padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),

//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Range Slider
//             RangeSlider(
//               values: range,
//               min: getxController.minPrice,
//               max: getxController.maxPrice,
//               divisions: 50,
//               labels: RangeLabels(
//                 '${range.start.toStringAsFixed(0)} Lacs',
//                 '${range.end.toStringAsFixed(0)} Lacs',
//               ),
//               onChanged: (values) {
//                 getxController.selectedPriceRange.value = values;
//                 getxController.minPriceController.value.text =
//                     values.start.toInt().toString();
//                 getxController.maxPriceController.value.text =
//                     values.end.toInt().toString();
//               },
//               activeColor: AppColors.green,
//               inactiveColor: AppColors.grey.withValues(alpha: .3),
//             ),

//             const SizedBox(height: 5),

//             // Price Display + Inputs
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 // Range Display
//                 Text(
//                   'Rs. ${range.start.toStringAsFixed(0)}L - Rs. ${range.end.toStringAsFixed(0)}L',
//                   style: const TextStyle(
//                     fontSize: 12,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),

//                 // Min & Max Fields
//                 SizedBox(
//                   width: 200,
//                   height: 40,
//                   child: Row(
//                     children: [
//                       // Min Price
//                       Expanded(
//                         child: TextField(
//                           controller: getxController.minPriceController.value,
//                           keyboardType: TextInputType.number,
//                           decoration: InputDecoration(
//                             labelText: 'Min (Lacs)',
//                             labelStyle: const TextStyle(
//                               fontSize: 10,
//                               color: AppColors.grey,
//                             ),
//                             isDense: true,
//                             contentPadding: const EdgeInsets.symmetric(
//                               horizontal: 10,
//                               vertical: 10,
//                             ),
//                             border: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(5),
//                             ),
//                           ),
//                           onChanged: (value) {
//                             final min = double.tryParse(value);
//                             final max =
//                                 getxController.selectedPriceRange.value.end;

//                             if (min != null) {
//                               final clampedMin = min.clamp(
//                                 getxController.minPrice,
//                                 getxController.maxPrice,
//                               );
//                               if (clampedMin <= max) {
//                                 getxController
//                                     .selectedPriceRange
//                                     .value = RangeValues(clampedMin, max);
//                               }
//                             }
//                           },
//                         ),
//                       ),
//                       const SizedBox(width: 10),

//                       // Max Price
//                       Expanded(
//                         child: TextField(
//                           controller: getxController.maxPriceController.value,
//                           keyboardType: TextInputType.number,
//                           decoration: InputDecoration(
//                             labelText: 'Max (Lacs)',
//                             labelStyle: const TextStyle(
//                               fontSize: 10,
//                               color: AppColors.grey,
//                             ),
//                             isDense: true,
//                             contentPadding: const EdgeInsets.symmetric(
//                               horizontal: 10,
//                               vertical: 10,
//                             ),
//                             border: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(5),
//                             ),
//                           ),
//                           onChanged: (value) {
//                             final max = double.tryParse(value);
//                             final min =
//                                 getxController.selectedPriceRange.value.start;

//                             if (max != null) {
//                               final clampedMax = max.clamp(
//                                 getxController.minPrice,
//                                 getxController.maxPrice,
//                               );
//                               if (clampedMax >= min) {
//                                 getxController
//                                     .selectedPriceRange
//                                     .value = RangeValues(min, clampedMax);
//                               }
//                             }
//                           },
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       );
//     });
//   }

//   Widget _buildTransmissionType() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         _buildSectionTitle('Transmission Type'),
//         _buildChips(
//           options: getxController.transmissionTypes,
//           selectedList: getxController.selectedTransmissionTypes,
//         ),
//       ],
//     );
//   }

//   Widget _buildBodyType() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         _buildSectionTitle('Body Type'),
//         _buildChips(
//           options: getxController.bodyTypes,
//           selectedList: getxController.selectedBodyTypes,
//         ),
//       ],
//     );
//   }

//   Widget _buildBrandSelector() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         _buildSectionTitle('Preferred Brands'),
//         SizedBox(
//           height: 80,
//           child: ListView.separated(
//             scrollDirection: Axis.horizontal,
//             itemCount: getxController.brandList.length,
//             separatorBuilder: (_, __) => const SizedBox(width: 12),
//             itemBuilder: (_, index) {
//               final brand = getxController.brandList[index];
//               final isSelected = getxController.selectedBrands.contains(brand);
//               return GestureDetector(
//                 onTap: () {
//                   if (isSelected) {
//                     getxController.selectedBrands.remove(brand);
//                   } else {
//                     getxController.selectedBrands.add(brand);
//                   }
//                 },
//                 child: Column(
//                   children: [
//                     CircleAvatar(
//                       backgroundColor:
//                           isSelected ? AppColors.green : Colors.grey.shade200,
//                       child: Text(
//                         brand[0], // replace with brand image
//                         style: const TextStyle(color: Colors.black),
//                       ),
//                     ),
//                     const SizedBox(height: 4),
//                     Text(brand, style: const TextStyle(fontSize: 10)),
//                   ],
//                 ),
//               );
//             },
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildCarCondition() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         _buildSectionTitle('Car Condition'),
//         _buildChips(
//           options: getxController.carConditions,
//           selectedList: getxController.selectedCarConditions,
//         ),
//       ],
//     );
//   }

//   Widget _buildColorPreferences() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         _buildSectionTitle('Color Preferences'),
//         Obx(
//           () => Wrap(
//             spacing: 10,
//             runSpacing: 6,
//             children:
//                 getxController.carColors.map((color) {
//                   final isSelected = getxController.selectedColors.contains(
//                     color,
//                   );
//                   return ChoiceChip(
//                     label: Row(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         CircleAvatar(radius: 4, backgroundColor: color['dot']),
//                         const SizedBox(width: 4),
//                         Text(color['name']),
//                       ],
//                     ),
//                     selected: isSelected,
//                     onSelected: (_) {
//                       isSelected
//                           ? getxController.selectedColors.remove(color)
//                           : getxController.selectedColors.add(color);
//                     },
//                   );
//                 }).toList(),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildLocationSelector() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         _buildSectionTitle('Location Preference'),
//         _buildChips(
//           options: getxController.cityList,
//           selectedList: getxController.selectedCities,
//         ),
//       ],
//     );
//   }

//   Widget _buildVerifiedSellerCheckbox() {
//     return Obx(
//       () => CheckboxListTile(
//         title: const Text('Show only trusted sellers'),
//         value: getxController.showVerifiedOnly.value,
//         onChanged:
//             (val) => getxController.showVerifiedOnly.value = val ?? false,
//       ),
//     );
//   }
// }
