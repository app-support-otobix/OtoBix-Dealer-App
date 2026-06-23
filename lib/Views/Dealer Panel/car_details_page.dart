import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:otobix/Controllers/home_controller.dart';
import 'package:otobix/Controllers/live_bids_controller.dart';
import 'package:otobix/Models/car_model.dart';
import 'package:otobix/Utils/app_constants.dart';
import 'package:otobix/Utils/global_functions.dart';
import 'package:otobix/Views/Dealer%20Panel/car_images_gallery_page.dart';
import 'package:otobix/Views/Dealer%20Panel/place_bid_button_widget.dart';
import 'package:otobix/Views/Dealer%20Panel/start_auto_bid_button_widget.dart';
import 'package:otobix/Views/Dealer%20Panel/car_images_page.dart';
import 'package:otobix/Views/Dealer%20Panel/video_player_page.dart';
import 'package:otobix/Widgets/accordion_widget.dart';
import 'package:otobix/Widgets/button_widget.dart';
import 'package:otobix/Widgets/congratulations_dialog_widget.dart';
import 'package:otobix/Widgets/shimmer_widget.dart';
import 'package:otobix/helpers/bid_color_change_helper.dart';
import 'package:otobix/helpers/car_margin_helpers.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:otobix/Models/cars_list_model.dart';
import 'package:otobix/Utils/app_colors.dart';
import 'package:otobix/Utils/app_images.dart';
import 'package:otobix/Controllers/car_details_controller.dart';
import 'package:shimmer/shimmer.dart';

class CarDetailsPage extends StatefulWidget {
  final String carId;
  final CarsListModel car;
  final String currentOpenSection;
  final RxString remainingAuctionTime;

  const CarDetailsPage({
    super.key,
    required this.carId,
    required this.car,
    required this.currentOpenSection,
    required this.remainingAuctionTime,
  });

  @override
  State<CarDetailsPage> createState() => _CarDetailsPageState();
}

class _CarDetailsPageState extends State<CarDetailsPage> {
  // @override
  // void initState() {
  //   super.initState();

  //   final getxController = Get.put(CarDetailsController(widget.carId));
  //   getxController.fetchCarDetails(carId: widget.carId);
  //   // await fetchCarDetails(carId: '68821747968635d593293346');
  //   debugPrint(getxController.carDetails?.toJson().toString() ?? 'null');
  // }

  late final CarDetailsController getxController; // keep controller once
  late final HomeController homeController; // keep reference once

  final LiveBidsController live = Get.find<LiveBidsController>();
  List<CarsListTitleAndImage> imageUrls = [];

  @override
  void initState() {
    super.initState();
    getxController = Get.put(CarDetailsController(widget.carId));
    homeController = Get.put(HomeController());

    imageUrls =
        widget.car.imageUrls ??
        [CarsListTitleAndImage(title: 'Main Image', url: widget.car.imageUrl)];
    getxController.setImageUrls(imageUrls);
    getxController.oneClickPriceAmount.value = widget.car.oneClickPrice.value;
    _setCurrentHighestBid();

    // Close screen when timer ends
    getxController.watchAndCloseOnTimerEnd(
      carName: '${widget.car.make} ${widget.car.model} ${widget.car.variant}',
      remainingAuctionTime:
          widget.currentOpenSection == homeController.upcomingSectionScreen ||
                  widget.currentOpenSection ==
                      homeController.liveBidsSectionScreen
              ? widget.remainingAuctionTime
              : null,
      currentOpenSection: widget.currentOpenSection,
    );

    // Update one click price on variable margin change
    getxController.listenToVariableMarginChangeUpdatedOneClickPriceRealtime(
      widget.car.variableMargin,
    );
  }

  // Setting highest bid initially
  void _setCurrentHighestBid() {
    // if highestBid is RxDouble (or RxDouble?)
    final double hb =
        (widget.car.highestBid).value; // current highest bid on car
    final double ho = widget.car.otobuyOffer; // current highest offer on car
    final double pd = widget.car.priceDiscovery;

    final double currentHighestBidOrPD = (hb == 0.0) ? pd * 0.75 : hb;
    final double currentHighestOfferOrPD = (ho == 0.0) ? pd * 0.75 : ho;

    // getxController.currentHighestBidAmount.value = current;
    if (widget.currentOpenSection != homeController.otobuySectionScreen) {
      getxController.currentHighestBidAmount.value = currentHighestBidOrPD;
    } else {
      getxController.currentHighestBidAmount.value = currentHighestOfferOrPD;
    }
  }

  @override
  Widget build(BuildContext context) {
    // final getxController = Get.put(CarDetailsController(widget.carId));
    // final homeController = Get.put(HomeController());
    // final imageUrls = widget.car.imageUrls ?? [widget.car.imageUrl];

    // getxController.startCountdown(DateTime.now().add(const Duration(days: 1)));

    final pageController = PageController();

    // Set current bid amount
    // getxController.currentHighestBidAmount.value =
    //     double.tryParse(widget.car.highestBid.toString()) ?? 0.0;

    // Set one click price amount
    // getxController.oneClickPriceAmount.value =
    //     getxController.currentHighestBidAmount.value + 10000;

    // Set your offer amount
    // Get margin added one click price
    final adjustedOneClickPrice = CarMarginHelpers.netAfterMarginsFlexible(
      originalPrice: getxController.oneClickPriceAmount.value,
      priceDiscovery: widget.car.priceDiscovery,
      fixedMargin: widget.car.fixedMargin.value,
      variableMargin: widget.car.variableMargin.value,
    );
    // Later if you want to increment/decrement by PD
    final pd = widget.car.priceDiscovery;
    final incrementStep = getxController.getIncrementStep(pd);
    widget.currentOpenSection != homeController.otobuySectionScreen
        ? getxController.yourOfferAmount.value =
            getxController.currentHighestBidAmount.value + incrementStep
        : getxController.yourOfferAmount.value =
            // getxController.oneClickPriceAmount.value;
            adjustedOneClickPrice;
    // widget.currentOpenSection != homeController.otobuySectionScreen
    //     ? getxController.yourOfferAmount.value =
    //         getxController.currentHighestBidAmount.value + 4000
    //     : getxController.yourOfferAmount.value =
    //         getxController.oneClickPriceAmount.value;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Obx(() {
              final isBusy = getxController.isLoading.value;
              final carDetails = getxController.carDetails;

              if (isBusy || carDetails == null) {
                return Center(child: _buildLoading());
              }

              // from here on, use local non-null 'carDetails'
              return
              //  getxController.isLoading.value
              //     ? Center(child: _buildLoading()) :
              Stack(
                children: [
                  CustomScrollView(
                    controller: getxController.scrollController,
                    slivers: [
                      SliverToBoxAdapter(
                        child: _buildCarImagesList(
                          imageUrls: imageUrls,
                          pageController: pageController,
                          getxController: getxController,
                          carDetails: carDetails,
                          car: widget.car,
                        ),
                      ),
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: _StickyHeaderDelegate(
                          child: _buildMainDetails(
                            carDetails: carDetails,
                            getxController: getxController,
                          ),
                          height: 190,
                        ),
                      ),
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: _StickyHeaderDelegate(
                          child: _buildStickyTabs(getxController),
                          height: 40,
                        ),
                      ),
                      SliverList(
                        delegate: SliverChildListDelegate([
                          // Each section wrapped with its GlobalKey
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 15),
                            child: Column(
                              children: [
                                Container(
                                  key:
                                      getxController
                                          .sectionKeys[CarDetailsController
                                          .imagesSectionKey],
                                  child: _buildImagesSection(
                                    car: getxController.carDetails!,
                                    currentOpenSection:
                                        widget.currentOpenSection,
                                    remainingAuctionTime:
                                        widget.remainingAuctionTime,
                                  ),
                                ),
                                // Container(
                                //   key:
                                //       getxController
                                //           .sectionKeys[CarDetailsController
                                //           .basicDetailsSectionKey],
                                //   child: _buildBasicDetails(
                                //     carDetails:
                                //         getxController.carDetails!,
                                //   ),
                                // ),
                                Container(
                                  key:
                                      getxController
                                          .sectionKeys[CarDetailsController
                                          .documentDetailsSectionKey],
                                  child: _buildDocumentDetails(
                                    carDetails: getxController.carDetails!,
                                    getxController: getxController,
                                  ),
                                ),
                                Container(
                                  key:
                                      getxController
                                          .sectionKeys[CarDetailsController
                                          .exteriorSectionKey],
                                  child: _buildExterior(
                                    carDetails: getxController.carDetails!,
                                    getxController: getxController,
                                  ),
                                ),
                                Container(
                                  key:
                                      getxController
                                          .sectionKeys[CarDetailsController
                                          .engineBaySectionKey],
                                  child: _buildEngineBay(
                                    carDetails: getxController.carDetails!,
                                    getxController: getxController,
                                  ),
                                ),
                                Container(
                                  key:
                                      getxController
                                          .sectionKeys[CarDetailsController
                                          .steeringBrakesAndSuspensionSectionKey],
                                  child: _buildSteeringBrackesAndSuspension(
                                    carDetails: getxController.carDetails!,
                                  ),
                                ),

                                Container(
                                  key:
                                      getxController
                                          .sectionKeys[CarDetailsController
                                          .interiorAndElectricalsSectionKey],
                                  child: _buildInteriorAndElectricals(
                                    carDetails: getxController.carDetails!,
                                    getxController: getxController,
                                  ),
                                ),
                                Container(
                                  key:
                                      getxController
                                          .sectionKeys[CarDetailsController
                                          .airConditioningSectionKey],
                                  child: _buildAirCondition(
                                    carDetails: getxController.carDetails!,
                                    getxController: getxController,
                                  ),
                                ),
                                SizedBox(height: 110),
                              ],
                            ),
                          ),
                        ]),
                      ),
                    ],
                  ),

                  // SingleChildScrollView(
                  //   padding: const EdgeInsets.only(bottom: 120),
                  //   child: ConstrainedBox(
                  //     constraints: BoxConstraints(
                  //       minHeight: constraints.maxHeight,
                  //     ),
                  //     child: Column(
                  //       children: [
                  //         _buildCarImagesList(
                  //           imageUrls: imageUrls,
                  //           pageController: pageController,
                  //           getxController: getxController,
                  //           carDetails: getxController.carDetails!,
                  //           car: widget.car,
                  //         ),
                  //         const SizedBox(height: 10),
                  //         _buildMainDetails(
                  //           carDetails: getxController.carDetails!,
                  //         ),
                  //         const SizedBox(height: 20),

                  //         _buildCarDetails(
                  //           carDetails: getxController.carDetails!,
                  //           getxController: getxController,
                  //         ),
                  //       ],
                  //     ),
                  //   ),
                  // ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: _buildBidButton(
                      getxController,
                      homeController,
                      context,
                      widget.currentOpenSection,
                      widget.car,
                      widget.remainingAuctionTime,
                    ),
                  ),
                ],
              );
            });
          },
        ),
      ),
    );
  }

  Widget _buildCarImagesList({
    // required List<String> imageUrls,
    required List<CarsListTitleAndImage> imageUrls,
    required PageController pageController,
    required CarDetailsController getxController,
    required CarModel carDetails,
    required CarsListModel car,
  }) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        GestureDetector(
          onTap: () {
            // final List<String> imageLabels = [];

            Get.to(
              () => CarImagesPage(
                imageLabels: imageUrls.map((e) => e.title).toList(),
                imageUrls: imageUrls.map((e) => e.url).toList(),
                initialIndex: getxController.currentIndex.value,
              ),
            );
          },
          child: LayoutBuilder(
            builder: (context, constraints) {
              final screenWidth = constraints.maxWidth;
              final aspectRatio = 4 / 3; // Your image ratio (1000x750)
              final imageHeight = screenWidth / aspectRatio;
              return SizedBox(
                height: imageHeight,
                child: PhotoViewGallery.builder(
                  itemCount: imageUrls.length,
                  pageController: pageController,
                  onPageChanged: (index) => getxController.updateIndex(index),
                  builder: (context, index) {
                    return PhotoViewGalleryPageOptions(
                      imageProvider: CachedNetworkImageProvider(
                        imageUrls[index].url,
                      ),
                      minScale: PhotoViewComputedScale.contained,
                      maxScale: PhotoViewComputedScale.covered * 2,
                      heroAttributes: PhotoViewHeroAttributes(
                        tag: 'image-$index',
                        transitionOnUserGestures: true,
                      ),
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Image(
                            image: AssetImage(AppImages.carAlternateImage),
                          ),
                        );
                      },
                    );
                  },
                  loadingBuilder:
                      (context, event) => const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.green,
                          strokeWidth: 2,
                        ),
                      ),
                  scrollPhysics: const BouncingScrollPhysics(),
                  backgroundDecoration: const BoxDecoration(
                    color: AppColors.white,
                  ),
                ),
              );
            },
          ),
        ),
        Positioned(
          bottom: 12,
          right: 16,
          child: Obx(
            () => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.black.withValues(alpha: .6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${getxController.currentIndex.value + 1} / ${imageUrls.length}',
                style: const TextStyle(color: AppColors.white, fontSize: 12),
              ),
            ),
          ),
        ),
        _buildAppbar(getxController: getxController, carDetails: carDetails),
      ],
    );
  }

  Widget _buildAppbar({
    required CarDetailsController getxController,
    required CarModel carDetails,
  }) {
    return Positioned(
      top: 12,
      left: 16,
      child: GestureDetector(
        onTap: () => Get.back(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.black.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.2),
                blurRadius: 10,
                spreadRadius: 2,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(
                Icons.arrow_back_ios_new,
                color: AppColors.white,
                size: 12,
              ),
              const SizedBox(width: 10),
              Text(
                '${carDetails.make} ${carDetails.model}',
                style: const TextStyle(color: AppColors.white, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCarDetails({
    required CarModel carDetails,
    required CarDetailsController getxController,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // _buildMainDetails(carDetails: carDetails),
          // const SizedBox(height: 20),
          // _buildIconAndTextDetails(carDetails: carDetails),
          // const SizedBox(height: 20),
          // _buildBasicDetails(carDetails: carDetails),
          // const SizedBox(height: 10),
          _buildDocumentDetails(
            carDetails: carDetails,
            getxController: getxController,
          ),
          const SizedBox(height: 5),
          _buildExterior(
            carDetails: carDetails,
            getxController: getxController,
          ),
          const SizedBox(height: 5),
          _buildEngineBay(
            carDetails: carDetails,
            getxController: getxController,
          ),
          const SizedBox(height: 5),
          _buildSteeringBrackesAndSuspension(carDetails: carDetails),
          const SizedBox(height: 5),
          _buildInteriorAndElectricals(
            carDetails: carDetails,
            getxController: getxController,
          ),
          const SizedBox(height: 5),
          _buildAirCondition(
            carDetails: carDetails,
            getxController: getxController,
          ),
          const SizedBox(height: 5),
          // _buildSafetyAndAirbags(carDetails: carDetails),
          // const SizedBox(height: 15),
          // _buildExteriorImages(),
          // const SizedBox(height: 10),
          // _buildStructuralAndUnderbody(carDetails: carDetails),
          // const SizedBox(height: 5),
          // _buildDashboardAndSeating(carDetails: carDetails),
          // const SizedBox(height: 10),
          // _buildAdminAndApprovalInfo(carDetails: carDetails),
          // const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildMainDetails({
    required CarModel carDetails,
    required CarDetailsController getxController,
  }) {
    // Helper Function
    Widget iconDetail(IconData icon, String label, String value) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 15, color: AppColors.grey),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          // Divider(),
          // Text(
          //   label,
          //   style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          // ),
        ],
      );
    }

    String maskRegistrationNumber(String? input) {
      if (input == null || input.length <= 5) return '*****';
      final visible = input.substring(0, input.length - 5);
      return '$visible*****';
    }

    final items = [
      // iconDetail(Icons.factory, 'Make', 'Mahindra'),
      // iconDetail(Icons.directions_car, 'Model', 'Scorpio'),
      // iconDetail(Icons.confirmation_number, 'Variant', '[2014–2017]'),
      iconDetail(
        Icons.calendar_month,
        'Registration Date',
        GlobalFunctions.getFormattedDate(
              date: carDetails.registrationDate,
              type: GlobalFunctions.monthYear,
            ) ??
            'N/A',
      ),
      iconDetail(
        Icons.speed,
        'Odometer Reading in Kms',
        // '${NumberFormat.decimalPattern('en_IN').format(carDetails.odometerReadingInKms)} km',
        '${NumberFormat.decimalPattern('en_IN').format(getFirstValidValueFromCarModel(values: [carDetails.odometerReadingBeforeTestDrive, carDetails.odometerReadingInKms], returnType: ReturnType.number))} km',
      ),
      iconDetail(Icons.local_gas_station, 'Fuel Type', carDetails.fuelType),

      iconDetail(
        Icons.settings,
        'Transmission',
        // carDetails.commentsOnTransmission,
        getFirstValidValueFromCarModel(
          values: [
            carDetails.transmissionTypeDropdownList,
            carDetails.commentsOnTransmission,
          ],
          returnType: ReturnType.string,
        ),
      ),
      iconDetail(
        Icons.person,
        'Owner Serial Number',
        carDetails.ownerSerialNumber == 1
            ? 'First Owner'
            : '${carDetails.ownerSerialNumber} Owners',
      ),
      iconDetail(
        Icons.receipt_long,
        'Tax Validity',
        carDetails.roadTaxValidity == 'LTT' ||
                carDetails.roadTaxValidity == 'OTT'
            ? carDetails.roadTaxValidity
            : GlobalFunctions.getFormattedDate(
                  date: carDetails.taxValidTill,
                  type: GlobalFunctions.monthYear,
                ) ??
                'N/A',
      ),

      // iconDetail(
      //   Icons.science,
      //   'Cubic Capacity',
      //   carDetails.cubicCapacity != 0
      //       ? '${carDetails.cubicCapacity} cc'
      //       : 'N/A',
      // ),
      iconDetail(
        Icons.location_on,
        'Inspection Location',
        // carDetails.city
        getFirstValidValueFromCarModel(
          values: [carDetails.inspectionCity, carDetails.city],
          returnType: ReturnType.string,
        ),
      ),
      iconDetail(
        Icons.directions_car_filled,
        'Registration No.',
        maskRegistrationNumber(carDetails.registrationNumber),
      ),
      iconDetail(Icons.apartment, 'Registered RTO', carDetails.registeredRto),
    ];

    // Add margin in one click price
    final double oneClickPriceAmountAfterMarginAdjustment =
        CarMarginHelpers.netAfterMarginsFlexible(
          originalPrice: widget.car.oneClickPrice.value,
          priceDiscovery: widget.car.priceDiscovery,
          fixedMargin: widget.car.fixedMargin.value,
          variableMargin: widget.car.variableMargin.value,
        );

    final highestBidText =
        widget.currentOpenSection == homeController.liveBidsSectionScreen
            ? 'Highest Bid: '
            : widget.currentOpenSection == homeController.upcomingSectionScreen
            ? 'Current Pre-Bid: '
            : widget.currentOpenSection == homeController.otobuySectionScreen
            ? 'One Click Price: '
            : 'Highest Bid: ';

    final RxDouble highestBidValue =
        widget.currentOpenSection == homeController.liveBidsSectionScreen
            ? getxController.currentHighestBidAmount
            : widget.currentOpenSection == homeController.upcomingSectionScreen
            ? getxController.currentHighestBidAmount
            : widget.currentOpenSection == homeController.otobuySectionScreen
            // ? getxController.oneClickPriceAmount
            ? oneClickPriceAmountAfterMarginAdjustment.obs
            : getxController.currentHighestBidAmount;

    return Container(
      color: AppColors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    '${GlobalFunctions.getFormattedDate(date: getFirstValidValueFromCarModel(values: [carDetails.yearAndMonthOfManufacture, carDetails.yearMonthOfManufacture], returnType: ReturnType.datetime), type: GlobalFunctions.year)} ${carDetails.make} ${carDetails.model} ${carDetails.variant}',
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),
            Container(
              // padding: const EdgeInsets.all(12),
              // margin: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Wrap(
                  //   spacing: 10,
                  //   runSpacing: 5,
                  //   alignment: WrapAlignment.start,
                  //   children: items,
                  // ),
                  GridView.count(
                    padding: EdgeInsets.zero,
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 5, // controls vertical space
                    crossAxisSpacing: 10, // controls horizontal space
                    childAspectRatio:
                        4, // width / height ratio — adjust as needed
                    children: items,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  highestBidText,
                  style: const TextStyle(
                    fontSize: 16,
                    // color: AppColors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 5),
                Obx(() {
                  final highestBid = highestBidValue.value;
                  final baseBid = widget.car.priceDiscovery * 0.75;

                  // use tolerance for floating-point check
                  final isAnyoneHavePlacedBidYet =
                      (highestBid - baseBid).abs() > 0.01;

                  final color =
                      widget.currentOpenSection ==
                              homeController.otobuySectionScreen
                          ? AppColors.green
                          : BidColorChangeHelper.getHighestBidColor(
                            currentUserId: getxController.currentUserId,
                            highestBidderUserId:
                                getxController.latestHighestBidderId,
                            hasUserBid: getxController.userHasBid,
                            neutralColor: AppColors.black,
                            winningColor: AppColors.green,
                            losingColor: AppColors.red,
                          );

                  return Text(
                    // 'Rs. ${NumberFormat.decimalPattern('en_IN').format(isAnyoneHavePlacedBidYet ? highestBidValue.value : 0)}/-',
                    'Rs. ${NumberFormat.decimalPattern('en_IN').format(GlobalFunctions.roundToNearestThousand<int>(isAnyoneHavePlacedBidYet ? highestBidValue.value : 0))}/-',
                    key: ValueKey(
                      isAnyoneHavePlacedBidYet ? highestBidValue.value : 0,
                    ),
                    style: TextStyle(
                      fontSize: 16,
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Widget _buildIconAndTextDetails({
  //   // required CarModel car,
  //   required CarModel2 carDetails,
  // }) {
  //   // Helper Function
  //   Widget item({required IconData icon, required String text}) => Column(
  //     children: [
  //       Icon(icon, color: AppColors.grey, size: 20),
  //       Text(text, style: const TextStyle(fontSize: 10)),
  //     ],
  //   );

  //   // Actual Widget
  //   return Row(
  //     children: [
  //       Expanded(
  //         child: Wrap(
  //           alignment: WrapAlignment.spaceEvenly,
  //           spacing: 10,
  //           runSpacing: 5,
  //           children: [
  //             item(
  //               icon: Icons.speed,
  //               text:
  //                   '${NumberFormat.decimalPattern('en_IN').format(carDetails.odometerReadingInKms)} kms',
  //             ),
  //             item(icon: Icons.local_gas_station, text: carDetails.fuelType),
  //             item(icon: Icons.settings, text: carDetails.variant),
  //             // _buildIconAndTextWidget(icon: Icons.color_lens, text: carDetails.color),
  //             item(
  //               icon: Icons.event,
  //               text:
  //                   GlobalFunctions.getFormattedDate(
  //                     date: carDetails.yearMonthOfManufacture,
  //                     type: GlobalFunctions.year,
  //                   ) ??
  //                   'N/A',
  //             ),
  //           ],
  //         ),
  //       ),
  //     ],
  //   );
  // }

  Widget _buildBasicDetails({required CarModel carDetails}) {
    // Mask Registration Number
    String maskRegistrationNumber(String? input) {
      if (input == null || input.length <= 5) return '*****';
      final visible = input.substring(0, input.length - 5);
      return '$visible*****';
    }

    return Column(
      children: [
        const SizedBox(height: 10),
        Row(
          children: [
            const Icon(
              Icons.directions_car_filled_outlined,
              color: AppColors.grey,
              size: 20,
            ),
            const SizedBox(width: 5),
            Text(
              'Basic Details',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        Divider(color: AppColors.grey.withValues(alpha: 0.5)),
        const SizedBox(height: 3),
        _buildDetailRowForOtherDetails('Make', carDetails.make),
        _buildDetailRowForOtherDetails('Model', carDetails.model),
        _buildDetailRowForOtherDetails('Variant', carDetails.variant),
        _buildDetailRowForOtherDetails(
          'Registration Number',
          maskRegistrationNumber(carDetails.registrationNumber),
        ),
        _buildDetailRowForOtherDetails(
          'Registration Date',
          GlobalFunctions.getFormattedDate(
                date: carDetails.registrationDate,
                type: GlobalFunctions.date,
              ) ??
              'N/A',
        ),
        _buildDetailRowForOtherDetails(
          'Manufacture Year',
          GlobalFunctions.getFormattedDate(
                date: carDetails.yearMonthOfManufacture,
                type: GlobalFunctions.year,
              ) ??
              'N/A',
        ),
        _buildDetailRowForOtherDetails(
          'Odometer Reading',
          '${NumberFormat.decimalPattern('en_IN').format(carDetails.odometerReadingInKms)} kms',
        ),
        _buildDetailRowForOtherDetails('Fuel Type', carDetails.fuelType),
        _buildDetailRowForOtherDetails(
          'Cubic Capacity',
          '${carDetails.cubicCapacity} cc',
        ),
        _buildDetailRowForOtherDetails('City', carDetails.city),
        _buildDetailRowForOtherDetails('Status', carDetails.status),
        _buildDetailRowForOtherDetails('Budget', carDetails.budgetCar),
      ],
    );
  }

  Widget _buildDetailRowForOtherDetails(String title, String value) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 12)),
            Text(value, style: const TextStyle(fontSize: 12)),
          ],
        ),
        Divider(color: AppColors.grey.withValues(alpha: 0.1)),
      ],
    );
  }

  Widget _buildDocumentDetails({
    required CarModel carDetails,
    required CarDetailsController getxController,
  }) {
    Widget buildRow(String title, String value) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 150,
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(
              child: Text(
                value.isNotEmpty ? value : '-',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      );
    }

    return AccordionWidget(
      // title: 'RC, Insurance & Legal Details',
      title: 'Document Details',
      contentSize: 300,
      icon: Icons.article_outlined,
      content: Column(
        children: [
          buildRow('Appointment ID', carDetails.appointmentId),
          buildRow(
            'RC Book Availability',
            getFirstValidValueFromCarModel(
              values: [
                carDetails.rcBookAvailabilityDropdownList,
                carDetails.rcBookAvailability,
              ],
              returnType: ReturnType.string,
            ),
          ),
          buildRow('RC Condition', carDetails.rcCondition),
          buildRow(
            'Mismatch In RC',
            getFirstValidValueFromCarModel(
              values: [
                carDetails.mismatchInRcDropdownList,
                carDetails.mismatchInRc,
              ],
              returnType: ReturnType.string,
            ),
          ),
          buildRow(
            'Registration Date',
            GlobalFunctions.getFormattedDate(
                  date: carDetails.registrationDate,
                  type: GlobalFunctions.monthYear,
                ) ??
                'N/A',
          ),
          buildRow(
            'Fitness Till',
            GlobalFunctions.getFormattedDate(
                  date: getFirstValidValueFromCarModel(
                    values: [
                      carDetails.fitnessValidity,
                      carDetails.fitnessTill,
                    ],
                    returnType: ReturnType.datetime,
                  ),
                  type: GlobalFunctions.monthYear,
                ) ??
                'N/A',
          ),
          buildRow('To Be Scrapped', carDetails.toBeScrapped),
          buildRow('Cubic Capacity', '${carDetails.cubicCapacity} cc'),
          buildRow('Hypothecation Details', carDetails.hypothecationDetails),
          buildRow('Road Tax Validity', carDetails.roadTaxValidity),
          buildRow(
            'Tax Valid Till',
            GlobalFunctions.getFormattedDate(
                  date: carDetails.taxValidTill,
                  type: GlobalFunctions.monthYear,
                ) ??
                'N/A',
          ),
          buildRow(
            'Insurance',
            getFirstValidValueFromCarModel(
              values: [carDetails.insuranceDropdownList, carDetails.insurance],
              returnType: ReturnType.string,
            ),
          ),
          buildRow(
            'Insurance Validity',
            GlobalFunctions.getFormattedDate(
                  date: carDetails.insuranceValidity,
                  type: GlobalFunctions.monthYear,
                ) ??
                'N/A',
          ),
          buildRow('Duplicate Key', carDetails.duplicateKey),
          buildRow('RTO NOC', carDetails.rtoNoc),
          buildRow('Party Peshi', carDetails.partyPeshi),
          buildRow(
            'Additional Details',
            getFirstValidValueFromCarModel(
              values: [
                carDetails.additionalDetailsDropdownList,
                carDetails.additionalDetails,
              ],
              returnType: ReturnType.string,
            ),
          ),
          // if (getxController.isValidComment(carDetails.comments))
          //   _buildCommentsCard(
          //     title: 'Comments',
          //     comment: carDetails.comments,
          //     icon: Icons.comment,
          //   ),

          // buildRow('Registered Owner', carDetails.registeredOwner),
          // buildRow('Registered Address', carDetails.registeredAddressAsPerRc),
          // buildRow('To Be Scrapped', carDetails.toBeScrapped),
          // buildRow('Road Tax Validity', carDetails.roadTaxValidity),
          // buildRow('RTO NOC', carDetails.rtoNoc),
          // buildRow('RTO Form 28 (2 Nos)', carDetails.rtoForm28),
          // buildRow('Hypothecation Details', carDetails.hypothecationDetails),
          // buildRow('Duplicate Key', carDetails.duplicateKey),
          // buildRow('Party Peshi', carDetails.partyPeshi),
          // const Divider(height: 20),
          // buildRow('Insurance', carDetails.insurance),
          // buildRow('Insurance Copy', carDetails.insuranceCopy),
          // buildRow('Insurance Copy 1', carDetails.insuranceCopy1),
          // const Divider(height: 20),
          // buildRow('RC Tax Token', carDetails.rcTaxToken),
          // buildRow('RC Token 1', carDetails.rcToken1),
          // buildRow('RC Token 2', carDetails.rcToken2),
          // buildRow('RC Token 3', carDetails.rcToken3),
          // buildRow('RC Token 4', carDetails.rcToken4),
        ],
      ),
    );
  }

  Widget _buildEngineBay({
    required CarModel carDetails,
    required CarDetailsController getxController,
  }) {
    // Helper: builds each labeled box
    // Widget infoCard({
    //   required IconData icon,
    //   required String label,
    //   required String value,
    // }) {
    //   return Container(
    //     decoration: BoxDecoration(
    //       color: AppColors.white,
    //       borderRadius: BorderRadius.circular(5),
    //       boxShadow: [
    //         BoxShadow(
    //           color: Colors.black.withValues(alpha: 0.15),
    //           blurRadius: 10,
    //           offset: const Offset(0, 4),
    //         ),
    //       ],
    //     ),
    //     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    //     child: Column(
    //       crossAxisAlignment: CrossAxisAlignment.start,
    //       children: [
    //         Row(
    //           mainAxisAlignment: MainAxisAlignment.center,
    //           children: [
    //             // Icon badge
    //             Container(
    //               width: 28,
    //               height: 28,
    //               // margin: const EdgeInsets.only(right: 10),
    //               decoration: BoxDecoration(
    //                 color: AppColors.green.withValues(alpha: 0.15),
    //                 shape: BoxShape.circle,
    //               ),
    //               child: Icon(icon, size: 16, color: AppColors.green),
    //             ),
    //             // Label + Value
    //             // Flexible(
    //             //   child: Column(
    //             //     crossAxisAlignment: CrossAxisAlignment.start,
    //             //     mainAxisAlignment: MainAxisAlignment.end,
    //             //     children: [SizedBox(height: 7)],
    //             //   ),
    //             // ),
    //           ],
    //         ),
    //         const SizedBox(height: 10),
    //         Row(
    //           mainAxisAlignment: MainAxisAlignment.center,
    //           children: [
    //             Flexible(
    //               child: Text(
    //                 label,
    //                 textAlign: TextAlign.center,
    //                 style: const TextStyle(
    //                   fontSize: 10,
    //                   fontWeight: FontWeight.w600,
    //                   color: Colors.black87,
    //                 ),
    //               ),
    //             ),
    //           ],
    //         ),
    //         Row(
    //           mainAxisAlignment: MainAxisAlignment.center,
    //           children: [
    //             Flexible(
    //               child: Text(
    //                 value.isNotEmpty ? value : '—',
    //                 textAlign: TextAlign.center,
    //                 style: const TextStyle(fontSize: 12, color: Colors.black54),
    //               ),
    //             ),
    //           ],
    //         ),
    //       ],
    //     ),
    //   );
    // }

    Widget videoCard({required String label, required String videoUrl}) {
      return InkWell(
        onTap: () {
          Get.to(() => VideoPlayerPage(videoLabel: label, videoUrl: videoUrl));
        },
        borderRadius: BorderRadius.circular(5),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: AppColors.grey.withValues(alpha: 0.5)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: Column(
              children: [
                Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      // color: AppColors.grey.withValues(alpha: 0.2),
                      child: const Center(
                        child: Icon(
                          Icons.play_circle_outline,
                          size: 50,
                          color: AppColors.green,
                        ),
                      ),
                    ),
                    // Optionally: You can add a thumbnail here using CachedNetworkImage or future frame from video
                  ],
                ),
                Container(
                  // width: double.infinity,
                  color: AppColors.grey.withValues(alpha: 0.5),
                  padding: const EdgeInsets.symmetric(
                    vertical: 6,
                    horizontal: 10,
                  ),
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    Widget buildItem({
      required IconData icon,
      required String label,
      required Widget trailing,
      List<String> imageUrls = const [],
    }) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.black54),
            const SizedBox(width: 10),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(label, style: const TextStyle(fontSize: 13)),
                  const SizedBox(width: 10),
                  Flexible(child: trailing),
                ],
              ),
            ),
            const SizedBox(width: 10),
            if (imageUrls.isNotEmpty) _buildSideImages(imageUrls: imageUrls),
          ],
        ),
      );
    }

    Widget engineBayValue(String? value) {
      final status = value?.toLowerCase();

      if (status == 'available' || status == 'yes' || status == 'okay') {
        return Icon(Icons.check_circle, color: AppColors.green, size: 20);
      } else if (status == 'not applicable' ||
          status == 'not available' ||
          status == 'no' ||
          status == 'not okay') {
        return Icon(Icons.cancel, color: AppColors.red, size: 20);
      } else {
        return Text(value.toString(), style: const TextStyle(fontSize: 13));
      }
    }

    // Field Map: Label and matching value from carDetails
    final fields = [
      {
        "label": "Upper Cross Member",
        "value": getFirstValidValueFromCarModel(
          values: [
            carDetails.upperCrossMemberDropdownList,
            carDetails.upperCrossMember,
          ],
          returnType: ReturnType.string,
        ),
        "icon": Icons.border_top,
      },
      {
        "label": "Radiator Support",
        "value": getFirstValidValueFromCarModel(
          values: [
            carDetails.radiatorSupportDropdownList,
            carDetails.radiatorSupport,
          ],
          returnType: ReturnType.string,
        ),
        "icon": Icons.water_drop_outlined, // coolant-related
      },
      {
        "label": "Head Light Support",
        "value": getFirstValidValueFromCarModel(
          values: [
            carDetails.headlightSupportDropdownList,
            carDetails.headlightSupport,
          ],
          returnType: ReturnType.string,
        ),
        "icon": Icons.lightbulb_outline, // lights
      },
      {
        "label": "Lower Cross Member",
        "value": getFirstValidValueFromCarModel(
          values: [
            carDetails.lowerCrossMemberDropdownList,
            carDetails.lowerCrossMember,
          ],
          returnType: ReturnType.string,
        ),
        "icon": Icons.border_bottom,
      },
      {
        "label": "LHS Apron",
        "value": getFirstValidValueFromCarModel(
          values: [carDetails.lhsApronDropdownList, carDetails.lhsApron],
          returnType: ReturnType.string,
        ),
        "icon": Icons.align_horizontal_left,
        // "imageUrls": [ carDetails.apronLhsRhs.isNotEmpty ? carDetails.apronLhsRhs[0] : 'NA', ],
        "imageUrls": getFirstValidValueFromCarModel(
          values: [
            carDetails.lhsApronImages,
            carDetails.apronLhsRhs.isNotEmpty
                ? carDetails.apronLhsRhs[0]
                : null,
          ],
          returnType: ReturnType.list,
          defaultValue: [],
        ),
      },
      {
        "label": "RHS Apron",
        "value": getFirstValidValueFromCarModel(
          values: [carDetails.rhsApronDropdownList, carDetails.rhsApron],
          returnType: ReturnType.string,
        ),
        "icon": Icons.align_horizontal_right,
        // "imageUrls": [ carDetails.apronLhsRhs.length > 1 ? carDetails.apronLhsRhs[1] : 'NA', ],
        "imageUrls": getFirstValidValueFromCarModel(
          values: [
            carDetails.rhsApronImages,
            carDetails.apronLhsRhs.length > 1
                ? carDetails.apronLhsRhs[1]
                : null,
          ],
          returnType: ReturnType.list,
          defaultValue: [],
        ),
      },
      {
        "label": "Firewall",
        "value": getFirstValidValueFromCarModel(
          values: [carDetails.firewallDropdownList, carDetails.firewall],
          returnType: ReturnType.string,
        ),
        "icon": Icons.shield, // metaphorical for firewall
        "imageUrls": carDetails.firewallImages,
      },
      {
        "label": "Cowl Top",
        "value": getFirstValidValueFromCarModel(
          values: [carDetails.cowlTopDropdownList, carDetails.cowlTop],
          returnType: ReturnType.string,
        ),
        "icon": Icons.expand_less, // top area metaphor
        "imageUrls": carDetails.cowlTopImages,
      },
      {
        "label": "Engine",
        "value": getFirstValidValueFromCarModel(
          values: [carDetails.engineDropdownList, carDetails.engine],
          returnType: ReturnType.string,
        ),
        "icon": Icons.settings, // engine machinery
      },
      {
        "label": "Battery",
        "value": getFirstValidValueFromCarModel(
          values: [carDetails.batteryDropdownList, carDetails.battery],
          returnType: ReturnType.string,
        ),
        "icon": Icons.battery_full,
        "imageUrls": carDetails.batteryImages,
      },
      {
        "label": "Coolant",
        "value": getFirstValidValueFromCarModel(
          values: [carDetails.coolantDropdownList, carDetails.coolant],
          returnType: ReturnType.string,
        ),
        "icon": Icons.water_drop,
      },
      {
        "label": "Engine Oil Level Dipstick",
        "value": getFirstValidValueFromCarModel(
          values: [
            carDetails.engineOilLevelDipstickDropdownList,
            carDetails.engineOilLevelDipstick,
          ],
          returnType: ReturnType.string,
        ),
        "icon": Icons.straighten, // for measuring tool
      },
      {
        "label": "Engine Oil",
        "value": getFirstValidValueFromCarModel(
          values: [carDetails.engineOilDropdownList, carDetails.engineOil],
          returnType: ReturnType.string,
        ),
        "icon": Icons.oil_barrel,
      },
      {
        "label": "Engine Mount",
        "value": getFirstValidValueFromCarModel(
          values: [carDetails.engineMountDropdownList, carDetails.engineMount],
          returnType: ReturnType.string,
        ),
        "icon": Icons.construction,
      },
      {
        "label": "Permisable Blow By",
        "value": getFirstValidValueFromCarModel(
          values: [
            carDetails.enginePermisableBlowByDropdownList,
            carDetails.enginePermisableBlowBy,
          ],
          returnType: ReturnType.string,
        ),
        "icon": Icons.compress,
      },
      {
        "label": "Exhaust Smoke",
        "value": getFirstValidValueFromCarModel(
          values: [
            carDetails.exhaustSmokeDropdownList,
            carDetails.exhaustSmoke,
          ],
          returnType: ReturnType.string,
        ),
        "icon": Icons.air,
      },
      {
        "label": "Clutch",
        "value": getFirstValidValueFromCarModel(
          values: [carDetails.clutchDropdownList, carDetails.clutch],
          returnType: ReturnType.string,
        ),
        "icon": Icons.sync_alt, // motion/transfer metaphor
      },
      {
        "label": "Gear Shift",
        "value": getFirstValidValueFromCarModel(
          values: [carDetails.gearShiftDropdownList, carDetails.gearShift],
          returnType: ReturnType.string,
        ),
        "icon": Icons.settings_input_component,
      },

      ////
      // {
      //   "label": "Chassis Number",
      //   "value": carDetails.chassisNumber,
      //   "icon": Icons.car_repair,
      // },
      // {
      //   "label": "Cubic Capacity",
      //   "value": '${carDetails.cubicCapacity} cc',
      //   "icon": Icons.compress,
      // },
      // {
      //   "label": "Fuel Type",
      //   "value": carDetails.fuelType,
      //   "icon": Icons.local_gas_station,
      // },
      // {
      //   "label": "Hypothecation",
      //   "value": carDetails.hypothecationDetails,
      //   "icon": Icons.verified_user,
      // },
      // {
      //   "label": "Engine Mount",
      //   "value": carDetails.engineMount,
      //   "icon": Icons.engineering,
      // },
      // // {
      // //   "label": "Engine Sound",
      // //   "value": carDetails.engineSound,
      // //   "icon": Icons.volume_up,
      // // },
      // // {
      // //   "label": "Engine Bay",
      // //   "value": carDetails.engineBay,
      // //   "icon": Icons.build_circle,
      // // },
      // {
      //   "label": "Dipstick Oil Level",
      //   "value": carDetails.engineOilLevelDipstick,
      //   "icon": Icons.water_drop,
      // },
      // {
      //   "label": "Engine Oil",
      //   "value": carDetails.engineOil,
      //   "icon": Icons.oil_barrel,
      // },
      // {
      //   "label": "Permissible Blow By",
      //   "value": carDetails.enginePermisableBlowBy,
      //   "icon": Icons.air,
      // },
      // {
      //   "label": "Exhaust Smoke",
      //   "value": carDetails.exhaustSmoke,
      //   "icon": Icons.smoke_free,
      // },
      // // {
      // //   "label": "Exhaust Smoke 2",
      // //   "value": carDetails.exhaustSmoke1,
      // //   "icon": Icons.smoke_free_outlined,
      // // },
      // {"label": "Coolant", "value": carDetails.coolant, "icon": Icons.ac_unit},
      // {
      //   "label": "Battery",
      //   "value": carDetails.battery,
      //   "icon": Icons.battery_full,
      // },
      // // {
      // //   "label": "Battery 2",
      // //   "value": carDetails.battery1,
      // //   "icon": Icons.battery_std,
      // // },
      // {"label": "Clutch", "value": carDetails.clutch, "icon": Icons.sync},
      // {
      //   "label": "Gear Shift",
      //   "value": carDetails.gearShift,
      //   "icon": Icons.settings_suggest,
      // },
      // {
      //   "label": "Oil Comments",
      //   "value": carDetails.commentsOnEngineOil,
      //   "icon": Icons.comment,
      // },
      // {
      //   "label": "Transmission Comments",
      //   "value": carDetails.commentsOnTransmission,
      //   "icon": Icons.notes,
      // },
    ];

    // Extract Comments
    final String commentsOnEngine = getFirstValidValueFromCarModel(
      values: [
        carDetails.commentsOnEngineDropdownList,
        carDetails.commentsOnEngine,
      ],
      returnType: ReturnType.string,
    );
    final String commentsOnEngineOil = getFirstValidValueFromCarModel(
      values: [
        carDetails.commentsOnEngineOilDropdownList,
        carDetails.commentsOnEngineOil,
      ],
      returnType: ReturnType.string,
    );
    final String commentsOnTransmission = getFirstValidValueFromCarModel(
      values: [
        carDetails.commentsOnTransmissionDropdownList,
        carDetails.commentsOnTransmission,
      ],
      returnType: ReturnType.string,
    );
    final String commentsOnRadiator = getFirstValidValueFromCarModel(
      values: [
        carDetails.commentsOnRadiatorDropdownList,
        carDetails.commentsOnRadiator,
      ],
      returnType: ReturnType.string,
    );
    final String commentsOnTowing = getFirstValidValueFromCarModel(
      values: [
        carDetails.commentsOnTowingDropdownList,
        carDetails.commentsOnTowing,
      ],
      returnType: ReturnType.string,
    );
    final String commentsOnOthers = getFirstValidValueFromCarModel(
      values: [
        carDetails.commentsOnOthersDropdownList,
        carDetails.commentsOnOthers,
      ],
      returnType: ReturnType.string,
    );

    final List<String> engineBayImages = getFirstValidValueFromCarModel(
      values: [carDetails.engineBayImages, carDetails.engineBay],
      returnType: ReturnType.list,
    );

    final List<String> additionalEngineImages = getFirstValidValueFromCarModel(
      values: [carDetails.additionalEngineImages, carDetails.additionalImages],
      returnType: ReturnType.list,
    );

    return AccordionWidget(
      title: 'Engine Bay',
      contentSize: 400,
      icon: Icons.engineering,
      content: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 8),
        child: Column(
          children: [
            if (engineBayImages.isNotEmpty)
              buildItem(
                icon: Icons.collections_outlined,
                label: 'Engine Bay Images',
                trailing: engineBayValue(engineBayImages.length.toString()),
                imageUrls: engineBayImages,
              ),

            ...fields.map((item) {
              return buildItem(
                icon: item['icon'] as IconData,
                label: item['label'] as String,
                trailing: engineBayValue(item['value'] as String? ?? ''),
                imageUrls: (item['imageUrls'] as List<String>?) ?? [],
              );
            }),

            if (additionalEngineImages.isNotEmpty)
              buildItem(
                icon: Icons.collections_outlined,
                label: 'Additional Images',
                trailing: engineBayValue(
                  additionalEngineImages.length.toString(),
                ),
                imageUrls: additionalEngineImages,
              ),

            // LayoutGrid(
            //   columnSizes: [1.fr, 1.fr],
            //   rowGap: 12,
            //   columnGap: 16,
            //   rowSizes: List.generate((fields.length / 2).ceil(), (_) => auto),
            //   children:
            //       fields.map((item) {
            //         return infoCard(
            //           icon: item['icon'] as IconData,
            //           label: item['label'] as String,
            //           value: item['value'] as String? ?? '',
            //         );
            //       }).toList(),
            // ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: const Text(
                'Videos',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                videoCard(
                  label: 'Engine Sound',
                  // videoUrl: carDetails.engineSound.isNotEmpty ? carDetails.engineSound[0] : 'NA',
                  videoUrl: getFirstValidValueFromCarModel(
                    values: [
                      [
                        carDetails.engineVideo.isNotEmpty
                            ? carDetails.engineVideo[0]
                            : 'NA',
                      ],
                      [
                        carDetails.engineSound.isNotEmpty
                            ? carDetails.engineSound[0]
                            : 'NA',
                      ],
                    ],
                    returnType: ReturnType.string,
                  ),
                ),
                videoCard(
                  label: 'Exhaust Smoke',
                  // videoUrl: carDetails.exhaustSmokeImages.isNotEmpty ? carDetails.exhaustSmokeImages[0] : 'NA',
                  videoUrl: getFirstValidValueFromCarModel(
                    values: [
                      [
                        carDetails.exhaustSmokeVideo.isNotEmpty
                            ? carDetails.exhaustSmokeVideo[0]
                            : 'NA',
                      ],
                      [
                        carDetails.exhaustSmokeImages.isNotEmpty
                            ? carDetails.exhaustSmokeImages[0]
                            : 'NA',
                      ],
                    ],
                    returnType: ReturnType.string,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Align(
              alignment: Alignment.centerLeft,
              child: const Text(
                'Comments',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(),
            const SizedBox(height: 10),
            // if no comments on any of the fields
            if (!getxController.isValidComment(commentsOnEngine) &&
                !getxController.isValidComment(commentsOnEngineOil) &&
                !getxController.isValidComment(commentsOnTransmission) &&
                !getxController.isValidComment(commentsOnRadiator) &&
                !getxController.isValidComment(commentsOnTowing) &&
                !getxController.isValidComment(commentsOnOthers))
              Text(
                'No Comments',
                style: TextStyle(fontSize: 12, color: AppColors.grey),
              ),

            // else show comments on each field
            if (getxController.isValidComment(commentsOnEngine))
              _buildCommentsCard(
                title: 'Comments on Engine',
                comment: commentsOnEngine,
                icon: Icons.settings, // represents engine/machinery
              ),
            if (getxController.isValidComment(commentsOnEngineOil))
              _buildCommentsCard(
                title: 'Comments on Engine Oil',
                comment: commentsOnEngineOil,
                icon: Icons.oil_barrel, // ideal for oil-related comments
              ),
            if (getxController.isValidComment(commentsOnTransmission))
              _buildCommentsCard(
                title: 'Comments on Transmission',
                comment: commentsOnTransmission,
                icon: Icons.sync_alt, // movement between components
              ),
            if (getxController.isValidComment(commentsOnRadiator))
              _buildCommentsCard(
                title: 'Comments on Radiator',
                comment: commentsOnRadiator,
                icon: Icons.water_drop, // fluid/coolant
              ),
            if (getxController.isValidComment(commentsOnTowing))
              _buildCommentsCard(
                title: 'Comments on Towing',
                comment: commentsOnTowing,
                icon: Icons.local_shipping, // towing/truck metaphor
              ),
            if (getxController.isValidComment(commentsOnOthers))
              _buildCommentsCard(
                title: 'Comments on Others',
                comment: commentsOnOthers,
                icon: Icons.info_outline, // general purpose
              ),
          ],
        ),
      ),
    );
  }

  // Steering, Brakes and Suspension
  Widget _buildSteeringBrackesAndSuspension({required CarModel carDetails}) {
    Widget buildItem(IconData icon, String label, String value) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: AppColors.green),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(fontSize: 13, color: AppColors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return AccordionWidget(
      title: 'Steering, Brakes and Suspension',
      icon: Icons.build_circle_outlined,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          buildItem(
            Icons.settings_ethernet,
            'Steering',
            getFirstValidValueFromCarModel(
              values: [carDetails.steeringDropdownList, carDetails.steering],
              returnType: ReturnType.string,
            ),
          ),
          buildItem(
            Icons.car_repair,
            'Brakes',
            getFirstValidValueFromCarModel(
              values: [carDetails.brakesDropdownList, carDetails.brakes],
              returnType: ReturnType.string,
            ),
          ),
          buildItem(
            Icons.directions_car_filled,
            'Suspension',
            getFirstValidValueFromCarModel(
              values: [
                carDetails.suspensionDropdownList,
                carDetails.suspension,
              ],
              returnType: ReturnType.string,
            ),
          ),
        ],
      ),
    );
  }

  // Safety & Airbags
  Widget _buildSafetyAndAirbags({required CarModel carDetails}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: AppColors.green),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.shield,
                size: 20,
                color: AppColors.blue.withValues(alpha: 0.7),
              ),
              SizedBox(width: 8),
              Text(
                'Safety & Airbags',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.blue,
                ),
              ),
            ],
          ),
          Divider(color: AppColors.grey.withValues(alpha: 0.5)),
          SizedBox(height: 5),
          _buildDetailRowForInspectionReport(
            Icons.date_range,
            'No. of Airbags',
            carDetails.noOfAirBags.toString(),
          ),
          Divider(color: AppColors.grey.withValues(alpha: 0.1)),
          const SizedBox(height: 5),
          _buildDetailRowForInspectionReport(
            Icons.description_outlined,
            'Airbag Features',
            carDetails.airbagFeaturesDriverSide.toString(),
          ),
          Divider(color: AppColors.grey.withValues(alpha: 0.1)),
          const SizedBox(height: 5),
          _buildDetailRowForInspectionReport(
            Icons.shield,
            'ABS',
            carDetails.abs,
          ),

          Divider(color: AppColors.grey.withValues(alpha: 0.1)),
          const SizedBox(height: 5),
          _buildDetailRowForInspectionReport(
            Icons.speed,
            'Odometer Reading',
            '${NumberFormat.decimalPattern().format(carDetails.odometerReadingInKms)} km',
          ),
          Divider(color: AppColors.grey.withValues(alpha: 0.1)),
          const SizedBox(height: 5),
          _buildDetailRowForInspectionReport(
            Icons.local_gas_station,
            'Fuel Level',
            carDetails.fuelLevel,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRowForInspectionReport(
    IconData icon,
    String title,
    String value,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.blueGrey),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 13)),
              const SizedBox(height: 4),
            ],
          ),
        ),
        Text(value, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildInteriorAndElectricals({
    required CarModel carDetails,
    required CarDetailsController getxController,
  }) {
    Widget item({
      required IconData icon,
      required String label,
      required Widget trailing,
      List<String> imageUrls = const [],
    }) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.black54),
            const SizedBox(width: 10),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
            trailing,
            const SizedBox(width: 10),
            if (imageUrls.isNotEmpty) _buildSideImages(imageUrls: imageUrls),
          ],
        ),
      );
    }

    Widget interiorFeatureValue(String? value) {
      final status = value?.toLowerCase();

      if (status == 'available' || status == 'yes') {
        return Icon(Icons.check_circle, color: AppColors.green, size: 20);
      } else if (status == 'not applicable' ||
          status == 'not available' ||
          status == '') {
        return Icon(Icons.cancel, color: AppColors.red, size: 20);
      } else {
        return Text(value.toString(), style: const TextStyle(fontSize: 13));
      }
    }

    // Widget powerWindowChips() {
    //   if (carDetails.powerWindowConditionLhsFront == null || carDetails.powerWindowConditionLhsRear == null) {
    //     return const Text('No info');
    //   }
    //   return Wrap(
    //     spacing: 6,
    //     runSpacing: 6,
    //     children: carDetails.powerWindowCondition!
    //         .map((e) => Chip(
    //               label: Text(e, style: const TextStyle(fontSize: 12)),
    //               backgroundColor: Colors.blue.shade50,
    //             ))
    //         .toList(),
    //   );
    // }

    final List<String> additionalInteriorImages =
        getFirstValidValueFromCarModel(
          values: [
            carDetails.additionalInteriorImages,
            carDetails.additionalImages2,
          ],
          returnType: ReturnType.list,
        );

    final String commentOnInterior = getFirstValidValueFromCarModel(
      values: [
        carDetails.commentOnInteriorDropdownList,
        carDetails.commentOnInterior,
      ],
      returnType: ReturnType.string,
    );

    final List<String> clusterMeterImages = getFirstValidValueFromCarModel(
      values: [
        carDetails.meterConsoleWithEngineOnImages,
        carDetails.meterConsoleWithEngineOn,
      ],
      returnType: ReturnType.list,
    );

    return AccordionWidget(
      title: 'Interior & Electricals',
      icon: Icons.chair_alt_outlined,
      contentSize: 300,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          item(
            icon: Icons.speed, // Cluster Meter With Engine Running
            label: 'Cluster Meter With Engine Running',
            trailing: interiorFeatureValue(
              clusterMeterImages.length.toString(),
            ),
            imageUrls: clusterMeterImages,
          ),

          item(
            icon: Icons.security, // ABS
            label: 'ABS',
            trailing: interiorFeatureValue(carDetails.abs),
          ),

          // item(
          //   icon: Icons.electric_bolt, // Electricals
          //   label: 'Electricals',
          //   trailing: interiorFeatureValue(carDetails.electricals),
          // ),
          item(
            icon: Icons.wash, // Front Wiper & Washer
            label: 'Front Wiper & Washer',
            trailing: interiorFeatureValue(
              getFirstValidValueFromCarModel(
                values: [carDetails.frontWiperAndWasherDropdownList],
                returnType: ReturnType.string,
              ),
            ),
            imageUrls: carDetails.frontWiperAndWasherImages,
          ),

          item(
            icon: Icons.wash, // Rear Wiper & Washer
            label: 'Rear Wiper & Washer',
            trailing: interiorFeatureValue(
              getFirstValidValueFromCarModel(
                values: [
                  carDetails.rearWiperWasherDropdownList,
                  carDetails.rearWiperWasher,
                ],
                returnType: ReturnType.string,
              ),
            ),
            imageUrls: carDetails.rearWiperAndWasherImages,
          ),

          item(
            icon: Icons.blur_on, // Rear Defogger
            label: 'Rear Defogger',
            trailing: interiorFeatureValue(
              getFirstValidValueFromCarModel(
                values: [
                  carDetails.rearDefoggerDropdownList,
                  carDetails.rearDefogger,
                ],
                returnType: ReturnType.string,
              ),
            ),
          ),

          // item(
          //   icon: Icons.music_note, // Music System
          //   label: 'Music System',
          //   trailing: interiorFeatureValue(carDetails.musicSystem),
          // ),

          // item(
          //   icon: Icons.speaker, // Stereo
          //   label: 'Stereo',
          //   trailing: interiorFeatureValue(carDetails.stereo),
          // ),
          item(
            icon: Icons.music_note, // Infotainment System
            label: 'Infotainment System',
            trailing: interiorFeatureValue(
              carDetails.infotainmentSystemDropdownList.isNotEmpty
                  ? carDetails.infotainmentSystemDropdownList.join(', ')
                  : 'not applicable',
            ),
          ),

          item(
            icon: Icons.speaker_group, // Inbuilt Speaker
            label: 'Inbuilt Speaker',
            trailing: interiorFeatureValue(carDetails.inbuiltSpeaker),
          ),

          item(
            icon: Icons.speaker_outlined, // External Speaker
            label: 'External Speaker',
            trailing: interiorFeatureValue(carDetails.externalSpeaker),
          ),

          item(
            // icon: Icons.surround_sound, // Steering Mounted Media Controls
            icon: Icons.music_note, // Steering Mounted Media Controls
            label: 'Steering Mounted Media Controls',
            trailing: interiorFeatureValue(
              getFirstValidValueFromCarModel(
                values: [
                  carDetails.steeringMountedMediaControls,
                  carDetails.steeringMountedAudioControl,
                ],
                returnType: ReturnType.string,
              ),
            ),
          ),

          item(
            icon: Icons.settings_remote, // Steering Mounted System Controls
            label: 'Steering Mounted System Controls',
            trailing: interiorFeatureValue(
              getFirstValidValueFromCarModel(
                values: [
                  carDetails.steeringMountedSystemControls,
                  carDetails.steeringMountedAudioControl,
                ],
                returnType: ReturnType.string,
              ),
            ),
          ),

          item(
            icon: Icons.window, // No. of Power Windows
            label: 'No. of Power Windows',
            trailing: interiorFeatureValue(carDetails.noOfPowerWindows),
          ),

          item(
            icon: Icons.door_front_door, // RHS Front Power Window
            // label: 'Power Window Condition (RHS) Front',
            label: 'RHS Front Door Features',
            trailing: interiorFeatureValue(
              getFirstValidValueFromCarModel(
                values: [
                  carDetails.rhsFrontDoorFeaturesDropdownList,
                  carDetails.powerWindowConditionRhsFront,
                ],
                returnType: ReturnType.string,
              ),
            ),
          ),

          item(
            icon: Icons.door_front_door, // LHS Front Power Window
            // label: 'Power Window Condition (LHS) Front',
            label: 'LHS Front Door Features',
            trailing: interiorFeatureValue(
              getFirstValidValueFromCarModel(
                values: [
                  carDetails.lhsFrontDoorFeaturesDropdownList,
                  carDetails.powerWindowConditionLhsFront,
                ],
                returnType: ReturnType.string,
              ),
            ),
          ),

          item(
            icon: Icons.meeting_room, // RHS Rear Power Window
            // label: 'Power Window Condition (RHS) Rear',
            label: 'RHS Rear Door Features',
            trailing: interiorFeatureValue(
              getFirstValidValueFromCarModel(
                values: [
                  carDetails.rhsRearDoorFeaturesDropdownList,
                  carDetails.powerWindowConditionRhsRear,
                ],
                returnType: ReturnType.string,
              ),
            ),
          ),

          item(
            icon: Icons.meeting_room, // LHS Rear Power Window
            // label: 'Power Window Condition (LHS) Rear',
            label: 'LHS Rear Door Features',
            trailing: interiorFeatureValue(
              getFirstValidValueFromCarModel(
                values: [
                  carDetails.lhsRearDoorFeaturesDropdownList,
                  carDetails.powerWindowConditionLhsRear,
                ],
                returnType: ReturnType.string,
              ),
            ),
          ),

          item(
            icon: Icons.airline_seat_recline_normal, // No. of Airbags
            label: 'No. of Airbags',
            trailing: interiorFeatureValue(carDetails.noOfAirBags.toString()),
            imageUrls: getFirstValidValueFromCarModel(
              values: [carDetails.airbagImages, carDetails.airbags],
              returnType: ReturnType.list,
            ),
          ),

          item(
            icon: Icons.shield_outlined, // Driver Airbag
            // label: 'Airbag Feature Driver Side',
            label: 'Driver Airbag',
            trailing: interiorFeatureValue(
              getFirstValidValueFromCarModel(
                values: [
                  carDetails.driverAirbag,
                  carDetails.airbagFeaturesDriverSide,
                ],
                returnType: ReturnType.string,
              ),
            ),
            imageUrls: getFirstValidValueFromCarModel(
              values: [
                carDetails.airbagImages.isNotEmpty
                    ? carDetails.airbagImages[0]
                    : null,
                carDetails.airbags.isNotEmpty ? carDetails.airbags[0] : null,
              ],
              returnType: ReturnType.list,
              defaultValue: [],
            ),
          ),

          item(
            icon: Icons.shield_outlined, // Co-Driver Airbag
            // label: 'Airbag Feature Co-Driver Side',
            label: 'Co-Driver Airbag',
            trailing: interiorFeatureValue(
              getFirstValidValueFromCarModel(
                values: [
                  carDetails.coDriverAirbag,
                  carDetails.airbagFeaturesCoDriverSide,
                ],
                returnType: ReturnType.string,
              ),
            ),
            imageUrls: getFirstValidValueFromCarModel(
              values: [
                carDetails.airbagImages.length > 1
                    ? carDetails.airbagImages[1]
                    : null,
                carDetails.airbags.length > 1 ? carDetails.airbags[1] : null,
              ],
              returnType: ReturnType.list,
              defaultValue: [],
            ),
          ),

          item(
            icon: Icons.event_seat, // RHS A Pillar Airbag
            // label: 'Airbag Feature RHS A Pillar',
            label: 'Driver Seat Airbag',
            trailing: interiorFeatureValue(
              getFirstValidValueFromCarModel(
                values: [
                  carDetails.driverSeatAirbag,
                  carDetails.airbagFeaturesRhsAPillarCurtain,
                ],
                returnType: ReturnType.string,
              ),
            ),
            imageUrls: getFirstValidValueFromCarModel(
              values: [
                carDetails.airbagImages.length > 2
                    ? carDetails.airbagImages[2]
                    : null,
                carDetails.airbags.length > 2 ? carDetails.airbags[2] : null,
              ],
              returnType: ReturnType.list,
              defaultValue: [],
            ),
          ),

          item(
            icon: Icons.event_seat, // LHS A Pillar Airbag
            // label: 'Airbag Feature LHS A Pillar',
            label: 'Co-Driver Seat Airbag',
            trailing: interiorFeatureValue(
              getFirstValidValueFromCarModel(
                values: [
                  carDetails.coDriverSeatAirbag,
                  carDetails.airbagFeaturesLhsAPillarCurtain,
                ],
                returnType: ReturnType.string,
              ),
            ),
            imageUrls: getFirstValidValueFromCarModel(
              values: [
                carDetails.airbagImages.length > 3
                    ? carDetails.airbagImages[3]
                    : null,
                carDetails.airbags.length > 3 ? carDetails.airbags[3] : null,
              ],
              returnType: ReturnType.list,
              defaultValue: [],
            ),
          ),

          item(
            icon: Icons.vertical_split, // RHS B Pillar Airbag
            // label: 'Airbag Feature RHS B Pillar',
            label: 'RHS Curtain Airbag',
            trailing: interiorFeatureValue(
              getFirstValidValueFromCarModel(
                values: [
                  carDetails.rhsCurtainAirbag,
                  carDetails.airbagFeaturesRhsBPillarCurtain,
                ],
                returnType: ReturnType.string,
              ),
            ),
            imageUrls: getFirstValidValueFromCarModel(
              values: [
                carDetails.airbagImages.length > 4
                    ? carDetails.airbagImages[4]
                    : null,
                carDetails.airbags.length > 4 ? carDetails.airbags[4] : null,
              ],
              returnType: ReturnType.list,
              defaultValue: [],
            ),
          ),

          item(
            icon: Icons.vertical_split, // LHS B Pillar Airbag
            // label: 'Airbag Feature LHS B Pillar',
            label: 'LHS Curtain Airbag',
            trailing: interiorFeatureValue(
              getFirstValidValueFromCarModel(
                values: [
                  carDetails.lhsCurtainAirbag,
                  carDetails.airbagFeaturesLhsBPillarCurtain,
                ],
                returnType: ReturnType.string,
              ),
            ),
            imageUrls: getFirstValidValueFromCarModel(
              values: [
                carDetails.airbagImages.length > 5
                    ? carDetails.airbagImages[5]
                    : null,
                carDetails.airbags.length > 5 ? carDetails.airbags[5] : null,
              ],
              returnType: ReturnType.list,
              defaultValue: [],
            ),
          ),

          item(
            icon: Icons.accessibility_new, // Driver Knee Airbag (new)
            label: 'Driver Knee Airbag',
            trailing: interiorFeatureValue(carDetails.driverSideKneeAirbag),
            imageUrls: getFirstValidValueFromCarModel(
              values: [
                carDetails.airbagImages.length > 6
                    ? carDetails.airbagImages[6]
                    : null,
                carDetails.airbags.length > 6 ? carDetails.airbags[6] : null,
              ],
              returnType: ReturnType.list,
              defaultValue: [],
            ),
          ),

          item(
            icon: Icons.accessibility_new, // Co-Driver Knee Airbag (new)
            label: 'Co-Driver Knee Airbag',
            trailing: interiorFeatureValue(carDetails.coDriverKneeSeatAirbag),
            imageUrls: getFirstValidValueFromCarModel(
              values: [
                carDetails.airbagImages.length > 7
                    ? carDetails.airbagImages[7]
                    : null,
                carDetails.airbags.length > 7 ? carDetails.airbags[7] : null,
              ],
              returnType: ReturnType.list,
              defaultValue: [],
            ),
          ),

          item(
            icon: Icons.airline_seat_recline_normal, // RHS C Pillar Airbag
            // label: 'Airbag Feature RHS C Pillar',
            label: 'RHS Rear Side Airbag',
            trailing: interiorFeatureValue(
              getFirstValidValueFromCarModel(
                values: [
                  carDetails.rhsRearSideAirbag,
                  carDetails.airbagFeaturesRhsCPillarCurtain,
                ],
                returnType: ReturnType.string,
              ),
            ),
            imageUrls: getFirstValidValueFromCarModel(
              values: [
                carDetails.airbagImages.length > 8
                    ? carDetails.airbagImages[8]
                    : null,
                carDetails.airbags.length > 8 ? carDetails.airbags[8] : null,
              ],
              returnType: ReturnType.list,
              defaultValue: [],
            ),
          ),

          item(
            icon: Icons.airline_seat_recline_normal, // LHS C Pillar Airbag
            // label: 'Airbag Feature LHS C Pillar',
            label: 'LHS Rear Side Airbag',
            trailing: interiorFeatureValue(
              getFirstValidValueFromCarModel(
                values: [
                  carDetails.lhsRearSideAirbag,
                  carDetails.airbagFeaturesLhsCPillarCurtain,
                ],
                returnType: ReturnType.string,
              ),
            ),
            imageUrls: getFirstValidValueFromCarModel(
              values: [
                carDetails.airbagImages.length > 9
                    ? carDetails.airbagImages[9]
                    : null,
                carDetails.airbags.length > 9 ? carDetails.airbags[9] : null,
              ],
              returnType: ReturnType.list,
              defaultValue: [],
            ),
          ),

          item(
            icon: Icons.event_seat, // Front Seats From Driver Side
            label: 'Front Seats From Driver Side',
            trailing: interiorFeatureValue(
              getFirstValidValueFromCarModel(
                values: [
                  carDetails.frontSeatsFromDriverSideImages,
                  carDetails.frontSeatsFromDriverSideDoorOpen,
                ],
                returnType: ReturnType.list,
              ).length.toString(),
            ),
            imageUrls: getFirstValidValueFromCarModel(
              values: [
                carDetails.frontSeatsFromDriverSideImages,
                carDetails.frontSeatsFromDriverSideDoorOpen,
              ],
              returnType: ReturnType.list,
            ),
          ),

          item(
            icon: Icons.weekend, // Rear Seats From Right Side
            label: 'Rear Seats From Right Side',
            trailing: interiorFeatureValue(
              getFirstValidValueFromCarModel(
                values: [
                  carDetails.rearSeatsFromRightSideImages,
                  carDetails.rearSeatsFromRightSideDoorOpen,
                ],
                returnType: ReturnType.list,
              ).length.toString(),
            ),
            imageUrls: getFirstValidValueFromCarModel(
              values: [
                carDetails.rearSeatsFromRightSideImages,
                carDetails.rearSeatsFromRightSideDoorOpen,
              ],
              returnType: ReturnType.list,
            ),
          ),

          item(
            icon: Icons.dashboard, // Dashboard From Rear Seat
            label: 'Dashboard From Rear Seat',
            trailing: interiorFeatureValue(
              getFirstValidValueFromCarModel(
                values: [
                  carDetails.dashboardImages,
                  carDetails.dashboardFromRearSeat,
                ],
                returnType: ReturnType.list,
              ).length.toString(),
            ),
            imageUrls: getFirstValidValueFromCarModel(
              values: [
                carDetails.dashboardImages,
                carDetails.dashboardFromRearSeat,
              ],
              returnType: ReturnType.list,
            ),
          ),

          item(
            icon: Icons.wb_sunny, // Sunroof
            label: 'Sunroof',
            trailing: interiorFeatureValue(
              getFirstValidValueFromCarModel(
                values: [carDetails.sunroofDropdownList, carDetails.sunroof],
                returnType: ReturnType.string,
              ),
            ),
            imageUrls: carDetails.sunroofImages,
          ),

          item(
            icon: Icons.videocam, // Reverse Camera
            label: 'Reverse Camera',
            trailing: interiorFeatureValue(
              getFirstValidValueFromCarModel(
                values: [
                  carDetails.reverseCameraDropdownList,
                  carDetails.reverseCamera,
                ],
                returnType: ReturnType.string,
              ),
            ),
            imageUrls: carDetails.reverseCameraImages,
          ),

          // item(
          //   icon: Icons.event_seat, // Leather Seats
          //   label: 'Leather Seats',
          //   trailing: interiorFeatureValue(carDetails.leatherSeats),
          // ),

          // item(
          //   icon: Icons.event_seat_outlined, // Fabric Seats
          //   label: 'Fabric Seats',
          //   trailing: interiorFeatureValue(carDetails.fabricSeats),
          // ),
          item(
            icon: Icons.event_seat, // Seats Upholstery
            label: 'Seats Upholstery',
            trailing: interiorFeatureValue(carDetails.seatsUpholstery),
          ),

          if (additionalInteriorImages.isNotEmpty)
            item(
              icon: Icons.collections_outlined,
              label: 'Additional Images',
              trailing: interiorFeatureValue(
                additionalInteriorImages.length.toString(),
              ),
              imageUrls: additionalInteriorImages,
            ),

          const SizedBox(height: 10),

          // if (getxController.isValidComment(carDetails.commentsOnElectricals))
          //   _buildCommentsCard(
          //     title: 'Comments on Electricals',
          //     comment: carDetails.commentsOnElectricals,
          //     icon: Icons.electrical_services,
          //   ),
          if (getxController.isValidComment(commentOnInterior))
            _buildCommentsCard(
              title: 'Comments on Interior',
              comment: commentOnInterior,
              icon: Icons.weekend,
            ),

          // const SizedBox(height: 10),

          // /// AC Features
          // item(
          //   icon: Icons.ac_unit,
          //   label: 'Manual AC',
          //   trailing: interiorFeatureValue(carDetails.airConditioningManual),
          // ),
          // item(
          //   icon: Icons.ac_unit_outlined,
          //   label: 'Climate Control',
          //   trailing: interiorFeatureValue(
          //     carDetails.airConditioningClimateControl,
          //   ),
          // ),

          // const SizedBox(height: 10),

          // /// Music System
          // item(
          //   icon: Icons.music_note,
          //   label: 'Music System',
          //   trailing: interiorFeatureValue(carDetails.musicSystem),
          // ),
          // item(
          //   icon: Icons.speaker,
          //   label: 'Stereo',
          //   trailing: interiorFeatureValue(carDetails.stereo),
          // ),
          // item(
          //   icon: Icons.speaker_group,
          //   label: 'Inbuilt Speaker',
          //   trailing: interiorFeatureValue(carDetails.inbuiltSpeaker),
          // ),
          // item(
          //   icon: Icons.speaker_outlined,
          //   label: 'External Speaker',
          //   trailing: interiorFeatureValue(carDetails.externalSpeaker),
          // ),

          // const SizedBox(height: 10),

          // /// Reverse & Seats
          // item(
          //   icon: Icons.videocam,
          //   label: 'Reverse Camera',
          //   trailing: interiorFeatureValue(carDetails.reverseCamera),
          // ),
          // item(
          //   icon: Icons.event_seat,
          //   label: 'Leather Seats',
          //   trailing: interiorFeatureValue(carDetails.leatherSeats),
          // ),
          // item(
          //   icon: Icons.event_seat_outlined,
          //   label: 'Fabric Seats',
          //   trailing: interiorFeatureValue(carDetails.fabricSeats),
          // ),
          // item(
          //   icon: Icons.roofing,
          //   label: 'Sunroof',
          //   trailing: interiorFeatureValue(carDetails.sunroof),
          // ),

          // const SizedBox(height: 10),

          // /// Power Windows
          // item(
          //   icon: Icons.window,
          //   label: 'No. of Power Windows',
          //   trailing: interiorFeatureValue(carDetails.noOfPowerWindows),
          // ),
          // const SizedBox(height: 6),

          // // _powerWindowChips(),
          // const SizedBox(height: 10),

          // /// Steering-mounted audio
          // item(
          //   icon: Icons.volume_up,
          //   label: 'Steering Mounted Audio Control',
          //   trailing: interiorFeatureValue(
          //     carDetails.steeringMountedAudioControl,
          //   ),
          // ),
        ],
      ),
    );
  }

  // Air Condition
  Widget _buildAirCondition({
    required CarModel carDetails,
    required CarDetailsController getxController,
  }) {
    Widget buildItem(IconData icon, String label, String value) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: AppColors.green),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(fontSize: 13, color: AppColors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return AccordionWidget(
      title: 'Air Condition',
      icon: Icons.build_circle_outlined,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          buildItem(
            Icons.ac_unit,
            'Air Conditioning - Manual',
            getFirstValidValueFromCarModel(
              values: [
                carDetails.acTypeDropdownList,
                carDetails.airConditioningManual,
              ],
              returnType: ReturnType.string,
            ),
          ),
          buildItem(
            Icons.ac_unit,
            'Air Conditioning - Climate Control',
            getFirstValidValueFromCarModel(
              values: [
                carDetails.acCoolingDropdownList,
                carDetails.airConditioningClimateControl,
              ],
              returnType: ReturnType.string,
            ),
          ),

          // const SizedBox(height: 10),
          if (getxController.isValidComment(carDetails.commentsOnAc))
            _buildCommentsCard(
              title: 'Comments',
              comment: carDetails.commentsOnAc,
              icon: Icons.electrical_services,
            ),

          SizedBox(height: 300),
        ],
      ),
    );
  }

  Widget _buildExterior({
    required CarModel carDetails,
    required CarDetailsController getxController,
  }) {
    ////
    Widget buildExteriorItem(
      String title,
      String value, {
      bool isLast = false,
      List<String> imageUrls = const [],
    }) {
      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                width: 100,
                child: Text(
                  title,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  value,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              const SizedBox(width: 10),
              if (imageUrls.isNotEmpty) _buildSideImages(imageUrls: imageUrls),
            ],
          ),
          if (!isLast) Divider(color: AppColors.grey.withValues(alpha: 0.1)),
        ],
      );
    }

    ////
    // Widget buildExteriorItem1(
    //   String title,
    //   String value, {
    //   bool isLast = false,
    //   List<String> imageUrls = const [],
    // }) {
    //   return Column(
    //     children: [
    //       Row(
    //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
    //         children: [
    //           Expanded(
    //             child: Text(
    //               title,
    //               maxLines: 3,
    //               overflow: TextOverflow.ellipsis,
    //               style: const TextStyle(fontSize: 12),
    //             ),
    //           ),
    //           Expanded(
    //             child: Text(
    //               value,
    //               maxLines: 3,
    //               overflow: TextOverflow.ellipsis,
    //               style: const TextStyle(fontSize: 12),
    //             ),
    //           ),
    //           const SizedBox(width: 10),
    //           if (imageUrls.isNotEmpty) _buildSideImages(imageUrls: imageUrls),
    //         ],
    //       ),
    //       if (!isLast) Divider(color: AppColors.grey.withValues(alpha: 0.1)),
    //     ],
    //   );
    // }

    Widget buildSection({
      required String title,
      required List<Widget> itemsList,
    }) {
      return Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            Divider(),
            ...itemsList,
          ],
        ),
      );
    }

    return AccordionWidget(
      title: 'Exterior',
      icon: Icons.car_rental,
      contentSize: 400,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildSection(
            title: 'Front',
            itemsList: [
              buildExteriorItem(
                'Bonnet',
                getFirstValidValueFromCarModel(
                  values: [carDetails.bonnetDropdownList, carDetails.bonnet],
                  returnType: ReturnType.string,
                ),
                imageUrls: getFirstValidValueFromCarModel(
                  values: [
                    [
                      ...carDetails.bonnetClosedImages,
                      ...carDetails.bonnetOpenImages,
                    ],
                    carDetails.bonnetImages,
                  ],
                  returnType: ReturnType.list,
                ),
              ),
              buildExteriorItem(
                'Front Windshield',
                getFirstValidValueFromCarModel(
                  values: [
                    carDetails.frontWindshieldDropdownList,
                    carDetails.frontWindshield,
                  ],
                  returnType: ReturnType.string,
                ),
                imageUrls: carDetails.frontWindshieldImages,
              ),
              buildExteriorItem(
                'Roof',
                getFirstValidValueFromCarModel(
                  values: [carDetails.roofDropdownList, carDetails.roof],
                  returnType: ReturnType.string,
                ),
                imageUrls: carDetails.roofImages,
              ),
              buildExteriorItem(
                'Front Bumper',
                getFirstValidValueFromCarModel(
                  values: [
                    carDetails.frontBumperDropdownList,
                    carDetails.frontBumper,
                  ],
                  returnType: ReturnType.string,
                ),
                imageUrls: getFirstValidValueFromCarModel(
                  values: [
                    [
                      ...carDetails.frontBumperLhs45DegreeImages,
                      ...carDetails.frontBumperRhs45DegreeImages,
                    ],
                    carDetails.frontBumperImages,
                  ],
                  returnType: ReturnType.list,
                ),
              ),
              buildExteriorItem(
                'LHS Headlamp',
                getFirstValidValueFromCarModel(
                  values: [
                    carDetails.lhsHeadlampDropdownList,
                    carDetails.lhsHeadlamp,
                  ],
                  returnType: ReturnType.string,
                ),
                imageUrls: carDetails.lhsHeadlampImages,
              ),
              buildExteriorItem(
                'LHS Foglamp',
                getFirstValidValueFromCarModel(
                  values: [
                    carDetails.lhsFoglampDropdownList,
                    carDetails.lhsFoglamp,
                  ],
                  returnType: ReturnType.string,
                ),
                imageUrls: carDetails.lhsFoglampImages,
              ),
              buildExteriorItem(
                'RHS Headlamp',
                getFirstValidValueFromCarModel(
                  values: [
                    carDetails.rhsHeadlampDropdownList,
                    carDetails.rhsHeadlamp,
                  ],
                  returnType: ReturnType.string,
                ),
                imageUrls: carDetails.rhsHeadlampImages,
              ),
              buildExteriorItem(
                'RHS Foglamp',
                getFirstValidValueFromCarModel(
                  values: [
                    carDetails.rhsFoglampDropdownList,
                    carDetails.rhsFoglamp,
                  ],
                  returnType: ReturnType.string,
                ),
                imageUrls: carDetails.rhsFoglampImages,
                isLast: true,
              ),
            ],
          ),
          const SizedBox(height: 10),
          buildSection(
            title: 'Left',
            itemsList: [
              buildExteriorItem(
                'LHS Fender',
                getFirstValidValueFromCarModel(
                  values: [
                    carDetails.lhsFenderDropdownList,
                    carDetails.lhsFender,
                  ],
                  returnType: ReturnType.string,
                ),
                imageUrls: carDetails.lhsFenderImages,
              ),
              buildExteriorItem(
                'LHS ORVM',
                getFirstValidValueFromCarModel(
                  values: [carDetails.lhsOrvmDropdownList, carDetails.lhsOrvm],
                  returnType: ReturnType.string,
                ),
                imageUrls: carDetails.lhsOrvmImages,
              ),
              buildExteriorItem(
                'LHS A Pillar',
                getFirstValidValueFromCarModel(
                  values: [
                    carDetails.lhsAPillarDropdownList,
                    carDetails.lhsAPillar,
                  ],
                  returnType: ReturnType.string,
                ),
                imageUrls: carDetails.lhsAPillarImages,
              ),
              buildExteriorItem(
                'LHS B Pillar',
                getFirstValidValueFromCarModel(
                  values: [
                    carDetails.lhsBPillarDropdownList,
                    carDetails.lhsAPillar,
                  ],
                  returnType: ReturnType.string,
                ),
                imageUrls: carDetails.lhsBPillarImages,
              ),
              buildExteriorItem(
                'LHS C Pillar',
                getFirstValidValueFromCarModel(
                  values: [
                    carDetails.lhsCPillarDropdownList,
                    carDetails.lhsCPillar,
                  ],
                  returnType: ReturnType.string,
                ),
                imageUrls: carDetails.lhsCPillarImages,
              ),
              buildExteriorItem(
                'LHS Front Wheel',
                getFirstValidValueFromCarModel(
                  values: [
                    carDetails.lhsFrontWheelDropdownList,
                    carDetails.lhsFrontAlloy,
                  ],
                  returnType: ReturnType.string,
                ),
                imageUrls: getFirstValidValueFromCarModel(
                  values: [
                    carDetails.lhsFrontWheelImages,
                    carDetails.lhsFrontAlloyImages,
                  ],
                  returnType: ReturnType.list,
                ),
              ),
              buildExteriorItem(
                'LHS Front Tyre',
                getFirstValidValueFromCarModel(
                  values: [
                    carDetails.lhsFrontTyreDropdownList,
                    carDetails.lhsFrontTyre,
                  ],
                  returnType: ReturnType.string,
                ),
                imageUrls: carDetails.lhsFrontTyreImages,
              ),
              buildExteriorItem(
                'LHS Rear Wheel',
                getFirstValidValueFromCarModel(
                  values: [
                    carDetails.lhsRearWheelDropdownList,
                    carDetails.lhsRearAlloy,
                  ],
                  returnType: ReturnType.string,
                ),
                imageUrls: getFirstValidValueFromCarModel(
                  values: [
                    carDetails.lhsRearWheelImages,
                    carDetails.lhsRearAlloyImages,
                  ],
                  returnType: ReturnType.list,
                ),
              ),
              buildExteriorItem(
                'LHS Rear Tyre',
                getFirstValidValueFromCarModel(
                  values: [
                    carDetails.lhsRearTyreDropdownList,
                    carDetails.lhsRearTyre,
                  ],
                  returnType: ReturnType.string,
                ),
                imageUrls: carDetails.lhsRearTyreImages,
              ),
              buildExteriorItem(
                'LHS Front Door',
                getFirstValidValueFromCarModel(
                  values: [
                    carDetails.lhsFrontDoorDropdownList,
                    carDetails.lhsFrontDoor,
                  ],
                  returnType: ReturnType.string,
                ),
                imageUrls: carDetails.lhsFrontDoorImages,
              ),
              buildExteriorItem(
                'LHS Rear Door',
                getFirstValidValueFromCarModel(
                  values: [
                    carDetails.lhsRearDoorDropdownList,
                    carDetails.lhsRearDoor,
                  ],
                  returnType: ReturnType.string,
                ),
                imageUrls: carDetails.lhsRearDoorImages,
              ),
              buildExteriorItem(
                'LHS Running Border',
                getFirstValidValueFromCarModel(
                  values: [
                    carDetails.lhsRunningBorderDropdownList,
                    carDetails.lhsRunningBorder,
                  ],
                  returnType: ReturnType.string,
                ),
                imageUrls: carDetails.lhsRunningBorderImages,
              ),
              buildExteriorItem(
                'LHS Quarter Panel',
                getFirstValidValueFromCarModel(
                  values: [
                    carDetails.lhsQuarterPanelDropdownList,
                    carDetails.lhsQuarterPanel,
                  ],
                  returnType: ReturnType.string,
                ),
                imageUrls: getFirstValidValueFromCarModel(
                  values: [
                    [
                      ...carDetails.lhsQuarterPanelWithRearDoorOpenImages,
                      ...carDetails.lhsQuarterPanelWithRearDoorClosedImages,
                    ],
                    carDetails.lhsQuarterPanelImages,
                  ],
                  returnType: ReturnType.list,
                ),
                isLast: true,
              ),
            ],
          ),
          const SizedBox(height: 10),
          buildSection(
            title: 'Rear',
            itemsList: [
              buildExteriorItem(
                'Rear Bumper',
                getFirstValidValueFromCarModel(
                  values: [
                    carDetails.rearBumperDropdownList,
                    carDetails.rearBumper,
                  ],
                  returnType: ReturnType.string,
                ),
                imageUrls: getFirstValidValueFromCarModel(
                  values: [
                    [
                      ...carDetails.rearBumperLhs45DegreeImages,
                      ...carDetails.rearBumperRhs45DegreeImages,
                    ],
                    carDetails.rearBumperImages,
                  ],
                  returnType: ReturnType.list,
                ),
              ),
              buildExteriorItem(
                'LHS Tail Lamp',
                getFirstValidValueFromCarModel(
                  values: [
                    carDetails.lhsTailLampDropdownList,
                    carDetails.lhsTailLamp,
                  ],
                  returnType: ReturnType.string,
                ),
                imageUrls: carDetails.lhsTailLampImages,
              ),
              buildExteriorItem(
                'RHS Tail Lamp',
                getFirstValidValueFromCarModel(
                  values: [
                    carDetails.rhsTailLampDropdownList,
                    carDetails.rhsTailLamp,
                  ],
                  returnType: ReturnType.string,
                ),
                imageUrls: carDetails.rhsTailLampImages,
              ),
              buildExteriorItem(
                'Rear Windshield',
                getFirstValidValueFromCarModel(
                  values: [
                    carDetails.rearWindshieldDropdownList,
                    carDetails.rearWindshield,
                  ],
                  returnType: ReturnType.string,
                ),
                imageUrls: carDetails.rearWindshieldImages,
              ),
              buildExteriorItem(
                'Boot Door',
                getFirstValidValueFromCarModel(
                  values: [
                    carDetails.bootDoorDropdownList,
                    carDetails.bootDoor,
                  ],
                  returnType: ReturnType.string,
                ),
                imageUrls: getFirstValidValueFromCarModel(
                  values: [
                    [
                      ...carDetails.bootDoorOpenImages,
                      ...carDetails.bootDoorClosedImages,
                    ],
                    carDetails.rearWithBootDoorOpen,
                  ],
                  returnType: ReturnType.list,
                ),
              ),
              buildExteriorItem(
                'Spare Tyre',
                getFirstValidValueFromCarModel(
                  values: [
                    carDetails.spareTyreDropdownList,
                    carDetails.spareTyre,
                  ],
                  returnType: ReturnType.string,
                ),
                imageUrls: carDetails.spareTyreImages,
              ),
              buildExteriorItem(
                'Spare Wheel',
                getFirstValidValueFromCarModel(
                  values: carDetails.spareWheelDropdownList,
                  returnType: ReturnType.string,
                ),
                imageUrls: carDetails.spareWheelImages,
              ),
              buildExteriorItem(
                'Boot Floor',
                getFirstValidValueFromCarModel(
                  values: [
                    carDetails.bootFloorDropdownList,
                    carDetails.bootFloor,
                  ],
                  returnType: ReturnType.string,
                ),
                imageUrls: carDetails.bootFloorImages,
                isLast: true,
              ),
            ],
          ),
          const SizedBox(height: 10),
          buildSection(
            title: 'Right',
            itemsList: [
              buildExteriorItem(
                'RHS Rear Wheel',
                getFirstValidValueFromCarModel(
                  values: [
                    carDetails.rhsRearWheelDropdownList,
                    carDetails.rhsRearAlloy,
                  ],
                  returnType: ReturnType.string,
                ),
                imageUrls: getFirstValidValueFromCarModel(
                  values: [
                    carDetails.rhsRearWheelImages,
                    carDetails.rhsRearAlloyImages,
                  ],
                  returnType: ReturnType.list,
                ),
              ),
              buildExteriorItem(
                'RHS Rear Tyre',
                getFirstValidValueFromCarModel(
                  values: [
                    carDetails.rhsRearTyreDropdownList,
                    carDetails.rhsRearTyre,
                  ],
                  returnType: ReturnType.string,
                ),
                imageUrls: carDetails.rhsRearTyreImages,
              ),
              buildExteriorItem(
                'RHS Front Wheel',
                getFirstValidValueFromCarModel(
                  values: [
                    carDetails.rhsFrontWheelDropdownList,
                    carDetails.rhsFrontAlloy,
                  ],
                  returnType: ReturnType.string,
                ),
                imageUrls: getFirstValidValueFromCarModel(
                  values: [
                    carDetails.rhsFrontWheelImages,
                    carDetails.rhsFrontAlloyImages,
                  ],
                  returnType: ReturnType.list,
                ),
              ),
              buildExteriorItem(
                'RHS Front Tyre',
                getFirstValidValueFromCarModel(
                  values: [
                    carDetails.rhsFrontTyreDropdownList,
                    carDetails.rhsFrontTyre,
                  ],
                  returnType: ReturnType.string,
                ),
                imageUrls: carDetails.rhsFrontTyreImages,
              ),
              buildExteriorItem(
                'RHS Quarter Panel',
                getFirstValidValueFromCarModel(
                  values: [
                    carDetails.rhsQuarterPanelDropdownList,
                    carDetails.rhsQuarterPanel,
                  ],
                  returnType: ReturnType.string,
                ),
                imageUrls: getFirstValidValueFromCarModel(
                  values: [
                    [
                      ...carDetails.rhsQuarterPanelWithRearDoorOpenImages,
                      ...carDetails.rhsQuarterPanelWithRearDoorClosedImages,
                    ],
                    carDetails.rhsQuarterPanelImages,
                  ],
                  returnType: ReturnType.list,
                ),
              ),
              buildExteriorItem(
                'RHS A Pillar',
                getFirstValidValueFromCarModel(
                  values: [
                    carDetails.rhsAPillarDropdownList,
                    carDetails.rhsAPillar,
                  ],
                  returnType: ReturnType.string,
                ),
                imageUrls: carDetails.rhsAPillarImages,
              ),
              buildExteriorItem(
                'RHS B Pillar',
                getFirstValidValueFromCarModel(
                  values: [
                    carDetails.rhsBPillarDropdownList,
                    carDetails.rhsBPillar,
                  ],
                  returnType: ReturnType.string,
                ),
                imageUrls: carDetails.rhsBPillarImages,
              ),
              buildExteriorItem(
                'RHS C Pillar',
                getFirstValidValueFromCarModel(
                  values: [
                    carDetails.rhsCPillarDropdownList,
                    carDetails.rhsCPillar,
                  ],
                  returnType: ReturnType.string,
                ),
                imageUrls: carDetails.rhsCPillarImages,
              ),
              buildExteriorItem(
                'RHS Running Border',
                getFirstValidValueFromCarModel(
                  values: [
                    carDetails.rhsRunningBorderDropdownList,
                    carDetails.rhsRunningBorder,
                  ],
                  returnType: ReturnType.string,
                ),
                imageUrls: carDetails.rhsRunningBorderImages,
              ),
              buildExteriorItem(
                'RHS Rear Door',
                getFirstValidValueFromCarModel(
                  values: [
                    carDetails.rhsRearDoorDropdownList,
                    carDetails.rhsRearDoor,
                  ],
                  returnType: ReturnType.string,
                ),
                imageUrls: carDetails.rhsRearDoorImages,
              ),
              buildExteriorItem(
                'RHS Front Door',
                getFirstValidValueFromCarModel(
                  values: [
                    carDetails.rhsFrontDoorDropdownList,
                    carDetails.rhsFrontDoor,
                  ],
                  returnType: ReturnType.string,
                ),
                imageUrls: carDetails.rhsFrontDoorImages,
              ),
              buildExteriorItem(
                'RHS ORVM',
                getFirstValidValueFromCarModel(
                  values: [carDetails.rhsOrvmDropdownList, carDetails.rhsOrvm],
                  returnType: ReturnType.string,
                ),
                imageUrls: carDetails.rhsOrvmImages,
              ),
              buildExteriorItem(
                'RHS Fender',
                getFirstValidValueFromCarModel(
                  values: [
                    carDetails.rhsFenderDropdownList,
                    carDetails.rhsFender,
                  ],
                  returnType: ReturnType.string,
                ),
                imageUrls: carDetails.rhsFenderImages,
                isLast: true,
              ),
            ],
          ),
          // buildExteriorItem('Bonnet', carDetails.bonnet),
          // buildExteriorItem('Front Windshield', carDetails.frontWindshield),
          // buildExteriorItem('Roof', carDetails.roof),
          // buildExteriorItem('Front Bumper', carDetails.frontBumper),
          // buildExteriorItem('LHS Headlamp', carDetails.lhsHeadlamp),
          // buildExteriorItem('LHS Foglamp', carDetails.lhsFoglamp),
          // buildExteriorItem('RHS Headlamp', carDetails.rhsHeadlamp),
          // buildExteriorItem('RHS Foglamp', carDetails.rhsFoglamp),
          // buildExteriorItem('LHS Fender', carDetails.lhsFender),
          // buildExteriorItem('LHS ORVM', carDetails.lhsOrvm),
          // buildExteriorItem('LHS A Pillar', carDetails.lhsAPillar),
          // buildExteriorItem('LHS B Pillar', carDetails.lhsBPillar),
          // buildExteriorItem('LHS C Pillar', carDetails.lhsCPillar),
          // buildExteriorItem('LHS Front Alloy', carDetails.lhsFrontAlloy),
          // buildExteriorItem('LHS Front Tyre', carDetails.lhsFrontTyre),
          // buildExteriorItem('LHS Rear Alloy', carDetails.lhsRearAlloy),
          // buildExteriorItem('LHS Rear Tyre', carDetails.lhsRearTyre),
          // buildExteriorItem('LHS Front Door', carDetails.lhsFrontDoor),
          // buildExteriorItem('LHS Rear Door', carDetails.lhsRearDoor),
          // buildExteriorItem('LHS Running Border', carDetails.lhsRunningBorder),
          // // buildExteriorItem('LHS Quarter Panel', carDetails.lhsQuarterPanel),
          // buildExteriorItem('Rear Bumper', carDetails.rearBumper),
          // buildExteriorItem('LHS Tail Lamp', carDetails.lhsTailLamp),
          // buildExteriorItem('RHS Tail Lamp', carDetails.rhsTailLamp),
          // buildExteriorItem('Rear Windshield', carDetails.rearWindshield),
          // buildExteriorItem('Boot Door', carDetails.bootDoor),
          // buildExteriorItem('Spare Tyre', carDetails.spareTyre),
          // buildExteriorItem('Boot Floor', carDetails.bootFloor),
          // buildExteriorItem('RHS Rear Alloy', carDetails.rhsRearAlloy),
          // buildExteriorItem('RHS Rear Tyre', carDetails.rhsRearTyre),
          // buildExteriorItem('RHS Front Alloy', carDetails.rhsFrontAlloy),
          // buildExteriorItem('RHS Front Tyre', carDetails.rhsFrontTyre),
          // buildExteriorItem('RHS Quarter Panel', carDetails.rhsQuarterPanel),
          // buildExteriorItem('RHS A Pillar', carDetails.rhsAPillar),
          // buildExteriorItem('RHS B Pillar', carDetails.rhsBPillar),
          // buildExteriorItem('RHS C Pillar', carDetails.rhsCPillar),
          // buildExteriorItem('RHS Running Border', carDetails.rhsRunningBorder),
          // buildExteriorItem('RHS Rear Door', carDetails.rhsRearDoor),
          // buildExteriorItem('RHS Front Door', carDetails.rhsFrontDoor),
          // buildExteriorItem('RHS ORVM', carDetails.rhsOrvm),
          // buildExteriorItem('RHS Fender', carDetails.rhsFender, isLast: true),
          const SizedBox(height: 15),
          if (getxController.isValidComment(carDetails.comments))
            _buildCommentsCard(
              title: 'Comments',
              comment: carDetails.comments,
              icon: Icons.comment,
            ),
        ],
      ),
    );
  }

  Widget _buildBidButton(
    CarDetailsController getxController,
    HomeController homeController,
    BuildContext context,
    String currentOpenSection,
    CarsListModel car,
    Rx<String> remainingAuctionTime,
  ) {
    return currentOpenSection != homeController.defaultSectionScreen
        ? ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.5),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                border: Border(
                  top: BorderSide(
                    color: AppColors.green.withValues(alpha: 0.5),
                  ),
                  left: BorderSide(
                    color: AppColors.green.withValues(alpha: 0.5),
                  ),
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (currentOpenSection != homeController.otobuySectionScreen)
                    Obx(
                      () => Text(
                        // getxController.remainingTime.value,
                        remainingAuctionTime.value,
                        style: const TextStyle(
                          fontSize: 15,
                          color: AppColors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),

                  /// LOGIC: check if type is marketplace
                  if (currentOpenSection ==
                      homeController.marketplaceSectionScreen)
                    SizedBox(
                      width: double.infinity,
                      child: ButtonWidget(
                        text: 'Request for Auction',
                        onTap: () {
                          Get.dialog(
                            CongratulationsDialogWidget(
                              icon: Icons.assignment_turned_in_outlined,
                              iconSize: 25,
                              title: "Request Sent!",
                              message:
                                  "Your request to list this car in auction has been submitted.",
                              buttonText: "OK",
                              onButtonTap: () => Get.back(),
                            ),
                          );
                        },
                        isLoading: false.obs,
                        height: 35,
                        fontSize: 12,
                        elevation: 10,
                        backgroundColor: AppColors.blue,
                      ),
                    )
                  /// Show two buttons
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        PlaceBidButtonWidget(
                          currentOpenSection: currentOpenSection,
                          getxController: getxController,
                          remainingAuctionTime: widget.remainingAuctionTime,
                          priceDiscovery: car.priceDiscovery,
                          fixedMargin: car.fixedMargin,
                          variableMargin: car.variableMargin,
                        ),
                        StartAutoBidButtonWidget(
                          currentOpenSection: currentOpenSection,
                          carId: getxController.carId,
                          remainingAuctionTime: widget.remainingAuctionTime,
                          priceDiscovery: car.priceDiscovery,
                          fixedMargin: car.fixedMargin,
                          variableMargin: car.variableMargin,
                        ),
                      ],
                    ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        )
        : const SizedBox();
  }

  Widget _buildLoading() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Car image placeholder
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const ShimmerWidget(height: 200, width: double.infinity),
          ),
          const SizedBox(height: 20),

          // Title
          const ShimmerWidget(height: 16, width: 180),
          const SizedBox(height: 10),

          // Price + City
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              ShimmerWidget(height: 14, width: 100),
              ShimmerWidget(height: 14, width: 80),
            ],
          ),
          const SizedBox(height: 20),

          // Icon and text rows
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              ShimmerWidget(height: 12, width: 60),
              ShimmerWidget(height: 12, width: 60),
              ShimmerWidget(height: 12, width: 60),
              ShimmerWidget(height: 12, width: 60),
            ],
          ),
          const SizedBox(height: 30),

          // Section headers and content placeholders
          for (int i = 0; i < 3; i++) ...[
            const ShimmerWidget(height: 14, width: 120),
            const SizedBox(height: 10),
            const ShimmerWidget(height: 12, width: double.infinity),
            const SizedBox(height: 6),
            const ShimmerWidget(height: 12, width: double.infinity),
            const SizedBox(height: 6),
            const ShimmerWidget(height: 12, width: double.infinity),
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }

  Widget _buildStructuralAndUnderbody({required CarModel carDetails}) {
    Widget item({
      required IconData icon,
      required String label,
      required Widget trailing,
    }) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.black54),
            const SizedBox(width: 10),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
            trailing,
          ],
        ),
      );
    }

    Widget structuralFieldValue(String? value) {
      final status = value?.toLowerCase();

      if (status == 'available' || status == 'okay') {
        return Icon(Icons.check_circle, color: AppColors.green, size: 20);
      } else if (status == 'not applicable' || status == 'not available') {
        return Icon(Icons.cancel, color: AppColors.red, size: 20);
      } else {
        return Text(value.toString(), style: const TextStyle(fontSize: 13));
      }
    }

    return AccordionWidget(
      title: 'Structural & Underbody',
      icon: Icons.car_repair,
      contentSize: 300,
      content: Column(
        children: [
          item(
            icon: Icons.directions_car_outlined, // structure/frame
            label: 'Upper Cross Member',
            trailing: structuralFieldValue(carDetails.upperCrossMember),
          ),
          item(
            icon: Icons.directions_car_filled, // lower structure/frame
            label: 'Lower Cross Member',
            trailing: structuralFieldValue(carDetails.lowerCrossMember),
          ),
          item(
            icon: Icons.ac_unit, // radiator/cooling
            label: 'Radiator Support',
            trailing: structuralFieldValue(carDetails.radiatorSupport),
          ),
          item(
            icon: Icons.lightbulb_outline, // headlight indicator
            label: 'Headlight Support',
            trailing: structuralFieldValue(carDetails.headlightSupport),
          ),
          item(
            icon: Icons.swap_horizontal_circle_outlined, // left-hand structure
            label: 'LHS Apron',
            trailing: structuralFieldValue(carDetails.lhsApron),
          ),
          item(
            icon: Icons.swap_horizontal_circle, // right-hand structure
            label: 'RHS Apron',
            trailing: structuralFieldValue(carDetails.rhsApron),
          ),
          item(
            icon: Icons.shield_outlined, // firewall protection metaphor
            label: 'Firewall',
            trailing: structuralFieldValue(carDetails.firewall),
          ),
          item(
            icon: Icons.view_day, // dashboard-top style, metaphor for cowl top
            label: 'Cowl Top',
            trailing: structuralFieldValue(carDetails.cowlTop),
          ),
          item(
            icon: Icons.inventory_2_outlined, // flat structure, boot floor
            label: 'Boot Floor',
            trailing: structuralFieldValue(carDetails.bootFloor),
          ),
          // item(
          //   icon: Icons.inventory_2, // second boot floor
          //   label: 'Boot Floor 1',
          //   trailing: structuralFieldValue(carDetails.bootFloor1),
          // ),
          item(
            icon: Icons.circle_outlined, // spare tyre
            label: 'Spare Tyre',
            trailing: structuralFieldValue(carDetails.spareTyre),
          ),
          // item(
          //   icon: Icons.circle, // secondary spare tyre
          //   label: 'Spare Tyre 1',
          //   trailing: structuralFieldValue(carDetails.spareTyre1),
          // ),
        ],
      ),
    );
  }

  Widget _buildDashboardAndSeating({required CarModel carDetails}) {
    final imageItems = [
      {
        'label': 'Dashboard View',
        'path': carDetails.dashboardFromRearSeat[0],
        // 'path': AppImages.hondaDashboardView,
      },
      {
        'label': 'Front Seats View',
        'path': carDetails.frontSeatsFromDriverSideDoorOpen[0],
        // 'path': AppImages.hondaFrontSeatsView,
      },
      {
        'label': 'Rear Seats View',
        'path': carDetails.rearSeatsFromRightSideDoorOpen[0],
        // 'path': AppImages.hondaRearSeatsView,
      },
    ];

    Widget item({
      required IconData icon,
      required String label,
      required Widget trailing,
    }) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.black54),
            const SizedBox(width: 10),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
            trailing,
          ],
        ),
      );
    }

    Widget seatFieldValue(String? value) {
      final status = value?.toLowerCase();

      if (status == 'available' || status == 'okay') {
        return Icon(Icons.check_circle, color: AppColors.green, size: 20);
      } else if (status == 'not applicable' || status == 'not available') {
        return Icon(Icons.cancel, color: AppColors.red, size: 20);
      } else {
        return Text(value.toString(), style: const TextStyle(fontSize: 13));
      }
    }

    Widget imageCard({
      required String label,
      required String imageUrl,
      required int imageIndex,
    }) {
      return InkWell(
        onTap: () {
          final List<String> imageLabels = [
            'Dashboard View',
            'Front Seats View',
            'Rear Seats View',
          ];

          final List<String> dashboardAndSeatingImages = [
            carDetails.dashboardFromRearSeat[0],
            carDetails.frontSeatsFromDriverSideDoorOpen[0],
            carDetails.rearSeatsFromRightSideDoorOpen[0],
            // AppImages.hondaDashboardView,
            // AppImages.hondaFrontSeatsView,
            // AppImages.hondaRearSeatsView,
          ];
          Get.to(
            () => CarImagesPage(
              imageLabels: imageLabels,
              imageUrls: dashboardAndSeatingImages,
              initialIndex: imageIndex,
            ),
          );
        },
        borderRadius: BorderRadius.circular(5),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: AppColors.grey.withValues(alpha: .5)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: Column(
              children: [
                Expanded(
                  child:
                      imageUrl.isNotEmpty
                          ? CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            placeholder:
                                (context, url) => const Center(
                                  child: SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: AppColors.green,
                                      strokeWidth: 1,
                                    ),
                                  ),
                                ),
                            errorWidget:
                                (context, url, error) => const Icon(
                                  Icons.image_not_supported,
                                  size: 40,
                                  color: AppColors.grey,
                                ),
                            //   loadingBuilder: (context, child, loadingProgress) {
                            //     if (loadingProgress == null) {
                            //       return child;
                            //     }
                            //     return Center(
                            //       child: SizedBox(
                            //         height: 20,
                            //         width: 20,
                            //         child: CircularProgressIndicator(
                            //         value:
                            //             loadingProgress.expectedTotalBytes !=
                            //                     null
                            //                 ? loadingProgress
                            //                         .cumulativeBytesLoaded /
                            //                     loadingProgress
                            //                         .expectedTotalBytes!
                            //                 : null,

                            //         color: AppColors.green,
                            //         strokeWidth: 1,
                            //       ),
                            //     ),
                            //   );
                            // },
                            // errorBuilder: (context, error, stackTrace) {
                            //   return Icon(
                            //     Icons.image_not_supported,
                            //     size: 40,
                            //     color: AppColors.grey,
                            //   );
                            // },
                          )
                          : Container(
                            color: AppColors.grey.withValues(alpha: .2),
                            child: Icon(
                              Icons.image_not_supported,
                              size: 40,
                              color: AppColors.grey,
                            ),
                          ),
                ),
                Container(
                  width: double.infinity,
                  color: AppColors.grey.withValues(alpha: .5),
                  padding: EdgeInsets.symmetric(vertical: 6),

                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.white, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return AccordionWidget(
      title: 'Dashboard & Seating',
      icon: Icons.event_seat_outlined,
      // contentSize: 370,
      content: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            item(
              icon: Icons.chair_alt,
              label: 'Fabric Seats',
              trailing: seatFieldValue(carDetails.fabricSeats),
            ),
            item(
              icon: Icons.chair_outlined,
              label: 'Leather Seats',
              trailing: seatFieldValue(carDetails.leatherSeats),
            ),

            SizedBox(height: 10),
            Divider(color: AppColors.green.withValues(alpha: .3)),
            SizedBox(height: 10),

            /// Photo Grid
            GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: imageItems.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.1,
              ),
              itemBuilder: (context, index) {
                final item = imageItems[index];
                // return Text(item['label']!);
                return imageCard(
                  label: item['label']!,
                  imageUrl: item['path']!,
                  imageIndex: index,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminAndApprovalInfo({required CarModel carDetails}) {
    Widget item({
      required IconData icon,
      required Color color,
      required String label,
      required String value,
    }) {
      return Container(
        padding: EdgeInsets.only(left: 20, bottom: 15),
        child: Row(
          children: [
            Icon(icon, color: color, size: 25),
            SizedBox(width: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 8),
                Text(
                  value.isNotEmpty ? value : 'N/A',
                  style: TextStyle(fontSize: 13),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: AppColors.green),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.admin_panel_settings,
                size: 20,
                color: AppColors.blue.withValues(alpha: 0.7),
              ),
              SizedBox(width: 8),
              Text(
                'Admin & Approval Info',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.blue,
                ),
              ),
            ],
          ),
          Divider(color: AppColors.grey.withValues(alpha: 0.5)),
          SizedBox(height: 5),
          Column(
            children: [
              item(
                icon: Icons.verified_user,
                color: Colors.blue,
                label: 'Approved By',
                value:
                    carDetails.approvedBy.isNotEmpty
                        ? carDetails.approvedBy
                        : 'N/A',
              ),
              item(
                icon: Icons.date_range,
                color: Colors.green,
                label: 'Approval Date',
                value: carDetails.approvalDate.toString().split(' ').first,
              ),
              item(
                icon: Icons.access_time_filled,
                color: Colors.orange,
                label: 'Approval Time',
                value:
                    GlobalFunctions.getFormattedDate(
                      date: carDetails.approvalTime,
                      type: GlobalFunctions.time,
                    ) ??
                    'N/A',
              ),
              item(
                icon: Icons.check_circle_outline,
                color: Colors.purple,
                label: 'Approval Status',
                value: carDetails.approvalStatus,
              ),
              Divider(),
              SizedBox(height: 5),
              item(
                icon: Icons.price_change,
                color: Colors.indigo,
                label: 'Price Discovery',
                value:
                    'Rs. ${NumberFormat.decimalPattern().format(carDetails.priceDiscovery)}/-',
              ),
              item(
                icon: Icons.account_circle_outlined,
                color: Colors.teal,
                label: 'Price Discovery By',
                value: carDetails.priceDiscoveryBy,
              ),
              item(
                icon: Icons.person_pin_circle_outlined,
                color: Colors.deepOrange,
                label: 'Retail Associate',
                value: carDetails.retailAssociate,
              ),
              Divider(),
              SizedBox(height: 5),
              item(
                icon: Icons.phone_outlined,
                color: Colors.black87,
                label: 'Contact Number',
                value: carDetails.contactNumber.toString(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsCard({
    required String title,
    required String comment,
    required IconData icon,
  }) {
    if (comment.trim().isEmpty) return SizedBox();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: AppColors.grey.withValues(alpha: .3)),
        // boxShadow: [
        //   BoxShadow(
        //     color: AppColors.grey.withValues(alpha: .2),
        //     blurRadius: 6,
        //     offset: Offset(0, 3),
        //   ),
        // ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.green),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  comment,
                  style: const TextStyle(fontSize: 13, color: AppColors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageCardForSections({
    required String imageLabel,
    required String imageUrl,

    required int imageIndex,
    required List<String> imageLabels,
    required List<String> imageUrls,
  }) {
    return InkWell(
      onTap: () {
        Get.to(
          () => CarImagesPage(
            imageLabels: imageLabels,
            imageUrls: imageUrls,
            initialIndex: imageIndex,
          ),
        );
      },
      borderRadius: BorderRadius.circular(5),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: AppColors.grey.withValues(alpha: .5)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: Column(
            children: [
              Expanded(
                child:
                    imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          placeholder:
                              (context, url) => const Center(
                                child: SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: AppColors.green,
                                    strokeWidth: 1,
                                  ),
                                ),
                              ),
                          errorWidget:
                              (context, url, error) => const Icon(
                                Icons.image_not_supported,
                                size: 40,
                                color: AppColors.grey,
                              ),
                        )
                        : Container(
                          color: AppColors.grey.withValues(alpha: .2),
                          child: Icon(
                            Icons.image_not_supported,
                            size: 40,
                            color: AppColors.grey,
                          ),
                        ),
              ),
              Container(
                width: double.infinity,
                color: AppColors.grey.withValues(alpha: .5),
                padding: EdgeInsets.symmetric(vertical: 6),

                child: Text(
                  imageLabel,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.white, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStickyTabs(CarDetailsController getxController) {
    final sectionNames = [
      'Images',
      // 'Basic',
      'Documents',
      'Exterior',
      'Engine',
      'Suspension',
      'Interior',
      'AC',
    ];
    final keys = [
      CarDetailsController.imagesSectionKey,
      // CarDetailsController.basicDetailsSectionKey,
      CarDetailsController.documentDetailsSectionKey,
      CarDetailsController.exteriorSectionKey,
      CarDetailsController.engineBaySectionKey,
      CarDetailsController.steeringBrakesAndSuspensionSectionKey,
      CarDetailsController.interiorAndElectricalsSectionKey,
      CarDetailsController.airConditioningSectionKey,
    ];

    return
    // Obx(
    //   () =>
    Container(
      color: AppColors.white,
      height: 50,
      child: ListView.builder(
        controller: getxController.sectionTabScrollController,
        scrollDirection: Axis.horizontal,
        itemCount: sectionNames.length,
        itemBuilder: (_, i) {
          return Obx(() {
            final isSelected = getxController.currentSection.value == keys[i];
            return GestureDetector(
              onTap: () => getxController.scrollToSection(keys[i]),

              child: Container(
                key: getxController.sectionTabKeys[keys[i]],
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                margin: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  border:
                      isSelected
                          ? Border(
                            bottom: BorderSide(
                              color: AppColors.green,
                              width: 2,
                            ),
                          )
                          : null,
                ),
                child: Text(
                  sectionNames[i],
                  style: TextStyle(
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            );
          });
        },
      ),
      // ),
    );
  }

  // Side images
  Widget _buildSideImages({required List<String> imageUrls}) {
    return GestureDetector(
      onTap: () {
        Get.to(() => CarImagesPage(imageUrls: imageUrls, initialIndex: 0));
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: CachedNetworkImage(
          imageUrl: imageUrls.first,
          width: 35,
          placeholder:
              (context, url) => const Center(
                child: SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: AppColors.green,
                    strokeWidth: 1,
                  ),
                ),
              ),
          errorWidget:
              (context, url, error) => const Icon(
                Icons.image_not_supported,
                size: 40,
                color: AppColors.grey,
              ),
        ),
      ),
    );
  }
}

// Images Section
Widget _buildImagesSection({
  required CarModel car,
  required String currentOpenSection,
  required RxString remainingAuctionTime,
}) {
  final getxController = Get.find<CarDetailsController>();
  // 1) Per-section fallbacks (assets or CDN placeholders)
  final fallbackBySection = <String, String>{
    AppConstants.imagesSectionIds.exterior: AppImages.exteriorFallback,
    AppConstants.imagesSectionIds.interior: AppImages.interiorFallback,
    AppConstants.imagesSectionIds.engine: AppImages.engineFallback,
    AppConstants.imagesSectionIds.tyres: AppImages.tyreFallback,
    AppConstants.imagesSectionIds.damages: AppImages.damagesFallback,
    // AppConstants.imagesSectionIds.suspension: AppImages.suspensionFallback,
    // AppConstants.imagesSectionIds.ac: AppImages.acFallback,
  };

  // 2) Your items, using your picker (primary → alts → fallback)
  final imageSections = <Map<String, String>>[
    {
      'id': AppConstants.imagesSectionIds.exterior,
      'title': 'Exterior',
      'thumb': getxController.pickImageForImagesSection(
        car.bonnetImages,
        // try other related sets if bonnet is empty:
        alts: [car.apronLhsRhs, car.airbags],
        fallbackUrl: AppImages.exteriorFallback,
      ),
    },
    {
      'id': AppConstants.imagesSectionIds.interior,
      'title': 'Interior',
      'thumb': getxController.pickImageForImagesSection(
        car.airbags,
        fallbackUrl: AppImages.interiorFallback,
      ),
    },
    {
      'id': AppConstants.imagesSectionIds.engine,
      'title': 'Engine',
      'thumb': getxController.pickImageForImagesSection(
        car.apronLhsRhs,
        fallbackUrl: AppImages.engineFallback,
      ),
    },
    {
      'id': AppConstants.imagesSectionIds.tyres,
      'title': 'Tyres',
      'thumb': AppImages.tyreFallback,
    },

    // {
    //   'id': AppConstants.imagesSectionIds.suspension,
    //   'title': 'Suspension',
    //   'thumb': AppImages.suspensionFallback,
    // },
    {
      'id': AppConstants.imagesSectionIds.damages,
      'title': 'Damages',
      'thumb': AppImages.damagesFallback,
    },
  ];

  return SizedBox(
    height: 120, // taller row to fit the image tiles nicely
    child: ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 10),
      scrollDirection: Axis.horizontal,
      itemCount: imageSections.length,
      separatorBuilder: (_, __) => const SizedBox(width: 10),
      itemBuilder: (_, index) {
        final section = imageSections[index];
        final title = section['title'] ?? '';
        final thumb = section['thumb'] ?? '';
        final sectionId = section['id'] ?? '';
        final alternativeImage = fallbackBySection[sectionId]!;

        return InkWell(
          onTap: () {
            Get.to(
              () => CarImagesGalleryPage(
                car: car,
                initialSectionId: sectionId,
                initialSectionIndex: index,
                currentOpenSection: currentOpenSection,
                remainingAuctionTime: remainingAuctionTime,
              ),

              // arguments: {'sectionId': id},
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            width: 120, // a bit wider to let the title breathe
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  // Image
                  Positioned.fill(
                    child: CachedNetworkImage(
                      imageUrl: thumb,
                      fit: BoxFit.cover,
                      placeholder:
                          (_, __) => Shimmer.fromColors(
                            baseColor: const Color(0xFFE5E7EB),
                            highlightColor: const Color(0xFFF3F4F6),
                            child: Container(color: const Color(0xFFE5E7EB)),
                          ),
                      errorWidget:
                          (_, __, ___) =>
                              Image.asset(alternativeImage, fit: BoxFit.cover),
                    ),
                  ),

                  // Bottom gradient (softens image behind blur bar)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: 56,
                    child: IgnorePointer(
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0x00000000),
                              Color(0x55000000),
                              Color(0x77000000),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Blurred title bar
                  Positioned(
                    left: 8,
                    right: 8,
                    bottom: 8,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xAA111111,
                            ), // translucent dark glass
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.18),
                            ),
                          ),
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}

class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  _StickyHeaderDelegate({required this.child, this.height = 60});

  @override
  Widget build(context, shrinkOffset, overlapsContent) => child;

  @override
  double get maxExtent => height;

  @override
  double get minExtent => height;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      true;
}
