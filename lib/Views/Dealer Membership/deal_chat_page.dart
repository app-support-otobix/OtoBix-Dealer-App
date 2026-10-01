import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:otobix/Controllers/Dealer%20Membership/dealer_chat_controller.dart';
import 'package:otobix/Controllers/Dealer%20Membership/dealer_membership_controller.dart';
import 'package:otobix/Models/Dealer%20Membership/dealer_negotiation_model.dart';
import 'package:otobix/Utils/app_colors.dart';
import 'package:otobix/Utils/global_functions.dart';
import 'package:otobix/Views/Dealer%20Membership/dealer_membership_navigator.dart';
import 'package:otobix/Widgets/Dealer%20Membership/chat_message_bubble.dart';
import 'package:otobix/Widgets/Dealer%20Membership/dealer_common_widgets.dart';
import 'package:otobix/Widgets/Dealer%20Membership/offer_card.dart';
import 'package:otobix/Widgets/app_bar_widget.dart';

class DealChatPage extends StatefulWidget {
  final String negotiationId;
  const DealChatPage({super.key, required this.negotiationId});

  @override
  State<DealChatPage> createState() => _DealChatPageState();
}

class _DealChatPageState extends State<DealChatPage> {
  late final DealerChatController chat = Get.put(
    DealerChatController(widget.negotiationId),
    tag: widget.negotiationId,
  );
  final membership = DealerMembershipController.to;

  static const _categoryColors = <String, Color>{
    'Greeting': AppColors.green,
    'Interest': AppColors.blue,
    'Offer': AppColors.deepOrange,
    'Vehicle History': Colors.purple,
    'Inspection': Colors.teal,
    'Connection': Colors.indigo,
  };

  @override
  void initState() {
    super.initState();
    membership.ensureConfig();
  }

  @override
  void dispose() {
    Get.delete<DealerChatController>(tag: widget.negotiationId);
    super.dispose();
  }

  Future<void> _onQuickReply(String text) async {
    if (text == membership.config.value?.offerQuickMessage) {
      final n = chat.negotiation.value;
      final amount = await showDealerOfferDialog(
        context,
        title: 'Your Offer',
        suggested: n?.lastOfferAmount ?? n?.askingPrice,
      );
      if (amount != null) chat.makeOffer(amount);
      return;
    }
    chat.send(text);
  }

  Future<void> _answer(DealerMessageModel question) async {
    final config = membership.config.value;
    final answers = [
      ...(config?.presetAnswers[question.text] ?? const []),
      ...(config?.fallbackAnswers ?? const []),
    ];
    final answer = await showModalBottomSheet<String>(
      context: context,
      builder:
          (ctx) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Text(
                    question.text,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                for (final a in answers)
                  ListTile(
                    dense: true,
                    title: Text(a),
                    onTap: () => Navigator.pop(ctx, a),
                  ),
              ],
            ),
          ),
    );
    if (answer != null) chat.send(answer, answerTo: question.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBarWidget(
        title: 'Buyer / Seller Chat Room',
        titleIcon: Icons.handshake_outlined,
      ),
      body: SafeArea(
        child: Obx(() {
          final n = chat.negotiation.value;
          if (n == null) {
            return DealerStateView(
              isLoading: chat.isLoading.value,
              error: chat.error.value,
              isEmpty: true,
              emptyMessage: 'Conversation not found.',
              onRetry: chat.load,
              child: const SizedBox(),
            );
          }
          return Column(
            children: [
              _partiesRow(n),
              _statusStrip(n),
              const SizedBox(height: 8),
              Expanded(child: _messages(n)),
              const SizedBox(height: 8),
              if (n.dealRoomId.isEmpty) _quickReplyBar(n),
              const SizedBox(height: 8),
            ],
          );
        }),
      ),
    );
  }

  Widget _partiesRow(DealerNegotiationModel n) {
    final other =
        n.counterpart.isRevealed
            ? n.counterpart.name
            : '${n.counterpart.dealerCode} · ${n.counterpart.dealerType}';
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
      child: Row(
        children: [
          Expanded(
            child: _partyBox(
              Icons.person,
              'Buyer',
              n.isBuyer ? 'You' : other,
              AppColors.green,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _partyBox(
              Icons.storefront_outlined,
              'Seller',
              n.isBuyer ? other : 'You',
              AppColors.blue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _partyBox(IconData icon, String label, String subtitle, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 14),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color.withValues(alpha: 0.8),
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusStrip(DealerNegotiationModel n) {
    Widget? action;
    if (n.dealRoomId.isNotEmpty) {
      action = _stripButton(
        'Open Deal Room',
        () => DealerMembershipNavigator.openDealRoom(n.dealRoomId),
      );
    } else if (n.awaitsMyReply) {
      action = _stripButton(
        'Review Offer',
        () => DealerMembershipNavigator.openReviewOffer(n.id),
      );
    } else if (n.hasPendingConnection) {
      action = Text(
        'Connection pending · ${GlobalFunctions.timeLeft(n.connectionExpiresAt)}',
        style: const TextStyle(
          fontSize: 11,
          color: AppColors.deepOrange,
          fontWeight: FontWeight.bold,
        ),
      );
    } else {
      action = _stripButton(
        'Enter Deal Room',
        () => DealerMembershipNavigator.openRequestConnection(
          negotiationId: n.id,
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: DealerSectionCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${n.carTitle} · ${GlobalFunctions.formatLakh(n.askingPrice)} asking',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  DealerStatusChip(
                    label: n.displayStatus,
                    color: dealerOfferStatusColor(n.displayStatus),
                    small: true,
                  ),
                ],
              ),
            ),
            action,
          ],
        ),
      ),
    );
  }

  Widget _stripButton(String label, VoidCallback onTap) {
    return FilledButton(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.green,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        minimumSize: const Size(0, 32),
        textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
      ),
      child: Text(label),
    );
  }

  Widget _messages(DealerNegotiationModel n) {
    final answered = {
      for (final m in chat.messages)
        if (m.kind == 'ANSWER') m.answerTo,
    };
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.grey.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(12),
        color: AppColors.grey.withValues(alpha: 0.03),
      ),
      child: NotificationListener<ScrollNotification>(
        onNotification: (s) {
          if (s.metrics.pixels <= 40) chat.loadOlder();
          return false;
        },
        child:
            chat.messages.isEmpty
                ? Center(
                  child: Text(
                    chat.isLoading.value
                        ? 'Loading…'
                        : 'Say hello - pick a message below. Chatting and offers are free.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: AppColors.grey),
                  ),
                )
                : ListView.builder(
                  controller: chat.scrollController,
                  padding: const EdgeInsets.all(14),
                  itemCount:
                      chat.messages.length +
                      (chat.isLoadingOlder.value ? 1 : 0),
                  itemBuilder: (context, i) {
                    if (chat.isLoadingOlder.value && i == 0) {
                      return const Padding(
                        padding: EdgeInsets.all(8),
                        child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    }
                    final m =
                        chat.messages[i - (chat.isLoadingOlder.value ? 1 : 0)];
                    final canAnswer =
                        !n.isBuyer &&
                        m.kind == 'QUESTION' &&
                        m.id.isNotEmpty &&
                        !answered.contains(m.id);
                    return ChatMessageBubble(
                      message: m,
                      mine: chat.isMine(m),
                      onRetry: () => chat.retry(m),
                      onAnswer: canAnswer ? () => _answer(m) : null,
                    );
                  },
                ),
      ),
    );
  }

  Widget _quickReplyBar(DealerNegotiationModel n) {
    final config = membership.config.value;
    // "Please kindly accept" only while my own connection request is pending.
    final nudge = config?.connectionQuickMessage ?? '';
    final canNudge = n.hasPendingConnection && n.connectionInitiatedByMe;
    bool shown(String text) => canNudge || text != nudge;
    final categories = <String, List<String>>{
      for (final e in (config?.quickMessages ?? const {}).entries)
        if (e.value.any(shown)) e.key: e.value.where(shown).toList(),
    };
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.3,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(10, 4, 10, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                'Pick a message to send:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.black,
                ),
              ),
            ),
            for (final category in categories.entries)
              Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color:
                                _categoryColors[category.key] ?? AppColors.grey,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          category.key.toUpperCase(),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: AppColors.grey.withValues(alpha: 0.8),
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final text in category.value)
                          OutlinedButton(
                            onPressed: () => _onQuickReply(text),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.black,
                              side: BorderSide(
                                color: AppColors.grey.withValues(alpha: 0.4),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              text,
                              style: const TextStyle(fontSize: 10),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
