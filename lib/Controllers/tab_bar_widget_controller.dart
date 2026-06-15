import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TabBarWidgetController extends GetxController
    with GetSingleTickerProviderStateMixin {
  late TabController tabController;
  var selectedIndex = 0.obs;

  /// titles length passed into the controller
  final int tabLength;

  TabBarWidgetController({required this.tabLength});
  // dummy for now
  setSelectedTab(int index) {
    tabController.animateTo(index);
    selectedIndex.value = index;
  }

  @override
  void onInit() {
    tabController = TabController(length: tabLength, vsync: this);
    tabController.addListener(_handleTabChange);
    super.onInit();
  }

  void _handleTabChange() {
    selectedIndex.value = tabController.index;
  }

  @override
  void onClose() {
    tabController.dispose();
    super.onClose();
  }
}
