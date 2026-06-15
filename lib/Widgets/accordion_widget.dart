import 'package:flutter/material.dart';
import 'package:accordion/accordion.dart';
import 'package:otobix/Utils/app_colors.dart';

class AccordionWidget extends StatelessWidget {
  final String title;
  final Widget content;
  final bool initiallyExpanded;
  final IconData icon;
  final Color? headerColor;
  final Color? iconColor;
  final double? contentSize;

  const AccordionWidget({
    super.key,
    required this.title,
    required this.content,
    this.initiallyExpanded = true,
    this.icon = Icons.article_outlined,
    this.headerColor,
    this.iconColor,
    this.contentSize,
  });

  @override
  Widget build(BuildContext context) {
    return Accordion(
      disableScrolling: true,
      maxOpenSections: 1,
      paddingListHorizontal: 0,
      headerBackgroundColor:
          headerColor ?? AppColors.blue.withValues(alpha: 0.1),
      headerBackgroundColorOpened: AppColors.green.withValues(alpha: 0.1),
      contentBorderColor: AppColors.green.withValues(alpha: 0.2),
      headerPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
      scaleWhenAnimating: true,
      openAndCloseAnimation: true,
      paddingListTop: 0,
      paddingListBottom: 0,

      children: [
        AccordionSection(
          isOpen: initiallyExpanded,
          leftIcon: Icon(icon, color: iconColor ?? AppColors.green),
          header: Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          content:
              // contentSize == null ?
              content,
          // : SizedBox(
          //   height: contentSize,
          //   child: SingleChildScrollView(child: content),
          // ),
          contentHorizontalPadding: 15,
          contentVerticalPadding: 12,

          rightIcon: const Icon(
            Icons.keyboard_arrow_down,
            color: AppColors.green,
          ),

          //////////// ✅ Disable collapse interaction /////////////////
          // headerBackgroundColor:
          //     headerColor ?? AppColors.blue.withValues(alpha: 0.1),
          // headerBackgroundColorOpened: AppColors.green.withValues(alpha: 0.1),
          // contentBorderColor: AppColors.green.withValues(alpha: 0.2),
          // rightIcon: const SizedBox.shrink(), // removes toggle arrow
          // onOpenSection: () {}, // do nothing
          // onCloseSection: () {}, // prevent closing
          //////////////////////////////////////////////////
        ),
      ],
    );
  }
}
