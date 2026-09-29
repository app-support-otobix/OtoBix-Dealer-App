import 'package:flutter/material.dart';
import 'package:otobix/Models/Dealer%20Membership/dealer_exchange_model.dart';
import 'package:otobix/Utils/app_colors.dart';
import 'package:otobix/Utils/global_functions.dart';
import 'package:otobix/Views/Dealer%20Membership/dealer_membership_navigator.dart';
import 'package:otobix/Widgets/Dealer%20Membership/dealer_common_widgets.dart';
import 'package:otobix/Widgets/Dealer%20Membership/vehicle_spec_sheet.dart';

class ExchangeListingCard extends StatelessWidget {
  final DealerExchangeListingModel listing;

  const ExchangeListingCard({super.key, required this.listing});

  @override
  Widget build(BuildContext context) {
    final l = listing;
    return DealerSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CarThumbnail(imageUrl: l.images.isEmpty ? '' : l.images.first),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _ThinBadge(label: l.source),
                        if (l.matchPercent > 0)
                          _ThinBadge(
                            label: '${l.matchPercent}% Match',
                            color: AppColors.blue,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: PriceBox(
              label: 'Exchange Price',
              value: GlobalFunctions.formatRupees(l.exchangePrice),
              color: AppColors.blue,
            ),
          ),
          const SizedBox(height: 12),
          VehicleSpecSheet(
            specs: [
              ('Make', l.make),
              ('Model', l.model),
              ('Variant', l.variant),
              ('Mfg Year', l.mfgYear > 0 ? '${l.mfgYear}' : ''),
              ('Regn Year', l.regnYear > 0 ? '${l.regnYear}' : ''),
              ('Own Srl No', l.ownerSerialNo > 0 ? '${l.ownerSerialNo}' : ''),
              ('Transmission', l.transmission),
              ('Fuel Type', l.fuelType.toUpperCase()),
              ('Tax Validity', l.taxValidity),
              ('Insurance Validity', l.insuranceValidity),
              ('RTO', l.rto),
              ('City', l.city),
              ('Kms', '${GlobalFunctions.formatNumber(l.kms)} km'),
              ('Listing', l.listingCode),
            ],
          ),
          Text(
            [
              'Seller: ${l.sellerType.isEmpty ? 'Dealer' : l.sellerType} · anonymous',
              if (l.matchedRequirement.isNotEmpty)
                'Matches ${l.matchedRequirement}',
              GlobalFunctions.timeAgo(l.listedAt),
            ].join(' · '),
            style: const TextStyle(fontSize: 11, color: AppColors.grey),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed:
                      () => DealerMembershipNavigator.openChatForListing(l),
                  icon: const Icon(Icons.chat_bubble_outline, size: 16),
                  label: const Text('Chat Now'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.green,
                    side: const BorderSide(color: AppColors.green),
                    minimumSize: const Size(0, 40),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed:
                      () =>
                          DealerMembershipNavigator.requestConnectionForListing(
                            l,
                          ),
                  icon: const Icon(Icons.meeting_room_outlined, size: 16),
                  label: const Text('Enter Deal Room'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.green,
                    minimumSize: const Size(0, 40),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ThinBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _ThinBadge({required this.label, this.color = AppColors.green});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
