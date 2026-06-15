import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:otobix/Views/Dealer%20Panel/account_page.dart';
import 'package:otobix/Views/Dealer%20Panel/add_ons_page.dart';
import 'package:otobix/Views/Dealer%20Panel/home_page.dart';
import 'package:otobix/Views/Dealer%20Panel/my_cars_page.dart';

class BottomNavigationController extends GetxController {
  RxInt currentIndex = 0.obs;

  final List<Widget> pages = [
    HomePage(),
    MyCarsPage(),
    // OrdersPage(),
    AddOnsPage(),
    AccountPage(),
  ];
}
