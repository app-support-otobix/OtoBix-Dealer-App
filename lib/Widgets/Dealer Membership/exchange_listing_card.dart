import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:otobix/Controllers/Dealer%20Membership/dealer_exchange_controller.dart';
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: PriceBox(
                  label: 'Their Price',
                  value: GlobalFunctions.formatRupees(l.exchangePrice),
                  color: AppColors.blue,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: _QuickOfferBox(listing: l)),
            ],
          ),
          _MyOfferStatus(listing: l),
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

/// Your price for this car, sent to the seller without opening the chat.
class _QuickOfferBox extends StatefulWidget {
  final DealerExchangeListingModel listing;
  const _QuickOfferBox({required this.listing});

  @override
  State<_QuickOfferBox> createState() => _QuickOfferBoxState();
}

class _QuickOfferBoxState extends State<_QuickOfferBox> {
  final _amount = TextEditingController();

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final amount = int.tryParse(_amount.text.trim()) ?? 0;
    if (amount <= 0) return;
    FocusScope.of(context).unfocus();
    if (await DealerExchangeController.to.quickOffer(widget.listing, amount)) {
      _amount.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = DealerExchangeController.to;
    return Obx(() {
      final offer = controller.myOfferOn(widget.listing);
      final closed = [
        'AGREED',
        'CONNECTED',
        'CLOSED',
      ].contains(offer?.displayStatus);
      final sending = controller.offeringOn.value == widget.listing.id;
      return Container(
        padding: const EdgeInsets.fromLTRB(10, 8, 4, 4),
        decoration: BoxDecoration(
          color: AppColors.green.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Offer',
              style: TextStyle(fontSize: 11, color: AppColors.grey),
            ),
            if (closed)
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 6),
                child: Text(
                  GlobalFunctions.formatRupees(offer!.agreedAmount),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.green,
                  ),
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _amount,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(9),
                      ],
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                      decoration: const InputDecoration(
                        prefixText: '₹ ',
                        hintText: 'Enter price',
                        hintStyle: TextStyle(fontSize: 13),
                        isDense: true,
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  sending
                      ? const Padding(
                        padding: EdgeInsets.all(10),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.green,
                          ),
                        ),
                      )
                      : IconButton(
                        tooltip: 'Send offer',
                        onPressed: _send,
                        icon: const Icon(Icons.send, color: AppColors.green),
                      ),
                ],
              ),
          ],
        ),
      );
    });
  }
}

/// Where the seller stands on your offer.
class _MyOfferStatus extends StatelessWidget {
  final DealerExchangeListingModel listing;
  const _MyOfferStatus({required this.listing});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final o = DealerExchangeController.to.myOfferOn(listing);
      if (o == null || o.displayStatus == 'IN DISCUSSION') {
        return const SizedBox.shrink();
      }
      final amount = GlobalFunctions.formatRupees(o.amount);
      final (String text, Color color) = switch (o.displayStatus) {
        'OFFER SENT' => (
          'You offered $amount · waiting for the seller',
          AppColors.deepOrange,
        ),
        'COUNTERED' => (
          'You countered $amount · waiting for the seller',
          AppColors.deepOrange,
        ),
        'ACTION NEEDED' => (
          'Seller countered $amount · send a new price or open the chat',
          AppColors.red,
        ),
        'AGREED' => (
          '${GlobalFunctions.formatRupees(o.agreedAmount)} agreed · the seller is interested, enter the Deal Room',
          AppColors.green,
        ),
        'CONNECTED' => ('Connected · Deal Room open', AppColors.green),
        'REJECTED' => (
          'Seller rejected your offer · you can send a new price',
          AppColors.red,
        ),
        _ => ('', AppColors.grey),
      };
      if (text.isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      );
    });
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
