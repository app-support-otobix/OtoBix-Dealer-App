import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:otobix/Controllers/Dealer%20Membership/dealer_connections_controller.dart';
import 'package:otobix/Models/Dealer%20Membership/dealer_deal_room_model.dart';
import 'package:otobix/Utils/app_colors.dart';
import 'package:otobix/Utils/global_functions.dart';
import 'package:otobix/Widgets/Dealer%20Membership/dealer_common_widgets.dart';
import 'package:otobix/Widgets/app_bar_widget.dart';

class DealRoomExceptionsPage extends StatefulWidget {
  final DealerDealRoomModel room;
  const DealRoomExceptionsPage({super.key, required this.room});

  @override
  State<DealRoomExceptionsPage> createState() => _DealRoomExceptionsPageState();
}

class _DealRoomExceptionsPageState extends State<DealRoomExceptionsPage> {
  final controller = DealerConnectionsController.to;
  late DealerDealRoomModel room = widget.room;

  Future<void> _exception(String status) async {
    final isDispute = status == 'DISPUTED';
    final note = await Get.dialog<String>(
      DealerInputDialog(
        title: isDispute ? 'Raise a dispute' : 'Cancel this deal',
        message:
            isDispute
                ? 'OtoBix support reviews disputes. Consumed points are not refunded automatically - any correction appears in your ledger.'
                : 'The Deal Room stays on record. Consumed points are not refunded.',
        cancelLabel: 'Back',
        confirmLabel: isDispute ? 'Raise Dispute' : 'Cancel Deal',
        confirmColor: AppColors.red,
        maxLines: 3,
        maxLength: 500,
        decoration: InputDecoration(
          hintText:
              isDispute ? 'What went wrong?' : 'Why is the deal cancelled?',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
    if (note == null) return;
    final updated = await controller.updateDealStatus(
      room.id,
      status: status,
      note: note,
    );
    if (updated != null) setState(() => room = updated);
  }

  @override
  Widget build(BuildContext context) {
    final closed = room.isClosed;
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBarWidget(
        title: '${room.statusLabel} — ${room.dealRoomCode}',
        onBackPressed: () => Get.back(result: room),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DealerSectionCard(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  DealerStatusChip(
                    label: room.statusLabel.toUpperCase(),
                    color:
                        room.status == 'COMPLETED'
                            ? AppColors.green
                            : closed
                            ? AppColors.red
                            : AppColors.blue,
                  ),
                  Text(
                    room.carTitle,
                    style: const TextStyle(fontSize: 11, color: AppColors.grey),
                  ),
                ],
              ),
            ),
            if (room.disputeReason.isNotEmpty ||
                room.cancelReason.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                room.disputeReason.isNotEmpty
                    ? 'Dispute: ${room.disputeReason}'
                    : 'Cancelled: ${room.cancelReason}',
                style: const TextStyle(fontSize: 12, color: AppColors.red),
              ),
            ],
            const SizedBox(height: 14),
            const Text(
              'Transaction Status',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 10),
            for (final h in room.statusHistory)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 56,
                      child: Text(
                        GlobalFunctions.getFormattedDate(
                              date: h.at,
                              type: GlobalFunctions.dayMonth,
                            ) ??
                            '',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.grey,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${h.label}${h.byMe ? ' · by you' : ''}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color:
                                  {'DISPUTED', 'CANCELLED'}.contains(h.status)
                                      ? AppColors.red
                                      : AppColors.black,
                            ),
                          ),
                          if (h.note.isNotEmpty)
                            Text(
                              h.note,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.grey,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 14),
            DealerSectionCard(
              title: 'If the Deal Breaks Down',
              child: Text(
                closed
                    ? 'This deal is ${room.statusLabel.toLowerCase()} and stays on record with its full history.'
                    : 'Cancel the deal, or raise a dispute for OtoBix support to review. Either way nothing is deleted - the room keeps its full audit history.',
                style: const TextStyle(fontSize: 12, color: AppColors.grey),
              ),
            ),
            if (!closed) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  if (room.nextStatuses.contains('CANCELLED'))
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _exception('CANCELLED'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.grey,
                        ),
                        child: const Text('Cancel Deal'),
                      ),
                    ),
                  const SizedBox(width: 10),
                  if (room.nextStatuses.contains('DISPUTED'))
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _exception('DISPUTED'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.red,
                        ),
                        child: const Text('Raise Dispute'),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
