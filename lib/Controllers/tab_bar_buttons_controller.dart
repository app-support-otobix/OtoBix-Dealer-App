import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TabBarButtonsController extends GetxController
    with GetSingleTickerProviderStateMixin {
  late TabController tabController;
  var selectedIndex = 0.obs;

  /// titles length passed into the controller
  final int? tabLength;
  final int initialIndex;

  TabBarButtonsController({this.tabLength, this.initialIndex = 0});

  // dummy for now
  setSelectedTab(int index) {
    tabController.animateTo(index);
    selectedIndex.value = index;
  }

  @override
  void onInit() {
    tabController = TabController(
      length: tabLength!,
      vsync: this,
      initialIndex: initialIndex,
    );
    selectedIndex.value = initialIndex;
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
