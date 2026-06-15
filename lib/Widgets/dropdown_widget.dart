import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:otobix/Utils/app_colors.dart';

class DropdownWidget extends StatelessWidget {
  final String label;
  final bool isRequired;
  final String? selectedValue;
  final String hintText;
  final IconData prefixIcon;
  final List<String>? items;
  final ValueChanged<String?>? onChanged;
  final bool giveSpaceToBottom;

  /// true → uses custom picker dialog
  /// false → uses DropdownButtonFormField
  final bool useCustomPicker;

  final double height;
  final double dialogMaxWidth;

  const DropdownWidget({
    super.key,
    required this.label,
    this.isRequired = false,
    this.selectedValue,
    required this.hintText,
    required this.prefixIcon,
    this.items,
    this.onChanged,
    this.useCustomPicker = true,
    this.height = 40,
    this.dialogMaxWidth = 300,
    this.giveSpaceToBottom = true,
    required String? Function(dynamic value) validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(),
        const SizedBox(height: 5),
        useCustomPicker
            ? GestureDetector(
              onTap: () {
                _showPickerDialog(context);
              },
              child: Container(
                height: height,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(color: AppColors.grey, width: 1.0),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      prefixIcon,
                      size: 15,
                      color: AppColors.grey.withValues(alpha: .5),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        selectedValue ?? hintText,
                        style: TextStyle(
                          color:
                              selectedValue == null
                                  ? AppColors.grey.withValues(alpha: .5)
                                  : AppColors.black,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.arrow_drop_down,
                      color: AppColors.grey,
                      size: 20,
                    ),
                  ],
                ),
              ),
            )
            : SizedBox(
              height: height,
              child: DropdownButtonFormField<String>(
                value: selectedValue,
                items:
                    items
                        ?.map(
                          (e) => DropdownMenuItem(
                            value: e,
                            child: Text(
                              e,
                              style: TextStyle(
                                color: AppColors.black,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                onChanged: onChanged,
                borderRadius: BorderRadius.circular(15),
                decoration: InputDecoration(
                  prefixIcon: Icon(
                    prefixIcon,
                    color: AppColors.grey.withValues(alpha: .5),
                    size: 15,
                  ),
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 20,
                    minHeight: 20,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                  hintText: hintText,
                  hintStyle: TextStyle(
                    color: AppColors.grey.withValues(alpha: .5),
                    fontSize: 12,
                  ),
                  border: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: AppColors.grey.withValues(alpha: .5),
                    ),
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: AppColors.grey.withValues(alpha: .5),
                    ),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.green, width: 1.5),
                  ),
                ),
                style: TextStyle(color: AppColors.black, fontSize: 12),
              ),
            ),
        if (giveSpaceToBottom) SizedBox(height: 30),
      ],
    );
  }

  /// Builds the label with optional * indicator
  Widget _buildLabel() {
    return RichText(
      text: TextSpan(
        text: label,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
          color: AppColors.grey,
        ),
        children:
            isRequired
                ? [
                  TextSpan(
                    text: ' *',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ]
                : [],
      ),
    );
  }

  /// Shows a centered dialog with selectable items
  void _showPickerDialog(BuildContext context) {
    if (items == null || items!.isEmpty) return;

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Container(
          constraints: BoxConstraints(maxHeight: 400, maxWidth: dialogMaxWidth),
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 12),
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: items!.length,
            separatorBuilder: (_, __) => const SizedBox(),
            itemBuilder: (context, index) {
              final item = items![index];
              return ListTile(
                leading: Icon(prefixIcon, color: AppColors.grey, size: 20),
                title: Text(
                  item,
                  style: TextStyle(color: AppColors.black, fontSize: 14),
                ),
                onTap: () {
                  onChanged?.call(item);
                  Get.back();
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
