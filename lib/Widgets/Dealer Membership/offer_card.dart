import 'package:flutter/material.dart';
import 'package:otobix/Models/Dealer%20Membership/dealer_negotiation_model.dart';
import 'package:otobix/Utils/app_colors.dart';
import 'package:otobix/Utils/global_functions.dart';
import 'package:otobix/Widgets/Dealer%20Membership/dealer_common_widgets.dart';

Color dealerOfferStatusColor(String status) {
  switch (status) {
    case 'ACTION NEEDED':
    case 'REJECTED':
    case 'DISPUTED':
      return AppColors.red;
    case 'COUNTERED':
    case 'OFFER SENT':
      return AppColors.deepOrange;
    case 'AGREED':
    case 'CONNECTED':
      return AppColors.green;
    default:
      return AppColors.grey;
  }
}

String dealerOfferNote(DealerNegotiationModel n) {
  final who =
      n.counterpart.isRevealed ? n.counterpart.name : n.counterpart.dealerCode;
  final amount = GlobalFunctions.formatLakh(n.lastOfferAmount ?? 0);
  switch (n.displayStatus) {
    case 'ACTION NEEDED':
      return '${n.lastOfferIsCounter ? 'Counteroffer' : 'Offer'} $amount from $who · accept, reject or counter';
    case 'COUNTERED':
      return 'You countered $amount · awaiting reply';
    case 'OFFER SENT':
      return 'You offered $amount · awaiting reply';
    case 'AGREED':
      return '${GlobalFunctions.formatLakh(n.agreedAmount)} agreed · request a connection to reveal identity';
    case 'CONNECTED':
      return 'Connected with $who · Deal Room open';
    case 'REJECTED':
      return 'Offer rejected · a new offer can be made';
    case 'DISPUTED':
      return 'Dispute raised on this deal · under review';
    default:
      return n.questionCount > 0
          ? '${n.questionCount} question${n.questionCount == 1 ? '' : 's'} · no offer yet'
          : 'In discussion · no offer yet';
  }
}

/// Both dealers' latest prices, as in the chat: mine in blue, the other
/// dealer's in red, and the agreed price in green once there is one.
class NegotiationPricesRow extends StatelessWidget {
  final DealerNegotiationModel negotiation;
  const NegotiationPricesRow({super.key, required this.negotiation});

  @override
  Widget build(BuildContext context) {
    final n = negotiation;
    if (n.buyerPrice <= 0 && n.sellerPrice <= 0 && n.finalPrice <= 0) {
      return const SizedBox.shrink();
    }
    final buyerColor = n.isBuyer ? AppColors.blue : AppColors.red;
    final sellerColor = n.isBuyer ? AppColors.red : AppColors.blue;
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        if (n.buyerPrice > 0)
          _pill(n.isBuyer ? 'Buyer (you)' : 'Buyer', n.buyerPrice, buyerColor),
        if (n.sellerPrice > 0)
          _pill(
            n.isBuyer ? 'Seller' : 'Seller (you)',
            n.sellerPrice,
            sellerColor,
          ),
        if (n.finalPrice > 0) _pill('Final', n.finalPrice, AppColors.green),
      ],
    );
  }

  Widget _pill(String label, int amount, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$label ',
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextSpan(
              text: GlobalFunctions.formatLakh(amount),
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Who the other dealer is: their dealer code (their name once connected),
/// dealer type and city.
class DealerPartyTile extends StatelessWidget {
  final DealerPartyModel party;
  const DealerPartyTile({super.key, required this.party});

  @override
  Widget build(BuildContext context) {
    final title = party.isRevealed ? party.name : party.dealerCode;
    final details = [
      if (party.isRevealed) party.dealerCode,
      if (party.dealerType.isNotEmpty) party.dealerType,
      if (party.city.isNotEmpty) party.city,
    ].join(' · ');
    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: AppColors.blue.withValues(alpha: 0.1),
          child: const Icon(Icons.storefront, size: 18, color: AppColors.blue),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title.isEmpty ? 'Dealer' : title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              if (details.isNotEmpty)
                Text(
                  details,
                  style: const TextStyle(fontSize: 11, color: AppColors.grey),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class OfferCard extends StatelessWidget {
  final DealerNegotiationModel negotiation;
  final VoidCallback onTap;
  final bool showCar;

  const OfferCard({
    super.key,
    required this.negotiation,
    required this.onTap,
    this.showCar = true,
  });

  @override
  Widget build(BuildContext context) {
    final n = negotiation;
    final amount =
        n.agreedAmount > 0 ? n.agreedAmount : (n.lastOfferAmount ?? 0);
    final actionLabel =
        n.dealRoomId.isNotEmpty
            ? 'Open Deal Room ›'
            : n.displayStatus == 'AGREED'
            ? 'Request Connection ›'
            : amount > 0
            ? 'Review Offer · ${GlobalFunctions.formatLakh(amount)} ›'
            : 'Open Chat ›';
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: DealerSectionCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: DealerPartyTile(party: n.counterpart)),
                if (n.unread > 0) ...[
                  Badge.count(count: n.unread),
                  const SizedBox(width: 8),
                ],
              ],
            ),
            const SizedBox(height: 10),
            DealerStatusChip(
              label: n.displayStatus,
              color: dealerOfferStatusColor(n.displayStatus),
            ),
            const SizedBox(height: 8),
            NegotiationPricesRow(negotiation: n),
            const SizedBox(height: 8),
            if (showCar)
              Text(
                '${n.carTitle} — ${GlobalFunctions.formatLakh(n.askingPrice)} asking',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            const SizedBox(height: 4),
            Text(
              dealerOfferNote(n),
              style: const TextStyle(fontSize: 12, color: AppColors.grey),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                actionLabel,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.blue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
