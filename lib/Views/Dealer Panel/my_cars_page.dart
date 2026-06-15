import 'package:flutter/material.dart';
import 'package:otobix/Controllers/home_controller.dart';
import 'package:otobix/Controllers/my_bids_controller.dart';
import 'package:otobix/Controllers/my_cars_controller.dart';
import 'package:otobix/Controllers/purchased_cars_controller.dart';
import 'package:otobix/Controllers/wishlist_controller.dart';
import 'package:otobix/Utils/app_colors.dart';
import 'package:otobix/Utils/app_constants.dart';
import 'package:otobix/Views/Dealer%20Panel/purchased_cars_page.dart';
import 'package:otobix/Views/Dealer%20Panel/my_bids_page.dart';
import 'package:otobix/Views/Dealer%20Panel/user_notifications_page.dart';
import 'package:otobix/Views/Dealer%20Panel/wishlist_page.dart';
import 'package:otobix/Widgets/tab_bar_widget.dart';
import 'package:get/get.dart';

class MyCarsPage extends StatelessWidget {
  MyCarsPage({super.key});

  final MyCarsController getxController = Get.put(MyCarsController());
  final HomeController homeController = Get.find<HomeController>();

  // WishlistController for getting realtime wishlist length
  final WishlistController wishlist = Get.put(
    WishlistController(),
    permanent: true,
  );

  // PurchasedCarsController for getting realtime purchased cars length
  final PurchasedCarsController purchasedCars = Get.put(
    PurchasedCarsController(),
    permanent: true,
  );

  // MyBidsController for getting realtime my bids length
  final MyBidsController myBids = Get.put(MyBidsController(), permanent: true);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 20),
            _buildSearchBar(context),
            SizedBox(height: 20),

            Expanded(
              child: Obx(() {
                //  Lengths of each tab
                final myBidsCarsLength = myBids.myBidCarsIds.length;
                final purchasedCarsLength =
                    purchasedCars.purchasedCarsIds.length;
                final wishlistCarsLength = wishlist.wishlistCarsIds.length;

                return TabBarWidget(
                  controllerTag:
                      AppConstants.tabBarWidgetControllerTags.myCarsTabs,
                  titles: ['My Bids', 'Purchased', 'Wishlist'],
                  counts: [
                    myBidsCarsLength,
                    purchasedCarsLength,
                    wishlistCarsLength,
                  ],
                  screens: [MyBidsPage(), PurchasedCarsPage(), WishlistPage()],
                  titleSize: 10,
                  countSize: 8,
                  spaceFromSides: 10,
                  tabsHeight: 30,
                );
              }),
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
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: () => Get.to(() => UserNotificationsPage()),
            child: Badge.count(
              count: homeController.unreadNotificationsCount.value,
              child: Icon(
                Icons.notifications_outlined,
                size: 25,
                color: AppColors.grey,
              ),
            ),
          ),
          SizedBox(width: 15),
        ],
      ),
    );
  }
}
