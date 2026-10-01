import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:otobix/Controllers/Dealer%20Membership/dealer_membership_controller.dart';
import 'package:otobix/Controllers/Dealer%20Membership/dealer_negotiations_controller.dart';
import 'package:otobix/Models/Dealer%20Membership/dealer_negotiation_model.dart';
import 'package:otobix/Utils/app_colors.dart';
import 'package:otobix/Utils/global_functions.dart';
import 'package:otobix/Views/Dealer%20Membership/dealer_membership_navigator.dart';
import 'package:otobix/Widgets/Dealer%20Membership/chat_message_bubble.dart';
import 'package:otobix/Widgets/Dealer%20Membership/dealer_common_widgets.dart';
import 'package:otobix/Widgets/Dealer%20Membership/offer_card.dart';
import 'package:otobix/Widgets/app_bar_widget.dart';
import 'package:otobix/Widgets/button_widget.dart';

class ReviewOfferPage extends StatefulWidget {
  final String negotiationId;
  const ReviewOfferPage({super.key, required this.negotiationId});

  @override
  State<ReviewOfferPage> createState() => _ReviewOfferPageState();
}

class _ReviewOfferPageState extends State<ReviewOfferPage> {
  final controller = DealerNegotiationsController.to;
  final negotiation = Rxn<DealerNegotiationModel>();
  final isLoading = true.obs;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    isLoading.value = true;
    negotiation.value = await controller.get(widget.negotiationId);
    isLoading.value = false;
  }

  Future<void> _counter(DealerNegotiationModel n) async {
    final amount = await showDealerOfferDialog(
      context,
      title: 'Counter Offer',
      suggested: n.lastOfferAmount,
    );
    if (amount == null) return;
    final updated = await controller.makeOffer(n.id, amount);
    if (updated != null) negotiation.value = updated;
  }

  Future<void> _respond(DealerNegotiationModel n, bool accept) async {
    final updated = await controller.respond(n.id, accept: accept);
    if (updated != null) negotiation.value = updated;
  }

  @override
  Widget build(BuildContext context) {
    final points =
        DealerMembershipController.to.config.value?.connectionPoints ?? 500;
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBarWidget(title: 'Review Offer'),
      body: SafeArea(
        child: Obx(() {
          final n = negotiation.value;
          if (n == null) {
            return DealerStateView(
              isLoading: isLoading.value,
              error: isLoading.value ? '' : 'This offer could not be loaded.',
              isEmpty: true,
              emptyMessage: '',
              onRetry: _load,
              child: const SizedBox(),
            );
          }
          final amount =
              n.agreedAmount > 0 ? n.agreedAmount : (n.lastOfferAmount ?? 0);
          return RefreshIndicator(
            color: AppColors.green,
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                DealerSectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${n.carTitle} — ${GlobalFunctions.formatLakh(n.askingPrice)} asking',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            amount > 0
                                ? GlobalFunctions.formatLakh(amount)
                                : 'No offer yet',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                              // Agreed green, my price blue, theirs red.
                              color:
                                  n.agreedAmount > 0 || amount == 0
                                      ? AppColors.green
                                      : n.lastOfferByMe
                                      ? AppColors.blue
                                      : AppColors.red,
                            ),
                          ),
                          DealerStatusChip(
                            label: n.displayStatus,
                            color: dealerOfferStatusColor(n.displayStatus),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      NegotiationPricesRow(negotiation: n),
                      const SizedBox(height: 6),
                      Text(
                        dealerOfferNote(n),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Accepting, rejecting or countering an offer is free. Only a connection to reveal identity uses $points points from each side.',
                  style: const TextStyle(fontSize: 12, color: AppColors.grey),
                ),
                const SizedBox(height: 20),
                if (n.awaitsMyReply)
                  _respondCard(n)
                else if (n.displayStatus != 'CONNECTED')
                  _counterCard(n),
                const SizedBox(height: 24),
                _connectSection(n),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _respondCard(DealerNegotiationModel n) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.grey.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'RESPOND TO OFFER',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.grey,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed:
                      controller.isActing.value
                          ? null
                          : () => _respond(n, false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.red,
                  ),
                  child: const Text('Reject'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed:
                      controller.isActing.value ? null : () => _counter(n),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.deepOrange,
                  ),
                  child: const Text('Counter'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ButtonWidget(
            text:
                'Accept · ${GlobalFunctions.formatLakh(n.lastOfferAmount ?? 0)}',
            isLoading: controller.isActing,
            width: double.infinity,
            onTap: () => _respond(n, true),
          ),
        ],
      ),
    );
  }

  Widget _counterCard(DealerNegotiationModel n) {
    if (n.displayStatus == 'AGREED' || n.status == 'CLOSED') {
      return const SizedBox.shrink();
    }
    return OutlinedButton.icon(
      onPressed: () => _counter(n),
      icon: const Icon(Icons.local_offer_outlined, size: 16),
      label: Text(
        n.lastOfferAmount == null ? 'Make an Offer' : 'Make a New Offer',
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.deepOrange,
        side: const BorderSide(color: AppColors.deepOrange),
        minimumSize: const Size(0, 40),
      ),
    );
  }

  Widget _connectSection(DealerNegotiationModel n) {
    final other = n.isBuyer ? 'SELLER' : 'BUYER';
    final Widget primary;
    if (n.dealRoomId.isNotEmpty) {
      primary = _filled(
        Icons.meeting_room_outlined,
        'Open Deal Room',
        () => DealerMembershipNavigator.openDealRoom(n.dealRoomId),
      );
    } else if (n.hasPendingConnection) {
      primary = _filled(
        Icons.hourglass_top,
        n.connectionInitiatedByMe
            ? 'Awaiting ${other.toLowerCase()}'
            : 'Respond to request',
        () => DealerMembershipNavigator.openConnection(n.connectionId),
      );
    } else {
      primary = _filled(
        Icons.meeting_room_outlined,
        'Enter Deal Room',
        () => DealerMembershipNavigator.openRequestConnection(
          negotiationId: n.id,
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CONNECT WITH $other',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: AppColors.grey,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => DealerMembershipNavigator.openChat(n.id),
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
            Expanded(child: primary),
          ],
        ),
      ],
    );
  }

  Widget _filled(IconData icon, String label, VoidCallback onTap) {
    return FilledButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label, overflow: TextOverflow.ellipsis),
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.green,
        minimumSize: const Size(0, 40),
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
    );
  }
}
