import 'package:flutter/material.dart';
import 'package:otobix/Utils/app_colors.dart';

class EmptyDataWidget extends StatelessWidget {
  final String message;
  final IconData icon;
  final double iconSize;
  final double fontSize;

  const EmptyDataWidget({
    super.key,
    this.message = 'No data found.',
    this.icon = Icons.search_off_rounded,
    this.iconSize = 50,
    this.fontSize = 14,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: iconSize, color: AppColors.grey),
          const SizedBox(height: 10),
          Text(
            message,
            style: TextStyle(fontSize: fontSize, color: AppColors.grey),
          ),
        ],
      ),
    );
  }
}
