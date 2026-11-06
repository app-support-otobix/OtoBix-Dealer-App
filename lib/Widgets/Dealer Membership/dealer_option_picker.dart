import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:otobix/Utils/app_colors.dart';

void showDealerOptionPicker(
  BuildContext context, {
  required String title,
  required RxList<String> options,
  required void Function(String value) onSelect,
  RxBool? isLoading,
  void Function(String query)? onSearch,
  // Offers what was typed when no option matches it exactly (e.g. a town
  // missing from a city list).
  bool allowTyped = false,
}) {
  FocusManager.instance.primaryFocus?.unfocus();
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder:
        (_) => _DealerOptionPickerSheet(
          title: title,
          options: options,
          onSelect: onSelect,
          isLoading: isLoading,
          onSearch: onSearch,
          allowTyped: allowTyped,
        ),
  );
}

class _DealerOptionPickerSheet extends StatefulWidget {
  final String title;
  final RxList<String> options;
  final void Function(String value) onSelect;
  final RxBool? isLoading;
  final void Function(String query)? onSearch;
  final bool allowTyped;

  const _DealerOptionPickerSheet({
    required this.title,
    required this.options,
    required this.onSelect,
    this.isLoading,
    this.onSearch,
    this.allowTyped = false,
  });

  @override
  State<_DealerOptionPickerSheet> createState() =>
      _DealerOptionPickerSheetState();
}

class _DealerOptionPickerSheetState extends State<_DealerOptionPickerSheet> {
  final searchController = TextEditingController();
  final query = ''.obs;

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final onSearch = widget.onSearch;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.65,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 45,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.grey.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 4, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: searchController,
                onChanged: (v) {
                  query.value = v.trim().toLowerCase();
                  onSearch?.call(v);
                },
                decoration: InputDecoration(
                  hintText: 'Search...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Obx(() {
                final all = widget.options.toList();
                final filtered =
                    query.value.isEmpty || onSearch != null
                        ? all
                        : all
                            .where((e) => e.toLowerCase().contains(query.value))
                            .toList();
                if ((widget.isLoading?.value ?? false) && all.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.green),
                  );
                }
                final typed = searchController.text.trim();
                final offerTyped =
                    widget.allowTyped &&
                    typed.isNotEmpty &&
                    !all.any((e) => e.toLowerCase() == query.value);
                if (filtered.isEmpty && !offerTyped) {
                  return const Center(
                    child: Text(
                      'No results found',
                      style: TextStyle(fontSize: 12, color: AppColors.grey),
                    ),
                  );
                }
                // The typed name comes last, so the matches are seen first.
                return ListView.separated(
                  itemCount: filtered.length + (offerTyped ? 1 : 0),
                  separatorBuilder:
                      (_, __) => Divider(
                        height: 1,
                        color: AppColors.grey.withValues(alpha: 0.25),
                      ),
                  itemBuilder: (_, i) {
                    if (i == filtered.length) {
                      return ListTile(
                        dense: true,
                        leading: const Icon(
                          Icons.edit_location_alt_outlined,
                          size: 20,
                          color: AppColors.green,
                        ),
                        title: Text(
                          'Use "$typed"',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: const Text(
                          'Not in the list',
                          style: TextStyle(fontSize: 11),
                        ),
                        onTap: () {
                          widget.onSelect(typed);
                          Navigator.pop(context);
                        },
                      );
                    }
                    final option = filtered[i];
                    return ListTile(
                      dense: true,
                      title: Text(option, style: const TextStyle(fontSize: 13)),
                      onTap: () {
                        widget.onSelect(option);
                        Navigator.pop(context);
                      },
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class DealerPickerField extends StatelessWidget {
  final String label;
  final String hintText;
  final String? value;
  final bool enabled;
  final bool isLoading;
  final VoidCallback onTap;

  const DealerPickerField({
    super.key,
    required this.label,
    required this.hintText,
    required this.value,
    required this.onTap,
    this.enabled = true,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null && value!.trim().isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppColors.black,
          ),
        ),
        const SizedBox(height: 6),
        Opacity(
          opacity: enabled ? 1 : 0.45,
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.grey.withValues(alpha: 0.6),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      hasValue ? value! : hintText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: hasValue ? AppColors.black : AppColors.grey,
                      ),
                    ),
                  ),
                  if (isLoading) ...[
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 8),
                  ],
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: AppColors.grey,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
