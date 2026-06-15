import 'package:flutter/material.dart';
import 'package:otobix/Utils/app_colors.dart';

class SearchBarWidget extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final String hintText;
  final double height;
  final double fontSize;
  final double iconSize;
  final EdgeInsetsGeometry contentPadding;

  const SearchBarWidget({
    super.key,
    required this.controller,
    this.onChanged,
    this.hintText = 'Search...',
    this.height = 35,
    this.fontSize = 12,
    this.iconSize = 20,
    this.contentPadding = const EdgeInsets.symmetric(
      vertical: 3,
      horizontal: 10,
    ),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.text,
        style: TextStyle(fontSize: fontSize),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: AppColors.grey.withOpacity(0.5),
            fontSize: fontSize,
          ),
          prefixIcon: Icon(Icons.search, color: AppColors.grey, size: iconSize),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(100),
            borderSide: const BorderSide(color: AppColors.black),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(100),
            borderSide: const BorderSide(color: AppColors.green, width: 2),
          ),
          contentPadding: contentPadding,
        ),
        onChanged: onChanged,
      ),
    );
  }
}
