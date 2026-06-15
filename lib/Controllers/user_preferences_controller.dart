import 'package:flutter/material.dart';
import 'package:get/get.dart';

class UserPreferencesController extends GetxController {
  // Preferences
  RxList<String> selectedCarTypes = <String>[].obs;
  RxList<String> selectedFuelTypes = <String>[].obs;

  Rx<RangeValues> selectedPriceRange = RangeValues(10, 50).obs;
  Rx<TextEditingController> minPriceController = TextEditingController().obs;
  Rx<TextEditingController> maxPriceController = TextEditingController().obs;

  double minPrice = 5;
  double maxPrice = 100;

  final carTypes = ['SUV', 'Sedan', 'Hatchback', 'Coupe', 'Convertible'];
  final fuelTypes = ['Petrol', 'Diesel', 'Electric', 'Hybrid'];

  void addToSelectedList({
    required RxList<String> selectedList,
    required String selectedValue,
  }) {
    if (!selectedList.contains(selectedValue)) {
      selectedList.add(selectedValue);
    }
  }

  void removeFromSelectedList({
    required RxList<String> selectedList,
    required String selectedValue,
  }) {
    if (selectedList.contains(selectedValue)) {
      selectedList.remove(selectedValue);
    }
  }

  // 1. Transmission Types
  final List<String> transmissionTypes = [
    'Manual',
    'Automatic',
    'CVT',
    'Tiptronic',
  ];
  final RxList<String> selectedTransmissionTypes = <String>[].obs;

  // 2. Body Types
  final List<String> bodyTypes = [
    'Sedan',
    'SUV',
    'Hatchback',
    'Coupe',
    'Crossover',
    'Convertible',
    'Pickup',
    'Van',
  ];
  final RxList<String> selectedBodyTypes = <String>[].obs;

  // 3. Brands
  final List<String> brandList = [
    'Toyota',
    'Honda',
    'Suzuki',
    'Kia',
    'Hyundai',
    'Nissan',
    'BMW',
    'Audi',
    'Mercedes',
  ];
  final RxList<String> selectedBrands = <String>[].obs;

  // 4. Car Condition
  final List<String> carConditions = [
    'Brand New',
    'Used',
    'Slightly Used',
    'Unregistered',
    'Auction Grade (e.g., Grade 4+, 3.5)',
  ];
  final RxList<String> selectedCarConditions = <String>[].obs;

  // 5. Model Year Range
  final Rx<RangeValues> selectedYearRange = const RangeValues(2010, 2024).obs;

  // 6. Car Colors with Color Dots
  final List<Map<String, dynamic>> carColors = [
    {'name': 'Black', 'dot': Colors.black},
    {'name': 'White', 'dot': Colors.white},
    {'name': 'Red', 'dot': Colors.red},
    {'name': 'Blue', 'dot': Colors.blue},
    {'name': 'Silver', 'dot': Colors.grey},
    {'name': 'Green', 'dot': Colors.green},
    {'name': 'Yellow', 'dot': Colors.yellow},
    {'name': 'Orange', 'dot': Colors.orange},
  ];
  final RxList<Map<String, dynamic>> selectedColors =
      <Map<String, dynamic>>[].obs;

  // 7. Location / City Preferences
 final List<String> cityList = [
  'Mumbai',
  'Delhi',
  'Bangalore',
  'Hyderabad',
  'Chennai',
  'Kolkata',
  'Pune',
  'Ahmedabad',
];

  final RxList<String> selectedCities = <String>[].obs;

  // 8. Verified Sellers Only
  final RxBool showVerifiedOnly = false.obs;
}
