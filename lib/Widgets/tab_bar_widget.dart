import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:otobix/Controllers/tab_bar_widget_controller.dart';
import 'package:otobix/Utils/app_colors.dart';

class TabBarWidget extends StatelessWidget {
  final List<String> titles;
  final List<int> counts;
  final List<Widget> screens;
  final double titleSize;
  final double countSize;
  final double tabsHeight;
  final double spaceFromSides;
  final bool showCount;

  /// Tag so that we can find which tab bar widget is used where like home, my cars, etc.
  final String? controllerTag;

  const TabBarWidget({
    super.key,
    required this.titles,
    required this.counts,
    required this.screens,
    this.titleSize = 12,
    this.countSize = 10,
    this.tabsHeight = 35,
    this.spaceFromSides = 15,
    this.showCount = true,
    this.controllerTag,
  });

  @override
  Widget build(BuildContext context) {
    // tag to tell the controller that which screen's tabs length it is
    final tag = (key ?? UniqueKey()).toString();

    final tabController = Get.put(
      TabBarWidgetController(tabLength: titles.length),
      tag: controllerTag ?? tag,
    );

    return Obx(
      () => Column(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(50)),
            child: Container(
              height: tabsHeight,
              margin: EdgeInsets.symmetric(horizontal: spaceFromSides),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.all(Radius.circular(50)),
                color: AppColors.grey.withValues(alpha: .2),
              ),
              child: TabBar(
                controller: tabController.tabController,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                indicator: const BoxDecoration(
                  color: AppColors.green,
                  borderRadius: BorderRadius.all(Radius.circular(50)),
                ),
                tabs: List.generate(
                  titles.length,
                  (index) => TabItem(
                    title: titles[index],
                    count: counts[index],
                    selected: tabController.selectedIndex.value == index,
                    titleSize: titleSize,
                    countSize: countSize,
                    showCount: showCount,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: TabBarView(
              controller: tabController.tabController,
              children: screens,
            ),
          ),
        ],
      ),
    );
  }
}

class TabItem extends StatelessWidget {
  final String title;
  final int count;
  final bool selected;
  final double titleSize;
  final double countSize;
  final bool showCount;

  const TabItem({
    super.key,
    required this.title,
    required this.count,
    required this.selected,
    this.titleSize = 12,
    this.countSize = 10,
    this.showCount = true,
  });

  @override
  Widget build(BuildContext context) {
    final titleColor = selected ? AppColors.white : AppColors.black;
    final badgeBg =
        selected ? AppColors.blue : AppColors.grey.withValues(alpha: .5);
    final badgeTextColor = selected ? AppColors.white : AppColors.black;

    return Tab(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: titleSize, color: titleColor),
          ),
          // if (count > 0)
          if (showCount)
            Container(
              margin: const EdgeInsetsDirectional.only(start: 5),
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(color: badgeBg, shape: BoxShape.circle),
              child: Text(
                count > 99
                    ? '99+'
                    : count < 10
                    ? '0${count.toString()}'
                    : count.toString(),
                style: TextStyle(color: badgeTextColor, fontSize: countSize),
              ),
            ),
        ],
      ),
    );
  }
}
