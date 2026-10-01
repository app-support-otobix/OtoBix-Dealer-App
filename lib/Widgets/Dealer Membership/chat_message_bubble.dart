import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:otobix/Models/Dealer%20Membership/dealer_negotiation_model.dart';
import 'package:otobix/Utils/app_colors.dart';
import 'package:otobix/Utils/global_functions.dart';
import 'package:otobix/Widgets/Dealer%20Membership/dealer_common_widgets.dart';

class ChatMessageBubble extends StatelessWidget {
  final DealerMessageModel message;
  final bool mine;
  final VoidCallback? onRetry;
  final VoidCallback? onAnswer;

  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.mine,
    this.onRetry,
    this.onAnswer,
  });

  @override
  Widget build(BuildContext context) {
    final m = message;
    if (m.kind == 'SYSTEM') return _systemNote(m.text);
    final isOffer = m.kind == 'OFFER';
    final failed = m.state == DealerMessageState.failed;
    final sending = m.state == DealerMessageState.sending;
    // The other dealer's counter-offer stands out in red.
    final isTheirCounter = isOffer && !mine && m.offerLabel == 'COUNTER';
    final background =
        isTheirCounter
            ? AppColors.red
            : isOffer
            ? AppColors.blue
            : mine
            ? AppColors.green
            : AppColors.grey.withValues(alpha: 0.15);
    final foreground = isOffer || mine ? Colors.white : AppColors.black;

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onTap: failed ? onRetry : onAnswer,
        child: Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: EdgeInsets.symmetric(
            horizontal: isOffer ? 12 : 10,
            vertical: isOffer ? 7 : 6,
          ),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.7,
          ),
          decoration: BoxDecoration(
            color: failed ? background.withValues(alpha: 0.5) : background,
            borderRadius: BorderRadius.circular(10),
            border: failed ? Border.all(color: AppColors.red) : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isOffer)
                Text(
                  _offerLabel(m),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
              if (m.kind == 'QUESTION')
                Text(
                  'QUESTION',
                  style: TextStyle(
                    color: foreground.withValues(alpha: 0.7),
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              Text(
                isOffer ? GlobalFunctions.formatLakh(m.amount) : m.text,
                style: TextStyle(
                  color: foreground,
                  fontSize: isOffer ? 15 : 12,
                  fontWeight: isOffer ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                failed
                    ? 'Not sent · tap to retry'
                    : sending
                    ? 'Sending…'
                    : onAnswer != null
                    ? 'Tap to answer'
                    : DateFormat('d MMM, HH:mm').format(m.createdAt.toLocal()),
                style: TextStyle(
                  color:
                      failed
                          ? AppColors.red
                          : foreground.withValues(alpha: 0.7),
                  fontSize: 8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _offerLabel(DealerMessageModel m) {
    final counter = m.offerLabel == 'COUNTER';
    if (mine) return counter ? 'YOUR COUNTER' : 'YOUR OFFER';
    final who = m.senderRole == 'BUYER' ? "BUYER'S" : "SELLER'S";
    return '$who ${counter ? 'COUNTER' : 'OFFER'}';
  }

  Widget _systemNote(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.grey.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

Future<int?> showDealerOfferDialog(
  BuildContext context, {
  required String title,
  int? suggested,
}) async {
  final text = await showDialog<String>(
    context: context,
    builder:
        (_) => DealerInputDialog(
          title: title,
          confirmLabel: 'Send',
          initialText:
              suggested != null && suggested > 0
                  ? (suggested / 100000).toStringAsFixed(2)
                  : '',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            prefixText: '₹',
            suffixText: 'L',
            hintText: 'e.g. 8.75',
          ),
        ),
  );
  final lakh = double.tryParse(text ?? '');
  if (lakh == null || lakh <= 0) return null;
  return (lakh * 100000).round();
}
