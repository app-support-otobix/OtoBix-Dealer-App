import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:otobix/Utils/app_colors.dart';
import 'package:otobix/Widgets/tab_bar_widget.dart';

class TabBarButtonsWidget extends StatelessWidget {
  final List<String> titles;
  final List<int> counts;
  final double titleSize;
  final double countSize;
  final double tabsHeight;
  final double spaceFromSides;
  final TabController controller;
  final RxInt selectedIndex;

  const TabBarButtonsWidget({
    super.key,
    required this.titles,
    required this.counts,
    required this.controller,
    required this.selectedIndex,
    this.titleSize = 12,
    this.countSize = 10,
    this.tabsHeight = 35,
    this.spaceFromSides = 15,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(50)),
        child: Container(
          height: tabsHeight,
          margin: EdgeInsets.symmetric(horizontal: spaceFromSides),
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(50)),
            color: AppColors.grey.withValues(alpha: .2),
          ),

          ///////////// From here i changed ///////////////////
          // child: Container(
          //   padding: EdgeInsets.symmetric(horizontal: 4),
          //   child: Row(
          //     mainAxisAlignment: MainAxisAlignment.center,
          //     children: List.generate(titles.length, (index) {
          //       final isSelected = selectedIndex.value == index;
          //       return GestureDetector(
          //         onTap: () {
          //           selectedIndex.value = index;
          //           controller.animateTo(index);
          //         },
          //         child: Container(
          //           // margin: const EdgeInsets.symmetric(horizontal: 4),
          //           padding: const EdgeInsets.symmetric(
          //             horizontal: 12,
          //             vertical: 6,
          //           ),
          //           decoration: BoxDecoration(
          //             color: isSelected ? AppColors.green : Colors.transparent,
          //             borderRadius: BorderRadius.circular(50),
          //           ),
          //           child: Row(
          //             mainAxisSize: MainAxisSize.min,
          //             children: [
          //               Text(
          //                 titles[index],
          //                 style: TextStyle(
          //                   fontSize: titleSize,
          //                   color: isSelected ? Colors.white : AppColors.black,
          //                 ),
          //               ),
          //               if (counts[index] > 0)
          //                 Container(
          //                   margin: const EdgeInsets.only(left: 5),
          //                   padding: const EdgeInsets.all(5),
          //                   decoration: BoxDecoration(
          //                     color:
          //                         isSelected
          //                             ? AppColors.blue
          //                             : AppColors.grey.withValues(alpha: .5),
          //                     shape: BoxShape.circle,
          //                   ),
          //                   child: Text(
          //                     counts[index] > 99
          //                         ? '99+'
          //                         : counts[index].toString(),
          //                     style: TextStyle(
          //                       color:
          //                           isSelected
          //                               ? AppColors.white
          //                               : AppColors.black,
          //                       fontSize: countSize,
          //                     ),
          //                   ),
          //                 ),
          //             ],
          //           ),
          //         ),
          //       );
          //     }),
          //   ),
          // ),
          child: TabBar(
            controller: controller,
            // isScrollable: true,
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            indicator: const BoxDecoration(
              color: AppColors.green,
              borderRadius: BorderRadius.all(Radius.circular(50)),
            ),
            labelPadding: EdgeInsets.symmetric(horizontal: 8),
            tabAlignment: TabAlignment.center,

            tabs: List.generate(
              titles.length,
              (index) => TabItem(
                title: titles[index],
                count: counts[index],
                selected: selectedIndex.value == index,
                titleSize: titleSize,
                countSize: countSize,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
