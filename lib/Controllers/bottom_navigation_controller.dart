import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:otobix/Views/Dealer%20Membership/dealer_home_page.dart';
import 'package:otobix/Views/Dealer%20Panel/profile_page.dart';
import 'package:otobix/Views/Dealer%20Panel/home_page.dart';
import 'package:otobix/Views/Dealer%20Panel/my_cars_page.dart';

class BottomNavigationController extends GetxController {
  RxInt currentIndex = 0.obs;

  final HomePage auctionsPage = HomePage();

  final List<Widget> pages = [
    const DealerHomePage(),
    MyCarsPage(),
    // OrdersPage(),
    // AddOnsPage(), // its services are on Dealer Home now
    ProfilePage(),
  ];
}
