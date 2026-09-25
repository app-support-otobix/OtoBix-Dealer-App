import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:otobix/Views/Dealer%20Membership/dealer_home_page.dart';
import 'package:otobix/Views/Dealer%20Panel/profile_page.dart';
import 'package:otobix/Views/Dealer%20Panel/add_ons_page.dart';
import 'package:otobix/Views/Dealer%20Panel/home_page.dart';
import 'package:otobix/Views/Dealer%20Panel/my_cars_page.dart';

class BottomNavigationController extends GetxController {
  RxInt currentIndex = 0.obs;

  // The auction screens (Upcoming / Live / OtoBuy / PD), opened from Buy >
  // Auctions. Built here, before the tabs, so their controllers exist from
  // the start as other screens (My Cars, car details) expect.
  final HomePage auctionsPage = HomePage();

  final List<Widget> pages = [
    const DealerHomePage(),
    MyCarsPage(),
    // OrdersPage(),
    AddOnsPage(),
    ProfilePage(),
  ];
}
