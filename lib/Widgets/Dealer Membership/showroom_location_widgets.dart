import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:otobix/Controllers/Dealer%20Membership/dealer_membership_controller.dart';
import 'package:otobix/Controllers/Dealer%20Membership/dealer_profile_update_controller.dart';
import 'package:otobix/Models/place_model.dart';
import 'package:otobix/Utils/app_colors.dart';
import 'package:otobix/Widgets/address_search_field.dart';

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
  const ShowroomLocationCard({
    super.key,
    this.promptOnly = false,
    this.onSaved,
  });

  @override
  Widget build(BuildContext context) {
    final membership = DealerMembershipController.to.membership;
    final controller = DealerProfileUpdateController.to;
    return Obx(() {
      final m = membership.value;
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
                        ? 'Updated ${DateFormat('d MMM yyyy').format(m!.showroomLocationAt?.toLocal() ?? DateTime.now())} · tap Update to change it'
                        : 'Search your showroom address, or use your location while at the showroom. Other dealers never see it, only the distance.',
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
                    if (await _ShowroomLocationSheet.show() == true) {
                      onSaved?.call();
                    }
                  },
                  child: Text(isSet ? 'Update' : 'Set location'),
                ),
          ],
        ),
      );
    });
  }
}

/// Asks a dealer who has no showroom location yet (enrolled before registration
/// asked for the address) to set one, when Dealer Home opens. Closes with true
/// once one is saved; Later asks again the next time the app opens.
Future<bool?> askForShowroomLocation() =>
    _ShowroomLocationSheet.show(asking: true);

/// Two ways to set the showroom location: search its address, or read the
/// phone GPS while at the showroom. Closes with true once one is saved.
class _ShowroomLocationSheet extends StatefulWidget {
  /// Opened by the app rather than by the dealer: says why, and offers Later.
  final bool asking;
  const _ShowroomLocationSheet({this.asking = false});

  // GetX already lifts the sheet above the keyboard. ignoreSafeArea: false
  // keeps the status bar's height in MediaQuery for the cap in build().
  static Future<bool?> show({bool asking = false}) => Get.bottomSheet<bool>(
    _ShowroomLocationSheet(asking: asking),
    isScrollControlled: true,
    ignoreSafeArea: false,
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
  );

  @override
  State<_ShowroomLocationSheet> createState() => _ShowroomLocationSheetState();
}

class _ShowroomLocationSheetState extends State<_ShowroomLocationSheet> {
  final _address = TextEditingController();
  final _controller = DealerProfileUpdateController.to;

  @override
  void dispose() {
    _address.dispose();
    super.dispose();
  }

  Future<void> _save({PlaceDetailsModel? place}) async {
    final saved = await _controller.setShowroomLocation(place: place);
    if (saved && mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        // However many suggestions show, the sheet stops below the status
        // bar and scrolls instead.
        constraints: BoxConstraints(
          maxHeight:
              media.size.height -
              media.viewInsets.bottom -
              media.padding.top -
              48,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.asking
                    ? 'Add your showroom location'
                    : 'Set your showroom location',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.asking
                    ? 'Distances now come from Google Maps. Search your '
                        "showroom's address so other dealers' cars show "
                        'exactly how far they are from you. They never see '
                        'it, only the distance.'
                    : 'Other dealers never see it, only how far their cars are from you.',
                style: const TextStyle(fontSize: 12, color: AppColors.grey),
              ),
              const SizedBox(height: 14),
              AddressSearchField(
                controller: _address,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search your showroom name or address',
                  hintStyle: TextStyle(fontSize: 13),
                  prefixIcon: Icon(Icons.search, size: 18),
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                onPicked: (place) => _save(place: place),
              ),
              const SizedBox(height: 8),
              Obx(
                () =>
                    _controller.isLocating.value
                        ? const Padding(
                          padding: EdgeInsets.all(10),
                          child: Center(
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        )
                        : TextButton.icon(
                          onPressed: _save,
                          icon: const Icon(Icons.my_location, size: 18),
                          label: const Text(
                            "Use my current location (I'm at the showroom)",
                          ),
                        ),
              ),
              if (widget.asking)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text(
                      'Later',
                      style: TextStyle(color: AppColors.grey),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
