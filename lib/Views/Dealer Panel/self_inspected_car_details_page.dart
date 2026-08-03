// self_inspected_car_details_page.dart
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:otobix/Controllers/self_inspected_car_details_controller.dart';
import 'package:otobix/Controllers/self_inspected_cars_list_controller.dart';
import 'package:otobix/Models/self_inspected_cars_model.dart';
import 'package:otobix/Utils/app_colors.dart';
import 'package:otobix/Utils/global_functions.dart';
import 'package:otobix/Views/Dealer%20Panel/show_image_page.dart';
import 'package:otobix/Widgets/app_bar_widget.dart';
import 'package:otobix/Widgets/button_widget.dart';
import 'package:otobix/helpers/bid_color_change_helper.dart';
import 'package:otobix/helpers/self_inspected_car_margin_helpers.dart';

class SelfInspectedCarDetailsPage extends StatelessWidget {
  final SelfInspectedCarModel car;

  const SelfInspectedCarDetailsPage({super.key, required this.car});

  @override
  Widget build(BuildContext context) {
    final carDetailsController = Get.put(
      SelfInspectedCarDetailsController(carId: car.id!, initialCar: car),
    );

    return Scaffold(
      appBar: AppBarWidget(title: 'Car Details'),
      body: Obx(() {
        if (carDetailsController.isPageLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final carData = carDetailsController.carData.value;

        if (carData == null) {
          return const Center(child: Text('No data available'));
        }

        return RefreshIndicator(
          onRefresh: () => carDetailsController.refreshData(),
          child: Stack(
            children: [
              SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Card with Registration Number
                    _buildHeaderCard(carData),
                    const SizedBox(height: 8),

                    // Highest Offer and Expected Price
                    _buildHighestOfferAndExpectedPriceCard(carData),
                    const SizedBox(height: 16),

                    // Vehicle Images Section
                    _buildImageSection(carData),
                    const SizedBox(height: 16),

                    // Status Cards
                    _buildStatusCards(carData),
                    const SizedBox(height: 16),

                    // RC Details Section
                    _buildRCDetailsSection(carData),
                    const SizedBox(height: 16),

                    // Vehicle Condition Section
                    _buildConditionSection(carData),
                    const SizedBox(height: 16),

                    // Additional Details
                    _buildAdditionalDetails(carData),
                    const SizedBox(height: 80),
                  ],
                ),
              ),

              // Make Offer Bottom Button
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: SafeArea(top: false, child: _buildMakeOfferButton(car)),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildHeaderCard(SelfInspectedCarModel car) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.blue.withValues(alpha: 0.6),
              AppColors.blue.withValues(alpha: 0.9),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    car.frontMainImage,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.car_repair,
                        color: Colors.white,
                        size: 60,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        car.inspectionId,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (car.make.isNotEmpty && car.model.isNotEmpty)
                        Text(
                          '${car.make} ${car.model} ${car.variant}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (car.manufacturingDate != null)
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    color: Colors.white70,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Manufacturing Year: ${car.manufacturingDate?.year}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHighestOfferAndExpectedPriceCard(SelfInspectedCarModel car) {
    final carDetailsController = Get.find<SelfInspectedCarDetailsController>();
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      shadowColor: AppColors.black.withValues(alpha: 0.2),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.grey.withValues(alpha: 0.3),
              AppColors.grey.withValues(alpha: 0.1),
              Colors.white.withValues(alpha: 0.9),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(19),
          border: Border.all(
            color: AppColors.green.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Obx(() {
          final selfInspectedCarsListController =
              Get.find<SelfInspectedCarsListController>();

          final expectedPriceAfterMarginAdjustment =
              SelfInspectedCarMarginHelpers.getMarginAdjustedAmount(
                originalPrice: car.expectedPrice.value,
                priceDiscovery: car.priceDiscovery,
                fixedMargin: car.fixedMargin.value,
                variableMargin: car.variableMargin.value,
                shouldIncreaseMargin: true,
              );

          // Resolve color:
          RxBool hasUserMadeOfferOnCar = selfInspectedCarsListController
              .hasUserMadeOfferOnCar(car.id ?? '');
          final highestOfferColor = BidColorChangeHelper.getHighestBidColor(
            currentUserId: selfInspectedCarsListController.currentUserId,
            highestBidderUserId: car.highestOfferBy.value,
            hasUserBid: hasUserMadeOfferOnCar.value,
            neutralColor: AppColors.black,
            winningColor: AppColors.green,
            losingColor: AppColors.red,
          );

          final Color expectedPriceColor =
              car.highestOffer.value >= expectedPriceAfterMarginAdjustment
                  ? AppColors.green
                  : AppColors.red;

          return Column(
            children: [
              // Highest Offer Row - Enhanced
              Container(
                padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
                decoration: BoxDecoration(
                  color: highestOfferColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: highestOfferColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.trending_up,
                        color: Colors.white,
                        size: 15,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Highest Offer',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.black,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            '₹ ${NumberFormat.decimalPattern('en_IN').format(car.highestOffer.value)}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: highestOfferColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Expected Price Row - Enhanced
              Container(
                padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
                decoration: BoxDecoration(
                  color: expectedPriceColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: expectedPriceColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.attach_money,
                        color: Colors.white,
                        size: 15,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Expected Price',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.black,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            '₹ ${NumberFormat.decimalPattern('en_IN').format(expectedPriceAfterMarginAdjustment)}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: expectedPriceColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildHighestOfferAndExpectedPriceCard1(SelfInspectedCarModel car) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.grey.withValues(alpha: 0.6),
              AppColors.grey.withValues(alpha: 0.3),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Obx(() {
          final selfInspectedCarsListController =
              Get.find<SelfInspectedCarsListController>();

          final expectedPriceAfterMarginAdjustment =
              SelfInspectedCarMarginHelpers.getMarginAdjustedAmount(
                originalPrice: car.expectedPrice.value,
                priceDiscovery: car.priceDiscovery,
                fixedMargin: car.fixedMargin.value,
                variableMargin: car.variableMargin.value,
                shouldIncreaseMargin: true,
              );

          // Resolve color:
          RxBool hasUserMadeOfferOnCar = selfInspectedCarsListController
              .hasUserMadeOfferOnCar(car.id ?? '');
          final highestOfferColor = BidColorChangeHelper.getHighestBidColor(
            currentUserId: selfInspectedCarsListController.currentUserId,
            highestBidderUserId: car.highestOfferBy.value,
            hasUserBid: hasUserMadeOfferOnCar.value,
            neutralColor: AppColors.black,
            winningColor: AppColors.green,
            losingColor: AppColors.red,
          );

          final Color expectedPriceColor =
              car.highestOffer.value >= expectedPriceAfterMarginAdjustment
                  ? AppColors.green
                  : AppColors.red;

          return Column(
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.trending_up,
                    color: AppColors.black,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Highest Offer: ',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.black,
                          ),
                        ),
                        Text(
                          '${NumberFormat.decimalPattern('en_IN').format(car.highestOffer.value)}/-',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: highestOfferColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  const Icon(
                    Icons.attach_money,
                    color: AppColors.black,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Expected Price: ',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.black,
                          ),
                        ),
                        Text(
                          '${NumberFormat.decimalPattern('en_IN').format(expectedPriceAfterMarginAdjustment)}/-',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: expectedPriceColor,
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
      ),
    );
  }

  Widget _buildStatusCards(SelfInspectedCarModel car) {
    final controller = Get.find<SelfInspectedCarDetailsController>();

    return Row(
      children: [
        Expanded(
          child: _buildStatusCard(
            'RC Status',
            car.rcStatus,
            controller.getStatusColor(car.rcStatus),
            Icons.assignment,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatusCard(
            'Insurance',
            car.insuranceValidity != null
                ? 'Valid till ${controller.formatDate(car.insuranceValidity)}'
                : 'N/A',
            car.insuranceValidity != null &&
                    car.insuranceValidity!.isAfter(DateTime.now())
                ? Colors.green
                : Colors.red,
            Icons.security,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCard(
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection(SelfInspectedCarModel car) {
    final List<Map<String, String>> images =
        [
          {'url': car.frontMainImage, 'title': 'Front View'},
          {'url': car.rearMainImage, 'title': 'Rear View'},
          {'url': car.rhsFullImage, 'title': 'Right Side'},
          {'url': car.lhsMainImage, 'title': 'Left Side'},
          {'url': car.engineBayImage, 'title': 'Engine Bay'},
          {'url': car.dashboardImage, 'title': 'Dashboard'},
          {'url': car.bootFloorImage, 'title': 'Boot Floor'},
        ].where((img) => img['url']!.isNotEmpty).toList();

    if (images.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Vehicle Images',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: images.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  Get.to(
                    () => ShowImagePage(
                      imageLabels: images.map((img) => img['title']!).toList(),
                      imageUrls: images.map((img) => img['url']!).toList(),
                      initialIndex: index,
                    ),
                  );
                },
                child: Container(
                  width: 280,
                  margin: const EdgeInsets.only(right: 12),
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: CachedNetworkImage(
                            imageUrl: images[index]['url']!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            placeholder:
                                (context, url) => Container(
                                  color: Colors.grey[200],
                                  child: const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                            errorWidget:
                                (context, url, error) => Container(
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.error_outline),
                                ),
                          ),
                        ),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(8),
                          color: Colors.grey[100],
                          child: Text(
                            images[index]['title']!,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRCDetailsSection(SelfInspectedCarModel car) {
    final controller = Get.find<SelfInspectedCarDetailsController>();

    String maskLastFive(String input) {
      if (input.length <= 5) {
        return '*' * input.length;
      }
      return '${input.substring(0, input.length - 5)}*****';
    }

    String mask(String input) {
      StringBuffer result = StringBuffer();
      for (int i = 0; i < input.length; i++) {
        // Even index visible, odd index masked
        if (i % 2 == 0) {
          result.write(input[i]);
        } else {
          result.write('*');
        }
      }
      return result.toString();
    }

    final List<Map<String, dynamic>> details =
        [
              {
                'icon': Icons.person,
                'label': 'Owner',
                'value': mask(car.registeredOwner),
              },
              {
                'icon': Icons.numbers,
                'label': 'Registration Number',
                'value': maskLastFive(car.registrationNumber),
              },
              {
                'icon': Icons.location_on,
                'label': 'Registration State',
                'value': car.registrationState,
              },
              {
                'icon': Icons.business,
                'label': 'Registered RTO',
                'value': car.registeredRTO,
              },
              {
                'icon': Icons.settings,
                'label': 'Engine Number',
                'value': mask(car.engineNumber),
              },
              {
                'icon': Icons.vpn_key,
                'label': 'Chassis Number',
                'value': mask(car.chassisNumber),
              },
              {
                'icon': Icons.local_gas_station,
                'label': 'Fuel Type',
                'value': car.fuelType,
              },
              {
                'icon': Icons.speed,
                'label': 'Cubic Capacity',
                'value': car.cubicCapacity > 0 ? '${car.cubicCapacity} cc' : 0,
              },
              {
                'icon': Icons.calendar_today,
                'label': 'Registration Date',
                'value':
                    GlobalFunctions.getFormattedDate(
                      date: car.registrationDate,
                      type: GlobalFunctions.monthYear,
                    ) ??
                    'N/A',
              },
              {
                'icon': Icons.assignment_turned_in,
                'label': 'Fitness Validity',
                'value':
                    GlobalFunctions.getFormattedDate(
                      date: car.fitnessValidity,
                      type: GlobalFunctions.monthYear,
                    ) ??
                    'N/A',
              },
              {
                'icon': Icons.security,
                'label': 'Insurance Validity',
                'value': controller.formatDate(car.insuranceValidity),
              },
              {
                'icon': Icons.eco,
                'label': 'PUC Validity',
                'value': controller.formatDate(car.pucValidityDate),
              },
              {
                'icon': Icons.numbers,
                'label': 'PUC Number',
                'value': mask(car.pucNumber),
              },
              {
                'icon': Icons.attach_money,
                'label': 'Road Tax Validity',
                'value': controller.formatDate(car.taxValidTill),
              },
              {
                'icon': Icons.business_center,
                'label': 'Hypothecation',
                'value': car.hypothecationDetails,
              },
              {
                'icon': Icons.account_balance,
                'label': 'Financier',
                'value': car.financierName,
              },
              {
                'icon': Icons.warning,
                'label': 'Blacklist Status',
                'value': car.blacklistStatus,
              },
            ]
            .where(
              (detail) =>
                  detail['value'] != null &&
                  detail['value'].toString().isNotEmpty,
            )
            .toList();

    if (details.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'RC Details',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: details.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final detail = details[index];
              return ListTile(
                leading: Icon(detail['icon'], color: Colors.blue.shade700),
                title: Text(
                  detail['label'],
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                trailing: Text(
                  detail['value'].toString(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildConditionSection(SelfInspectedCarModel car) {
    final List<Map<String, String>> conditions =
        [
          {'label': 'Accidental Status', 'value': car.accidentalStatus},
          {'label': 'Clutch', 'value': car.clutch},
          {'label': 'Suspension', 'value': car.suspension},
          {'label': 'Steering', 'value': car.steering},
          {'label': 'Brake', 'value': car.brake},
          {'label': 'AC', 'value': car.ac},
        ].where((cond) => cond['value']!.isNotEmpty).toList();

    if (conditions.isEmpty && car.odometer <= 0) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Vehicle Condition',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              if (car.odometer > 0)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.speed, color: Colors.blue.shade700),
                          const SizedBox(width: 12),
                          const Text('Odometer Reading'),
                        ],
                      ),
                      Text(
                        '${car.odometer} km',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ...conditions.map((condition) {
                Color getConditionColor(String value) {
                  switch (value.toLowerCase()) {
                    case 'okay':
                    case 'effective':
                    case 'non-accidental':
                    case 'working':
                      return Colors.green;
                    case 'hard':
                    case 'noisy':
                    case 'spongy':
                      return Colors.orange;
                    case 'accidental':
                    case 'burnt':
                    case 'weak':
                    case 'non-effective':
                    case 'non-working':
                      return Colors.red;
                    default:
                      return Colors.grey;
                  }
                }

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(condition['label']!),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: getConditionColor(
                            condition['value']!,
                          ).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          condition['value']!,
                          style: TextStyle(
                            color: getConditionColor(condition['value']!),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAdditionalDetails(SelfInspectedCarModel car) {
    final controller = Get.find<SelfInspectedCarDetailsController>();

    if (car.expectedPrice.value > 0 &&
        car.expectedDateOfCarHandover == null &&
        car.additionalNotes.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Additional Information',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              if (car.expectedDateOfCarHandover != null)
                ListTile(
                  leading: const Icon(Icons.event, color: Colors.blue),
                  title: const Text(
                    'Expected Handover Date',
                    style: TextStyle(fontSize: 13),
                  ),
                  trailing: Text(
                    controller.formatDate(car.expectedDateOfCarHandover),
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              if (car.additionalNotes.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Additional Notes',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        car.additionalNotes,
                        style: const TextStyle(height: 1.5),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // Make Offer Bottom Button
  Widget _buildMakeOfferButton(SelfInspectedCarModel car) {
    RxBool isSheetOpen = false.obs;

    return Obx(() {
      final selfInspectedCarsListController =
          Get.find<SelfInspectedCarsListController>();

      final selfInspectedCarDetailsController =
          Get.find<SelfInspectedCarDetailsController>();

      return ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color:
                  isSheetOpen.value
                      ? AppColors.white
                      : AppColors.white.withValues(alpha: 0.5),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              border: Border(
                top: BorderSide(color: AppColors.green.withValues(alpha: 0.5)),
                left: BorderSide(color: AppColors.green.withValues(alpha: 0.5)),
                right: BorderSide(
                  color: AppColors.green.withValues(alpha: 0.5),
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withValues(alpha: 0.2),
                  blurRadius: 10,
                  spreadRadius: 5,
                  offset: const Offset(5, 0),
                ),
              ],
            ),
            child:
                !isSheetOpen.value
                    ? Center(
                      child: InkWell(
                        onTap: () {
                          isSheetOpen.value = !isSheetOpen.value;
                        },
                        borderRadius: BorderRadius.circular(50),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 5,
                          ),
                          child: Text(
                            "Tap to Make Offer",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.green,
                            ),
                          ),
                        ),
                      ),
                    )
                    : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () {
                            isSheetOpen.value = !isSheetOpen.value;
                          },
                          icon: Icon(
                            Icons.keyboard_arrow_down,
                            size: 25,
                            color: AppColors.green,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Place Your Offer",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.black,
                              ),
                            ),
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  color: AppColors.red,
                                  size: 15,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  selfInspectedCarsListController
                                      .getRemainingTime(
                                        car.auctionEndTime ?? DateTime.now(),
                                      ),
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: AppColors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: 20),
                        // Offer Box
                        Container(
                          padding: EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 20,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.grey),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Starting Offer
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Highest Offer",
                                    style: TextStyle(
                                      color: AppColors.grey,
                                      fontSize: 10,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    "Rs. ${NumberFormat.decimalPattern('en_IN').format(car.highestOffer.value)}",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                      color: AppColors.black,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                width: 1,
                                height: 30,
                                color: AppColors.grey,
                              ),
                              // Last Bid
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    "Your Offer",
                                    style: TextStyle(
                                      color: AppColors.grey,
                                      fontSize: 10,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Obx(
                                    () => Text(
                                      "Rs. ${NumberFormat.decimalPattern('en_IN').format(selfInspectedCarDetailsController.yourOfferAmount.value)}",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                        color: AppColors.black,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 30),
                        // Offer Controller
                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Minus
                              GestureDetector(
                                onTap: () {
                                  double decrementStep =
                                      selfInspectedCarDetailsController
                                          .getIncrementDecrementStep(
                                            car.priceDiscovery.toDouble(),
                                          );
                                  selfInspectedCarDetailsController
                                      .decreaseOffer(
                                        decrementStep: decrementStep,
                                        highestOffer:
                                            car.highestOffer.value.toDouble(),
                                      );
                                },
                                child: Container(
                                  padding: EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: AppColors.red),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.remove,
                                    color: AppColors.red,
                                    size: 20,
                                  ),
                                ),
                              ),
                              SizedBox(width: 20),
                              // Bid Value
                              Obx(
                                () => Column(
                                  children: [
                                    Text(
                                      "Rs. ${NumberFormat.decimalPattern('en_IN').format(selfInspectedCarDetailsController.yourOfferAmount.value)}",
                                      style: TextStyle(
                                        color: AppColors.blue,
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      "Offer increased by ${NumberFormat.decimalPattern('en_IN').format(selfInspectedCarDetailsController.yourOfferAmount.value - car.highestOffer.value)}",
                                      style: TextStyle(
                                        color: AppColors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 20),
                              // Plus
                              GestureDetector(
                                onTap: () {
                                  double incrementStep =
                                      selfInspectedCarDetailsController
                                          .getIncrementDecrementStep(
                                            car.priceDiscovery.toDouble(),
                                          );
                                  selfInspectedCarDetailsController
                                      .increaseOffer(incrementStep);
                                },
                                child: Container(
                                  padding: EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: AppColors.green),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.add,
                                    color: AppColors.green,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 30),
                        // Bid Button
                        Row(
                          children: [
                            Expanded(
                              child: ButtonWidget(
                                text: "Make Subjective Offer",
                                isLoading:
                                    selfInspectedCarDetailsController
                                        .isMakeOfferLoading,
                                onTap: () async {
                                  final ok =
                                      await selfInspectedCarDetailsController
                                          .makeOfferOnSelfInspectedCar(
                                            carId: car.id ?? '',
                                          );
                                  if (ok) {
                                    isSheetOpen.value = !isSheetOpen.value;
                                    selfInspectedCarDetailsController
                                            .yourOfferAmount
                                            .value =
                                        selfInspectedCarDetailsController
                                            .yourOfferAmount
                                            .value +
                                        selfInspectedCarDetailsController
                                            .getIncrementDecrementStep(
                                              car.priceDiscovery.toDouble(),
                                            );
                                  }
                                },
                                height: 35,
                                fontSize: 12,
                                elevation: 10,
                                backgroundColor: AppColors.green,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
          ),
        ),
      );
    });
  }
}
