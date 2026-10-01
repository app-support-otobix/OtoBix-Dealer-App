import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:otobix/Controllers/Dealer%20Membership/dealer_membership_controller.dart';
import 'package:otobix/Utils/app_colors.dart';

/// Distance from my showroom to the seller's, coloured by how far it is:
/// under 20 km green, 20–50 km yellow, over 50 km red.
class DistanceBadge extends StatelessWidget {
  final double km;
  const DistanceBadge({super.key, required this.km});

  static const _darkYellow = Color(0xFF9A6B00); // readable on the light tint

  @override
  Widget build(BuildContext context) {
    final (tint, text) =
        km < 20
            ? (AppColors.green, AppColors.green)
            : km <= 50
            ? (AppColors.yellow, _darkYellow)
            : (AppColors.red, AppColors.red);
    final label = km < 10 ? km.toStringAsFixed(1) : km.round().toString();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.place, size: 11, color: text),
          const SizedBox(width: 2),
          Text(
            '$label km away',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: text,
            ),
          ),
        ],
      ),
    );
  }
}

/// The dealer's showroom location: whether it is set, and a button that reads
/// the phone GPS. [promptOnly] shows nothing once it is set (for Find Cars).
class ShowroomLocationCard extends StatelessWidget {
  final bool promptOnly;
  final VoidCallback? onSaved;
  const ShowroomLocationCard({super.key, this.promptOnly = false, this.onSaved});

  @override
  Widget build(BuildContext context) {
    final controller = DealerMembershipController.to;
    return Obx(() {
      final m = controller.membership.value;
      final isSet = m?.hasShowroomLocation ?? false;
      if (promptOnly && (m == null || isSet)) return const SizedBox.shrink();
      return Container(
        margin: promptOnly ? const EdgeInsets.only(bottom: 10) : null,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: (isSet ? AppColors.green : AppColors.blue).withValues(
            alpha: 0.07,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: (isSet ? AppColors.green : AppColors.blue).withValues(
              alpha: 0.25,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSet ? Icons.where_to_vote : Icons.add_location_alt_outlined,
              color: isSet ? AppColors.green : AppColors.blue,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isSet
                        ? 'Showroom location set'
                        : 'See how far each car is from you',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isSet
                        ? 'Updated ${DateFormat('d MMM yyyy').format(m!.showroomLocationAt?.toLocal() ?? DateTime.now())} · tap Update while at your showroom to change it'
                        : 'Set your showroom location while you are at your showroom. Other dealers never see it, only the distance.',
                    style: const TextStyle(fontSize: 11, color: AppColors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            controller.isLocating.value
                ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                : TextButton(
                  onPressed: () async {
                    if (await controller.setShowroomLocation()) onSaved?.call();
                  },
                  child: Text(isSet ? 'Update' : 'Use my location'),
                ),
          ],
        ),
      );
    });
  }
}
